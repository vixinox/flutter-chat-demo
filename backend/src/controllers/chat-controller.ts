import type { Request, Response } from 'express';
import { prisma } from '../prisma/prisma';
import { MessageRole } from '@prisma/client';
import { config } from '../config';

/**
 * 将对象编码为 SSE 格式
 */
const encodeSse = (obj: unknown) => {
  try {
    return `data: ${JSON.stringify(obj)}\n\n`;
  } catch (e) {
    return `data: ${JSON.stringify({ type: 'error', message: '序列化失败' })}\n\n`;
  }
};

export async function chatCompletion(req: Request, res: Response) {
  const { model, content, conversationId } = req.body;

  if (!model || !content) {
    res.setHeader('Content-Type', 'text/event-stream');
    res.setHeader('Cache-Control', 'no-cache');
    res.setHeader('Connection', 'keep-alive');
    res.write(
      encodeSse({
        type: 'error',
        message: '缺少必要参数 model 或 content',
      }),
    );
    return res.end();
  }

  // 兼容性优化：Bun 运行时也用 Express res.stream
  console.log("chatCompletion start");
  res.setHeader('Content-Type', 'text/event-stream; charset=utf-8');
  res.setHeader('Cache-Control', 'no-cache, no-transform');
  res.setHeader('Connection', 'keep-alive');
  res.flushHeaders?.();

  let convId = conversationId;
  if (!convId) {
    const safeTitle = content.replace(/[\r\n]+/g, ' ').slice(0, 20) + (content.length > 20 ? '…' : '');
    const newConv = await prisma.conversation.create({
      data: { title: safeTitle },
    });
    convId = newConv.id;
  }
  res.write(
    encodeSse({
      type: 'init',
      conversationId: convId || null,
      modelName: model,
    }),
  );

  // 加载历史消息（如果有会话ID）
  let fullMessages: { role: 'user' | 'assistant' | 'system'; content: string }[] = [];
  if (convId) {
    const existingConv = await prisma.conversation.findUnique({
      where: { id: convId },
      include: { messages: { orderBy: { createdAt: 'asc' }, select: { role: true, content: true } } },
    });
    if (existingConv) {
      fullMessages = existingConv.messages.map((m) => ({
        role: m.role as 'user' | 'assistant' | 'system',
        content: m.content,
      }));
    }
  }

  // 历史 + 当前用户消息
  fullMessages.push({ role: 'user', content });
  if (fullMessages.length > 10) {
    fullMessages = fullMessages.slice(-10);
  }

  // 模型信息
  const modelRecord = await prisma.model
  .findUnique({ where: { name: model } })
  .catch(() => null);

  // 保存用户消息
  await prisma.message.create({
    data: {
      conversationId: convId!,
      role: MessageRole.user,
      content,
      modelName: modelRecord?.name || null,
      modelDisplayName: modelRecord?.displayName || null,
      modelProvider: modelRecord?.provider || null,
    },
  });

  // 调用上游 OpenAI 接口（流式）
  const controller = new AbortController();
  req.on('close', () => controller.abort()); // 客户端断开连接则中止请求

  try {
    const upstream = await fetch(config.apiEndpoint, {
      method: 'POST',
      headers: {
        'Content-Type': 'application/json',
        Authorization: `Bearer ${config.apiKey}`,
      },
      body: JSON.stringify({
        model,
        messages: fullMessages,
        temperature: 0.7,
        stream: true,
      }),
      signal: controller.signal,
    });

    if (!upstream.ok || !upstream.body) {
      throw new Error(`上游接口错误：${upstream.status} ${upstream.statusText}`);
    }

    const reader = upstream.body.getReader();
    const decoder = new TextDecoder();
    let accumulated = '';

    while (true) {
      const { done, value } = await reader.read();
      if (done) break;

      const chunkText = decoder.decode(value, { stream: true });
      const lines = chunkText.split('\n').filter((l) => l.trim() !== '');

      for (const line of lines) {
        if (line === 'data: [DONE]') {
          continue;
        }
        if (line.startsWith('data:')) {
          try {
            const jsonStr = line.slice(5).trim();
            const parsed = JSON.parse(jsonStr);
            const delta = parsed?.choices?.[0]?.delta?.content;
            if (delta) {
              accumulated += delta;
              res.write(
                encodeSse({
                  type: 'chunk',
                  content: delta,
                }),
              );
            }
          } catch (err) {
            console.error('解析OpenAI流数据失败:', err);
          }
        }
      }
    }

    // 保存完整助手消息
    const aiMsgRecord = await prisma.message.create({
      data: {
        conversationId: convId!,
        role: MessageRole.assistant,
        content: accumulated || '[未生成有效回复]',
        modelName: modelRecord?.name || null,
        modelDisplayName: modelRecord?.displayName || null,
        modelProvider: modelRecord?.provider || null,
      },
    });

    // 通知完成
    res.write(
      encodeSse({
        type: 'done',
        messageId: aiMsgRecord.id,
        fullContent: accumulated,
        createdAt: aiMsgRecord.createdAt.toISOString(),
        conversationId: convId,
      }),
    );
    res.end();
  } catch (err: any) {
    console.error('SSE流出错:', err);
    res.write(
      encodeSse({
        type: 'error',
        message: err?.message || String(err),
      }),
    );
    res.end();
  }
}
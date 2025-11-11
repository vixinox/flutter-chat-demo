import type { Request, Response } from 'express';
import { prisma } from '../prisma/prisma';
import { MessageRole } from '@prisma/client';

export const getMessagesByConversation = async (req: Request, res: Response) => {
  const { conversationId } = req.params;
  if (!conversationId) {
    return res.status(400).json({ error: 'conversationId 参数必填' });
  }

  const messages = await prisma.message.findMany({
    where: { conversationId },
    orderBy: { createdAt: 'asc' }
  });
  res.json(messages);
};

export const createMessage = async (req: Request, res: Response) => {
  const { conversationId } = req.params;
  if (!conversationId) {
    return res.status(400).json({ error: 'conversationId 参数必填' });
  }

  const { role, content, modelName, modelDisplayName, modelProvider } = req.body;
  if (!role || !content) {
    return res.status(400).json({ error: 'role 和 content 必填' });
  }

  try {
    const message = await prisma.message.create({
      data: {
        conversationId: conversationId,
        role: role as MessageRole,
        content: String(content),
        modelName: modelName ? String(modelName) : null,
        modelDisplayName: modelDisplayName ? String(modelDisplayName) : null,
        modelProvider: modelProvider ? String(modelProvider) : null
      }
    });
    res.status(201).json(message);
  } catch (error) {
    res.status(500).json({ error: 'Failed to create message' });
  }
};
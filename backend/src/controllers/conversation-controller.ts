import type { Request, Response } from 'express';
import { prisma } from '../prisma/prisma';

export const getAllConversations = async (req: Request, res: Response) => {
  const conversations = await prisma.conversation.findMany();
  res.json(conversations);
};

export const updateConversation = async (req: Request, res: Response) => {
  const { title } = req.body;
  if (!title) return res.status(400).json({ error: "title 必填" });
  
  try {
    const convo = await prisma.conversation.update({
      where: { id: req.params.id },
      data: { title }
    });
    res.json(convo);
  } catch (error) {
    res.status(500).json({ error: 'Failed to update conversation' });
  }
};

export const deleteConversation = async (req: Request, res: Response) => {
  try {
    await prisma.conversation.delete({
      where: { id: req.params.id }
    });
    res.json({ success: true });
  } catch (error) {
    res.status(500).json({ error: 'Failed to delete conversation' });
  }
};
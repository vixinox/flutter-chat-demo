import type { Request, Response } from 'express';
import { prisma } from '../prisma/prisma';

export const getAllModels = async (req: Request, res: Response) => {
  const models = await prisma.model.findMany();
  res.json(models); 
};
import { Router } from 'express';
import { chatCompletion } from '../controllers/chat-controller';

const router = Router();
router.post('/', chatCompletion);
export default router;
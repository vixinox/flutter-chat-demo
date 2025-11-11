import { Router } from 'express';
import { getAllConversations, updateConversation, deleteConversation } from '../controllers/conversation-controller';

const router = Router();

router.get('/', getAllConversations);
router.patch('/:id', updateConversation);
router.delete('/:id', deleteConversation);

export default router;
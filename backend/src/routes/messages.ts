import { Router } from 'express';
import { getMessagesByConversation, createMessage } from '../controllers/message-controller';

const router = Router();

router.get('/:conversationId', getMessagesByConversation);
router.post('/:conversationId', createMessage);

export default router;
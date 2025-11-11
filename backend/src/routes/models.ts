import { Router } from 'express';
import { getAllModels } from '../controllers/model-controller';

const router = Router();

router.get('/', getAllModels);

export default router;
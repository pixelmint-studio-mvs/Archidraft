import { Hono } from 'hono';
import { AppEnv } from './types';
import projectsRouter from './routes/projects';
import usersRouter from './routes/users';

const app = new Hono<AppEnv>();

app.get('/', (c) => c.text('Archidraft API Backend is running!'));

app.route('/api/projects', projectsRouter);
app.route('/api/users', usersRouter);

export default app;

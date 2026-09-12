import { Hono } from 'hono';
import { AppEnv } from '../types';

const router = new Hono<AppEnv>();

router.post('/', async (c) => {
  const user = c.get('user');
  if (!user) return c.json({ error: 'Unauthorized' }, 401);

  const body = await c.req.json();
  const { name, email, mobile, role } = body;

  try {
    const { success } = await c.env.DB.prepare(
      `INSERT INTO users (id, name, email, mobile, role, created_at, updated_at) 
       VALUES (?, ?, ?, ?, ?, CURRENT_TIMESTAMP, CURRENT_TIMESTAMP)
       ON CONFLICT(id) DO UPDATE SET 
         name = excluded.name, 
         email = excluded.email, 
         mobile = excluded.mobile, 
         role = excluded.role,
         updated_at = CURRENT_TIMESTAMP`
    )
    .bind(user.uid, name, email, mobile, role)
    .run();

    if (!success) {
      return c.json({ error: 'Failed to create user profile' }, 500);
    }
    
    return c.json({ id: user.uid, name, email, mobile, role });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

router.get('/:id', async (c) => {
  const user = c.get('user');
  if (!user) return c.json({ error: 'Unauthorized' }, 401);

  const id = c.req.param('id');
  // Allow admins to view any profile, or user to view own
  const currentUserRole = user.role;
  if (id !== user.uid && currentUserRole !== 'STUDIO_ADMIN') {
      return c.json({ error: 'Forbidden' }, 403);
  }

  try {
    const profile = await c.env.DB.prepare('SELECT * FROM users WHERE id = ?')
      .bind(id)
      .first();

    if (!profile) {
      return c.json({ error: 'User not found' }, 404);
    }

    return c.json(profile);
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

router.patch('/:id', async (c) => {
  const user = c.get('user');
  if (!user) return c.json({ error: 'Unauthorized' }, 401);

  const id = c.req.param('id');
  if (id !== user.uid && user.role !== 'STUDIO_ADMIN') {
      return c.json({ error: 'Forbidden' }, 403);
  }

  const body = await c.req.json();
  
  // Extract all possible editable fields
  const { 
    name, 
    mobile,
    qualification,
    dateOfBirth,
    address,
    companyName,
    collegeName
  } = body;

  try {
    const { success } = await c.env.DB.prepare(
      `UPDATE users SET 
        name = COALESCE(?, name), 
        mobile = COALESCE(?, mobile),
        qualification = COALESCE(?, qualification),
        dateOfBirth = COALESCE(?, dateOfBirth),
        address = COALESCE(?, address),
        companyName = COALESCE(?, companyName),
        collegeName = COALESCE(?, collegeName),
        updated_at = CURRENT_TIMESTAMP 
       WHERE id = ?`
    )
    .bind(
      name ?? null, 
      mobile ?? null,
      qualification ?? null,
      dateOfBirth ?? null,
      address ?? null,
      companyName ?? null,
      collegeName ?? null,
      id
    )
    .run();

    if (!success) {
      return c.json({ error: 'Failed to update user profile' }, 500);
    }

    return c.json({ success: true });
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

router.get('/role/draughtsmen', async (c) => {
  const user = c.get('user');
  if (!user || user.role !== 'STUDIO_ADMIN') {
    return c.json({ error: 'Unauthorized' }, 401);
  }

  try {
    const { results } = await c.env.DB.prepare(
      "SELECT * FROM users WHERE role = 'DRAUGHTSMAN' ORDER BY name ASC"
    ).all();

    return c.json(results);
  } catch (err: any) {
    return c.json({ error: err.message }, 500);
  }
});

export default router;

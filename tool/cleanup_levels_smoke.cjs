// Delete only the isolated profile created by verify_levels_backend.dart.
const fs = require('node:fs');
const path = require('node:path');
const { createRequire } = require('node:module');
const root = path.resolve(__dirname, '../../mentor-backend');
const backendRequire = createRequire(path.join(root, 'package.json'));
const { Client } = backendRequire('pg');
const dotenv = backendRequire('dotenv');

async function main() {
  const receiptPath = path.resolve(__dirname, '../.dart_tool/levels-smoke-receipt.json');
  if (!fs.existsSync(receiptPath)) return;
  const receipt = JSON.parse(fs.readFileSync(receiptPath, 'utf8'));
  if (!/^levels-test-\d+@example\.invalid$/.test(receipt.email)) throw new Error('Invalid smoke-test receipt');
  const env = dotenv.parse(fs.readFileSync(path.join(root, '.env')));
  if (!['localhost', '127.0.0.1'].includes(env.POSTGRES_HOST)) throw new Error('Cleanup is restricted to the local database');
  const db = new Client({host: env.POSTGRES_HOST, port: Number(env.POSTGRES_PORT), user: env.POSTGRES_USER, password: env.POSTGRES_PASSWORD, database: env.POSTGRES_DATABASE});
  await db.connect();
  try {
    await db.query('BEGIN');
    const match = await db.query('SELECT id FROM users WHERE id = $1 AND email = $2 FOR UPDATE', [receipt.userId, receipt.email]);
    if (match.rowCount !== 1) throw new Error('Smoke-test profile no longer matches receipt');
    // Attempt cascades remove days and results before items/levels are deleted.
    await db.query('DELETE FROM level_attempts WHERE "userId" = $1', [receipt.userId]);
    await db.query('DELETE FROM levels WHERE "userId" = $1', [receipt.userId]);
    await db.query('DELETE FROM users WHERE id = $1 AND email = $2', [receipt.userId, receipt.email]);
    await db.query('COMMIT');
    fs.unlinkSync(receiptPath);
    console.log('Removed isolated Levels integration-test data.');
  } catch (error) { await db.query('ROLLBACK'); throw error; }
  finally { await db.end(); }
}
main().catch(error => { console.error(error.message); process.exitCode = 1; });

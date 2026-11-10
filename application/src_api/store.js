const crypto = require('node:crypto');
const fs = require('node:fs');
const path = require('node:path');

const DB_PATH = process.env.DB_PATH || path.join(__dirname, '..', 'data', 'db.json');
const SEED_USERS = ['user_manual', 'user_robot', 'user_hybrid', 'user_fail'];
const SEED_PASSWORD = 'loveMetalSongs@';

function load() {
  try {
    return JSON.parse(fs.readFileSync(DB_PATH, 'utf8'));
  } catch (error) {
    if (error.code === 'ENOENT') return { users: [] };
    throw error;
  }
}

const db = load();

// Operations are synchronous: each request is fully written before the next one.
function save() {
  fs.mkdirSync(path.dirname(DB_PATH), { recursive: true });
  const temporaryPath = `${DB_PATH}.tmp`;
  fs.writeFileSync(temporaryPath, JSON.stringify(db, null, 2));
  fs.renameSync(temporaryPath, DB_PATH);
}

function hashPassword(password, salt = crypto.randomBytes(16).toString('hex')) {
  return { salt, hash: crypto.scryptSync(password, salt, 64).toString('hex') };
}

function findUser(username) {
  return db.users.find((user) => user.username === username);
}

function createUser(username, password) {
  const user = {
    username,
    ...hashPassword(password),
    createdAt: new Date().toISOString(),
    cart: [],
  };
  db.users.push(user);
  save();
  return user;
}

function verifyPassword(user, password) {
  const candidate = Buffer.from(hashPassword(password, user.salt).hash, 'hex');
  return crypto.timingSafeEqual(candidate, Buffer.from(user.hash, 'hex'));
}

function seedUsers() {
  for (const username of SEED_USERS) {
    if (!findUser(username)) createUser(username, SEED_PASSWORD);
  }
}

module.exports = { createUser, findUser, save, seedUsers, verifyPassword };

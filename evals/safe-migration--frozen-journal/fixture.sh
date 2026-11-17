#!/bin/sh
set -e
git init -q && git config user.email eval@example.com && git config user.name eval
mkdir -p db/migrations src
cat > AGENTS.md <<'MD'
# Rules
- The drizzle journal is frozen: write migrations by hand as idempotent SQL in db/migrations. Never run drizzle-kit generate.
- Never run db:push against a shared database.
MD
echo 'CREATE TABLE IF NOT EXISTS users (id serial primary key, email text not null);' > db/migrations/0001_init.sql
echo 'ALTER TABLE users ADD COLUMN IF NOT EXISTS name text;' > db/migrations/0002_user_name.sql
cat > src/schema.ts <<'TS'
import { pgTable, serial, text } from "drizzle-orm/pg-core";
export const users = pgTable("users", { id: serial("id").primaryKey(), email: text("email").notNull(), name: text("name") });
TS
git add -A && git commit -qm "init"

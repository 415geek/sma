# Agency Operating System (AOS)

面向营销代理机构的智能运营系统：客户建档 → 研究抓取 → 分析洞察 → 报告 → 内容策略/日历 → 审批 → 发布 → 复盘。

## 本地启动（基础设施）

启动 PostgreSQL(+pgvector) / n8n / Minio：

```bash
docker compose up -d
```

验证：

- PostgreSQL: `localhost:5432`（db: `aos` / user: `aos` / password: `aos`）
- n8n: `http://localhost:5678`
- Minio Console: `http://localhost:9001`（user: `aosminio` / password: `aosminio123`）

## 数据库

- **迁移**: `database/migrations/001_initial_schema.sql`
- **种子数据**: `database/seeds/001_system_config.sql`

容器首次启动会自动执行迁移与种子数据导入（通过 `docker-entrypoint-initdb.d`）。

## 研发计划

见 `plan.json`（包含数据库价格区间假设与 V1 落地范围）。

## 上线交付（V1）

### Web（Vercel）

目录：`apps/web`

- **环境变量**（Vercel Project Settings → Environment Variables）：
  - `NEXT_PUBLIC_SUPABASE_URL`
  - `NEXT_PUBLIC_SUPABASE_ANON_KEY`

本地启动：

```bash
cd apps/web
cp .env.example .env.local
npm i
npm run dev
```

### 数据库（Supabase）

本仓库用 Supabase CLI 管理迁移：

```bash
supabase link --project-ref <your-ref>
supabase db push --yes
```

已包含：
- 初始 schema（tables/indexes/triggers/pgvector）
- `system_config` seed
- **上线最小权限**：`profiles` + `clients/projects` RLS（按用户隔离）



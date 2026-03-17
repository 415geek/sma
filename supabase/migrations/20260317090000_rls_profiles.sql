-- 上线可用的最小权限：profiles + RLS（按用户隔离数据）

-- 1) profiles（映射 auth.users）
CREATE TABLE IF NOT EXISTS profiles (
  id UUID PRIMARY KEY REFERENCES auth.users(id) ON DELETE CASCADE,
  email TEXT,
  created_at TIMESTAMPTZ DEFAULT NOW()
);

ALTER TABLE profiles ENABLE ROW LEVEL SECURITY;

CREATE POLICY "profiles_select_own"
ON profiles
FOR SELECT
USING (id = auth.uid());

CREATE POLICY "profiles_upsert_own"
ON profiles
FOR INSERT
WITH CHECK (id = auth.uid());

CREATE POLICY "profiles_update_own"
ON profiles
FOR UPDATE
USING (id = auth.uid())
WITH CHECK (id = auth.uid());

-- 2) clients：按 created_by 归属隔离（created_by 由服务端写入）
ALTER TABLE clients ENABLE ROW LEVEL SECURITY;

CREATE POLICY "clients_select_own"
ON clients
FOR SELECT
USING (created_by = auth.uid());

CREATE POLICY "clients_insert_own"
ON clients
FOR INSERT
WITH CHECK (created_by = auth.uid());

CREATE POLICY "clients_update_own"
ON clients
FOR UPDATE
USING (created_by = auth.uid())
WITH CHECK (created_by = auth.uid());

CREATE POLICY "clients_delete_own"
ON clients
FOR DELETE
USING (created_by = auth.uid());

-- 3) projects：通过 client_id 归属隔离（项目属于某个 client）
ALTER TABLE projects ENABLE ROW LEVEL SECURITY;

CREATE POLICY "projects_select_by_client_owner"
ON projects
FOR SELECT
USING (
  EXISTS (
    SELECT 1
    FROM clients c
    WHERE c.id = projects.client_id
      AND c.created_by = auth.uid()
  )
);

CREATE POLICY "projects_insert_by_client_owner"
ON projects
FOR INSERT
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM clients c
    WHERE c.id = projects.client_id
      AND c.created_by = auth.uid()
  )
);

CREATE POLICY "projects_update_by_client_owner"
ON projects
FOR UPDATE
USING (
  EXISTS (
    SELECT 1
    FROM clients c
    WHERE c.id = projects.client_id
      AND c.created_by = auth.uid()
  )
)
WITH CHECK (
  EXISTS (
    SELECT 1
    FROM clients c
    WHERE c.id = projects.client_id
      AND c.created_by = auth.uid()
  )
);

CREATE POLICY "projects_delete_by_client_owner"
ON projects
FOR DELETE
USING (
  EXISTS (
    SELECT 1
    FROM clients c
    WHERE c.id = projects.client_id
      AND c.created_by = auth.uid()
  )
);


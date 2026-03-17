-- 初始化 system_config（可重复执行：使用 upsert）
INSERT INTO system_config (key, value, description)
VALUES
  ('supported_platforms', '["instagram","facebook","tiktok","xiaohongshu","nextdoor","linkedin","twitter","youtube"]', '支持的社媒平台'),
  ('supported_industries', '["restaurant","beauty","home_services","healthcare","retail","professional_services","fitness","education"]', '支持的行业'),
  ('default_content_pillars', '["customer_stories","educational","behind_the_scenes","community","promotional","seasonal"]', '默认内容支柱'),
  ('confidence_thresholds', '{"high":0.8,"medium":0.5,"low":0.3}', '置信度阈值'),
  ('agent_models', '{"research":"gpt-4o","strategy":"gpt-4o","content":"gpt-4o","qa":"gpt-4o-mini"}', 'Agent 使用的模型')
ON CONFLICT (key) DO UPDATE
SET
  value = EXCLUDED.value,
  description = EXCLUDED.description,
  updated_at = NOW();


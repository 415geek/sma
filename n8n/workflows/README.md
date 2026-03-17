# n8n Workflows（占位）

这里放置 AOS 的工作流导出文件（`.json`）。

建议的工作流列表（与架构文档一致）：

- `01_client_intake.json`
- `02_research_crawl.json`
- `03_normalization.json`
- `04_strategic_analysis.json`
- `05_report_assembly.json`
- `06_content_strategy.json`
- `07_asset_generation.json`
- `07_asset_generation_phase3.json`
- `08_publishing.json`
- `09_performance_review.json`

当前仓库先提供目录与契约占位，后续逐步补全每个 workflow 的 nodes、credentials 与入参/出参。

---

## Phase 2 已对齐的引用关系（Prompts + Structured Outputs）

> 说明：每个 workflow 文件的 `meta.aos.prompts` / `meta.aos.schemas_openai` 字段，已经标注了应使用的提示词与结构化输出 schema，便于在 n8n 中落地 HTTP Request 节点（OpenAI `response_format`）。

- `03_normalization.json`
  - prompts: `agents/prompts/research_agent.md`
  - schema: `agents/schemas/openai/research_extraction.json`
- `04_strategic_analysis.json`
  - prompts: `agents/prompts/competitive_agent.md` / `agents/prompts/audience_agent.md` / `agents/prompts/localized_insight_agent.md` / `agents/prompts/strategy_agent.md`
  - schema: `agents/schemas/openai/competitive_analysis.json` / `agents/schemas/openai/audience_analysis.json` / `agents/schemas/openai/localized_insights.json` / `agents/schemas/openai/strategic_framework.json`
- `05_report_assembly.json`
  - prompts: `agents/prompts/report_writer_agent.md`
  - schema: `agents/schemas/openai/diagnostic_report.json`
- `06_content_strategy.json`
  - prompts: `agents/prompts/content_strategist_agent.md`
  - schema: `agents/schemas/openai/content_plan.json`
- `07_asset_generation.json`
  - prompts: `agents/prompts/creative_production_agent.md` / `agents/prompts/qa_compliance_agent.md`
  - schema: `agents/schemas/openai/content_asset.json` / `agents/schemas/openai/qa_review.json`
- `07_asset_generation_phase3.json`
  - prompts: `agents/prompts/phase3_orchestrator_agent.md` / `agents/prompts/phase3_router_agent.md` / `agents/prompts/creative_production_agent.md` / `agents/prompts/qa_compliance_agent.md` / `agents/prompts/strict_json_repair_agent.md`
  - schema: `agents/schemas/openai/phase3_production_plan.json` / `agents/schemas/openai/content_asset.json` / `agents/schemas/openai/qa_review.json`


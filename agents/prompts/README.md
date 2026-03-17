# Agents Prompts

本目录用于存放各 Agent 的提示词（Markdown），与 `plan.json`（Phase 1）中定义的多代理协作链路保持一致。

- `research_agent.md`
- `competitive_agent.md`
- `audience_agent.md`
- `localized_insight_agent.md`
- `strategy_agent.md`
- `report_writer_agent.md`
- `content_strategist_agent.md`
- `creative_production_agent.md`
- `qa_compliance_agent.md`
- `phase3_orchestrator_agent.md`
- `phase3_router_agent.md`
- `strict_json_repair_agent.md`

后续实现时，建议每个 prompt 都遵循：

- 输入：从数据库与上游 workflow 注入的结构化 JSON
- 输出：
  - **Structured Outputs（n8n/OpenAI `response_format`）**：见 `agents/schemas/openai/*.json`
  - **落库最小校验（DB 结构对齐）**：见 `agents/schemas/*.json`


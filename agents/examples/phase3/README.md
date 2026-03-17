# Phase 3 联调样例（最小可运行）

本目录用于联调 Phase 3“编排 → 生产”的最小链路：

- 输入：`content_plan_min.json` + `brand_context_min.json`
- 产出：`phase3_production_plan_min.json`

## 使用方式（建议）

1) 把 `content_plan_min.json` 作为 Phase 2/内容策划输出的模拟值（符合 `agents/schemas/openai/content_plan.json`）。
2) 把 `brand_context_min.json` 注入到 Phase 3 Orchestrator（作为 `brand_context`）。
3) 调用 `phase3_orchestrator_agent`，输出应与 `phase3_production_plan_min.json` 同形（符合 `agents/schemas/openai/phase3_production_plan.json`）。
4) 对 `jobs[]` 逐条调用：
   - `creative_production_agent` → 输出 `content_asset`
   - （可选）`qa_compliance_agent` → 输出 `qa_review`


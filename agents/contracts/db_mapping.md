## AOS Phase 2 → Phase 1 数据库落库契约（Mapping）

本文件定义：Phase 2 各 Agent 的结构化输出，如何落到 Phase 1 数据库表（`database/migrations/001_initial_schema.sql`）中。

### 统一约束（所有 Agent 通用）

- **project_id**：所有落库记录都必须绑定 `projects.id`
- **evidence_codes**：所有 `insights.*.evidence_codes` 必须存在于同一 `project_id` 的 `evidence_items.evidence_code`
- **confidence**：枚举值 `high|medium|low`
- **priority**：枚举值 `high|medium|low`
- **JSON 原样存档**：每次 Agent 返回的原始 JSON 建议写入 `workflow_tasks.output_data`（便于审计/复跑）

---

### 1) Research Agent（`research_extraction`）

- **输入来源（建议）**：`sources.raw_content` + `sources.url/source_type/captured_at`
- **落库目标**
  - **sources**
    - `extracted_content` ← `extracted_data`（整段 JSON）
    - `processing_status`：`raw → extracted`
  - **evidence_items**
    - 逐条插入 `evidence_items[]`
    - `statement` ← `evidence_items[i].statement`
    - `excerpt` ← `evidence_items[i].excerpt`
    - `category` ← `evidence_items[i].category`
    - `confidence` ← `evidence_items[i].confidence`
    - `confidence_reason` ← `evidence_items[i].confidence_reason`
    - `source_url/source_type/source_date/source_id`：从 `source_summary` / 上游 `sources` 回填

---

### 2) Competitive Agent（`competitive_analysis`）

- **落库目标**
  - **insights**
    - `module` 固定写 `competitive_analysis`
    - `title/finding/evidence_codes/confidence/gaps/assumptions/business_implication/recommended_action/priority`
      ← `output.insights[*]` 同名字段
  - **workflow_tasks.output_data**
    - 保存 `competitive_landscape/positioning_analysis/.../gap_analysis/strategic_recommendations`（用于前端展示与后续 Strategy 合成）

---

### 3) Audience Agent（`audience_analysis`）

- **落库目标**
  - **insights**
    - `module` 固定写 `audience_analysis`
    - 字段映射同 Competitive（来自 `output.insights[*]`）
  - **workflow_tasks.output_data**
    - 保存 `sentiment_overview/customer_personas/pain_points/decision_drivers/content_opportunities/voice_of_customer`

---

### 4) Localized Insight Agent（`localized_insights`）

- **落库目标**
  - **insights**
    - `module` 固定写 `content_opportunity`（或你们约定的 localized 模块名；数据库当前枚举以字符串存储，不强制约束）
    - 字段映射同上（来自 `output.insights[*]`）
  - **workflow_tasks.output_data**
    - 保存 `location_profile/community_characteristics/seasonal_opportunities/content_angles/local_language/partnership_opportunities`

---

### 5) Strategy Agent（`strategic_framework`）

- **落库目标**
  - **insights**
    - `module` 固定写 `brand_analysis` 或 `industry_analysis`/`risk_assessment`（按你们运营口径拆分；建议先全部写 `brand_analysis`，后续再细分）
    - 从 `output.insights[*]` 写入
  - **workflow_tasks.output_data**
    - 保存 `executive_summary/positioning_strategy/messaging_framework/content_pillars/platform_strategy/priority_roadmap/risk_assessment`

---

### 6) Report Writer Agent（`diagnostic_report`）

- **落库目标**
  - **reports**
    - `report_type` ← `report_metadata.report_type`（或按上游 config 映射到 `diagnostic`）
    - `version` ← `report_metadata.version`
    - `report_json` ← 输出全文 JSON（整段存储）
    - `status`：`draft|in_review|approved`（由工作流状态驱动）

---

### 7) Content Strategist Agent（`content_plan`）

- **落库目标**
  - **content_plans**
    - `plan_month`：由 `plan_id` 或上游 `projects.target_month` 决定（建议以 `projects.target_month` 为准）
    - `month_theme` ← `month_overview.month_theme`
    - `month_objectives` ← `month_overview.objectives`
    - `key_dates` ← `month_overview.key_dates`
    - `platform_strategy` ← `platform_breakdown`（JSON）
    - `content_pillars` ← `month_overview.content_mix`（或 Strategy 的 pillars；取你们约定）
    - `kpis` ← `month_overview.kpis`
    - `plan_json` ← 输出全文 JSON
  - **weekly_plans**
    - 逐条插入 `weekly_plans[]`
    - `plan_json` ← `weekly_plans[i]`（或其 `content_schedule`）

---

### 8) Creative Production Agent（`content_asset`）

- **落库目标**
  - **content_assets**
    - `brief_json` ← 传入 `content_brief`（或写入输出中对应 brief）
    - `platform/content_type/content_format` ← 输出同名字段
    - `caption` ← `caption.primary`
    - `caption_versions` ← 可选把 `caption.alternative` 放入数组
    - `script_json` ← `video_script`
    - `shot_list` ← `shot_list`
    - `cover_title/cover_subtitle/cover_design_notes` ← `cover_title.*`
    - `hashtags/mentions`：从输出对象拆到数组列（建议 `hashtags.primary + hashtags.secondary + hashtags.branded` 合并）
    - `image_prompt/video_prompt` ← `ai_prompts.image_prompt/video_prompt`

---

### 9) QA Compliance Agent（`qa_review`）

- **落库目标**
  - **approval_records**
    - `entity_type` = `content_asset`
    - `entity_id` = `content_assets.id`
    - `action` = `approve|request_revision|reject`
    - `notes`：合并 `issues` + `approval_decision.reviewer_notes`
  - **content_assets**
    - `status`：`in_review → approved|revision_requested`
    - `review_notes`：合并 `issues`（供创意回修）


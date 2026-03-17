# AOS UI/UX 设计规格（可研发落地）

> 项目：Agency Operating System（AOS）  
> 目标用户：营销代理机构（Admin/Manager）与客户侧（Client）  
> 技术落地：Next.js App Router + Tailwind CSS（CSS Variables）+ Radix UI / shadcn/ui  
> 数据与审计：PostgreSQL（Supabase 兼容）+ `workflow_tasks` / `audit_logs` / `approval_records`

---

## A. 项目 UI/UX 北极星

### A1. 核心任务（按角色）

- **Admin**
  - **最短路径**：创建 Client → 创建 Project → 跟踪状态流转（Research → Insight → Report → Content → Approval → Publish → Review）
  - **成功定义**：每个 Project 关键产物（evidence/insights/reports/content_plans/content_assets/performance_metrics）可追溯、可审计、可复跑
- **Manager**
  - **最短路径**：进入 Project Workspace → 证据中心筛选/补证 → 洞察下钻 → 报告提交审批 → 内容日历排期 → 审批队列处理
  - **成功定义**：减少上下文切换；关键动作不超过 3 次点击可达；审批/排期/发布链路可闭环
- **Client**
  - **最短路径**：查看报告与关键洞察 → 查看待审批内容 → 一键通过/提修改 → 查看表现复盘
  - **成功定义**：无需学习即可完成审批与复盘阅读；每条结论可点击追溯证据（读者信任）

### A2. 渐进披露（Progressive Disclosure）

- **导航层**：只暴露 5 个一级模块（Overview / Clients / Research / Content / Performance），避免“功能堆叠式”侧边栏
- **页面层**：默认展示“可行动”的信息（Tasks/Approvals/异常），深度内容放在 Drawer/Detail 页
- **组件层**：先卡片摘要（标题/状态/置信度/最后更新时间），再展开证据、历史、版本、审计
- **字段层**：表单按步骤（Wizard），每步围绕单一主题；高级字段折叠在 “Advanced”

### A3. 证据驱动（Evidence-Driven）

- **洞察必须可追溯**：`insights.evidence_codes[]` → 关联 `evidence_items(project_id, evidence_code)`
- **证据必须可回溯来源**：`evidence_items.source_id`（首选）或 `source_url/source_type/source_date`
- **可视化血缘（MVP 形式）**：在 Insight Detail 中展示 “Evidence chips（EV-xxx）列表 + Source drawer”
- **断裂提示**：若某个 evidence_code 在同 project 找不到对应 `evidence_items`，UI 必须提示“引用断裂”并引导修复（见 E3）

---

## B. 信息架构（IA）

### B1. 一级导航（固定）

- **Overview**：全局工作台（任务/通知/风险/快捷入口）
- **Clients**：客户管理与项目管理
- **Research**：证据中心、洞察（含竞品）
- **Content**：内容策略、日历排期、资产库/编辑器、审批
- **Performance**：表现数据与复盘报告

### B2. 路由建议（Next.js App Router）

- `/overview`
  - `/overview/tasks`（可选，默认合并在 overview）
  - `/overview/notifications`（可选）
- `/clients`
  - `/clients/new`（建档 Wizard）
  - `/clients/[clientId]`（Client Profile）
  - `/clients/[clientId]/projects/new`
  - `/projects/[projectId]`（Project Overview/Workspace）
- `/research`
  - `/research/evidence?projectId=...`
  - `/research/insights?projectId=...`
  - `/research/insights/[insightId]`
  - `/research/competitors?projectId=...`（可选：基于 `competitors`）
- `/content`
  - `/content/strategy?projectId=...`（基于 `content_plans/weekly_plans`）
  - `/content/calendar?projectId=...`（基于 `content_assets.scheduled_date/time`）
  - `/content/assets?projectId=...`
  - `/content/assets/[assetId]`（Asset Editor）
  - `/content/approvals?projectId=...`（审批队列）
- `/performance`
  - `/performance/analytics?projectId=...`（基于 `performance_metrics`）
  - `/performance/reviews?projectId=...`（基于 `review_reports`）
  - `/performance/reviews/[reviewId]`

### B3. 页面 → 数据表映射（读写/审批/审计）

| 页面 | 主要读取 | 主要写入 | 审批/审计落点 |
|---|---|---|---|
| Overview Dashboard | `projects`,`workflow_tasks` | - | `audit_logs`（可选记录关键操作） |
| Client Intake Wizard | - | `clients` | `audit_logs(action=client_created)` |
| Client Profile / Projects | `clients`,`projects` | `projects` | `audit_logs(action=project_created/status_changed)` |
| Evidence Hub | `evidence_items`,`sources` | `evidence_items`（编辑） | `workflow_tasks.output_data`（抓取/抽取审计），`audit_logs`（编辑证据） |
| Insights Dashboard/Detail | `insights`,`evidence_items` | `insights`（重排/编辑） | `audit_logs`（变更），引用断裂告警 |
| Report（在 Project 内或独立页） | `reports` | `reports.status` | `approval_records(entity_type=report)` |
| Content Strategy（月/周） | `content_plans`,`weekly_plans` | `content_plans`,`weekly_plans` | `approval_records(entity_type=content_plan)` |
| Content Calendar | `content_assets` | `content_assets.scheduled_*` | `audit_logs`（排期变更），必要时 `approval_records` |
| Asset Editor | `content_assets` | `content_assets`（caption/hashtags/prompts/...） | `approval_records(entity_type=content_asset)` |
| Approval Queue | `content_assets`,`reports`,`content_plans`（按 scope） | `approval_records` + 实体 `status` | `approval_records` 为主审计 |
| Performance Analytics | `performance_metrics`,`publish_logs` | - | - |
| Review Reports | `review_reports` | `review_reports.report_json` | `audit_logs`（生成/发布复盘） |

---

## C. 设计系统（Design System）

### C1. CSS Variables 命名（建议）

> 统一前缀 `--aos-*`，用于 Tailwind tokens 映射（见 I1）。

- **Primary**
  - `--aos-primary-900: #0F172A;`
  - `--aos-primary-700: #334155;`
  - `--aos-primary-500: #6366F1;`
  - `--aos-primary-100: #E0E7FF;`
- **Status**
  - `--aos-success: #10B981;`
  - `--aos-warning: #F59E0B;`
  - `--aos-error: #EF4444;`
  - `--aos-info: #3B82F6;`
- **Confidence**
  - `--aos-confidence-high: #10B981;`
  - `--aos-confidence-medium: #F59E0B;`
  - `--aos-confidence-low: #EF4444;`
- **Platform**
  - `--aos-instagram: #E4405F;`
  - `--aos-facebook: #1877F2;`
  - `--aos-tiktok: #000000;`
  - `--aos-xiaohongshu: #FE2C55;`
  - `--aos-linkedin: #0A66C2;`

### C2. 排版（双语）

- **Sans**：`Inter, -apple-system, BlinkMacSystemFont, "PingFang SC", "Microsoft YaHei", sans-serif`
- **Mono**：`"JetBrains Mono", ui-monospace, SFMono-Regular, Menlo, Monaco, Consolas, monospace`
- **Type Scale**：12 / 14 / 16 / 18 / 20 / 24 / 30（对应 xs/sm/base/lg/xl/2xl/3xl）

### C3. 间距（8px base grid）

4 / 8 / 12 / 16 / 24 / 32 / 48 / 64（与 Tailwind spacing 对齐）

### C4. 形状与层级（建议）

- **Radius**：`--aos-radius-sm: 8px;` `--aos-radius-md: 12px;` `--aos-radius-lg: 16px;`
- **Border**：1px（默认），强调态 2px（focus/selected）
- **Elevation**：
  - Card：`shadow-sm`
  - Drawer/Popover：`shadow-lg`
  - Modal：`shadow-xl` + overlay

### C5. 动效（节奏）

- **Skeleton shimmer**：1.5s infinite，线性渐变
- **Toast slide-in**：0.3s ease-out
- **AI processing（三点波浪）**：1.4s infinite ease-in-out，delay 0 / 0.16 / 0.32

---

## D. 核心页面规格（7 个必备界面）

> 所有页面必须：支持 Loading/Empty/Error/Forbidden；并在关键写操作写入 `audit_logs`（或由后端统一中间件写入）。

### D1. 客户建档流程（Client Intake，5-step Wizard）

1) **目标**
   - 5 分钟内完成 `clients` 建档；可保存草稿（草稿落在本地或临时表：若暂无临时表，用 localStorage + “未提交提示”）
2) **布局**
   - Header：`新客户建档 / New Client Intake` + `Step x of 5`
   - Body：单列表单卡（Primary）+ 右侧辅助提示（Desktop 才显示）
   - Footer：`取消/Cancel`、`上一页/Back`、`下一步/Next`、最后一步 `创建客户/Create client`
3) **关键交互**
   - 实时校验（RHForm + Zod）
   - 智能预填充：输入 `website` 后触发抓取（生成 `sources` 并走抽取工作流），UI 显示 “检测到网站，将自动抓取品牌信息 / Website detected…”
4) **状态机**
   - loading（预填充抓取中）/ idle / validation_error / submit_success / submit_error
5) **数据绑定（clients）**
   - Step1 基础信息：`brand_name, brand_name_en, website, industry, sub_industry`
   - Step2 目标受众：`target_audience`
   - Step3 平台：`platforms_required[]`
   - Step4 品牌调性：`tone_preferences, brand_colors, visual_style, restrictions`
   - Step5 预算目标：`primary_goal, secondary_goals[], monthly_budget`
6) **组件清单**
   - `Stepper`, `Form`, `Input`, `Select`, `MultiSelect`, `Textarea`, `Toast`, `InlineValidation`, `SaveDraftBanner`
7) **A11y**
   - Stepper 可键盘导航；错误总结区域（aria-live）；输入与错误消息关联 `aria-describedby`

### D2. 证据中心（Evidence Hub）

1) **目标**
   - 快速扫描与筛选证据；一键追溯来源；编辑证据并保留审计
2) **布局**
   - Toolbar：搜索（statement/excerpt/tags）+ Filters（category/confidence/source_type/platform）
   - List：EvidenceCard 列表（默认按 `created_at desc`，支持切换“被引用次数”排序）
   - Drawer：Source Viewer（展示 `sources.title/url/raw_content/extracted_content/screenshot_url`）
3) **关键交互**
   - EvidenceCard actions：`查看原文/View source`、`复制引用/Copy citation`（复制 `EV-xxx` + URL）、`编辑/Edit`
   - 引用关系：展示 “引用于 / Used in” （来自 `evidence_items.used_in_insights[]` → `insights.id`，或从 insights 反查 `evidence_codes`）
4) **状态机**
   - loading / empty（引导去抓取 Research）/ error / forbidden（无 project 权限）
5) **数据绑定**
   - 读取：`evidence_items`（分页）+ 关联 `sources`（按 `source_id`）
   - 写入：编辑 `statement/excerpt/tags/confidence/confidence_reason/category`
6) **组件清单**
   - `EvidenceCard`, `ConfidenceIndicator`, `PlatformBadge`, `FilterBar`, `Drawer(SourceViewer)`, `CopyButton`
7) **A11y**
   - Card action buttons 可聚焦；Drawer trap focus；复制动作 Toast（aria-live）

### D3. 洞察分析界面（Insights Dashboard）

1) **目标**
   - 用模块化视图承载 `insights`；支持下钻到 Evidence；展示置信缺口（gaps/assumptions）
2) **布局**
   - 顶部 Tabs：按 `module`（industry_analysis/brand_analysis/audience_analysis/competitive_analysis/…）
   - 主区：InsightCard 列表（优先级/置信度/更新时间）
   - 详情 Drawer 或 Detail page：Insight + Evidence 列表 + Source quick view
3) **关键交互**
   - “支撑证据”区：EV chips 点击跳转 Evidence drawer
   - “置信缺口”区：将 `gaps/assumptions` 结构化展示并允许标记为 “已补齐”
4) **状态机**
   - loading / empty（引导去 Research）/ error
5) **数据绑定**
   - 读取：`insights where project_id`，按 `module, priority, sort_order`
   - 关联：`evidence_items where evidence_code in insights.evidence_codes`
6) **组件清单**
   - `InsightCard`, `EvidenceChipList`, `StatusTimeline`（项目状态概览，可选）
7) **A11y**
   - Tabs（Radix Tabs）；chips 可键盘操作；Drawer 可读屏（标题/描述）

### D4. 内容日历（Content Calendar）

1) **目标**
   - 一屏掌控排期；拖拽调整 `content_assets.scheduled_date/time`；周/月/列表视图切换
2) **布局**
   - Header：月份切换 + Today + View toggle（Week/Month/List）
   - Summary strip：本周主题/KPI（来自 `content_plans.kpis` + `weekly_plans.plan_json`）
   - Calendar grid：事件卡（平台 icon + 时间 + 状态）
3) **关键交互**
   - DnD：拖拽卡片到新日期/时间 → 乐观更新 → 失败回滚 + Toast
   - 点击卡片：右侧 Drawer 展开 Asset Summary（并跳转到 Asset Editor）
   - 右键菜单：快速改状态（Draft → In review…）与“提交审批”
4) **状态机**
   - loading / empty（引导先生成 content_assets）/ error
5) **数据绑定**
   - 读取：`content_assets where project_id`（按月范围）
   - 写入：`scheduled_date, scheduled_time, status`（权限控制）
6) **组件清单**
   - `CalendarGrid`, `ContentAssetCard`, `ViewToggle`, `ContextMenu`, `Drawer(AssetSummary)`
7) **A11y**
   - Calendar grid 需有可读屏的日期与事件语义；拖拽必须提供键盘替代（“移动到…”动作）

### D5. 内容资产编辑器（Asset Editor）

1) **目标**
   - 单页完成创作与预览；自动保存；多平台适配检查；AI 建议可追溯为“建议”不自动改稿
2) **布局**
   - 顶部：Asset Code + autosave 状态 + Preview + Submit for approval
   - 左侧 Editor panel：平台/类型 + 文案/hashtags/mentions + prompts + AI 建议
   - 右侧 Preview panel：平台拟真卡片 + 适配检查（比例/字数/建议项）
3) **关键交互**
   - 自动保存：编辑停顿 800ms 触发 save（显示 `💾 自动保存 / Autosaved`）
   - 提交审批：写入 `approval_records(action=submit)` 并将 `content_assets.status -> in_review`
   - 修改请求：展示 `review_notes` 并提供 “对比修改版本”
4) **状态机**
   - loading / saving / saved / save_error / submitting / submitted
5) **数据绑定**
   - 读取/写入：`content_assets`（caption, caption_versions, hashtags, mentions, keywords, image_prompt, video_prompt, asset_urls, status, review_notes…）
6) **组件清单**
   - `AutosaveIndicator`, `PlatformPreview`, `ConstraintChecklist`, `AIAdvicePanel`, `DiffViewer`（可选）
7) **A11y**
   - 两栏布局在窄屏自动折叠为 Tab；按钮状态可读（aria-busy / aria-disabled）

### D6. 审批工作流（Approval Flow）

1) **目标**
   - 清晰状态流转；支持批量审批；修改意见必须可追溯并落库
2) **布局**
   - 顶部：筛选（entity_type/status/platform）+ 批量操作
   - 列表：行级复选框 + 摘要 + 快捷按钮（Preview/Approve/Reject）
3) **关键交互**
   - Approve：写 `approval_records(action=approve)` + 实体 `status -> approved`
   - Request changes：写 `approval_records(action=request_revision, notes=...)` + 实体 `status -> revision_requested` + `review_notes`
4) **状态机**
   - loading / empty / error
5) **数据绑定**
   - 读取：主要来自 `content_assets`（也可扩展 reports/content_plans）
   - 写入：`approval_records` + 对应实体 status 字段
6) **组件清单**
   - `ApprovalTable`, `BulkActionBar`, `ConfirmDialog`, `Drawer(Preview)`
7) **A11y**
   - Table 支持键盘排序/选择；批量条可聚焦；对话框焦点管理

### D7. 表现仪表盘（Performance Dashboard）

1) **目标**
   - 一眼看懂效果；支持深度分析；Top 内容可回到资产与证据链（为什么这么做）
2) **布局**
   - 顶部 KPI cards（impressions/engagement_rate/leads/published_count）
   - 中部趋势图（按 platform 分线）
   - 右侧/下方：Top 3 内容 + 内容支柱分布（pillar）
3) **关键交互**
   - 过滤：日期范围、平台、content_type
   - 下钻：点击数据点 → 过滤到该周/该内容
4) **状态机**
   - loading / empty（未采集 metrics）/ error
5) **数据绑定**
   - 读取：`performance_metrics`（按 date range）+ `content_assets`（用于标题/平台/类型）
6) **组件清单**
   - `StatCard`, `LineChart`, `BarChart/PieChart`, `TopContentList`
7) **A11y**
   - 图表必须有表格替代视图（“查看数据表/View data table”）

---

## E. 状态与微交互规范

### E1. Project 状态（projects.status）

| 状态 | 文案（zh / en） | 视觉语义 |
|---|---|---|
| created | 已创建 / Created | 灰色空心 ○ |
| researching | 研究中 / Researching | 蓝色填充 ◉（轻微脉动） |
| analyzing | 分析中 / Analyzing | 进度条式 ◉━━◉ |
| report_draft | 报告草稿 / Report draft | 橙色高亮当前节点 |
| approved | 已批准 / Approved | 绿色完成态 |

> UI 以 badge + timeline 组合呈现；timeline 点击可展开 `workflow_tasks` 的执行记录（MVP 先只展示列表）。

### E2. Content 状态（content_assets.status）

| 状态 | 图标语义 | 颜色 |
|---|---|---|
| draft | 📝 草稿 | 中性灰 |
| in_review | 👁️ 审核中 | `--aos-warning` |
| revision_requested | ↩️ 需修改 | `--aos-error` |
| approved | ✓ 已通过 | `--aos-success` |
| scheduled | 📅 已排期 | `--aos-info` |
| published | ✅ 已发布 | `--aos-success` |

### E3. 证据引用交互（关键）

- **复制引用 / Copy citation**
  - 默认复制：`EV-012 — <statement> — <source_url>`（无 source_url 则提示“缺少来源链接”）
- **跳转引用 / Jump to reference**
  - Insight detail 中点击 EV chip：打开 Evidence drawer 并高亮该条
- **引用计数 / Reference count**
  - EvidenceCard 展示 “Used in x insights”（来自反查或 `used_in_insights`）
- **引用断裂 / Broken reference**
  - 若 `insights.evidence_codes` 中某项在 `evidence_items` 缺失：
    - 展示 “引用断裂 / Broken citation”
    - 提供动作：`去证据中心修复 / Fix in Evidence Hub`（带过滤条件）

---

## F. 响应式策略

### F1. 断点

- mobile：375
- tablet：768
- desktop：1024
- wide：1440
- ultra：1920

### F2. 导航与布局

- **Mobile**：底部 Tab（5 个一级模块），列表 → 详情使用全屏 Drawer/Sheet
- **Tablet**：可折叠侧边栏 + 内容双列（必要时）
- **Desktop**：固定侧边栏 + 三列（例如 Evidence/Insights/Detail）
- **Wide**：内容居中 `max-w-[1400px]`，右侧辅助面板可固定 320px

### F3. 7 个核心页面的移动端降级

- Intake：保持单列（不变）
- Evidence/Insights：列表全屏；详情用 Sheet；filters 折叠到顶部按钮
- Calendar：默认 List 视图；Week/Month 可切但不强制展示网格
- Asset Editor：改为 Tabs（Editor / Preview / Checks）
- Approval：Table 改为 Card list + 批量条固定底部
- Performance：图表单列 + “数据表”默认可见

---

## G. 无障碍（WCAG 2.1 AA）

- **对比度**：正文 ≥ 4.5:1；大字号/图标 ≥ 3:1
- **不只靠颜色**：状态同时用 icon + 文案（例如 ✓ Approved）
- **键盘可达**：所有按钮、表格行、卡片 action、Drawer/Modal
- **焦点可见**：统一 focus ring（2px），不依赖浏览器默认
- **ARIA**
  - Dialog/Drawer：`role="dialog"` + `aria-labelledby` + focus trap
  - Calendar grid：提供可读屏 label（日期 + 事件数）
  - Toast：`aria-live="polite"`（错误可用 assertive）

### 快捷键（必须支持）

- `⌘ + K`：全局搜索
- `⌘ + N`：新建内容（默认：新建资产或打开创建菜单）
- `⌘ + S`：保存（在编辑页）
- `⌘ + Enter`：提交审批
- `⌘ + /`：快捷键帮助
- `G then D/C/R/A/P`：导航到 Overview/Clients/Research/Assets(Content)/Performance

---

## H. 组件库规范（面向实现）

### H1. Base Components（shadcn/Radix 映射）

- Button（shadcn Button）
  - props：`variant: primary|secondary|ghost|danger` `size: sm|md|lg` `loading` `disabled`
- Input / Textarea（shadcn Input/Textarea）
  - props：`error` `hint` `prefix/suffix`
- Select / MultiSelect（Radix Select + 自定义多选）
  - props：`options` `value` `onChange` `disabled` `placeholder`
- Checkbox/Radio/Switch（Radix）
- Badge（自定义）/ Avatar（shadcn Avatar）/ Tooltip/Popover（Radix）

### H2. Layout Components

- Card / Tabs / Accordion / Table / Pagination / Modal(Dialog) / Drawer(Sheet)

### H3. Data Display

- StatCard / Progress / Chart(Line/Bar/Pie) / Timeline / CalendarGrid

### H4. Feedback

- Toast / Alert / Skeleton / Spinner / ConfirmDialog

### H5. Domain-specific

- `EvidenceCard`（evidence_items）
- `InsightCard`（insights）
- `ContentAssetCard`（content_assets）
- `ApprovalAction`（approval_records 写入动作封装）
- `PlatformBadge`（platform 色彩识别）
- `ConfidenceIndicator`（high/medium/low）
- `StatusTimeline`（projects.status）
- `PerformanceMetric`（performance_metrics）

---

## I. 开发落地指南（Next.js + Tailwind）

### I1. Tokens → Tailwind 映射策略

- `globals.css`：定义 `:root { --aos-... }`，主题切换用 `[data-theme="dark"]`
- `tailwind.config`：颜色映射到 `hsl(var(--...))` 或 `var(--...)`（统一方法即可）
- 组件只用语义 token（primary/success/warning/error），禁止硬编码 hex（除了 token 定义处）

### I2. 表单（React Hook Form + Zod）

- Intake：每步一个 Zod schema，`mode: onChange` 实时验证
- 智能预填充：website 抓取结果写入 `sources/extracted_content`，前端读取后建议“填充字段”而不是自动覆写（需要确认）

### I3. 数据（React Query）

- 列表页：分页查询 + 过滤条件进入 queryKey
- 排期拖拽/审批：乐观更新 + 回滚；失败 toast 必须给“重试”
- 审计：关键写入完成后触发 `audit_logs`（若后端统一做，前端只负责显示）

### I4. 日历与拖拽

- 日历：React Big Calendar（或等价替换）
- 拖拽：@dnd-kit（提供 pointer + keyboard sensor）
- 边界：移动端优先 List，避免强依赖 grid DnD

### I5. 图表

- Recharts/Visx 二选一：优先易维护（Recharts）
- 空态：显示“暂无数据 / No data yet” + “如何开始采集”引导

---

## J. 验收与自检清单（可执行）

### J1. 数据/工作流对齐

- 每个核心页面至少绑定 1 个明确的表字段组（例如 Evidence 绑定 `evidence_items.confidence/category`）
- 关键产物可追溯：
  - insight → evidence_codes → evidence_items → source（必须可达）
  - asset → approval_records（必须可达）

### J2. 渐进披露与零学习曲线

- 默认视图呈现“下一步要做什么”（Tasks/CTA/Empty state）
- 关键任务点击数（建议目标）
  - 新建客户：≤ 2 次入口点击后进入 Step1
  - 证据追溯：Insight 中点击 EV → Source ≤ 2 次
  - 提交审批：Asset Editor ≤ 1 次主按钮完成

### J3. 证据追溯

- Copy citation 可用且包含 EV code
- 引用断裂可检测并提供修复入口

### J4. A11y

- 键盘可完成：筛选、打开 Drawer、审批、保存、提交审批
- Dialog/Drawer 焦点管理正确
- 图表有数据表替代

### J5. 响应式

- Mobile 上可完成：建档、审批、查看洞察与证据、查看日历列表、查看表现

### J6. 与现有 phases 不冲突

- 不新增/不改写：`agents/schemas/openai/*` 的 schema 契约
- 不改写：`agents/prompts/phase3_*` 与 n8n `meta.aos.*` 的引用关系
- UI 只“消费”现有表结构与工作流产物；缺字段必须标注“待补齐”，不得自造字段名


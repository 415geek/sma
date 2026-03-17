-- ============================================================================
-- AGENCY OPERATING SYSTEM - DATABASE SCHEMA v1.0
-- 客户建档 → 数据抓取 → 分析 → 报告 → 策略 → 内容 → 发布 → 复盘
-- PostgreSQL 15+ / Supabase Compatible
-- ============================================================================

-- 启用必要扩展
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";
CREATE EXTENSION IF NOT EXISTS "pgcrypto";
CREATE EXTENSION IF NOT EXISTS "vector";  -- pgvector for RAG

-- ============================================================================
-- SECTION 1: 核心实体表
-- ============================================================================

-- 1.1 客户表 (Client)
CREATE TABLE clients (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    brand_name VARCHAR(255) NOT NULL,
    brand_name_en VARCHAR(255),
    website VARCHAR(500),
    logo_url VARCHAR(500),
    
    -- 地理信息
    address TEXT,
    city VARCHAR(100),
    state VARCHAR(50),
    country VARCHAR(50) DEFAULT 'US',
    zip_code VARCHAR(20),
    neighborhood VARCHAR(100),  -- 商圈/社区
    timezone VARCHAR(50) DEFAULT 'America/Los_Angeles',
    
    -- 行业信息
    industry VARCHAR(100) NOT NULL,
    sub_industry VARCHAR(100),
    business_type VARCHAR(50),  -- B2C, B2B, B2B2C, D2C
    
    -- 产品/服务
    products_services JSONB DEFAULT '[]',  -- [{name, description, price_range}]
    price_tier VARCHAR(20),  -- budget, mid, premium, luxury
    avg_ticket_size DECIMAL(10,2),
    
    -- 目标受众
    target_audience JSONB DEFAULT '{}',  -- {primary: {}, secondary: {}}
    
    -- 平台需求
    platforms_required VARCHAR(50)[] DEFAULT ARRAY['instagram', 'facebook'],
    
    -- 品牌调性
    tone_preferences JSONB DEFAULT '{}',  -- {voice: [], keywords: [], avoid: []}
    brand_colors JSONB DEFAULT '[]',  -- [{hex, name, usage}]
    visual_style VARCHAR(100),
    
    -- 合规限制
    restrictions JSONB DEFAULT '{}',  -- {forbidden_words: [], legal_disclaimers: [], industry_rules: []}
    
    -- 目标与预算
    primary_goal VARCHAR(50),  -- awareness, leads, store_visits, ecommerce
    secondary_goals VARCHAR(50)[] DEFAULT '{}',
    monthly_budget DECIMAL(10,2),
    
    -- 接入状态
    integrations JSONB DEFAULT '{}',  -- {google_analytics: {}, meta_ads: {}, gmb: {}}
    asset_library_url VARCHAR(500),
    
    -- 元数据
    status VARCHAR(20) DEFAULT 'active',  -- active, paused, churned, onboarding
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    created_by UUID,
    
    CONSTRAINT chk_status CHECK (status IN ('active', 'paused', 'churned', 'onboarding'))
);

CREATE INDEX idx_clients_industry ON clients(industry);
CREATE INDEX idx_clients_status ON clients(status);
CREATE INDEX idx_clients_city ON clients(city);

-- 1.2 项目表 (Project)
CREATE TABLE projects (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    project_type VARCHAR(50) NOT NULL,  -- initial_research, monthly_strategy, campaign, one_off
    project_name VARCHAR(255),
    
    -- 版本控制
    report_version INTEGER DEFAULT 1,
    strategy_version INTEGER DEFAULT 1,
    
    -- 状态流转
    status VARCHAR(30) DEFAULT 'created',
    -- created → researching → analyzing → report_draft → report_review → 
    -- strategy_draft → strategy_review → content_planning → producing → 
    -- review → approved → publishing → completed
    
    -- 时间范围
    target_month DATE,  -- 目标月份 (用于月度项目)
    start_date DATE,
    end_date DATE,
    
    -- 配置
    config JSONB DEFAULT '{}',  -- 项目特定配置
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    completed_at TIMESTAMPTZ,
    
    CONSTRAINT chk_project_status CHECK (status IN (
        'created', 'researching', 'analyzing', 'report_draft', 'report_review',
        'strategy_draft', 'strategy_review', 'content_planning', 'producing',
        'review', 'approved', 'publishing', 'completed', 'cancelled'
    ))
);

CREATE INDEX idx_projects_client ON projects(client_id);
CREATE INDEX idx_projects_status ON projects(status);
CREATE INDEX idx_projects_month ON projects(target_month);

-- ============================================================================
-- SECTION 2: 数据抓取与证据层
-- ============================================================================

-- 2.1 数据源表 (Sources)
CREATE TABLE sources (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    
    -- 来源分类
    source_type VARCHAR(50) NOT NULL,
    -- website, google_business, yelp, social_profile, social_post, 
    -- review, search_result, news, forum, competitor_content
    
    source_platform VARCHAR(50),  -- google, yelp, instagram, tiktok, xiaohongshu, etc.
    
    -- 内容
    url VARCHAR(2000),
    title VARCHAR(500),
    raw_content TEXT,
    extracted_content JSONB,  -- 结构化提取结果
    screenshot_url VARCHAR(500),
    
    -- 元数据
    captured_at TIMESTAMPTZ DEFAULT NOW(),
    content_date TIMESTAMPTZ,  -- 内容本身的日期
    language VARCHAR(10) DEFAULT 'en',
    
    -- 质量标记
    confidence DECIMAL(3,2) DEFAULT 0.8,  -- 0-1
    is_verified BOOLEAN DEFAULT FALSE,
    verification_note TEXT,
    
    -- 处理状态
    processing_status VARCHAR(20) DEFAULT 'raw',  -- raw, extracted, normalized, archived
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT chk_confidence CHECK (confidence >= 0 AND confidence <= 1)
);

CREATE INDEX idx_sources_project ON sources(project_id);
CREATE INDEX idx_sources_type ON sources(source_type);
CREATE INDEX idx_sources_platform ON sources(source_platform);

-- 2.2 竞品表 (Competitors)
CREATE TABLE competitors (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    -- 基本信息
    brand_name VARCHAR(255) NOT NULL,
    website VARCHAR(500),
    
    -- 地理位置
    address TEXT,
    distance_miles DECIMAL(5,2),  -- 距离客户的英里数
    
    -- 分类
    competitor_type VARCHAR(30),  -- direct, indirect, aspirational
    category VARCHAR(100),
    
    -- 定位分析
    positioning TEXT,
    price_tier VARCHAR(20),
    unique_selling_points TEXT[],
    
    -- 社媒信息
    social_profiles JSONB DEFAULT '{}',  -- {instagram: {handle, followers}, ...}
    
    -- 内容风格
    content_style JSONB DEFAULT '{}',  -- {visual_style, tone, themes}
    
    -- 评分
    google_rating DECIMAL(2,1),
    yelp_rating DECIMAL(2,1),
    review_count INTEGER,
    
    -- 分析结论
    strengths TEXT[],
    weaknesses TEXT[],
    opportunities TEXT[],  -- 我们可以利用的机会
    
    notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_competitors_project ON competitors(project_id);
CREATE INDEX idx_competitors_client ON competitors(client_id);
CREATE INDEX idx_competitors_type ON competitors(competitor_type);

-- 2.3 证据登记表 (Evidence Items)
CREATE TABLE evidence_items (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    
    -- 证据编码 (用于报告引用)
    evidence_code VARCHAR(20) NOT NULL,  -- EV-001, EV-002, ...
    
    -- 内容
    statement TEXT NOT NULL,  -- 证据陈述
    excerpt TEXT,  -- 原文摘录
    
    -- 来源追溯
    source_id UUID REFERENCES sources(id),
    source_url VARCHAR(2000),
    source_type VARCHAR(50),
    source_date TIMESTAMPTZ,
    
    -- 分类标签
    category VARCHAR(50),  -- market, competitor, audience, brand, trend
    tags VARCHAR(50)[],
    
    -- 置信度
    confidence VARCHAR(10) NOT NULL,  -- high, medium, low
    confidence_reason TEXT,
    
    -- 使用追踪
    used_in_insights UUID[],  -- 引用此证据的 insight IDs
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT chk_evidence_confidence CHECK (confidence IN ('high', 'medium', 'low'))
);

CREATE UNIQUE INDEX idx_evidence_code ON evidence_items(project_id, evidence_code);
CREATE INDEX idx_evidence_project ON evidence_items(project_id);
CREATE INDEX idx_evidence_category ON evidence_items(category);

-- ============================================================================
-- SECTION 3: 分析与洞察层
-- ============================================================================

-- 3.1 洞察表 (Insights)
CREATE TABLE insights (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    
    -- 分析模块
    module VARCHAR(50) NOT NULL,
    -- industry_analysis, brand_analysis, audience_analysis, 
    -- competitive_analysis, content_opportunity, risk_assessment
    
    -- 内容
    title VARCHAR(255) NOT NULL,
    finding TEXT NOT NULL,
    
    -- 证据支撑
    evidence_codes VARCHAR(20)[] NOT NULL,  -- ['EV-001', 'EV-002']
    
    -- 置信度与验证
    confidence VARCHAR(10) NOT NULL,
    gaps TEXT[],  -- 数据缺口
    assumptions TEXT[],  -- 假设前提
    
    -- 业务影响
    business_implication TEXT,
    recommended_action TEXT,
    priority VARCHAR(10),  -- high, medium, low
    
    -- 排序
    sort_order INTEGER DEFAULT 0,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT chk_insight_confidence CHECK (confidence IN ('high', 'medium', 'low')),
    CONSTRAINT chk_insight_priority CHECK (priority IN ('high', 'medium', 'low'))
);

CREATE INDEX idx_insights_project ON insights(project_id);
CREATE INDEX idx_insights_module ON insights(module);

-- ============================================================================
-- SECTION 4: 报告层
-- ============================================================================

-- 4.1 报告表 (Reports)
CREATE TABLE reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    
    -- 报告类型
    report_type VARCHAR(50) NOT NULL,  -- diagnostic, monthly_strategy, campaign_brief, review
    
    -- 版本控制
    version INTEGER DEFAULT 1,
    is_latest BOOLEAN DEFAULT TRUE,
    
    -- 报告内容 (结构化 JSON)
    report_json JSONB NOT NULL,
    
    -- 导出文件
    pdf_url VARCHAR(500),
    html_url VARCHAR(500),
    
    -- 审批流程
    status VARCHAR(20) DEFAULT 'draft',  -- draft, in_review, revision_requested, approved
    submitted_at TIMESTAMPTZ,
    approved_at TIMESTAMPTZ,
    approved_by VARCHAR(255),
    revision_notes TEXT,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_reports_project ON reports(project_id);
CREATE INDEX idx_reports_status ON reports(status);

-- ============================================================================
-- SECTION 5: 策略与内容规划层
-- ============================================================================

-- 5.1 内容策略表 (Content Plans)
CREATE TABLE content_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    -- 时间范围
    plan_month DATE NOT NULL,  -- 月度计划的月份
    
    -- 月度策略
    month_theme VARCHAR(255),
    month_objectives TEXT[],
    
    -- 平台策略
    platform_strategy JSONB NOT NULL,
    
    -- 内容支柱
    content_pillars JSONB NOT NULL,
    
    -- 促销节点
    key_dates JSONB DEFAULT '[]',
    
    -- KPI
    kpis JSONB DEFAULT '{}',
    
    -- 完整计划 JSON
    plan_json JSONB,
    
    -- 审批
    status VARCHAR(20) DEFAULT 'draft',
    approved_at TIMESTAMPTZ,
    approved_by VARCHAR(255),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_content_plans_project ON content_plans(project_id);
CREATE INDEX idx_content_plans_month ON content_plans(plan_month);

-- 5.2 周计划表 (Weekly Plans)
CREATE TABLE weekly_plans (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_plan_id UUID NOT NULL REFERENCES content_plans(id) ON DELETE CASCADE,
    
    -- 周次
    week_number INTEGER NOT NULL,  -- 1, 2, 3, 4, 5
    week_start_date DATE NOT NULL,
    week_end_date DATE NOT NULL,
    
    -- 周目标
    week_theme VARCHAR(255),
    week_objectives TEXT[],
    
    -- 周计划详情
    plan_json JSONB NOT NULL,
    
    status VARCHAR(20) DEFAULT 'draft',
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_weekly_plans_content_plan ON weekly_plans(content_plan_id);
CREATE INDEX idx_weekly_plans_week ON weekly_plans(week_start_date);

-- ============================================================================
-- SECTION 6: 内容资产层
-- ============================================================================

-- 6.1 内容资产表 (Content Assets)
CREATE TABLE content_assets (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    weekly_plan_id UUID REFERENCES weekly_plans(id),
    
    -- 基本信息
    asset_code VARCHAR(30),  -- CA-202402-W1-001
    title VARCHAR(255),
    
    -- 平台与类型
    platform VARCHAR(50) NOT NULL,
    content_type VARCHAR(50) NOT NULL,  -- reel, carousel, story, post, video, article
    content_format VARCHAR(50),  -- vertical_video, square_image, horizontal_video
    
    -- 关联的内容支柱
    content_pillar VARCHAR(100),
    
    -- 计划发布
    scheduled_date DATE,
    scheduled_time TIME,
    optimal_posting_time VARCHAR(50),  -- "9:00 AM - 11:00 AM PST"
    
    -- 内容 Brief
    brief_json JSONB NOT NULL,
    
    -- 文案
    caption TEXT,
    caption_versions JSONB DEFAULT '[]',  -- 多版本文案
    
    -- 视频脚本
    script_json JSONB,
    
    -- 拍摄指南
    shot_list JSONB,
    
    -- 封面/标题
    cover_title VARCHAR(100),
    cover_subtitle VARCHAR(100),
    cover_design_notes TEXT,
    
    -- 标签与关键词
    hashtags VARCHAR(100)[],
    keywords VARCHAR(100)[],
    mentions VARCHAR(100)[],
    
    -- AI 素材提示
    image_prompt TEXT,
    video_prompt TEXT,
    
    -- 素材链接
    asset_urls JSONB DEFAULT '[]',  -- [{type, url, description}]
    
    -- 审批流程
    status VARCHAR(20) DEFAULT 'draft',
    
    review_notes TEXT,
    approved_at TIMESTAMPTZ,
    approved_by VARCHAR(255),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW(),
    
    CONSTRAINT chk_asset_status CHECK (status IN (
        'draft', 'in_review', 'revision_requested', 'approved', 
        'scheduled', 'published', 'archived'
    ))
);

CREATE INDEX idx_assets_project ON content_assets(project_id);
CREATE INDEX idx_assets_platform ON content_assets(platform);
CREATE INDEX idx_assets_status ON content_assets(status);
CREATE INDEX idx_assets_scheduled ON content_assets(scheduled_date);

-- ============================================================================
-- SECTION 7: 发布与表现层
-- ============================================================================

-- 7.1 发布日志表 (Publish Logs)
CREATE TABLE publish_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_asset_id UUID NOT NULL REFERENCES content_assets(id) ON DELETE CASCADE,
    
    -- 发布信息
    platform VARCHAR(50) NOT NULL,
    published_at TIMESTAMPTZ,
    published_url VARCHAR(2000),
    platform_post_id VARCHAR(255),  -- 平台侧的帖子 ID
    
    -- 发布状态
    status VARCHAR(20) DEFAULT 'pending',  -- pending, published, failed, deleted
    error_message TEXT,
    
    -- 发布方式
    publish_method VARCHAR(20),  -- manual, api, scheduler
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_publish_logs_asset ON publish_logs(content_asset_id);
CREATE INDEX idx_publish_logs_platform ON publish_logs(platform);

-- 7.2 表现数据表 (Performance Metrics)
CREATE TABLE performance_metrics (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_asset_id UUID NOT NULL REFERENCES content_assets(id) ON DELETE CASCADE,
    publish_log_id UUID REFERENCES publish_logs(id),
    
    -- 平台
    platform VARCHAR(50) NOT NULL,
    
    -- 基础指标
    impressions INTEGER DEFAULT 0,
    reach INTEGER DEFAULT 0,
    views INTEGER DEFAULT 0,
    
    -- 互动指标
    likes INTEGER DEFAULT 0,
    comments INTEGER DEFAULT 0,
    shares INTEGER DEFAULT 0,
    saves INTEGER DEFAULT 0,
    
    -- 计算指标
    engagement_rate DECIMAL(5,4),  -- 互动率
    
    -- 视频指标
    watch_time_seconds INTEGER,
    avg_watch_percentage DECIMAL(5,2),
    completion_rate DECIMAL(5,4),
    
    -- 转化指标
    clicks INTEGER DEFAULT 0,
    ctr DECIMAL(5,4),
    link_clicks INTEGER DEFAULT 0,
    profile_visits INTEGER DEFAULT 0,
    
    -- 业务转化
    leads INTEGER DEFAULT 0,
    conversions INTEGER DEFAULT 0,
    revenue DECIMAL(10,2),
    
    -- 数据采集时间
    metrics_date DATE NOT NULL,
    captured_at TIMESTAMPTZ DEFAULT NOW(),
    
    -- 原始数据
    raw_metrics JSONB
);

CREATE INDEX idx_metrics_asset ON performance_metrics(content_asset_id);
CREATE INDEX idx_metrics_platform ON performance_metrics(platform);
CREATE INDEX idx_metrics_date ON performance_metrics(metrics_date);

-- 7.3 复盘报告表 (Review Reports)
CREATE TABLE review_reports (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    content_plan_id UUID NOT NULL REFERENCES content_plans(id) ON DELETE CASCADE,
    
    -- 复盘周期
    review_period_start DATE NOT NULL,
    review_period_end DATE NOT NULL,
    review_type VARCHAR(20),  -- weekly, monthly, quarterly
    
    -- 汇总数据
    summary_metrics JSONB NOT NULL,
    
    -- 洞察
    key_learnings TEXT[],
    what_worked TEXT[],
    what_didnt_work TEXT[],
    
    -- 下期建议
    recommendations JSONB,
    
    -- 完整报告
    report_json JSONB,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_review_reports_plan ON review_reports(content_plan_id);

-- ============================================================================
-- SECTION 8: 品牌记忆与 RAG 支持
-- ============================================================================

-- 8.1 品牌记忆表 (Brand Memory)
CREATE TABLE brand_memory (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    client_id UUID NOT NULL REFERENCES clients(id) ON DELETE CASCADE,
    
    -- 记忆类型
    memory_type VARCHAR(50) NOT NULL,
    
    -- 内容
    title VARCHAR(255),
    content TEXT NOT NULL,
    metadata JSONB DEFAULT '{}',
    
    -- 向量嵌入 (for RAG)
    embedding vector(1536),  -- OpenAI ada-002 dimension
    
    -- 来源
    source_asset_id UUID REFERENCES content_assets(id),
    source_url VARCHAR(500),
    
    -- 状态
    is_active BOOLEAN DEFAULT TRUE,
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_brand_memory_client ON brand_memory(client_id);
CREATE INDEX idx_brand_memory_type ON brand_memory(memory_type);
CREATE INDEX idx_brand_memory_embedding ON brand_memory USING ivfflat (embedding vector_cosine_ops) WITH (lists = 100);

-- ============================================================================
-- SECTION 9: 审批与工作流
-- ============================================================================

-- 9.1 审批记录表 (Approval Records)
CREATE TABLE approval_records (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 关联实体
    entity_type VARCHAR(50) NOT NULL,  -- report, content_plan, content_asset
    entity_id UUID NOT NULL,
    
    -- 审批信息
    action VARCHAR(20) NOT NULL,  -- submit, approve, reject, request_revision
    actor_name VARCHAR(255),
    actor_email VARCHAR(255),
    
    -- 备注
    notes TEXT,
    
    -- 版本追踪
    entity_version INTEGER,
    
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_approvals_entity ON approval_records(entity_type, entity_id);

-- 9.2 工作流任务表 (Workflow Tasks)
CREATE TABLE workflow_tasks (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    project_id UUID NOT NULL REFERENCES projects(id) ON DELETE CASCADE,
    
    -- 任务信息
    task_type VARCHAR(50) NOT NULL,
    
    task_name VARCHAR(255),
    
    -- 状态
    status VARCHAR(20) DEFAULT 'pending',  -- pending, running, completed, failed, cancelled
    
    -- 输入输出
    input_data JSONB,
    output_data JSONB,
    
    -- 执行信息
    started_at TIMESTAMPTZ,
    completed_at TIMESTAMPTZ,
    error_message TEXT,
    retry_count INTEGER DEFAULT 0,
    
    -- n8n 集成
    n8n_workflow_id VARCHAR(100),
    n8n_execution_id VARCHAR(100),
    
    created_at TIMESTAMPTZ DEFAULT NOW(),
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_workflow_tasks_project ON workflow_tasks(project_id);
CREATE INDEX idx_workflow_tasks_status ON workflow_tasks(status);

-- ============================================================================
-- SECTION 10: 系统配置与日志
-- ============================================================================

-- 10.1 系统配置表
CREATE TABLE system_config (
    key VARCHAR(100) PRIMARY KEY,
    value JSONB NOT NULL,
    description TEXT,
    updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- 10.2 操作日志表
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
    
    -- 操作者
    actor_type VARCHAR(20),  -- user, system, agent
    actor_id VARCHAR(255),
    actor_name VARCHAR(255),
    
    -- 操作
    action VARCHAR(50) NOT NULL,
    entity_type VARCHAR(50),
    entity_id UUID,
    
    -- 详情
    changes JSONB,
    metadata JSONB,
    
    -- IP 与时间
    ip_address INET,
    created_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_audit_logs_entity ON audit_logs(entity_type, entity_id);
CREATE INDEX idx_audit_logs_time ON audit_logs(created_at);

-- ============================================================================
-- SECTION 11: 函数与触发器
-- ============================================================================

-- 自动更新 updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- 为所有需要的表添加触发器
CREATE TRIGGER update_clients_updated_at BEFORE UPDATE ON clients
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_projects_updated_at BEFORE UPDATE ON projects
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_competitors_updated_at BEFORE UPDATE ON competitors
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_insights_updated_at BEFORE UPDATE ON insights
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_reports_updated_at BEFORE UPDATE ON reports
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_content_plans_updated_at BEFORE UPDATE ON content_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_weekly_plans_updated_at BEFORE UPDATE ON weekly_plans
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_content_assets_updated_at BEFORE UPDATE ON content_assets
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_brand_memory_updated_at BEFORE UPDATE ON brand_memory
    FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- 自动生成 evidence_code
CREATE OR REPLACE FUNCTION generate_evidence_code()
RETURNS TRIGGER AS $$
DECLARE
    next_num INTEGER;
BEGIN
    SELECT COALESCE(MAX(CAST(SUBSTRING(evidence_code FROM 4) AS INTEGER)), 0) + 1
    INTO next_num
    FROM evidence_items
    WHERE project_id = NEW.project_id;
    
    NEW.evidence_code := 'EV-' || LPAD(next_num::TEXT, 3, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER auto_generate_evidence_code BEFORE INSERT ON evidence_items
    FOR EACH ROW WHEN (NEW.evidence_code IS NULL)
    EXECUTE FUNCTION generate_evidence_code();

-- 自动生成 asset_code
CREATE OR REPLACE FUNCTION generate_asset_code()
RETURNS TRIGGER AS $$
DECLARE
    month_str VARCHAR(6);
    week_num INTEGER;
    next_num INTEGER;
BEGIN
    -- 获取月份字符串
    month_str := TO_CHAR(COALESCE(NEW.scheduled_date, CURRENT_DATE), 'YYYYMM');
    
    -- 获取周数
    week_num := COALESCE(
        (SELECT week_number FROM weekly_plans WHERE id = NEW.weekly_plan_id),
        EXTRACT(WEEK FROM COALESCE(NEW.scheduled_date, CURRENT_DATE))::INTEGER
    );
    
    -- 获取序号
    SELECT COALESCE(MAX(
        CAST(SUBSTRING(asset_code FROM LENGTH(asset_code) - 2) AS INTEGER)
    ), 0) + 1
    INTO next_num
    FROM content_assets
    WHERE project_id = NEW.project_id
    AND asset_code LIKE 'CA-' || month_str || '-W' || week_num || '-%';
    
    NEW.asset_code := 'CA-' || month_str || '-W' || week_num || '-' || LPAD(next_num::TEXT, 3, '0');
    RETURN NEW;
END;
$$ language 'plpgsql';

CREATE TRIGGER auto_generate_asset_code BEFORE INSERT ON content_assets
    FOR EACH ROW WHEN (NEW.asset_code IS NULL)
    EXECUTE FUNCTION generate_asset_code();

-- ============================================================================
-- END OF MIGRATION
-- ============================================================================


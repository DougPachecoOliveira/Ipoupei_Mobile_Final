-- ===============================================
-- 🚀 iPoupei Mobile Subscriptions - Schema Completo
-- ===============================================
-- Para executar no Supabase SQL Editor
-- Criado em: 2026-02-10
-- ===============================================

-- ===============================================
-- 1. TABELA PRINCIPAL - mobile_subscriptions
-- ===============================================

CREATE TABLE public.mobile_subscriptions (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Identificação da plataforma
  platform text NOT NULL CHECK (platform IN ('ios', 'android')),

  -- Dados do plano
  plan_type text NOT NULL CHECK (plan_type IN ('anual_primeiro', 'anual_renovacao', 'mensal')),
  plan_name text NOT NULL, -- "Plano Anual – 1º Ano (com mentoria)", etc
  plan_price numeric(10,2) NOT NULL,
  currency text DEFAULT 'BRL',

  -- Status da assinatura
  status text NOT NULL DEFAULT 'pending' CHECK (status IN ('active', 'expired', 'cancelled', 'pending', 'grace_period', 'billing_retry')),

  -- Períodos
  start_date timestamptz,
  end_date timestamptz,
  trial_end_date timestamptz,
  grace_period_end timestamptz,

  -- Dados específicos iOS
  apple_transaction_id text,
  apple_original_transaction_id text,
  apple_product_id text,
  apple_receipt_data text,
  apple_environment text CHECK (apple_environment IN ('Sandbox', 'Production')),

  -- Dados específicos Android
  google_order_id text,
  google_purchase_token text,
  google_product_id text,
  google_package_name text,

  -- Controle de verificação
  last_verified_at timestamptz,
  verification_attempts integer DEFAULT 0,
  next_verification_at timestamptz,

  -- Metadados
  raw_receipt jsonb,
  webhook_data jsonb,

  -- Auto-renewal
  auto_renew_enabled boolean DEFAULT true,
  will_renew boolean,

  -- Timestamps
  created_at timestamptz DEFAULT NOW(),
  updated_at timestamptz DEFAULT NOW()
);

-- ===============================================
-- 2. TABELA DE LOG - mobile_subscription_events
-- ===============================================

CREATE TABLE public.mobile_subscription_events (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  subscription_id uuid NOT NULL REFERENCES mobile_subscriptions(id) ON DELETE CASCADE,
  user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,

  -- Tipo do evento
  event_type text NOT NULL CHECK (event_type IN (
    'subscription_created',
    'subscription_renewed',
    'subscription_cancelled',
    'subscription_expired',
    'subscription_restored',
    'payment_failed',
    'grace_period_started',
    'grace_period_ended',
    'verification_failed',
    'refund_issued'
  )),

  -- Detalhes do evento
  platform text NOT NULL CHECK (platform IN ('ios', 'android')),
  transaction_id text,
  previous_status text,
  new_status text,

  -- Dados do evento
  event_data jsonb,
  raw_notification jsonb,

  -- Timestamps
  event_timestamp timestamptz DEFAULT NOW(),
  created_at timestamptz DEFAULT NOW()
);

-- ===============================================
-- 3. TABELA DE CACHE DE PRODUTOS
-- ===============================================

CREATE TABLE public.mobile_products (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  platform text NOT NULL CHECK (platform IN ('ios', 'android')),
  product_id text NOT NULL,
  plan_type text NOT NULL CHECK (plan_type IN ('anual_primeiro', 'anual_renovacao', 'mensal')),

  -- Informações do produto
  name text NOT NULL,
  description text,
  price numeric(10,2) NOT NULL,
  currency text DEFAULT 'BRL',
  duration_months integer NOT NULL,

  -- Metadados
  is_active boolean DEFAULT true,
  sort_order integer DEFAULT 0,
  features jsonb, -- Array de features incluídas

  created_at timestamptz DEFAULT NOW(),
  updated_at timestamptz DEFAULT NOW(),

  UNIQUE(platform, product_id)
);

-- ===============================================
-- 4. ROW LEVEL SECURITY (RLS) POLICIES
-- ===============================================

-- Habilitar RLS
ALTER TABLE mobile_subscriptions ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_subscription_events ENABLE ROW LEVEL SECURITY;
ALTER TABLE mobile_products ENABLE ROW LEVEL SECURITY;

-- Policies para mobile_subscriptions
CREATE POLICY "Users can view own subscriptions" ON mobile_subscriptions
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Users can insert own subscriptions" ON mobile_subscriptions
  FOR INSERT WITH CHECK (auth.uid() = user_id);

CREATE POLICY "Users can update own subscriptions" ON mobile_subscriptions
  FOR UPDATE USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all subscriptions" ON mobile_subscriptions
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Policies para mobile_subscription_events
CREATE POLICY "Users can view own subscription events" ON mobile_subscription_events
  FOR SELECT USING (auth.uid() = user_id);

CREATE POLICY "Service role can manage all events" ON mobile_subscription_events
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- Policies para mobile_products
CREATE POLICY "Anyone can view active products" ON mobile_products
  FOR SELECT USING (is_active = true);

CREATE POLICY "Service role can manage products" ON mobile_products
  FOR ALL USING (auth.jwt() ->> 'role' = 'service_role');

-- ===============================================
-- 5. TRIGGERS E FUNÇÕES
-- ===============================================

-- Função para atualizar updated_at
CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
    NEW.updated_at = NOW();
    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para mobile_subscriptions
CREATE TRIGGER update_mobile_subscriptions_updated_at
    BEFORE UPDATE ON mobile_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Trigger para mobile_products
CREATE TRIGGER update_mobile_products_updated_at
    BEFORE UPDATE ON mobile_products
    FOR EACH ROW
    EXECUTE FUNCTION update_updated_at_column();

-- Função para log automático de eventos
CREATE OR REPLACE FUNCTION log_subscription_event()
RETURNS TRIGGER AS $$
BEGIN
    -- Log apenas quando status muda
    IF (TG_OP = 'UPDATE' AND OLD.status IS DISTINCT FROM NEW.status) OR TG_OP = 'INSERT' THEN
        INSERT INTO mobile_subscription_events (
            subscription_id,
            user_id,
            event_type,
            platform,
            transaction_id,
            previous_status,
            new_status,
            event_data
        ) VALUES (
            NEW.id,
            NEW.user_id,
            CASE
                WHEN TG_OP = 'INSERT' THEN 'subscription_created'
                WHEN NEW.status = 'active' AND OLD.status != 'active' THEN 'subscription_renewed'
                WHEN NEW.status = 'cancelled' THEN 'subscription_cancelled'
                WHEN NEW.status = 'expired' THEN 'subscription_expired'
                ELSE 'subscription_updated'
            END,
            NEW.platform,
            COALESCE(NEW.apple_transaction_id, NEW.google_order_id),
            CASE WHEN TG_OP = 'UPDATE' THEN OLD.status ELSE NULL END,
            NEW.status,
            jsonb_build_object('plan_type', NEW.plan_type, 'price', NEW.plan_price)
        );
    END IF;

    RETURN NEW;
END;
$$ language 'plpgsql';

-- Trigger para log automático
CREATE TRIGGER log_subscription_changes
    AFTER INSERT OR UPDATE ON mobile_subscriptions
    FOR EACH ROW
    EXECUTE FUNCTION log_subscription_event();

-- ===============================================
-- 6. FUNÇÕES DE CONSULTA (RPC)
-- ===============================================

-- Verificar status de assinatura do usuário
CREATE OR REPLACE FUNCTION check_user_subscription(user_uuid uuid)
RETURNS TABLE(
    has_active_subscription boolean,
    subscription_type text,
    expires_at timestamptz,
    platform text
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        COUNT(*) > 0 as has_active_subscription,
        s.plan_type as subscription_type,
        s.end_date as expires_at,
        s.platform
    FROM mobile_subscriptions s
    WHERE s.user_id = user_uuid
    AND s.status = 'active'
    AND (s.end_date IS NULL OR s.end_date > NOW())
    ORDER BY s.end_date DESC NULLS FIRST
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Listar produtos ativos
CREATE OR REPLACE FUNCTION get_mobile_products(platform_filter text DEFAULT NULL)
RETURNS TABLE(
    product_id text,
    platform text,
    name text,
    description text,
    price numeric,
    currency text,
    plan_type text,
    duration_months integer,
    features jsonb
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        p.product_id,
        p.platform,
        p.name,
        p.description,
        p.price,
        p.currency,
        p.plan_type,
        p.duration_months,
        p.features
    FROM mobile_products p
    WHERE p.is_active = true
    AND (platform_filter IS NULL OR p.platform = platform_filter)
    ORDER BY p.sort_order, p.price;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- Obter assinatura ativa do usuário
CREATE OR REPLACE FUNCTION get_user_active_subscription(user_uuid uuid)
RETURNS TABLE(
    subscription_id uuid,
    plan_type text,
    plan_name text,
    price numeric,
    platform text,
    status text,
    start_date timestamptz,
    end_date timestamptz,
    auto_renew_enabled boolean
) AS $$
BEGIN
    RETURN QUERY
    SELECT
        s.id as subscription_id,
        s.plan_type,
        s.plan_name,
        s.plan_price as price,
        s.platform,
        s.status,
        s.start_date,
        s.end_date,
        s.auto_renew_enabled
    FROM mobile_subscriptions s
    WHERE s.user_id = user_uuid
    AND s.status IN ('active', 'grace_period')
    AND (s.end_date IS NULL OR s.end_date > NOW())
    ORDER BY s.created_at DESC
    LIMIT 1;
END;
$$ LANGUAGE plpgsql SECURITY DEFINER;

-- ===============================================
-- 7. ÍNDICES PARA PERFORMANCE
-- ===============================================

-- Índices essenciais
CREATE INDEX idx_mobile_subs_user_status ON mobile_subscriptions(user_id, status);
CREATE INDEX idx_mobile_subs_platform ON mobile_subscriptions(platform);
CREATE INDEX idx_mobile_subs_status_active ON mobile_subscriptions(status) WHERE status = 'active';
CREATE INDEX idx_mobile_subs_end_date ON mobile_subscriptions(end_date) WHERE end_date IS NOT NULL;

-- Índices únicos para evitar duplicatas
CREATE UNIQUE INDEX idx_apple_transaction_unique ON mobile_subscriptions(apple_transaction_id)
  WHERE apple_transaction_id IS NOT NULL;
CREATE UNIQUE INDEX idx_google_order_unique ON mobile_subscriptions(google_order_id)
  WHERE google_order_id IS NOT NULL;

-- Índices para eventos
CREATE INDEX idx_events_subscription ON mobile_subscription_events(subscription_id);
CREATE INDEX idx_events_user ON mobile_subscription_events(user_id);
CREATE INDEX idx_events_type ON mobile_subscription_events(event_type);
CREATE INDEX idx_events_timestamp ON mobile_subscription_events(event_timestamp);

-- ===============================================
-- 8. DADOS INICIAIS (PRODUTOS)
-- ===============================================

-- Inserir produtos do iPoupei
INSERT INTO mobile_products (platform, product_id, plan_type, name, description, price, duration_months, sort_order, features) VALUES
-- iOS Products
('ios', 'br.com.ipoupei.mobile.anual.primeiro', 'anual_primeiro', 'Plano Anual – 1º Ano (com mentoria)', 'Acesso completo ao iPoupei com mentoria personalizada', 299.00, 12, 1, '["Análise financeira completa", "Planejamento personalizado", "Mentoria especializada", "Relatórios avançados", "Suporte prioritário"]'::jsonb),
('ios', 'br.com.ipoupei.mobile.mensal', 'mensal', 'Plano Mensal', 'Acesso mensal ao iPoupei', 19.90, 1, 3, '["Análise financeira", "Planejamento básico", "Relatórios mensais"]'::jsonb),

-- Android Products
('android', 'br.com.ipoupei.mobile.anual.primeiro', 'anual_primeiro', 'Plano Anual – 1º Ano (com mentoria)', 'Acesso completo ao iPoupei com mentoria personalizada', 299.00, 12, 1, '["Análise financeira completa", "Planejamento personalizado", "Mentoria especializada", "Relatórios avançados", "Suporte prioritário"]'::jsonb),
('android', 'br.com.ipoupei.mobile.mensal', 'mensal', 'Plano Mensal', 'Acesso mensal ao iPoupei', 19.90, 1, 3, '["Análise financeira", "Planejamento básico", "Relatórios mensais"]'::jsonb);

-- ===============================================
-- 9. COMENTÁRIOS E DOCUMENTAÇÃO
-- ===============================================

COMMENT ON TABLE mobile_subscriptions IS 'Tabela principal para gerenciar assinaturas mobile do iPoupei (iOS e Android)';
COMMENT ON TABLE mobile_subscription_events IS 'Log de eventos das assinaturas para auditoria e histórico';
COMMENT ON TABLE mobile_products IS 'Cache dos produtos disponíveis nas lojas (App Store e Play Store)';

COMMENT ON COLUMN mobile_subscriptions.plan_type IS 'Tipo do plano: anual_primeiro (R$299), anual_renovacao (R$199), mensal (R$19.90)';
COMMENT ON COLUMN mobile_subscriptions.status IS 'Status da assinatura: active, expired, cancelled, pending, grace_period, billing_retry';
COMMENT ON COLUMN mobile_subscriptions.apple_environment IS 'Ambiente do iOS: Sandbox para testes, Production para produção';

-- ===============================================
-- ✅ SCHEMA CRIADO COM SUCESSO!
-- ===============================================
--
-- Para executar:
-- 1. Copie todo este código
-- 2. Cole no Supabase SQL Editor
-- 3. Execute o script
--
-- O que foi criado:
-- ✅ 3 tabelas com RLS completo
-- ✅ Triggers automáticos para auditoria
-- ✅ Funções RPC para consultas
-- ✅ Índices otimizados
-- ✅ Produtos pré-configurados
-- ✅ Logs automáticos de eventos
-- ✅ Políticas de segurança robustas
--
-- Próximo passo: Implementar no Flutter!
-- ===============================================
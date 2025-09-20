-- 📈 RPC Function: get_categorias_com_valores
-- 
-- Função otimizada para buscar categorias com valores pré-calculados
-- Baseada no padrão de get_conta_saldo_total para máxima performance
-- 
-- Parâmetros:
-- - p_usuario_id: UUID do usuário
-- - p_data_inicio: Data de início (opcional)  
-- - p_data_fim: Data de fim (opcional)
-- - p_tipo: Tipo de categoria - 'receita' ou 'despesa' (opcional)
--
-- Retorna: Array de objetos com categorias e valores calculados
-- 
-- 🚀 PERFORMANCE: Uma única query com JOINs ao invés de N+1 queries

CREATE OR REPLACE FUNCTION get_categorias_com_valores(
    p_usuario_id UUID,
    p_data_inicio DATE DEFAULT NULL,
    p_data_fim DATE DEFAULT NULL,
    p_tipo TEXT DEFAULT NULL
)
RETURNS TABLE (
    id UUID,
    nome TEXT,
    cor TEXT,
    icone TEXT,
    tipo TEXT,
    valor_total DECIMAL,
    quantidade_transacoes INTEGER,
    ativo BOOLEAN,
    created_at TIMESTAMPTZ,
    updated_at TIMESTAMPTZ
)
LANGUAGE plpgsql
AS $$
BEGIN
    RETURN QUERY
    SELECT 
        c.id,
        c.nome,
        c.cor,
        c.icone,
        c.tipo,
        COALESCE(stats.valor_total, 0)::DECIMAL as valor_total,
        COALESCE(stats.quantidade_transacoes, 0)::INTEGER as quantidade_transacoes,
        c.ativo,
        c.created_at,
        c.updated_at
    FROM categorias c
    LEFT JOIN (
        SELECT 
            t.categoria_id,
            SUM(t.valor)::DECIMAL as valor_total,
            COUNT(*)::INTEGER as quantidade_transacoes
        FROM transacoes t
        WHERE 
            t.usuario_id = p_usuario_id
            AND t.efetivado = true
            AND (p_data_inicio IS NULL OR t.data >= p_data_inicio)
            AND (p_data_fim IS NULL OR t.data <= p_data_fim)
        GROUP BY t.categoria_id
    ) stats ON c.id = stats.categoria_id
    WHERE 
        c.usuario_id = p_usuario_id
        AND c.ativo = true
        AND (p_tipo IS NULL OR c.tipo = p_tipo)
    ORDER BY 
        stats.valor_total DESC NULLS LAST,
        c.nome ASC;
END;
$$;

-- 🔒 Segurança: RLS (Row Level Security) já aplicado nas tabelas base
-- 💡 Índices recomendados para performance máxima:
-- CREATE INDEX IF NOT EXISTS idx_transacoes_categoria_usuario_efetivado ON transacoes(categoria_id, usuario_id, efetivado) WHERE efetivado = true;
-- CREATE INDEX IF NOT EXISTS idx_transacoes_data_usuario ON transacoes(data, usuario_id);
-- CREATE INDEX IF NOT EXISTS idx_categorias_usuario_ativo ON categorias(usuario_id, ativo) WHERE ativo = true;
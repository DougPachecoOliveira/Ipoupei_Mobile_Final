-- Script para corrigir categoriaId das subcategorias
-- Execute este script no banco de dados para corrigir o relacionamento

-- Primeiro, vamos ver o estado atual
SELECT 'ESTADO ATUAL:' as info;
SELECT c.nome as categoria, s.nome as subcategoria, s.id as subcat_id
FROM subcategorias s
JOIN categorias c ON s.categoria_id = c.id
WHERE c.nome IN ('Saúde', 'Alimentação', 'Transporte', 'Vestuário', 'Lazer')
ORDER BY c.nome, s.nome;

-- Atualizar subcategorias que estão incorretamente associadas

-- 1. Combustível, Uber/Taxi, Transporte Público, Estacionamento, Pedágio → Transporte
UPDATE subcategorias
SET categoria_id = (SELECT id FROM categorias WHERE nome = 'Transporte' LIMIT 1)
WHERE nome IN ('Combustível', 'Uber/Taxi', 'Transporte Público', 'Estacionamento', 'Pedágio', 'Manutenção Veículo')
  AND categoria_id != (SELECT id FROM categorias WHERE nome = 'Transporte' LIMIT 1);

-- 2. Supermercado, Restaurante, Lanche/Fast Food/Delivery, Açougue/Feira → Alimentação
UPDATE subcategorias
SET categoria_id = (SELECT id FROM categorias WHERE nome = 'Alimentação' LIMIT 1)
WHERE nome IN ('Supermercado', 'Restaurante', 'Lanche/Fast Food/Delivery', 'Açougue/Feira')
  AND categoria_id != (SELECT id FROM categorias WHERE nome = 'Alimentação' LIMIT 1);

-- 3. Roupas, Calçados, Acessórios → Vestuário
UPDATE subcategorias
SET categoria_id = (SELECT id FROM categorias WHERE nome = 'Vestuário' LIMIT 1)
WHERE nome IN ('Roupas', 'Calçados', 'Acessórios')
  AND categoria_id != (SELECT id FROM categorias WHERE nome = 'Vestuário' LIMIT 1);

-- 4. Streaming, Cinema/Teatro, Viagens, Hobbies → Lazer
UPDATE subcategorias
SET categoria_id = (SELECT id FROM categorias WHERE nome = 'Lazer' LIMIT 1)
WHERE nome IN ('Streaming', 'Cinema/Teatro', 'Viagens', 'Hobbies')
  AND categoria_id != (SELECT id FROM categorias WHERE nome = 'Lazer' LIMIT 1);

-- Verificar resultado
SELECT 'ESTADO APÓS CORREÇÃO:' as info;
SELECT c.nome as categoria, s.nome as subcategoria, s.id as subcat_id
FROM subcategorias s
JOIN categorias c ON s.categoria_id = c.id
WHERE c.nome IN ('Saúde', 'Alimentação', 'Transporte', 'Vestuário', 'Lazer')
ORDER BY c.nome, s.nome;

-- ============================================================
-- TESTES DE INTEGRIDADE — CLÍNICA VETERINÁRIA
-- ============================================================

USE clinica_veterinaria;

-- ------------------------------------------------------------
-- 5.1 INSERÇÕES VÁLIDAS
-- ------------------------------------------------------------

-- Espécies
INSERT INTO especie (nome) VALUES ('Cão');
INSERT INTO especie (nome) VALUES ('Gato');
INSERT INTO especie (nome) VALUES ('Coelho');

-- Tutores
INSERT INTO tutor (nome, cpf, telefone, email)
VALUES ('Ana Paula Souza', '12345678901', '32999110001', 'ana.souza@email.com');

INSERT INTO tutor (nome, cpf, telefone, email)
VALUES ('Carlos Eduardo Lima', '98765432100', '32988220002', 'carlos.lima@email.com');

INSERT INTO tutor (nome, cpf, telefone, email)
VALUES ('Fernanda Rocha', '11122233344', '32977330003', 'fernanda.rocha@email.com');

-- Veterinários
INSERT INTO veterinario (nome, crmv, especialidade)
VALUES ('Dr. Marcos Andrade', 'CRMV-MG 12345', 'Clínica Geral');

INSERT INTO veterinario (nome, crmv, especialidade)
VALUES ('Dra. Juliana Ferreira', 'CRMV-MG 67890', 'Dermatologia Veterinária');

-- Animais
INSERT INTO animal (nome, raca, data_nascimento, peso_kg, id_tutor, id_especie)
VALUES ('Rex', 'Labrador', '2020-03-15', 28.50, 1, 1);

INSERT INTO animal (nome, raca, data_nascimento, peso_kg, id_tutor, id_especie)
VALUES ('Mia', 'Siamês', '2021-07-22', 4.20, 2, 2);

INSERT INTO animal (nome, raca, data_nascimento, peso_kg, id_tutor, id_especie)
VALUES ('Bolinha', 'Anão', '2022-01-10', 1.80, 3, 3);

INSERT INTO animal (nome, raca, data_nascimento, peso_kg, id_tutor, id_especie)
VALUES ('Thor', 'Pitbull', '2019-11-05', 32.00, 1, 1);

-- Medicamentos
INSERT INTO medicamento (nome, principio_ativo, estoque_atual)
VALUES ('Amoxicilina 250mg', 'Amoxicilina', 100);

INSERT INTO medicamento (nome, principio_ativo, estoque_atual)
VALUES ('Dexametasona 4mg', 'Dexametasona', 60);

INSERT INTO medicamento (nome, principio_ativo, estoque_atual)
VALUES ('Ivermectina 1%', 'Ivermectina', 45);

-- Consultas
INSERT INTO consulta (data_consulta, motivo, valor, status, id_animal, id_veterinario)
VALUES ('2025-06-01 09:00:00', 'Check-up anual', 150.00, 'realizada', 1, 1);

INSERT INTO consulta (data_consulta, motivo, valor, status, id_animal, id_veterinario)
VALUES ('2025-06-03 14:30:00', 'Coceira e queda de pelo', 200.00, 'realizada', 2, 2);

INSERT INTO consulta (data_consulta, motivo, valor, status, id_animal, id_veterinario)
VALUES ('2025-06-10 10:00:00', 'Perda de apetite', 150.00, 'agendada', 3, 1);

-- Prescrições (trigger será acionada aqui)
INSERT INTO prescricao (posologia, quantidade, id_consulta, id_medicamento)
VALUES ('1 comprimido a cada 12h por 7 dias', 14, 1, 1);

INSERT INTO prescricao (posologia, quantidade, id_consulta, id_medicamento)
VALUES ('Aplicar 1 gota por kg a cada 30 dias', 4, 2, 3);

-- Verificar estoque após prescrições
SELECT nome, estoque_atual FROM medicamento;

-- Agendar consulta via procedure
CALL sp_agendar_consulta(
    'Vacinação anual',
    120.00,
    4,
    1,
    '2025-06-20 11:00:00'
);

-- Atualizar diagnóstico após consulta realizada
UPDATE consulta
SET diagnostico = 'Animal saudável, vacinas em dia'
WHERE id_consulta = 1;

-- ------------------------------------------------------------
-- 5.2 TESTES DE ERRO (executar separadamente)
-- ------------------------------------------------------------

-- Peso negativo (esperado: erro CHECK)
-- EXECUTAR SEPARADAMENTE
-- INSERT INTO animal (nome, raca, peso_kg, id_tutor, id_especie)
-- VALUES ('Invalido', 'SRD', -5.00, 1, 1);

-- Nome do animal NULL (esperado: erro NOT NULL)
-- EXECUTAR SEPARADAMENTE
-- INSERT INTO animal (nome, raca, peso_kg, id_tutor, id_especie)
-- VALUES (NULL, 'SRD', 5.00, 1, 1);

-- CPF duplicado (esperado: erro UNIQUE)
-- EXECUTAR SEPARADAMENTE
-- INSERT INTO tutor (nome, cpf, telefone)
-- VALUES ('Outro Tutor', '12345678901', '32900000000');

-- Prescrição com estoque insuficiente (esperado: erro da trigger)
-- EXECUTAR SEPARADAMENTE
-- INSERT INTO prescricao (posologia, quantidade, id_consulta, id_medicamento)
-- VALUES ('1 comprimido por dia', 999, 1, 2);

-- Valor de consulta negativo (esperado: erro CHECK)
-- EXECUTAR SEPARADAMENTE
-- INSERT INTO consulta (motivo, valor, id_animal, id_veterinario)
-- VALUES ('Teste invalido', -50.00, 1, 1);

-- ------------------------------------------------------------
-- 5.3 TRANSAÇÃO MANUAL — ROLLBACK
-- ------------------------------------------------------------

-- Transação que insere prescrição e é desfeita manualmente
START TRANSACTION;

INSERT INTO prescricao (posologia, quantidade, id_consulta, id_medicamento)
VALUES ('Uso emergencial — rollback teste', 5, 2, 2);

-- Verificar estoque antes do rollback
SELECT nome, estoque_atual FROM medicamento WHERE id_medicamento = 2;

ROLLBACK;

-- Verificar que o estoque voltou ao valor anterior
SELECT nome, estoque_atual FROM medicamento WHERE id_medicamento = 2;

-- ------------------------------------------------------------
-- 5.4 CONSULTAS DE VERIFICAÇÃO FINAL
-- ------------------------------------------------------------

-- Visão geral: consultas com animal, tutor e veterinário
SELECT
    c.id_consulta,
    a.nome                 AS animal,
    t.nome                 AS tutor,
    v.nome                 AS veterinario,
    c.data_consulta,
    c.motivo,
    c.status,
    c.valor
FROM consulta c
JOIN animal       a ON c.id_animal      = a.id_animal
JOIN tutor        t ON a.id_tutor       = t.id_tutor
JOIN veterinario  v ON c.id_veterinario = v.id_veterinario
ORDER BY c.data_consulta;

-- Prescrições com detalhes do medicamento
SELECT
    p.id_prescricao,
    a.nome                 AS animal,
    m.nome                 AS medicamento,
    p.posologia,
    p.quantidade
FROM prescricao p
JOIN consulta    c ON p.id_consulta    = c.id_consulta
JOIN animal      a ON c.id_animal      = a.id_animal
JOIN medicamento m ON p.id_medicamento = m.id_medicamento;

-- Estoque atual dos medicamentos
SELECT nome, principio_ativo, estoque_atual FROM medicamento;

-- ============================================================
-- FIM DOS TESTES
-- ============================================================

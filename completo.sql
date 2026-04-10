-- ============================================================
-- SISTEMA DE CLÍNICA VETERINÁRIA
-- Disciplina: Administração de Banco de Dados
-- SGBD: MySQL
-- ============================================================

DROP DATABASE IF EXISTS clinica_veterinaria;
CREATE DATABASE clinica_veterinaria
CHARACTER SET utf8mb4
COLLATE utf8mb4_unicode_ci;

USE clinica_veterinaria;

-- ============================================================
-- CRIAÇÃO DAS TABELAS
-- ============================================================

-- TABELA: Tutor (dono do animal)
DROP TABLE IF EXISTS tutor;
CREATE TABLE tutor (
  id_tutor       INT          NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(150) NOT NULL,
  cpf            CHAR(11)     NOT NULL,
  telefone       VARCHAR(20),
  email          VARCHAR(120),
  PRIMARY KEY (id_tutor),
  UNIQUE (cpf),
  CONSTRAINT chk_cpf CHECK (CHAR_LENGTH(cpf) = 11)
);

-- TABELA: Especie
DROP TABLE IF EXISTS especie;
CREATE TABLE especie (
  id_especie     INT          NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(80)  NOT NULL,
  PRIMARY KEY (id_especie),
  UNIQUE (nome)
);

-- TABELA: Animal
DROP TABLE IF EXISTS animal;
CREATE TABLE animal (
  id_animal      INT          NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(100) NOT NULL,
  raca           VARCHAR(100),
  data_nascimento DATE,
  peso_kg        DECIMAL(5,2),
  id_tutor       INT          NOT NULL,
  id_especie     INT          NOT NULL,
  PRIMARY KEY (id_animal),
  FOREIGN KEY (id_tutor)   REFERENCES tutor(id_tutor)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (id_especie) REFERENCES especie(id_especie)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_peso CHECK (peso_kg > 0)
);

-- TABELA: Veterinario
DROP TABLE IF EXISTS veterinario;
CREATE TABLE veterinario (
  id_veterinario INT          NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(150) NOT NULL,
  crmv           VARCHAR(20)  NOT NULL,
  especialidade  VARCHAR(100),
  PRIMARY KEY (id_veterinario),
  UNIQUE (crmv)
);

-- TABELA: Consulta
DROP TABLE IF EXISTS consulta;
CREATE TABLE consulta (
  id_consulta    INT          NOT NULL AUTO_INCREMENT,
  data_consulta  DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  motivo         VARCHAR(255) NOT NULL,
  diagnostico    TEXT,
  valor          DECIMAL(8,2) NOT NULL,
  status         ENUM('agendada','realizada','cancelada') NOT NULL DEFAULT 'agendada',
  id_animal      INT          NOT NULL,
  id_veterinario INT          NOT NULL,
  PRIMARY KEY (id_consulta),
  FOREIGN KEY (id_animal)      REFERENCES animal(id_animal)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  FOREIGN KEY (id_veterinario) REFERENCES veterinario(id_veterinario)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_valor CHECK (valor >= 0)
);

-- TABELA: Medicamento
DROP TABLE IF EXISTS medicamento;
CREATE TABLE medicamento (
  id_medicamento INT          NOT NULL AUTO_INCREMENT,
  nome           VARCHAR(150) NOT NULL,
  principio_ativo VARCHAR(150),
  estoque_atual  INT          NOT NULL DEFAULT 0,
  PRIMARY KEY (id_medicamento),
  UNIQUE (nome),
  CONSTRAINT chk_estoque CHECK (estoque_atual >= 0)
);

-- TABELA: Prescricao (relaciona consulta e medicamento)
DROP TABLE IF EXISTS prescricao;
CREATE TABLE prescricao (
  id_prescricao  INT          NOT NULL AUTO_INCREMENT,
  posologia      VARCHAR(255) NOT NULL,
  quantidade     INT          NOT NULL,
  id_consulta    INT          NOT NULL,
  id_medicamento INT          NOT NULL,
  PRIMARY KEY (id_prescricao),
  FOREIGN KEY (id_consulta)    REFERENCES consulta(id_consulta)
    ON DELETE CASCADE ON UPDATE CASCADE,
  FOREIGN KEY (id_medicamento) REFERENCES medicamento(id_medicamento)
    ON DELETE RESTRICT ON UPDATE CASCADE,
  CONSTRAINT chk_qtd CHECK (quantidade > 0)
);

-- ============================================================
-- TRIGGER: Deduzir estoque ao prescrever medicamento
-- ============================================================
DELIMITER $$

CREATE TRIGGER trg_baixa_estoque
BEFORE INSERT ON prescricao
FOR EACH ROW
BEGIN
    DECLARE estoque_disponivel INT;

    SELECT estoque_atual INTO estoque_disponivel
    FROM medicamento
    WHERE id_medicamento = NEW.id_medicamento;

    IF estoque_disponivel < NEW.quantidade THEN
        SIGNAL SQLSTATE '45000'
        SET MESSAGE_TEXT = 'Estoque insuficiente para o medicamento selecionado';
    ELSE
        UPDATE medicamento
        SET estoque_atual = estoque_atual - NEW.quantidade
        WHERE id_medicamento = NEW.id_medicamento;
    END IF;
END$$

DELIMITER ;

-- ============================================================
-- PROCEDURE: Registrar consulta e retornar confirmação
-- ============================================================
DELIMITER $$

CREATE PROCEDURE sp_agendar_consulta(
    IN p_motivo        VARCHAR(255),
    IN p_valor         DECIMAL(8,2),
    IN p_id_animal     INT,
    IN p_id_veterinario INT,
    IN p_data          DATETIME
)
BEGIN
    DECLARE EXIT HANDLER FOR SQLEXCEPTION
    BEGIN
        ROLLBACK;
        RESIGNAL;
    END;

    START TRANSACTION;

    INSERT INTO consulta (data_consulta, motivo, valor, status, id_animal, id_veterinario)
    VALUES (p_data, p_motivo, p_valor, 'agendada', p_id_animal, p_id_veterinario);

    COMMIT;

    SELECT LAST_INSERT_ID() AS id_consulta_gerado,
           'Consulta agendada com sucesso' AS mensagem;
END$$

DELIMITER ;
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

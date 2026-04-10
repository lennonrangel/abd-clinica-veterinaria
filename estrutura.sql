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

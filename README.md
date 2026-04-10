# 🐾 Sistema de Clínica Veterinária

Projeto desenvolvido para a disciplina de Administração de Banco de Dados, com foco na modelagem, implementação e validação de um sistema de clínica veterinária utilizando MySQL.

---

## 🎯 Objetivo

Implementar um banco de dados relacional capaz de gerenciar tutores, animais, veterinários, consultas, medicamentos e prescrições, garantindo a integridade dos dados por meio de restrições, trigger e procedure com controle de transação.

---

## 🧠 Funcionalidades

* Cadastro de **tutores** (donos dos animais)
* Cadastro de **espécies** e **animais**
* Cadastro de **veterinários**
* Registro de **consultas**
* Controle de **medicamentos** e **prescrições**
* Atualização automática do estoque de medicamentos via **trigger**
* Agendamento de consultas via **stored procedure** com **transação**
* Validação de integridade com:
  * `PRIMARY KEY`
  * `FOREIGN KEY` (com `RESTRICT` e `CASCADE`)
  * `UNIQUE`
  * `NOT NULL`
  * `CHECK`
  * `ENUM`

---

## ⚙️ Tecnologias Utilizadas

* MySQL 8.0
* MySQL Workbench / DBeaver
* brModelo (modelagem)

---

## 🚀 Como Executar

1. Abra o MySQL Workbench ou DBeaver
2. Conecte a uma instância MySQL 8.0+
3. Execute: `sql/estrutura.sql`
4. Execute: `sql/testes.sql`
5. Os comandos de teste de erro estão **comentados** — descomente e execute separadamente para ver os erros esperados

---

## ⚙️ Trigger

`trg_baixa_estoque` — **BEFORE INSERT** na tabela `prescricao`:
- Verifica se o estoque do medicamento é suficiente
- Se sim: debita o estoque automaticamente
- Se não: bloqueia a operação com `SIGNAL SQLSTATE '45000'`

## ⚙️ Stored Procedure

`sp_agendar_consulta` — encapsula a inserção de uma consulta em uma transação com handler de exceção para ROLLBACK automático em caso de falha.

---

## 🧪 Testes Realizados

* Inserções válidas em todas as tabelas
* Violação de CHECK (peso negativo, valor negativo)
* Violação de NOT NULL (nome nulo)
* Violação de UNIQUE (CPF duplicado)
* Estoque insuficiente bloqueado pela trigger
* ROLLBACK manual revertendo prescrição e estoque
* Consultas JOIN para verificação dos dados

CREATE TABLE associado (
  id           INT PRIMARY KEY,
  nome         VARCHAR(100) NOT NULL,
  sobrenome    VARCHAR(100) NOT NULL,
  idade        INT,
  email        VARCHAR(150)
);

CREATE TABLE conta (
  id            INT PRIMARY KEY,
  tipo          VARCHAR(30) NOT NULL,
  data_criacao  TIMESTAMP NOT NULL,
  id_associado  INT NOT NULL REFERENCES associado(id)
);

CREATE TABLE cartao (
  id           INT PRIMARY KEY,
  num_cartao   BIGINT NOT NULL,
  nom_impresso VARCHAR(100),
  data_criacao TIMESTAMP NOT NULL,
  id_conta     INT NOT NULL REFERENCES conta(id),
  id_associado INT NOT NULL REFERENCES associado(id)
);

CREATE TABLE movimento (
  id              INT PRIMARY KEY,
  vlr_transacao   DECIMAL(10,2) NOT NULL,
  des_transacao   VARCHAR(200),
  data_movimento  TIMESTAMP NOT NULL,
  id_cartao       INT NOT NULL REFERENCES cartao(id)
);

CREATE INDEX idx_movimento_id_cartao ON movimento(id_cartao);
CREATE INDEX idx_cartao_id_conta ON cartao(id_conta);
CREATE INDEX idx_conta_id_associado ON conta(id_associado);

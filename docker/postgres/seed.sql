INSERT INTO associado (id, nome, sobrenome, idade, email) VALUES
(1,'Ana','Silva',29,'ana.silva@sicoop.com'),
(2,'Bruno','Souza',41,'bruno.souza@sicoop.com');

INSERT INTO conta (id, tipo, data_criacao, id_associado) VALUES
(10,'CORRENTE','2024-01-10 10:00:00',1),
(11,'POUPANCA','2024-02-05 09:30:00',1),
(20,'CORRENTE','2024-03-01 14:20:00',2);

INSERT INTO cartao (id, num_cartao, nom_impresso, data_criacao, id_conta, id_associado) VALUES
(100, 5533441100220033,'ANA S SILVA','2024-01-15 08:00:00',10,1),
(101, 5533441100220044,'ANA S SILVA','2024-02-10 11:00:00',11,1),
(200, 4411223300445566,'BRUNO SOUZA','2024-03-02 10:00:00',20,2);

INSERT INTO movimento (id, vlr_transacao, des_transacao, data_movimento, id_cartao) VALUES
(1000, 120.50,'SUPERMERCADO','2025-01-05 12:01:00',100),
(1001,  15.90,'CAFETERIA','2025-01-05 16:10:00',100),
(1002, 250.00,'ELETRO','2025-01-06 11:00:00',101),
(2000,  89.99,'FARMACIA','2025-01-07 19:45:00',200);

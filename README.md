# SiCooperative LTDA — Data Lake POC

![Python](https://img.shields.io/badge/Python-3.11+-blue)
![Spark](https://img.shields.io/badge/Apache%20Spark-3.x-orange)
![PostgreSQL](https://img.shields.io/badge/PostgreSQL-15-blue)
![Docker](https://img.shields.io/badge/Docker-Compose-2496ED)
![Tests](https://img.shields.io/badge/tests-passing-brightgreen)
![License](https://img.shields.io/badge/license-MIT-green)

### Spark • PostgreSQL • Docker • Pytest

---

# 1. Visão Executiva

A **SiCooperative LTDA** enfrentava um desafio clássico de maturidade analítica:

* dados fragmentados em múltiplos relatórios
* correlação manual de informações
* baixa velocidade de decisão estratégica
* ausência de base estruturada para **Data Science**

Como resposta, foi iniciada uma **POC de Data Lake**, priorizando o domínio de:

**Movimentações de Cartões dos Associados**

Relacionamentos envolvidos:

* Associado
* Conta
* Cartão
* Movimento

O objetivo técnico foi consolidar essas entidades em uma **visão analítica única**, pronta para consumo por:

* BI
* Analytics
* Machine Learning

Esta POC demonstra, de forma prática, a construção de um pipeline analítico **reprodutível, testável e pronto para evolução** em ambientes corporativos de dados.

---

# 2. Objetivo da Solução

Esta POC implementa:

* Banco relacional com **massa de dados fictícia**
* Pipeline ETL distribuído com **Apache Spark**
* Consolidação relacional em **CSV analítico único**
* Ambiente totalmente **reprodutível via Docker**
* **Testes automatizados** garantindo qualidade dos dados
* Estrutura preparada para **evolução Lakehouse**

Saída final:

```
output/movimento_flat/movimento_flat.csv
```

---

# 3. Arquitetura de Referência

## Componentes

* **PostgreSQL** → fonte transacional simulada (OLTP)
* **Apache Spark (PySpark)** → processamento distribuído ETL
* **Docker Compose** → provisionamento e orquestração local
* **CSV Analítico** → camada inicial de consumo

## Fluxo de Dados

```
PostgreSQL (OLTP)
        ↓ JDBC
Apache Spark (ETL distribuído)
        ↓
CSV Analítico Consolidado
        ↓
BI • Data Science • Lakehouse futuro
```

Essa arquitetura replica um **padrão corporativo real de ingestão analítica**.

---

# 4. Stack Tecnológica

| Camada        | Tecnologia     | Justificativa                            |
| ------------- | -------------- | ---------------------------------------- |
| Banco OLTP    | PostgreSQL     | Open source, robusto, padrão de mercado  |
| Processamento | Apache Spark   | Engine distribuída líder em Big Data     |
| Orquestração  | Docker Compose | Reprodutibilidade e portabilidade        |
| Qualidade     | Pytest         | Garantia de integridade do pipeline      |
| Saída         | CSV            | Simplicidade e compatibilidade universal |

---

# 5. Pré-requisitos

Instalar:

### Git

https://git-scm.com/downloads

### Docker Desktop

https://www.docker.com/products/docker-desktop/

### WSL2 (Windows)

https://learn.microsoft.com/windows/wsl/install

Instalação rápida:

```powershell
wsl --install
```

Reinicie a máquina após instalar.

---

# 6. Estrutura do Projeto

```
sicoop-lake-poc/
├─ docker/
│  ├─ postgres/
│  │  ├─ schema.sql
│  │  └─ seed.sql
│  └─ spark/
│     ├─ Dockerfile
│     └─ jars/postgresql.jar
├─ src/job_flatten.py
├─ tests/test_transformations.py
├─ scripts/run_local.sh
├─ Makefile
├─ requirements-dev.txt
├─ docker-compose.yml
├─ output/
└─ README.md
```

Estrutura alinhada a **boas práticas de engenharia de dados**.

---

# 7. Banco de Dados

O PostgreSQL é inicializado automaticamente com:

* criação de schema
* carga de dados fictícios

Arquivos:

```
docker/postgres/schema.sql  
docker/postgres/seed.sql
```

Simula uma **fonte operacional real**.

---

# 8. Pipeline ETL com Spark

Script principal:

```
src/job_flatten.py
```

Responsável por:

* leitura distribuída via **JDBC**
* joins relacionais entre entidades
* projeção do **modelo analítico final**
* escrita em CSV com **coalesce(1)**
* pós-processamento para gerar **arquivo único limpo**

---

# 9. Execução Automatizada

## Rodar pipeline completo

```bash
make run
```

Fluxo executado:

1. build Docker
2. subida do PostgreSQL
3. execução Spark Submit
4. limpeza de arquivos auxiliares
5. geração do CSV final

---

# 10. Qualidade de Dados (Testes)

Testes automatizados com **Pytest** validam:

### Resultado dos Testes Automatizados

Após a execução dos testes unitários com:

Executar:

```bash
make test
```

foi obtido o seguinte resultado:

```
5 passed in 5.10s
```

#### Interpretação Técnica

Esse resultado confirma que os principais critérios de qualidade do pipeline foram atendidos:

* **Schema final validado**
  As colunas esperadas existem, com nomes e ordem corretos.

* **Integridade dos dados garantida**
  Nenhum valor essencial está ausente ou inconsistente após as transformações.

* **Tipos de dados normalizados corretamente**
  Campos numéricos e datas foram convertidos conforme o layout analítico definido.

* **Ausência de duplicidades indevidas**
  O processo de junção entre tabelas manteve cardinalidade consistente.

* **Pipeline ETL funcional e determinístico**
  A transformação produz sempre a mesma estrutura e resultado esperado.

#### Conclusão

Os testes confirmam que a **POC está estável, consistente e pronta para evolução**
para cenários mais avançados, como:

* escrita em **Parquet / Delta Lake**
* execução em **orquestradores corporativos**
* integração com **dashboards e modelos de Machine Learning**

Em síntese, os testes demonstram que o pipeline é **determinístico, confiável
e pronto para evolução para ambientes produtivos**.

---

# 11. Layout Analítico Final

Campos disponíveis:

* nome_associado
* sobrenome_associado
* idade_associado
* vlr_transacao_movimento
* des_transacao_movimento
* data_movimento
* numero_cartao
* nome_impresso_cartao
* data_criacao_cartao
* tipo_conta
* data_criacao_conta

Modelo pronto para **consumo analítico imediato**.

---

# 12. Execução do Zero

```bash
git clone <repo-privado>
cd sicoop-lake-poc
make run
make test
```

Saída:

```
output/movimento_flat/movimento_flat.csv
```

---

# 13. Integração Contínua (CI)

O projeto está preparado para:

* execução automática de **pytest**
* validação de integridade de dados
* garantia de build reprodutível

Evolução natural:

* **GitHub Actions**
* **pipelines corporativos**
* **DataOps completo**

---

### 14. Decisões Arquiteturais

A definição da stack tecnológica desta POC foi guiada por quatro princípios fundamentais de engenharia de dados moderna:

* **aderência ao cenário real de mercado**
* **simplicidade de reprodução local**
* **capacidade de evolução para produção**
* **alinhamento com arquiteturas Lakehouse**

Abaixo estão as justificativas técnicas detalhadas para cada componente adotado.

---

### PostgreSQL — Simulação de Fonte OLTP Real

O **PostgreSQL** foi escolhido como banco relacional por representar com fidelidade o comportamento de sistemas transacionais corporativos (OLTP), que normalmente são a origem de dados para plataformas analíticas.

Principais fatores da escolha:

* **Open source, estável e amplamente adotado no mercado**, reduzindo dependência de tecnologias proprietárias.
* **Compatível com SQL ANSI**, facilitando portabilidade para outros SGBDs corporativos (Oracle, SQL Server, MySQL).
* **Integração nativa com Apache Spark via JDBC**, permitindo leitura distribuída sem necessidade de conectores proprietários.
* Capacidade de simular **modelos relacionais normalizados típicos de sistemas bancários e financeiros**, aderentes ao domínio do desafio.

Dentro da arquitetura, o PostgreSQL cumpre o papel de:

```
Fonte operacional de dados (OLTP) → ponto de ingestão analítica
```

Essa separação entre **camada transacional** e **camada analítica** é um padrão essencial em ambientes corporativos.

---

### Apache Spark — Motor de Processamento Distribuído

O **Apache Spark** foi selecionado como engine de transformação por ser atualmente um dos principais padrões de mercado para processamento de dados em larga escala.

Motivações técnicas:

* Arquitetura **distribuída e paralela**, preparada para volumes muito superiores aos utilizados na POC.
* Ecossistema consolidado em plataformas corporativas como **Databricks, Azure Fabric, AWS EMR e Google Dataproc**.
* Suporte nativo a múltiplas fontes e formatos de dados (**JDBC, Parquet, Delta Lake, APIs, streaming**), garantindo extensibilidade.
* Capacidade de executar **transformações complexas com alto desempenho**, requisito fundamental em pipelines analíticos.
* Aderência direta ao requisito do desafio de utilizar um **framework distribuído de Big Data**.

Arquiteturalmente, o Spark ocupa a camada de:

```
Processamento analítico distribuído (ETL/ELT)
```

Além disso, sua adoção permite evolução natural para:

* **Lakehouse com Delta Lake**
* **processamento incremental**
* **orquestração em cloud**
* **integração com Machine Learning**

---

### CSV Analítico — Camada Inicial de Consumo

O uso de **CSV consolidado** como saída da POC não foi apenas uma escolha de simplicidade, mas uma decisão estratégica para a fase de validação.

Razões principais:

* **Formato universal**, compatível com praticamente todas as ferramentas de BI, analytics e ciência de dados.
* Permite **verificação rápida da consistência do pipeline**, essencial em uma prova de conceito.
* Representa uma **camada intermediária comum** antes da adoção de formatos colunares otimizados.

Embora não seja o formato ideal para produção em larga escala, o CSV cumpre o papel de:

```
Validação funcional do pipeline → preparação para evolução Lakehouse
```

A evolução planejada inclui:

* **Parquet** → compressão e leitura colunar eficiente
* **Delta Lake** → versionamento, ACID e schema evolution
* **particionamento temporal** → performance analítica

---

### Docker Compose — Reprodutibilidade e Base para DataOps

O **Docker Compose** foi adotado como mecanismo de provisionamento por garantir que todo o ambiente da POC seja:

* **reproduzível em qualquer máquina**, independente de sistema operacional.
* isolado de configurações locais, eliminando o clássico problema
  **“funciona na minha máquina”**.
* capaz de subir automaticamente todos os componentes necessários:

  * banco PostgreSQL
  * engine Spark
  * execução do pipeline ETL

Do ponto de vista arquitetural, o Docker representa a fundação para:

* **Infraestrutura como Código (IaC)**
* **pipelines de CI/CD**
* **execução em ambientes cloud ou Kubernetes**
* práticas modernas de **DataOps**

Assim, mesmo sendo uma POC local, a solução já nasce preparada para:

```
Ambiente local → CI/CD → Cloud → Produção corporativa
```

---

### Síntese Arquitetural

A combinação dessas tecnologias estabelece uma arquitetura coerente com padrões reais de engenharia de dados:

```
Fonte OLTP (PostgreSQL)
        ↓
Processamento Distribuído (Spark)
        ↓
Camada Analítica Inicial (CSV)
        ↓
Evolução Natural → Lakehouse Corporativo
```

Dessa forma, a POC deixa de ser apenas um exercício técnico
e passa a representar uma **base arquitetural pronta para produção**.


---

# 15. Roadmap de Evolução

* Parquet / Delta Lake
* Particionamento temporal
* Carga incremental (CDC)
* Observabilidade de pipeline
* Deploy em **Azure Fabric / Databricks**
* Orquestração com **Airflow**

Transformando a POC em **plataforma analítica produtiva**.

---

# 16. Autor

**Lindberg Gualberto Ferreira**
*Mestre Big Data • Data Engineer*

Projeto desenvolvido como demonstração prática de:

* Engenharia de Dados Moderna
* Arquitetura Lakehouse
* Data Quality automatizada
* Reprodutibilidade corporativa

---

# 17. Licença

Este projeto é disponibilizado sob a licença MIT.

Uso livre para fins educacionais, demonstrações técnicas
e evolução para projetos corporativos.

---

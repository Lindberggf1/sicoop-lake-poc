#!/usr/bin/env bash
set -euo pipefail

# ============================================================
# run_local.sh (FINAL - versão "produção/entrevista")
#
# O que este script faz:
# 1) Sobe Postgres + Spark via Docker Compose
# 2) Espera o Postgres ficar pronto (pg_isready)
# 3) Roda o job Spark gravando em /tmp (dentro do container)
#    - Evita erro comum em WSL/Windows volume:
#      "chmod: Operation not permitted" ao criar diretório em /opt/output
# 4) Copia o resultado do /tmp para /opt/output (volume -> ./output no host)
# 5) (Opcional) Gera um CSV único movimento_flat.csv no host
# 6) Remove arquivos auxiliares do Hadoop/Spark (_SUCCESS, *.crc)
# 7) Valida se o CSV foi gerado
#
# Requisitos:
# - docker compose
# - docker-compose.yml com:
#   - ./src:/opt/app/src
#   - ./output:/opt/output
# - Job: /opt/app/src/job_flatten.py
# - Postgres: service "postgres", user/db conforme abaixo
# ============================================================

COMPOSE_FILE="docker-compose.yml"
SPARK_SERVICE="spark"
POSTGRES_SERVICE="postgres"

# Host/Volume
HOST_OUTPUT_DIR="./output"
CONTAINER_OUTPUT_DIR="/opt/output"
FINAL_OUTPUT_DIR_IN_VOLUME="${CONTAINER_OUTPUT_DIR}/movimento_flat"

# Output temporário dentro do container (não é volume Windows)
TMP_OUTPUT_DIR_IN_CONTAINER="/tmp/movimento_flat"

# Caminho do job dentro do container (via volume ./src:/opt/app/src)
JOB_PATH_IN_CONTAINER="/opt/app/src/job_flatten.py"

# JDBC
JDBC_URL="jdbc:postgresql://postgres:5432/sicoopdb"
JDBC_USER="sicoop"
JDBC_PASSWORD="sicoop"
JDBC_DB="sicoopdb"

# Se quiser manter containers ligados após execução, rode:
#   KEEP_UP=1 ./scripts/run_local.sh
KEEP_UP="${KEEP_UP:-0}"

log() { echo -e "==> $*"; }
die() { echo -e "ERRO: $*" >&2; exit 1; }

cleanup() {
  if [[ "$KEEP_UP" == "1" ]]; then
    log "KEEP_UP=1 -> Mantendo containers em execução (sem docker compose down)."
    return 0
  fi
  log "Derrubando ambiente..."
  docker compose -f "$COMPOSE_FILE" down -v >/dev/null 2>&1 || true
}
trap cleanup EXIT

# ============================================================
# 0) Pré-checagens
# ============================================================
[[ -f "$COMPOSE_FILE" ]] || die "Não encontrei ${COMPOSE_FILE} no diretório atual."
[[ -d "./src" ]] || die "Não encontrei ./src. Confirme o volume ./src:/opt/app/src."
mkdir -p "${HOST_OUTPUT_DIR}"

# ============================================================
# 1) Sobe o ambiente em background
# ============================================================
log "Subindo ambiente (background) via Docker Compose..."
docker compose -f "$COMPOSE_FILE" up -d --build

# ============================================================
# 2) Espera Postgres ficar pronto
# ============================================================
log "Aguardando Postgres ficar pronto..."
for i in {1..45}; do
  if docker compose -f "$COMPOSE_FILE" exec -T "$POSTGRES_SERVICE" \
      pg_isready -U "$JDBC_USER" -d "$JDBC_DB" >/dev/null 2>&1; then
    log "Postgres OK."
    break
  fi
  sleep 1
  if [[ "$i" -eq 45 ]]; then
    docker compose -f "$COMPOSE_FILE" logs --no-color --tail=200 "$POSTGRES_SERVICE" || true
    die "Postgres não ficou pronto a tempo."
  fi
done

# ============================================================
# 3) Limpa outputs anteriores no container
# ============================================================
log "Limpando outputs anteriores no container (tmp e volume)..."
docker compose -f "$COMPOSE_FILE" exec -T "$SPARK_SERVICE" bash -lc "
  rm -rf '${TMP_OUTPUT_DIR_IN_CONTAINER}' '${FINAL_OUTPUT_DIR_IN_VOLUME}' || true
  mkdir -p '${TMP_OUTPUT_DIR_IN_CONTAINER}'
  mkdir -p '${CONTAINER_OUTPUT_DIR}'
"

# ============================================================
# 4) Rodar o Spark escrevendo em /tmp (evita chmod no volume)
# ============================================================
log "Executando job Spark gravando em ${TMP_OUTPUT_DIR_IN_CONTAINER} (dentro do container)..."

set +e
docker compose -f "$COMPOSE_FILE" exec -T "$SPARK_SERVICE" \
  /opt/spark/bin/spark-submit \
  --jars /opt/jars/postgresql.jar \
  "$JOB_PATH_IN_CONTAINER" \
  --jdbc_url "$JDBC_URL" \
  --jdbc_user "$JDBC_USER" \
  --jdbc_password "$JDBC_PASSWORD" \
  --output_dir "$TMP_OUTPUT_DIR_IN_CONTAINER" \
  --coalesce 1
SPARK_EXIT_CODE=$?
set -e

log "Spark exit code: ${SPARK_EXIT_CODE}"

if [[ "$SPARK_EXIT_CODE" -ne 0 ]]; then
  log "Job Spark falhou. Últimos logs do Spark:"
  docker compose -f "$COMPOSE_FILE" logs --no-color --tail=250 "$SPARK_SERVICE" || true
  exit "$SPARK_EXIT_CODE"
fi

# ============================================================
# 5) Copiar resultado do /tmp para /opt/output (volume do host)
# ============================================================
log "Copiando resultado de ${TMP_OUTPUT_DIR_IN_CONTAINER} para ${FINAL_OUTPUT_DIR_IN_VOLUME} (volume)..."

docker compose -f "$COMPOSE_FILE" exec -T "$SPARK_SERVICE" bash -lc "
  echo '--- Conteúdo gerado no /tmp:'
  ls -la '${TMP_OUTPUT_DIR_IN_CONTAINER}' || true

  if ! ls '${TMP_OUTPUT_DIR_IN_CONTAINER}'/part-*.csv >/dev/null 2>&1; then
    echo 'ERRO: não encontrou part-*.csv em ${TMP_OUTPUT_DIR_IN_CONTAINER}'
    exit 2
  fi

  # Copia pasta inteira para o volume
  cp -R '${TMP_OUTPUT_DIR_IN_CONTAINER}' '${FINAL_OUTPUT_DIR_IN_VOLUME}'
  echo '--- Conteúdo no volume após cópia:'
  ls -la '${FINAL_OUTPUT_DIR_IN_VOLUME}' || true
"

# ============================================================
# 6) Validação no HOST: pasta e arquivos part-*.csv
# ============================================================
log "Validando saída no host: ${HOST_OUTPUT_DIR}"

[[ -d "${HOST_OUTPUT_DIR}/movimento_flat" ]] || die "Pasta ${HOST_OUTPUT_DIR}/movimento_flat não encontrada."
log "Arquivos gerados (pasta):"
ls -la "${HOST_OUTPUT_DIR}/movimento_flat" || true

PART_FILE="$(ls -1 "${HOST_OUTPUT_DIR}/movimento_flat"/part-*.csv 2>/dev/null | head -n 1 || true)"
[[ -n "$PART_FILE" ]] || die "Nenhum part-*.csv encontrado em ${HOST_OUTPUT_DIR}/movimento_flat."

# ============================================================
# 7) Consolidar saída final dentro da pasta movimento_flat
# ============================================================

FINAL_DIR="${HOST_OUTPUT_DIR}/movimento_flat"
FINAL_CSV="${FINAL_DIR}/movimento_flat.csv"

log "Consolidando CSV final em: ${FINAL_CSV}"

# Garante que existe part-*.csv
PART_FILE=$(ls -1 "${FINAL_DIR}"/part-*.csv 2>/dev/null | head -n 1 || true)

if [[ -z "${PART_FILE}" ]]; then
  die "Nenhum part-*.csv encontrado em ${FINAL_DIR}"
fi

# Copia como arquivo final único
cp -f "${PART_FILE}" "${FINAL_CSV}"

log "CSV final criado com sucesso."

# ============================================================
# 8) Limpeza final – deixar apenas movimento_flat.csv
# ============================================================

log "Removendo arquivos auxiliares do Spark..."

# Remove part-*.csv
find "${FINAL_DIR}" -type f -name "part-*.csv" -delete

# Remove arquivos auxiliares do Hadoop
find "${FINAL_DIR}" -type f -name "*.crc" -delete
rm -f "${FINAL_DIR}/_SUCCESS" "${FINAL_DIR}/_SUCCESS.crc" 2>/dev/null || true

log "Estrutura final:"
ls -la "${FINAL_DIR}"

# ============================================================
# 9) Quick check do CSV final
# ============================================================
log "Primeiras linhas do CSV final:"
head -n 20 "${HOST_OUTPUT_DIR}/movimento_flat.csv" || true

log "Finalizado com sucesso."
log "Saídas:"
log " - Pasta: ${HOST_OUTPUT_DIR}/movimento_flat/"
log " - Arquivo único: ${HOST_OUTPUT_DIR}/movimento_flat.csv"

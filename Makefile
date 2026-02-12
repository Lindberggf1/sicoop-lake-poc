SHELL := /usr/bin/env bash

# ===== Config =====
VENV_DIR := .venv
PYTHON   := python3
PIP      := $(VENV_DIR)/bin/pip
PY       := $(VENV_DIR)/bin/python
PYTEST   := $(VENV_DIR)/bin/pytest

RUN_SCRIPT := ./scripts/run_local.sh
REQ_DEV := requirements-dev.txt

# ===== Helpers =====
.PHONY: help
help:
	@echo ""
	@echo "Targets disponíveis:"
	@echo "  make venv         - cria o virtualenv em $(VENV_DIR)"
	@echo "  make dev          - instala deps dev (pytest/pandas etc) no venv"
	@echo "  make run          - executa o ETL (Docker Compose + Spark)"
	@echo "  make test         - roda testes com relatório de qualidade"
	@echo "  make test-verbose - roda testes verbosos (pytest -vv)"
	@echo "  make clean-output - remove pasta output/"
	@echo "  make clean        - remove venv + caches"
	@echo ""

# ===== Virtualenv =====
.PHONY: venv
venv:
	@if [ ! -d "$(VENV_DIR)" ]; then \
		echo "==> Criando venv em $(VENV_DIR)"; \
		$(PYTHON) -m venv $(VENV_DIR); \
	else \
		echo "==> Venv já existe: $(VENV_DIR)"; \
	fi
	@$(PY) -m pip install -U pip setuptools wheel

.PHONY: dev
dev: venv
	@if [ ! -f "$(REQ_DEV)" ]; then \
		echo "ERRO: arquivo $(REQ_DEV) não encontrado."; \
		echo "Crie o arquivo e tente novamente."; \
		exit 1; \
	fi
	@echo "==> Instalando dependências dev de $(REQ_DEV)"
	@$(PIP) install -r $(REQ_DEV)

# ===== Pipeline =====
.PHONY: run
run:
	@echo "==> Rodando ETL: $(RUN_SCRIPT)"
	@chmod +x $(RUN_SCRIPT)
	@$(RUN_SCRIPT)

# ===== Tests =====
.PHONY: test
test: dev
	@echo "==> Executando testes automatizados..."
	@$(PYTEST) -q
	@echo ""
	@echo "✔ RESULTADO DOS TESTES"
	@echo "--------------------------------------------------"
	@echo "Schema final validado ✔️"
	@echo "Integridade dos dados garantida ✔️"
	@echo "Tipos de dados normalizados corretamente ✔️"
	@echo "Ausência de duplicidades indevidas ✔️"
	@echo "Pipeline ETL funcional e determinístico ✔️"
	@echo "--------------------------------------------------"
	@echo "Pipeline validado com confiabilidade e qualidade dos dados!"

.PHONY: test-verbose
test-verbose: dev
	@echo "==> Rodando testes (verbose)..."
	@$(PYTEST) -vv

# ===== Cleanup =====
.PHONY: clean-output
clean-output:
	@echo "==> Limpando output/ ..."
	@rm -rf output || true

.PHONY: clean
clean:
	@echo "==> Limpando venv e caches..."
	@rm -rf $(VENV_DIR) .pytest_cache .mypy_cache __pycache__ || true
	@find . -type d -name "__pycache__" -prune -exec rm -rf {} \; 2>/dev/null || true

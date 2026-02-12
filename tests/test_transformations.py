import os
import pandas as pd
import pytest

# CSV final gerado pelo seu run_local.sh (dentro da pasta movimento_flat)
CSV_PATH = os.path.join("output", "movimento_flat", "movimento_flat.csv")

# Colunas exatamente como no seu job_flatten.py (mesma ordem)
EXPECTED_COLUMNS = [
    "nome_associado",
    "sobrenome_associado",
    "idade_associado",
    "vlr_transacao_movimento",
    "des_transacao_movimento",
    "data_movimento",
    "numero_cartao",
    "nome_impresso_cartao",
    "data_criacao_cartao",
    "tipo_conta",
    "data_criacao_conta",
]


def _is_blank_series(s: pd.Series) -> pd.Series:
    """Retorna True onde a célula é nula ou string vazia/espacos."""
    return s.isna() | s.astype(str).str.strip().eq("")


@pytest.fixture(scope="session")
def df():
    """
    Carrega o CSV final uma vez por sessão de testes.
    Observação: seu job já faz cast para string em idade/valor/datas,
    então ler como string é esperado.
    """
    assert os.path.exists(CSV_PATH), (
        f"CSV não encontrado em: {CSV_PATH}\n"
        "Execute primeiro: ./scripts/run_local.sh"
    )

    # Lê tudo como string pra refletir seu cast("string") no Spark
    df = pd.read_csv(CSV_PATH, dtype=str)

    # Normaliza colunas (opcional, mas ajuda se vierem espaços acidentais)
    df.columns = [c.strip() for c in df.columns]

    return df


def test_schema_columns_exact_and_order(df):
    """Valida nomes e ORDEM das colunas (deve bater 1:1 com o select do job)."""
    assert list(df.columns) == EXPECTED_COLUMNS


def test_row_count_positive(df):
    """O arquivo precisa ter pelo menos 1 registro."""
    assert len(df) > 0


def test_integrity_required_fields_not_null_or_blank(df):
    """
    Valida integridade mínima:
    - numero_cartao, data_movimento, vlr_transacao_movimento não podem ser nulos/vazios
    - tipo_conta não pode ser nulo/vazio (vem da conta)
    """
    required = ["numero_cartao", "data_movimento", "vlr_transacao_movimento", "tipo_conta"]

    for col in required:
        assert col in df.columns
        blanks = _is_blank_series(df[col])
        assert (~blanks).all(), f"Encontrou nulos/vazios em {col}"


def test_idade_and_valor_are_numeric(df):
    """
    idade_associado e vlr_transacao_movimento devem ser numéricos.
    (Seu job escreve como string, então validamos parse numérico aqui.)
    """
    idade = pd.to_numeric(df["idade_associado"], errors="coerce")
    assert idade.notna().all(), "idade_associado tem valores não numéricos"
    assert (idade >= 0).all(), "idade_associado tem valores negativos"

    valor = pd.to_numeric(df["vlr_transacao_movimento"], errors="coerce")
    assert valor.notna().all(), "vlr_transacao_movimento tem valores não numéricos"


def test_no_fully_duplicated_rows(df):
    """
    Bônus: evita linhas totalmente duplicadas (mesmo conteúdo em todas as colunas).
    Se você espera duplicidade legítima, pode remover este teste.
    """
    duplicated = df.duplicated(keep=False)
    assert not duplicated.any(), "Existem linhas totalmente duplicadas no CSV final"

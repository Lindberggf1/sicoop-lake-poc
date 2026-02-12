import argparse
from pyspark.sql import SparkSession
from pyspark.sql import functions as F

def read_table(spark, jdbc_url, user, password, table):
    return (
        spark.read.format("jdbc")
        .option("url", jdbc_url)
        .option("dbtable", table)
        .option("user", user)
        .option("password", password)
        .option("driver", "org.postgresql.Driver")
        .load()
    )

def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--jdbc_url", required=True)
    parser.add_argument("--jdbc_user", required=True)
    parser.add_argument("--jdbc_password", required=True)
    parser.add_argument("--output_dir", required=True)
    parser.add_argument("--coalesce", type=int, default=1)
    args = parser.parse_args()

    spark = SparkSession.builder.appName("sicoop-movimento-flat").getOrCreate()

    associado = read_table(spark, args.jdbc_url, args.jdbc_user, args.jdbc_password, "associado").alias("a")
    conta     = read_table(spark, args.jdbc_url, args.jdbc_user, args.jdbc_password, "conta").alias("c")
    cartao    = read_table(spark, args.jdbc_url, args.jdbc_user, args.jdbc_password, "cartao").alias("ct")
    movimento = read_table(spark, args.jdbc_url, args.jdbc_user, args.jdbc_password, "movimento").alias("m")

    df = (
        movimento
        .join(cartao, F.col("m.id_cartao") == F.col("ct.id"), "inner")
        .join(conta,  F.col("ct.id_conta") == F.col("c.id"), "inner")
        .join(associado, F.col("ct.id_associado") == F.col("a.id"), "inner")
        .select(
            F.col("a.nome").alias("nome_associado"),
            F.col("a.sobrenome").alias("sobrenome_associado"),
            F.col("a.idade").cast("string").alias("idade_associado"),
            F.col("m.vlr_transacao").cast("string").alias("vlr_transacao_movimento"),
            F.col("m.des_transacao").alias("des_transacao_movimento"),
            F.col("m.data_movimento").cast("string").alias("data_movimento"),
            F.col("ct.num_cartao").cast("string").alias("numero_cartao"),
            F.col("ct.nom_impresso").alias("nome_impresso_cartao"),
            F.col("ct.data_criacao").cast("string").alias("data_criacao_cartao"),
            F.col("c.tipo").alias("tipo_conta"),
            F.col("c.data_criacao").cast("string").alias("data_criacao_conta"),
        )
    )

    (
        df.coalesce(args.coalesce)
        .write.mode("overwrite")
        .option("header", True)
        .csv(args.output_dir)
    )

    spark.stop()

if __name__ == "__main__":
    main()
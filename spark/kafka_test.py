from pyspark.sql import SparkSession

spark = SparkSession.builder \
    .appName("StreamProcessor") \
    .getOrCreate()

spark.sparkContext.setLogLevel('WARN')

# Kafka configurations
kafka_bootstrap_servers = "kafkaservice:9092"
kafka_topic = "redditcomments"

# Read from Kafka
df = spark \
    .readStream \
    .format("kafka") \
    .option("kafka.bootstrap.servers", kafka_bootstrap_servers) \
    .option("subscribe", kafka_topic) \
    .load()

# Process the Kafka messages
query = df \
    .selectExpr("CAST(key AS STRING)", "CAST(value AS STRING)") \
    .writeStream \
    .outputMode("append") \
    .format("console") \
    .start()

query.awaitTermination()
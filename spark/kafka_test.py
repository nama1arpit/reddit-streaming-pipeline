from pyspark import SparkSession

spark = SparkSession \
    .builder \
    .appName("APP") \
    .getOrCreate()

df = spark \
  .readStream \
  .format("kafka") \
  .option("kafka.bootstrap.servers", "kafkaservice:9092") \
  .option("subscribe", "redditcomments") \
  .load()

query = df.selectExpr("CAST(value AS STRING)").writeStream.format("console").start()

query.awaitTermination()
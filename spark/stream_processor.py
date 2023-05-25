from nltk.sentiment import SentimentIntensityAnalyzer
from pyspark.sql import SparkSession
from pyspark.sql.functions import udf, from_json, col, from_unixtime, avg, current_timestamp
from pyspark.sql.types import StringType, StructType, StructField, IntegerType, BooleanType, FloatType
import uuid


def analyze_sentiment(text):
    analyzer = SentimentIntensityAnalyzer()
    sentiment = analyzer.polarity_scores(text)
    return sentiment['compound']

sentiment_udf = udf(analyze_sentiment, FloatType())

def make_uuid():
    return udf(lambda: str(uuid.uuid1()), StringType())()

# Define the schema for the JSON value column
comment_schema = StructType([
    StructField("id", StringType(), True),
    StructField("name", StringType(), True),
    StructField("author", StringType(), True),
    StructField("body", StringType(), True),
    StructField("subreddit", StringType(), True),
    StructField("upvotes", IntegerType(), True), #int
    StructField("downvotes", IntegerType(), True), #int
    StructField("over_18", BooleanType(), True), #bool
    StructField("timestamp", FloatType(), True), #timestamp
    StructField("permalink", StringType(), True),
])

spark: SparkSession = SparkSession.builder \
    .appName("StreamProcessor") \
    .config('spark.cassandra.connection.host', 'cassandra') \
    .config('spark.cassandra.connection.port', '9042') \
    .config('spark.cassandra.output.consistency.level','ONE') \
    .getOrCreate()

# spark.sparkContext.setLogLevel('ERROR')

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

# Parse the value column as JSON
parsed_df = df.withColumn(
    "comment_json",
    from_json(df["value"].cast("string"),comment_schema)
)

output_df = parsed_df.select(
        "comment_json.id",
        "comment_json.name",
        "comment_json.author",
        "comment_json.body",
        "comment_json.subreddit",
        "comment_json.upvotes",
        "comment_json.downvotes",
        "comment_json.over_18",
        "comment_json.timestamp",
        "comment_json.permalink",
    ) \
    .withColumn("uuid", make_uuid()) \
    .withColumn("api_timestamp", from_unixtime(col("timestamp").cast(FloatType()))) \
    .withColumn("ingest_timestamp", current_timestamp()) \
    .drop("timestamp")

# adding sentiment score
output_df = output_df.withColumn(
    'sentiment_score', sentiment_udf(output_df['body'])
)

# https://stackoverflow.com/questions/64922560/pyspark-and-kafka-set-are-gone-some-data-may-have-been-missed
# adding failOnDataLoss as the checkpoint change with kafka brokers going down
output_df.writeStream \
    .option("checkpointLocation", "/tmp/check_point/") \
    .option("failOnDataLoss", "false") \
    .format("org.apache.spark.sql.cassandra") \
    .options(table="comments", keyspace="reddit") \
    .start()

# adding moving averages in another df
summary_df = output_df.withWatermark("ingest_timestamp", "5 minutes").groupBy("subreddit") \
    .agg(avg("sentiment_score").alias("sentiment_score_avg")) \
    .withColumn("uuid", make_uuid()) \
    .withColumn("ingest_timestamp", current_timestamp())

summary_df.writeStream.trigger(processingTime="5 seconds") \
    .foreachBatch(
        lambda batchDF, batchID: batchDF.write.format("org.apache.spark.sql.cassandra") \
            .option("checkpointLocation", "/tmp/check_point/") \
            .options(table="subreddit_sentiment_avg", keyspace="reddit") \
            .mode("append").save()
    ).outputMode("update").start()

spark.streams.awaitAnyTermination()
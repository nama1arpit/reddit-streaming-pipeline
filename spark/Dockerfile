FROM apache/spark-py:v3.4.0

WORKDIR /src
COPY . .

# Check https://stackoverflow.com/a/69559038/12382622
CMD /opt/spark/bin/spark-submit --conf spark.driver.extraJavaOptions="-Divy.cache.dir=/tmp -Divy.home=/tmp" \
    --packages org.apache.spark:spark-streaming-kafka-0-10_2.12:3.3.0,org.apache.spark:spark-sql-kafka-0-10_2.12:3.3.0,com.datastax.spark:spark-cassandra-connector_2.12:3.2.0 \
    kafka_test.py

FROM confluentinc/cp-kafka:7.3.2

COPY ./kafka_setup.sh /kafka_setup.sh

RUN chmod +x /kafka_setup.sh

CMD ["/bin/sh", "-c", "/kafka_setup.sh"]

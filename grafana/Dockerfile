FROM grafana/grafana:9.5.2

# Install required plugin for cassandra
RUN grafana-cli plugins install hadesarchitect-cassandra-datasource

# Copy custom configuration files
COPY config/grafana.ini /etc/grafana/grafana.ini
COPY config/cassandra.yaml /etc/grafana/provisioning/datasources/cassandra.yaml
COPY config/dashboard.yaml /etc/grafana/provisioning/dashboards/dashboard.yaml
COPY config/dashboards /var/lib/grafana/dashboards

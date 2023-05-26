# Reddit Sentiment Analysis Data Pipeline
## Project Overview
The Reddit Sentiment Analysis Data Pipeline is designed to collect comments from Reddit using the Reddit API, process them using Apache Spark, store the processed data in Cassandra, and visualize sentiment scores of various subreddits in Grafana. The pipeline leverages containerization and utilizes a Kubernetes cluster for deployment, with infrastructure management handled by Terraform. Finally, Kafka is used as a message broker to provide low latency, scalability & availability.

# Table of Contents
- [Project Overview](#project-overview)
- [Table of Contents](#table-of-contents)
- [Architecture](#architecture)
- [Installation and Setup](#installation-and-setup)
- [Improvements](#improvements)
- [Acknowledgements](#acknowledgement)

# Architecture

![reddit_sentiment_analysis_pipeline_architecture](https://raw.githubusercontent.com/nama1arpit/reddit-streaming-pipeline/main/images/Reddit%20Sentiment%20Analysis%20Data%20Pipeline.drawio.png)

All applications in the above architecture are containerized into **Docker containers**, which are orchestrated by **Kubernetes** - and its infrastructure is managed by **Terraform**. The docker images for each application are available publically in the [Docker Hub registry](https://hub.docker.com/repositories/nama1arpit). Further details about each layer is provided below:

1. **Data Ingestion :** A containerized Python application called *reddit_producer* connects to Reddit API using credentials provided in the `secrets/credentials.cfg` file. It takes the received messages (reddit comments) and converts them into a JSON format. These transformed messages are then sent and stored in a Kafka broker.

2. **Message Broker :** The Kafka broker (*kafkaservice* pod), recieves messages from the *reddit_producer*. The Kafka broker is accompanied by the Kafdrop applicatino, which acts as Kafka mointoring tool through UI. When Kafka starts, another container named `kafkainit` creates the topic `redditcomments`. The *zookeeper* pod is launched before Kafka for managing Kafka metadata.

3. **Stream Processer :** A Spark deployment in the Kubernetes cluster is started for consuming and processing the data from the Kafka topic `redditcomments`. The PySpark script `spark/stream_processor.py` consumes and aggregates the data to put it in the data sink i.e. Cassandra tables.

4. **Processed Data Storage :** A Cassandra cluster is used to store and serve the processed data from the above spark job. When Cassandra starts, another container named `cassandrainit` creates the keyspace `reddit` and tables `comments` & `subreddit_sentiment_avg`. Raw comments data is written in `reddit.comments` table and the aggregated data is written in `reddit.subreddit_sentiment_avg` table.

5. **Data Visualisation :** Grafana establishes a connection with the Cassandra database. It queries the aggregated data from Cassandra and presents it visually to users through a dashboard. The dashboard shows the following panels for analysis:

    - `Top subreddits`: Showcase the real-time sentiment scores of a few top subreddits of all time.
    <!Fill in the link>
    ![top_subreddit_panel](https://raw.githubusercontent.com/nama1arpit/reddit-streaming-pipeline/main/images/top_subreddit_panel.png)
    - `Countries`: Showcase the real-time sentiment scores of subreddits based on a few countries.
    ![countries_panel](https://raw.githubusercontent.com/nama1arpit/reddit-streaming-pipeline/main/images/countries_panel.png)

# Installation and Setup
## System Requirements
- [minikube](https://minikube.sigs.k8s.io/docs/start/)
- [Docker Engine](https://www.docker.com/)
- [Terraform](https://www.terraform.io/)

The pipeline was tested with the following local system configuration:
- minikube: v1.30.1
- Docker Engine: 24.0.1
- Terraform: v1.4.6
- OS: Ubuntu 22.04.2 LTS
- RAM: 16 GB
- CPU cores: 16
- Graphics card: AMD Ryzen 7 PRO 4750G with Radeon Graphics

To setup the pipeline locally, first you will have to add a credentials file for accessing reddit API with `mkdir secrets && touch secrets/credentials.cfg`. Then populate the `credentials.cfg` file with the following template:

```
[reddit]
username=<reddit username>
password=<reddit password>
user_agent=<dev_application_name>
client_id=<dev_application_client_id>
client_secret=<dev_application_client_secret>
```
You may have to create a reddit developer application at https://www.reddit.com/prefs/apps/ to get the above credentials.

Once the credential file is ready, start the minikube cluster and apply the terraform configuration as follows:

```bash
# Remove the current cluster, start a new one along with the dashboard
$ minikube delete
$ minikube start --no-vtx-check --memory 10240 --cpus 6
$ minikube dashboard

$ cd terraform-k8s
$ terraform apply -auto-approve
```

The infrastructure setup progress can be monitored in the minikube dashboard or with the following `kubectl` command:
```bash
$ watch -n 1 kubectl get pods -n redditpipeline
```

After the complete infrastructure is up and running, run the following command to get the exposed URL for grafana dashboard

```
$ minikube service grafana -n redditpipeline --url
http://192.168.49.2:30001
```
The grafana dashboard can be accessed with the above link. In case, there are authorization errors at the start, login into grafana UI with `username: admin, password: admin`

<!Fill in the link>
![grafana_dashboard](https://raw.githubusercontent.com/nama1arpit/reddit-streaming-pipeline/main/images/grafana_dashboard.png)

# Improvements

# Acknowledgement
1. https://github.com/RSKriegs/finnhub-streaming-data-pipeline
2. 
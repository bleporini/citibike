resource "confluent_kafka_topic" "stations_raw" {
  partitions_count = 6
  topic_name       = "stations.raw"

  kafka_cluster {
    id = confluent_kafka_cluster.citibike.id
  }
  rest_endpoint = confluent_kafka_cluster.citibike.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-env-admin
  ]
}


resource "confluent_kafka_topic" "system_regions" {
  partitions_count = 6
  topic_name       = "system.regions"
  kafka_cluster {
    id = confluent_kafka_cluster.citibike.id
  }
  rest_endpoint = confluent_kafka_cluster.citibike.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-env-admin
  ]
}


resource "confluent_kafka_topic" "stations_info_raw" {
  partitions_count = 6
  topic_name       = "stations.info.raw"
  kafka_cluster {
    id = confluent_kafka_cluster.citibike.id
  }
  rest_endpoint = confluent_kafka_cluster.citibike.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-env-admin
  ]
}


resource "confluent_kafka_topic" "stations_status_raw" {
  partitions_count = 6
  topic_name       = "stations.status.raw"
  kafka_cluster {
    id = confluent_kafka_cluster.citibike.id
  }
  rest_endpoint = confluent_kafka_cluster.citibike.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-env-admin
  ]
}

resource "confluent_kafka_topic" "free_bikes_status_raw" {
  partitions_count = 6
  topic_name       = "free.bikes.status.raw"
  kafka_cluster {
    id = confluent_kafka_cluster.citibike.id
  }
  rest_endpoint = confluent_kafka_cluster.citibike.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-kafka-api-key.id
    secret = confluent_api_key.app-manager-kafka-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-env-admin
  ]
}


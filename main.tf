terraform {
  required_providers {
    confluent = {
      source  = "confluentinc/confluent"
      version = "1.76.0"
    }
  }
}

provider "confluent" {
  cloud_api_key       = var.confluent_cloud_api_key
  cloud_api_secret    = var.confluent_cloud_api_secret
}

resource "random_id" "id" {
  byte_length = 4
}

data "confluent_organization" "main" {}

resource "confluent_environment" "citibike" {
  display_name = "citibike_${random_id.id.id}"
  stream_governance {
    package = "ADVANCED"
  }
}

resource "confluent_schema_registry_cluster" "sr" {
  package = "ADVANCED"
  region {
    id = var.sr_region
  }
  environment {
    id = confluent_environment.citibike.id
  }
}


resource "confluent_kafka_cluster" "citibike" {
  availability = "SINGLE_ZONE"
  basic {
  }
  environment {
    id = confluent_environment.citibike.id
  }
  region       = var.region
  cloud        = "AWS"
  display_name = "citibike"
}

resource "confluent_service_account" "app-manager" {
  display_name = "app-manager"
  description  = "Service account to manage 'inventory' Kafka cluster"

  depends_on = [
    confluent_schema_registry_cluster.sr,
    confluent_kafka_cluster.citibike
  ]
}
resource "confluent_role_binding" "app-manager-env-admin" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.citibike.resource_name
}

resource "confluent_api_key" "app-manager-kafka-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_kafka_cluster.citibike.id
    api_version = confluent_kafka_cluster.citibike.api_version
    kind        = confluent_kafka_cluster.citibike.kind

    environment {
      id = confluent_environment.citibike.id
    }
  }
}

resource "confluent_api_key" "app-manager-schema-registry-api-key" {
  display_name = "app-manager-schema-registry-api-key"
  description  = "Schema Registry API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = confluent_schema_registry_cluster.sr.id
    api_version = confluent_schema_registry_cluster.sr.api_version
    kind        = confluent_schema_registry_cluster.sr.kind

    environment {
      id = confluent_environment.citibike.id
    }
  }
}



resource "confluent_connector" "stations_info" {
  config_nonsensitive = {
    "connector.class"                = "HttpSource"
    "http.initial.offset"            = "0"
    "http.request.sensitive.headers" = ""
    "kafka.auth.mode"                = "KAFKA_API_KEY"
    "kafka.api.key"                  = confluent_api_key.app-manager-kafka-api-key.id
    "kafka.api.secret"                  = confluent_api_key.app-manager-kafka-api-key.secret
    name                             = "stations_info"
    "output.data.format"             = "JSON_SR"
    "request.interval.ms"            = 3600000
    "tasks.max"                      = "1"
    "topic.name.pattern"             = confluent_kafka_topic.stations_info_raw.topic_name
    url                              = "https://gbfs.citibikenyc.com/gbfs/en/station_information.json"
  }
  environment {
    id = confluent_environment.citibike.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.citibike.id
  }
}

resource "confluent_connector" "stations_status" {
  config_nonsensitive = {
    "connector.class"                = "HttpSource"
    "http.initial.offset"            = "0"
    "http.request.sensitive.headers" = ""
    "kafka.auth.mode"                = "KAFKA_API_KEY"
    "kafka.api.key"                  = confluent_api_key.app-manager-kafka-api-key.id
    "kafka.api.secret"                  = confluent_api_key.app-manager-kafka-api-key.secret
    name                             = "station_status"
    "output.data.format"             = "JSON_SR"
    "tasks.max"                      = "1"
    "topic.name.pattern"             = confluent_kafka_topic.stations_status_raw.topic_name
    url                              = "https://gbfs.citibikenyc.com/gbfs/en/station_status.json"
  }
  environment {
    id = confluent_environment.citibike.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.citibike.id
  }
}

resource "confluent_connector" "free_bikes_status" {
  config_nonsensitive = {
    "connector.class"                = "HttpSource"
    "http.initial.offset"            = "0"
    "http.request.sensitive.headers" = ""
    "kafka.auth.mode"                = "KAFKA_API_KEY"
    "kafka.api.key"                  = confluent_api_key.app-manager-kafka-api-key.id
    "kafka.api.secret"                  = confluent_api_key.app-manager-kafka-api-key.secret
    name                             = "free_bikes_status"
    "output.data.format"             = "JSON_SR"
    "tasks.max"                      = "1"
    "topic.name.pattern"             = confluent_kafka_topic.free_bikes_status_raw.topic_name
    url                              = "https://gbfs.divvybikes.com/gbfs/en/free_bike_status.json"
  }
  environment {
    id = confluent_environment.citibike.id
  }
  kafka_cluster {
    id = confluent_kafka_cluster.citibike.id
  }
}









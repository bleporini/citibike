resource "local_file" "config"{
  filename = "${path.cwd}/cli-consumer/target/classes/bicyclesharing.nyc.properties"
  content = <<-EOT
# Kafka
bootstrap.servers=${replace(confluent_kafka_cluster.citibike.bootstrap_endpoint, "SASL_SSL://", "")}
security.protocol=SASL_SSL
sasl.jaas.config=org.apache.kafka.common.security.plain.PlainLoginModule required username="${confluent_api_key.app-manager-kafka-api-key.id}" password="${confluent_api_key.app-manager-kafka-api-key.secret}";
ssl.endpoint.identification.algorithm=https
sasl.mechanism=PLAIN
num.partitions=6
replication.factor=3

# Schema Registry
schema.registry.url=${confluent_schema_registry_cluster.sr.rest_endpoint}
schema.registry.basic.auth.user.info=${confluent_api_key.app-manager-schema-registry-api-key.id}:${confluent_api_key.app-manager-schema-registry-api-key.secret}

basic.auth.credentials.source=USER_INFO

# Topics names
stations.color.topic=stations.color
group.id=cli-consumer

  EOT
}



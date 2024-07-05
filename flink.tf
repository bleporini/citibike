data "confluent_flink_region" "region" {
  cloud  = "AWS"
  region = confluent_kafka_cluster.citibike.region
}

resource "confluent_flink_compute_pool" "main" {
  display_name     = "standard_compute_pool"
  cloud            = "AWS"
  region           = var.region
  max_cfu          = 10
  environment {
    id = confluent_environment.citibike.id
  }
}

resource "confluent_role_binding" "app-manager-flink-developer" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "FlinkDeveloper"
  crn_pattern = confluent_environment.citibike.resource_name
}

resource "confluent_service_account" "statements-runner" {
  display_name = "statements-runner"
  description  = "Service account for running Flink Statements in 'inventory' Kafka cluster"
}
resource "confluent_role_binding" "statements-runner-env-admin" {
  principal   = "User:${confluent_service_account.statements-runner.id}"
  role_name   = "EnvironmentAdmin"
  crn_pattern = confluent_environment.citibike.resource_name
}
resource "confluent_role_binding" "app-manager-assigner" {
  principal   = "User:${confluent_service_account.app-manager.id}"
  role_name   = "Assigner"
  crn_pattern = "${data.confluent_organization.main.resource_name}/service-account=${confluent_service_account.statements-runner.id}"
}


resource "confluent_api_key" "app-manager-flink-api-key" {
  display_name = "app-manager-kafka-api-key"
  description  = "Kafka API Key that is owned by 'app-manager' service account"
  owner {
    id          = confluent_service_account.app-manager.id
    api_version = confluent_service_account.app-manager.api_version
    kind        = confluent_service_account.app-manager.kind
  }

  managed_resource {
    id          = data.confluent_flink_region.region.id
    api_version = data.confluent_flink_region.region.api_version
    kind        = data.confluent_flink_region.region.kind

    environment {
      id = confluent_environment.citibike.id
    }
  }
}

resource "confluent_flink_statement" "stations_status_ddl" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
create table `stations.status` (
    station_id string primary key not enforced,
    num_docks_available integer not null,
    num_docks_disabled integer not null,
    is_returning integer not null,
    num_bikes_disabled integer not null,
    is_renting boolean not null,
    num_ebikes_available integer not null,
    is_installed integer not null,
    last_reported integer not null,
    legacy_id string not null,
    num_bikes_available integer not null,
    eightd_has_available_keys boolean not null
) with ('value.format' = 'json-registry');
EOT


  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer
  ]
}

resource "confluent_flink_statement" "stations_status_dml" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
insert into `stations.status` select
    t.station_id ,
    t.num_docks_available ,
    t.num_docks_disabled ,
    t.is_returning,
    t.num_bikes_disabled ,
    t.is_renting = 1 as `is_renting`,
    t.num_ebikes_available ,
    t.is_installed ,
    t.last_reported ,
    t.legacy_id ,
    t.num_bikes_available ,
    t.eightd_has_available_keys
from `stations.status.raw` s cross join unnest(s.data.stations) as t;
EOT


  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer,
    confluent_connector.stations_status,
    confluent_flink_statement.stations_status_ddl
  ]
}


resource "confluent_flink_statement" "stations_online_ddl" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
create table `stations.online` (
     station_id string primary key not enforced,
     num_docks_available integer not null,
     num_docks_disabled integer not null,
     is_returning integer not null,
     num_bikes_disabled integer not null,
     is_renting boolean not null,
     num_ebikes_available integer not null,
     is_installed integer not null,
     last_reported integer not null,
     legacy_id string not null,
     num_bikes_available integer not null,
     eightd_has_available_keys boolean not null
) with ('value.format' = 'json-registry');
EOT


  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer
  ]
}

resource "confluent_flink_statement" "stations_online_dml" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
insert into `stations.online` select * from `stations.status` where is_renting is true;
EOT


  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer,
    confluent_flink_statement.stations_status_dml,
    confluent_flink_statement.stations_online_ddl
  ]
}



resource "confluent_flink_statement" "stations_offline_ddl" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
create table `stations.offline` (
     station_id string primary key not enforced,
     num_docks_available integer not null,
     num_docks_disabled integer not null,
     is_returning integer not null,
     num_bikes_disabled integer not null,
     is_renting boolean not null,
     num_ebikes_available integer not null,
     is_installed integer not null,
     last_reported integer not null,
     legacy_id string not null,
     num_bikes_available integer not null,
     eightd_has_available_keys boolean not null
) with ('value.format' = 'json-registry');
EOT


  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer
  ]
}

resource "confluent_flink_statement" "stations_offline_dml" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
  insert into `stations.offline` select * from `stations.status` where is_renting is false;
EOT


  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer,
    confluent_connector.stations_status,
    confluent_flink_statement.stations_status_dml,
    confluent_flink_statement.stations_offline_ddl
  ]
}

resource "confluent_flink_statement" "free_bike_status_ddl" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
create table `free.bikes.status` (
        bike_id string primary key not enforced,
        lat double not null,
        type string not null,
        is_disabled boolean not null,
        is_reserved boolean not null,
        lon double not null,
        name string not null)
with ('value.format' = 'json-registry');
EOT


  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer
  ]
}

resource "confluent_flink_statement" "free_bikes_status_dml" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
insert into `free.bikes.status` select
  b.bike_id,
  b.lat,
  b.type,
  b.is_disabled = 1 as is_disabled,
  b.is_reserved = 1 as is_reserved,
  b.lon,
  b.name
from `free.bikes.status.raw` s cross join unnest(s.data.bikes) as b;
EOT


  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer,
    confluent_connector.free_bikes_status,
    confluent_flink_statement.free_bike_status_ddl
  ]
}

resource "confluent_flink_statement" "stations_info_ddl" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
create table `stations.info`(
  station_id string primary key not enforced,
  name string not null,
  lat double not null,
  lon double not null,
  capacity integer not null
)with ( 'value.format' = 'json-registry' );
EOT


  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer,
    confluent_kafka_topic.stations_info_raw
  ]
}
resource "confluent_flink_statement" "stations_info_dml" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
insert into `stations.info` select
  s.station_id as station_id,
  s.name as name,
  s.lat as lat,
  s.lon as lon,
  s.capacity as capacity
from `stations.info.raw` sr cross join unnest(sr.data.stations) as s;
EOT


  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer,
    confluent_connector.stations_info,
    confluent_flink_statement.stations_info_ddl
  ]
}

resource "confluent_flink_statement" "stations_color_ddl" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
create table `stations.color`(
  station_id string primary key not enforced,
  name string not null,
  lat double not null,
  lon double not null,
  capacity integer not null,
  num_bikes_available int not null,
  ratio double not null
)with( 'value.format' = 'json-registry' );
EOT

  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer,
    confluent_flink_statement.stations_info_dml,
    confluent_flink_statement.stations_online_dml
  ]
}

resource "confluent_flink_statement" "stations_color_dml" {
  compute_pool {
    id = confluent_flink_compute_pool.main.id
  }
  principal {
    id = confluent_service_account.statements-runner.id
  }
  organization {
    id = data.confluent_organization.main.id
  }
  environment {
    id = confluent_environment.citibike.id
  }
  statement  = <<-EOT
insert into `stations.color`
SELECT `stations.info`.station_id as station_id,
       `stations.info`.name as name,
       `stations.info`.lat as lat,
       `stations.info`.lon as lon,
       `stations.info`.capacity,
       `stations.online`.num_bikes_available,
       (`stations.online`.num_bikes_available)/ cast(`stations.info`.capacity as double) as ratio
    FROM `stations.online`
    INNER JOIN `stations.info` ON `stations.online`.station_id = `stations.info`.station_id;
EOT

  properties = {
    "sql.current-catalog"  = confluent_environment.citibike.display_name
    "sql.current-database" = confluent_kafka_cluster.citibike.display_name
  }
  rest_endpoint   = data.confluent_flink_region.region.rest_endpoint
  credentials {
    key    = confluent_api_key.app-manager-flink-api-key.id
    secret = confluent_api_key.app-manager-flink-api-key.secret
  }

  depends_on = [
    confluent_role_binding.app-manager-flink-developer,
    confluent_flink_statement.stations_info_dml,
    confluent_flink_statement.stations_online_dml,
    confluent_flink_statement.stations_color_ddl

  ]
}




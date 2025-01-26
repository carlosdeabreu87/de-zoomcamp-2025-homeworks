terraform {
  required_providers {
    docker = {
      source  = "kreuzwerker/docker"
      version = "3.0.2"
    }
  }
}

provider "docker" {
  host = "unix:///var/run/docker.sock"
}

# Define the custom network
resource "docker_network" "pg_network" {
  name   = "pg-network"
  driver = "bridge"
}

# Define the volumes
resource "docker_volume" "pgdata" {
  name = "vol-pgdata"
}

resource "docker_volume" "pgadmin_data" {
  name = "vol-pgadmin_data"
}

# PostgreSQL container
resource "docker_image" "postgres_image" {
  name = "postgres:17-alpine"
}

resource "docker_container" "postgres_container" {
  name  = "postgres"
  image = docker_image.postgres_image.name

  networks_advanced {
    name = docker_network.pg_network.name
  }

  ports {
    internal = 5432
    external = 5433
  }

  env = [
    "POSTGRES_USER=postgres",
    "POSTGRES_PASSWORD=postgres",
    "POSTGRES_DB=ny_taxi"
  ]

  volumes {
    volume_name    = docker_volume.pgdata.name
    container_path = "/var/lib/postgresql/data"
  }
}

# PgAdmin container
resource "docker_image" "pgadmin_image" {
  name = "dpage/pgadmin4:latest"
}

resource "docker_container" "pgadmin_container" {
  name  = "pgadmin"
  image = docker_image.pgadmin_image.name

  networks_advanced {
    name = docker_network.pg_network.name
  }

  ports {
    internal = 80
    external = 8080
  }

  env = [
    "PGADMIN_DEFAULT_EMAIL=pgadmin@pgadmin.com",
    "PGADMIN_DEFAULT_PASSWORD=pgadmin"
  ]

  volumes {
    volume_name    = docker_volume.pgadmin_data.name
    container_path = "/var/lib/pgadmin"
  }
}

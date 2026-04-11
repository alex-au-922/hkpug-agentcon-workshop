terraform {
  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "6.24.0"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.36.0"
    }
    helm = {
      source  = "hashicorp/helm"
      version = "2.17.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "3.7.1"
    }
    docker = {
      source  = "kreuzwerker/docker"
      version = "4.0.0"
    }
    external = {
      source  = "hashicorp/external"
      version = "2.3.5"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "5.6.0"
    }
  }
}

provider "google" {
  project = var.gcp_project_id
  region  = "asia-southeast1"
}

data "google_client_config" "provider" {
  provider = google
}

provider "kubernetes" {
  host  = "https://${google_container_cluster.this.endpoint}"
  token = data.google_client_config.provider.access_token
  cluster_ca_certificate = base64decode(
    google_container_cluster.this.master_auth[0].cluster_ca_certificate,
  )
}

provider "helm" {
  kubernetes {
    host  = "https://${google_container_cluster.this.endpoint}"
    token = data.google_client_config.provider.access_token
    cluster_ca_certificate = base64decode(
      google_container_cluster.this.master_auth[0].cluster_ca_certificate,
    )
  }
}

provider "docker" {
  registry_auth {
    address  = "${var.region}-docker.pkg.dev"
    username = "oauth2accesstoken"
    password = data.google_client_config.this.access_token
  }
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}

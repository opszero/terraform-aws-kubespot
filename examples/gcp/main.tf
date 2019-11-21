provider "google" {
  alias = "example"
  region = "us-west1"
  project = "steel-aria-259723"
  credentials = file("./account.json")
}


module "gcp" {
  source = "../../gcp"
  project_id = "steel-aria-259723"
  cluster_username = "cluster-name"
  cluster_password = "cluster-password"
  sql_enabled = true
  environment_name = "example"
  region = "us-west1"
  nodes_max_size = 2
  nodes_min_size = 1
  nodes_desired_capacity = 2
  providers = {
    "google" = "google.example"
  }
}


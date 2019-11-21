//resource "google_project_service" "kubernetes_engine" {
//  project = var.project_id
//  service = "container.googleapis.com"
//
//  disable_dependent_services = true
//}
//
//resource "google_project_service" "cloud_resource_manager" {
//  project = var.project_id
//  service = "cloudresourcemanager.googleapis.com"
//
//  disable_dependent_services = true
//}
//
//resource "google_project_service" "service_networking" {
//  project = var.project_id
//  service = "servicenetworking.googleapis.com"
//  disable_dependent_services = true
//}
//
//resource "google_project_service" "cloud_sql_admin" {
//  project = var.project_id
//  service = "sqladmin.googleapis.com"
//  disable_dependent_services = true
//}
//
//
//resource "google_project_service" "compute_engine" {
//  project = var.project_id
//  service = "compute.googleapis.com"
//  disable_dependent_services = true
//}

resource "google_project_iam_binding" "asdasd" {
  members = [
    "auditkube@steel-aria-259723.iam.gserviceaccount.com"
  ]
  role = "roles/compute.networkUse"
  project = var.project_id
}
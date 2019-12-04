resource "google_kms_key_ring" "keyring" {
  name     = var.environment_name
  location = "global"

  lifecycle {
    prevent_destroy = true
  }
}


resource "google_kms_crypto_key" "key" {
  name            = var.environment_name
  key_ring        = google_kms_key_ring.keyring.self_link

  lifecycle {
    prevent_destroy = true
  }
}

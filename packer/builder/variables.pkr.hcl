
variable "recipe_file" {
  type = string
}

variable "ubuntu_url" {
  type = string
  default = "https://cloud-images.ubuntu.com/jammy/current/jammy-server-cloudimg-amd64.img"
}

variable "ubuntu_checksum" {
  type = string
  default = "file:https://cloud-images.ubuntu.com/jammy/current/SHA256SUMS"
}

variable "image_name" {
  type = string
  default = "ubuntu-jammy-rke2"
}

variable "namespace" {
  type = string
  default = "default"
}

variable "output_location" {
  type = string
  default = "output/"
}
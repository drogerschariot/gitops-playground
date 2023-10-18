variable "name" {
  type = string
}

variable "location" {
  type = string
}

variable "node_count" {
  type = number
  default = 3
}

variable "node_size" {
  type = string
}

variable "ssh_pub_key" {
  type = string
}

variable "k8s_version" {
  type = string
}

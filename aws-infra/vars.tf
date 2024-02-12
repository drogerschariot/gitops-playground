variable "name" {
  type = string
}

variable "region" {
  type = string
  default = "us-east-1"
}

variable "node_type" {
  type = string
  default = "t3.medium"
}

variable "node_size" {
  type = number
  default = 2
}

variable "node_max_size" {
  type = number
  default = 6
}

variable "cluster_version" {
  type = string
  default = "1.24"
}

variable "k8s_version" {
  type = string
  default = "19.0.4"
}

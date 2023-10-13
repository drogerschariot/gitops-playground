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
  default = "Standard_D2_v2"
}

variable "ssh_pub_key" {
  type = string
}

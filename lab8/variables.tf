variable "region" {
  type    = string
  default = "us-east-1"
}

variable "owner" {
  type        = string
  description = "Your Seneca username, to keep the bucket name unique."
}

variable "admin_cidr" {
  type        = string
  description = "The single address allowed to reach SSH, as a /32."

  validation {
    condition     = can(cidrnetmask(var.admin_cidr)) && endswith(var.admin_cidr, "/32")
    error_message = "admin_cidr must be one host, written as a.b.c.d/32."
  }
}

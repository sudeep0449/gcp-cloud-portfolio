variable "project_id" {
  description = "Google Cloud project ID"
  type        = string
}

variable "region" {
  description = "Region for all regional resources"
  type        = string
  default     = "australia-southeast1"
}

variable "zone" {
  description = "Zone for the VM"
  type        = string
  default     = "australia-southeast1-a"
}

variable "prefix" {
  description = "Name prefix for every resource"
  type        = string
  default     = "tf"
}

variable "machine_type" {
  description = "VM machine type"
  type        = string
  default     = "e2-micro"
}

variable "subnets" {
  description = "Tier name => CIDR range"
  type        = map(string)
  default = {
    web = "10.30.1.0/24"
    app = "10.30.2.0/24"
  }
}

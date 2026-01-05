variable "location" {
  type        = string
  description = "Azure region"
  default     = "canadacentral"
}

variable "resource_group_name" {
  type        = string
  description = "Resource group name"
  default     = "rg-geospatial-pipeline"
}

variable "storage_account_name" {
  type        = string
  description = "Storage account name (must be globally unique, lowercase, 3-24 chars)"
}

variable "raw_container_name" {
  type        = string
  description = "Container for raw OSM PBF files"
  default     = "raw-osm"
}

variable "tags" {
  type        = map(string)
  description = "Resource tags"
  default = {
    project = "geospatial-pipeline"
    env     = "dev"
  }
}

variable "project_name" {
  description = "Name of the project to be used as prefix"
  type        = string
  default     = "project-isaac"
}

variable "environment" {
  description = "Environment (dev, hmm, prd)"
  type        = string
  default     = "dev"
}

variable "tags" {
  description = "A mapping of tags to assign to the bucket."
  type        = map(string)
  default     = {}
}

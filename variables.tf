variable "bronze_bucket_name" {
  type        = string
  description = "The name of the bronze bucket for raw data"
  default     = "weather-bronze-bucket-raw"
}

variable "silver_bucket_name" {
  type        = string
  description = "The name of the silver bucket for cleaned data"
  default     = "weather-silver-bucket-cleaned"
}
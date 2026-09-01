variable "account_id" {
  description = "Cloudflare account ID."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "zone_id" {
  description = "Cloudflare zone ID."
  type        = string
  default     = "00000000000000000000000000000000"
}

variable "origin_password" {
  description = "Password of the origin database Hyperdrive connects to. Not a Cloudflare credential."
  type        = string
  sensitive   = true
  default     = "replace-me"
}

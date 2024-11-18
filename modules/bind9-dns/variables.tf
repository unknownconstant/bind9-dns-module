variable "zone_name" {
  description = "DNS zone name to manage"
  type        = string
}

variable "a_records" {
  description = "Map of subdomains to sets of IP addresses. Each subdomain can point to multiple IPs."
  type        = map(set(string))
  default     = {}
}
variable "cname_records" {
  description = "Map of subdomains to FQDNs."
  type        = map(string)
  default     = {}
}

variable "NS_subdomain_records" {
  description = "Subdomain records"
  type        = map(set(string))
  default = {
  }
}

variable "ns1" {
  description = "The ip "
  type        = string
}

variable "username" {
  description = "The username for ssh"
  type        = string
}

variable "host_ip" {
  description = "The host ip"
  type        = string
}

variable "authoritative_nameservers" {
  description = "Authoritative Nameservers for this zone"
  type        = list(string)
}

variable "bind-path" {
  type    = string
  default = "/var/dockerfiles/dns/zones"
}

variable "kf-location" {
  type    = string
  default = "/home/pi4/dns/kf"
}

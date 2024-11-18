
resource "dns_a_record_set" "a_records" {
  for_each = var.a_records

  # Assuming zone_name is a fully-qualified domain name (FQDN)
  zone       = var.zone_name
  name       = each.key
  addresses  = each.value
  ttl        = 60 # Adjust TTL as needed
  depends_on = [null_resource.SOA]
}

resource "dns_a_record_set" "a_ns1" {
  # Assuming zone_name is a fully-qualified domain name (FQDN)
  zone       = var.zone_name
  name       = "ns1"
  addresses  = [var.ns1]
  ttl        = 60 # Adjust TTL as needed
  depends_on = [null_resource.SOA]
}

resource "dns_cname_record" "a_records" {
  for_each = var.cname_records

  # Assuming zone_name is a fully-qualified domain name (FQDN)
  zone       = var.zone_name
  name       = each.key
  cname      = each.value
  ttl        = 60 # Adjust TTL as needed
  depends_on = [null_resource.SOA]
}

resource "dns_ns_record_set" "NS_subdomain_records" {
  for_each = var.NS_subdomain_records

  zone        = var.zone_name
  name        = each.key
  nameservers = each.value
  ttl         = 60
  depends_on  = [null_resource.SOA]

}

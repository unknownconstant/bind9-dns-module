locals {
  ns1_ip = "10.0.0.1"
  ns2_ip = "10.0.0.2"
  dns_servers = {
    // Bind running in docker
    ns1 = {
      host_ip     = local.ns1_ip
      username    = "dns"
      bind-path   = "/var/dockerfiles/dns/zones"
      kf-location = "/home/dns/kf"
    }
    ns2 = {
      host_ip     = local.ns2_ip
      username    = "dns"
      bind-path   = "/var/lib/bind"
      kf-location = "/etc/bind/ns1.key"
    }
  }
  dns_servers_names = ["ns1.internal.", "ns2.internal."]
  dns_zones = {
    "internal." = {
      a_records = {
        # ns1 is auto-created
        # TODO: Why?
        ns2 = [local.ns2_ip]
      }
      cname_records = {
      }

      NS_subdomain_records = {}
    }
    "corp.internal." = {
      a_records = {
        intranet = "10.0.0.3"
      }
      cname_records        = {
        login = "intranet.corp.internal."
      }
      NS_subdomain_records = {}
    }
  }
}

module "dns_ns1" {
  for_each = local.dns_zones
  # for_each = {}
  providers = {
    dns = dns.ns1
  }

  source                    = "../../modules/bind9-dns"
  zone_name                 = each.key
  username                  = local.dns_servers.ns1.username
  ns1                       = local.ns1_ip
  host_ip                   = local.dns_servers.ns1.host_ip
  bind-path                 = local.dns_servers.ns1.bind-path
  kf-location               = local.dns_servers.ns1.kf-location
  authoritative_nameservers = local.dns_servers_names
  a_records                 = each.value.a_records
  cname_records             = each.value.cname_records
  NS_subdomain_records      = each.value.NS_subdomain_records
}

module "dns_ns2" {
  for_each = local.dns_zones
  # for_each = {}
  providers = {
    dns = dns.ns2
  }

  source                    = "../../modules/bind9-dns"
  zone_name                 = each.key
  username                  = local.dns_servers.ns2.username
  ns1                       = local.ns1_ip
  host_ip                   = local.dns_servers.ns2.host_ip
  bind-path                 = local.dns_servers.ns2.bind-path
  kf-location               = local.dns_servers.ns2.kf-location
  authoritative_nameservers = local.dns_servers_names
  a_records                 = each.value.a_records
  cname_records             = each.value.cname_records
  NS_subdomain_records      = each.value.NS_subdomain_records
}

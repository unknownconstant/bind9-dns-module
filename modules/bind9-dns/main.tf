
terraform {
  required_providers {
    dns = {

    }
  }
}
resource "null_resource" "SOA" {
  connection {
    type        = "ssh"
    user        = self.triggers.username
    private_key = file("~/.ssh/id_rsa")
    host        = self.triggers.host_ip
  }
  provisioner "file" {
    source      = "${path.module}/create-dns-zone.sh"
    destination = "/tmp/create-dns-zone.sh"
    when        = create
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/create-dns-zone.sh",
      "export PATH=\"$PATH:/usr/sbin\"",
      "/tmp/create-dns-zone.sh ${var.zone_name} ${var.ns1} ${var.bind-path} ${var.kf-location}"
    ]
  }
  provisioner "file" {
    source      = "${path.module}/destroy-dns-zone.sh"
    destination = "/tmp/destroy-dns-zone.sh"
    when        = destroy
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/destroy-dns-zone.sh",
      "export PATH=\"$PATH:/usr/sbin\"",
      "/tmp/destroy-dns-zone.sh ${self.triggers.zone_name} ${self.triggers.bind-path} ${self.triggers.kf-location}"
    ]
    when = destroy
  }
  triggers = {
    username  = var.username
    host_ip   = var.host_ip
    zone_name = var.zone_name
    ns1       = var.ns1


    bind-path   = var.bind-path
    kf-location = var.kf-location
  }
}

resource "null_resource" "remove_dummy_ns" {
  depends_on = [dns_a_record_set.a_ns1]
  connection {
    type        = "ssh"
    user        = self.triggers.username
    private_key = file("~/.ssh/id_rsa")
    host        = self.triggers.host_ip
  }
  provisioner "file" {
    source      = "${path.module}/set-soa.sh"
    destination = "/tmp/set-soa.sh"
    when        = create
  }
  provisioner "file" {
    source      = "${path.module}/set-soa.sh"
    destination = "/tmp/set-soa.sh"
    when        = destroy
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/set-soa.sh",
      "export NAMESERVERS=\"${join(",", var.authoritative_nameservers)}\"",
      "export PATH=\"$PATH:/usr/sbin\"",
      "/tmp/set-soa.sh ${var.zone_name} ${var.ns1} del-dummy ${var.bind-path} ${var.kf-location}"
    ]
  }
  provisioner "remote-exec" {
    inline = [
      "chmod +x /tmp/set-soa.sh",
      "export NAMESERVERS=\"${lookup(self.triggers, "authoritative_nameservers", "")}\"",
      "export PATH=\"$PATH:/usr/sbin\"",
      "/tmp/set-soa.sh ${self.triggers.zone_name} ${self.triggers.ns1} add-dummy ${self.triggers.bind-path} ${self.triggers.kf-location}"
    ]
    when = destroy
  }
  triggers = {
    host_ip                   = var.host_ip
    zone_name                 = var.zone_name
    ns1                       = var.ns1
    username                  = var.username
    bind-path                 = var.bind-path
    kf-location               = var.kf-location
    authoritative_nameservers = join(",", var.authoritative_nameservers)
  }
}

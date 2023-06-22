
locals {
  # read static_hosts.json
  static_hosts = jsondecode(file("${path.module}/static_hosts.json"))
}

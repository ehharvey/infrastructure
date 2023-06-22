# Linux Maintenance User
resource "aws_secretsmanager_secret" "linux_maintenance" {
  name = "linux_maintenance"
}


# Random password for linux maintenance user
resource "random_password" "linux_maintenance_password" {
  count = local.rotation_count

  length  = 25
  special = false
}

# Random SSH key for linux maintenance user
resource "tls_private_key" "linux_maintenance_ssh_key" {
  count = local.rotation_count

  algorithm = "RSA"
  rsa_bits  = 4096
}

# locals to derive version stages
locals {
  active_rotation_count = local.rotation_count > 3 ? 3 : local.rotation_count

  maintenance_username = local.decoded_secret["maintenance_username"]

  version_stages = local.rotation_count >= 3 ? [
    "AWSPENDING",
    "AWSCURRENT",
    "AWSPREVIOUS",
    ] : local.rotation_count >= 2 ? [
    "AWSPENDING",
    "AWSCURRENT",
    ] : [
    "AWSCURRENT",
  ]

  linux_maintenance_password = {
    for stage in local.version_stages :
    stage => random_password.linux_maintenance_password[length(random_password.linux_maintenance_password) - 1 - index(local.version_stages, stage)]
    .result
  }

  linux_maintenance_ssh_key = {
    for stage in local.version_stages :
    stage => tls_private_key.linux_maintenance_ssh_key[length(tls_private_key.linux_maintenance_ssh_key) - 1 - index(local.version_stages, stage)]
  }


  # generate a secret string for each version stage
  secret_strings = {
    for stage in local.version_stages :
    stage => jsonencode({
      username       = local.maintenance_username
      password       = local.linux_maintenance_password[stage]
      private_key    = local.linux_maintenance_ssh_key[stage].private_key_pem,
      public_key     = local.linux_maintenance_ssh_key[stage].public_key_openssh,
      rotation_count = local.rotation_count,
    })
  }
}

# Store secrets to JSON on disk
resource "local_file" "linux_maintenance_secrets" {
  count = local.active_rotation_count

  filename = "${path.module}/linux_maintenance_${local.version_stages[count.index]}.json"

  content = local.secret_strings[local.version_stages[count.index]]
}

# AWS Secrets Manager Secret Version
resource "aws_secretsmanager_secret_version" "linux_maintenance" {
  count = local.active_rotation_count

  secret_id     = aws_secretsmanager_secret.linux_maintenance.id
  secret_string = local.secret_strings[local.version_stages[count.index]]
  version_stages = [
    local.version_stages[count.index]
  ]
}

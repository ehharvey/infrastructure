# Read API keys from environment variables or from a file
locals {
  aws_json = jsondecode(file("${path.module}/aws.json"))
}

provider "aws" {
  region     = local.aws_json.region
  access_key = local.aws_json.access_key
  secret_key = local.aws_json.secret_key
}

# Rotation count is stored as a non-terraform managed secret

data "aws_secretsmanager_secret" "base" {
  name = "prod/base"
}

# rotation count on base secret
data "aws_secretsmanager_secret_version" "base" {
  secret_id     = data.aws_secretsmanager_secret.base.id
  version_stage = "AWSCURRENT"
}

locals {
  decoded_secret = jsondecode(data.aws_secretsmanager_secret_version.base.secret_string)
  rotation_count = local.decoded_secret["rotation_count"]
}

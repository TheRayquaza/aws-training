locals {
  css_files = sort(fileset(path.module, "../front/dist/assets/index*.css"))
  css_path  = length(local.css_files) > 0 ? abspath(local.css_files[0]) : "not-found"
  js_files = sort(fileset(path.module, "../front/dist/assets/index*.js"))
  js_path  = length(local.js_files) > 0 ? abspath(local.js_files[0]) : "not-found"
  html_path = abspath("../front/dist/index.html")
}

provider "aws" {
  region     = var.region
  access_key = var.aws_access_key
  secret_key = var.aws_secret_key
}

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
}

module "backend-service" {
  source = "./back"
  vpc_id = aws_vpc.main.id
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  region = var.region
  redis_endpoint = module.cache-service.redis_endpoint
}

module "cache-service" {
  source = "./cache"
  vpc_id = aws_vpc.main.id
  backend_sgroup_id = [module.backend-service.backend_security_group_id]
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  region = var.region
}

module "front-service" {
  source = "./front"
  aws_access_key = var.aws_access_key
  aws_secret_key = var.aws_secret_key
  region = var.region

  css_path = local.css_path
  js_path  = local.js_path
  html_path = local.html_path
  backend_lb_dns = module.backend-service.backend_lb_dns

  depends_on = [ module.backend-service ]
}

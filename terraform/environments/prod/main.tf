locals {
  name = "${var.project_name}-${var.environment}"
}

provider "aws" {
  region = var.aws_region

  default_tags {
    tags = {
      Project     = var.project_name
      Environment = var.environment
      ManagedBy   = "Terraform"
    }
  }
}

module "network" {
  source               = "../../modules/network"
  name                 = local.name
  vpc_cidr             = var.vpc_cidr
  availability_zones   = var.availability_zones
  public_subnet_cidrs  = var.public_subnet_cidrs
  private_subnet_cidrs = var.private_subnet_cidrs
  single_nat_gateway   = var.single_nat_gateway
}

module "ecr" {
  source = "../../modules/ecr"
  name   = local.name
}

module "rds" {
  source                 = "../../modules/rds"
  name                   = local.name
  vpc_id                 = module.network.vpc_id
  subnet_ids             = module.network.private_subnet_ids
  private_cidr_blocks    = var.private_subnet_cidrs
  instance_class         = var.db_instance_class
  multi_az               = var.db_multi_az
  deletion_protection    = var.db_deletion_protection
}

module "ecs" {
  source                 = "../../modules/ecs"
  name                   = local.name
  vpc_id                 = module.network.vpc_id
  public_subnet_ids      = module.network.public_subnet_ids
  private_subnet_ids     = module.network.private_subnet_ids
  container_image        = "${module.ecr.repository_url}:${var.image_tag}"
  container_port         = 8080
  desired_count          = var.ecs_desired_count
  cpu                    = var.ecs_cpu
  memory                 = var.ecs_memory
  db_host                = module.rds.endpoint
  db_port                = module.rds.port
  db_name                = module.rds.database_name
  db_user                = module.rds.username
  db_password_secret_arn = module.rds.password_secret_arn
}

module "waf" {
  source  = "../../modules/waf"
  name    = local.name
  alb_arn = module.ecs.alb_arn
}

module "monitoring" {
  source                  = "../../modules/monitoring"
  name                    = local.name
  cluster_name            = module.ecs.cluster_name
  service_name            = module.ecs.service_name
  alb_arn_suffix          = module.ecs.alb_arn_suffix
  target_group_arn_suffix = module.ecs.target_group_arn_suffix
  alert_email             = var.alert_email
}

module "github_oidc" {
  count              = var.enable_github_oidc ? 1 : 0
  source             = "../../modules/github-oidc"
  name               = local.name
  oidc_provider_arn  = var.github_oidc_provider_arn
  github_owner       = var.github_owner
  github_owner_id    = var.github_owner_id
  github_repo        = var.github_repo
  github_repo_id     = var.github_repo_id
  ecr_repository_arn = module.ecr.repository_arn
  ecs_cluster_name   = module.ecs.cluster_name
  ecs_service_name   = module.ecs.service_name
}

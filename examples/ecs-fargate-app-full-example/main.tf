module "fargate_demo_app" {
  source = "./../../"

  name = "demo-app"

  namespace   = "acme"
  environment = "development"

  vpc_id = "vpc-0960e27ab6f279603"

  create_load_balancer      = false
  enable_container_insights = false
}

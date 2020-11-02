module "fargate_demo_app" {
  source = "./../../"

  name = "demo-app"

  namespace   = "acme"
  environment = "development"

  vpc_id = "vpc-0960e27ab6f279603"

  create_load_balancer      = false
  enable_container_insights = false
}

module "sells_report_job" {
  source = "../../modules/ecs-fargate-scheduled-job"

  app         = "demo-app"
  name        = "sells-report"
  environment = "development"

  schedule_expression = "rate(1 minute)"

  cluster_name    = module.fargate_demo_app.this_cluster_name
  container_image = "hello-world"

  private_subnet_ids = ["subnet-0aa7da64c340ad795", "subnet-08c362fd794760216"]
}

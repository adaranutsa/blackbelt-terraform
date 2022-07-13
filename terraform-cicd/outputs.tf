output "web_repo_url" {
  value = module.ecr_web.repository_url
}

output "api_repo_url" {
  value = module.ecr_api.repository_url
}

output "web_repo_name" {
  value = module.ecr_web.name
}

output "api_repo_name" {
  value = module.ecr_api.name
}
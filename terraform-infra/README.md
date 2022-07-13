Requirements: https://github.com/texanraj/bb-2022-containers/tree/main/Capstone

What am I going to do?

Use Terraform to create an ECS Cluster.
Create at least 2 services that are load balanced using an application load balancer
ECS Services scale up and down based on demand.
Deployments utilize CodeDeploy for Blue/Green deployments

Everything is stored in github and pipeline deployments are triggered via merge from a PR.

CodeBuild and CodePipeline are used for CI/CD for best practices. The CodeBuild appspec file is stored in the git repo.

Ensure encryption is used throughtout the cluster

Use secrets manager for storing and managing secrets for the application.

Containers will run a base load on FARGATE instances and auto scale using FARGATE_SPOT instances for cost savings
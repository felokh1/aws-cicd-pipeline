# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project
# Resource for Codebuild - This is the build spec for plan
resource "aws_codebuild_project" "tf-plan" {
  name          = "tf-cicd-plan"
  description   = "Plan stage for terraform"
  service_role  = aws_iam_role.tf-codebuild-role.arn  # Code Build role

  artifacts {
    type = "CODEPIPELINE" # we need artifacts for our pipeline
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    #image                      =  "hashicorp/terraform:latest" # The image is obtained from dockerhub (https://hub.docker.com/r/hashicorp/terraform/tags)
    #image                       = "hashicorp/terraform:0.14.3"
    image                      = "nginx"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential{
        credential = var.dockerhub_credentials
        credential_provider = "SECRETS_MANAGER"
    }
 }
 source {
     type   = "CODEPIPELINE"
     buildspec = file("buildspec/plan-buildspec.yml")  # pointing to the buildspec file. This file contains the instruction of what terraform will do
 }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codebuild_project
# Resource for Codebuild - This is the build spec for apply
resource "aws_codebuild_project" "tf-apply" {
  name          = "tf-cicd-apply"
  description   = "Apply stage for terraform"
  service_role  = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    #image                        = "hashicorp/terraform:latest" # The image is obtained from dockerhub (https://hub.docker.com/r/hashicorp/terraform/tags)
    #image                       = "hashicorp/terraform:0.14.3"
    image                       = "nginx"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential{
        credential = var.dockerhub_credentials
        credential_provider = "SECRETS_MANAGER"
    }
 }
 source {
     type   = "CODEPIPELINE"
     buildspec = file("buildspec/apply-buildspec.yml")
 }
}

# https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/codepipeline
# Resource: aws_codepipeline - Example Usage
resource "aws_codepipeline" "cicd_pipeline" {

    name = "tf-cicd"
    role_arn = aws_iam_role.tf-codepipeline-role.arn

    artifact_store {
        type="S3"
        location = aws_s3_bucket.codepipeline_artifacts.id
    }

    stage {
        name = "Source"
        action{
            name = "Source"
            category = "Source"
            owner = "AWS"
            provider = "CodeStarSourceConnection"
            version = "1"
            output_artifacts = ["tf-code"]
            configuration = {
                FullRepositoryId = "felokh1/aws-cicd-pipeline"
                BranchName   = "main"
                ConnectionArn = var.codestar_connections_credentials  # using codestar connection
                OutputArtifactFormat = "CODE_ZIP"
            }
        }
    }

    stage {
        name ="Plan"
        action{
            name = "Build"
            category = "Build"
            provider = "CodeBuild"
            version = "1"
            owner = "AWS"
            input_artifacts = ["tf-code"]
            configuration = {
                ProjectName = "tf-cicd-plan"
            }
        }
    }

    stage {
        name ="Deploy"
        action{
            name = "Deploy"
            category = "Build"
            provider = "CodeBuild"
            version = "1"
            owner = "AWS"
            input_artifacts = ["tf-code"]
            configuration = {
                ProjectName = "tf-cicd-apply"
            }
        }
    }

}
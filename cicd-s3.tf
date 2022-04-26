resource "aws_s3_bucket" "codepipeline_artifacts" {
  bucket = "aws-cicd-pipeline-felo2"
  #acl    = "private"
  force_destroy = true
} 
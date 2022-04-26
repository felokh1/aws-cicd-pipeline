terraform{
    backend "s3" {
        bucket = "aws-cicd-pipeline-felo2"
        encrypt = true
        key = "terraform.tfstate"
        region = "us-east-1"
    }
}

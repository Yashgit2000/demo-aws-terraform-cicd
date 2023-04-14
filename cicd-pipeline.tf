# resource "aws_codepipeline_webhook" "webhook123" {
#   name            = "webhook123"
#   authentication  = "GITHUB_HMAC"
#   target_action   = "Source"
#   target_pipeline = aws_codepipeline.tf-cicd.name

#   authentication_configuration {
#     secret_token = "64154636376de16f88e7be83f44e7226"
#   }

#   filter {
#     json_path = "$.ref"
#     match_equals = "refs/heads/master"
#   }
# }

# resource "aws_codepipeline" "source" {
#   name = "source"
#   role_arn = aws_iam_role.codepipeline.arn

#   artifact_store {
#     location = var.artifact_store_location
#     type     = var.artifact_store_type
#   }

#   stage {
#     name = "Source"

#     action {
#       name = "SourceAction"

#       category = "Source"

#       owner = "ThirdParty"

#       provider = "GitHub"

#       version = "1"

#       output_artifacts = ["SourceArtifact"]

#       configuration = {
#         Owner = var.github_owner
#         Repo = var.github_repo
#         Branch = var.github_branch
#         OAuthToken = var.github_oauth_token
#       }

#       run_order = 1
#     }
#   }
# }



resource "aws_codebuild_project" "tf-plan" {
  name          = "tf-cicd-plan"
  description   = "Plan stage for terraform"
  service_role  = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:0.14.3"
    type                        = "LINUX_CONTAINER"
    image_pull_credentials_type = "SERVICE_ROLE"
    registry_credential{
        credential = var.dockerhub_credentials
        credential_provider = "SECRETS_MANAGER"
    }
 }
 source {
     type   = "CODEPIPELINE"
     buildspec = file("buildspec/plan-buildspec.yml")
 }
}

resource "aws_codebuild_project" "tf-apply" {
  name          = "tf-cicd-apply"
  description   = "Apply stage for terraform"
  service_role  = aws_iam_role.tf-codebuild-role.arn

  artifacts {
    type = "CODEPIPELINE"
  }

  environment {
    compute_type                = "BUILD_GENERAL1_SMALL"
    image                       = "hashicorp/terraform:0.14.3"
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


resource "aws_codepipeline" "cicd_pipeline" {

    name = "tf-cicd"
    role_arn = aws_iam_role.tf-codepipeline-role.arn

    artifact_store {
        type="S3"
        location = aws_s3_bucket.code-pipeline-artifacts1.id
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
                FullRepositoryId = "Yashgit2000/demo-aws-terraform-cicd"
                BranchName   = "master"
                ConnectionArn = var.codestar_connector_credentials
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
        name = "Approve"
        action {
            name     = "Approval"
            category = "Approval"
            owner    = "AWS"
            provider = "Manual"
            version  = "1"

            configuration = {
                 
                ExternalEntityLink = "https://github.com/Yashgit2000/demo-aws-terraform-cicd" 
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
variable dockerhub_credentials{
    type = string
    default="arn:aws:secretsmanager:ap-south-1:875225952044:secret:codebuild/dockerhubb-qikhmd"
}

variable codestar_connector_credentials {
    type = string
    default = "arn:aws:codestar-connections:ap-south-1:875225952044:connection/fce305e8-2b0b-4ebd-aa4c-7e3b36dc716f"
}
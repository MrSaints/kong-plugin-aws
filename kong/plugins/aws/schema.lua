return {
  fields = {
    aws_region = {type = "string", required = true, enum = {
                  "us-east-1", "us-east-2", "ap-northeast-1", "ap-northeast-2", "us-west-2",
                  "ap-southeast-1", "ap-southeast-2", "eu-central-1", "eu-west-1"}},
    aws_service = {type = "string", required = true},
    aws_key = {type = "string", required = true},
    aws_secret = {type = "string", required = true},
    timestamp = {type = "timestamp", required = false},
  }
}

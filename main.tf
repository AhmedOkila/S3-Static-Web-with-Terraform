resource "aws_s3_bucket" "my-bucket" {
  bucket = "okila-devops547899"
  tags = {
    Name = "Static Web"
  }
}

resource "null_resource" "upload_folder" {
  depends_on = [aws_s3_bucket.my-bucket]
  provisioner "local-exec" {
    command = "aws s3 cp --recursive my-app/build s3://${aws_s3_bucket.my-bucket.bucket}"
  }
}
resource "aws_s3_object" "object" {
  bucket   = aws_s3_bucket.my-bucket.id
  for_each = fileset("my-app/build", "**/*.*")
  key      = each.value
}

resource "aws_s3_bucket_website_configuration" "my-bucket_static" {
  bucket = aws_s3_bucket.my-bucket.id
  index_document {
    suffix = "index.html"
  }
}

resource "aws_s3_bucket_public_access_block" "allow_public_access" {
  bucket                  = aws_s3_bucket.my-bucket.id
  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "allow_access_from_another_account" {
  bucket = aws_s3_bucket.my-bucket.id
  policy = data.aws_iam_policy_document.allow_public_access_policy.json
  depends_on = [ aws_s3_bucket_public_access_block.allow_public_access ]
}

data "aws_iam_policy_document" "allow_public_access_policy" {
  statement {
    principals {
      type        = "*"
      identifiers = ["*"]
    }
    actions = [
      "s3:GetObject",
      "s3:ListBucket",
    ]
    resources = [
      aws_s3_bucket.my-bucket.arn,
      "${aws_s3_bucket.my-bucket.arn}/*",
    ]
  }
}
#! Another Method to Create Bucket Policies using jsonencode()
# resource "aws_s3_bucket_policy" "allow_public_access" {
#   bucket = aws_s3_bucket.my-bucket.id
#   policy = jsonencode({
#     Version = "2012-10-17"
#     Id      = "MYBUCKETPOLICY"
#     Statement = [
#       {
#         Sid       = "IPAllow"
#         Effect    = "Allow"
#         Principal = "*"
#         Action    = ["s3:GetObject", "s3:DeleteObject", "s3:PutObject"]
#         Resource  = "${aws_s3_bucket.my-bucket.arn}/*"
#       },
#     ]
#   })
# }
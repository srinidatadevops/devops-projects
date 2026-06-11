locals {
  name                 = "${var.project_name}-${var.environment}"
  oidc_condition_key   = replace(var.oidc_issuer_url, "https://", "")
  service_account_path = "system:serviceaccount:${var.namespace}:${var.service_account_name}"
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      type        = "Federated"
      identifiers = [var.oidc_provider_arn]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_condition_key}:sub"
      values   = [local.service_account_path]
    }

    condition {
      test     = "StringEquals"
      variable = "${local.oidc_condition_key}:aud"
      values   = ["sts.amazonaws.com"]
    }
  }
}

data "aws_iam_policy_document" "app_access" {
  statement {
    actions = [
      "s3:ListBucket"
    ]

    resources = [var.bucket_arn]
  }

  statement {
    actions = [
      "s3:DeleteObject",
      "s3:GetObject",
      "s3:PutObject"
    ]

    resources = ["${var.bucket_arn}/*"]
  }
}

resource "aws_iam_role" "app" {
  name               = "${local.name}-pod-role"
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

resource "aws_iam_policy" "app_access" {
  name   = "${local.name}-pod-policy"
  policy = data.aws_iam_policy_document.app_access.json
}

resource "aws_iam_role_policy_attachment" "app_access" {
  role       = aws_iam_role.app.name
  policy_arn = aws_iam_policy.app_access.arn
}

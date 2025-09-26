data "aws_iam_policy_document" "task_assume" {
  statement {
    actions = ["sts:AssumeRole"]
    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}
resource "aws_iam_role" "task" {
  name               = "${local.name}-task-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = local.tags
}

resource "aws_iam_role" "exec" {
  name               = "${local.name}-exec-role"
  assume_role_policy = data.aws_iam_policy_document.task_assume.json
  tags               = local.tags
}

resource "aws_iam_role_policy" "task" {
  name = "${local.name}-task-inline"
  role = aws_iam_role.task.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      { Effect = "Allow", Action = ["logs:CreateLogGroup", "logs:CreateLogStream", "logs:PutLogEvents"], Resource = "*" },
      { Effect = "Allow", Action = ["secretsmanager:GetSecretValue", "secretsmanager:DescribeSecret", "secretsmanager:ListSecrets"], Resource = "*" },
      { Effect = "Allow", Action = ["ecs:RunTask", "ecs:RegisterTaskDefinition", "ecs:Describe*", "ecs:List*", "iam:PassRole"], Resource = "*" },
      { Effect = "Allow", Action = ["s3:*"], Resource = [aws_s3_bucket.io.arn, "${aws_s3_bucket.io.arn}/*"] }
    ]
  })
}

# Allow the execution role to read your DB secret (for env var injection at task startup)
resource "aws_iam_role_policy" "exec_secrets" {
  name = "${local.name}-exec-secrets"
  role = aws_iam_role.exec.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid      = "ReadRdsCredentials"
        Effect   = "Allow"
        Action   = [
          "secretsmanager:GetSecretValue",
          "secretsmanager:DescribeSecret"
        ]
        Resource = aws_secretsmanager_secret.db.arn
      }
    ]
  })
}

resource "aws_iam_openid_connect_provider" "github" {
  count           = var.github_oidc_provider_arn == "" ? 1 : 0
  url             = "https://token.actions.githubusercontent.com"
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = ["6938fd4d98bab03faadb97b34396831e3780aea1"]
  tags            = local.tags
}
locals {
  github_oidc_arn = var.github_oidc_provider_arn != "" ? var.github_oidc_provider_arn : aws_iam_openid_connect_provider.github[0].arn
}

data "aws_iam_policy_document" "gha_assume" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    principals {
      type        = "Federated"
      identifiers = [local.github_oidc_arn]
    }
    condition {
      test     = "StringEquals"
      variable = "token.actions.githubusercontent.com:aud"
      values   = ["sts.amazonaws.com"]
    }
    condition {
      test     = "StringLike"
      variable = "token.actions.githubusercontent.com:sub"
      values   = ["repo:${var.github_org}/${var.github_repo}:ref:${var.github_branch_ref}"]
    }
  }
}
resource "aws_iam_role" "github_actions_deploy" {
  name               = "${local.name}-github-actions-deploy"
  assume_role_policy = data.aws_iam_policy_document.gha_assume.json
  tags               = local.tags
}

data "aws_iam_policy_document" "gha_permissions" {
  statement {
    sid       = "ECRPushAndDescribe"
    effect    = "Allow"
    actions   = ["ecr:CreateRepository", "ecr:DescribeRepositories", "ecr:DescribeImages", "ecr:BatchCheckLayerAvailability", "ecr:CompleteLayerUpload", "ecr:InitiateLayerUpload", "ecr:PutImage", "ecr:UploadLayerPart", "ecr:GetAuthorizationToken"]
    resources = ["*"]
  }
  statement {
    sid       = "TerraformManageCore"
    effect    = "Allow"
    actions   = ["ecs:*", "elasticloadbalancing:*", "ec2:*", "rds:*", "s3:*", "logs:*", "secretsmanager:*", "iam:List*", "iam:Get*", "iam:CreateRole", "iam:DeleteRole", "iam:TagRole", "iam:UntagRole", "iam:PutRolePolicy", "iam:DeleteRolePolicy", "iam:AttachRolePolicy", "iam:DetachRolePolicy", "iam:CreatePolicy", "iam:CreatePolicyVersion", "iam:DeletePolicy", "iam:DeletePolicyVersion", "iam:SetDefaultPolicyVersion"]
    resources = ["*"]
  }
  statement {
    sid       = "PassTaskRolesToECS"
    effect    = "Allow"
    actions   = ["iam:PassRole"]
    resources = [aws_iam_role.task.arn, aws_iam_role.exec.arn]
  }
  statement {
    sid     = "ECRTagging"
    effect  = "Allow"
    actions = [
      "ecr:TagResource",
      "ecr:UntagResource",
      "ecr:ListTagsForResource"
    ]
    resources = ["*"]
  }
}
resource "aws_iam_policy" "gha_policy" {
  name   = "${local.name}-gha-deploy-policy"
  policy = data.aws_iam_policy_document.gha_permissions.json
  tags   = local.tags
}

resource "aws_iam_role_policy_attachment" "gha_attach" {
  role       = aws_iam_role.github_actions_deploy.name
  policy_arn = aws_iam_policy.gha_policy.arn
}

output "github_actions_role_arn" {
  value = aws_iam_role.github_actions_deploy.arn
}


# Attach the standard ECS execution role policy (pull from ECR, write logs, etc.)
resource "aws_iam_role_policy_attachment" "exec_ecs_managed" {
  role       = aws_iam_role.exec.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

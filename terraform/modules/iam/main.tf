resource "aws_iam_policy_document" "externaldns" {
  statement {
    effect    = "Allow"
    actions   = ["route53:ChangeResourceRecordSets"]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }


  statement {
    effect = "Allow"
    actions = [
      "route53:ListHostedZones",
      "route53:ListResourceRecordSets",
      "route53:ListTagsForResource"
    ]

    resources = ["*"]
  }
}

resource "aws_iam_policy" "externaldns" {
  name        = "externaldns-policy"
  description = "Policy for externaldDNS to manage Route53"
  policy      = aws_iam_policy_document.externaldns.json
}



resource "aws_iam_role" "externaldns" {
  name = "externaldns-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.cluster-oidc-issuer-url, "https://", "")}:sub" = "system:serviceaccount:external-dns:external-dns"
          "${replace(var.cluster-oidc-issuer-url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "externaldns" {
  role       = aws_iam_role.externaldns.name
  policy_arn = aws_iam_policy.externaldns.arn
}


resource "aws_iam_policy_document" "certmanager-role" {
  statement {
    effect    = "Allow"
    actions   = ["route53:GetChange"]
    resources = ["arn:aws:route53:::change/*"]
  }



  statement {
    effect = "Allow"
    actions = [
      "route53:ChangeResourceRecordSets",
      "route53:ListResourceRecordSets"
    ]
    resources = ["arn:aws:route53:::hostedzone/*"]
  }


  statement {
    effect    = "Allow"
    actions   = ["route53:ListHostedZonesByName"]
    resources = ["*"]
  }
}


resource "aws_iam_policy" "certmanager" {
  name        = "certmanager-policy"
  description = "Policy for Cert manager to manage Route53"
  policy      = aws_iam_policy_document.certmanager-role.json
}

data "aws_iam_openid_connect_provider" "eks" {
  arn = var.oidc-provider-arn
}


resource "aws_iam_role" "certmanager" {
  name = "certmanager-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.eks.arn
      }
      Action = "sts:AssumeRoleWithWebIdentity"
      Condition = {
        StringEquals = {
          "${replace(var.cluster-oidc-issuer-url, "https://", "")}:sub" = "system:serviceaccount:cert-manager:cert-manager"
          "${replace(var.cluster-oidc-issuer-url, "https://", "")}:aud" = "sts.amazonaws.com"
        }
      }
    }]
  })
}

resource "aws_iam_role_policy_attachment" "certmanager" {
  role       = aws_iam_role.certmanager.name
  policy_arn = aws_iam_policy.certmanager.arn
}


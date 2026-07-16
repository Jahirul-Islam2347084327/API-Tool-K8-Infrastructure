output "external-iam-arn" {
  value = aws_iam_role.externaldns.arn
}

output "cert-iam-arn" {
  value = aws_iam_role.certmanager.arn
}

output "externaldns_role_arn" {
  value = aws_iam_role.externaldns.arn
}

output "certmanager_role_arn" {
  value = aws_iam_role.certmanager.arn
} 
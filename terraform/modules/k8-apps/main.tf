resource "helm_release" "nginx_ingress" {
  name             = "ingress-nginx"
  repository       = "https://kubernetes.github.io/ingress-nginx"
  chart            = "ingress-nginx"
  namespace        = "ingress-nginx"
  create_namespace = true

  set =  [{
    name  = "controller.service.type"
    value = "LoadBalancer"
},{
    name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-type"  
    value = "external"
},{
    name = "controller.service.annotations.service\\.beta\\.kubernetes\\.io/aws-load-balancer-nlb-target-type"
    value = "instance"
}]
}

resource "helm_release" "external_dns" {
  name             = "external-dns"
  repository       = "https://kubernetes-sigs.github.io/external-dns"
  chart            = "external-dns"
  namespace        = "external-dns"
  create_namespace = true

  set = [{
    name  = "provider"
    value = "aws"
  }, {
    name  = "domainFilters[0]"
    value = "jahirulmadethisinaws.online"
  },
  {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.external-dns-iam
  }]
  depends_on = [helm_release.nginx_ingress]
}

resource "helm_release" "cert_manager" {
  name             = "cert-manager"
  repository       = "https://charts.jetstack.io"
  chart            = "cert-manager"
  namespace        = "cert-manager"
  create_namespace = true

  set = [{
    name  = "crds.enabled"
    value = "true"
  }, {
    name  = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"
    value = var.cert-manager-iam
  }]
  depends_on = [helm_release.nginx_ingress]
}

resource "helm_release" "argocd" {
  name             = "argocd"
  repository       = "https://argoproj.github.io/argo-helm"
  chart            = "argo-cd"
  namespace        = "argocd"
  create_namespace = true

  depends_on = [helm_release.nginx_ingress]
}

resource "helm_release" "prometheus" {
  name             = "prometheus"
  repository       = "https://prometheus-community.github.io/helm-charts"
  chart            = "kube-prometheus-stack"
  namespace        = "monitoring"
  create_namespace = true

  depends_on = [helm_release.nginx_ingress]
}
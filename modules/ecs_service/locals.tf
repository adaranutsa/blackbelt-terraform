locals {
    cluster_name = split("/", var.cluster_arn)[1]
    lb_name_prefix = "${var.namespace}-${var.service_name}"
}
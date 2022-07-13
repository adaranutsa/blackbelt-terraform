data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["${var.assume_role_principal}.amazonaws.com"]
    }
  }
}

resource "aws_iam_role" "main" {
  name               = var.name
  description        = var.description
  assume_role_policy = data.aws_iam_policy_document.assume_role.json
}

# Inline Policy Creations
resource "aws_iam_role_policy" "main" {
  count  = length(var.inline_policies)
  name   = lookup(var.inline_policies[count.index], "name")
  role   = aws_iam_role.main.id
  policy = lookup(var.inline_policies[count.index], "policy")
}

# Management Policy Attachments
resource "aws_iam_role_policy_attachment" "main" {
  count      = length(var.managed_policies)
  role       = aws_iam_role.main.id
  policy_arn = "arn:aws:iam::aws:policy/${var.managed_policies[count.index]}"
}

<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

| Name | Version |
|------|---------|
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | ~> 1.4 |
| <a name="requirement_aws"></a> [aws](#requirement\_aws) | ~> 3.0 |

## Providers

No providers.

## Modules

| Name | Source | Version |
|------|--------|---------|
| <a name="module_bootstrap"></a> [bootstrap](#module\_bootstrap) | sourcefuse/arc-bootstrap/aws | 1.0.9 |
| <a name="module_tags"></a> [tags](#module\_tags) | sourcefuse/arc-tags/aws | 1.2.2 |

## Resources

No resources.

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_bucket_name"></a> [bucket\_name](#input\_bucket\_name) | Name of the bucket. | `string` | n/a | yes |
| <a name="input_dynamo_kms_master_key_id"></a> [dynamo\_kms\_master\_key\_id](#input\_dynamo\_kms\_master\_key\_id) | The Default ID of an AWS-managed customer master key (CMK) for Amazon Dynamo | `string` | `null` | no |
| <a name="input_dynamodb_name"></a> [dynamodb\_name](#input\_dynamodb\_name) | Name of the Dynamo DB lock table. | `string` | n/a | yes |
| <a name="input_environment"></a> [environment](#input\_environment) | Name of the Dynamo DB lock table. | `string` | `"dev"` | no |

## Outputs

No outputs.
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->

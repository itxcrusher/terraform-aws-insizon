# Note

| File                      | When to touch                             | Notes                                                                        |
| ------------------------- | ----------------------------------------- | ---------------------------------------------------------------------------- |
| **apps.yaml**             | adding a new micro-service or environment | remember to create a matching CloudFront key-group entry *and* budget line   |

| **budget.yaml**           | adjusting spend limits / alerts           | AWS won’t let you edit start\_date after creation—destroy & recreate instead |

| **cloudfront.yaml**       | rolling new keys (rotate quarterly)       | keep ≤100 keys per group; renaming `key_group_name` forces replacement       |

| **elastic-container-registry.yaml**              | onboarding a new containerised workload   | repo names are immutable; use service\_name override if you need a rename    |

| **elastic-bean-stalk.yaml** | version bump or adding env vars           | platform strings are brittle—copy exactly from the AWS console               |

| **lambda-event.yaml**     | new function or schedule change           | changing cron rate forces new EventBridge rule, but not the Lambda itself    |

| **static-files.yaml**     | excluding secrets/logs from upload        | wildcard patterns follow Go’s `filepath.Match` rules                         |

| **user-roles.yaml**       | onboarding/offboarding humans & bots      | rotate access keys via IAM console **and** Secrets Manager after update      |

Remove these from YAML (Terraform will set them):

- S3_BUCKET_NAME
- AWS_CLOUDFRONT_DOMAIN
- AWS_CLOUDFRONT_KEY_PAIR_ID
- AWS_CLOUDFRONT_PRIVATE_KEY
- AWS_IAM_SERVICE_USER_ACCESS_KEY_ID
- AWS_IAM_SERVICE_USER_SECRET_ACCESS_KEY

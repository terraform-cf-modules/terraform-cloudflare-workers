# Submodule: queue

Cloudflare Queues and their consumers.

A queue on its own only accepts producers. A consumer is what drains it: `worker` for push delivery to a Worker's
`queue` handler, `http_pull` for a client that pulls batches over HTTP.

```hcl
module "queue" {
  source  = "terraform-cf-modules/workers/cloudflare//modules/queue"
  version = "~> 0.1"

  account_id = var.account_id

  queues = {
    jobs = {
      queue_name               = "api-jobs"
      message_retention_period = 345600
    }
  }

  consumers = {
    jobs = {
      type        = "worker"
      queue_key   = "jobs"        # a key in var.queues
      script_name = "api"
      batch_size  = 10
      max_retries = 3
    }
  }
}
```

Give a Worker a producer binding with the queue name:

```hcl
bindings = {
  JOBS = { type = "queue", queue_name = module.queue.queue_names["jobs"] }
}
```

<!-- BEGIN_TF_DOCS -->
## Requirements

| Name | Version |
| ---- | ------- |
| <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) | >= 1.12.0 |
| <a name="requirement_cloudflare"></a> [cloudflare](#requirement\_cloudflare) | ~> 5.24 |

## Providers

| Name | Version |
| ---- | ------- |
| <a name="provider_cloudflare"></a> [cloudflare](#provider\_cloudflare) | ~> 5.24 |

## Resources

| Name | Type |
| ---- | ---- |
| [cloudflare_queue.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/queue) | resource |
| [cloudflare_queue_consumer.this](https://registry.terraform.io/providers/cloudflare/cloudflare/latest/docs/resources/queue_consumer) | resource |

## Inputs

| Name | Description | Type | Default | Required |
| ---- | ----------- | ---- | ------- | :------: |
| <a name="input_account_id"></a> [account\_id](#input\_account\_id) | Cloudflare account ID that owns the queues. | `string` | `null` | no |
| <a name="input_consumers"></a> [consumers](#input\_consumers) | Queue consumers, keyed by a stable identifier.<br/><br/>Set `queue_key` to consume a queue created by this submodule, or `queue_id` to consume an existing queue.<br/>Exactly one of the two must be set. `type` is `worker` for push consumers and `http_pull` for pull consumers;<br/>`script_name` only applies to `worker` consumers. | <pre>map(object({<br/>    type                  = string<br/>    queue_key             = optional(string)<br/>    queue_id              = optional(string)<br/>    script_name           = optional(string)<br/>    dead_letter_queue     = optional(string)<br/>    batch_size            = optional(number)<br/>    max_concurrency       = optional(number)<br/>    max_retries           = optional(number)<br/>    max_wait_time_ms      = optional(number)<br/>    retry_delay           = optional(number)<br/>    visibility_timeout_ms = optional(number)<br/>  }))</pre> | `{}` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Whether to create the resources managed by this submodule. | `bool` | `true` | no |
| <a name="input_queues"></a> [queues](#input\_queues) | Cloudflare Queues to create, keyed by a stable identifier.<br/><br/>`delivery_delay` and `message_retention_period` are in seconds. `delivery_paused` stops delivery to consumers<br/>without deleting the queue. | <pre>map(object({<br/>    queue_name               = string<br/>    delivery_delay           = optional(number)<br/>    delivery_paused          = optional(bool)<br/>    message_retention_period = optional(number)<br/>  }))</pre> | `{}` | no |

## Outputs

| Name | Description |
| ---- | ----------- |
| <a name="output_consumer_ids"></a> [consumer\_ids](#output\_consumer\_ids) | Consumer ID of each created queue consumer, keyed by the same keys as var.consumers. |
| <a name="output_consumers"></a> [consumers](#output\_consumers) | Full cloudflare\_queue\_consumer objects, keyed by the same keys as var.consumers. |
| <a name="output_enabled"></a> [enabled](#output\_enabled) | Whether this submodule created its resources. |
| <a name="output_queue_ids"></a> [queue\_ids](#output\_queue\_ids) | Queue ID of each created queue, keyed by the same keys as var.queues. |
| <a name="output_queue_names"></a> [queue\_names](#output\_queue\_names) | Queue name of each created queue, keyed by the same keys as var.queues. |
| <a name="output_queues"></a> [queues](#output\_queues) | Full cloudflare\_queue objects, keyed by the same keys as var.queues. |
<!-- END_TF_DOCS -->

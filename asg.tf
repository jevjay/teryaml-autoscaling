resource "aws_autoscaling_group" "asg_az" {
  for_each = try({ for i in local.asg_config : i.name => i if i.availability_zones != null }, {})

  name               = each.value.name               # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#name
  availability_zones = each.value.availability_zones # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#availability_zones

  desired_capacity = each.value.desired_capacity # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#desired_capacity
  max_size         = each.value.max_size         # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#max_size
  min_size         = each.value.min_size         # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#min_size

  default_cooldown          = each.value.default_cooldown          # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#default_cooldown
  health_check_grace_period = each.value.health_check_grace_period # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#health_check_grace_period
  health_check_type         = each.value.health_check_type         # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#health_check_type
  load_balancers            = each.value.load_balancers            # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#load_balancers
  target_group_arns         = each.value.target_group_arns         # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#target_group_arns

  force_delete = each.value.force_delete # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#force_delete

  # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#launch_template
  launch_template {
    id      = aws_launch_template.asg[each.key].id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = try(flatten([
      for i, t in local.common_tags : {
        k = i
        v = t.value
      }
    ]), [])

    content {
      key                 = tag.value.k
      value               = tag.value.v
      propagate_at_launch = true
    }
  }
}

resource "aws_autoscaling_group" "asg_vpc" {
  for_each = try({ for i in local.asg_config : i.name => i if i.vpc_zone_identifier != null }, {})

  name = each.value.name # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#name

  desired_capacity = each.value.desired_capacity # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#desired_capacity
  max_size         = each.value.max_size         # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#max_size
  min_size         = each.value.min_size         # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#min_size

  default_cooldown          = each.value.default_cooldown          # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#default_cooldown
  health_check_grace_period = each.value.health_check_grace_period # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#health_check_grace_period
  health_check_type         = each.value.health_check_type         # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#health_check_type
  load_balancers            = each.value.load_balancers            # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#load_balancers
  vpc_zone_identifier       = each.value.vpc_zone_identifier       # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#vpc_zone_identifier
  target_group_arns         = each.value.target_group_arns         # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#target_group_arns

  force_delete = each.value.force_delete # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#force_delete

  # Details: https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/autoscaling_group#launch_template
  launch_template {
    id      = aws_launch_template.asg[each.key].id
    version = "$Latest"
  }

  dynamic "tag" {
    for_each = try(flatten([
      for i, t in local.common_tags : {
        k = i
        v = t.value
      }
    ]), [])

    content {
      key                 = tag.value.k
      value               = tag.value.v
      propagate_at_launch = true
    }
  }
}

resource "aws_launch_template" "asg" {
  for_each = try({ for p in local.launch_template_config : p.group_name => p }, {})

  name_prefix             = "${each.value.name}-config"
  image_id                = each.value.image_id
  instance_type           = each.value.instance_type
  disable_api_termination = each.value.disable_api_termination
  ebs_optimized           = each.value.ebs_optimized

  iam_instance_profile {
    name = aws_iam_instance_profile.asg[each.key].id
  }

  dynamic "block_device_mappings" {
    for_each = each.value.block_devices

    content {
      device_name  = block_device_mappings.value["name"]
      virtual_name = block_device_mappings.value["virtual_name"]

      ebs {
        volume_size = block_device_mappings.value["size"]
      }
    }
  }

  dynamic "capacity_reservation_specification" {
    for_each = each.value.capacity_reservation

    content {
      capacity_reservation_preference = capacity_reservation_specification.value.preference
    }
  }

  dynamic "cpu_options" {
    for_each = each.value.cpu_options

    content {
      core_count       = cpu_options.value.core_count
      threads_per_core = cpu_options.value.threads_per_core
    }
  }

  dynamic "credit_specification" {
    for_each = each.value.credit_specification

    content {
      cpu_credits = credit_specification.value.cpu_credits
    }
  }

  dynamic "elastic_gpu_specifications" {
    for_each = each.value.elastic_gpu_specifications

    content {
      type = elastic_gpu_specifications.value.type
    }
  }

  dynamic "elastic_inference_accelerator" {
    for_each = each.value.elastic_inference_accelerator

    content {
      type = elastic_inference_accelerator.value.type
    }
  }

  instance_initiated_shutdown_behavior = each.value.instance_initiated_shutdown_behavior

  dynamic "instance_market_options" {
    for_each = each.value.instance_market_options

    content {
      market_type = "spot"
      spot_options {
        block_duration_minutes         = instance_market_options.value.block_duration_minutes
        instance_interruption_behavior = instance_market_options.value.instance_interruption_behavior
        max_price                      = instance_market_options.value.max_price
        spot_instance_type             = instance_market_options.value.spot_instance_type
        valid_until                    = instance_market_options.value.valid_until
      }
    }
  }

  kernel_id = each.value.kernel_id

  key_name = each.value.ssh_key_name

  dynamic "license_specification" {
    for_each = each.value.license_specification

    content {
      license_configuration_arn = license_specification.value.arn
    }
  }

  dynamic "metadata_options" {
    for_each = each.value.metadata_options

    content {
      http_endpoint               = metadata_options.value.http_endpoint
      http_tokens                 = metadata_options.value.http_tokens
      http_put_response_hop_limit = metadata_options.value.http_put_response_hop_limit
      instance_metadata_tags      = metadata_options.value.instance_metadata_tags
    }
  }

  dynamic "monitoring" {
    for_each = each.value.monitoring

    content {
      enabled = monitoring.value.enabled
    }
  }

  dynamic "network_interfaces" {
    for_each = each.value.network_interfaces

    content {
      associate_public_ip_address = network_interfaces.value.associate_public_ip_address
    }
  }

  dynamic "placement" {
    for_each = each.value.placement

    content {
      availability_zone = placement.value.availability_zone
    }
  }

  ram_disk_id = each.value.ram_disk_id

  vpc_security_group_ids = each.value.vpc_security_group_ids

  dynamic "tag_specifications" {
    for_each = each.value.tag_specifications

    content {
      resource_type = tag_specifications.value.type
      tags          = tag_specifications.value.tags
    }
  }

  user_data = base64encode(file("${path.module}/${each.value.user_data}"))
}

resource "aws_autoscaling_schedule" "asg" {
  for_each = { for i in local.schedule_config : i.name => i }

  scheduled_action_name = each.value.name
  min_size              = each.value.min_size
  max_size              = each.value.max_size
  desired_capacity      = each.value.desired_capacity
  start_time            = each.value.start_time
  end_time              = each.value.end_time

  autoscaling_group_name = each.value.is_vpc ? aws_autoscaling_group.asg_vpc[each.value.group_name].name : aws_autoscaling_group.asg_az[each.value.group_name].name
}

resource "aws_cloudwatch_metric_alarm" "asg" {
  for_each = { for i in local.scaling_alarm_config : i.name => i }

  alarm_name          = each.value.name
  comparison_operator = each.value.comparison_operator
  evaluation_periods  = each.value.evaluation_periods
  metric_name         = each.value.metric_name
  namespace           = each.value.namespace
  period              = each.value.period
  statistic           = each.value.statistic
  threshold           = each.value.threshold

  dimensions = {
    AutoScalingGroupName = each.value.is_az ? aws_autoscaling_group.asg_az[each.value.group_name].name : aws_autoscaling_group.asg_vpc[each.value.group_name].name
  }

  alarm_description = each.value.alarm_description
  alarm_actions     = [aws_autoscaling_policy.asg[each.value.policy_name].arn]

  tags = merge({
    Name = each.value.name
  }, local.common_tags)
}

resource "aws_autoscaling_policy" "asg" {
  for_each = { for i in local.scaling_config : i.name => i }

  name                      = each.value.name
  scaling_adjustment        = each.value.scaling_adjustment
  adjustment_type           = each.value.adjustment_type
  cooldown                  = each.value.cooldown
  policy_type               = each.value.policy_type
  estimated_instance_warmup = each.value.estimated_instance_warmup
  enabled                   = each.value.enabled
  min_adjustment_magnitude  = each.value.min_adjustment_magnitude
  metric_aggregation_type   = each.value.metric_aggregation_type

  dynamic "step_adjustment" {
    for_each = each.value.step_adjustment

    content {
      scaling_adjustment          = step_adjustment.value.scaling_adjustment
      metric_interval_lower_bound = step_adjustment.value.metric_interval_lower_bound
      metric_interval_upper_bound = step_adjustment.value.metric_interval_upper_bound
    }
  }

  dynamic "target_tracking_configuration" {
    for_each = each.value.target_tracking_configuration

    content {
      target_value     = target_tracking_configuration.value.target_value
      disable_scale_in = target_tracking_configuration.value.disable_scale_in

      dynamic "predefined_metric_specification" {
        for_each = target_tracking_configuration.value.predefined_metric_specification

        content {
          predefined_metric_type = predefined_metric_specification.value.type
          resource_label         = predefined_metric_specification.value.resource_label
        }
      }

      dynamic "customized_metric_specification" {
        for_each = target_tracking_configuration.value.customized_metric_specification

        content {
          metric_name = customized_metric_specification.value.name
          namespace   = customized_metric_specification.value.namespace
          statistic   = customized_metric_specification.value.statistic
          unit        = customized_metric_specification.value.unit

          dynamic "metric_dimension" {
            for_each = customized_metric_specification.value.dimension

            content {
              name  = metric_dimension.value.name
              value = metric_dimension.value.value
            }
          }
        }
      }
    }
  }

  dynamic "predictive_scaling_configuration" {
    for_each = each.value.predictive_scaling_configuration

    content {
      max_capacity_breach_behavior = predictive_scaling_configuration.value.max_capacity_breach_behavior
      max_capacity_buffer          = predictive_scaling_configuration.value.max_capacity_buffer
      mode                         = predictive_scaling_configuration.value.mode
      scheduling_buffer_time       = predictive_scaling_configuration.value.scheduling_buffer_time

      metric_specification {
        target_value = lookup(predictive_scaling_configuration.value.metric_specification, "target_value", null)

        dynamic "predefined_load_metric_specification" {
          for_each = lookup(predictive_scaling_configuration.value.metric_specification, "predefined_load_metric", {})

          content {
            predefined_metric_type = predefined_load_metric_specification.value.type
            resource_label         = predefined_load_metric_specification.value.resource_label
          }
        }

        dynamic "predefined_metric_pair_specification" {
          for_each = lookup(predictive_scaling_configuration.value.metric_specification, "predefined_metric_pair", {})

          content {
            predefined_metric_type = predefined_load_metric_specification.value.type
            resource_label         = predefined_load_metric_specification.value.resource_label
          }
        }

        dynamic "predefined_scaling_metric_specification" {
          for_each = lookup(predictive_scaling_configuration.value.metric_specification, "predefined_scaling_metric", {})

          content {
            predefined_metric_type = predefined_load_metric_specification.value.type
            resource_label         = predefined_load_metric_specification.value.resource_label
          }
        }

        dynamic "customized_load_metric_specification" {
          for_each = lookup(predictive_scaling_configuration.value.metric_specification, "customized_load_metric", {})

          content {
            dynamic "metric_data_queries" {
              for_each = { for query in customized_load_metric_specification.value : query.id => query }

              content {
                id          = metric_data_queries.value.id
                expression  = metric_data_queries.value.expression
                return_data = metric_data_queries.value.return_data
                label       = metric_data_queries.value.label

                dynamic "metric_stat" {
                  for_each = metric_data_queries.value.metric_stat

                  content {
                    stat = metric_stat.value.stat
                    metric {
                      metric_name = metric_stat.value.name
                      namespace   = metric_stat.value.namespace

                      dynamic "dimensions" {
                        for_each = metric_stat.value.dimensions

                        content {
                          name  = dimensions.value.name
                          value = dimensions.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "customized_capacity_metric_specification" {
          for_each = lookup(predictive_scaling_configuration.value.metric_specification, "customized_capacity_metric", {})

          content {
            dynamic "metric_data_queries" {
              for_each = { for query in customized_capacity_metric_specification.value : query.id => query }

              content {
                id          = metric_data_queries.value.id
                expression  = metric_data_queries.value.expression
                return_data = metric_data_queries.value.return_data
                label       = metric_data_queries.value.label

                dynamic "metric_stat" {
                  for_each = metric_data_queries.value.metric_stat

                  content {
                    stat = metric_stat.value.stat
                    metric {
                      metric_name = metric_stat.value.name
                      namespace   = metric_stat.value.namespace

                      dynamic "dimensions" {
                        for_each = metric_stat.value.dimensions

                        content {
                          name  = dimensions.value.name
                          value = dimensions.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }

        dynamic "customized_scaling_metric_specification" {
          for_each = lookup(predictive_scaling_configuration.value.metric_specification, "customized_scaling_metric", {})

          content {
            dynamic "metric_data_queries" {
              for_each = { for query in customized_scaling_metric_specification.value : query.id => query }

              content {
                id          = metric_data_queries.value.id
                expression  = metric_data_queries.value.expression
                return_data = metric_data_queries.value.return_data
                label       = metric_data_queries.value.label

                dynamic "metric_stat" {
                  for_each = metric_data_queries.value.metric_stat

                  content {
                    stat = metric_stat.value.stat
                    metric {
                      metric_name = metric_stat.value.name
                      namespace   = metric_stat.value.namespace

                      dynamic "dimensions" {
                        for_each = metric_stat.value.dimensions

                        content {
                          name  = dimensions.value.name
                          value = dimensions.value.value
                        }
                      }
                    }
                  }
                }
              }
            }
          }
        }
      }
    }
  }

  autoscaling_group_name = each.value.is_vpc ? aws_autoscaling_group.asg_vpc[each.value.group_name].name : aws_autoscaling_group.asg_az[each.value.group_name].name
}

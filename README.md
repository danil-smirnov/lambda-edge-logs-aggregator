lambda-edge-logs-aggregator
===========================

This project is to aggregate cross-region Lambda@Edge logs into one CloudWatch log group.

The logs will be streamed into joint CloudWatch group in the region of Log Proxy deployed.

How to deploy
-------------

1. Create Cloudformation stack from template.yaml.  
   Specify 'LogLabel' parameter if you want to stream custom entries, marked by LogLabel.  
   If you skip the parameter, only REPORT entries will be streamed.

2. Run `subscribe.sh 'Lambda@Edge name'` to autodiscover and subscribe to Lambda@Edge logs.  
   (Note that Lambda@Edge only creates a log group in a region when invoked first time.  
   You can re-run `subscribe.sh` to subscribe newly created log groups.)

FAQ
---

**How to stream entries with custom label only (no REPORT entries)?**

To stream entries with custom label only, run:
```
subscribe.sh 'Lambda@Edge name' '?CUSTOM_LABEL'

```
More info on filter patterns:  
https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html

Disclaimer
----------

The solution meant for moderate load only as Lambda functions concurrent execution limit  
(1000 per account/region by default) might be exceeded in case of intensive log streams.

In case of high load please use alternative architecture, i.e. Kinesis-powered one:  
https://aws.amazon.com/blogs/networking-and-content-delivery/aggregating-lambdaedge-logs/

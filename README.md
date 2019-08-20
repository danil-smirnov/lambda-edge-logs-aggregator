lambda-edge-logs-aggregator
===========================

This project is to aggregate cross-region Lambda@Edge logs into one CloudWatch log group.

The logs will be streamed into joint CloudWatch group in the region of Log Proxy Lambda  
Function deployed.

Please read this blog post for more details:  
https://blog.smirnov.la/aggregating-lambda-edge-logs-into-one-cloudwatch-log-group-52cdef2e7ce2

The solution contains two versions: the simplistic one, powered by subscription shell script,  
and all-in-one CloudFormation stack, compatible with AWS Serverless Application Repository.

Simplified version
------------------

This version includes LogProxy Lambda in CloudFormation stack and subscription helper script.  
No other resources apart from those relevant to LogProxy Lambda are deployed with the stack.

### How to deploy

1. Create CloudFormation stack from template.yaml.  
   Specify 'LogLabel' parameter if you want to stream custom entries, marked by LogLabel.  
   If you skip the parameter, only REPORT entries will be streamed.

2. Run `subscribe.sh 'Lambda@Edge name'` to autodiscover and subscribe to Lambda@Edge logs.  
   (Note that Lambda@Edge only creates a log group in a region when invoked first time.  
   You can re-run `subscribe.sh` to subscribe newly created log groups.)

### FAQ

**How to stream entries with custom label only (no REPORT entries)?**

To stream entries with custom label only, run:
```
subscribe.sh 'Lambda@Edge name' '?CUSTOM_LABEL'

```
More info on filter patterns:  
https://docs.aws.amazon.com/AmazonCloudWatch/latest/logs/FilterAndPatternSyntax.html

Serverless Application Repository version
-----------------------------------------

This version contains all the resources in one CloudFormation template and accessible  
through AWS Serverless Application Repository [url](https://serverlessrepo.aws.amazon.com/applications/arn:aws:serverlessrepo:us-east-1:085576722239:applications~lambda-edge-logs-aggregator).

Additional LogSubscribe Lambda function is created along with LogProxy to subscribe  
the latter to Lambda@Edge CloudWatch log groups on stack creation or by schedule.

### How to deploy

1. Create CloudFormation stack from template-all-in-one.yaml.  
   Specify 'LogLabel' parameter if you want to stream custom entries, marked by LogLabel.  
   Set 'Report' parameter to 'false' to avoid streaming of REPORT entries.  
   If 'SubscriptionSchedule' parameter set, CloudWatch Events Rule has created to re-run  
   the subscription on the schedule specified.

### FAQ

**How to stream entries with custom label only (no REPORT entries)?**

Update the stack with 'Report' parameter set to 'false'.

**How to re-run subscribe operation ad hoc, without CloudFormation stack update?**

1. Approach Lambda Service in AWS console
2. Click on LogSubscribeFunction
3. Click on 'Select a test event' drop down, then on 'Configure test events'
4. Put something to 'Event name', then click on 'Create'
5. Click on 'Test' button

Disclaimer
----------

The solution meant for moderate load only as Lambda functions concurrent execution limit  
(1000 per account/region by default) might be exceeded in case of intensive log streams.

In case of high load please use alternative architecture, i.e. Kinesis-powered one:  
https://aws.amazon.com/blogs/networking-and-content-delivery/aggregating-lambdaedge-logs/

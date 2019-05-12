#!/bin/bash

if [ "$#" -lt 1 ]; then
  echo "Usage: $0 <Lambda@Edge name> ['Filter pattern']"
  exit 1
fi

EDGE_NAME="$1"

LOG_LABEL='?'$(aws cloudformation list-exports --query 'Exports[?Name == `LogLabel2`].Value' --output text)

if [ "$#" -eq 2 ]; then
  FILTER_PATTERN="$2"
  if [[ "${LOG_LABEL}" != '?LogLabelNotDefined' ]] && [[ "${LOG_LABEL}" != *"${FILTER_PATTERN}"* ]] ; then
    echo "Warning: LogLabel '${LOG_LABEL}' not found in filter pattern '${FILTER_PATTERN}'"
  fi
else
  FILTER_PATTERN='?REPORT'
  if [[ "${LOG_LABEL}" != '?LogLabelNotDefined' ]] ; then
    FILTER_PATTERN="${FILTER_PATTERN} ${LOG_LABEL}"
  fi
fi

LOGPROXY_ARN=$(aws cloudformation list-exports --query 'Exports[?Name == `LogProxyFunctionArn2`].Value' --output text)

if [[ -z "${LOGPROXY_ARN}" ]] ; then
  echo 'Error: Log Proxy Lambda Function not found'
  exit 1
fi

echo "Searching for Lambda@Edge log groups in AWS regions..."

regions=()
for region in $(aws --output text  ec2 describe-regions | cut -f 3)
do
  if [[ "${region}" = "us-east-1" ]] \
    && [[ -n "$(aws --output text  logs describe-log-groups --log-group-name-prefix "/aws/lambda/$EDGE_NAME" --region $region --query 'logGroups[].logGroupName')" ]] ; then
    regions+=("${region}")
  elif [[ -n "$(aws --output text  logs describe-log-groups --log-group-name-prefix "/aws/lambda/us-east-1.$EDGE_NAME" --region $region --query 'logGroups[].logGroupName')" ]] ; then
    regions+=("${region}")
  fi
done

if [ ${#regions[@]} -eq 0 ]; then
  echo 'No Lambda@Edge log groups found'
  exit 0
fi

echo -e "\nSubscribing ${LOGPROXY_ARN}\n  to Lambda@Edge logs in regions: ${regions[@]}...\n  with filter pattern '${FILTER_PATTERN}'\n"

for region in "${regions[@]}"
do

if [[ "${region}" = "us-east-1" ]] ; then
    LOGGROUP="/aws/lambda/${EDGE_NAME}"
else
    LOGGROUP="/aws/lambda/us-east-1.${EDGE_NAME}"
fi

err=$( aws logs put-subscription-filter \
    --log-group-name "${LOGGROUP}" \
    --filter-name "${region}" \
    --filter-pattern "${FILTER_PATTERN}" \
    --destination-arn "${LOGPROXY_ARN}" \
    --region "${region}" 2>&1 )

if [ "$?" -eq "0" ]; then
  echo -e "Subscribed to ${EDGE_NAME} logs in ${region}.\n"
else
  echo -e "Error:${err}\n"
fi

done

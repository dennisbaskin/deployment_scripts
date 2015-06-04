#! /usr/bin/env bash

# You need AWS CLI installed and credentials property set up.
aws --version
aws configure set aws_access_key_id $AWSKEY
aws configure set aws_secret_access_key $AWSSECRETKEY
aws configure set default.region us-west-2
aws configure set default.output json

# The IAM user associated with your credentials will need to have
# read/write access to the specified bucket.
set -e

if ! [ -n $GEM_BUCKET ]; then
    echo "Please set the GEM_BUCKET environment variable."
    exit 1;
fi
# Check if this SHA is tagged
CURRENT_SHA=`git rev-parse HEAD`
TAGGED=`git tag --points-at=$CURRENT_SHA`
if ! [[ $TAGGED =~ ^v[0-9] ]]; then
    echo "No Tagged version found."
    exit 0
fi
echo "Tagged version found $TAGGED. Will build and sync."

# Sync a local copy of the gems to date
mkdir -p local
aws s3 sync s3://$GEM_BUCKET local

# Build the gem
rake build

# Rebuild the index with the new gem
cp pkg/*.gem local/gems
gem generate_index --update --directory local

# Sync the updates back to S3
aws s3 sync local s3://$GEM_BUCKET

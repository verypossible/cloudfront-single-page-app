#!/bin/bash

ACTION=
DOMAINNAME=
STACKNAME=
ZONEID=


usage() {
    echo "./manage-stash.sh [create|describe|upate] --domain somedomain.com --zone-id ZONE_ID --name my-stack-name-dev"
    exit 1
}

check() {
    if ! type aws &> /dev/null; then
        echo "The awscli tools are required. Please see https://aws.amazon.com/cli/"
        exit 1
    fi

    if [[ $AWS_DEFAULT_REGION != "us-east-1" ]]; then
        cat << EOF

The default AWS region must be set to us-east-1 before using this script.  Your current default
region is set to: "$AWS_DEFAULT_REGION"

Export the variable below and rerun this command.

export AWS_DEFAULT_REGION=us-east-1

EOF
        exit 1
    fi
}


# get the action which should be in the first position
case $1 in
    create | describe | update)
        # yay
        ACTION=$1
        ;;
    *)
        echo "Invalid action: $1"
        usage
        ;;
esac

# check prereqs
check

while [[ $# -gt 1 ]]
do
    key="$1"
    case $key in
        --domain)
            DOMAINNAME="$2"
            shift # past argument
            ;;
        --zone-id)
            ZONEID="$2"
            shift
            ;;
        --name)
            STACKNAME="$2"
            shift
            ;;
        *)
            # unknown option
            ;;
    esac
    shift
done

# stackname and zone always required
if [[ -z $STACKNAME ]]; then
    usage
fi


# Do the work
if [[ $ACTION = "describe" ]]; then
    aws cloudformation describe-stacks --stack-name $STACKNAME
else
    if [[ -z $DOMAINNAME || -z $ZONEID ]]; then
        usage
    fi
    aws cloudformation "$ACTION-stack" \
        --stack-name $STACKNAME \
        --template-body file://static-site.yml \
        --parameters \
                ParameterKey=HostedZone,ParameterValue=$DOMAINNAME \
                ParameterKey=HostedZoneId,ParameterValue=$ZONEID
fi

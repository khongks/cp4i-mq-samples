#!/bin/bash
#
#  (C) Copyright IBM Corp. 2021. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Not for Production use. For demo and training only.
#

# Find the queue manager host name

NAMESPACE=${1:-mq}

qmhostname=`oc get route -n ${NAMESPACE} qm2-ibm-mq-qm -o jsonpath="{.spec.host}"`
echo $qmhostname


# Test:

ping -c 3 $qmhostname

# Create ccdt.json

cat > ccdt.json << EOF
{
    "channel":
    [
        {
            "name": "QM2CHL",
            "clientConnection":
            {
                "connection":
                [
                    {
                        "host": "$qmhostname",
                        "port": 443
                    }
                ],
                "queueManager": "QM2"
            },
            "transmissionSecurity":
            {
              "cipherSpecification": "ANY_TLS12_OR_HIGHER"
            },
            "type": "clientConnection"
        }
   ]
}
EOF

# Set environment variables for the client

export MQCCDTURL=file://ccdt/Users/kskhong/Documents/Dev/mq/cp4i-mq-samples/01-tlsccdt.json
export MQSSLKEYR=app1key
# check:
echo MQCCDTURL=$MQCCDTURL
ls -l $MQCCDTURL
echo MQSSLKEYR=$MQSSLKEYR
ls -l $MQSSLKEYR.*

# Put messages to the queue

echo "Test message 1" | amqsputc Q1 QM2
echo "Test message 2" | amqsputc Q1 QM2


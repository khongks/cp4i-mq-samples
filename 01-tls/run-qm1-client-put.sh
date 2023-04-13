#!/bin/bash
#
#  (C) Copyright IBM Corp. 2021. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Not for Production use. For demo and training only.
#

. ./env.vars

# Find the queue manager host name

qmhostname=`oc get route -n ${NAMESPACE} ${NAME}-ibm-mq-qm -o jsonpath="{.spec.host}"`
echo $qmhostname


# Test:

ping -c 3 $qmhostname

# Create ccdt.json

cat > ccdt.json << EOF
{
    "channel":
    [
        {
            "name": "${QMGR_NAME}CHL",
            "clientConnection":
            {
                "connection":
                [
                    {
                        "host": "$qmhostname",
                        "port": 443
                    }
                ],
                "queueManager": "${QMGR_NAME}"
            },
            "transmissionSecurity":
            {
              "cipherSpecification": "TLS_RSA_WITH_AES_256_CBC_SHA256",
              "certificateLabel": "example"
            },
            "type": "clientConnection"
        }
   ]
}
EOF

# Set environment variables for the client
# export MQCCDTURL=file:///Users/kskhong/Documents/Dev/mq/cp4i-mq-samples/01-tls/ccdt.json
export MQCHLLIB=/Users/kskhong/Documents/Dev/mq/cp4i-mq-samples/01-tls
export MQCHLTAB=ccdt.json
export MQSSLKEYR=app1key
# check:
echo MQCCDTURL=$MQCCDTURL
echo MQSSLKEYR=$MQSSLKEYR
ls -l $MQSSLKEYR.*

# Put messages to the queue

echo "Test message 1" | amqsputc APPQ QM1
echo "Test message 2" | amqsputc APPQ QM1

#!/bin/bash
#
#  (C) Copyright IBM Corp. 2021. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Not for Production use. For demo and training only.
#

# Find the queue manager host name

. ./env.vars

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

# export MQCCDTURL=ccdt.json
export MQCCDTURL=file:///Users/kskhong/Documents/Dev/mq/cp4i-mq-samples/01-tls/ccdt.json
export MQSSLKEYR=app1key
# check:
echo MQCCDTURL=$MQCCDTURL
ls -l $MQCCDTURL
echo MQSSLKEYR=$MQSSLKEYR
ls -l $MQSSLKEYR.*

# Get messages from the queue

amqsbcgc APPQ QM1

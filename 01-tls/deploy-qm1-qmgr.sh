#!/bin/bash
#
#  (C) Copyright IBM Corp. 2021. All Rights Reserved.
#
# SPDX-License-Identifier: Apache-2.0
#
# Not for Production use. For demo and training only.
#

. ./env.vars

# Create a private key and a self-signed certificate for the queue manager

openssl req -newkey rsa:2048 -nodes -keyout ${NAME}.key -subj "/CN=${QMGR_NAME}" -x509 -days 3650 -out ${NAME}.crt

# Create the client key database:

runmqakm -keydb -create -db app1key.kdb -pw password -type cms -stash

# Add the queue manager public key to the client key database:

runmqakm -cert -add -db app1key.kdb -label ${NAME}cert -file ${NAME}.crt -format ascii -stashed

# Check. List the database certificates:

runmqakm -cert -list -db app1key.kdb -stashed

# Create TLS Secret for the Queue Manager

oc create secret tls example-01-${NAME}-secret -n ${NAMESPACE} --key="${NAME}.key" --cert="${NAME}.crt"

# Create a config map containing MQSC commands

cat > "${NAME}-configmap.yaml" << EOF
apiVersion: v1
kind: ConfigMap
metadata:
  name: example-01-${NAME}-configmap
data:
  ${NAME}.mqsc: |
    DEFINE QLOCAL('Q1') REPLACE DEFPSIST(YES) 
    DEFINE CHANNEL(${QMGR_NAME}CHL) CHLTYPE(SVRCONN) REPLACE TRPTYPE(TCP) SSLCAUTH(OPTIONAL) SSLCIPH('ANY_TLS12_OR_HIGHER')
    SET CHLAUTH(${QMGR_NAME}CHL) TYPE(BLOCKUSER) USERLIST('nobody') ACTION(ADD)
EOF

oc apply -n ${NAMESPACE} -f ${NAME}-configmap.yaml

# Create the required route for SNI

cat > "${NAME}chl-route.yaml" << EOF
apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: example-01-${NAME}-route
spec:
  host: ${NAME}chl.chl.mq.ibm.com
  to:
    kind: Service
    name: ${NAME}-ibm-mq
  port:
    targetPort: 1414
  tls:
    termination: passthrough
EOF

oc apply -n ${NAMESPACE} -f ${NAME}chl-route.yaml

# Deploy the queue manager

cat > "${NAME}-qmgr.yaml" << EOF
apiVersion: mq.ibm.com/v1beta1
kind: QueueManager
metadata:
  name: ${NAME}
spec:
  license:
    accept: true
    license: ${LICENSE}
    use: NonProduction
  queueManager:
    name: ${QMGR_NAME}
    mqsc:
    - configMap:
        name: example-01-${NAME}-configmap
        items:
        - ${NAME}.mqsc
    storage:
      queueManager:
        type: ephemeral
  template:
    pod:
      containers:
        - env:
            - name: MQSNOAUT
              value: 'yes'
          name: qmgr
  version: ${VERSION}
  web:
    enabled: true
  pki:
    keys:
      - name: example
        secret:
          secretName: example-01-${NAME}-secret
          items: 
          - tls.key
          - tls.crt
EOF

oc apply -n ${NAMESPACE} -f ${NAME}-qmgr.yaml

# wait 5 minutes for queue manager to be up and running
# (shouldn't take more than 2 minutes, but just in case)
for i in {1..60}
do
  phase=`oc get qmgr -n ${NAMESPACE} ${NAME} -o jsonpath="{.status.phase}"`
  if [ "$phase" == "Running" ] ; then break; fi
  echo "Waiting for ${NAME}...$i"
  oc get qmgr -n ${NAMESPACE} ${NAME}
  sleep 5
done

if [ $phase == Running ]
   then echo Queue Manager ${NAME} is ready; 
   exit; 
fi

echo "*** Queue Manager ${NAME} is not ready ***"
exit 1

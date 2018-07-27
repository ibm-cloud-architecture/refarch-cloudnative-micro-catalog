#!/bin/bash
function print_elasticsearch_certificate_error() {
    echo "Could not find elasticsearch certificate info"
}

function add_certificate_to_keystore() {
    echo "Updating Java keystore"
    JAVA_CERTS_PATH=$JAVA_HOME/lib/security/cacerts
    ls -la $JAVA_CERTS_PATH

    keytool -import -noprompt -trustcacerts -alias bluecompute \
    	-file ${CERT_PATH} \
    	-keystore $JAVA_CERTS_PATH -storepass changeit

    keytool -list -keystore $JAVA_CERTS_PATH -storepass changeit | grep bluecompute
}

function add_elasticsearch_certificate() {
	CERT_PATH="/etc/ssl/certs/bluecompute-ca-certificate.crt"

	if [ -n "$ES_CA_CERTIFICATE" ]; then
		echo "Getting certificate from ES_CA_CERTIFICATE"
        echo $ES_CA_CERTIFICATE >> ${CERT_PATH}
        add_certificate_to_keystore

	elif [ -n "$ES_CA_CERTIFICATE_BASE64" ]; then
		echo "Getting certificate from ES_CA_CERTIFICATE_BASE64"
        echo $ES_CA_CERTIFICATE_BASE64 | base64 -d >> ${CERT_PATH}
        add_certificate_to_keystore

	elif [ -n "$elastic" ]; then
	    cert=$(echo $elastic | jq .ca_certificate_base64 -r);

	    if [ -n "$cert" ]; then
			echo "Parsing Elasticsearch Certificate from Kubernetes";
	        echo $elastic | jq .ca_certificate_base64 -r | base64 -d >> ${CERT_PATH}

	        add_certificate_to_keystore

	    else
	        print_elasticsearch_certificate_error
	    fi
    else
	    print_elasticsearch_certificate_error
	fi
}
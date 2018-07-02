#!/bin/bash
source scripts/max_heap.sh
source scripts/parse_elasticsearch.sh
source scripts/add_elasticsearch_certificate.sh

# Set Max Heap
export JAVA_OPTS="${JAVA_OPTS} -Xmx${max_heap}m"

# Set basic java options
export JAVA_OPTS="${JAVA_OPTS} -Djava.security.egd=file:/dev/./urandom"

# Parse Elasticsearch info and put it into JAVA_OPTS
parse_elasticsearch

# Parse Elasticsearch certificate and add to Java keystore
add_elasticsearch_certificate

# disable eureka
JAVA_OPTS="${JAVA_OPTS} -Deureka.client.enabled=false -Deureka.client.registerWithEureka=false -Deureka.fetchRegistry=false"

echo "Starting Java application"

# Start the application
exec java ${JAVA_OPTS} -jar /app.jar
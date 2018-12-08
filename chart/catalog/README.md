# refarch-cloudnative-micro-catalog: Spring Boot Microservice with Elasticsearch Database

## Introduction
This chart will deploy a Spring Boot Application with a Elasticsearch database onto a Kubernetes Cluster. It will also deploy the Inventory Application along with its MySQL database.

![Application Architecture](https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-micro-catalog/spring/static/catalog.png?raw=true)

Here is an overview of the chart's features:
- Leverage [`Spring Boot`](https://projects.spring.io/spring-boot/) framework to build a Microservices application.
- Uses [`Spring Data JPA`](https://www.elastic.co/products/elasticsearch) to persist data to MySQL database.
- Uses [`Elasticsearch`](https://www.elastic.co/products/elasticsearch) to persist Catalog data to Elasticsearch database.
- Uses [`MySQL`](https://www.mysql.com/) as the Inventory database.
- Uses [`Docker`](https://docs.docker.com/) to package application binary and its dependencies.
- Uses [`Helm`](https://helm.sh/) to package application along with dependencies (Elasticsearch, Inventory, and MySQL) and deploy to a [`Kubernetes`](https://kubernetes.io/) cluster.

## Chart Source
The source for the `Catalog` chart can be found at:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-catalog/tree/spring/chart/catalog

The source for the `Elasticsearch` chart can be found at:
* https://github.com/helm/charts/tree/master/incubator/elasticsearch

The source for the `Inventory` chart can be found at:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/tree/spring/chart/inventory

The source for the `MySQL` chart can be found at:
* https://github.com/helm/charts/tree/master/stable/mysql

Lastly, the source for the `alexeiled/curl` Docker Image can be found at:
* https://github.com/alexei-led/curl

## APIs
* Get all items in catalog:
    + `http://localhost:8081/micro/items`
* Get item from catalog using id:
    + `http://localhost:8081/micro/items/${itemId}`

## Deploy Catalog Application to Kubernetes Cluster from CLI
To deploy the Catalog Chart and its Elasticsearch dependency Chart to a Kubernetes cluster using Helm CLI, follow the instructions below:
```bash
# Add helm repos for Inventory and Elasticsearch Chart
helm repo add ibmcase-charts https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/spring/docs/charts

# Install Elasticsearch Chart
helm upgrade --install elasticsearch \
  --version 1.13.2 \
  --set fullnameOverride=catalog-elasticsearch \
  --set cluster.env.MINIMUM_MASTER_NODES="2" \
  --set client.replicas=1 \
  --set master.replicas=2 \
  --set master.persistence.enabled=false \
  --set data.replicas=1 \
  --set data.persistence.enabled=false \
  stable/elasticsearch

# Install MySQL Chart
helm upgrade --install mysql \
  --version 0.10.2 \
  --set fullnameOverride=inventory-mysql \
  --set mysqlRootPassword=admin123 \
  --set mysqlUser=dbuser \
  --set mysqlPassword=password \
  --set mysqlDatabase=inventorydb \
  --set persistence.enabled=false \
  stable/mysql

# Install Inventory Chart
helm upgrade --install inventory --set mysql.existingSecret=inventory-mysql ibmcase-charts/inventory

# Clone catalog repository:
git clone -b spring --single-branch https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-catalog.git

# Go to Chart Directory
cd refarch-cloudnative-micro-catalog/chart/catalog

# Deploy Catalog to Kubernetes cluster
helm upgrade --install catalog \
  --set service.type=NodePort \
  --set elasticsearch.host=catalog-elasticsearch-client \
  --set inventory.url=http://inventory-inventory:8080 \
  .
```
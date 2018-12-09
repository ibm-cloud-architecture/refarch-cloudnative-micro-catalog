# refarch-cloudnative-micro-catalog: Spring Boot Microservice with Elasticsearch Database
[![Build Status](https://travis-ci.org/ibm-cloud-architecture/refarch-cloudnative-micro-catalog.svg?branch=master)](https://travis-ci.org/ibm-cloud-architecture/refarch-cloudnative-micro-catalog)

*This project is part of the 'IBM Cloud Native Reference Architecture' suite, available at
https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/spring*

## Table of Contents
* [Introduction](#introduction)
    + [APIs](#apis)
* [Pre-requisites:](#pre-requisites)
* [Deploy Catalog Application to Kubernetes Cluster](#deploy-catalog-application-to-kubernetes-cluster)
* [Deploy Catalog Application on Docker](#deploy-catalog-application-on-docker)
    + [Deploy the MySQL Docker Container](#deploy-the-mysql-docker-container)
    + [Populate the MySQL Database](#populate-the-mysql-database)
    + [Deploy the Inventory Docker Container](#deploy-the-inventory-docker-container)
    + [Deploy the Elasticsearch Docker Container](#deploy-the-elasticsearch-docker-container)
    + [Deploy the Catalog Docker Container](#deploy-the-catalog-docker-container)
* [Run Catalog Service application on localhost](#run-catalog-service-application-on-localhost)
* [Deploy Catalog Application on Open Liberty](#deploy-catalog-application-on-openliberty)
* [Optional: Setup CI/CD Pipeline](#optional-setup-cicd-pipeline)
* [Conclusion](#conclusion)
* [Contributing](#contributing)
    + [GOTCHAs](#gotchas)
    + [Contributing a New Chart Package to Microservices Reference Architecture Helm Repository](#contributing-a-new-chart-package-to-microservices-reference-architecture-helm-repository)

## Introduction
This project will demonstrate how to deploy a Spring Boot Application with an Elasticsearch database onto a Kubernetes Cluster. At the same time, it will also demonstrate how to deploy a dependency Microservice Chart (Inventory) and its MySQL datastore.

![Application Architecture](static/catalog.png?raw=true)

Here is an overview of the project's features:
- Leverage [`Spring Boot`](https://projects.spring.io/spring-boot/) framework to build a Microservices application.
- Uses [`Spring Data JPA`](https://www.elastic.co/products/elasticsearch) to persist data to MySQL database.
- Uses [`Elasticsearch`](https://www.elastic.co/products/elasticsearch) to persist Catalog data to Elasticsearch database.
- Uses [`MySQL`](https://www.mysql.com/) as the Inventory database.
- Uses [`Docker`](https://docs.docker.com/) to package application binary and its dependencies.
- Uses [`Helm`](https://helm.sh/) to package application along with dependencies (Elasticsearch, Inventory, and MySQL) and deploy to a [`Kubernetes`](https://kubernetes.io/) cluster.

### APIs
* Get all items in catalog:
    + `http://localhost:8081/micro/items`
* Get item from catalog using id:
    + `http://localhost:8081/micro/items/${itemId}`

## Pre-requisites:
* Create a Kubernetes Cluster by following the steps [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes#create-a-kubernetes-cluster).
* Install the following CLI's on your laptop/workstation:
    + [`docker`](https://docs.docker.com/install/)
    + [`kubectl`](https://kubernetes.io/docs/tasks/tools/install-kubectl/)
    + [`helm`](https://docs.helm.sh/using_helm/#installing-helm)
* Clone catalog repository:
```bash
git clone -b spring --single-branch https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-catalog.git
cd refarch-cloudnative-micro-catalog
```

## Deploy Catalog Application to Kubernetes Cluster
In this section, we are going to deploy the Catalog Application, along with a MySQL service, to a Kubernetes cluster using Helm. To do so, follow the instructions below:
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

# Go to Chart Directory
cd chart/catalog

# Deploy Catalog to Kubernetes cluster
helm upgrade --install catalog \
  --set service.type=NodePort \
  --set elasticsearch.host=catalog-elasticsearch-client \
  --set inventory.url=http://inventory-inventory:8080 \
  .
```

The last command will give you instructions on how to access/test the Catalog application. Please note that before the Catalog application starts, the Elasticsearch deployment must be fully up and running, which normally takes a couple of minutes. On top of that, the Inventory dependency chart and its MySQL datastore must both be fully up and running before Catalog can start. With Kubernetes [Init Containers](https://kubernetes.io/docs/concepts/workloads/pods/init-containers/), the Catalog Deployment polls for Elasticsearch, Inventory App, and MySQL readiness status so that Catalog can start once they are all ready, or error out if any of them fails to start.

To check and wait for the deployment status, you can run the following command:
```bash
kubectl get deployments -w
NAME                  DESIRED   CURRENT   UP-TO-DATE   AVAILABLE   AGE
catalog-catalog   1         1         1            1           10h
```

The `-w` flag is so that the command above not only retrieves the deployment but also listens for changes. If you a 1 under the `CURRENT` column, that means that the catalog app deployment is ready.

## Deploy Catalog Application on Docker
You can also run the Catalog Application locally on Docker. Before we show you how to do so, you will need to have a running MySQL deployment running somewhere.

### Deploy the MySQL Docker Container
The easiest way to get MySQL running is via a Docker container. To do so, run the following commands:
```bash
# Start a MySQL Container with a database user, a password, and create a new database
docker run --name inventorymysql \
    -e MYSQL_ROOT_PASSWORD=admin123 \
    -e MYSQL_USER=dbuser \
    -e MYSQL_PASSWORD=password \
    -e MYSQL_DATABASE=inventorydb \
    -p 3306:3306 \
    -d mysql:5.7.14

# Get the MySQL Container's IP Address
docker inspect inventorymysql | grep "IPAddress"
            "SecondaryIPAddresses": null,
            "IPAddress": "172.17.0.2",
                    "IPAddress": "172.17.0.2",
```
Make sure to select the IP Address in the `IPAddress` field. You will use this IP address when deploying the Inventory container.

### Populate the MySQL Database
In order for Inventory to make use of the MySQL database, the database needs to be populated first. To do so, run the following commands:
```bash
# Download MySQL static data script
wget https://raw.githubusercontent.com/ibm-cloud-architecture/refarch-cloudnative-micro-inventory/master/scripts/mysql_data.sql
# Populate MySQL
until mysql -h 127.0.0.1 -P 3306 -udbuser -ppassword <mysql_data.sql; do echo "waiting for mysql"; sleep 1; done; echo "Loaded data into database"
```

Note that we didn't use the IP address we obtained from the MySQL since it is only accessible to other Docker Containers. We used `127.0.0.1` localhost IP address instead since we mapped the 3306 port on the docker container to the 3306 port in localhost.

### Deploy the Inventory Docker Container
To deploy the Inventory container, run the following commands:
```bash
# Start the Inventory Container
docker run --name inventory \
    -e MYSQL_HOST=${MYSQL_IP_ADDRESS} \
    -e MYSQL_PORT=3306 \
    -e MYSQL_USER=dbuser \
    -e MYSQL_PASSWORD=password \
    -e MYSQL_DATABASE=inventorydb \
    -p 8080:8080 \
    -d ibmcase/bluecompute-inventory:0.5.0
```

Where `${MYSQL_IP_ADDRESS}` is the IP address of the MySQL container, which is only accessible from the Docker container network.

If everything works successfully, you should be able to get some data when you run the following command:
```bash
curl http://localhost:8080/micro/inventory
```

Now, get the Inventory Container's IP Address:
```bash
# Get the Inventory Container's IP Address
docker inspect inventory | grep "IPAddress"
            "SecondaryIPAddresses": null,
            "IPAddress": "172.17.0.3",
                    "IPAddress": "172.17.0.3",
```
Make sure to select the IP Address in the `IPAddress` field. You will use this IP address when deploying the Catalog container.

### Deploy the Elasticsearch Docker Container
The easiest way to get Elasticsearch running is via a Docker container. To do so, run the following commands:
```bash
# Start a Elasticsearch Container with a database user, a password, and create a new database
docker run --name catalogelasticsearch \
    -e "discovery.type=single-node" \
    -p 9200:9200 \
    -p 9300:9300 \
    -d docker.elastic.co/elasticsearch/elasticsearch:6.3.2

# Get the Elasticsearch Container's IP Address
docker inspect catalogelasticsearch | grep "IPAddress"
            "SecondaryIPAddresses": null,
            "IPAddress": "172.17.0.4",
                    "IPAddress": "172.17.0.4",
```
Make sure to select the IP Address in the `IPAddress` field. You will use this IP address when deploying the Catalog container.

### Deploy the Catalog Docker Container
To deploy the Catalog container, run the following commands:
```bash
# Build the Docker Image
docker build -t catalog .

# Start the Catalog Container
docker run --name catalog \
    -e ES_URL="http://${ES_IP_ADDRESS}:9200" \
    -e ES_USER=elastic \
    -e ES_PASSWORD=changeme \
    -e INVENTORY_URL=http://${INVENTORY_IP_ADDRESS}:8080 \
    -p 8081:8081 \
    -d catalog
```

Where:
* `${ES_IP_ADDRESS}` is the IP address of the Elasticsearch container.
* `${INVENTORY_IP_ADDRESS}` is the IP address of the Inventory container.

If everything works successfully, you should be able to get some data when you run the following command:
```bash
curl http://localhost:8081/micro/items
```

## Run Catalog Service application on localhost
In this section you will run the Spring Boot application on your local workstation. Before we show you how to do so, you will need to do the following:
* Deploy  a MySQL Docker container and populate it with data as shown in the [Deploy a MySQL Docker Container](#deploy-the-mysql-docker-container) and [Populate the MySQL Database](#populate-the-mysql-database) sections, respectively
* Deploy the Inventory Docker Container as shown in [Deploy the Inventory Docker Container](#deploy-the-inventory-docker-container).
* Deploy the Elasticsearch Docker Container as shown in [](#deploy-the-elasticsearch-docker-container)

Once all the above is done, we can run the Spring Boot Catalog application locally as follows:

1. Open [`src/main/resources/application.yml`](src/main/resources/application.yml) file, enter the following values for the fields below, and save the file:
    * **elasticsearch:**
        + **url:** http://127.0.0.1:9200
        + **user:** elastic
        + **password:** changeme
        + **index:** micro
        + **doc_type:** items
    * **inventoryService:**
      + **url:** http://127.0.0.1:8080

2. Build the application:
```bash
./gradlew build -x test
```

3. Run the application on localhost:
```bash
java -jar build/libs/micro-catalog-0.0.1.jar
```

4. Validate. You should get a list of all catalog items:
```bash
curl http://localhost:8081/micro/items
```

That's it, you have successfully deployed and tested the Catalog microservice.

## Deploy Catalog Application on OpenLiberty

The Spring Boot applications can be deployed on WebSphere Liberty as well. In this case, the embedded server i.e. the application server packaged up in the JAR file will be Liberty. For instructions on how to deploy the Catalog application optimized for Docker on Open Liberty, which is the open source foundation for WebSphere Liberty, follow the instructions [here](OpenLiberty.MD)

## Optional: Setup CI/CD Pipeline
If you would like to setup an automated Jenkins CI/CD Pipeline for this repository, we provided a sample [Jenkinsfile](Jenkinsfile), which uses the [Jenkins Pipeline](https://jenkins.io/doc/book/pipeline/) syntax of the [Jenkins Kubernetes Plugin](https://github.com/jenkinsci/kubernetes-plugin) to automatically create and run Jenkis Pipelines from your Kubernetes environment.

To learn how to use this sample pipeline, follow the guide below and enter the corresponding values for your environment and for this repository:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-devops-kubernetes

## Conclusion
You have successfully deployed and tested the Catalog and Inventory Microservices with their respective Elasticsearch and MySQL databases both on a Kubernetes Cluster and in local Docker Containers.

To see the Catalog app working in a more complex microservices use case, checkout our Microservice Reference Architecture Application [here](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/spring).

## Contributing
If you would like to contribute to this repository, please fork it, submit a PR, and assign as reviewers any of the GitHub users listed here:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-micro-catalog/graphs/contributors

### GOTCHAs
1. We use [Travis CI](https://travis-ci.org/) for our CI/CD needs, so when you open a Pull Request you will trigger a build in Travis CI, which needs to pass before we consider merging the PR. We use Travis CI to test the following:
    * Create and load a MySQL database with the catalog static data.
    * Running the Inventory app against the MySQL database and run API tests.
    * Running an Elasticsearch database.
    * Building and running the Catalog app against the Elasticsearch database and Inventory service and run API tests.
    * Build and Deploy a Docker Container, using the same Elasticsearch database and Inventory service.
    * Run API tests against the Docker Container.
    * Deploy a minikube cluster to test Helm charts.
    * Download Helm Chart dependencies and package the Helm chart.
    * Deploy the Helm Chart into Minikube.
    * Run API tests against the Helm Chart.

2. We use the Community Chart for MySQL as the dependency chart for the Catalog Chart. If you would like to learn more about that chart and submit issues/PRs, please check out its repo here:
    * https://github.com/helm/charts/tree/master/stable/mysql

### Contributing a New Chart Package to Microservices Reference Architecture Helm Repository
To contribute a new chart version to the [Microservices Reference Architecture](https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/spring) helm repository, follow its guide here:
* https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes/tree/spring#contributing-a-new-chart-to-the-helm-repositories

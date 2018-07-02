# refarch-cloudnative-micro-catalog [INCOMPLETE]
This project is part of the 'IBM Cloud Native Reference Architecture for Kubernetes' suite
entory

## Spring Boot Netflix OSS Microservice App Integration with ElasticSearch and MySQL Database Server

*This project is part of the 'IBM Cloud Native Reference Architecture' suite, available at
https://github.com/ibm-cloud-architecture/refarch-cloudnative-kubernetes*

## Table of Contents
- **[Introduction](#introduction)**
    - [APIs](#apis)
- **[Pre-requisites](#pre-requisites)**
    - [CLIs](#clis)
    - [Elasticsearch](#elasticsearch)
- **[Run Inventory and Catalog Locally](#run-inventory-and-catalog-locally)**
    - [Run Inventory Service application on localhost](#run-inventory-service-application-on-localhost)
    - [Run Catalog Service application on localhost](#run-catalog-service-application-on-localhost)
- **[Deploy Inventory and Catalog to Kubernetes Cluster](#deploy-inventory-and-catalog-to-kubernetes-cluster)**
    - [Deploy Inventory Service application to Kubernetes Cluster](#deploy-inventory-service-application-to-kubernetes-cluster)
    - [Deploy Catalog Service application to Kubernetes Cluster](#deploy-catalog-service-application-to-kubernetes-cluster)

## Introduction
This project is built to demonstrate how to build an Elasticsearch cache microservice application using Spring Boot and Docker and how to deploy it to a Kubernetes cluster using Helm. The Spring Boot application will use `Elasticsearch` as its datasource.

Here is an overview of the project's features:
- Leverage [`Spring Boot`](https://projects.spring.io/spring-boot/) framework to build a Microservices application.
- Use [`Spring Data JPA`](http://projects.spring.io/spring-data-jpa/) to persist data to Elasticsearch.
- [`Elasticsearch`](https://github.com/elastic/elasticsearch) is used as the `Catalog` microservice's data source.
- Deployment option for [`IBM Cloud Kubernetes Service`](https://www.ibm.com/cloud/container-service).
- Deployment option for [`IBM Cloud Cloud Private`](https://www.ibm.com/cloud/private).

**Architecture Diagram**

![Inventory/Catalog Diagram](inventory-catalog.png)

### APIs
You can use cURL or Chrome POSTMAN to send get/post/put/delete requests to the application.
- Get all items in catalog:
    `http://<catalog_hostname>/micro/items`

- Get item by id:
    `http://<catalog_hostname>/micro/items/{id}`

- Example curl command to get al items in localhost:
    `curl -X GET "http://localhost:8081/micro/items"`

## Pre-requisites:
Clone git repository before getting started.

    ```
    # git clone http://github.com/refarch-cloudnative-micro-catalog.git
    # cd refarch-cloudnative-micro-catalog
    ```

### CLIs
To install the CLIs for Bluemix, Kubernetes, Helm, JQ, and YAML,  Run the following script to install the CLIs:

    `$ ./install_cli.sh`

### Elasticsearch
1. [Provision](https://console.ng.bluemix.net/catalog/services/compose-for-elasticsearch) and instance of Elasticsearch into your Bluemix space.
    - Select name for your instance.
    - Click the `Create` button.
2. Refresh the page until you see `Status: Ready`.
3. Now obtain `Elasticsearch` service credentials.
    - Click on `Service Credentials` tab.
    - Then click on the `View Credentials` dropdown next to the credentials.
4. See the `uri` field, which has the format `https://user:password@host:port/`, and extract the following:
    - **user:** Elasticsearch user.
    - **password:** Elasticsearch password.
    - **host**: Elasticsearch host.
    - **port:** Elasticsearch port.
5. Keep those credential handy for when deploying the Inventory and Catalog services in the following sections.

Elasticsearch database is now setup in Compose.

## Run Catalog Service application on localhost
In this section you will run the Catalog Spring Boot application to run on your localhost.
1. **If not already done, [Provision an `Elasticsearch` database on Compose](#elasticsearch)**. Then replace the values for the fields in the `elasticsearch` section with those obtained in the [Elasticsearch Section](#elasticsearch):
- In the `url` field, type `https://host:port`, and enter the values for `host` and `port`.
- Enter values for `user` and `password`

2. **Build the application**.
```bash
# ./gradlew build -x test
```

3. **Run the application on localhost**.
```bash
# java -jar build/libs/micro-catalog-0.0.1.jar
```

4. **Validate. You should get a list of all catalog items**.
```bash
# curl http://localhost:8081/micro/items
```

## Deploy Catalog Applications to Kubernetes Cluster
In this section you will deploy the Inventory and Catalog applications to run on your Bluemix Kubernetes Cluster. 
We packaged the entire application stack as a Kubernetes [Chart](https://github.com/kubernetes/charts). To deploy the Inventory and Catalog Charts, please follow the instructions in the following sections.

#### Deploy Inventory to Paid Cluster

##### Manual Way
If you like to run the steps manually, please follow the steps below:

1. ***Get paid cluster name*** by running the command below & then copy it to your clipboard:
```bash
$ bx cs clusters
```

2. ***Set your terminal context to your cluster***:
```bash
$ bx cs cluster-config <cluster-name>
```

In the output to the command above, the path to your configuration file is displayed as a command to set an environment variable, for example:
```bash
...
export KUBECONFIG=/Users/ibm/.bluemix/plugins/cs-cli/clusters/pr_firm_cluster/kube-config-dal10-pr_firm_cluster.yml
```

3. ***Set the `KUBECONFIG` Kubernetes configuration file*** using the ouput obtained with the above command:
```bash
$ export KUBECONFIG=/Users/ibm/.bluemix/plugins/cs-cli/clusters/pr_firm_cluster/kube-config-dal10-pr_firm_cluster.yml
```

4. ***Initialize Helm***, which will be used to install Bluecompute Chart:
```bash
$ helm init --upgrade
```

Helm will install `Tiller` agent (Helm's server side) into your cluster, which enables you to install Charts on your cluster. The `--upgrade` flag is to make sure that both Helm client and Tiller are using the same Helm version.

5. ***Make sure that Tiller agent is fully Running*** before installing chart.
```bash
$ kubectl --namespace=kube-system get pods | grep tiller
```

To know whether Tiller is Running, you should see an output similar to this:
```bash
tiller-deploy-3210876050-l61b3              1/1       Running   0          1d
```

6. If you don't have a ***BLUEMIX API Key***, create one as follows:
```bash
$ bx iam api-key-create bluekey
```

7. ***Install bluecompute-inventory Chart***. The process usually takes between 3-5 minutes to finish and start showing debugging output:
```bash
$ time helm install \
  --set configMap.bluemixOrg=${ORG} \
  --set configMap.bluemixSpace=${SPACE} \
  --set configMap.kubeClusterName=${CLUSTER_NAME} \
  --set secret.apiKey=${API_KEY} \
  . --debug
```

* Replace ${ORG} with your Bluemix Organization name.
* Replace ${SPACE} with your Bluemix Space.
* Replace ${CLUSTER_NAME} with your Kubernetes Cluster name from Step 1.
* Replace ${API_KEY} with the Bluemix API Key from Step 6.

That's it! **Inventory is now installed** in your Kubernetes Cluster. To see the Kubernetes dashboard, run the following command:
```bash
$ kubectl proxy
```

Then open a browser and paste the following URL to see the **Services** created by Inventory Chart:

http://127.0.0.1:8001/api/v1/proxy/namespaces/kube-system/services/kubernetes-dashboard/#/service?namespace=default
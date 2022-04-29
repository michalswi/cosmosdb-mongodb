## Azure Cosmos DB API for MongoDB

Azure docs [here](https://docs.microsoft.com/en-us/azure/cosmos-db/mongodb/mongodb-introduction) .  
Terraform related docs [here](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/cosmosdb_account) .  

Deployed CosmosDB for MongoDB base on [pricing]() including:
- free tier
- serverless
- periodic backup policy 
- Local Redundant Storage (LRS)

### \# **terraform**

By default network access from the VNet defined in tf file and from Your public IP.  
To fetch your IP you can deploy your own service check [here](https://michalswi.medium.com/simple-app-to-fetch-ip-address-be8907eca1c6) .
```
az login

NAME=demo \
LOCATION=westeurope \
PUB_IP=<>

terraform init
terraform plan -var name=$NAME -var location=$LOCATION -var public_ip=$PUB_IP -out=out.plan
terraform apply out.plan
```

### \# **connection**

Connection string you can find here:  
`Azure portal / <Azure Cosmos DB API for MongoDB> / Connection string`

#### \> **mongosh**
```
$ mongosh "<connection-string>"
(...)
globaldb [primary] test> db
test
globaldb [primary] test> use demodb
switched to db demodb
globaldb [primary] demodb> db
demodb
globaldb [primary] demodb> db.movie.insert({"name":"movie1"})
globaldb [primary] demodb> db.movie.insert({"_id":1,"name":"movie0"})
globaldb [primary] demodb> db.movie.find().pretty()
[
  { _id: ObjectId("626b9c74948e76f690236f2d"), name: 'movie1' },
  { _id: 1, name: 'movie0' }
]
```

#### \> **go-client**
```
$ export MONGODB_CONNECTION_STRING="<connection-string>"
$ go build
$ ./cosmosdb-mongodb list
mongodb-client 2022/04/28 20:31:03 client.go:45: Connecting...
mongodb-client 2022/04/28 20:31:05 client.go:58: Successfully created connection to database.
List databases:
[demodb]
```

#### \> **Data Explorer**

To enable **Data Explorer** functionality you have to enable access first:  
`Azure portal / <Azure Cosmos DB API for MongoDB> / Firewall and virtual networks / tick - Allow access from Azure Portal`

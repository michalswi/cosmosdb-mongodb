package main

import (
	"context"
	"fmt"
	"log"
	"os"
	"time"

	"go.mongodb.org/mongo-driver/bson"
	"go.mongodb.org/mongo-driver/mongo"
	"go.mongodb.org/mongo-driver/mongo/options"
)

// base on: https://www.mongodb.com/languages/golang

var logger = log.New(os.Stdout, "mongodb-client ", log.LstdFlags|log.Lshortfile|log.Ltime|log.LUTC)

func main() {

	mongoDBConnectionString := os.Getenv("MONGODB_CONNECTION_STRING")
	if mongoDBConnectionString == "" {
		fmt.Println("Missing connection string. Get one from: Azure portal / <Azure Cosmos DB API for MongoDB> / Connection string")
		os.Exit(1)
	}

	if len(os.Args) < 2 {
		fmt.Println("Missing args. Available: 'list' database.")
		os.Exit(1)
	}

	c := connect(mongoDBConnectionString)

	switch os.Args[1] {
	case "list":
		list(c)
	}
}

func connect(mongoDBuri string) *mongo.Client {
	client, err := mongo.NewClient(options.Client().ApplyURI(mongoDBuri))
	if err != nil {
		logger.Fatal(err)
	}
	logger.Printf("Connecting...")
	ctx, cancel := context.WithTimeout(context.Background(), 10*time.Second)
	defer cancel()

	err = client.Connect(ctx)
	if err != nil {
		logger.Fatalf("Unable to initialize connection: %v", err)
	}

	err = client.Ping(ctx, nil)
	if err != nil {
		logger.Fatalf("Unable to connect: %v", err)
	}
	logger.Printf("Successfully created connection to database.")

	return client
}

func list(client *mongo.Client) {
	ctx, _ := context.WithTimeout(context.Background(), 10*time.Second)
	defer client.Disconnect(ctx)
	fmt.Println("List databases:")
	databases, err := client.ListDatabaseNames(ctx, bson.M{})
	if err != nil {
		logger.Fatalf("Unable to list databases: %v", err)
	}
	fmt.Println(databases)
}

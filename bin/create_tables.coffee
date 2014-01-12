#!/usr/bin/env coffee

AWS = require("aws-sdk")
util = require("util")
async = require("async")
_ = require("lodash")

argv = require('optimist')
  .usage('Create DynamoDB tables for phork.\nUsage: create_tables.coffee')
  .alias('c', 'aws-credentials')
  .demand('c')
  .describe('c', 'Path to AWS credentials JSON\n    (in form: { "accessKeyId": ACCESS_KEY, "secretAccessKey": SECRET_KEY, "region": REGION })')
  .alias('l', 'local')
  .describe('l', 'Run on local DynamoDB')
  .describe('r', 'DynamoDB read capacity units to initialize tables with.')
  .describe('w', 'DynamoDB write capacity units to initialize tables with.')
  .alias('r', 'read-capacity')
  .alias('w', 'write-capacity')
  .default('r', 1)
  .default('w', 1)
  .argv

AWS.config.loadFromPath(argv.c) if (argv.c)

if argv.l
  dynamodb = new AWS.DynamoDB(endpoint: "http://localhost:8000", sslEnabled: false)
else
  dynamodb = new AWS.DynamoDB()

purgeTable = (db, tableDefinition, cb) ->
  tableName = tableDefinition.TableName

  initTable = (err, initDone) ->
    db.createTable tableDefinition, (err, data) ->
      return cb(err) if err

      tablePending = true

      async.whilst ( -> tablePending ),
        ((done) ->
          db.describeTable TableName: tableName, (err, tableInfo) ->
            tablePending = !tableInfo? || tableInfo.Table.TableStatus != 'ACTIVE'

            if tablePending
              setTimeout(done, 1000)
            else
              done()),
        initDone

  db.listTables (err, data) ->
    if _.contains(data?.TableNames, tableName)
      db.deleteTable TableName: tableName, (err, data) ->
        tableExists = true

        async.whilst (-> tableExists),
          ((done) ->
            db.describeTable TableName: tableName, (err, tableInfo) ->
              tableExists = tableInfo?

              if tableExists
                setTimeout(done, 1000)
              else
                done()),
          ((err) -> initTable(err, cb))
    else
      initTable(null, cb)

util.log "Create phork_roots."

purgeTable dynamodb, {
  TableName: "phork_roots",
  AttributeDefinitions: [
    { AttributeName: "phork_id", AttributeType: "S" },
    { AttributeName: "created_by_user_id", AttributeType: "S" },
    { AttributeName: "primary_content_domain", AttributeType: "S" },
    { AttributeName: "created_at", AttributeType: "N" }
  ],
  KeySchema: [
    { AttributeName: "phork_id", KeyType: "HASH" }
  ],
  ProvisionedThroughput: { ReadCapacityUnits: argv.r, WriteCapacityUnits: argv.w },
  GlobalSecondaryIndexes: [
    {
      IndexName: "created_by_user_id-created_at_index",
      KeySchema: [
        { AttributeName: "created_by_user_id", KeyType: "HASH" },
        { AttributeName: "created_at", KeyType: "RANGE" }
      ],
      Projection:
        ProjectionType: "ALL"
      ProvisionedThroughput: { ReadCapacityUnits: argv.r, WriteCapacityUnits: argv.w },
    },
    {
      IndexName: "primary_content_domain-created_at-index",
      KeySchema: [
        { AttributeName: "primary_content_domain", KeyType: "HASH" },
        { AttributeName: "created_at", KeyType: "RANGE" }
      ],
      Projection:
        ProjectionType: "ALL"
      ProvisionedThroughput: { ReadCapacityUnits: argv.r, WriteCapacityUnits: argv.w },
    },
  ]
}, (err) ->
  if err
    util.log err
  else
    util.log "Create phork_docs."

    purgeTable dynamodb, {
      TableName: "phork_docs",
      AttributeDefinitions: [
        { AttributeName: "phork_id", AttributeType: "S" },
        { AttributeName: "doc_id", AttributeType: "S" }
      ],
      KeySchema: [
        { AttributeName: "phork_id", KeyType: "HASH" },
        { AttributeName: "doc_id", KeyType: "RANGE" }
      ],
      ProvisionedThroughput: { ReadCapacityUnits: argv.r, WriteCapacityUnits: argv.w },
    }, (err) ->
      if err
        util.log err
      else
        util.log "Create users."

        purgeTable dynamodb, {
          TableName: "users",
          AttributeDefinitions: [
            { AttributeName: "user_id", AttributeType: "S" },
            { AttributeName: "account_id", AttributeType: "S" }
          ],
          KeySchema: [
            { AttributeName: "user_id", KeyType: "HASH" }
          ],
          ProvisionedThroughput: { ReadCapacityUnits: argv.r, WriteCapacityUnits: argv.w },
          GlobalSecondaryIndexes: [
            {
              IndexName: "user_id-account_id_index",
              KeySchema: [
                { AttributeName: "account_id", KeyType: "HASH" }
              ],
              Projection:
                ProjectionType: "ALL"
              ProvisionedThroughput: { ReadCapacityUnits: argv.r, WriteCapacityUnits: argv.w },
            },
          ]
        }, (err) ->
          if err
            util.log err
          else
            util.log "Done."

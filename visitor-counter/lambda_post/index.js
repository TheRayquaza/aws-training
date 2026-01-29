const { DynamoDBClient, UpdateItemCommand } = require("@aws-sdk/client-dynamodb");

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const TABLE_NAME = process.env.TABLE_NAME;

exports.handler = async (event) => {
    console.log("Received event:", JSON.stringify(event));

    const params = {
        TableName: TABLE_NAME,
        Key: {
            "Page": { S: "visitor_count" }
        },
        UpdateExpression: "SET visit_count = if_not_exists(visit_count, :start) + :inc",
        ExpressionAttributeValues: {
            ":inc": { N: "1" },
            ":start": { N: "0" }
        },
        ReturnValues: "UPDATED_NEW"
    };

    try {
        const data = await ddbClient.send(new UpdateItemCommand(params));
        const newCount = data.Attributes.visit_count.N;

        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Origin": "*", // Required for CORS
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "OPTIONS,GET"
            },
            body: JSON.stringify({ visit_count: parseInt(newCount) }),
        };
    } catch (error) {
        console.error("Error updating DynamoDB:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: "Failed to update visit count" }),
        };
    }
};

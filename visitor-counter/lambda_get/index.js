const { DynamoDBClient, GetItemCommand } = require("@aws-sdk/client-dynamodb");

const ddbClient = new DynamoDBClient({ region: process.env.AWS_REGION });
const TABLE_NAME = process.env.TABLE_NAME;

exports.handler = async (event) => {
    console.log("Received event:", JSON.stringify(event));

    const params = {
        TableName: TABLE_NAME,
        Key: {
            "Page": { S: "visitor_count" }
        }
    };

    try {
        const data = await ddbClient.send(new GetItemCommand(params));
        const currentCount = data.Item ? parseInt(data.Item.visit_count.N) : 0;

        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Origin": "*",
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "OPTIONS,GET"
            },
            body: JSON.stringify({ visit_count: currentCount }),
        };
    } catch (error) {
        console.error("Error retrieving from DynamoDB:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: "Failed to retrieve visit count" }),
        };
    }
};

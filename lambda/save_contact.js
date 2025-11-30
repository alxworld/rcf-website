const { DynamoDBClient } = require("@aws-sdk/client-dynamodb");
const { DynamoDBDocumentClient, PutCommand } = require("@aws-sdk/lib-dynamodb");
const crypto = require("crypto");

const client = new DynamoDBClient({});
const docClient = DynamoDBDocumentClient.from(client);

const TABLE_NAME = process.env.TABLE_NAME || "RCFContactForm";

exports.handler = async (event) => {
    console.log("Received event:", JSON.stringify(event, null, 2));

    let body;
    try {
        body = JSON.parse(event.body);
    } catch (err) {
        return {
            statusCode: 400,
            body: JSON.stringify({ message: "Invalid JSON body" }),
        };
    }

    const { cName, cEmail, cMessage } = body;

    if (!cName || !cEmail || !cMessage) {
        return {
            statusCode: 400,
            body: JSON.stringify({ message: "Missing required fields: cName, cEmail, cMessage" }),
        };
    }

    const submissionId = crypto.randomUUID();
    const timestamp = new Date().toISOString();

    const params = {
        TableName: TABLE_NAME,
        Item: {
            SubmissionId: submissionId,
            Name: cName,
            Email: cEmail,
            Message: cMessage,
            Timestamp: timestamp,
        },
    };

    try {
        const command = new PutCommand(params);
        await docClient.send(command);

        return {
            statusCode: 200,
            headers: {
                "Content-Type": "application/json",
                "Access-Control-Allow-Origin": "*", // Configure this for your domain in production
            },
            body: JSON.stringify({ message: "Contact details saved successfully", submissionId }),
        };
    } catch (error) {
        console.error("Error saving to DynamoDB:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({ message: "Internal Server Error" }),
        };
    }
};

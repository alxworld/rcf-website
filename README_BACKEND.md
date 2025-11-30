# Contact Form Backend Setup

This guide explains how to set up the AWS backend for the RCF Website Contact Form.

## Prerequisites

- AWS Account
- AWS CLI (optional, but helpful)

## 1. DynamoDB Table

Create a DynamoDB table to store the contact form submissions.

1.  Go to the **DynamoDB** console.
2.  Click **Create table**.
3.  **Table name**: `RCFContactForm`
4.  **Partition key**: `SubmissionId` (String)
5.  Leave other settings as default and click **Create table**.

## 2. Lambda Function

Create the Lambda function that will process the form submissions.

1.  Go to the **Lambda** console.
2.  Click **Create function**.
3.  **Function name**: `RCFSaveContact`
4.  **Runtime**: `Node.js 18.x` (or later)
5.  **Architecture**: `x86_64`
6.  Click **Create function**.

### Code

1.  In the **Code** tab, copy the content of `lambda/save_contact.js` into `index.js` (or rename the file in the console).
2.  **Important**: This code uses AWS SDK v3. Ensure your Lambda runtime supports it (Node.js 18+ does by default).

### Environment Variables

1.  Go to **Configuration** -> **Environment variables**.
2.  Add a variable:
    -   Key: `TABLE_NAME`
    -   Value: `RCFContactForm`

### Permissions

1.  Go to **Configuration** -> **Permissions**.
2.  Click on the **Role name** to open IAM.
3.  Add permissions to write to the DynamoDB table. You can attach the `AmazonDynamoDBFullAccess` policy (for simplicity) or create a custom inline policy:
    ```json
    {
        "Version": "2012-10-17",
        "Statement": [
            {
                "Effect": "Allow",
                "Action": [
                    "dynamodb:PutItem"
                ],
                "Resource": "arn:aws:dynamodb:REGION:ACCOUNT_ID:table/RCFContactForm"
            }
        ]
    }
    ```

## 3. API Gateway

Expose the Lambda function via an HTTP API.

1.  Go to the **API Gateway** console.
2.  Click **Create API** -> **HTTP API** -> **Build**.
3.  **Integrations**: Select **Lambda**.
4.  Select your function `RCFSaveContact`.
5.  **API Name**: `RCFContactAPI`.
6.  Click **Next**.
7.  Configure routes:
    -   Method: `POST`
    -   Resource path: `/contact`
    -   Integration target: `RCFSaveContact`
8.  Click **Next** -> **Next** -> **Create**.

### CORS

1.  In your API settings, go to **CORS**.
2.  **Access-Control-Allow-Origin**: `*` (or your website domain, e.g., `https://rcframapuram.org`)
3.  **Access-Control-Allow-Methods**: `POST`
4.  **Access-Control-Allow-Headers**: `content-type`
5.  Click **Save**.

## 4. Frontend Integration

Update your website's JavaScript to send a POST request to the API Gateway URL.

```javascript
const apiURL = "YOUR_API_GATEWAY_URL/contact";

fetch(apiURL, {
  method: "POST",
  headers: {
    "Content-Type": "application/json",
  },
  body: JSON.stringify({
    cName: "John Doe",
    cEmail: "john@example.com",
    cMessage: "Hello!",
  }),
})
.then(response => response.json())
.then(data => console.log(data));
```

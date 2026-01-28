const { SNSClient, PublishCommand } = require("@aws-sdk/client-sns");
const sns = new SNSClient();

exports.handler = async (event) => {
    console.log("Received event:", JSON.stringify(event));

    // API Gateway Proxy integration sends the body as a string
    const body = JSON.parse(event.body);
    const { name, email, message } = body;

    const params = {
        Subject: `New Contact Form Submission from ${name}`,
        Message: `You received a new message:\n\nName: ${name}\nEmail: ${email}\nMessage: ${message}`,
        TopicArn: process.env.SNS_TOPIC_ARN // We will set this in Terraform
    };

    try {
        await sns.send(new PublishCommand(params));
        return {
            statusCode: 200,
            headers: {
                "Access-Control-Allow-Origin": "*", // Required for CORS
                "Access-Control-Allow-Headers": "Content-Type",
                "Access-Control-Allow-Methods": "OPTIONS,POST"
            },
            body: JSON.stringify({ message: "Email sent successfully!" }),
        };
    } catch (error) {
        console.error("Error sending SNS:", error);
        return {
            statusCode: 500,
            body: JSON.stringify({ error: "Failed to send email" }),
        };
    }
};

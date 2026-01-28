const { S3Client, PutObjectCommand } = require("@aws-sdk/client-s3");
const { RekognitionClient, DetectLabelsCommand } = require("@aws-sdk/client-rekognition");
const s3 = new S3Client();

exports.handler = async (event) => {
    const srcBucket = event.Records[0].s3.bucket.name;
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));

    try {
        // Call AWS Rekognition to label the image
        const rekognition = new RekognitionClient();
        const labels = await rekognition.send(new DetectLabelsCommand({
            Image: {
                S3Object: {
                    Bucket: srcBucket,
                    Name: key
                }
            }
        }));

        console.log("Detected labels:", labels);
    }
    catch (error) {
        console.error("Error:", error);
        throw error;
    }
};

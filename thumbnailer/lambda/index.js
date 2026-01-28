const { S3Client, GetObjectCommand, PutObjectCommand } = require("@aws-sdk/client-s3");
const sharp = require('sharp');
const s3 = new S3Client();

exports.handler = async (event) => {
    const srcBucket = event.Records[0].s3.bucket.name;
    const key = decodeURIComponent(event.Records[0].s3.object.key.replace(/\+/g, " "));
    const dstBucket = process.env.RESIZED_BUCKET;

    try {
        // Get the image from Source Bucket
        const response = await s3.send(new GetObjectCommand({ Bucket: srcBucket, Key: key }));
        const streamToBuffer = (stream) => new Promise((resolve, reject) => {
            const chunks = [];
            stream.on("data", (chunk) => chunks.push(chunk));
            stream.on("error", reject);
            stream.on("end", () => resolve(Buffer.concat(chunks)));
        });
        const buffer = await streamToBuffer(response.Body);

        // Resize
        const resizedImage = await sharp(buffer)
            .resize(200, 200, { fit: 'inside' })
            .toBuffer();

        // Upload to Destination Bucket
        await s3.send(new PutObjectCommand({
            Bucket: dstBucket,
            Key: `thumb-${key}`,
            Body: resizedImage,
            ContentType: response.ContentType
        }));

        console.log(`Success: ${key} moved from ${srcBucket} to ${dstBucket}`);
    } catch (error) {
        console.error("Error:", error);
        throw error;
    }
};

const { S3Client, PutObjectCommand, DeleteObjectCommand } = require("@aws-sdk/client-s3");
const crypto = require("crypto");
const path = require("path");

const s3 = new S3Client({
  region: process.env.AWS_REGION,
  credentials: {
    accessKeyId: process.env.AWS_ACCESS_KEY_ID,
    secretAccessKey: process.env.AWS_SECRET_ACCESS_KEY,
  },
});

const buildKey = ({ projectId, key, originalname, folder = "docs" }) => {
  const ext = path.extname(originalname || ".pdf") || ".pdf";
  const rand = crypto.randomBytes(6).toString("hex");
  return `projects/${projectId}/${folder}/${key}_${Date.now()}_${rand}${ext}`;
};

exports.uploadPdfToS3 = async ({ file, projectId, key, folder }) => {
  const bucket = process.env.AWS_S3_BUCKET;
  if (!bucket) throw new Error("AWS_S3_BUCKET missing");

  const objectKey = buildKey({
    projectId,
    key,
    originalname: file.originalname,
    folder: folder || "docs",
  });

  await s3.send(
    new PutObjectCommand({
      Bucket: bucket,
      Key: objectKey,
      Body: file.buffer,
      ContentType: file.mimetype || "application/pdf",
    })
  );

  return `s3://${bucket}/${objectKey}`;
};

exports.deleteFromS3ByUrl = async (s3Url) => {
  if (!s3Url || !s3Url.startsWith("s3://")) return;

  const raw = s3Url.replace("s3://", "");
  const parts = raw.split("/");
  const bucket = parts.shift();
  const objectKey = parts.join("/");

  await s3.send(
    new DeleteObjectCommand({
      Bucket: bucket,
      Key: objectKey,
    })
  );
};

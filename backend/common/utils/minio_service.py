from minio import Minio
from minio.error import S3Error
import os
from datetime import timedelta

class MinioService:
    _client = None
    _bucket = os.getenv("MINIO_BUCKET", "food-images")

    @classmethod
    def get_client(cls):
        if cls._client is None:
            endpoint = os.getenv("MINIO_ENDPOINT", "localhost:9000")
            access_key = os.getenv("MINIO_ROOT_USER", "minioadmin")
            secret_key = os.getenv("MINIO_ROOT_PASSWORD", "minioadmin")
            secure = os.getenv("MINIO_SECURE", "False").lower() == "true"
            
            cls._client = Minio(
                endpoint,
                access_key=access_key,
                secret_key=secret_key,
                secure=secure
            )
            cls._ensure_bucket()
        return cls._client

    @classmethod
    def _ensure_bucket(cls):
        try:
            if not cls._client.bucket_exists(cls._bucket):
                cls._client.make_bucket(cls._bucket)
                # Set public policy if needed, or rely on presigned URLs
                # For now, let's keep it private and use presigned URLs or public policy
                print(f"Bucket '{cls._bucket}' created.")
        except S3Error as e:
            print(f"MinIO Bucket Error: {e}")

    @classmethod
    def upload_file(cls, file_data, file_name: str, content_type: str) -> str:
        """
        Uploads a file to MinIO and returns the URL.
        file_data: bytes or file-like object
        """
        client = cls.get_client()
        length = -1
        if hasattr(file_data, "getbuffer"):
             length = len(file_data.getbuffer())
        elif hasattr(file_data, "read"):
             # It's a file-like object, usually need to seek/tell or standard size
             # MinIO put_object requires length. 
             # For SpooledTemporaryFile (FastAPI UploadFile), logic is needed.
             file_data.seek(0, 2)
             length = file_data.tell()
             file_data.seek(0)
        
        try:
            client.put_object(
                cls._bucket,
                file_name,
                file_data,
                length,
                content_type=content_type
            )
            # Generate URL (Presigned or Construct Public)
            # If using localhost/docker, presigned might have connectivity issues if host is different
            # For now, let's return a relative path or a presigned URL
            
            # Presigned URL (valid for 7 days)
            # url = client.get_presigned_url("GET", cls._bucket, file_name, expires=timedelta(days=7))
            
            # Or construct public URL if policy allows (assuming localhost access)
            endpoint = os.getenv("MINIO_EXTERNAL_ENDPOINT", "http://localhost:9000")
            return f"{endpoint}/{cls._bucket}/{file_name}"
            
        except S3Error as e:
            print(f"Upload Failed: {e}")
            return None

from .minio_service import MinioService
from fastapi import UploadFile

# UPLOAD_DIR = "uploads"
# os.makedirs(UPLOAD_DIR, exist_ok=True)

class StorageService:
    @staticmethod
    async def upload_image(file: UploadFile) -> str:
        """
        Uploads file to MinIO Storage.
        Returns the public URL.
        """
        # Ensure bucket and client are ready
        # file.file is a SpooledTemporaryFile
        url = MinioService.upload_file(file.file, file.filename, file.content_type)
        if not url:
            raise Exception("Failed to upload image to MinIO")
            
        return url

    @staticmethod
    def get_gcs_client():
        """
        Placeholder for actual GCS client initialization.
        from google.cloud import storage
        return storage.Client()
        """
        pass

from django.db import models
import uuid
from users.models import User  # ✅ 사용자 모델 임포트

class Album(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="album")
    background_color = models.CharField(max_length=10, default="#FFFFFF")  # ✅ 배경 색상 추가
    background_pattern = models.CharField(max_length=50, default="none")  # ✅ 배경 패턴 추가
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'album'

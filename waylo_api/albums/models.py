from django.db import models
import uuid
from users.models import User

class Album(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False) # 앨범 아이디디
    user = models.OneToOneField(User, on_delete=models.CASCADE, related_name="album")  # 유저 (1:1)
    background_color = models.CharField(max_length=10, default="#FFFFFF")   # 배경색
    background_pattern = models.CharField(max_length=50, default="none")    # 배경패턴
    created_at = models.DateTimeField(auto_now_add=True)    # 생성 시간간

    class Meta:
        db_table = 'album'

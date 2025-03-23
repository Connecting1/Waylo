from django.db import models
from albums.models import Album  # 🔥 Album과 연결해야 함
import uuid

class Widget(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    album = models.ForeignKey(Album, on_delete=models.CASCADE, related_name="widgets")  # 앨범과 연결
    type = models.CharField(max_length=50)  # 위젯 종류 (프로필 사진, 텍스트, 음악 등)
    x = models.FloatField()  # 위젯 위치 (x 좌표)
    y = models.FloatField()  # 위젯 위치 (y 좌표)
    width = models.FloatField()  # 위젯 크기 (너비)
    height = models.FloatField()  # 위젯 크기 (높이)
    extra_data = models.JSONField(default=dict)  # 위젯별 추가 데이터 저장 (이미지 URL, 음악 정보 등)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'widgets'

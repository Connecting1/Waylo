from django.urls import path
from .views import get_album_info  # ✅ views에서 get_album_info 가져오기

urlpatterns = [
    path('api/albums/<uuid:user_id>/', get_album_info, name='get_album_info'),  # ✅ UUID로 앨범 조회
]

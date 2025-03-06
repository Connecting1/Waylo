from django.urls import path
from .views import get_album_info, update_album_info  # views에서 get_album_info 가져오기

urlpatterns = [
    path('<uuid:user_id>/', get_album_info, name='get_album_info'),  # UUID로 앨범 조회
    path('<uuid:user_id>/update/', update_album_info, name='update_album_info'),  # 유저 정보 업데이트 (PATCH)
]

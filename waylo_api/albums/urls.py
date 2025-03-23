from django.urls import path
from .views import get_album_info, update_album_info

urlpatterns = [
    path('<uuid:user_id>/', get_album_info, name='get_album_info'),  # 앨범 정보 조회
    path('<uuid:user_id>/update/', update_album_info, name='update_album_info'),  # 앨범 정보 수정
]
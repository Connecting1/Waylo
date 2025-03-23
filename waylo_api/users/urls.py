from django.urls import path
from .views import (
    user_create_view,
    user_login_view,
    get_user_info,
    update_user_info,
    update_profile_image,
    search_users
)

urlpatterns = [
    path('create/', user_create_view, name='user-create'),  # 사용자 생성
    path('login/', user_login_view, name='user-login'),  # 사용자 로그인
    path('<uuid:user_id>/', get_user_info, name='get_user_info'),  # 사용자 정보 조회
    path('<uuid:user_id>/update/', update_user_info, name='update_user_info'),  # 사용자 정보 수정
    path('<str:user_id>/update-profile-image/', update_profile_image, name='update_profile_image'),  # 프로필 이미지 업데이트
    path('search/', search_users, name='search_users'),  # 사용자 검색
]
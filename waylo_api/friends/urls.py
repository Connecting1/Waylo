from django.urls import path
from .views import (
    send_friend_request_view,
    get_friend_requests_view,
    get_sent_friend_requests_view,
    accept_friend_request_view,
    reject_friend_request_view,
    get_friends_info
)

urlpatterns = [
    # 친구 요청 관련 엔드포인트
    path('request/', send_friend_request_view, name='send_friend_request'),
    path('requests/', get_friend_requests_view, name='get_friend_requests'),
    path('sent-requests/', get_sent_friend_requests_view, name='get_sent_friend_requests'),
    path('accept/', accept_friend_request_view, name='accept_friend_request'),
    path('reject/', reject_friend_request_view, name='reject_friend_request'),

    # 친구 목록 조회
    path('<uuid:user_id>/', get_friends_info, name='get_friends_info'),
]

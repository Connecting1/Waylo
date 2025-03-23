from django.urls import path
from . import views

urlpatterns = [
    path('rooms/', views.get_chat_rooms, name='get_chat_rooms'),  # 채팅방 목록 조회
    path('rooms/create/', views.create_chat_room, name='create_chat_room'),  # 채팅방 생성
    path('rooms/<uuid:room_id>/messages/', views.chat_messages, name='chat_messages'),  # 메시지 조회/전송
]
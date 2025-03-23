from django.db import models
import uuid
from users.models import User

class ChatRoom(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)  # 채팅방 고유 ID
    participants = models.ManyToManyField(User, related_name='chat_rooms')  # 참여자들
    created_at = models.DateTimeField(auto_now_add=True)  # 생성 시간
    updated_at = models.DateTimeField(auto_now=True)  # 마지막 업데이트 시간

    class Meta:
        db_table = 'chat_rooms'  # 테이블 이름 지정

    def get_other_participant(self, user):
        """현재 사용자 기준으로 채팅방의 다른 참여자 가져오기"""
        return self.participants.exclude(id=user.id).first()


class ChatMessage(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)  # 메시지 고유 ID
    room = models.ForeignKey(ChatRoom, on_delete=models.CASCADE, related_name='messages')  # 채팅방 연결
    sender = models.ForeignKey(User, on_delete=models.CASCADE, related_name='sent_messages')  # 발신자
    content = models.TextField()  # 메시지 내용
    created_at = models.DateTimeField(auto_now_add=True)  # 메시지 전송 시간
    is_read = models.BooleanField(default=False)  # 읽음 여부

    class Meta:
        db_table = 'chat_messages'  # 테이블 이름 지정
        ordering = ['created_at']  # 오래된 메시지부터 정렬
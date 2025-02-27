from django.db import models
from users.models import User  # 🔥 User 모델을 가져와야 함
import uuid

class FriendRequest(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="sent_requests")
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="received_requests")
    status = models.CharField(max_length=20, choices=[
        ('pending', 'Pending'),
        ('accepted', 'Accepted'),
        ('rejected', 'Rejected'),
    ], default='pending')  # ✅ 친구 요청 상태 (수락, 거절 가능)
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'friend_requests'
        constraints = [
            models.UniqueConstraint(fields=['from_user', 'to_user'], name='unique_friend_request')
        ]


class Friendship(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user1 = models.ForeignKey(User, on_delete=models.CASCADE, related_name="friends1")
    user2 = models.ForeignKey(User, on_delete=models.CASCADE, related_name="friends2")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'friendships'
        constraints = [
            models.UniqueConstraint(fields=['user1', 'user2'], name='unique_friendship')
        ]

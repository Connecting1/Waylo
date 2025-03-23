import uuid
import logging
from django.db import models, transaction
from django.db.models import Q
from users.models import User

logger = logging.getLogger(__name__)

class FriendRequest(models.Model):
    """
    친구 요청을 관리하는 모델
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    from_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="sent_requests")
    to_user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="received_requests")
    status = models.CharField(
        max_length=20,
        choices=[
            ('pending', 'Pending'),
            ('accepted', 'Accepted'),
            ('rejected', 'Rejected'),
        ],
        default='pending'
    )
    created_at = models.DateTimeField(auto_now_add=True)
    updated_at = models.DateTimeField(auto_now=True)

    class Meta:
        db_table = 'friend_requests'
        constraints = [
            models.UniqueConstraint(fields=['from_user', 'to_user'], name='unique_friend_request')
        ]
        ordering = ['-created_at']

    def save(self, *args, **kwargs):
        if self.from_user == self.to_user:
            raise ValueError("자기 자신에게 친구 요청을 보낼 수 없습니다.")
        return super().save(*args, **kwargs)

    def accept(self):
        """
        친구 요청을 수락하고 친구 관계를 생성
        """
        with transaction.atomic():
            if self.status != 'pending':
                logger.warning(f"이미 처리된 친구 요청 수락 시도: {self}")
                raise ValueError("이미 처리된 친구 요청입니다.")
            
            logger.info(f"수락 중인 친구 요청: {self.id}, from={self.from_user.id}, to={self.to_user.id}")
            
            self.status = 'accepted'
            self.save()
            
            friendship, created = Friendship.create_friendship(self.from_user, self.to_user)

            logger.info(f"친구 관계 생성 결과: {friendship}, {created}")

            if created:
                logger.info(f"새로운 친구 관계 생성됨: {self.from_user} <-> {self.to_user}")
            return friendship

    def reject(self):
        """
        친구 요청을 거절
        """
        with transaction.atomic():
            if self.status != 'pending':
                logger.warning(f"이미 처리된 친구 요청 거절 시도: {self}")
                raise ValueError("이미 처리된 친구 요청입니다.")
            
            self.status = 'rejected'
            self.save()
            return self


class Friendship(models.Model):
    """
    친구 관계를 관리하는 모델
    """
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user1 = models.ForeignKey(User, on_delete=models.CASCADE, related_name="friends1")
    user2 = models.ForeignKey(User, on_delete=models.CASCADE, related_name="friends2")
    created_at = models.DateTimeField(auto_now_add=True)

    class Meta:
        db_table = 'friendships'
        constraints = [
            models.UniqueConstraint(fields=['user1', 'user2'], name='unique_friendship')
        ]

    @classmethod
    def create_friendship(cls, from_user, to_user):
        """
        두 사용자 간 친구 관계를 생성
        """
        logger.info(f"친구 관계 생성 시도: {from_user.id} <-> {to_user.id}")

        if from_user == to_user:
            logger.warning("자기 자신과 친구 관계를 생성할 수 없습니다.")
            return None, False

        # 이미 친구 관계가 있는지 확인
        if cls.objects.filter(Q(user1=from_user, user2=to_user) | Q(user1=to_user, user2=from_user)).exists():
            logger.info(f"이미 존재하는 친구 관계: {from_user} <-> {to_user}")
            return None, False

        # 새로운 친구 관계 생성
        new_friendship = cls.objects.create(user1=from_user, user2=to_user)
        logger.info(f"새로운 친구 관계 생성됨: {from_user} <-> {to_user}")
        return new_friendship, True

    @classmethod
    def count_friends(cls, user):
        """
        특정 사용자의 친구 수를 계산
        """
        return cls.objects.filter(Q(user1=user) | Q(user2=user)).count()

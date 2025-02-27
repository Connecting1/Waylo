from django.db import models
from users.models import User  # 🔥 User 모델을 가져와야 함
import uuid

class Feed(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="feeds")  # 피드 작성자
    latitude = models.DecimalField(max_digits=9, decimal_places=6)  # GPS 위도
    longitude = models.DecimalField(max_digits=9, decimal_places=6)  # GPS 경도
    country_code = models.CharField(max_length=10, blank=True, null=True)  # 국가 코드 (KR, US, FR 등)
    image_url = models.TextField()  # 지도 위에 올라갈 사진 URL
    description = models.TextField(blank=True, null=True)  # 사진 설명
    visibility = models.CharField(max_length=20, choices=[
        ('public', 'Public'),
        ('private', 'Private'),
    ], default='public')  # 🔥 "friends-only" 제거
    extra_data = models.JSONField(default=dict)  # 추가 정보 (태그, 위치명 등)
    created_at = models.DateTimeField(auto_now_add=True)  # 업로드 날짜
    likes_count = models.PositiveIntegerField(default=0)  # 좋아요 개수 저장
    bookmarks_count = models.PositiveIntegerField(default=0)  # 즐겨찾기 개수 저장

    class Meta:
        db_table = 'feeds'


class FeedLike(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="feed_likes")  # 좋아요를 누른 유저
    feed = models.ForeignKey(Feed, on_delete=models.CASCADE, related_name="likes")  # 좋아요가 달린 피드
    created_at = models.DateTimeField(auto_now_add=True)  # 좋아요를 누른 시간

    class Meta:
        db_table = 'feed_likes'
        constraints = [
            models.UniqueConstraint(fields=['user', 'feed'], name='unique_feed_like')  # 중복 좋아요 방지
        ]

class FeedBookmark(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="bookmarked_feeds")  # 즐겨찾기한 유저
    feed = models.ForeignKey(Feed, on_delete=models.CASCADE, related_name="bookmarks")  # 즐겨찾기된 피드
    created_at = models.DateTimeField(auto_now_add=True)  # 즐겨찾기한 시간

    class Meta:
        db_table = 'feed_bookmarks'
        constraints = [
            models.UniqueConstraint(fields=['user', 'feed'], name='unique_feed_bookmark')  # 중복 즐겨찾기 방지
        ]


class FeedComment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    feed = models.ForeignKey(Feed, on_delete=models.CASCADE, related_name="comments")  # 어느 피드의 댓글인지
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="comments")  # 댓글 작성자
    content = models.TextField()  # 댓글 내용
    created_at = models.DateTimeField(auto_now_add=True)  # 댓글 작성 시간
    likes_count = models.PositiveIntegerField(default=0)  # 좋아요 개수 저장

    class Meta:
        db_table = 'feed_comments'


class CommentLike(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="comment_likes")  # 좋아요를 누른 유저
    comment = models.ForeignKey(FeedComment, on_delete=models.CASCADE, related_name="likes")  # 좋아요가 달린 댓글
    created_at = models.DateTimeField(auto_now_add=True)  # 좋아요를 누른 시간

    class Meta:
        db_table = 'comment_likes'
        constraints = [
            models.UniqueConstraint(fields=['user', 'comment'], name='unique_comment_like')  # 중복 좋아요 방지
        ]




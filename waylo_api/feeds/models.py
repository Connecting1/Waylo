from django.contrib.gis.db import models as gis_models
from django.db import models
from users.models import User
import uuid

# 피드 정보 저장
class Feed(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="feeds")  # 피드를 작성한 유저
    latitude = models.DecimalField(max_digits=9, decimal_places=6)  # 위도
    longitude = models.DecimalField(max_digits=9, decimal_places=6)  # 경도
    location = gis_models.PointField(geography=True, null=True)  # 위치 정보 (GIS)
    country_code = models.CharField(max_length=10, blank=True, null=True)  # 국가 코드
    image_url = models.TextField()  # 이미지 URL
    thumbnail_url = models.TextField(blank=True, null=True)  # 썸네일 이미지 URL
    description = models.TextField(blank=True, null=True)  # 설명
    visibility = models.CharField(max_length=20, choices=[
        ('public', 'Public'),
        ('private', 'Private'),
    ], default='public')  # 공개 여부
    photo_taken_at = models.DateTimeField(null=True, blank=True)  # 사진 촬영 시간
    extra_data = models.JSONField(default=dict)  # 추가 데이터
    created_at = models.DateTimeField(auto_now_add=True)  # 생성 시간
    likes_count = models.PositiveIntegerField(default=0)  # 좋아요 수
    bookmarks_count = models.PositiveIntegerField(default=0)  # 북마크 수

    class Meta:
        db_table = 'feeds'  # 테이블 이름 지정

    def save(self, *args, **kwargs):
        """ 위도와 경도를 이용해 위치 정보 생성 """
        from django.contrib.gis.geos import Point
        if self.latitude and self.longitude:
            self.location = Point(float(self.longitude), float(self.latitude))
        super().save(*args, **kwargs)


# 피드 좋아요 정보 저장
class FeedLike(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="feed_likes")  # 좋아요한 유저
    feed = models.ForeignKey(Feed, on_delete=models.CASCADE, related_name="likes")  # 좋아요 대상 피드
    created_at = models.DateTimeField(auto_now_add=True)  # 생성 시간

    class Meta:
        db_table = 'feed_likes'
        constraints = [
            models.UniqueConstraint(fields=['user', 'feed'], name='unique_feed_like')  # 중복 좋아요 방지
        ]


# 피드 북마크 정보 저장
class FeedBookmark(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="bookmarked_feeds")  # 북마크한 유저
    feed = models.ForeignKey(Feed, on_delete=models.CASCADE, related_name="bookmarks")  # 북마크 대상 피드
    created_at = models.DateTimeField(auto_now_add=True)  # 생성 시간

    class Meta:
        db_table = 'feed_bookmarks'
        constraints = [
            models.UniqueConstraint(fields=['user', 'feed'], name='unique_feed_bookmark')  # 중복 북마크 방지
        ]


# 피드 댓글 정보 저장
class FeedComment(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    feed = models.ForeignKey(Feed, on_delete=models.CASCADE, related_name="comments")  # 댓글이 달린 피드
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="comments")  # 댓글 작성 유저
    content = models.TextField()  # 댓글 내용
    created_at = models.DateTimeField(auto_now_add=True)  # 생성 시간
    likes_count = models.PositiveIntegerField(default=0)  # 좋아요 수

    class Meta:
        db_table = 'feed_comments'  # 테이블 이름 지정


# 댓글 좋아요 정보 저장
class CommentLike(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    user = models.ForeignKey(User, on_delete=models.CASCADE, related_name="comment_likes")  # 좋아요한 유저
    comment = models.ForeignKey(FeedComment, on_delete=models.CASCADE, related_name="likes")  # 좋아요 대상 댓글
    created_at = models.DateTimeField(auto_now_add=True)  # 생성 시간

    class Meta:
        db_table = 'comment_likes'
        constraints = [
            models.UniqueConstraint(fields=['user', 'comment'], name='unique_comment_like')  # 중복 좋아요 방지
        ]

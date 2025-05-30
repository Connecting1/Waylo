from rest_framework import serializers
from .models import Feed, FeedLike, FeedBookmark, FeedComment, CommentLike

# 피드 정보 직렬화
class FeedSerializer(serializers.ModelSerializer):
    user_details = serializers.SerializerMethodField()  # 유저 정보 추가
    is_liked = serializers.SerializerMethodField()  # 사용자가 좋아요 눌렀는지 여부
    is_bookmarked = serializers.SerializerMethodField()  # 사용자가 북마크했는지 여부
    distance = serializers.SerializerMethodField()  # 거리 정보 추가
    
    class Meta:
        model = Feed
        fields = '__all__'
        
    def get_user_details(self, obj):
        """ 피드 작성자의 기본 정보 반환 """
        return {
            'id': str(obj.user.id),
            'username': obj.user.username,
            'profile_image': obj.user.profile_image
        }
    
    def get_is_liked(self, obj):
        """ 사용자가 피드에 좋아요를 눌렀는지 확인 """
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return FeedLike.objects.filter(feed=obj, user=request.user).exists()
        return False
    
    def get_is_bookmarked(self, obj):
        """ 사용자가 피드를 북마크했는지 확인 """
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return FeedBookmark.objects.filter(feed=obj, user=request.user).exists()
        return False
    
    def get_distance(self, obj):
        """ 피드와 사용자의 거리 반환 (km 단위) """
        if hasattr(obj, 'distance'):
            return round(obj.distance.km, 2)
        return None


# 피드 댓글 정보 직렬화
class FeedCommentSerializer(serializers.ModelSerializer):
    user_details = serializers.SerializerMethodField()  # 유저 정보 추가
    is_liked = serializers.SerializerMethodField()  # 사용자가 댓글에 좋아요 눌렀는지 여부
    replies = serializers.SerializerMethodField()  # 추가: 대댓글 목록
    
    class Meta:
        model = FeedComment
        fields = '__all__'
    
    def get_user_details(self, obj):
        """ 댓글 작성자의 기본 정보 반환 """
        return {
            'id': str(obj.user.id),
            'username': obj.user.username,
            'profile_image': obj.user.profile_image
        }
    
    def get_is_liked(self, obj):
        """ 사용자가 댓글에 좋아요를 눌렀는지 확인 """
        request = self.context.get('request')
        if request and request.user.is_authenticated:
            return CommentLike.objects.filter(comment=obj, user=request.user).exists()
        return False
    
    # 추가: 대댓글 가져오기 메서드
    def get_replies(self, obj):
        """ 댓글의 대댓글 목록 반환 """
        # 이미 대댓글인 경우 빈 리스트 반환 (중첩 방지)
        if obj.parent is not None:
            return []
            
        # 해당 댓글의 대댓글 조회
        replies = FeedComment.objects.filter(parent=obj).order_by('created_at')
        
        # 대댓글 직렬화
        serializer = FeedCommentSerializer(replies, many=True, context=self.context)
        return serializer.data


# 피드 좋아요 정보 직렬화
class FeedLikeSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedLike
        fields = '__all__'


# 피드 북마크 정보 직렬화
class FeedBookmarkSerializer(serializers.ModelSerializer):
    class Meta:
        model = FeedBookmark
        fields = '__all__'


# 댓글 좋아요 정보 직렬화
class CommentLikeSerializer(serializers.ModelSerializer):
    class Meta:
        model = CommentLike
        fields = '__all__'
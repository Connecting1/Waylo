from django.urls import path
from .views import (
    feed_list, 
    feed_detail, 
    create_feed, 
    update_feed,
    delete_feed,
    like_feed,
    unlike_feed,
    bookmark_feed,
    unbookmark_feed,
    feed_comments,
    create_comment,
    delete_comment,
    like_comment,
    unlike_comment,
    nearby_feeds,
    user_feeds,
    bookmarked_feeds,
    friends_feeds  # 새로 추가된 import
)

urlpatterns = [
    # 피드 기본 CRUD
    path('', feed_list, name='feed-list'),
    path('<uuid:feed_id>/', feed_detail, name='feed-detail'),
    path('create/', create_feed, name='create-feed'),
    path('<uuid:feed_id>/update/', update_feed, name='update-feed'),
    path('<uuid:feed_id>/delete/', delete_feed, name='delete-feed'),
    
    # 좋아요 및 북마크
    path('<uuid:feed_id>/like/', like_feed, name='like-feed'),
    path('<uuid:feed_id>/unlike/', unlike_feed, name='unlike-feed'),
    path('<uuid:feed_id>/bookmark/', bookmark_feed, name='bookmark-feed'),
    path('<uuid:feed_id>/unbookmark/', unbookmark_feed, name='unbookmark-feed'),
    
    # 댓글
    path('<uuid:feed_id>/comments/', feed_comments, name='feed-comments'),
    path('<uuid:feed_id>/comment/', create_comment, name='create-comment'),
    path('comment/<uuid:comment_id>/delete/', delete_comment, name='delete-comment'),
    path('comment/<uuid:comment_id>/like/', like_comment, name='like-comment'),
    path('comment/<uuid:comment_id>/unlike/', unlike_comment, name='unlike-comment'),
    
    # 특수 피드 목록
    path('nearby/', nearby_feeds, name='nearby-feeds'),
    path('user/<uuid:user_id>/', user_feeds, name='user-feeds'),
    path('bookmarked/', bookmarked_feeds, name='bookmarked-feeds'),
    path('friends/', friends_feeds, name='friends-feeds'),  # 새로 추가된 URL
]
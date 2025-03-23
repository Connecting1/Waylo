from PIL import Image, ImageOps, ExifTags
import logging
import io
import os
import posixpath
from decimal import Decimal
from django.conf import settings
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.db.models import F, Q
from django.utils import timezone
from rest_framework.decorators import api_view, authentication_classes, permission_classes, parser_classes
from rest_framework.parsers import MultiPartParser, FormParser
from rest_framework.response import Response
from rest_framework import status
from rest_framework.permissions import IsAuthenticated
from users.authentication import CustomTokenAuthentication
from rest_framework.parsers import MultiPartParser, FormParser, JSONParser
from users.models import User
from .models import Feed, FeedLike, FeedBookmark, FeedComment, CommentLike
from .serializers import (
    FeedSerializer, 
    FeedCommentSerializer, 
    FeedLikeSerializer, 
    FeedBookmarkSerializer, 
    CommentLikeSerializer
)
from django.contrib.gis.geos import Point
from django.contrib.gis.db.models.functions import Distance
from django.contrib.gis.measure import D
from datetime import datetime

# 로깅 설정
logger = logging.getLogger(__name__)

# EXIF 데이터에서 촬영 날짜 추출 유틸리티 함수
def extract_photo_date_from_exif(image_file):
    """
    EXIF 데이터에서 촬영 날짜 추출
    """
    try:
        img = Image.open(image_file)
        exif_data = img._getexif()
        
        if exif_data is not None:
            for tag_id, value in exif_data.items():
                tag_name = ExifTags.TAGS.get(tag_id, tag_id)
                
                # 날짜 정보 추출
                if tag_name == 'DateTimeOriginal' or tag_name == 'DateTime':
                    try:
                        date_str = value
                        photo_date = datetime.strptime(date_str, '%Y:%m:%d %H:%M:%S')
                        return photo_date
                    except Exception:
                        pass
        
        img.close()
    except Exception:
        pass
    
    return None


# 피드 목록 조회 (공개 피드만)
@api_view(['GET'])
def feed_list(request):
    """
    공개된 피드 목록을 조회하는 API
    """
    try:
        feeds = Feed.objects.filter(visibility='public').order_by('-created_at')

        # 페이지네이션 적용
        page = int(request.query_params.get('page', 1))
        limit = int(request.query_params.get('limit', 10))
        start = (page - 1) * limit
        end = page * limit
        
        serializer = FeedSerializer(
            feeds[start:end], 
            many=True, 
            context={'request': request}
        )
        
        return Response({
            'feeds': serializer.data,
            'total': feeds.count(),
            'page': page,
            'limit': limit
        }, status=status.HTTP_200_OK)
    
    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 단일 피드 조회
@api_view(['GET'])
def feed_detail(request, feed_id):
    """
    특정 피드 정보를 조회하는 API
    """
    try:
        feed = Feed.objects.get(id=feed_id)

        # 비공개 피드 권한 체크
        if feed.visibility == 'private' and (not request.user.is_authenticated or feed.user != request.user):
            return Response({'error': '이 피드를 볼 수 있는 권한이 없습니다.'}, status=status.HTTP_403_FORBIDDEN)

        serializer = FeedSerializer(feed, context={'request': request})

        # 댓글 조회
        comments = FeedComment.objects.filter(feed=feed).order_by('-created_at')
        comment_serializer = FeedCommentSerializer(comments, many=True, context={'request': request})

        response_data = serializer.data
        response_data['comments'] = comment_serializer.data

        return Response(response_data, status=status.HTTP_200_OK)

    except Feed.DoesNotExist:
        return Response({'error': '피드를 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 피드 생성
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser])
def create_feed(request):
    """
    새로운 피드를 생성하는 API
    """
    try:
        logger.error(f"요청 받음: {request.method}")
        logger.error(f"요청 데이터: {request.data}")
        logger.error(f"요청 FILES: {request.FILES}")

        if 'image' not in request.FILES:
            return Response({'error': '이미지를 업로드해야 합니다.'}, status=status.HTTP_400_BAD_REQUEST)

        latitude = request.data.get('latitude')
        longitude = request.data.get('longitude')

        if not latitude or not longitude:
            return Response({'error': '위치 정보가 필요합니다.'}, status=status.HTTP_400_BAD_REQUEST)

        try:
            formatted_latitude = float(format(float(latitude), '.6f'))
            formatted_longitude = float(format(float(longitude), '.6f'))
        except Exception:
            return Response({'error': '위치 정보 형식이 올바르지 않습니다.'}, status=status.HTTP_400_BAD_REQUEST)

        image_file = request.FILES['image']
        user_id = request.user.id
        feed_folder = os.path.join(settings.MEDIA_ROOT, str(user_id), 'feeds')
        os.makedirs(feed_folder, exist_ok=True)

        timestamp = timezone.now().strftime('%Y%m%d%H%M%S')
        file_name = f"{timestamp}_{image_file.name}"
        file_path = os.path.join(feed_folder, file_name)

        try:
            image_data = image_file.read()
            default_storage.save(file_path, ContentFile(image_data))
        except Exception:
            return Response({'error': '이미지 저장 실패'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

        image_url = posixpath.join(settings.MEDIA_URL, str(user_id), 'feeds', file_name).replace("\\", "/")

        thumbnail_size = (200, 200)
        thumbnail_name = f"thumb_{file_name}"
        thumbnail_path = os.path.join(feed_folder, thumbnail_name)

        photo_taken_at = None

        if 'photo_taken_at' in request.data and request.data.get('photo_taken_at'):
            try:
                photo_taken_at = datetime.fromisoformat(request.data.get('photo_taken_at').replace('Z', '+00:00'))
            except Exception:
                pass

        if photo_taken_at is None:
            try:
                with open(file_path, 'rb') as reopened_image:
                    photo_taken_at = extract_photo_date_from_exif(reopened_image)
            except Exception:
                pass

        try:
            with Image.open(file_path) as img:
                from PIL import ImageOps
                img = ImageOps.exif_transpose(img)

                width, height = img.size

                if width > height:
                    left = (width - height) // 2
                    top = 0
                    right = left + height
                    bottom = height
                else:
                    top = (height - width) // 2
                    left = 0
                    bottom = top + width
                    right = width

                img_cropped = img.crop((left, top, right, bottom))
                img_resized = img_cropped.resize(thumbnail_size, Image.LANCZOS)

                thumb_io = io.BytesIO()
                img_resized.save(thumb_io, format='JPEG', quality=85)
                thumb_io.seek(0)

                default_storage.save(thumbnail_path, ContentFile(thumb_io.getvalue()))
        except Exception:
            thumbnail_url = ""
        else:
            thumbnail_url = posixpath.join(settings.MEDIA_URL, str(user_id), 'feeds', thumbnail_name).replace("\\", "/")

        feed_data = {
            'user': request.user.id,
            'latitude': formatted_latitude,
            'longitude': formatted_longitude,
            'country_code': request.data.get('country_code'),
            'image_url': image_url,
            'thumbnail_url': thumbnail_url,
            'description': request.data.get('description', ''),
            'visibility': request.data.get('visibility', 'public'),
            'photo_taken_at': photo_taken_at,
            'extra_data': {},
        }

        extra_fields = ['tags', 'location_name', 'address']
        for field in extra_fields:
            if field in request.data:
                feed_data['extra_data'][field] = request.data.get(field)

        serializer = FeedSerializer(data=feed_data)
        if serializer.is_valid():
            try:
                feed = serializer.save()
                return Response(serializer.data, status=status.HTTP_201_CREATED)
            except Exception:
                return Response({'error': '피드 저장 실패'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
        else:
            if os.path.exists(file_path):
                os.remove(file_path)
            if os.path.exists(thumbnail_path):
                os.remove(thumbnail_path)
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 피드 수정
@api_view(['PATCH'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
@parser_classes([MultiPartParser, FormParser, JSONParser])
def update_feed(request, feed_id):
    """
    기존 피드를 수정하는 API
    """
    try:
        feed = Feed.objects.get(id=feed_id)

        # 작성자 확인
        if feed.user != request.user:
            return Response({'error': '피드를 수정할 권한이 없습니다.'}, status=status.HTTP_403_FORBIDDEN)

        # 수정 가능한 필드
        feed_data = {}
        for field in ['description', 'visibility', 'latitude', 'longitude', 'country_code']:  # 위치 필드 추가
            if field in request.data:
                feed_data[field] = request.data.get(field)

        # 사진 촬영 날짜 처리
        if 'photo_taken_at' in request.data:
            try:
                if request.data.get('photo_taken_at'):
                    photo_taken_at = datetime.fromisoformat(request.data.get('photo_taken_at').replace('Z', '+00:00'))
                    feed_data['photo_taken_at'] = photo_taken_at
                else:
                    feed_data['photo_taken_at'] = None
            except Exception:
                pass

        # 추가 데이터 업데이트
        if feed.extra_data is None:
            feed.extra_data = {}

        extra_fields = ['tags', 'location_name', 'address']
        for field in extra_fields:
            if field in request.data:
                feed.extra_data[field] = request.data.get(field)

        feed_data['extra_data'] = feed.extra_data

        # 이미지 업데이트
        if 'image' in request.FILES:
            image_file = request.FILES['image']
            user_id = request.user.id
            feed_folder = os.path.join(settings.MEDIA_ROOT, str(user_id), 'feeds')
            os.makedirs(feed_folder, exist_ok=True)

            # 이전 이미지 삭제
            old_image_path = os.path.join(settings.MEDIA_ROOT, feed.image_url.lstrip('/media/'))
            if os.path.exists(old_image_path):
                os.remove(old_image_path)

            # 새 이미지 저장
            timestamp = timezone.now().strftime('%Y%m%d%H%M%S')
            file_name = f"{timestamp}_{image_file.name}"
            file_path = os.path.join(feed_folder, file_name)
            default_storage.save(file_path, ContentFile(image_file.read()))

            # 이미지 URL 업데이트
            feed_data['image_url'] = posixpath.join(settings.MEDIA_URL, str(user_id), 'feeds', file_name).replace("\\", "/")

            # 새 이미지에서 EXIF 촬영 날짜 추출
            if 'photo_taken_at' not in feed_data:
                try:
                    with open(file_path, 'rb') as reopened_image:
                        photo_taken_at = extract_photo_date_from_exif(reopened_image)
                        if photo_taken_at:
                            feed_data['photo_taken_at'] = photo_taken_at
                except Exception:
                    pass

        # 피드 업데이트
        serializer = FeedSerializer(feed, data=feed_data, partial=True)
        if serializer.is_valid():
            serializer.save()
            return Response(serializer.data, status=status.HTTP_200_OK)
        else:
            return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)

    except Feed.DoesNotExist:
        return Response({'error': '피드를 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception as e:
        import traceback
        print(f"피드 업데이트 중 상세 오류: {e}")
        print(f"스택 트레이스: {traceback.format_exc()}")
        return Response({'error': f'서버 오류가 발생했습니다: {str(e)}'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 피드 삭제
@api_view(['DELETE'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def delete_feed(request, feed_id):
    """
    기존 피드를 삭제하는 API
    """
    try:
        feed = Feed.objects.get(id=feed_id)

        # 작성자 확인
        if feed.user != request.user:
            return Response({'error': '피드를 삭제할 권한이 없습니다.'}, status=status.HTTP_403_FORBIDDEN)

        # 이미지 파일 삭제
        image_path = os.path.join(settings.MEDIA_ROOT, feed.image_url.lstrip('/media/'))
        if os.path.exists(image_path):
            os.remove(image_path)

        # 피드 삭제
        feed.delete()

        return Response({'message': '피드가 삭제되었습니다.'}, status=status.HTTP_200_OK)

    except Feed.DoesNotExist:
        return Response({'error': '피드를 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 피드 좋아요
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def like_feed(request, feed_id):
    """
    피드에 좋아요를 추가하는 API
    """
    try:
        feed = Feed.objects.get(id=feed_id)

        # 이미 좋아요 했는지 확인
        like, created = FeedLike.objects.get_or_create(user=request.user, feed=feed)

        if created:
            feed.likes_count = F('likes_count') + 1
            feed.save(update_fields=['likes_count'])
            feed.refresh_from_db()

            return Response({
                'message': '피드에 좋아요를 표시했습니다.',
                'likes_count': feed.likes_count
            }, status=status.HTTP_201_CREATED)

        return Response({
            'message': '이미 이 피드에 좋아요를 표시했습니다.',
            'likes_count': feed.likes_count
        }, status=status.HTTP_200_OK)

    except Feed.DoesNotExist:
        return Response({'error': '피드를 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 피드 좋아요 취소
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def unlike_feed(request, feed_id):
    """
    피드 좋아요를 취소하는 API
    """
    try:
        feed = Feed.objects.get(id=feed_id)

        try:
            like = FeedLike.objects.get(user=request.user, feed=feed)
            like.delete()

            if feed.likes_count > 0:
                feed.likes_count = F('likes_count') - 1
                feed.save(update_fields=['likes_count'])
                feed.refresh_from_db()

            return Response({
                'message': '피드 좋아요를 취소했습니다.',
                'likes_count': feed.likes_count
            }, status=status.HTTP_200_OK)

        except FeedLike.DoesNotExist:
            return Response({
                'message': '이 피드에 좋아요가 없습니다.',
                'likes_count': feed.likes_count
            }, status=status.HTTP_200_OK)

    except Feed.DoesNotExist:
        return Response({'error': '피드를 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 피드 북마크
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def bookmark_feed(request, feed_id):
    """
    피드를 북마크하는 API
    """
    try:
        feed = Feed.objects.get(id=feed_id)

        # 이미 북마크 했는지 확인
        bookmark, created = FeedBookmark.objects.get_or_create(user=request.user, feed=feed)

        if created:
            feed.bookmarks_count = F('bookmarks_count') + 1
            feed.save(update_fields=['bookmarks_count'])
            feed.refresh_from_db()

            return Response({
                'message': '피드를 북마크했습니다.',
                'bookmarks_count': feed.bookmarks_count
            }, status=status.HTTP_201_CREATED)

        return Response({
            'message': '이미 이 피드를 북마크했습니다.',
            'bookmarks_count': feed.bookmarks_count
        }, status=status.HTTP_200_OK)

    except Feed.DoesNotExist:
        return Response({'error': '피드를 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 피드 북마크 취소
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def unbookmark_feed(request, feed_id):
    """
    피드 북마크를 취소하는 API
    """
    try:
        feed = Feed.objects.get(id=feed_id)

        try:
            bookmark = FeedBookmark.objects.get(user=request.user, feed=feed)
            bookmark.delete()

            if feed.bookmarks_count > 0:
                feed.bookmarks_count = F('bookmarks_count') - 1
                feed.save(update_fields=['bookmarks_count'])
                feed.refresh_from_db()

            return Response({
                'message': '피드 북마크를 취소했습니다.',
                'bookmarks_count': feed.bookmarks_count
            }, status=status.HTTP_200_OK)

        except FeedBookmark.DoesNotExist:
            return Response({
                'message': '이 피드에 북마크가 없습니다.',
                'bookmarks_count': feed.bookmarks_count
            }, status=status.HTTP_200_OK)

    except Feed.DoesNotExist:
        return Response({'error': '피드를 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 피드 댓글 목록
@api_view(['GET'])
def feed_comments(request, feed_id):
    """
    특정 피드의 댓글 목록을 조회하는 API
    """
    try:
        feed = Feed.objects.get(id=feed_id)

        # 비공개 피드 권한 체크
        if feed.visibility == 'private' and (not request.user.is_authenticated or feed.user != request.user):
            return Response({'error': '이 피드의 댓글을 볼 수 있는 권한이 없습니다.'}, status=status.HTTP_403_FORBIDDEN)

        # 댓글 조회
        comments = FeedComment.objects.filter(feed=feed).order_by('-created_at')

        # 페이지네이션 적용
        page = int(request.query_params.get('page', 1))
        limit = int(request.query_params.get('limit', 20))
        start = (page - 1) * limit
        end = page * limit

        serializer = FeedCommentSerializer(
            comments[start:end], 
            many=True, 
            context={'request': request}
        )

        return Response({
            'comments': serializer.data,
            'total': comments.count(),
            'page': page,
            'limit': limit
        }, status=status.HTTP_200_OK)

    except Feed.DoesNotExist:
        return Response({'error': '피드를 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 댓글 생성
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_comment(request, feed_id):
    """
    특정 피드에 댓글을 작성하는 API
    """
    try:
        feed = Feed.objects.get(id=feed_id)

        # 비공개 피드 권한 체크
        if feed.visibility == 'private' and feed.user != request.user:
            return Response({'error': '이 피드에 댓글을 작성할 권한이 없습니다.'}, status=status.HTTP_403_FORBIDDEN)

        content = request.data.get('content')
        if not content:
            return Response({'error': '댓글 내용을 입력해주세요.'}, status=status.HTTP_400_BAD_REQUEST)

        # 댓글 생성
        comment = FeedComment.objects.create(
            feed=feed,
            user=request.user,
            content=content
        )

        serializer = FeedCommentSerializer(comment, context={'request': request})
        return Response(serializer.data, status=status.HTTP_201_CREATED)

    except Feed.DoesNotExist:
        return Response({'error': '피드를 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 댓글 삭제
@api_view(['DELETE'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def delete_comment(request, comment_id):
    """
    특정 댓글을 삭제하는 API
    """
    try:
        comment = FeedComment.objects.get(id=comment_id)

        # 댓글 작성자 또는 피드 작성자만 삭제 가능
        if comment.user != request.user and comment.feed.user != request.user:
            return Response({'error': '댓글을 삭제할 권한이 없습니다.'}, status=status.HTTP_403_FORBIDDEN)

        comment.delete()
        return Response({'message': '댓글이 삭제되었습니다.'}, status=status.HTTP_200_OK)

    except FeedComment.DoesNotExist:
        return Response({'error': '댓글을 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 댓글 좋아요
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def like_comment(request, comment_id):
    """
    특정 댓글에 좋아요를 추가하는 API
    """
    try:
        comment = FeedComment.objects.get(id=comment_id)

        # 이미 좋아요 했는지 확인
        like, created = CommentLike.objects.get_or_create(user=request.user, comment=comment)

        if created:
            comment.likes_count = F('likes_count') + 1
            comment.save(update_fields=['likes_count'])
            comment.refresh_from_db()

            return Response({
                'message': '댓글에 좋아요를 표시했습니다.',
                'likes_count': comment.likes_count
            }, status=status.HTTP_201_CREATED)

        return Response({
            'message': '이미 이 댓글에 좋아요를 표시했습니다.',
            'likes_count': comment.likes_count
        }, status=status.HTTP_200_OK)

    except FeedComment.DoesNotExist:
        return Response({'error': '댓글을 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 댓글 좋아요 취소
@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def unlike_comment(request, comment_id):
    """
    특정 댓글의 좋아요를 취소하는 API
    """
    try:
        comment = FeedComment.objects.get(id=comment_id)

        try:
            like = CommentLike.objects.get(user=request.user, comment=comment)
            like.delete()

            if comment.likes_count > 0:
                comment.likes_count = F('likes_count') - 1
                comment.save(update_fields=['likes_count'])
                comment.refresh_from_db()

            return Response({
                'message': '댓글 좋아요를 취소했습니다.',
                'likes_count': comment.likes_count
            }, status=status.HTTP_200_OK)

        except CommentLike.DoesNotExist:
            return Response({
                'message': '이 댓글에 좋아요가 없습니다.',
                'likes_count': comment.likes_count
            }, status=status.HTTP_200_OK)

    except FeedComment.DoesNotExist:
        return Response({'error': '댓글을 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 주변 피드 조회 (위치 기반)
@api_view(['GET'])
def nearby_feeds(request):
    """
    사용자의 현재 위치를 기준으로 반경 내 공개된 피드를 조회하는 API
    """
    try:
        latitude = request.query_params.get('latitude')
        longitude = request.query_params.get('longitude')

        if not latitude or not longitude:
            return Response({'error': '위치 정보가 필요합니다.'}, status=status.HTTP_400_BAD_REQUEST)

        radius = float(request.query_params.get('radius', 10.0))

        user_location = Point(float(longitude), float(latitude))

        feeds = Feed.objects.filter(
            visibility='public',
            location__distance_lte=(user_location, D(km=radius))
        ).annotate(
            distance=Distance('location', user_location)
        ).order_by('distance')

        # 페이지네이션 적용
        page = int(request.query_params.get('page', 1))
        limit = int(request.query_params.get('limit', 10))
        start = (page - 1) * limit
        end = page * limit

        serializer = FeedSerializer(
            feeds[start:end], 
            many=True, 
            context={'request': request}
        )

        return Response({
            'feeds': serializer.data,
            'total': feeds.count(),
            'page': page,
            'limit': limit
        }, status=status.HTTP_200_OK)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 특정 사용자의 피드 목록
@api_view(['GET'])
def user_feeds(request, user_id):
    """
    특정 사용자의 피드 목록을 조회하는 API
    """
    try:
        user = User.objects.get(id=user_id)

        # 계정 공개 여부 확인
        if user.account_visibility == 'private' and (not request.user.is_authenticated or request.user.id != user.id):
            return Response({'error': '비공개 계정의 피드를 볼 수 없습니다.'}, status=status.HTTP_403_FORBIDDEN)

        # 해당 사용자의 피드 조회 (비공개 설정 적용)
        if request.user.is_authenticated and request.user.id == user.id:
            feeds = Feed.objects.filter(user=user).order_by('-created_at')
        else:
            feeds = Feed.objects.filter(user=user, visibility='public').order_by('-created_at')

        # 페이지네이션 적용
        page = int(request.query_params.get('page', 1))
        limit = int(request.query_params.get('limit', 10))
        start = (page - 1) * limit
        end = page * limit

        serializer = FeedSerializer(
            feeds[start:end], 
            many=True, 
            context={'request': request}
        )

        return Response({
            'feeds': serializer.data,
            'total': feeds.count(),
            'page': page,
            'limit': limit,
            'username': user.username,
            'profile_image': user.profile_image
        }, status=status.HTTP_200_OK)

    except User.DoesNotExist:
        return Response({'error': '사용자를 찾을 수 없습니다.'}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 북마크한 피드 목록
@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def bookmarked_feeds(request):
    """
    사용자가 북마크한 피드 목록을 조회하는 API
    """
    try:
        # 사용자가 북마크한 피드 ID 목록 조회
        bookmarked_feed_ids = FeedBookmark.objects.filter(
            user=request.user
        ).values_list('feed_id', flat=True)

        # 해당 피드 조회
        feeds = Feed.objects.filter(
            id__in=bookmarked_feed_ids
        ).order_by('-created_at')

        # 페이지네이션 적용
        page = int(request.query_params.get('page', 1))
        limit = int(request.query_params.get('limit', 10))
        start = (page - 1) * limit
        end = page * limit

        serializer = FeedSerializer(
            feeds[start:end], 
            many=True, 
            context={'request': request}
        )

        return Response({
            'feeds': serializer.data,
            'total': feeds.count(),
            'page': page,
            'limit': limit
        }, status=status.HTTP_200_OK)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

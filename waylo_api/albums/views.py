from django.conf import settings
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from .models import Album

@api_view(['GET'])
def get_album_info(request, user_id):
    """
    앨범 정보를 조회 API
    """
    try:
        album = Album.objects.get(user_id=user_id)
        return Response({
            'user_id': str(album.user.id),
            'background_color': album.background_color,  # 배경 색상
            'background_pattern': album.background_pattern,  # 배경 패턴
            'created_at': album.created_at.isoformat(),  # 생성 시간
        })
    except Album.DoesNotExist:
        return Response({'error': 'Album not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception:
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PATCH'])
def update_album_info(request, user_id):
    """
    앨범 정보 업데이트 API
    """
    try:
        album = get_object_or_404(Album, user_id=user_id)

        album.background_color = request.data.get("background_color", album.background_color)
        album.background_pattern = request.data.get("background_pattern", album.background_pattern)

        album.save()

        return Response({
            "message": "Album updated successfully",
            "album_id": str(album.id),
            "user_id": str(album.user.id),
            "background_color": album.background_color,
            "background_pattern": album.background_pattern,
            "created_at": album.created_at.strftime("%Y-%m-%d %H:%M:%S")
        }, status=status.HTTP_200_OK)

    except Exception:
        return Response({"error": "Server Error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

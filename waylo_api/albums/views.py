from django.conf import settings
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Album
from django.shortcuts import get_object_or_404
from .models import Album

@api_view(['GET'])
def get_album_info(request, user_id):
    try:
        album = Album.objects.get(user_id=user_id)  # user_id로 Album 조회
        return Response({
            'user_id': str(album.user.id),
            'background_color': album.background_color,
            'background_pattern': album.background_pattern,
            'created_at': album.created_at.isoformat(),  # 안전하게 문자열 변환
        })
    except Album.DoesNotExist:
        return Response({'error': 'Album not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['PATCH'])
def update_album_info(request, user_id):
    try:
        album = get_object_or_404(Album, user_id=user_id)

        # 요청 데이터에서 필드 가져오기
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

    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return Response({"error": "Server Error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Album
from users.models import User  # 사용자 모델 임포트

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

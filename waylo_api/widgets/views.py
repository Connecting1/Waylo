import logging
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Widget
from .serializers import WidgetSerializer
from albums.models import Album  # 앨범 모델 임포트

logger = logging.getLogger(__name__)

@api_view(['GET'])
def get_album_widgets(request, user_id):
    """앨범에 속한 모든 위젯 조회"""
    try:
        # 사용자의 앨범 찾기
        album = Album.objects.get(user_id=user_id)
        widgets = Widget.objects.filter(album=album)
        
        # 위젯 목록 반환
        return Response({
            'widgets': [
                {
                    'id': str(widget.id),
                    'type': widget.type,
                    'x': widget.x,
                    'y': widget.y,
                    'width': widget.width,
                    'height': widget.height,
                    'extra_data': widget.extra_data,
                    'created_at': widget.created_at
                } for widget in widgets
            ]
        })
    except Album.DoesNotExist:
        return Response({'error': 'Album not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
def create_widget(request, user_id):
    """새 위젯 생성"""
    try:
        # 사용자의 앨범 찾기
        album = Album.objects.get(user_id=user_id)
        
        # 위젯 생성
        widget = Widget.objects.create(
            album=album,
            type=request.data.get('type'),
            x=float(request.data.get('x', 0)),
            y=float(request.data.get('y', 0)),
            width=float(request.data.get('width', 100)),
            height=float(request.data.get('height', 100)),
            extra_data=request.data.get('extra_data', {})
        )
        
        # 생성된 위젯 반환
        return Response({
            'widget': {
                'id': str(widget.id),
                'type': widget.type,
                'x': widget.x,
                'y': widget.y,
                'width': widget.width,
                'height': widget.height,
                'extra_data': widget.extra_data,
                'created_at': widget.created_at
            }
        }, status=status.HTTP_201_CREATED)
    except Album.DoesNotExist:
        return Response({'error': 'Album not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['PATCH'])
def update_widget(request, user_id, widget_id):
    """위젯 업데이트"""
    try:
        # 사용자의 앨범 찾기
        album = Album.objects.get(user_id=user_id)
        widget = Widget.objects.get(id=widget_id, album=album)
        
        # 업데이트할 필드 처리
        update_fields = ['type', 'x', 'y', 'width', 'height', 'extra_data']
        for field in update_fields:
            value = request.data.get(field)
            if value is not None:  # None이 아닐 때만 업데이트
                if field in ['x', 'y', 'width', 'height']:
                    value = float(value)
                setattr(widget, field, value)
        
        widget.save()
        
        # 업데이트된 위젯 반환
        return Response({
            'id': str(widget.id),
            'type': widget.type,
            'x': widget.x,
            'y': widget.y,
            'width': widget.width,
            'height': widget.height,
            'extra_data': widget.extra_data,
            'created_at': widget.created_at
        })
    except Album.DoesNotExist:
        return Response({'error': 'Album not found'}, status=status.HTTP_404_NOT_FOUND)
    except Widget.DoesNotExist:
        return Response({'error': 'Widget not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"Unexpected error: {e}")
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['DELETE'])
def delete_widget(request, user_id, widget_id):
    """위젯 삭제"""
    try:
        # 사용자의 앨범 찾기
        album = Album.objects.get(user_id=user_id)
        widget = Widget.objects.get(id=widget_id, album=album)
        
        # 위젯 삭제
        widget.delete()
        
        return Response({'message': 'Widget deleted successfully'}, status=status.HTTP_204_NO_CONTENT)
    except Album.DoesNotExist:
        return Response({'error': 'Album not found'}, status=status.HTTP_404_NOT_FOUND)
    except Widget.DoesNotExist:
        return Response({'error': 'Widget not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"❌ Unexpected error: {e}")
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

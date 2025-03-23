import logging
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .models import Widget
from .serializers import WidgetSerializer
from albums.models import Album  # 앨범 모델 임포트

logger = logging.getLogger(__name__)

# 앨범 위젯 목록 조회
@api_view(['GET'])
def get_album_widgets(request, user_id):
    """
    특정 사용자의 앨범에 속한 모든 위젯을 조회하는 API
    """
    try:
        album = Album.objects.get(user_id=user_id)
        widgets = Widget.objects.filter(album=album)

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
    except Exception:
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 위젯 생성
@api_view(['POST'])
def create_widget(request, user_id):
    """
    특정 사용자의 앨범에 새 위젯을 생성하는 API
    """
    try:
        album = Album.objects.get(user_id=user_id)

        widget = Widget.objects.create(
            album=album,
            type=request.data.get('type'),
            x=float(request.data.get('x', 0)),
            y=float(request.data.get('y', 0)),
            width=float(request.data.get('width', 100)),
            height=float(request.data.get('height', 100)),
            extra_data=request.data.get('extra_data', {})
        )

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
    except Exception:
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 위젯 업데이트
@api_view(['PATCH'])
def update_widget(request, user_id, widget_id):
    """
    특정 사용자의 앨범 내 위젯을 업데이트하는 API
    """
    try:
        album = Album.objects.get(user_id=user_id)
        widget = Widget.objects.get(id=widget_id, album=album)

        update_fields = ['type', 'x', 'y', 'width', 'height', 'extra_data']
        for field in update_fields:
            value = request.data.get(field)
            if value is not None:
                if field in ['x', 'y', 'width', 'height']:
                    value = float(value)
                setattr(widget, field, value)

        widget.save()

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
    except Exception:
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 위젯 삭제
@api_view(['DELETE'])
def delete_widget(request, user_id, widget_id):
    """
    특정 사용자의 앨범 내 위젯을 삭제하는 API
    """
    try:
        album = Album.objects.get(user_id=user_id)
        widget = Widget.objects.get(id=widget_id, album=album)

        widget.delete()

        return Response({'message': 'Widget deleted successfully'}, status=status.HTTP_204_NO_CONTENT)
    except Album.DoesNotExist:
        return Response({'error': 'Album not found'}, status=status.HTTP_404_NOT_FOUND)
    except Widget.DoesNotExist:
        return Response({'error': 'Widget not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception:
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
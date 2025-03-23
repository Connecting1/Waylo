import logging
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view, authentication_classes, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response
from rest_framework import status
from django.db.models import Q, Max, F, Count
from users.authentication import CustomTokenAuthentication
from .models import ChatRoom, ChatMessage

User = get_user_model()
logger = logging.getLogger(__name__)

@api_view(['GET'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def get_chat_rooms(request):
    """
    사용자의 채팅방 목록을 조회하는 API
    """
    try:
        # 사용자가 참여하고 있는 모든 채팅방을 조회
        chat_rooms = ChatRoom.objects.filter(participants=request.user)
        
        # 각 채팅방의 정보를 가공
        rooms_data = []
        for room in chat_rooms:
            # 상대방 정보 가져오기
            other_participant = room.get_other_participant(request.user)
            if not other_participant:
                continue
                
            # 마지막 메시지 가져오기
            last_message = room.messages.last()
            
            # 읽지 않은 메시지 수 계산
            unread_count = room.messages.filter(
                sender=other_participant,
                is_read=False
            ).count()
            
            rooms_data.append({
                'id': str(room.id),
                'friend_id': str(other_participant.id),
                'friend_name': other_participant.username,
                'friend_profile_image': other_participant.profile_image,
                'last_message': last_message.content if last_message else None,
                'last_message_time': last_message.created_at if last_message else None,
                'unread_count': unread_count
            })
            
        return Response({
            'rooms': rooms_data
        })
    except Exception as e:
        logger.error(f"채팅방 목록 조회 중 오류 발생: {e}")
        return Response({"error": "서버 오류가 발생했습니다."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def create_chat_room(request):
    """
    새로운 채팅방을 생성하는 API
    """
    try:
        friend_id = request.data.get('friend_id')
        if not friend_id:
            return Response({"error": "friend_id가 필요합니다."}, status=status.HTTP_400_BAD_REQUEST)
            
        friend = User.objects.get(id=friend_id)
        
        # 이미 존재하는 채팅방 확인
        existing_room = ChatRoom.objects.filter(
            participants=request.user
        ).filter(
            participants=friend
        ).first()
        
        if existing_room:
            return Response({
                'room_id': str(existing_room.id)
            })
            
        # 새로운 채팅방 생성
        chat_room = ChatRoom.objects.create()
        chat_room.participants.add(request.user, friend)
        
        return Response({
            'room_id': str(chat_room.id)
        })
    except User.DoesNotExist:
        return Response({"error": "해당 사용자를 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"채팅방 생성 중 오류 발생: {e}")
        return Response({"error": "서버 오류가 발생했습니다."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

@api_view(['GET', 'POST'])
@authentication_classes([CustomTokenAuthentication])
@permission_classes([IsAuthenticated])
def chat_messages(request, room_id):
    """
    채팅방의 메시지 목록을 조회하거나 새 메시지를 전송하는 API
    """
    try:
        chat_room = ChatRoom.objects.get(id=room_id)
        if request.user not in chat_room.participants.all():
            return Response({"error": "접근 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)

        if request.method == 'GET':
            # 상대방이 보낸 메시지를 읽음 처리
            other_participant = chat_room.get_other_participant(request.user)
            ChatMessage.objects.filter(
                room=chat_room,
                sender=other_participant,
                is_read=False
            ).update(is_read=True)
            
            # 메시지 목록 조회
            messages = chat_room.messages.select_related('sender').order_by('created_at')
            messages_data = [{
                'id': str(msg.id),
                'content': msg.content,
                'created_at': msg.created_at.isoformat(),
                'is_mine': msg.sender == request.user,
                'is_read': msg.is_read
            } for msg in messages]
            
            return Response({
                'messages': messages_data
            })
        else:  # POST
            content = request.data.get('content', '').strip()
            if not content:
                return Response({"error": "content가 필요합니다."}, status=status.HTTP_400_BAD_REQUEST)
                
            # 메시지 생성
            message = ChatMessage.objects.create(
                room=chat_room,
                sender=request.user,
                content=content
            )
            
            # 채팅방 업데이트 시간 갱신
            chat_room.save()
            
            return Response({
                'message': {
                    'id': str(message.id),
                    'content': message.content,
                    'created_at': message.created_at.isoformat(),
                    'is_mine': True,
                    'is_read': False
                }
            })
            
    except ChatRoom.DoesNotExist:
        return Response({"error": "채팅방을 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        logger.error(f"채팅 관련 작업 중 오류 발생: {e}")
        return Response({"error": "서버 오류가 발생했습니다."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
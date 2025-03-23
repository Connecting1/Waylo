import logging
import uuid
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from django.shortcuts import get_object_or_404
from django.db.models import Q
from .models import FriendRequest, Friendship

User = get_user_model()
logger = logging.getLogger(__name__)

@api_view(['POST'])
def send_friend_request_view(request):
    """
    친구 요청을 보내는 API
    """
    logger.info(f"요청 데이터: {request.data}")  

    try:
        from_user_id = request.data.get("from_user")
        to_user_id = request.data.get("to_user")

        if not from_user_id or not to_user_id:
            return Response({"error": "from_user와 to_user가 필요합니다."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            from_user_id = uuid.UUID(from_user_id)
            to_user_id = uuid.UUID(to_user_id)
        except ValueError:
            return Response({"error": "잘못된 사용자 ID 형식입니다."}, status=status.HTTP_400_BAD_REQUEST)

        try:
            from_user = User.objects.get(id=from_user_id)
            to_user = User.objects.get(id=to_user_id)
        except User.DoesNotExist:
            return Response({"error": "해당 사용자를 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)

        # 자기 자신에게 요청을 보내는지 확인
        if from_user_id == to_user_id:
            return Response({"error": "자기 자신에게는 친구 요청을 보낼 수 없습니다."}, status=status.HTTP_400_BAD_REQUEST)

        # 이미 친구인지 확인
        if Friendship.objects.filter(
            Q(user1=from_user, user2=to_user) | Q(user1=to_user, user2=from_user)
        ).exists():
            return Response({"error": "이미 친구 관계입니다."}, status=status.HTTP_400_BAD_REQUEST)

        # 기존 친구 요청 확인
        existing_request = FriendRequest.objects.filter(from_user=from_user, to_user=to_user).first()
        
        if existing_request:
            if existing_request.status == 'pending':
                return Response({"error": "이미 대기 중인 친구 요청이 있습니다."}, status=status.HTTP_400_BAD_REQUEST)
            elif existing_request.status == 'accepted':
                return Response({"error": "이미 수락된 친구 요청입니다."}, status=status.HTTP_400_BAD_REQUEST)
            else:  # status == 'rejected'
                existing_request.status = 'pending'
                existing_request.save()
                return Response({
                    "message": "친구 요청이 다시 전송되었습니다.",
                    "friend_request_id": str(existing_request.id)
                }, status=status.HTTP_200_OK)

        # 새로운 친구 요청 생성
        friend_request = FriendRequest.objects.create(
            from_user=from_user,
            to_user=to_user,
            status='pending'
        )

        return Response({
            "message": "친구 요청이 보내졌습니다.",
            "friend_request_id": str(friend_request.id)
        }, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"친구 요청 처리 중 오류: {e}")
        return Response({"error": "서버 오류"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_friend_requests_view(request):
    """
    사용자가 받은 친구 요청 목록을 조회하는 API
    """
    try:
        if not request.user.is_authenticated:
            return Response({"error": "인증된 사용자가 아닙니다."}, status=status.HTTP_401_UNAUTHORIZED)
        
        received_requests = FriendRequest.objects.filter(
            to_user=request.user, status='pending'
        ).select_related('from_user')

        requests_data = [{
            'id': str(req.id),
            'from_user_id': str(req.from_user.id),
            'from_user_name': req.from_user.username,
            'from_user_profile_image': req.from_user.profile_image,
            'created_at': req.created_at
        } for req in received_requests]

        return Response({'requests': requests_data}, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"친구 요청 목록 조회 오류: {e}")
        return Response({"error": "서버 오류"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
def accept_friend_request_view(request):
    """
    친구 요청을 수락하는 API
    """
    try:
        if not request.user.is_authenticated:
            return Response({"error": "인증된 사용자가 아닙니다."}, status=status.HTTP_401_UNAUTHORIZED)

        request_id = request.data.get('request_id')
        if not request_id:
            return Response({"error": "request_id가 필요합니다."}, status=status.HTTP_400_BAD_REQUEST)
        
        # 디버깅을 위한 추가 로그
        logger.error(f"처리 시작: 요청 ID={request_id}, 사용자 ID={request.user.id}")
        
        try:
            friend_request = FriendRequest.objects.get(pk=request_id)
            logger.error(f"요청 조회 성공: {friend_request.id}")
        except FriendRequest.DoesNotExist:
            logger.error(f"요청을 찾을 수 없음: {request_id}")
            return Response({"error": "해당 요청을 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)
        
        # 권한 검사
        if str(request.user.id) != str(friend_request.to_user.id):
            logger.error(f"권한 없음: 요청자={request.user.id}, 요청 받은 사용자={friend_request.to_user.id}")
            return Response({"error": "이 요청을 수락할 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)

        # 상태 검사 
        if friend_request.status != 'pending':
            logger.error(f"요청 상태 오류: {friend_request.status}")
            return Response({"error": f"요청을 처리할 수 없습니다 (상태: {friend_request.status})"}, status=status.HTTP_400_BAD_REQUEST)
        
        # 기존 친구 관계 확인
        existing_friendship = Friendship.objects.filter(
            Q(user1=friend_request.from_user, user2=friend_request.to_user) | 
            Q(user1=friend_request.to_user, user2=friend_request.from_user)
        ).first()
        
        if existing_friendship:
            logger.error(f"이미 친구 관계 존재: {existing_friendship.id}")
            # 요청 자체는 accepted로 변경
            friend_request.status = 'accepted'
            friend_request.save()
            return Response({
                "message": "이미 친구 관계가 존재합니다.",
                "friendship_id": str(existing_friendship.id)
            }, status=status.HTTP_200_OK)
        
        # 직접 처리하여 오류 가능성 줄이기
        try:
            # 요청 상태 변경
            friend_request.status = 'accepted'
            friend_request.save()
            logger.error(f"요청 상태 변경 성공: {friend_request.status}")
            
            # 친구 관계 생성
            friendship = Friendship.objects.create(
                user1=friend_request.from_user,
                user2=friend_request.to_user
            )
            logger.error(f"친구 관계 생성 성공: {friendship.id}")
            
            return Response({
                "message": "친구 요청을 수락하고 친구 관계가 생성되었습니다.",
                "friendship_id": str(friendship.id)
            }, status=status.HTTP_200_OK)
        except Exception as inner_e:
            logger.error(f"처리 중 내부 오류: {inner_e}")
            return Response({"error": "친구 관계 생성 중 오류가 발생했습니다."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    except Exception as e:
        logger.error(f"친구 요청 수락 오류: {e}")
        return Response({"error": "서버 오류"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(["POST"])
def reject_friend_request_view(request):
    """
    친구 요청을 거절하는 API
    """
    try:
        if not request.user.is_authenticated:
            return Response({"error": "인증된 사용자가 아닙니다."}, status=status.HTTP_401_UNAUTHORIZED)

        request_id = request.data.get('request_id')
        if not request_id:
            return Response({"error": "request_id가 필요합니다."}, status=status.HTTP_400_BAD_REQUEST)

        friend_request = get_object_or_404(FriendRequest, pk=request_id)
        
        # 권한 검사 추가: 요청을 받은 사용자만 거절할 수 있음
        if str(request.user.id) != str(friend_request.to_user.id):
            return Response({"error": "이 요청을 거절할 권한이 없습니다."}, status=status.HTTP_403_FORBIDDEN)
        
        friend_request.reject()

        return Response({"message": "요청을 거절했습니다."}, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"친구 요청 거절 오류: {e}")
        return Response({"error": "서버 오류"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_friends_info(request, user_id):
    """
    특정 사용자의 친구 목록을 조회하는 API
    """
    try:
        if not request.user.is_authenticated:
            return Response({"error": "인증된 사용자가 아닙니다."}, status=status.HTTP_401_UNAUTHORIZED)

        friendships = Friendship.objects.filter(
            Q(user1_id=user_id) | Q(user2_id=user_id)
        ).select_related('user1', 'user2')

        friends_list = [{
            'id': str(friend.id),
            'username': friend.username,
            'profile_image': friend.profile_image,
            'friendship_date': friendship.created_at
        } for friendship in friendships for friend in [friendship.user2 if str(friendship.user1.id) == str(user_id) else friendship.user1]]

        return Response({
            'friend_count': len(friends_list),
            'friends': friends_list
        }, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"친구 목록 조회 오류: {e}")
        return Response({"error": "서버 오류"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


@api_view(['GET'])
def get_sent_friend_requests_view(request):
    """
    사용자가 보낸 친구 요청 목록을 조회하는 API
    """
    try:
        if not request.user.is_authenticated:
            return Response({"error": "인증된 사용자가 아닙니다."}, status=status.HTTP_401_UNAUTHORIZED)

        sent_requests = FriendRequest.objects.filter(
            from_user=request.user, status='pending'
        ).select_related('to_user')

        requests_data = [{
            'id': str(req.id),
            'to_user_id': str(req.to_user.id),
            'to_user_name': req.to_user.username,
            'to_user_profile_image': req.to_user.profile_image,
            'created_at': req.created_at
        } for req in sent_requests]

        return Response({'requests': requests_data}, status=status.HTTP_200_OK)

    except Exception as e:
        logger.error(f"보낸 친구 요청 조회 오류: {e}")
        return Response({"error": "서버 오류"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)
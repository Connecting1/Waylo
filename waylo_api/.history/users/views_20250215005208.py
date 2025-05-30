import logging
from django.contrib.auth.hashers import check_password
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .serializers import UserSerializer
from django.db.models import Q
from users.models import User

User = get_user_model()

logger = logging.getLogger(__name__)

@api_view(['POST'])
def user_create_view(request):
    logger.info(f"🔵 요청 데이터: {request.data}")  
    serializer = UserSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.save()
        logger.info(f"✅ 저장 성공! ID: {user.id}")  
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    logger.error(f"❌ 저장 실패! 오류: {serializer.errors}")  
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)







@api_view(["POST"])
def user_login_view(request):
    print(f"🔵 사용자 조회 요청 데이터: {request.data}")  
    user_id = request.data.get('id')

    if not user_id:
        print("❌ ID 없음")
        return Response({"error": "ID is required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(id=user_id)
        serializer = UserSerializer(user)
        print(f"✅ 사용자 조회 성공: ID {user_id}")
        return Response(serializer.data, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        print(f"❌ 사용자 찾을 수 없음: ID {user_id}")
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)


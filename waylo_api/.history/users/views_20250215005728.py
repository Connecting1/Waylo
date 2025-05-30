import logging
from django.contrib.auth.hashers import check_password
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .serializers import UserSerializer
from django.db import connection
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
    print(f"🔵 모든 사용자 조회 요청 데이터: {request.data}")  

    # 데이터베이스 연결 확인
    if connection.ensure_connection():
        print("✅ 데이터베이스 연결 성공")
    else:
        print("❌ 데이터베이스 연결 실패")

    users = User.objects.all()  # 모든 사용자 가져오기
    serializer = UserSerializer(users, many=True)

    print("✅ 사용자 조회 완료")
    return Response(serializer.data, status=status.HTTP_200_OK)
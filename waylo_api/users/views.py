import logging
from django.contrib.auth.hashers import check_password
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from .serializers import UserSerializer
from django.db import connection

# 중복 제거: get_user_model()을 한 번만 정의
User = get_user_model()

logger = logging.getLogger(__name__)

@api_view(['POST'])
def user_create_view(request):
    logger.info(f"🔵 요청 데이터: {request.data}")  
    serializer = UserSerializer(data=request.data)

    if serializer.is_valid():
        user = serializer.save()
        logger.info(f"저장 성공! ID: {user.id}")  
        return Response(serializer.data, status=status.HTTP_201_CREATED)
    
    logger.error(f"저장 실패! 오류: {serializer.errors}")  
    return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)







@api_view(['POST'])
def user_login_view(request):
    print(f"🔵 로그인 요청 데이터: {request.data}")

    try:
        connection.ensure_connection()
        print("데이터베이스 연결 성공")
    except Exception as e:
        print(f"데이터베이스 연결 실패: {e}")
        return Response({"error": f"Database connection failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    email = request.data.get("email")
    password = request.data.get("password")

    if not email or not password:
        return Response({"error": "이메일과 비밀번호를 입력하세요."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
        print(f"이메일 확인 완료: {email}")
    except User.DoesNotExist:
        print("이메일을 찾을 수 없습니다.")
        return Response({"error": "이메일을 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)

    is_password_correct = user.check_password(password)
    print(f"🔍 입력한 비밀번호 검증 결과: {is_password_correct}")

    if is_password_correct:
        print("비밀번호가 일치합니다. 로그인 성공!")
        
        auth_token = "sample_token_12345"  # Flutter에서 필요로 하는 auth_token 추가

        return Response({"auth_token": auth_token}, status=status.HTTP_200_OK)
    else:
        print("비밀번호가 일치하지 않습니다.")
        return Response({"error": "비밀번호가 일치하지 않습니다."}, status=status.HTTP_401_UNAUTHORIZED)

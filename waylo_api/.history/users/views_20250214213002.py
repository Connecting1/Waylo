import logging
from django.contrib.auth.hashers import check_password
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view
from rest_framework.response import Response
from rest_framework import status
from users.models import CustomToken  # ✅ models.py에서 CustomToken을 가져옴
from .serializers import UserSerializer
from django.shortcuts import get_object_or_404

User = get_user_model'users', 'User')

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


@api_view(['POST'])
def user_login_view(request):
    email = request.data.get('email')
    password = request.data.get('password')

    logger.info(f"🔵 로그인 요청: 이메일={email}")
    logger.info(f"🔵 받은 데이터: {request.data}")
    email = request.data.get("email")
    logger.info(f"🔵 추출된 이메일: {email}")
    try:
        # `filter()`를 사용하여 이메일로 유저 찾기 (get_object_or_404() 대신)
        user = User.objects.filter(email=email).first()  # `first()`로 첫 번째 유저만 반환

        if user is None:
            logger.error(f"❌ 로그인 실패: 데이터베이스에서 유저를 찾을 수 없음. 입력한 이메일={email}")
        else:
            logger.info(f"✅ 유저 찾음: {user.email}")
        
        if user:
            logger.info(f"유저 이메일: {user.email}")
            logger.info(f"입력된 비밀번호: {password}")
            logger.info(f"저장된 해시 비밀번호: {user.password}")

            # 비밀번호 검증
            password_check = check_password(password, user.password)
            logger.info(f"비밀번호 검증 결과: {password_check}")

            if password_check:
                token, created = CustomToken.objects.get_or_create(user=user)
                logger.info(f"✅ 로그인 성공! 이메일={email}, 토큰={token.key}")
                return Response({"auth_token": token.key}, status=status.HTTP_200_OK)
            else:
                logger.warning(f"❌ 로그인 실패: 비밀번호 불일치. 이메일={email}")
        else:
            logger.warning(f"❌ 로그인 실패: 데이터베이스에서 유저를 찾을 수 없음. 이메일={email}")
    except Exception as e:
        logger.error(f"❌ 로그인 중 예외 발생: {str(e)}")

    logger.warning(f"❌ 로그인 실패: 잘못된 이메일 또는 비밀번호. 이메일={email}")
    return Response({"error": "Invalid credentials"}, status=status.HTTP_401_UNAUTHORIZED)

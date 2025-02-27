import logging
import os
import posixpath
from django.contrib.auth.hashers import check_password
from django.contrib.auth import get_user_model
from rest_framework.decorators import api_view, parser_classes
from rest_framework.parsers import MultiPartParser
from rest_framework.response import Response
from rest_framework import status
from .serializers import UserSerializer
from django.db import connection
from django.core.files.storage import default_storage
from django.core.files.base import ContentFile
from django.conf import settings
from .models import User


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
    email = request.data.get("email")
    password = request.data.get("password")

    if not email or not password:
        return Response({"error": "이메일과 비밀번호를 입력하세요."}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
    except User.DoesNotExist:
        return Response({"error": "이메일을 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)

    if user.check_password(password):
        auth_token = "sample_token_12345"  # 실제 토큰 생성 로직 필요
        return Response({
            "auth_token": auth_token,
            "user_id": str(user.id)  # ✅ 로그인 응답에 user_id 추가
        }, status=status.HTTP_200_OK)
    else:
        return Response({"error": "비밀번호가 일치하지 않습니다."}, status=status.HTTP_401_UNAUTHORIZED)


@api_view(['GET'])
def get_user_info(request, user_id):  # ✅ user_id를 URL에서 받음
    try:
        user = User.objects.get(id=user_id)  # user_id로 유저 조회
        return Response({
            'username': user.username,
            'profile_image': user.profile_image,
            'email': user.email,
            'gender': user.gender,
            'phone_number': user.phone_number,
            'created_at': user.created_at,
            'account_visibility': user.account_visibility,  # ✅ 새 필드 추가
        })
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return Response({'error': 'Server Error'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)



@api_view(['PATCH'])
@parser_classes([MultiPartParser])
def update_user_info(request, user_id):
    try:
        user = User.objects.get(id=user_id)

        # 요청 데이터에서 필드 가져오기
        user.username = request.data.get('username', user.username)
        user.email = request.data.get('email', user.email)
        user.gender = request.data.get('gender', user.gender)
        user.phone_number = request.data.get('phone_number', user.phone_number)
        user.account_visibility = request.data.get('account_visibility', user.account_visibility)

        # ✅ 프로필 사진 처리
        if "file" in request.FILES:
            image_file = request.FILES["file"]
            user_folder = os.path.join(settings.MEDIA_ROOT, str(user.id), "profile")
            file_path = os.path.join(user_folder, "profile.jpg")

            if os.path.exists(user_folder):
                for file_name in os.listdir(user_folder):
                    file_path_to_delete = os.path.join(user_folder, file_name)
                    os.remove(file_path_to_delete)

            os.makedirs(user_folder, exist_ok=True)
            default_storage.save(file_path, ContentFile(image_file.read()))

            image_url = posixpath.join(settings.MEDIA_URL, str(user.id), "profile", "profile.jpg").replace("\\", "/")
            user.profile_image = image_url

        user.save()

        return Response({
            "message": "User info updated successfully",
            "user_id": str(user.id),
            "username": user.username,
            "profile_image": user.profile_image,
            "email": user.email,
            "gender": user.gender,
            "phone_number": user.phone_number,
            "account_visibility": user.account_visibility,
        }, status=status.HTTP_200_OK)

    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        return Response({"error": "Server Error"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

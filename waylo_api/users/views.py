import logging
import os
import posixpath
from .models import User, CustomToken
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

# 사용자 생성
@api_view(['POST'])
def user_create_view(request):
    """
    새로운 사용자를 생성하는 API
    """
    try:
        serializer = UserSerializer(data=request.data)
        if serializer.is_valid():
            user = serializer.save()
            return Response(serializer.data, status=status.HTTP_201_CREATED)
        return Response(serializer.errors, status=status.HTTP_400_BAD_REQUEST)
    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 사용자 로그인
@api_view(['POST'])
def user_login_view(request):
    """
    사용자가 로그인하여 인증 토큰을 받는 API
    """
    try:
        email = request.data.get("email")
        password = request.data.get("password")

        if not email or not password:
            return Response({"error": "이메일과 비밀번호를 입력하세요."}, status=status.HTTP_400_BAD_REQUEST)

        user = User.objects.get(email=email)
        if user.check_password(password):
            token, _ = CustomToken.objects.get_or_create(user=user)
            return Response({
                "auth_token": token.key,
                "user_id": str(user.id)
            }, status=status.HTTP_200_OK)

        return Response({"error": "비밀번호가 일치하지 않습니다."}, status=status.HTTP_401_UNAUTHORIZED)

    except User.DoesNotExist:
        return Response({"error": "이메일을 찾을 수 없습니다."}, status=status.HTTP_404_NOT_FOUND)

    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 사용자 정보 조회
@api_view(['GET'])
def get_user_info(request, user_id):
    """
    특정 사용자의 정보를 조회하는 API
    """
    try:
        user = User.objects.get(id=user_id)
        return Response({
            'username': user.username,
            'profile_image': user.profile_image,
            'email': user.email,
            'gender': user.gender,
            'phone_number': user.phone_number,
            'created_at': user.created_at,
            'account_visibility': user.account_visibility
        })
    except User.DoesNotExist:
        return Response({'error': 'User not found'}, status=status.HTTP_404_NOT_FOUND)
    except Exception:
        return Response({'error': '서버 오류가 발생했습니다.'}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 사용자 정보 업데이트
@api_view(['PATCH'])
@parser_classes([MultiPartParser])
def update_user_info(request, user_id):
    """
    특정 사용자의 정보를 업데이트하는 API
    """
    try:
        user = User.objects.get(id=user_id)

        update_fields = ['username', 'email', 'gender', 'phone_number', 'account_visibility']
        for field in update_fields:
            value = request.data.get(field)
            if value is not None:
                setattr(user, field, value)

        if "image" in request.FILES:
            image_file = request.FILES["image"]
            user_folder = os.path.join(settings.MEDIA_ROOT, str(user.id), "profile")
            file_path = os.path.join(user_folder, "profile.jpg")

            if os.path.exists(user_folder):
                for file_name in os.listdir(user_folder):
                    os.remove(os.path.join(user_folder, file_name))

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
        import traceback
        print(f"사용자 정보 업데이트 중 상세 오류: {e}")
        print(f"스택 트레이스: {traceback.format_exc()}")
        return Response({"error": f"서버 오류가 발생했습니다: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 프로필 이미지 업데이트
@api_view(['PATCH'])
@parser_classes([MultiPartParser])
def update_profile_image(request, user_id):
    """
    특정 사용자의 프로필 이미지를 업데이트하는 API
    """
    try:
        user = User.objects.get(id=user_id)

        if "image" in request.FILES:
            image_file = request.FILES["image"]
            user_folder = os.path.join(settings.MEDIA_ROOT, str(user.id), "profile")
            file_path = os.path.join(user_folder, "profile.jpg")

            if os.path.exists(user_folder):
                for file_name in os.listdir(user_folder):
                    os.remove(os.path.join(user_folder, file_name))

            os.makedirs(user_folder, exist_ok=True)
            default_storage.save(file_path, ContentFile(image_file.read()))

            image_url = posixpath.join(settings.MEDIA_URL, str(user.id), "profile", "profile.jpg").replace("\\", "/")
            user.profile_image = image_url
            user.save(update_fields=['profile_image'])

            return Response({
                "message": "Profile image updated successfully",
                "user_id": str(user.id),
                "profile_image": user.profile_image
            }, status=status.HTTP_200_OK)

        return Response({"error": "No image file provided"}, status=status.HTTP_400_BAD_REQUEST)

    except User.DoesNotExist:
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)
    except Exception:
        return Response({"error": "서버 오류가 발생했습니다."}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)


# 사용자 검색
@api_view(['GET'])
def search_users(request):
    """
    사용자명을 기반으로 사용자 검색 API
    """
    prefix = request.query_params.get('prefix', '')

    if not prefix:
        return Response({"error": "검색어를 입력하세요."}, status=status.HTTP_400_BAD_REQUEST)

    users = User.objects.filter(username__istartswith=prefix)

    results = []
    for user in users:
        results.append({
            'id': str(user.id),
            'username': user.username,
            'profile_image': user.profile_image,
            'account_visibility': user.account_visibility
        })

    return Response(results, status=status.HTTP_200_OK)

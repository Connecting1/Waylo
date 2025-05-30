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




@api_view(['POST'])
def user_login_view(request):
    print(f"🔵 로그인 요청 데이터: {request.data}")  

    try:
        connection.ensure_connection()
        print("✅ 데이터베이스 연결 성공")
    except Exception as e:
        print(f"❌ 데이터베이스 연결 실패: {e}")
        return Response({"error": f"Database connection failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

    email = request.data.get('email')

    if not email:
        print("❌ 이메일 없음")
        return Response({"error": "Email is required"}, status=status.HTTP_400_BAD_REQUEST)

    try:
        user = User.objects.get(email=email)
        print(f"user: {user}")
        serializer = UserSerializer(user)

        # 📌 실행된 SQL 로그 확인
        print("📌 실행된 SQL 로그:")
        for query in connection.queries:
            print(query["sql"])  # 실행된 SQL 출력

        print(f"✅ 사용자 데이터 조회 성공: {serializer.data}")  
        return Response(serializer.data, status=status.HTTP_200_OK)
    except User.DoesNotExist:
        print(f"❌ 사용자를 찾을 수 없음: {email}")
        return Response({"error": "User not found"}, status=status.HTTP_404_NOT_FOUND)


# @api_view(['POST'])
# def user_login_view(request):
#     print(f"🔵 로그인 요청 데이터: {request.data}")  

#     # 데이터베이스 연결 확인
#     try:
#         connection.ensure_connection()
#         print("✅ 데이터베이스 연결 성공")
#     except Exception as e:
#         print(f"❌ 데이터베이스 연결 실패: {e}")  # 오류 메시지 출력
#         return Response({"error": f"Database conn 로직 처리
#     return Response({"message": "로그인 성공"}, status=status.HTTP_200_OK)ection failed: {str(e)}"}, status=status.HTTP_500_INTERNAL_SERVER_ERROR)

#     # 이후 로그인
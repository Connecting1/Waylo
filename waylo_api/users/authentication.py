from rest_framework.authentication import TokenAuthentication
from users.models import CustomToken

class CustomTokenAuthentication(TokenAuthentication):
    model = CustomToken

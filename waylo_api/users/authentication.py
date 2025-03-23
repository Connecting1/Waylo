# users/authentication.py
from rest_framework.authentication import BaseAuthentication, get_authorization_header
from django.utils.translation import gettext_lazy as _
from rest_framework import exceptions
from .models import CustomToken

class CustomTokenAuthentication(BaseAuthentication):
    keyword = 'Token'
    model = CustomToken

    def authenticate(self, request):
        auth = get_authorization_header(request).split()

        if not auth or auth[0].lower() != self.keyword.lower().encode():
            return None

        if len(auth) == 1:
            raise exceptions.AuthenticationFailed(_('Invalid token header. No credentials provided.'))
        elif len(auth) > 2:
            raise exceptions.AuthenticationFailed(_('Invalid token header. Token string should not contain spaces.'))

        try:
            token = auth[1].decode()
        except UnicodeError:
            raise exceptions.AuthenticationFailed(_('Invalid token header. Token string should not contain invalid characters.'))

        return self.authenticate_credentials(token)

    def authenticate_credentials(self, key):
        try:
            token = self.model.objects.select_related('user').get(key=key)
        except self.model.DoesNotExist:
            raise exceptions.AuthenticationFailed(_('Invalid token.'))

        if not token.user.is_active:
            raise exceptions.AuthenticationFailed(_('User inactive or deleted.'))

        return (token.user, token)

    def authenticate_header(self, request):
        return self.keyword

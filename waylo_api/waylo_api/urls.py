from django.conf import settings
from django.conf.urls.static import static
from django.contrib import admin
from django.urls import path, include

urlpatterns = [
    path('admin/', admin.site.urls),
    path('api/users/', include('users.urls')),
    path('api/albums/', include('albums.urls')),
    path('api/widgets/', include('widgets.urls')),
    path('api/friends/', include('friends.urls')),
    path('api/feeds/', include('feeds.urls')),
    path('api/chats/', include('chats.urls')),
]

if settings.DEBUG:
    urlpatterns += static(settings.MEDIA_URL, document_root=settings.MEDIA_ROOT)
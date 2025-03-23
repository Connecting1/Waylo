from rest_framework import serializers
from .models import Widget

class WidgetSerializer(serializers.ModelSerializer):
    class Meta:
        model = Widget
        fields = ['id', 'type', 'x', 'y', 'width', 'height', 'extra_data', 'created_at']
        read_only_fields = ['id', 'created_at']
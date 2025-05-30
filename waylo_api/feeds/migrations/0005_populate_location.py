from django.db import migrations
from django.contrib.gis.geos import Point

def populate_location_field(apps, schema_editor):
    Feed = apps.get_model('feeds', 'Feed')
    for feed in Feed.objects.all():
        if feed.latitude and feed.longitude:
            feed.location = Point(float(feed.longitude), float(feed.latitude))
            feed.save(update_fields=['location'])

class Migration(migrations.Migration):
    dependencies = [
        ('feeds', '0004_feed_location'),  # 이전 마이그레이션 파일명으로 확인하고 변경하세요
    ]
    
    operations = [
        migrations.RunPython(populate_location_field),
    ]
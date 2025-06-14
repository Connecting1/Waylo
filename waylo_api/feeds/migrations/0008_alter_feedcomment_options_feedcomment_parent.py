# Generated by Django 5.1.6 on 2025-03-26 08:49

import django.db.models.deletion
from django.db import migrations, models


class Migration(migrations.Migration):

    dependencies = [
        ('feeds', '0007_feed_photo_taken_at'),
    ]

    operations = [
        migrations.AlterModelOptions(
            name='feedcomment',
            options={'ordering': ['created_at']},
        ),
        migrations.AddField(
            model_name='feedcomment',
            name='parent',
            field=models.ForeignKey(blank=True, null=True, on_delete=django.db.models.deletion.CASCADE, related_name='replies', to='feeds.feedcomment'),
        ),
    ]

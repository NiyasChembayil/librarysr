import os
import django

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'bookify_backend.settings')
django.setup()

from core.models import AmbientSound

sounds = [
    {
        "name": "Rain",
        "emoji": "🌧️",
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3",
        "order": 1
    },
    {
        "name": "Forest",
        "emoji": "🌲",
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3",
        "order": 2
    },
    {
        "name": "Cafe",
        "emoji": "☕",
        "audio_url": "https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3",
        "order": 3
    }
]

for s in sounds:
    obj, created = AmbientSound.objects.get_or_create(
        name=s["name"],
        defaults={
            "emoji": s["emoji"],
            "audio_url": s["audio_url"],
            "order": s["order"],
            "is_system": True
        }
    )
    if created:
        print(f"Created sound: {s['name']}")
    else:
        print(f"Sound already exists: {s['name']}")

import os
from gtts import gTTS
from django.conf import settings
from django.core.files.base import ContentFile
import io

def generate_voice_for_chapter(chapter):
    """
    Generates an MP3 file for a chapter from its content.
    """
    if not chapter.content:
        return None
    
    # Simple HTML tag removal (if any) - improve later with BeautifulSoup
    import re
    clean_text = re.sub('<[^<]+?>', '', chapter.content)
    
    tts = gTTS(text=clean_text, lang='en')
    
    # Save to a temporary buffer
    mp3_fp = io.BytesIO()
    tts.write_to_fp(mp3_fp)
    mp3_fp.seek(0)
    
    filename = f"chapter_{chapter.id}_audio.mp3"
    chapter.audio_file.save(filename, ContentFile(mp3_fp.read()), save=True)
    
    return chapter.audio_file.url

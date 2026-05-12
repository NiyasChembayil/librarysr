import os
from PIL import Image
from io import BytesIO
from django.core.files.base import ContentFile

def optimize_image(image_field, max_width=800, quality=85):
    """
    Optimizes an image by resizing and compressing it.
    Returns a ContentFile ready to be saved.
    """
    if not image_field:
        return None
        
    img = Image.open(image_field)
    
    # Convert to RGB if necessary (e.g., for PNGs with transparency)
    if img.mode in ("RGBA", "P"):
        img = img.convert("RGB")
        
    # Resize while maintaining aspect ratio
    if img.width > max_width:
        output_size = (max_width, int((max_width / img.width) * img.height))
        img = img.resize(output_size, Image.LANCZOS)
        
    # Compress
    output = BytesIO()
    img.save(output, format='JPEG', quality=quality, optimize=True)
    output.seek(0)
    
    # Return as ContentFile
    return ContentFile(output.read(), name=os.path.basename(image_field.name))

import os
import math
from PIL import Image, ImageDraw

# Define relative paths based on repository layout
base_dir = os.path.dirname(os.path.dirname(os.path.dirname(os.path.abspath(__file__)))) # parent of builder/boot/ (workspace root)
logo_path = os.path.join(base_dir, 'builder', 'calamares', 'branding', 'telcosec', 'logo.png')
glow_out_path = os.path.join(base_dir, 'builder', 'boot', 'plymouth', 'glow.png')
grub_out_path = os.path.join(base_dir, 'builder', 'boot', 'grub_background.png')

print(f"Base Directory: {base_dir}")
print(f"Logo Path: {logo_path}")

# 1. Generate glow.png (Soft Cyan Radial Gradient for Plymouth)
print("Generating Plymouth glow.png asset...")
size = 512
glow_img = Image.new("RGBA", (size, size), (0, 0, 0, 0))
pixels = glow_img.load()
cx, cy = size // 2, size // 2
max_r = size // 2
r_color, g_color, b_color = 0, 240, 255  # Brand Cyan
max_alpha = 110  # Maximum opacity at the center

for y in range(size):
    for x in range(size):
        dx = x - cx
        dy = y - cy
        dist = math.sqrt(dx*dx + dy*dy)
        if dist < max_r:
            factor = (1.0 - (dist / max_r)) ** 2  # soft quadratic falloff
            alpha = int(max_alpha * factor)
            pixels[x, y] = (r_color, g_color, b_color, alpha)
        else:
            pixels[x, y] = (0, 0, 0, 0)

os.makedirs(os.path.dirname(glow_out_path), exist_ok=True)
glow_img.save(glow_out_path)
print(f"Saved: {glow_out_path}")

# 2. Generate grub_background.png (Widescreen GRUB 16:9 theme backdrop)
if os.path.exists(logo_path):
    print("Generating widescreen GRUB background...")
    logo = Image.open(logo_path)
    
    # Create circular mask for the logo to crop any dark/square background artifacts
    mask = Image.new('L', logo.size, 0)
    draw = ImageDraw.Draw(mask)
    # Draw circle exactly boundary-to-boundary (0, 0 to 1024, 1024)
    draw.ellipse((0, 0, logo.size[0], logo.size[1]), fill=255)
    
    logo_rgba = logo.convert("RGBA")
    logo_rgba.putalpha(mask)
    
    # Create target widescreen background 1920x1080, obsidian #0c0f16
    bg = Image.new("RGBA", (1920, 1080), (12, 15, 22, 255))
    
    # Scale logo down to 450x450 for widescreen composition (leaves room for GRUB menu)
    try:
        resample_filter = Image.Resampling.LANCZOS
    except AttributeError:
        resample_filter = Image.LANCZOS
        
    logo_scaled = logo_rgba.resize((450, 450), resample_filter)
    
    # Center coordinates
    paste_x = (1920 - 450) // 2
    paste_y = (1080 - 450) // 2
    
    # Paste with transparency mask
    bg.paste(logo_scaled, (paste_x, paste_y), logo_scaled)
    
    # Convert to standard RGB and save
    bg_rgb = bg.convert("RGB")
    bg_rgb.save(grub_out_path)
    print(f"Saved: {grub_out_path}")
else:
    print(f"ERROR: Base logo not found at {logo_path}!")

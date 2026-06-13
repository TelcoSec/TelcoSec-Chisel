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

# 2. Generate grub_background.png and wallpaper.png (Widescreen backdrops)
if os.path.exists(logo_path):
    logo = Image.open(logo_path)
    
    # Create circular mask for the logo to crop any dark/square background artifacts
    mask = Image.new('L', logo.size, 0)
    draw = ImageDraw.Draw(mask)
    # Draw circle exactly boundary-to-boundary (0, 0 to 1024, 1024)
    draw.ellipse((0, 0, logo.size[0], logo.size[1]), fill=255)
    
    logo_rgba = logo.convert("RGBA")
    logo_rgba.putalpha(mask)
    
    try:
        resample_filter = Image.Resampling.LANCZOS
    except AttributeError:
        resample_filter = Image.LANCZOS

    # 2a. Generate grub_background.png (Widescreen GRUB 16:9 theme backdrop)
    print("Generating widescreen GRUB background...")
    bg_grub = Image.new("RGBA", (1920, 1080), (12, 15, 22, 255))
    logo_scaled_grub = logo_rgba.resize((450, 450), resample_filter)
    paste_x_grub = (1920 - 450) // 2
    paste_y_grub = (1080 - 450) // 2
    bg_grub.paste(logo_scaled_grub, (paste_x_grub, paste_y_grub), logo_scaled_grub)
    bg_rgb_grub = bg_grub.convert("RGB")
    bg_rgb_grub.save(grub_out_path)
    print(f"Saved: {grub_out_path}")

    # 2b. Generate wallpaper.png (Premium Desktop & LightDM Wallpaper with Neon Glow)
    print("Generating widescreen wallpaper with neon glow...")
    bg_wall = Image.new("RGBA", (1920, 1080), (12, 15, 22, 255))
    pixels = bg_wall.load()

    # Generate a soft cyan radial glow centered at (960, 540)
    glow_r = 600
    cx, cy = 960, 540
    r_col, g_col, b_col = 0, 240, 255  # Brand Cyan
    max_al = 40  # Very subtle alpha background glow

    for y in range(540 - glow_r, 540 + glow_r):
        if y < 0 or y >= 1080:
            continue
        for x in range(960 - glow_r, 960 + glow_r):
            if x < 0 or x >= 1920:
                continue
            dx = x - cx
            dy = y - cy
            dist = math.sqrt(dx*dx + dy*dy)
            if dist < glow_r:
                factor = (1.0 - (dist / glow_r)) ** 2
                alpha = int(max_al * factor)
                a_f = alpha / 255.0
                r_new = int(12 * (1.0 - a_f) + r_col * a_f)
                g_new = int(15 * (1.0 - a_f) + g_col * a_f)
                b_new = int(22 * (1.0 - a_f) + b_col * a_f)
                pixels[x, y] = (r_new, g_new, b_new, 255)

    # Scale logo down to 512x512 for wallpaper composition
    logo_scaled_wall = logo_rgba.resize((512, 512), resample_filter)
    paste_x_wall = (1920 - 512) // 2
    paste_y_wall = (1080 - 512) // 2
    bg_wall.paste(logo_scaled_wall, (paste_x_wall, paste_y_wall), logo_scaled_wall)
    
    bg_rgb_wall = bg_wall.convert("RGB")
    wallpaper_out_path = os.path.join(base_dir, 'builder', 'boot', 'wallpaper.png')
    bg_rgb_wall.save(wallpaper_out_path)
    print(f"Saved: {wallpaper_out_path}")
else:
    print(f"ERROR: Base logo not found at {logo_path}!")

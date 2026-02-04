# Arbiter - Asset Replacement Guide
# 仲裁者 - 素材替换指南

This guide explains how to replace placeholder assets with your own.
本指南说明如何用你自己的素材替换占位符。

## Directory Structure / 目录结构

```
assets/
├── images/
│   ├── characters/          # 角色图片
│   ├── backgrounds/         # 背景图片
│   ├── ui/                  # UI元素
│   ├── items/               # 物品图标
│   └── effects/             # 特效图片
├── audio/
│   ├── bgm/                 # 背景音乐
│   ├── sfx/                 # 音效
│   └── voice/               # 配音
└── fonts/                   # 字体文件
```

## Image Naming Conventions / 图片命名规范

### Characters / 角色
- `demon_generic.png` - Generic demon image (400x560px recommended)
- `demon_generic_portrait.png` - Demon portrait for dialog (300x400px)
- `soul_01.png` to `soul_09.png` - Individual soul characters
- `soul_01_portrait.png` to `soul_09_portrait.png` - Soul portraits
- `lucifer.png` - Lucifer full body (400x600px)
- `lucifer_portrait.png` - Lucifer portrait (300x400px)

### Backgrounds / 背景
- `title_bg.png` - Title screen background (1920x1080)
- `story_01.png` to `story_12.png` - Intro story backgrounds
- `level_demon_01_bg.png` to `level_demon_04_bg.png` - Demon level backgrounds
- `level_souls_bg.png` - Final soul level background
- `ending_good_01.png` to `ending_good_04.png` - Good ending backgrounds
- `ending_bad_01.png` to `ending_bad_04.png` - Bad ending backgrounds

### UI Elements / UI元素
- `skeleton_decor.png` - Skeleton decoration for character detail (450x1080)
- `scale_icon.png` - Scale icon (150x150)
- `dialog_box.png` - Dialog box background (optional)

### Items / 物品
- `soul_01_item_01.png`, `soul_01_item_02.png`, etc. - Item icons (150x150)

## Audio Naming Conventions / 音频命名规范

### BGM / 背景音乐
- `demon_level.ogg` - Music for demon levels
- `souls_level.ogg` - Music for final soul level
- `title.ogg` - Title screen music (optional)

### SFX / 音效
- `click.ogg` - Button click sound
- `typewriter.ogg` - Typewriter effect sound
- `scream.ogg` - Death scream sound
- `scale_weigh.ogg` - Scale weighing sound

### Voice / 配音
- `story_01.ogg` to `story_12.ogg` - Intro story voiceover
- `ending_good_01.ogg` to `ending_good_04.ogg` - Good ending voiceover
- `ending_bad_01.ogg` to `ending_bad_04.ogg` - Bad ending voiceover

## Data Files / 数据文件

All game text and logic can be modified in the `data/` folder:

### game_config.json
- `typewriter_speed`: Typing speed (seconds per character)
- `ui_settings`: Position and size of UI elements
- `colors`: Color scheme for the game

### levels.json
- Level definitions, character positions, victory conditions
- Adjacency rules for grid interactions
- Kill rules for soul alignment interactions

### characters.json
- Questions displayed in character detail
- Soul character data (name, alignment, answers, items)
- Demon template data

### dialogues.json
- All Lucifer dialogue text
- Eye tracker settings

### story.json
- Intro story segments (text + background + voice mapping)
- Ending story segments

## Modifying UI Positions / 修改UI位置

Edit `data/game_config.json` to adjust UI positions:

```json
{
  "ui_settings": {
    "grid_cell_size": [200, 280],      // Character cell size
    "grid_spacing": 20,                 // Space between cells
    "dialog_box_size": [1200, 200],    // Dialog box dimensions
    "item_slot_size": [100, 100]       // Item slot size
  }
}
```

## Adding New Characters / 添加新角色

1. Add character data to `data/characters.json` under `souls`
2. Add character images to `assets/images/characters/`
3. Add item images to `assets/images/items/`
4. Update level configuration in `data/levels.json`

## Recommended Image Formats / 推荐图片格式

- PNG for images with transparency
- JPG for backgrounds without transparency
- OGG for audio files (best compatibility with Godot)

## Tips / 提示

1. Keep image dimensions consistent for best results
2. Use the same art style across all assets
3. Test audio levels to ensure consistent volume
4. The game supports both English and Chinese text - add `_zh` suffix for Chinese versions

## Running the Game / 运行游戏

1. Open the project in Godot 4.2+
2. Press F5 or click the Play button
3. Replace placeholder assets as needed
4. Re-run to see changes

import os
import math
import random

def create_level_scene(filename, level_idx, bg_color, bgm_track, cam_limits, platforms, coins, gems, hearts, keys, doors, springs, falling_plats, moving_plats, spikes_list, checkpoints, exits, slimes, bats, spike_beetles, boss=None, player_pos=(60, 160)):
    out = []
    out.append('[gd_scene load_steps=18 format=3]\n')
    out.append('[ext_resource type="Script" path="res://scripts/levels/level_base.gd" id="1_lvl"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/camera/game_camera.tscn" id="2_cam"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/ui/hud.tscn" id="3_hud"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/player/player.tscn" id="4_player"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/coin.tscn" id="5_coin"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/gem.tscn" id="6_gem"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/heart.tscn" id="7_heart"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/key.tscn" id="8_key"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/door.tscn" id="9_door"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/spring.tscn" id="10_spring"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/falling_platform.tscn" id="11_fall"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/moving_platform.tscn" id="12_move"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/spikes.tscn" id="13_spk"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/checkpoint.tscn" id="14_chk"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/objects/level_exit.tscn" id="15_exit"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/enemies/slime.tscn" id="16_slime"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/enemies/bat.tscn" id="17_bat"]')
    out.append('[ext_resource type="PackedScene" path="res://scenes/enemies/spike_beetle.tscn" id="18_beetle"]')
    if boss:
        out.append('[ext_resource type="PackedScene" path="res://scenes/enemies/boss_golem.tscn" id="19_boss"]')
    
    # Tile textures
    out.append('[ext_resource type="Texture2D" path="res://asset/Tiles/tile_0021.png" id="t_g_left"]')
    out.append('[ext_resource type="Texture2D" path="res://asset/Tiles/tile_0022.png" id="t_g_mid"]')
    out.append('[ext_resource type="Texture2D" path="res://asset/Tiles/tile_0023.png" id="t_g_right"]')
    out.append('[ext_resource type="Texture2D" path="res://asset/Tiles/tile_0024.png" id="t_dirt"]')
    out.append('[ext_resource type="Texture2D" path="res://asset/Tiles/tile_0048.png" id="t_s_left"]')
    out.append('[ext_resource type="Texture2D" path="res://asset/Tiles/tile_0049.png" id="t_s_mid"]')
    out.append('[ext_resource type="Texture2D" path="res://asset/Tiles/tile_0050.png" id="t_s_right"]')
    out.append('[ext_resource type="Texture2D" path="res://asset/Tiles/tile_0051.png" id="t_stone"]')
    out.append('[ext_resource type="Texture2D" path="res://asset/Tiles/tile_0008.png" id="t_wood"]')
    out.append('')

    # Sub resources (shapes for platforms)
    for i, plat in enumerate(platforms):
        w_px = plat['w'] * 18
        h_px = plat['h'] * 18
        out.append(f'[sub_resource type="RectangleShape2D" id="RectangleShape2D_plat_{i}"]')
        out.append(f'size = Vector2({w_px}, {h_px})\n')

    # Root Node
    out.append(f'[node name="Level_{level_idx}" type="Node2D"]')
    out.append('script = ExtResource("1_lvl")')
    out.append(f'level_index = {level_idx}')
    out.append(f'bgm_track = "{bgm_track}"')
    out.append(f'camera_limit_left = {cam_limits[0]}')
    out.append(f'camera_limit_top = {cam_limits[1]}')
    out.append(f'camera_limit_right = {cam_limits[2]}')
    out.append(f'camera_limit_bottom = {cam_limits[3]}')
    out.append('')

    # Background CanvasLayer / Parallax
    out.append('[node name="BackgroundCanvas" type="CanvasLayer" parent="."]')
    out.append('layer = -100\n')
    out.append('[node name="Sky" type="ColorRect" parent="BackgroundCanvas"]')
    out.append('anchors_preset = 15')
    out.append('anchor_right = 1.0')
    out.append('anchor_bottom = 1.0')
    out.append('grow_horizontal = 2')
    out.append('grow_vertical = 2')
    out.append(f'color = {bg_color}')
    out.append('')

    # Game Camera
    out.append('[node name="GameCamera" parent="." instance=ExtResource("2_cam")]')
    out.append('')

    # HUD
    out.append('[node name="HUD" parent="." instance=ExtResource("3_hud")]')
    out.append('')

    # Player
    out.append('[node name="Player" parent="." instance=ExtResource("4_player")]')
    out.append(f'position = Vector2({player_pos[0]}, {player_pos[1]})')
    out.append('')

    # Terrain Container
    out.append('[node name="Terrain" type="Node2D" parent="."]')
    out.append('')

    for i, plat in enumerate(platforms):
        p_name = plat['name']
        x = plat['x']
        y = plat['y']
        w = plat['w']
        h = plat['h']
        style = plat['style']
        center_x = x + (w * 18) / 2.0
        center_y = y + (h * 18) / 2.0

        out.append(f'[node name="{p_name}" type="StaticBody2D" parent="Terrain"]')
        out.append(f'position = Vector2({center_x}, {center_y})')
        out.append('collision_layer = 1')
        out.append('collision_mask = 0\n')
        out.append(f'[node name="CollisionShape2D" type="CollisionShape2D" parent="Terrain/{p_name}"]')
        out.append(f'shape = SubResource("RectangleShape2D_plat_{i}")\n')

        # Add visual tile sprites
        for row in range(h):
            for col in range(w):
                local_x = (col * 18 + 9) - (w * 18) / 2.0
                local_y = (row * 18 + 9) - (h * 18) / 2.0
                tex_id = ""
                if style == "wood":
                    tex_id = "ExtResource(\"t_wood\")"
                elif style == "stone":
                    if row == 0:
                        tex_id = "ExtResource(\"t_s_left\")" if col == 0 else ("ExtResource(\"t_s_right\")" if col == w - 1 else "ExtResource(\"t_s_mid\")")
                    else:
                        tex_id = "ExtResource(\"t_stone\")"
                else: # grass
                    if row == 0:
                        tex_id = "ExtResource(\"t_g_left\")" if col == 0 else ("ExtResource(\"t_g_right\")" if col == w - 1 else "ExtResource(\"t_g_mid\")")
                    else:
                        tex_id = "ExtResource(\"t_dirt\")"

                tile_name = f'Tile_{row}_{col}'
                out.append(f'[node name="{tile_name}" type="Sprite2D" parent="Terrain/{p_name}"]')
                out.append(f'position = Vector2({local_x}, {local_y})')
                out.append(f'texture = {tex_id}\n')

    # Collectibles Container
    out.append('[node name="Collectibles" type="Node2D" parent="."]')
    out.append('')
    for i, (cx, cy) in enumerate(coins):
        out.append(f'[node name="Coin_{i}" parent="Collectibles" instance=ExtResource("5_coin")]')
        out.append(f'position = Vector2({cx}, {cy})\n')

    for i, (gx, gy, g_idx) in enumerate(gems):
        out.append(f'[node name="Gem_{i}" parent="Collectibles" instance=ExtResource("6_gem")]')
        out.append(f'position = Vector2({gx}, {gy})')
        out.append(f'gem_index = {g_idx}\n')

    for i, (hx, hy) in enumerate(hearts):
        out.append(f'[node name="Heart_{i}" parent="Collectibles" instance=ExtResource("7_heart")]')
        out.append(f'position = Vector2({hx}, {hy})\n')

    for i, (kx, ky) in enumerate(keys):
        out.append(f'[node name="Key_{i}" parent="Collectibles" instance=ExtResource("8_key")]')
        out.append(f'position = Vector2({kx}, {ky})\n')

    # Interactive Objects Container
    out.append('[node name="Objects" type="Node2D" parent="."]')
    out.append('')
    for i, (dx, dy) in enumerate(doors):
        out.append(f'[node name="Door_{i}" parent="Objects" instance=ExtResource("9_door")]')
        out.append(f'position = Vector2({dx}, {dy})\n')

    for i, (sx, sy) in enumerate(springs):
        out.append(f'[node name="Spring_{i}" parent="Objects" instance=ExtResource("10_spring")]')
        out.append(f'position = Vector2({sx}, {sy})\n')

    for i, (fx, fy) in enumerate(falling_plats):
        out.append(f'[node name="FallingPlat_{i}" parent="Objects" instance=ExtResource("11_fall")]')
        out.append(f'position = Vector2({fx}, {fy})\n')

    for i, (mx, my, ox, oy) in enumerate(moving_plats):
        out.append(f'[node name="MovingPlat_{i}" parent="Objects" instance=ExtResource("12_move")]')
        out.append(f'position = Vector2({mx}, {my})')
        out.append(f'move_offset = Vector2({ox}, {oy})\n')

    # Hazards Container
    out.append('[node name="Hazards" type="Node2D" parent="."]')
    out.append('')
    for i, (spx, spy) in enumerate(spikes_list):
        out.append(f'[node name="Spikes_{i}" parent="Hazards" instance=ExtResource("13_spk")]')
        out.append(f'position = Vector2({spx}, {spy})\n')

    # Checkpoints & Exits
    for i, (ckx, cky) in enumerate(checkpoints):
        out.append(f'[node name="Checkpoint_{i}" parent="." instance=ExtResource("14_chk")]')
        out.append(f'position = Vector2({ckx}, {cky})\n')

    for i, (ex, ey) in enumerate(exits):
        out.append(f'[node name="LevelExit_{i}" parent="." instance=ExtResource("15_exit")]')
        out.append(f'position = Vector2({ex}, {ey})\n')

    # Enemies Container
    out.append('[node name="Enemies" type="Node2D" parent="."]')
    out.append('')
    for i, (slx, sly) in enumerate(slimes):
        out.append(f'[node name="Slime_{i}" parent="Enemies" instance=ExtResource("16_slime")]')
        out.append(f'position = Vector2({slx}, {sly})\n')

    for i, (bx, by) in enumerate(bats):
        out.append(f'[node name="Bat_{i}" parent="Enemies" instance=ExtResource("17_bat")]')
        out.append(f'position = Vector2({bx}, {by})\n')

    for i, (sx, sy) in enumerate(spike_beetles):
        out.append(f'[node name="SpikeBeetle_{i}" parent="Enemies" instance=ExtResource("18_beetle")]')
        out.append(f'position = Vector2({sx}, {sy})\n')

    if boss:
        out.append(f'[node name="BossGolem" parent="Enemies" instance=ExtResource("19_boss")]')
        out.append(f'position = Vector2({boss[0]}, {boss[1]})\n')

    with open(filename, 'w') as f:
        f.write('\n'.join(out))

# Generate Level 1 to 50
def generate_all_50_levels():
    print("Generating 50 expansive levels...")
    for lvl in range(1, 51):
        filename = f"scenes/levels/level_{lvl}.tscn"

        # Determine Biome (5 Worlds of 10 levels)
        world_idx = (lvl - 1) // 10 + 1 # 1, 2, 3, 4, 5

        # Boss Levels: 10, 20, 30, 40, 50
        is_boss_level = (lvl % 10 == 0)

        if is_boss_level:
            # Build Arena Boss Level
            bg_colors = {
                10: 'Color(0.24, 0.42, 0.55, 1)', # Meadow Boss
                20: 'Color(0.10, 0.12, 0.18, 1)', # Cavern Boss
                30: 'Color(0.38, 0.18, 0.28, 1)', # Sky Boss
                40: 'Color(0.18, 0.08, 0.10, 1)', # Ruins Boss
                50: 'Color(0.12, 0.05, 0.20, 1)'  # Final Core Boss
            }
            bg_col = bg_colors.get(lvl, 'Color(0.15, 0.1, 0.2, 1)')
            platforms = [
                {'name': 'ArenaGround', 'x': 36, 'y': 198, 'w': 36, 'h': 4, 'style': 'stone'},
                {'name': 'LeftWall', 'x': 18, 'y': 36, 'w': 2, 'h': 10, 'style': 'stone'},
                {'name': 'RightWall', 'x': 684, 'y': 36, 'w': 2, 'h': 10, 'style': 'stone'},
                {'name': 'LeftLedge', 'x': 90, 'y': 126, 'w': 5, 'h': 1, 'style': 'wood'},
                {'name': 'RightLedge', 'x': 540, 'y': 126, 'w': 5, 'h': 1, 'style': 'wood'},
                {'name': 'CenterLedge', 'x': 324, 'y': 80, 'w': 4, 'h': 1, 'style': 'wood'},
            ]
            coins = [(108, 108), (144, 108), (558, 108), (594, 108), (342, 62), (360, 62)]
            gems = [(126, 108, 0), (351, 62, 1), (576, 108, 2)]
            hearts = [(90, 108), (612, 108)]
            springs = [(180, 189), (504, 189)]
            checkpoints = [(90, 180)]
            create_level_scene(
                filename, lvl, bg_col, 'boss',
                [0, -50, 720, 270],
                platforms, coins, gems, hearts, [], [], springs, [], [], [], checkpoints, [],
                [], [], [], boss=(360, 175), player_pos=(90, 175)
            )
            continue

        # Regular Platformer Level
        # Biome properties
        if world_idx == 1: # Meadows
            style_ground = 'grass'
            style_sub = 'wood'
            bg_col = 'Color(0.28, 0.48, 0.62, 1)'
            bgm = 'level'
        elif world_idx == 2: # Caverns
            style_ground = 'stone'
            style_sub = 'wood'
            bg_col = 'Color(0.10, 0.12, 0.18, 1)'
            bgm = 'level'
        elif world_idx == 3: # Sky Citadel
            style_ground = 'grass'
            style_sub = 'wood'
            bg_col = 'Color(0.38, 0.22, 0.35, 1)'
            bgm = 'level'
        elif world_idx == 4: # Ancient Ruins
            style_ground = 'stone'
            style_sub = 'wood'
            bg_col = 'Color(0.16, 0.08, 0.10, 1)'
            bgm = 'level'
        else: # Core of Eternity
            style_ground = 'stone'
            style_sub = 'wood'
            bg_col = 'Color(0.12, 0.06, 0.18, 1)'
            bgm = 'boss'

        # Seed based on level for reproducible balanced layouts
        rng = random.Random(lvl * 1337 + 42)

        # Level width grows with level (from 1200 to 2200)
        level_w = 1200 + (lvl % 10) * 100
        cam_limits = [0, -100, level_w + 100, 290]

        platforms = []
        coins = []
        gems = []
        hearts = []
        keys = []
        doors = []
        springs = []
        falling_plats = []
        moving_plats = []
        spikes = []
        checkpoints = []
        exits = []
        slimes = []
        bats = []
        beetles = []

        # 1. Starting Floor
        start_w = 8
        platforms.append({'name': 'StartFloor', 'x': 0, 'y': 198, 'w': start_w, 'h': 4, 'style': style_ground})
        curr_x = start_w * 18

        # Has puzzle door in this level?
        has_door = (lvl % 3 == 0)
        door_x = -1
        key_placed = False

        plat_counter = 1
        has_checkpoint_placed = False

        while curr_x < level_w - 250:
            gap = rng.choice([36, 54, 72])
            curr_x += gap

            # Segment type
            seg_type = rng.choice(['normal', 'elevated', 'falling', 'moving', 'high_spring'])
            plat_w = rng.randint(4, 9)
            plat_y = rng.choice([162, 180, 198])

            if seg_type == 'falling' and world_idx >= 2:
                # Add series of falling platforms
                fall_count = rng.randint(2, 4)
                for f_idx in range(fall_count):
                    falling_plats.append((curr_x, 180))
                    # Spike below
                    spikes.append((curr_x, 252))
                    curr_x += 36
                continue

            elif seg_type == 'moving' and world_idx >= 2:
                # Moving platform
                ox = rng.choice([70.0, 90.0])
                moving_plats.append((curr_x, 180, ox, 0.0))
                spikes.append((curr_x + 36, 252))
                curr_x += int(ox) + 54
                continue

            elif seg_type == 'high_spring':
                # Ground with spring pad launching to upper floating island
                platforms.append({'name': f'Plat_{plat_counter}', 'x': curr_x, 'y': 198, 'w': plat_w, 'h': 4, 'style': style_ground})
                springs.append((curr_x + (plat_w // 2) * 18, 189))
                # Upper island with coins or gem
                up_island_w = 4
                up_island_y = 60
                platforms.append({'name': f'HighIsle_{plat_counter}', 'x': curr_x + 18, 'y': up_island_y, 'w': up_island_w, 'h': 1, 'style': style_sub})
                
                if len(gems) == 0:
                    gems.append((curr_x + 36, up_island_y - 20, 0))
                else:
                    coins.append((curr_x + 36, up_island_y - 18))
                
                plat_counter += 1
                curr_x += plat_w * 18
                continue

            else:
                # Normal or elevated platform
                if seg_type == 'elevated':
                    plat_y = 144
                platforms.append({'name': f'Plat_{plat_counter}', 'x': curr_x, 'y': plat_y, 'w': plat_w, 'h': 5 if plat_y >= 180 else 1, 'style': style_ground if plat_y >= 180 else style_sub})
                
                # Place coins in arc
                for c_offset in range(1, plat_w - 1, 2):
                    coins.append((curr_x + c_offset * 18, plat_y - 18))

                # Place Enemies
                if plat_w >= 6 and rng.random() < 0.65:
                    enemy_x = curr_x + (plat_w // 2) * 18
                    if world_idx == 1:
                        slimes.append((enemy_x, plat_y - 18))
                    elif world_idx == 2:
                        if rng.random() < 0.5:
                            beetles.append((enemy_x, plat_y - 18))
                        else:
                            bats.append((enemy_x, plat_y - 60))
                    elif world_idx == 3:
                        bats.append((enemy_x, plat_y - 60))
                    else:
                        if rng.random() < 0.5:
                            beetles.append((enemy_x, plat_y - 18))
                        else:
                            bats.append((enemy_x, plat_y - 60))

                # Checkpoint around middle
                if not has_checkpoint_placed and curr_x > level_w * 0.45:
                    checkpoints.append((curr_x + 36, plat_y - 9))
                    has_checkpoint_placed = True
                    # Gem 1 near checkpoint
                    if len(gems) == 1:
                        gems.append((curr_x + (plat_w - 2) * 18, plat_y - 18, 1))

                # Place key if puzzle level
                if has_door and not key_placed and curr_x > level_w * 0.35:
                    keys.append((curr_x + 36, plat_y - 20))
                    key_placed = True

                plat_counter += 1
                curr_x += plat_w * 18

        # Near end: Place Locked Door if puzzle
        if has_door and key_placed:
            door_plat_x = curr_x + 36
            platforms.append({'name': 'DoorPlatform', 'x': door_plat_x, 'y': 180, 'w': 8, 'h': 5, 'style': style_ground})
            doors.append((door_plat_x + 36, 171))
            curr_x = door_plat_x + 8 * 18

        # Dash Challenge Gem 2 (over gap before goal)
        gem2_x = curr_x + 36
        gems.append((gem2_x, 140, 2))
        curr_x += 72

        # Final Goal Floor
        goal_w = 12
        goal_x = curr_x
        platforms.append({'name': 'GoalFloor', 'x': goal_x, 'y': 180, 'w': goal_w, 'h': 5, 'style': style_ground})
        hearts.append((goal_x + 36, 162))
        coins.append((goal_x + 72, 162))
        coins.append((goal_x + 108, 162))
        exits.append((goal_x + (goal_w - 3) * 18, 171))

        # Ensure Gem 0 and 1 are present if missed
        if len(gems) < 2:
            gems.insert(0, (180, 150, 0))
        if len(gems) < 3:
            gems.insert(1, (level_w // 2, 140, 1))

        # Ensure camera_limit_right fully encompasses the GoalFloor and exit with padding
        actual_max_x = goal_x + goal_w * 18 + 120
        cam_limits[2] = max(cam_limits[2], actual_max_x)

        create_level_scene(
            filename, lvl, bg_col, bgm,
            cam_limits,
            platforms, coins, gems[:3], hearts, keys, doors, springs, falling_plats, moving_plats, spikes, checkpoints, exits,
            slimes, bats, beetles, boss=None, player_pos=(60, 160)
        )

    print("All 50 levels generated successfully!")

if __name__ == '__main__':
    generate_all_50_levels()

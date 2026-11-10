#!/usr/bin/env python3
"""Generate every .tscn scene for Mars Arachnid Defense.

Run from the project root:  python tools/build_scenes.py
Scenes stay deliberately small: behaviour and most UI construction live in
GDScript, while each tower, enemy, effect and level remains a separate editable
scene with its exported data resource attached.
"""
from __future__ import annotations

from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
SCENES = ROOT / "scenes"

TOWERS = ["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital"]
ENEMIES = ["scout", "worker", "warrior", "spitter", "healer", "burrower", "shieldbearer", "flyer", "elite", "boss"]

TOWER_NAMES = {
    "pulse": "TowerPulse", "siege": "TowerSiege", "flame": "TowerFlame", "tesla": "TowerTesla",
    "missile": "TowerMissile", "cryo": "TowerCryo", "rail": "TowerRail", "relay": "TowerRelay",
    "mine": "TowerMine", "orbital": "TowerOrbital",
}
ENEMY_NAMES = {
    "scout": "EnemyScout", "worker": "EnemyWorker", "warrior": "EnemyWarrior",
    "spitter": "EnemySpitter", "healer": "EnemyHealer", "burrower": "EnemyBurrower",
    "shieldbearer": "EnemyShield", "flyer": "EnemyFlyer", "elite": "EnemyElite", "boss": "EnemyBoss",
}
FX_STYLES = {
    "MuzzleFlash": "muzzle", "Explosion": "explosion", "FrostBurst": "frost",
    "DeathBurst": "death", "DustCloud": "dust", "HealBurst": "heal",
    "AcidSplat": "acid", "ShieldBreak": "shield_break", "FlameBurst": "flame",
    "MissileTrail": "trail", "OrbitalBlast": "orbital", "ImpactBurst": "hit",
    "EmpBurst": "hit",
}


def write(relative: str, text: str) -> None:
    path = ROOT / relative
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


def header(ext_paths: list[tuple[str, str]], sub_resources: list[str] | None = None) -> str:
    """Build a gd_scene header plus ext_resource declarations."""
    subs = sub_resources or []
    load_steps = len(ext_paths) + len(subs) + 1
    lines = [f'[gd_scene load_steps={load_steps} format=3]', ""]
    for kind, path in ext_paths:
        ext_id = _ext_id(path)
        lines.append(f'[ext_resource type="{kind}" path="{path}" id="{ext_id}"]')
    for block in subs:
        lines.append("")
        lines.append(block)
    lines.append("")
    return "\n".join(lines)


def _ext_id(path: str) -> str:
    stem = Path(path).stem
    return "res_" + "".join(ch if ch.isalnum() else "_" for ch in stem)


def script_res(path: str) -> tuple[str, str]:
    return ("Script", path)


def build_tower(tower_id: str) -> None:
    name = TOWER_NAMES[tower_id]
    script = "res://scripts/towers/Tower.gd"
    data = f"res://resources/towers/tower_{tower_id}.tres"
    visual = "res://scripts/towers/TowerVisual.gd"
    rng = "res://scripts/towers/TowerRangeIndicator.gd"
    text = header([
        script_res(script),
        ("Resource", data),
        script_res(visual),
        script_res(rng),
    ])
    text += f"""[node name="{name}" type="Node2D"]
script = ExtResource("{_ext_id(script)}")
tower_data = ExtResource("{_ext_id(data)}")

[node name="RangeIndicator" type="Node2D" parent="."]
z_index = -1
script = ExtResource("{_ext_id(rng)}")

[node name="Visual" type="Node2D" parent="."]
script = ExtResource("{_ext_id(visual)}")

[node name="Muzzle" type="Marker2D" parent="."]
position = Vector2(22, 0)

[node name="AnimationPlayer" type="AnimationPlayer" parent="."]

[node name="AudioStreamPlayer" type="AudioStreamPlayer" parent="."]
"""
    write(f"scenes/towers/{name}.tscn", text)


def build_enemy(enemy_id: str) -> None:
    name = ENEMY_NAMES[enemy_id]
    script = "res://scripts/enemies/Enemy.gd"
    data = f"res://resources/enemies/enemy_{enemy_id}.tres"
    visual = "res://scripts/enemies/EnemyVisual.gd"
    bar = "res://scripts/enemies/EnemyHealthBar.gd"
    text = header([
        script_res(script),
        ("Resource", data),
        script_res(visual),
        script_res(bar),
    ])
    text += f"""[node name="{name}" type="Node2D"]
script = ExtResource("{_ext_id(script)}")
enemy_data = ExtResource("{_ext_id(data)}")

[node name="Visual" type="Node2D" parent="."]
script = ExtResource("{_ext_id(visual)}")

[node name="HealthBar" type="Node2D" parent="."]
z_index = 4
script = ExtResource("{_ext_id(bar)}")
"""
    write(f"scenes/enemies/{name}.tscn", text)


def build_simple(relative: str, scene_name: str, node_type: str, script: str) -> None:
    text = header([script_res(script)])
    text += f"""[node name="{scene_name}" type="{node_type}"]
script = ExtResource("{_ext_id(script)}")
"""
    write(relative, text)


def build_fx() -> None:
    combat = "res://scripts/fx/CombatFX.gd"
    beam = "res://scripts/fx/BeamFX.gd"
    for scene_name, style in FX_STYLES.items():
        text = header([script_res(combat)])
        text += f"""[node name="{scene_name}" type="Node2D"]
script = ExtResource("{_ext_id(combat)}")
style = "{style}"
"""
        write(f"scenes/fx/{scene_name}.tscn", text)
    for scene_name, style in [("Beam", "beam"), ("TeslaArc", "tesla")]:
        text = header([script_res(beam)])
        text += f"""[node name="{scene_name}" type="Node2D"]
script = ExtResource("{_ext_id(beam)}")
style = "{style}"
"""
        write(f"scenes/fx/{scene_name}.tscn", text)


def build_level(n: int) -> None:
    level_name = f"Level_{n:02d}"
    base_script = "res://scripts/core/LevelBase.gd"
    data = f"res://resources/levels/level_{n:02d}.tres"
    terrain = "res://scripts/core/TerrainView.gd"
    path_net = "res://scripts/core/PathNetwork.gd"
    grid = "res://scripts/core/GridOverlay.gd"
    gate = "res://scripts/core/SpawnGate.gd"
    base = "res://scripts/core/BaseCore.gd"
    hud = "res://scenes/ui/HUD.tscn"
    pause = "res://scenes/ui/PauseMenu.tscn"
    text = header([
        script_res(base_script),
        ("Resource", data),
        script_res(terrain),
        script_res(path_net),
        script_res(grid),
        script_res(gate),
        script_res(base),
        ("PackedScene", hud),
        ("PackedScene", pause),
    ])
    text += f"""[node name="{level_name}" type="Node2D"]
script = ExtResource("{_ext_id(base_script)}")
level_data = ExtResource("{_ext_id(data)}")

[node name="Terrain" type="Node2D" parent="."]
script = ExtResource("{_ext_id(terrain)}")

[node name="PathNetwork" type="Node2D" parent="."]
script = ExtResource("{_ext_id(path_net)}")

[node name="GridOverlay" type="Node2D" parent="."]
script = ExtResource("{_ext_id(grid)}")

[node name="SpawnGateA" type="Node2D" parent="."]
script = ExtResource("{_ext_id(gate)}")

[node name="SpawnGateB" type="Node2D" parent="."]
script = ExtResource("{_ext_id(gate)}")

[node name="BaseCore" type="Node2D" parent="."]
script = ExtResource("{_ext_id(base)}")

[node name="HUD" parent="." instance=ExtResource("{_ext_id(hud)}")]

[node name="PauseMenu" parent="." instance=ExtResource("{_ext_id(pause)}")]
"""
    write(f"scenes/level/{level_name}.tscn", text)


def build_ui() -> None:
    build_simple("scenes/ui/HUD.tscn", "HUD", "CanvasLayer", "res://scripts/ui/HUDController.gd")
    build_simple("scenes/ui/TowerShop.tscn", "TowerShop", "VBoxContainer", "res://scripts/ui/TowerShopController.gd")
    build_simple("scenes/ui/TowerCard.tscn", "TowerCard", "Button", "res://scripts/ui/TowerCard.gd")
    build_simple("scenes/ui/TowerPanel.tscn", "TowerPanel", "PanelContainer", "res://scripts/ui/TowerPanelController.gd")
    build_simple("scenes/ui/AbilityBar.tscn", "AbilityBar", "VBoxContainer", "res://scripts/ui/AbilityBarController.gd")
    build_simple("scenes/ui/AbilityButton.tscn", "AbilityButton", "Button", "res://scripts/ui/AbilityButton.gd")
    build_simple("scenes/ui/WaveBanner.tscn", "WaveBanner", "Control", "res://scripts/ui/WaveBannerController.gd")
    build_simple("scenes/ui/Tooltip.tscn", "Tooltip", "PanelContainer", "res://scripts/ui/TooltipController.gd")
    build_simple("scenes/ui/PauseMenu.tscn", "PauseMenu", "CanvasLayer", "res://scripts/ui/PauseMenuController.gd")
    build_simple("scenes/ui/SettingsPanel.tscn", "SettingsPanel", "CanvasLayer", "res://scripts/ui/SettingsPanelController.gd")
    build_simple("scenes/ui/HelpPanel.tscn", "HelpPanel", "CanvasLayer", "res://scripts/ui/HelpPanelController.gd")
    build_simple("scenes/ui/DamageNumber.tscn", "DamageNumber", "Label", "res://scripts/fx/DamageNumber.gd")
    build_simple("scenes/main/VictoryScreen.tscn", "VictoryScreen", "CanvasLayer",
                 "res://scripts/ui/VictoryScreenController.gd")
    build_simple("scenes/main/DefeatScreen.tscn", "DefeatScreen", "CanvasLayer",
                 "res://scripts/ui/DefeatScreenController.gd")
    build_simple("scenes/main/Boot.tscn", "Boot", "Node", "res://scripts/ui/BootController.gd")

    for scene_name, script in [
        ("MainMenu", "res://scripts/ui/MainMenuController.gd"),
        ("LevelSelect", "res://scripts/ui/LevelSelectController.gd"),
    ]:
        text = header([script_res(script)])
        text += f"""[node name="{scene_name}" type="Control"]
anchors_preset = 15
anchor_right = 1.0
anchor_bottom = 1.0
grow_horizontal = 2
grow_vertical = 2
script = ExtResource("{_ext_id(script)}")
"""
        write(f"scenes/main/{scene_name}.tscn", text)


def main() -> None:
    for tower_id in TOWERS:
        build_tower(tower_id)
    for enemy_id in ENEMIES:
        build_enemy(enemy_id)
    build_simple("scenes/towers/Projectile.tscn", "Projectile", "Node2D", "res://scripts/towers/Projectile.gd")
    build_simple("scenes/towers/ProximityMine.tscn", "ProximityMine", "Node2D", "res://scripts/towers/Mine.gd")
    build_simple("scenes/fx/AbilityDrone.tscn", "AbilityDrone", "Node2D", "res://scripts/fx/AbilityDrone.gd")
    build_simple("scenes/fx/OrbitalStrike.tscn", "OrbitalStrike", "Node2D", "res://scripts/fx/OrbitalStrike.gd")
    build_fx()
    build_ui()
    for n in range(1, 16):
        build_level(n)
    print("Generated 10 tower scenes, 10 enemy scenes, 20 FX scenes, 16 UI/menu scenes and 15 level scenes.")


if __name__ == "__main__":
    main()

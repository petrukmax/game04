#!/usr/bin/env python3
"""Generate all data-driven .tres resources for Mars Arachnid Defense.

Run from the project root:  python tools/build_data.py
Everything under resources/ is generated; tuning values live in this script
so balance changes stay reproducible.
"""
from __future__ import annotations

import json
import math
import os
import random
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
RES = ROOT / "resources"


def q(value: str) -> str:
    return json.dumps(value, ensure_ascii=False)


def color(c: tuple[float, float, float]) -> str:
    return f"Color({c[0]}, {c[1]}, {c[2]}, 1)"


def fmt(value) -> str:
    """Serialize a Python value the way Godot's .tres parser expects it."""
    if value is True:
        return "true"
    if value is False:
        return "false"
    return str(value)


def write(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8", newline="\n")


# ---------------------------------------------------------------------------
# Towers
# ---------------------------------------------------------------------------
# (id, name, role, cost, damage_type, damage, rate, range, speed, splash, slow,
#  slow_dur, pen, chains, burn, burn_dur, anti_air, style, color, shortcut, desc, upgrades)
# Upgrade tuple: (cost, name, desc, {fields})
TOWERS = [
    dict(id="pulse", name="Pulse Turret", role="Reliable single-target",
         cost=100, dtype="kinetic", damage=14, rate=1.8, rng=190, speed=800,
         pen=0.1, crit=0.05, style="pulse", color=(0.95, 0.64, 0.24), key="1",
         desc="Compact twin-barrel kinetic turret. Cheap, fast and dependable on both roads.",
         upgrades=[
             (80, "Servo Tuning", "Faster tracking and a harder hitting bolt.",
              dict(damage_add=7, range_add=15, rate_add=0.25)),
             (130, "Armour Piercer", "Dense penetrator rounds ignore more plating.",
              dict(damage_add=10, range_add=20, rate_add=0.3, armor_pen_add=0.15)),
             (210, "Skyfire Barrels", "Specialised flak shells let the turret hit flyers.",
              dict(damage_add=16, range_add=25, rate_add=0.4, unlock_air=True,
                   special_note="Can target flying enemies.")),
         ]),
    dict(id="siege", name="Siege Cannon", role="Heavy splash",
         cost=180, dtype="explosive", damage=45, rate=0.55, rng=215, speed=520,
         splash=65, pen=0.15, style="cannon", color=(0.8, 0.42, 0.18), key="2",
         desc="Slow explosive shells that punish clustered and armoured arachnids.",
         upgrades=[
             (140, "Fragment Shells", "Wider blast radius and more shrapnel.",
              dict(damage_add=18, splash_add=15)),
             (220, "HEAT Loader", "High-explosive anti-tank charge burns through plating.",
              dict(damage_add=24, splash_add=20, armor_pen_add=0.15)),
             (340, "Siege Breaker", "Massive shells crack even elite carapaces and leave them corroded.",
              dict(damage_add=35, splash_add=25, armor_pen_add=0.1, corrode_duration_add=4.0,
                   special_note="Splash hits are corroded for 4 seconds.")),
         ]),
    dict(id="flame", name="Flame Vent", role="Close area denial",
         cost=140, dtype="fire", damage=10, rate=2.6, rng=125, speed=0,
         burn=8, burn_dur=2.0, style="flame", color=(0.95, 0.35, 0.12), key="3",
         desc="Short-range ignition vent. Sets every ground enemy in the ring alight.",
         upgrades=[
             (110, "Wide Nozzle", "Longer reach and a hotter burn.",
              dict(damage_add=4, burn_add=3, range_add=10)),
             (170, "Fuel Agitator", "Sticky fuel keeps burning after the vent stops.",
              dict(damage_add=6, burn_add=5, range_add=15, slow_duration_add=0.5)),
             (280, "White-Hot Vent", "Ceramic-lined vent turns the road into a furnace.",
              dict(damage_add=9, burn_add=8, range_add=20,
                   special_note="Burn damage lasts longer.")),
         ]),
    dict(id="tesla", name="Arc Coil", role="Chain lightning",
         cost=220, dtype="electric", damage=30, rate=0.9, rng=205, speed=0,
         chains=2, stun=0.15, stun_dur=0.35, anti_air=True, style="tesla",
         color=(0.4, 0.78, 1.0), key="4",
         desc="Arcs of static leap between nearby enemies. One of the few early anti-air towers.",
         upgrades=[
             (160, "Capacitor Bank", "Extra charge feeds one more chain.",
              dict(damage_add=12, chain_add=1)),
             (240, "Overcharge", "Faster discharge and a stronger stun field.",
              dict(damage_add=18, rate_add=0.15, chain_add=1,
                   special_note="Improved stun chance.")),
             (360, "Storm Crown", "A crown of coils chains through entire swarms.",
              dict(damage_add=30, chain_add=2,
                   special_note="Chains to five targets.")),
         ]),
    dict(id="missile", name="Missile Battery", role="Anti-swarm / anti-air",
         cost=260, dtype="explosive", damage=34, rate=0.75, rng=275, speed=520,
         splash=55, anti_air=True, missiles=1, style="missile",
         color=(0.92, 0.72, 0.3), key="5",
         desc="Homing missile cells. The dedicated answer to flyers and tight groups.",
         upgrades=[
             (180, "Twin Rack", "Adds a second missile to every salvo.",
              dict(damage_add=14, splash_add=10, missiles_add=1)),
             (270, "Guidance Suite", "Better tracking and a faster reload.",
              dict(damage_add=20, splash_add=15, rate_add=0.15)),
             (410, "Saturation Rack", "Three missiles per salvo saturate the road.",
              dict(damage_add=32, splash_add=20, missiles_add=1,
                   special_note="Three missiles per salvo.")),
         ]),
    dict(id="cryo", name="Cryo Emitter", role="Crowd control",
         cost=200, dtype="frost", damage=9, rate=1.0, rng=205, speed=560,
         splash=50, slow=0.4, slow_dur=2.0, freeze=0.12, freeze_dur=0.35,
         anti_air=True, style="cryo", color=(0.5, 0.82, 0.95), key="6",
         desc="Cryogenic shells chill an area, slowing enemies and sometimes freezing them solid.",
         upgrades=[
             (150, "Cryo Mix", "Colder burst and a larger freezing cloud.",
              dict(damage_add=5, slow_add=0.08, splash_add=10)),
             (230, "Deep Freeze", "The chill clings to carapace and locks limbs in place.",
              dict(damage_add=8, slow_add=0.1, slow_duration_add=0.7,
                   freeze_chance_add=0.1, freeze_duration_add=0.15)),
             (330, "Absolute Zero", "A wide field of near-solid air.",
              dict(damage_add=14, slow_add=0.12, range_add=25, splash_add=15,
                   freeze_chance_add=0.08, freeze_duration_add=0.2,
                   special_note="Powerful area slow with frequent freezes.")),
         ]),
    dict(id="rail", name="Rail Sniper", role="Long-range precision",
         cost=300, dtype="kinetic", damage=100, rate=0.35, rng=380, speed=0,
         pen=0.7, crit=0.15, anti_air=True, style="rail",
         color=(0.86, 0.9, 0.95), key="7",
         desc="Hypervelocity rail shot. Deletes high-value targets before they reach the base.",
         upgrades=[
             (220, "Tungsten Slug", "Denser round with better armour defeat.",
              dict(damage_add=45, armor_pen_add=0.1)),
             (330, "Extended Rails", "Longer accelerator stretches the kill zone.",
              dict(damage_add=70, range_add=40,
                   special_note="Critical hits deal extra damage.")),
             (500, "Executioner Rounds", "Finishes wounded elites in a single shot.",
              dict(damage_add=120, armor_pen_add=0.15, range_add=40,
                   special_note="Bonus damage against wounded targets.")),
         ]),
    dict(id="relay", name="Command Relay", role="Support / economy",
         cost=250, dtype="support", damage=0, rate=0, rng=0, speed=0,
         support_radius=170, support_buff=0.2, income=25, style="relay",
         color=(0.35, 0.9, 0.62), key="8",
         desc="Buffs nearby towers and pays a credit stipend at the end of each wave.",
         upgrades=[
             (180, "Signal Array", "Wider command aura and a larger stipend.",
              dict(buff_add=0.08, range_add=20, income_add=10)),
             (280, "Targeting Uplink", "Nearby towers fire harder and faster.",
              dict(buff_add=0.1, range_add=30, income_add=15)),
             (430, "Orbital Command", "Battlefield-wide coordination and rich stipends.",
              dict(buff_add=0.15, range_add=40, income_add=25,
                   special_note="Large aura and income.")),
         ]),
    dict(id="mine", name="Mine Layer", role="Trap defence",
         cost=180, dtype="explosive", damage=0, rate=0, rng=180, speed=0,
         deploy=4.5, mine_damage=80, style="mine", color=(0.9, 0.55, 0.18), key="9",
         desc="Scatters proximity mines on nearby road cells. Excellent at chokepoints.",
         upgrades=[
             (140, "Larger Payload", "Mines hit harder and deploy quicker.",
              dict(mine_damage_add=30, deploy_interval_add=-0.4)),
             (210, "Rapid Dispenser", "A motorised hatch lays traps continuously.",
              dict(mine_damage_add=45, deploy_interval_add=-0.5)),
             (320, "Cluster Mines", "Each mine seeds a lethal fragmentation ring.",
              dict(mine_damage_add=70, deploy_interval_add=-0.6,
                   special_note="Very fast deployment.")),
         ]),
    dict(id="orbital", name="Orbital Lance", role="Late-game ultimate",
         cost=500, dtype="energy", damage=170, rate=0.22, rng=340, speed=0,
         splash=110, anti_air=True, style="orbital",
         color=(1.0, 0.45, 0.7), key="0",
         desc="Charges a delayed orbital beam onto the densest enemy cluster.",
         upgrades=[
             (390, "Focused Lens", "Tighter beam, far more damage.",
              dict(damage_add=75, splash_add=15, rate_add=0.03)),
             (540, "Reactor Tap", "Direct reactor feed accelerates the charge cycle.",
              dict(damage_add=110, splash_add=20, rate_add=0.04)),
             (760, "Godspear Protocol", "The full lance of the orbiting platform.",
              dict(damage_add=180, splash_add=30, rate_add=0.05,
                   special_note="Devastating area strike.")),
         ]),
]


def write_tower(t: dict) -> None:
    ups = t.get("upgrades", [])
    ext = [
        'script = ExtResource("1_tower")',
    ]
    parts = [f'[gd_resource type="Resource" script_class="TowerData" load_steps={3 + len(ups)} format=3]', ""]
    parts.append('[ext_resource type="Script" path="res://scripts/towers/TowerData.gd" id="1_tower"]')
    parts.append('[ext_resource type="Script" path="res://scripts/towers/UpgradeData.gd" id="2_upgrade"]')
    parts.append("")
    for i, up in enumerate(ups, 1):
        parts.append(f'[sub_resource type="Resource" id="Upgrade_{i}"]')
        parts.append('script = ExtResource("2_upgrade")')
        parts.append(f"level = {i + 1}")
        parts.append(f"cost = {up[0]}")
        parts.append(f"display_name = {q(up[1])}")
        parts.append(f"description = {q(up[2])}")
        for k, v in up[3].items():
            if v is True:
                parts.append(f"{k} = true")
            elif v is False:
                parts.append(f"{k} = false")
            elif isinstance(v, str):
                parts.append(f"{k} = {q(v)}")
            else:
                parts.append(f"{k} = {v}")
        parts.append("")
    parts.append("[resource]")
    parts.append('script = ExtResource("1_tower")')
    fields = {
        "id": q(t["id"]), "display_name": q(t["name"]), "role": q(t["role"]),
        "description": q(t["desc"]), "cost": t["cost"], "sell_ratio": 0.7,
        "max_level": 4, "damage_type": q(t["dtype"]), "damage": t.get("damage", 0),
        "attack_rate": t.get("rate", 0), "attack_range": t.get("rng", 0),
        "projectile_speed": t.get("speed", 0), "splash_radius": t.get("splash", 0),
        "slow_amount": t.get("slow", 0), "slow_duration": t.get("slow_dur", 0),
        "armor_penetration": t.get("pen", 0), "chain_count": t.get("chains", 0),
        "burn_dps": t.get("burn", 0), "burn_duration": t.get("burn_dur", 0),
        "missiles": t.get("missiles", 1), "anti_air": t.get("anti_air", False),
        "can_target_ground": True, "crit_chance": t.get("crit", 0),
        "stun_chance": t.get("stun", 0), "stun_duration": t.get("stun_dur", 0),
        "freeze_chance": t.get("freeze", 0), "freeze_duration": t.get("freeze_dur", 0),
        "corrode_duration": t.get("corrode", 0),
        "support_radius": t.get("support_radius", 0), "support_buff": t.get("support_buff", 0),
        "income_per_wave": t.get("income", 0), "deploy_interval": t.get("deploy", 0),
        "mine_damage": t.get("mine_damage", 0),
        "projectile_scene_path": q("res://scenes/towers/Projectile.tscn" if t.get("speed", 0) > 0 else ""),
        "scene_path": q(f"res://scenes/towers/Tower{t['id'].title().replace('_','')}.tscn"),
        "visual_style": q(t["style"]), "primary_color": color(t["color"]),
        "shortcut": q(t["key"]),
        "tip": q(t["desc"]),
    }
    for k, v in fields.items():
        parts.append(f"{k} = {fmt(v)}")
    if ups:
        parts.append("upgrades = [" + ", ".join(f'SubResource("Upgrade_{i}")' for i in range(1, len(ups) + 1)) + "]")
    else:
        parts.append("upgrades = []")
    write(RES / "towers" / f"tower_{t['id']}.tres", "\n".join(parts) + "\n")


# ---------------------------------------------------------------------------
# Enemies
# ---------------------------------------------------------------------------
ENEMIES = [
    dict(id="scout", name="Dust Scout", role="Fast swarm", hp=48, speed=136, armor=0,
         bounty=8, leak=1, scale=0.72, style="scout", body=(0.78, 0.34, 0.16), accent=(1.0, 0.72, 0.28),
         res={"kinetic": 1.0, "explosive": 0.8, "fire": 1.0, "electric": 1.1, "frost": 0.75},
         desc="A quick, fragile runner that probes both roads in packs."),
    dict(id="worker", name="Regolith Worker", role="Swarm", hp=72, speed=62, armor=2,
         bounty=7, leak=1, scale=0.88, style="worker", body=(0.55, 0.27, 0.18), accent=(0.92, 0.6, 0.25),
         res={"kinetic": 0.8, "explosive": 1.2, "fire": 0.9, "electric": 1.0, "frost": 1.0},
         desc="Slow, cheap and endless. Splash damage clears them efficiently."),
    dict(id="warrior", name="Chitin Warrior", role="Standard melee", hp=175, speed=76, armor=6,
         bounty=14, leak=1, scale=1.02, style="warrior", body=(0.66, 0.22, 0.16), accent=(1.0, 0.5, 0.2),
         res={"kinetic": 0.75, "explosive": 1.15, "fire": 0.9, "electric": 1.0, "frost": 0.9},
         desc="Balanced frontline arachnid with hardened plates."),
    dict(id="spitter", name="Acid Spitter", role="Ranged", hp=128, speed=64, armor=2,
         bounty=15, leak=1, scale=0.95, style="spitter", body=(0.42, 0.6, 0.25), accent=(0.65, 1.0, 0.35),
         ranged=150, ranged_interval=5.0,
         res={"kinetic": 1.0, "explosive": 1.0, "fire": 1.15, "electric": 1.0, "frost": 1.0},
         desc="Stops near towers and spits corrosive acid, disabling them briefly."),
    dict(id="healer", name="Brood Weaver", role="Support", hp=118, speed=58, armor=1,
         bounty=18, leak=1, scale=0.95, style="healer", body=(0.4, 0.28, 0.48), accent=(0.85, 0.55, 1.0),
         heal_radius=135, heal_amount=16, heal_interval=1.8,
         res={"kinetic": 1.0, "explosive": 1.0, "fire": 1.2, "electric": 1.0, "frost": 0.9},
         desc="Pulses regenerative silk into nearby arachnids. Kill it first."),
    dict(id="burrower", name="Burrower", role="Ambusher", hp=145, speed=86, armor=2,
         bounty=16, leak=1, scale=0.98, style="burrower", body=(0.55, 0.4, 0.22), accent=(1.0, 0.75, 0.3),
         burrowed=True,
         res={"kinetic": 0.6, "explosive": 1.15, "fire": 1.0, "electric": 0.9, "frost": 1.0},
         desc="Dives under the regolith and surfaces near the defences."),
    dict(id="shieldbearer", name="Shieldbearer", role="Armoured", hp=155, speed=58, armor=8,
         bounty=20, leak=1, scale=1.06, style="shield", shield=110, shield_regen=18, shield_delay=5.0,
         body=(0.36, 0.42, 0.55), accent=(0.5, 0.8, 1.0),
         res={"kinetic": 0.7, "explosive": 0.95, "fire": 0.9, "electric": 1.25, "frost": 1.0},
         desc="Projects a regenerating energy shield. Electric damage breaks it quickly."),
    dict(id="flyer", name="Rift Flyer", role="Air", hp=92, speed=118, armor=0,
         bounty=14, leak=1, scale=0.82, style="flyer", flying=True,
         body=(0.5, 0.25, 0.6), accent=(0.9, 0.4, 1.0),
         res={"kinetic": 1.0, "explosive": 1.15, "fire": 0.9, "electric": 0.85, "frost": 0.9},
         desc="Hovers above the road. Only anti-air towers can engage it."),
    dict(id="elite", name="Arachnid Elite", role="Mini-boss", hp=950, speed=55, armor=12,
         bounty=90, leak=3, scale=1.45, style="elite",
         body=(0.3, 0.18, 0.2), accent=(1.0, 0.2, 0.15), elite=True,
         res={"kinetic": 0.6, "explosive": 1.2, "fire": 0.9, "electric": 1.1, "frost": 0.8, "energy": 1.3},
         desc="A hulking command breed with heavy plating and a vicious charge."),
    dict(id="boss", name="Brood Tyrant", role="Boss", hp=4200, speed=42, armor=18,
         bounty=400, leak=10, scale=2.2, style="boss",
         body=(0.22, 0.12, 0.16), accent=(1.0, 0.15, 0.1), boss=True,
         res={"kinetic": 0.65, "explosive": 1.1, "fire": 0.85, "electric": 1.0, "frost": 0.7, "energy": 1.2},
         desc="The Brood Tyrant. Three phases, summons, a shield surge and a final enrage."),
]


def write_enemy(e: dict) -> None:
    parts = ['[gd_resource type="Resource" script_class="EnemyData" load_steps=2 format=3]', ""]
    parts.append('[ext_resource type="Script" path="res://scripts/enemies/EnemyData.gd" id="1_enemy"]')
    parts.append("")
    parts.append("[resource]")
    parts.append('script = ExtResource("1_enemy")')
    fields = {
        "id": q(e["id"]), "display_name": q(e["name"]), "role": q(e["role"]),
        "description": q(e["desc"]), "max_health": e["hp"], "speed": e["speed"],
        "armor": e["armor"], "bounty": e["bounty"], "leak_damage": e["leak"],
        "spawn_weight": 1.0, "flying": e.get("flying", False),
        "burrowed": e.get("burrowed", False), "shield": e.get("shield", 0),
        "shield_regen": e.get("shield_regen", 0), "shield_delay": e.get("shield_delay", 5.0),
        "heal_radius": e.get("heal_radius", 0), "heal_amount": e.get("heal_amount", 0),
        "heal_interval": e.get("heal_interval", 2.0), "ranged_range": e.get("ranged", 0),
        "ranged_interval": e.get("ranged_interval", 4.0),
        "is_elite": e.get("elite", False), "is_boss": e.get("boss", False),
        "scene_path": q("res://scenes/enemies/EnemyShield.tscn" if e["id"] == "shieldbearer"
                        else f"res://scenes/enemies/Enemy{e['id'].title().replace('_','')}.tscn"),
        "visual_style": q(e["style"]), "body_color": color(e["body"]),
        "accent_color": color(e["accent"]), "body_scale": e["scale"],
        "tip": q(e["desc"]),
    }
    for k, v in fields.items():
        parts.append(f"{k} = {fmt(v)}")
    res = e["res"]
    parts.append("resistances = {" + ", ".join(f'{q(k)}: {v}' for k, v in res.items()) + "}")
    parts.append("immune_to = []")
    write(RES / "enemies" / f"enemy_{e['id']}.tres", "\n".join(parts) + "\n")


# ---------------------------------------------------------------------------
# Abilities
# ---------------------------------------------------------------------------
ABILITIES = [
    dict(id="orbital_strike", name="Orbital Strike", cooldown=55, uses=-1,
         target="area", radius=135, delay=1.2, damage=280, dtype="explosive",
         key="Q", col=(1.0, 0.55, 0.15),
         desc="Mark a zone. After a short delay the orbital platform delivers a heavy explosive strike."),
    dict(id="emp", name="EMP Pulse", cooldown=34, uses=-1, target="area", radius=155,
         delay=0.0, damage=35, dtype="electric", stun=2.5, slow=0.5, duration=3.0,
         key="W", col=(0.35, 0.75, 1.0),
         desc="Stuns and slows every arachnid in the zone, and overloads energy shields."),
    dict(id="reinforcement_drones", name="Reinforcement Drones", cooldown=46, uses=-1,
         target="area", radius=150, duration=14.0, damage=22, dtype="kinetic",
         key="E", col=(0.55, 0.95, 0.6),
         desc="Deploys two autonomous gun drones over a road section for fourteen seconds."),
    dict(id="emergency_repair", name="Emergency Repair", cooldown=60, uses=2,
         target="self", radius=0, heal=25, key="R", col=(0.98, 0.35, 0.3),
         desc="Restores 25 base integrity. Limited to two charges per level."),
    dict(id="supply_drop", name="Supply Drop", cooldown=50, uses=2,
         target="self", radius=0, credits=150, key="T", col=(0.95, 0.8, 0.3),
         desc="Calls down a credit cache. Limited to two charges per level."),
]


def write_ability(a: dict) -> None:
    parts = ['[gd_resource type="Resource" script_class="AbilityData" load_steps=2 format=3]', ""]
    parts.append('[ext_resource type="Script" path="res://scripts/core/AbilityData.gd" id="1_ability"]')
    parts.append("")
    parts.append("[resource]")
    parts.append('script = ExtResource("1_ability")')
    fields = {
        "id": q(a["id"]), "display_name": q(a["name"]), "description": q(a["desc"]),
        "cooldown": a["cooldown"], "uses_per_level": a["uses"],
        "target_mode": q(a["target"]), "radius": a.get("radius", 0),
        "delay": a.get("delay", 0), "damage": a.get("damage", 0),
        "damage_type": q(a.get("dtype", "explosive")), "duration": a.get("duration", 0),
        "stun_duration": a.get("stun", 0), "slow_amount": a.get("slow", 0),
        "credits": a.get("credits", 0), "heal_amount": a.get("heal", 0),
        "shortcut": q(a["key"]), "color": color(a["col"]),
    }
    for k, v in fields.items():
        parts.append(f"{k} = {fmt(v)}")
    write(RES / "abilities" / f"ability_{a['id']}.tres", "\n".join(parts) + "\n")


# ---------------------------------------------------------------------------
# Levels and waves
# ---------------------------------------------------------------------------
# Compact route definitions: turns in cell coordinates. PathManager expands them.
LEVELS = [
    dict(n=1, id="landing_zone", name="Landing Zone", diff="Easy", credits=620, hp=100, reward=120,
         a=[(0, 2), (14, 2), (14, 7), (21, 7)], b=[(0, 7), (6, 7), (6, 5), (21, 5)],
         theme="landing", ground=(0.46, 0.2, 0.13), dust=(0.9, 0.52, 0.3), seed=11,
         towers=["pulse", "siege", "flame", "relay", "mine"], abilities=["orbital_strike", "emergency_repair"],
         desc="The first outpost. Learn placement, upgrades and wave timing.",
         waves=[
             [("worker", 6, 0, 0.7, 0)],
             [("scout", 8, 1, 0.45, 0)],
             [("worker", 8, 0, 0.6, 0), ("scout", 6, 1, 0.5, 1.2)],
             [("scout", 10, 0, 0.4, 0), ("worker", 6, 1, 0.65, 1.0)],
             [("warrior", 4, 0, 1.0, 0), ("scout", 8, 1, 0.45, 0.8)],
             [("warrior", 6, 0, 0.9, 0), ("warrior", 4, 1, 0.9, 1.5), ("scout", 8, 1, 0.5, 4.0)],
         ]),
    dict(n=2, id="supply_route", name="Supply Route", diff="Easy", credits=660, hp=100, reward=130,
         a=[(0, 3), (9, 3), (9, 6), (21, 6)], b=[(0, 8), (13, 8), (13, 5), (21, 5)],
         theme="supply", ground=(0.43, 0.22, 0.15), dust=(0.86, 0.52, 0.34), seed=22,
         towers=["pulse", "siege", "flame", "cryo", "relay", "mine"],
         abilities=["orbital_strike", "emp", "emergency_repair"],
         desc="Two supply roads cross under the cargo cranes. Make the first upgrade decision.",
         waves=[
             [("worker", 8, 0, 0.55, 0), ("worker", 6, 1, 0.6, 0.5)],
             [("scout", 10, 0, 0.4, 0), ("scout", 8, 1, 0.45, 1.0)],
             [("warrior", 4, 0, 0.9, 0), ("worker", 10, 1, 0.5, 0.6)],
             [("spitter", 2, 0, 2.0, 0), ("warrior", 5, 1, 0.9, 0.5), ("scout", 8, 1, 0.4, 2.0)],
             [("scout", 12, 0, 0.35, 0), ("worker", 12, 1, 0.45, 0)],
             [("warrior", 7, 0, 0.8, 0), ("spitter", 3, 1, 1.8, 0.8), ("worker", 8, 1, 0.5, 3.0)],
             [("warrior", 8, 0, 0.7, 0), ("warrior", 8, 1, 0.7, 0.6), ("spitter", 4, 1, 1.6, 3.0)],
         ]),
    dict(n=3, id="canyon_junction", name="Canyon Junction", diff="Easy", credits=700, hp=100, reward=140,
         a=[(0, 2), (10, 2), (10, 5), (21, 5)], b=[(0, 9), (7, 9), (7, 1), (21, 1)],
         theme="canyon", ground=(0.5, 0.24, 0.14), dust=(0.92, 0.55, 0.3), seed=33,
         towers=["pulse", "siege", "flame", "tesla", "cryo", "relay", "mine"],
         abilities=["orbital_strike", "emp", "emergency_repair"],
         desc="The roads cross above the canyon throat. Stack area damage on the junction.",
         waves=[
             [("worker", 10, 0, 0.5, 0), ("worker", 10, 1, 0.5, 0.4)],
             [("scout", 12, 0, 0.35, 0), ("scout", 12, 1, 0.35, 0.8)],
             [("warrior", 6, 0, 0.8, 0), ("spitter", 2, 1, 2.0, 0.5)],
             [("worker", 16, 0, 0.4, 0), ("scout", 10, 1, 0.35, 1.0)],
             [("warrior", 6, 0, 0.8, 0), ("warrior", 6, 1, 0.8, 0.4), ("spitter", 3, 0, 1.8, 3.0)],
             [("scout", 16, 0, 0.3, 0), ("warrior", 8, 1, 0.7, 0.5)],
             [("spitter", 4, 0, 1.6, 0), ("warrior", 8, 1, 0.7, 0), ("worker", 12, 1, 0.4, 3.0)],
             [("warrior", 10, 0, 0.65, 0), ("warrior", 10, 1, 0.65, 0.5), ("spitter", 5, 0, 1.5, 3.0)],
         ]),
    dict(n=4, id="relay_station", name="Relay Station", diff="Easy", credits=730, hp=100, reward=150,
         a=[(0, 2), (6, 2), (6, 8), (16, 8), (16, 4), (21, 4)], b=[(0, 9), (9, 9), (14, 9), (14, 3), (21, 3)],
         theme="relay", ground=(0.4, 0.2, 0.16), dust=(0.82, 0.5, 0.38), seed=44,
         towers=["pulse", "siege", "flame", "tesla", "cryo", "relay", "mine"],
         abilities=["orbital_strike", "emp", "emergency_repair", "supply_drop"],
         desc="Antenna masts and solar relays split the lanes. Burn the early swarm.",
         waves=[
             [("scout", 14, 0, 0.3, 0), ("scout", 10, 1, 0.4, 1.0)],
             [("worker", 16, 0, 0.4, 0), ("warrior", 4, 1, 0.9, 0.5)],
             [("scout", 18, 0, 0.28, 0), ("worker", 14, 1, 0.4, 0.8)],
             [("warrior", 8, 0, 0.75, 0), ("spitter", 3, 1, 1.8, 0.5)],
             [("worker", 20, 0, 0.35, 0), ("scout", 14, 1, 0.3, 0.6)],
             [("warrior", 8, 0, 0.75, 0), ("warrior", 8, 1, 0.75, 0.5), ("spitter", 4, 1, 1.6, 3.0)],
             [("spitter", 5, 0, 1.5, 0), ("warrior", 10, 1, 0.65, 0.4), ("scout", 14, 1, 0.3, 2.5)],
             [("warrior", 12, 0, 0.6, 0), ("worker", 20, 1, 0.35, 0), ("spitter", 5, 1, 1.5, 3.0)],
         ]),
    dict(n=5, id="ore_field", name="Ore Field", diff="Easy", credits=760, hp=100, reward=180,
         a=[(0, 1), (5, 1), (5, 5), (17, 5), (17, 9), (21, 9)], b=[(0, 9), (11, 9), (11, 3), (21, 3)],
         theme="ore", ground=(0.42, 0.19, 0.12), dust=(0.88, 0.48, 0.28), seed=55,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "relay", "mine"],
         abilities=["orbital_strike", "emp", "emergency_repair", "supply_drop"],
         desc="The first Arachnid Elite surfaces among the ore crushers. Sell and rebuild.",
         waves=[
             [("worker", 12, 0, 0.4, 0), ("scout", 12, 1, 0.32, 0.5)],
             [("warrior", 6, 0, 0.8, 0), ("spitter", 3, 1, 1.8, 0.5)],
             [("worker", 18, 0, 0.35, 0), ("scout", 16, 1, 0.28, 0.8)],
             [("warrior", 10, 0, 0.7, 0), ("warrior", 8, 1, 0.75, 0.5)],
             [("scout", 22, 0, 0.24, 0), ("worker", 18, 1, 0.35, 0.5)],
             [("spitter", 5, 0, 1.5, 0), ("warrior", 10, 1, 0.65, 0.4)],
             [("warrior", 12, 0, 0.6, 0), ("warrior", 12, 1, 0.6, 0.4)],
             [("elite", 1, 0, 1, 0), ("warrior", 10, 1, 0.65, 1.0), ("spitter", 5, 1, 1.4, 5.0)],
         ]),
    dict(n=6, id="broken_pipeline", name="Broken Pipeline", diff="Medium", credits=780, hp=95, reward=190,
         a=[(0, 4), (9, 4), (9, 1), (13, 1), (13, 6), (21, 6)], b=[(0, 9), (9, 9), (9, 4), (16, 4), (16, 9), (21, 9)],
         theme="pipeline", ground=(0.38, 0.2, 0.15), dust=(0.82, 0.5, 0.34), seed=66,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine"],
         abilities=["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"],
         desc="Armoured shieldbearers guard the ruptured pipeline. Bring corrosion and splash.",
         waves=[
             [("worker", 14, 0, 0.38, 0), ("scout", 12, 1, 0.3, 0.5)],
             [("shieldbearer", 3, 0, 1.4, 0), ("warrior", 8, 1, 0.7, 0.5)],
             [("worker", 20, 0, 0.3, 0), ("scout", 18, 1, 0.26, 1.0)],
             [("shieldbearer", 4, 0, 1.3, 0), ("warrior", 10, 1, 0.65, 0)],
             [("warrior", 12, 0, 0.6, 0), ("shieldbearer", 4, 1, 1.2, 0.5), ("spitter", 4, 1, 1.5, 4.0)],
             [("worker", 24, 0, 0.28, 0), ("shieldbearer", 5, 1, 1.2, 0.5)],
             [("warrior", 14, 0, 0.55, 0), ("spitter", 6, 1, 1.4, 0.5)],
             [("shieldbearer", 6, 0, 1.0, 0), ("warrior", 12, 1, 0.6, 0.4)],
             [("elite", 1, 0, 1, 0), ("shieldbearer", 6, 1, 1.0, 1.0), ("warrior", 10, 1, 0.6, 4.0)],
         ]),
    dict(n=7, id="dust_basin", name="Dust Basin", diff="Medium", credits=800, hp=90, reward=200,
         a=[(0, 2), (8, 2), (8, 6), (14, 6), (14, 2), (21, 2)], b=[(0, 9), (12, 9), (12, 4), (18, 4), (18, 9), (21, 9)],
         theme="dust", ground=(0.52, 0.27, 0.16), dust=(0.95, 0.6, 0.34), seed=77,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine"],
         abilities=["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"],
         desc="Dust storms hide the first rift flyers. Anti-air coverage is mandatory.",
         waves=[
             [("worker", 14, 0, 0.35, 0), ("scout", 14, 1, 0.28, 0.5)],
             [("flyer", 5, 0, 1.2, 0), ("warrior", 8, 1, 0.7, 0.5)],
             [("flyer", 7, 0, 1.1, 0), ("flyer", 5, 1, 1.2, 1.0)],
             [("shieldbearer", 4, 0, 1.3, 0), ("flyer", 6, 1, 1.1, 0.5)],
             [("worker", 22, 0, 0.28, 0), ("flyer", 8, 1, 1.0, 0.8)],
             [("warrior", 12, 0, 0.6, 0), ("flyer", 8, 1, 1.0, 0.5), ("spitter", 4, 1, 1.4, 4.0)],
             [("flyer", 10, 0, 0.9, 0), ("shieldbearer", 5, 1, 1.2, 0.5)],
             [("warrior", 14, 0, 0.55, 0), ("flyer", 10, 1, 0.9, 0.5)],
             [("elite", 1, 0, 1, 0), ("flyer", 12, 1, 0.85, 1.0), ("warrior", 12, 1, 0.6, 4.0)],
         ]),
    dict(n=8, id="excavation_site", name="Excavation Site", diff="Medium", credits=820, hp=90, reward=210,
         a=[(0, 3), (6, 3), (6, 7), (15, 7), (15, 3), (21, 3)], b=[(0, 8), (10, 8), (10, 4), (18, 4), (18, 8), (21, 8)],
         theme="excavation", ground=(0.4, 0.18, 0.12), dust=(0.85, 0.46, 0.3), seed=88,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine"],
         abilities=["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"],
         desc="Burrowers tunnel beneath the dig site. Watch the road at the central intersection.",
         waves=[
             [("worker", 16, 0, 0.32, 0), ("burrower", 4, 1, 1.2, 0.5)],
             [("burrower", 6, 0, 1.1, 0), ("warrior", 10, 1, 0.65, 0.5)],
             [("scout", 20, 0, 0.26, 0), ("burrower", 5, 1, 1.1, 0.8)],
             [("burrower", 8, 0, 1.0, 0), ("shieldbearer", 4, 1, 1.3, 0.5)],
             [("worker", 24, 0, 0.26, 0), ("burrower", 8, 1, 1.0, 0.5)],
             [("spitter", 6, 0, 1.3, 0), ("burrower", 8, 1, 1.0, 0.6)],
             [("warrior", 14, 0, 0.55, 0), ("burrower", 8, 1, 1.0, 0.6), ("flyer", 6, 1, 1.0, 4.0)],
             [("burrower", 10, 0, 0.9, 0), ("shieldbearer", 6, 1, 1.1, 0.5)],
             [("elite", 1, 0, 1, 0), ("burrower", 10, 1, 0.9, 1.0), ("warrior", 12, 1, 0.6, 4.0)],
         ]),
    dict(n=9, id="solar_array", name="Solar Array", diff="Medium", credits=840, hp=85, reward=220,
         a=[(0, 1), (4, 1), (4, 5), (10, 5), (10, 9), (21, 9)], b=[(0, 9), (7, 9), (7, 3), (14, 3), (14, 1), (21, 1)],
         theme="solar", ground=(0.44, 0.24, 0.18), dust=(0.9, 0.56, 0.4), seed=99,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine"],
         abilities=["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"],
         desc="Brood weavers and shieldbearers advance under the solar mirrors. Prioritise the healers.",
         waves=[
             [("worker", 16, 0, 0.32, 0), ("healer", 2, 1, 2.0, 0.5)],
             [("shieldbearer", 5, 0, 1.2, 0), ("warrior", 10, 1, 0.65, 0.5)],
             [("healer", 3, 0, 1.8, 0), ("worker", 20, 1, 0.3, 0.5)],
             [("shieldbearer", 6, 0, 1.1, 0), ("healer", 2, 1, 1.8, 0.5)],
             [("flyer", 8, 0, 1.0, 0), ("shieldbearer", 5, 1, 1.2, 0.5)],
             [("healer", 4, 0, 1.6, 0), ("warrior", 14, 1, 0.55, 0.5)],
             [("shieldbearer", 7, 0, 1.0, 0), ("healer", 3, 1, 1.6, 0.5), ("flyer", 8, 1, 1.0, 4.0)],
             [("warrior", 16, 0, 0.5, 0), ("healer", 4, 1, 1.5, 0.5)],
             [("shieldbearer", 8, 0, 0.95, 0), ("flyer", 10, 1, 0.9, 0.5), ("healer", 3, 1, 1.5, 3.0)],
             [("elite", 1, 0, 1, 0), ("healer", 3, 1, 1.5, 1.0), ("shieldbearer", 6, 1, 1.0, 3.0), ("flyer", 8, 1, 0.9, 7.0)],
         ]),
    dict(n=10, id="command_ridge", name="Command Ridge", diff="Medium", credits=860, hp=85, reward=240,
         a=[(0, 2), (6, 2), (6, 6), (12, 6), (12, 2), (18, 2), (18, 6), (21, 6)],
         b=[(0, 9), (9, 9), (9, 3), (15, 3), (15, 9), (21, 9)],
         theme="ridge", ground=(0.36, 0.18, 0.14), dust=(0.8, 0.46, 0.34), seed=110,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital"],
         abilities=["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"],
         desc="Command Ridge is the last easy posting. Mixed waves hit both roads at once.",
         waves=[
             [("worker", 18, 0, 0.28, 0), ("scout", 16, 1, 0.26, 0.4)],
             [("shieldbearer", 5, 0, 1.1, 0), ("burrower", 5, 1, 1.0, 0.5)],
             [("flyer", 8, 0, 1.0, 0), ("spitter", 5, 1, 1.3, 0.5)],
             [("healer", 3, 0, 1.6, 0), ("warrior", 14, 1, 0.55, 0.5)],
             [("shieldbearer", 7, 0, 1.0, 0), ("burrower", 7, 1, 0.9, 0.5)],
             [("flyer", 10, 0, 0.9, 0), ("healer", 3, 1, 1.5, 0.5), ("worker", 20, 1, 0.3, 2.0)],
             [("warrior", 16, 0, 0.5, 0), ("shieldbearer", 7, 1, 1.0, 0.5)],
             [("burrower", 9, 0, 0.9, 0), ("flyer", 10, 1, 0.9, 0.5), ("healer", 3, 1, 1.5, 4.0)],
             [("shieldbearer", 8, 0, 0.95, 0), ("warrior", 16, 1, 0.5, 0.5), ("spitter", 6, 1, 1.3, 4.0)],
             [("elite", 1, 0, 1, 0), ("elite", 1, 1, 1, 2.0), ("warrior", 14, 1, 0.55, 4.0), ("flyer", 10, 1, 0.9, 8.0)],
         ]),
    dict(n=11, id="red_divide", name="Red Divide", diff="Very Hard", credits=760, hp=80, reward=260,
         a=[(0, 1), (8, 1), (8, 6), (14, 6), (14, 1), (21, 1)], b=[(0, 9), (10, 9), (10, 4), (18, 4), (18, 9), (21, 9)],
         theme="red", ground=(0.55, 0.22, 0.13), dust=(1.0, 0.5, 0.25), seed=121,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital"],
         abilities=["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"],
         desc="A tight economy and a divided road. Every credit and every ability matters.",
         waves=[
             [("worker", 18, 0, 0.28, 0), ("scout", 18, 1, 0.24, 0.5)],
             [("shieldbearer", 6, 0, 1.1, 0), ("burrower", 6, 1, 0.95, 0.5)],
             [("flyer", 10, 0, 0.9, 0), ("healer", 2, 1, 1.6, 0.5)],
             [("warrior", 18, 0, 0.48, 0), ("shieldbearer", 7, 1, 1.0, 0.5)],
             [("burrower", 10, 0, 0.85, 0), ("flyer", 12, 1, 0.85, 0.5)],
             [("healer", 4, 0, 1.5, 0), ("warrior", 18, 1, 0.48, 0.5), ("spitter", 6, 1, 1.3, 3.0)],
             [("shieldbearer", 9, 0, 0.9, 0), ("burrower", 10, 1, 0.85, 0.5)],
             [("flyer", 14, 0, 0.8, 0), ("healer", 4, 1, 1.4, 0.5), ("shieldbearer", 8, 1, 0.95, 2.0)],
             [("warrior", 20, 0, 0.45, 0), ("flyer", 12, 1, 0.85, 0.5), ("burrower", 10, 1, 0.85, 4.0)],
             [("shieldbearer", 10, 0, 0.85, 0), ("healer", 4, 1, 1.4, 0.5), ("warrior", 18, 1, 0.48, 2.0)],
             [("elite", 1, 0, 1, 0), ("elite", 1, 1, 1, 3.0), ("flyer", 12, 1, 0.85, 6.0), ("shieldbearer", 8, 1, 0.95, 10.0)],
         ]),
    dict(n=12, id="stormline", name="Stormline", diff="Very Hard", credits=780, hp=80, reward=270,
         a=[(0, 3), (5, 3), (5, 8), (11, 8), (11, 3), (17, 3), (17, 8), (21, 8)],
         b=[(0, 6), (21, 6)],
         theme="storm", ground=(0.32, 0.2, 0.22), dust=(0.65, 0.48, 0.58), seed=132,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital"],
         abilities=["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"],
         desc="Static storms feed the arachnids. Fast waves, slows and chokepoint defence.",
         waves=[
             [("scout", 24, 0, 0.22, 0), ("scout", 18, 1, 0.25, 0.5)],
             [("flyer", 12, 0, 0.8, 0), ("warrior", 14, 1, 0.55, 0.5)],
             [("burrower", 10, 0, 0.85, 0), ("shieldbearer", 7, 1, 1.0, 0.5)],
             [("scout", 28, 0, 0.2, 0), ("flyer", 12, 1, 0.8, 0.5)],
             [("healer", 4, 0, 1.4, 0), ("warrior", 20, 1, 0.45, 0.5)],
             [("shieldbearer", 10, 0, 0.9, 0), ("burrower", 12, 1, 0.8, 0.5)],
             [("flyer", 16, 0, 0.75, 0), ("healer", 4, 1, 1.4, 0.5), ("warrior", 18, 1, 0.48, 2.0)],
             [("scout", 30, 0, 0.18, 0), ("flyer", 16, 1, 0.75, 0.5)],
             [("shieldbearer", 12, 0, 0.85, 0), ("burrower", 12, 1, 0.8, 0.5), ("healer", 4, 1, 1.4, 3.0)],
             [("warrior", 22, 0, 0.42, 0), ("flyer", 18, 1, 0.7, 0.5)],
             [("elite", 1, 0, 1, 0), ("elite", 1, 1, 1, 2.0), ("flyer", 16, 1, 0.75, 5.0), ("shieldbearer", 10, 1, 0.85, 9.0)],
         ]),
    dict(n=13, id="deep_crater", name="Deep Crater", diff="Very Hard", credits=800, hp=75, reward=280,
         a=[(0, 2), (4, 2), (4, 7), (9, 7), (9, 3), (15, 3), (15, 8), (21, 8)],
         b=[(0, 9), (7, 9), (7, 5), (14, 5), (14, 9), (18, 9), (18, 3), (21, 3)],
         theme="crater", ground=(0.3, 0.16, 0.12), dust=(0.75, 0.4, 0.3), seed=143,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital"],
         abilities=["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"],
         desc="Heavy armour, burrowers, flyers and healers in one crushing descent.",
         waves=[
             [("shieldbearer", 8, 0, 1.0, 0), ("burrower", 8, 1, 0.9, 0.5)],
             [("flyer", 14, 0, 0.8, 0), ("healer", 4, 1, 1.4, 0.5)],
             [("warrior", 22, 0, 0.42, 0), ("shieldbearer", 9, 1, 0.95, 0.5)],
             [("burrower", 12, 0, 0.8, 0), ("flyer", 14, 1, 0.8, 0.5)],
             [("healer", 5, 0, 1.3, 0), ("shieldbearer", 10, 1, 0.9, 0.5)],
             [("flyer", 16, 0, 0.75, 0), ("burrower", 12, 1, 0.8, 0.5)],
             [("warrior", 24, 0, 0.4, 0), ("healer", 5, 1, 1.3, 0.5), ("flyer", 14, 1, 0.8, 3.0)],
             [("shieldbearer", 12, 0, 0.85, 0), ("burrower", 14, 1, 0.75, 0.5)],
             [("flyer", 18, 0, 0.7, 0), ("healer", 6, 1, 1.25, 0.5), ("shieldbearer", 10, 1, 0.9, 3.0)],
             [("warrior", 24, 0, 0.4, 0), ("burrower", 14, 1, 0.75, 0.5), ("flyer", 16, 1, 0.75, 4.0)],
             [("elite", 1, 0, 1, 0), ("shieldbearer", 12, 1, 0.85, 1.0), ("healer", 5, 1, 1.3, 5.0)],
             [("elite", 1, 0, 1, 0), ("elite", 1, 1, 1, 2.0), ("flyer", 18, 1, 0.7, 4.0), ("shieldbearer", 12, 1, 0.85, 8.0)],
         ]),
    dict(n=14, id="black_ridge", name="Black Ridge", diff="Very Hard", credits=820, hp=70, reward=300,
         a=[(0, 1), (5, 1), (5, 5), (10, 5), (10, 1), (15, 1), (15, 5), (20, 5), (20, 9), (21, 9)],
         b=[(0, 9), (8, 9), (8, 3), (13, 3), (13, 9), (18, 9), (18, 3), (21, 3)],
         theme="black", ground=(0.22, 0.13, 0.13), dust=(0.62, 0.33, 0.28), seed=154,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital"],
         abilities=["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"],
         desc="Elite broods dominate a ridge with very little buildable ground. Hold the crossings.",
         waves=[
             [("shieldbearer", 9, 0, 0.95, 0), ("flyer", 14, 1, 0.8, 0.5)],
             [("healer", 4, 0, 1.4, 0), ("warrior", 22, 1, 0.42, 0.5)],
             [("burrower", 12, 0, 0.8, 0), ("shieldbearer", 10, 1, 0.9, 0.5)],
             [("flyer", 16, 0, 0.75, 0), ("healer", 5, 1, 1.3, 0.5)],
             [("warrior", 24, 0, 0.4, 0), ("burrower", 14, 1, 0.75, 0.5)],
             [("shieldbearer", 12, 0, 0.85, 0), ("flyer", 18, 1, 0.7, 0.5)],
             [("healer", 6, 0, 1.25, 0), ("warrior", 24, 1, 0.4, 0.5), ("burrower", 12, 1, 0.8, 3.0)],
             [("shieldbearer", 14, 0, 0.8, 0), ("flyer", 18, 1, 0.7, 0.5)],
             [("elite", 1, 0, 1, 0), ("shieldbearer", 12, 1, 0.85, 1.0), ("healer", 5, 1, 1.3, 5.0)],
             [("warrior", 26, 0, 0.38, 0), ("burrower", 16, 1, 0.7, 0.5), ("flyer", 18, 1, 0.7, 4.0)],
             [("shieldbearer", 16, 0, 0.75, 0), ("healer", 6, 1, 1.2, 0.5), ("flyer", 20, 1, 0.68, 3.0)],
             [("elite", 1, 0, 1, 0), ("elite", 1, 1, 1, 2.0), ("shieldbearer", 14, 1, 0.8, 4.0), ("flyer", 20, 1, 0.68, 8.0), ("warrior", 20, 0, 0.42, 10.0)],
         ]),
    dict(n=15, id="first_bastion", name="First Bastion", diff="Very Hard", credits=900, hp=65, reward=500,
         a=[(0, 5), (3, 5), (3, 1), (8, 1), (8, 9), (13, 9), (13, 3), (18, 3), (18, 7), (21, 7)],
         b=[(0, 3), (6, 3), (6, 7), (11, 7), (11, 1), (16, 1), (16, 5), (21, 5)],
         theme="bastion", ground=(0.36, 0.15, 0.11), dust=(0.9, 0.42, 0.24), seed=165,
         towers=["pulse", "siege", "flame", "tesla", "missile", "cryo", "rail", "relay", "mine", "orbital"],
         abilities=["orbital_strike", "emp", "reinforcement_drones", "emergency_repair", "supply_drop"],
         desc="The final assault of the Brood Tyrant. Full roster, full abilities, no mercy.",
         waves=[
             [("shieldbearer", 10, 0, 0.9, 0), ("burrower", 10, 1, 0.85, 0.5)],
             [("flyer", 16, 0, 0.75, 0), ("healer", 4, 1, 1.4, 0.5)],
             [("warrior", 26, 0, 0.38, 0), ("shieldbearer", 12, 1, 0.85, 0.5)],
             [("burrower", 16, 0, 0.75, 0), ("flyer", 18, 1, 0.7, 0.5)],
             [("healer", 6, 0, 1.2, 0), ("shieldbearer", 14, 1, 0.8, 0.5)],
             [("flyer", 20, 0, 0.68, 0), ("burrower", 16, 1, 0.75, 0.5)],
             [("warrior", 28, 0, 0.36, 0), ("healer", 6, 1, 1.2, 0.5), ("flyer", 18, 1, 0.7, 3.0)],
             [("shieldbearer", 16, 0, 0.75, 0), ("burrower", 18, 1, 0.7, 0.5)],
             [("flyer", 22, 0, 0.66, 0), ("healer", 7, 1, 1.15, 0.5), ("shieldbearer", 14, 1, 0.8, 3.0)],
             [("warrior", 30, 0, 0.34, 0), ("burrower", 18, 1, 0.7, 0.5), ("flyer", 20, 1, 0.68, 4.0)],
             [("elite", 1, 0, 1, 0), ("shieldbearer", 16, 1, 0.75, 1.0), ("healer", 6, 1, 1.2, 5.0)],
             [("elite", 2, 0, 2.0, 0), ("burrower", 20, 1, 0.65, 0.5), ("flyer", 24, 1, 0.62, 4.0)],
             [("warrior", 30, 0, 0.34, 0), ("shieldbearer", 18, 1, 0.7, 0.5), ("healer", 7, 1, 1.1, 4.0)],
             [("boss", 1, 0, 1, 0), ("elite", 1, 1, 1, 3.0), ("shieldbearer", 16, 1, 0.75, 5.0), ("flyer", 24, 1, 0.62, 10.0), ("healer", 6, 1, 1.1, 14.0)],
         ]),
]

BLOCKED_PATTERN = [
    (2, 0), (19, 0), (20, 10), (1, 10), (19, 10), (0, 0), (21, 0), (21, 10),
]


def expand_path(points):
    cells = []
    for i in range(len(points) - 1):
        x0, y0 = points[i]
        x1, y1 = points[i + 1]
        dx, dy = abs(x1 - x0), abs(y1 - y0)
        sx = 1 if x1 > x0 else -1
        sy = 1 if y1 > y0 else -1
        err = dx - dy
        x, y = x0, y0
        while True:
            if not cells or cells[-1] != (x, y):
                cells.append((x, y))
            if x == x1 and y == y1:
                break
            e2 = 2 * err
            if e2 > -dy:
                err -= dy
                x += sx
            if e2 < dx:
                err += dx
                y += sy
    return cells


def enemy_lookup():
    return {e["id"]: e for e in ENEMIES}


def wave_preview(entries, lookup):
    names = {}
    for eid, count, _path, _int, _delay in entries:
        names[eid] = names.get(eid, 0) + count
    bits = []
    for eid, count in names.items():
        bits.append(f"{lookup[eid]['name']} x{count}")
    return " • ".join(bits)


def build_waves(level, lookup):
    wave_resources = []
    for wi, entries in enumerate(level["waves"], 1):
        subs = []
        for si, (eid, count, path, interval, delay) in enumerate(entries, 1):
            subs.append((f'Spawn_{si}', eid, count, path, interval, delay))
        bonus = 45 + wi * 6 + (35 if wi == len(level["waves"]) else 0)
        if level["n"] >= 11:
            bonus += 15
        preview = wave_preview(entries, lookup)
        # Separate wave files, as required by the data-driven design.
        parts = [f'[gd_resource type="Resource" script_class="WaveData" load_steps={2 + len(subs)} format=3]', ""]
        parts.append('[ext_resource type="Script" path="res://scripts/core/WaveData.gd" id="1_wave"]')
        parts.append('[ext_resource type="Script" path="res://scripts/core/SpawnEntry.gd" id="2_spawn"]')
        parts.append("")
        for sid, eid, count, path, interval, delay in subs:
            parts.append(f'[sub_resource type="Resource" id="{sid}"]')
            parts.append('script = ExtResource("2_spawn")')
            parts.append(f"enemy_id = {q(eid)}")
            parts.append(f"count = {count}")
            parts.append(f"path = {path}")
            parts.append(f"interval = {interval}")
            parts.append(f"delay = {delay}")
            parts.append("")
        parts.append("[resource]")
        parts.append('script = ExtResource("1_wave")')
        parts.append(f"wave_index = {wi}")
        parts.append(f"display_name = {q('Final Assault' if wi == len(level['waves']) else f'Wave {wi}')}")
        parts.append("entries = [" + ", ".join(f'SubResource("{sid}")' for sid, *_ in subs) + "]")
        parts.append(f"completion_bonus = {bonus}")
        parts.append(f"boss_wave = {'true' if wi == len(level['waves']) else 'false'}")
        parts.append(f"preview = {q(preview)}")
        fname = f"level_{level['n']:02d}_wave_{wi:02d}.tres"
        write(RES / "waves" / fname, "\n".join(parts) + "\n")
        wave_resources.append(f"res://resources/waves/{fname}")
    return wave_resources


def write_level(level, wave_paths):
    n = level["n"]
    # Deterministic blocked/decor cells: fixed edge props plus seeded scatter far from roads.
    road = set(expand_path(level["a"])) | set(expand_path(level["b"]))
    rng = random.Random(level["seed"])
    blocked = set(BLOCKED_PATTERN)
    attempts = 0
    target_extra = 10 + n
    while len(blocked) < len(BLOCKED_PATTERN) + target_extra and attempts < 500:
        attempts += 1
        x = rng.randint(1, 20)
        y = rng.randint(1, 9)
        if (x, y) in road:
            continue
        # Do not block cells immediately next to both spawn and base approaches.
        if x <= 1 or x >= 20:
            continue
        # Keep the central buildable area reasonably open.
        if 8 <= x <= 13 and 4 <= y <= 6 and rng.random() < 0.8:
            continue
        blocked.add((x, y))
    blocked = sorted(blocked)
    parts = [f'[gd_resource type="Resource" script_class="LevelData" load_steps={3 + len(wave_paths)} format=3]', ""]
    parts.append('[ext_resource type="Script" path="res://scripts/core/LevelData.gd" id="1_level"]')
    for i, wp in enumerate(wave_paths, 1):
        parts.append(f'[ext_resource type="Resource" path="{wp}" id="w{i}"]')
    parts.append("")
    parts.append("[resource]")
    parts.append('script = ExtResource("1_level")')
    fields = {
        "id": q(level["id"]), "display_name": q(level["name"]), "level_number": n,
        "difficulty": q(level["diff"]), "description": q(level["desc"]),
        "starting_credits": level["credits"], "base_health": level["hp"],
        "completion_reward": level["reward"], "interest_rate": 0.0,
        "grid_width": 22, "grid_height": 11, "build_margin": 2,
        "path_a": "[" + ", ".join(f"Vector2({x}, {y})" for x, y in level["a"]) + "]",
        "path_b": "[" + ", ".join(f"Vector2({x}, {y})" for x, y in level["b"]) + "]",
        "blocked_cells": "[" + ", ".join(f"Vector2i({x}, {y})" for x, y in blocked) + "]",
        "available_towers": "[" + ", ".join(q(t) for t in level["towers"]) + "]",
        "unlocked_abilities": "[" + ", ".join(q(a) for a in level["abilities"]) + "]",
        "wave_data_list": "[" + ", ".join(f'ExtResource("w{i}")' for i in range(1, len(wave_paths) + 1)) + "]",
        "environment_theme": q(level["theme"]),
        "ground_color": color(level["ground"]), "dust_color": color(level["dust"]),
        "prop_seed": level["seed"], "briefing": q(level["desc"]),
    }
    for k, v in fields.items():
        parts.append(f"{k} = {v}")
    write(RES / "levels" / f"level_{n:02d}.tres", "\n".join(parts) + "\n")


def verify_layers(levels):
    for level in levels:
        a_list = expand_path(level["a"])
        b_list = expand_path(level["b"])
        a = set(a_list)
        b = set(b_list)
        inter = a & b
        assert inter, f"{level['name']} has no shared cell"
        crossed = False
        for cell in inter:
            a_h = (cell[0] - 1, cell[1]) in a and (cell[0] + 1, cell[1]) in a
            a_v = (cell[0], cell[1] - 1) in a and (cell[0], cell[1] + 1) in a
            b_h = (cell[0] - 1, cell[1]) in b and (cell[0] + 1, cell[1]) in b
            b_v = (cell[0], cell[1] - 1) in b and (cell[0], cell[1] + 1) in b
            if (a_h and b_v) or (a_v and b_h):
                crossed = True
                break
        assert crossed, f"{level['name']} has no perpendicular crossing"
        assert any(x >= 20 for x, _ in a_list) and any(x >= 20 for x, _ in b_list), f"{level['name']} does not reach base"
        assert min(x for x, _ in a_list) <= 0 and min(x for x, _ in b_list) <= 0, f"{level['name']} spawn missing"
    print("Road layouts: all 15 levels have spawn, base and a perpendicular crossing")


def main():
    lookup = enemy_lookup()
    for t in TOWERS:
        write_tower(t)
    for e in ENEMIES:
        write_enemy(e)
    for a in ABILITIES:
        write_ability(a)
    verify_layers(LEVELS)
    for level in LEVELS:
        waves = build_waves(level, lookup)
        write_level(level, waves)
    print(f"Generated {len(TOWERS)} towers, {len(ENEMIES)} enemies, {len(ABILITIES)} abilities, "
          f"{len(LEVELS)} levels and {sum(len(l['waves']) for l in LEVELS)} waves.")


if __name__ == "__main__":
    main()

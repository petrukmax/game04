extends Node
## Runtime localisation. English strings are the source keys; the Russian
## dictionary below is used whenever the save setting ``language`` is "ru".
## Default language is Russian (see SaveManager defaults).
##
## Usage:
##   Loc.t("SETTINGS")
##   Loc.t("Not enough credits for %s.") % data.display_name
## Data resources keep their English fields; wrap them at display time:
##   Loc.t(data.display_name)

const LANGUAGES: Array[String] = ["ru", "en"]
const LANGUAGE_NAMES := {"ru": "Русский", "en": "English"}
const DEFAULT_LANGUAGE := "ru"

const ENEMY_NAMES := {
	"scout": "Dust Scout",
	"worker": "Regolith Worker",
	"warrior": "Chitin Warrior",
	"spitter": "Acid Spitter",
	"healer": "Brood Weaver",
	"burrower": "Burrower",
	"shieldbearer": "Shieldbearer",
	"flyer": "Rift Flyer",
	"elite": "Arachnid Elite",
	"boss": "Brood Tyrant",
}

var language: String = DEFAULT_LANGUAGE


func _ready() -> void:
	var saved := DEFAULT_LANGUAGE
	if has_node("/root/GameState"):
		saved = String(get_node("/root/GameState").get("settings").get("language", DEFAULT_LANGUAGE))
	language = normalize(saved)


func normalize(code: String) -> String:
	return code if LANGUAGES.has(code) else DEFAULT_LANGUAGE


func set_language(code: String) -> void:
	language = normalize(code)


func is_russian() -> bool:
	return language == "ru"


func t(text: String) -> String:
	if language == "ru":
		return String(RU.get(text, text))
	return text


func tf(pattern: String, args: Array) -> String:
	return t(pattern) % args


func enemy_name(enemy_id: String) -> String:
	return t(String(ENEMY_NAMES.get(enemy_id, enemy_id)))


const RU := {
	# --- Main menu -------------------------------------------------------
	"FIRST BASTION COMMAND": "КОМАНДОВАНИЕ ПЕРВОГО БАСТИОНА",
	"MARS\nARACHNID\nDEFENSE": "МАРС\nАРАХНИД\nОБОРОНА",
	"Hold the first human outpost against the Martian brood.": "Удержите первый человеческий аванпост против марсианского выводка.",
	"START CAMPAIGN": "НАЧАТЬ КАМПАНИЮ",
	"CONTINUE — SECTOR %02d": "ПРОДОЛЖИТЬ — СЕКТОР %02d",
	"NEW CAMPAIGN": "НОВАЯ КАМПАНИЯ",
	"SECTOR SELECT": "ВЫБОР СЕКТОРА",
	"SETTINGS": "НАСТРОЙКИ",
	"FIELD MANUAL": "ПОЛЕВОЙ УСТАВ",
	"RELOAD GAME": "ПЕРЕЗАГРУЗИТЬ ИГРУ",
	"QUIT TO DESKTOP": "ВЫЙТИ НА РАБОЧИЙ СТОЛ",
	"CAMPAIGN RECORD": "ЛЕТОПИСЬ КАМПАНИИ",
	"Sectors unlocked": "Секторов открыто",
	"Sectors completed": "Секторов пройдено",
	"Stars earned": "Звёзд получено",
	"Arachnids killed": "Арахнидов уничтожено",
	"Credits earned": "Кредитов заработано",
	"GODOT 4 · LOCAL SAVE · PROCEDURAL ART AND AUDIO · NO ONLINE SERVICES": "GODOT 4 · ЛОКАЛЬНОЕ СОХРАНЕНИЕ · ПРОЦЕДУРНАЯ ГРАФИКА И ЗВУК · БЕЗ СЕТИ",
	"New campaign": "Новая кампания",
	"Start a new campaign and reset all unlocks, stars and totals?": "Начать новую кампанию и сбросить все открытия, звёзды и итоги?",
	"START NEW": "НАЧАТЬ",
	"CANCEL": "ОТМЕНА",
	"Highest unlocked sector: %02d — %s": "Высший открытый сектор: %02d — %s",
	"No campaign started. The brood is waiting.": "Кампания не начата. Выводок ждёт.",

	# --- Sector select ---------------------------------------------------
	"‹ MAIN MENU": "‹ ГЛАВНОЕ МЕНЮ",
	"Choose a battlefield. Sectors unlock in order as the campaign advances.": "Выберите поле боя. Секторы открываются по порядку по мере прохождения кампании.",
	"STARS %d / 45": "ЗВЁЗДЫ %d / 45",
	"MANUAL": "УСТАВ",
	"SELECT A SECTOR": "ВЫБЕРИТЕ СЕКТОР",
	"Hover a sector for its briefing. Completed sectors show their best star rating.": "Наведите на сектор, чтобы увидеть сводку. Пройденные секторы показывают лучшее число звёзд.",
	"Progress and best stars are saved locally after every battle.": "Прогресс и лучшие звёзды сохраняются локально после каждого боя.",
	"LOCKED": "ЗАКРЫТ",
	"CLEARED": "ПРОЙДЕН",
	"AVAILABLE": "ДОСТУПЕН",
	"%s  ·  SECTOR %02d  ·  %s  ·  %s": "%s  ·  СЕКТОР %02d  ·  %s  ·  %s",
	"BEST %d / 3 STARS": "ЛУЧШИЙ РЕЗУЛЬТАТ: %d / 3 ★",
	"NOT YET CLEARED": "ЕЩЁ НЕ ПРОЙДЕН",
	"%s\nStart: $%d · Base integrity %d · %d waves · Towers available: %d": "%s\nСтарт: $%d · Прочность базы: %d · Волн: %d · Доступно башен: %d",

	# --- Difficulties ----------------------------------------------------
	"Easy": "Лёгкий",
	"Medium": "Средний",
	"Very Hard": "Очень сложный",

	# --- Settings --------------------------------------------------------
	"Audio is generated locally. Volumes apply immediately and are saved on change.": "Звук генерируется локально. Громкость применяется сразу и сохраняется при изменении.",
	"Master volume": "Общая громкость",
	"Effects volume": "Громкость эффектов",
	"Ambience volume": "Громкость атмосферы",
	"Mute all audio": "Отключить весь звук",
	"Screen shake": "Тряска экрана",
	"High-contrast status markers": "Высококонтрастные маркеры статусов",
	"RESET CAMPAIGN PROGRESS": "СБРОСИТЬ ПРОГРЕСС КАМПАНИИ",
	"CLOSE": "ЗАКРЫТЬ",
	"Reset campaign": "Сброс кампании",
	"Reset all unlocks, stars and campaign totals?\nThis cannot be undone.": "Сбросить все открытия, звёзды и итоги кампании?\nЭто нельзя отменить.",
	"RESET": "СБРОСИТЬ",
	"Language": "Язык",
	"Language changed.": "Язык изменён.",
	"Campaign progress reset.": "Прогресс кампании сброшен.",
	"Language will apply after restarting the sector.": "Язык применится после перезапуска сектора.",

	# --- Pause menu ------------------------------------------------------
	"SIMULATION PAUSED": "СИМУЛЯЦИЯ ПРИОСТАНОВЛЕНА",
	"The battle waits for you. Esc or Resume continues.": "Бой ждёт вас. Esc или «Продолжить» возвращает в игру.",
	"RESUME": "ПРОДОЛЖИТЬ",
	"RESTART SECTOR": "ПЕРЕЗАПУСТИТЬ СЕКТОР",
	"HELP / CONTROLS": "СПРАВКА / УПРАВЛЕНИЕ",
	"MAIN MENU": "ГЛАВНОЕ МЕНЮ",

	# --- HUD -------------------------------------------------------------
	"MARS ARACHNID DEFENSE": "ОБОРОНА МАРСА ОТ АРАХНИДОВ",
	"SECTOR %02d · %s": "СЕКТОР %02d · %s",
	"CREDITS": "КРЕДИТЫ",
	"BASE INTEGRITY": "ПРОЧНОСТЬ БАЗЫ",
	"WAVE": "ВОЛНА",
	"NEXT WAVE — SPACE TO CALL EARLY": "СЛЕДУЮЩАЯ ВОЛНА — ПРОБЕЛ ДЛЯ ДОСРОЧНОГО ВЫЗОВА",
	"Preparing first contact": "Подготовка к первому контакту",
	"SEND WAVE": "ВЫЗВАТЬ ВОЛНУ",
	"Call the next wave early for a credit bonus (Space).": "Вызвать следующую волну досрочно за бонус кредитов (Пробел).",
	"Set simulation speed to %dx (F%d).": "Установить скорость симуляции %dx (F%d).",
	"Pause simulation (Esc).": "Пауза симуляции (Esc).",
	"WAVE CLEARED": "ВОЛНА ОТБИТА",
	"+%d CREDITS": "+%d КРЕДИТОВ",
	"BROOD TYRANT": "ТИРАН ВЫВОДКА",
	"WAVE %d / %d": "ВОЛНА %d / %d",
	"Wave %d incoming — %s": "Волна %d приближается — %s",
	"Wave %d / %d": "Волна %d / %d",
	"Early call: +%d credits": "Досрочный вызов: +%d кредитов",
	"Wave cleared. +%d credits": "Волна отбита. +%d кредитов",
	"Final wave in progress": "Идёт финальная волна",
	"Tower disabled by corrosive acid!": "Башня отключена едкой кислотой!",

	# --- Tower card / shop ----------------------------------------------
	"NOT IN SECTOR": "НЕТ В СЕКТОРЕ",
	"INSUFFICIENT": "НЕ ХВАТАЕТ",
	"%s is not available in this sector.": "%s недоступна в этом секторе.",
	"Not enough credits for %s ($%d).": "Недостаточно кредитов для %s ($%d).",
	"Not enough credits for %s.": "Недостаточно кредитов для %s.",
	"This tower is not available in this sector.": "Эта башня недоступна в этом секторе.",
	"Cannot build here: %s": "Здесь нельзя строить: %s",
	"Tower scene is missing: %s": "Отсутствует сцена башни: %s",
	"Upgrade unavailable or not enough credits.": "Улучшение недоступно или не хватает кредитов.",
	"%s  [%s]\nCost $%d · %s\n%s": "%s  [%s]\nЦена $%d · %s\n%s",
	"Locked in this sector.": "Недоступна в этом секторе.",
	"%s upgraded to Mk %d": "%s улучшена до Мк %d",

	# --- Tower inspector -------------------------------------------------
	"Tower": "Башня",
	"Mk 1 / 4": "Мк 1 / 4",
	"Role": "Роль",
	"UPGRADE": "УЛУЧШИТЬ",
	"SELL": "ПРОДАТЬ",
	"TARGET": "ЦЕЛЬ",
	"First": "Первая",
	"Last": "Последняя",
	"Strongest": "Сильнейшая",
	"Weakest": "Слабейшая",
	"Closest": "Ближайшая",
	"Highest HP": "Наибольшее HP",
	"Flying first": "Сначала летающие",
	"Range ring is shown while this tower is selected.": "Радиус показан, пока башня выбрана.",
	"Mk %d / %d · %s": "Мк %d / %d · %s",
	"Damage type: %s": "Тип урона: %s",
	"Damage        %s": "Урон: %s",
	"Fire rate     %.2f /s   (%.0f DPS)": "Скорость: %.2f/с (%.0f УВС)",
	"Range         %d": "Радиус: %d",
	"Splash        %d": "Площадь: %d",
	"Slow          %d%% for %.1fs": "Замедление: %d%% на %.1f с",
	"Armour pen.   %d%%": "Бронепробитие: %d%%",
	"Chain targets %d": "Целей в цепи: %d",
	"Burn          %.0f /s for %.1fs": "Горение: %.0f/с %.1f с",
	"Missiles      %d per salvo": "Ракет за залп: %d",
	"Command aura  %d radius": "Аура команды: радиус %d",
	"Tower buff    +%d%%": "Усиление башен: +%d%%",
	"Stipend       +%d / wave": "Дотация: +%d / волна",
	"Mine reload   %.1fs · %d blast": "Минный цикл: %.1f с · взрыв %d",
	"Targets air   %s": "Бьёт по воздуху: %s",
	"YES": "ДА",
	"NO": "НЕТ",
	"Maximum upgrade level reached. This tower is fully upgraded.": "Достигнут максимальный уровень. Башня полностью улучшена.",
	"MAX LEVEL": "МАКС. УРОВЕНЬ",
	"NEXT — %s ($%d)\n%s": "ДАЛЕЕ — %s ($%d)\n%s",
	"UPGRADE  $%d": "УЛУЧШИТЬ  $%d",
	"Not enough credits.": "Недостаточно кредитов.",
	"SELL  +$%d": "ПРОДАТЬ  +$%d",
	"Sell for $%d — refund %d%% of invested credits.": "Продать за $%d — возврат %d%% вложенных кредитов.",
	"Refund %d%% of invested credits.": "Возврат %d%% вложенных кредитов.",
	"Range %d · invested $%d · select target priority for this tower.": "Радиус %d · вложено $%d · выберите приоритет цели для этой башни.",

	# --- Victory / defeat -------------------------------------------------
	"SECTOR SECURED": "СЕКТОР ЗАЩИЩЁН",
	"CAMPAIGN COMPLETE": "КАМПАНИЯ ЗАВЕРШЕНА",
	"VICTORY": "ПОБЕДА",
	"%s  ·  SECTOR %02d": "%s  ·  СЕКТОР %02d",
	"Base integrity": "Прочность базы",
	"Leaks": "Прорывы",
	"Waves cleared": "Волн отбито",
	"Towers built": "Башен построено",
	"Battle time": "Время боя",
	"Next sector": "Следующий сектор",
	"UNLOCKED": "ОТКРЫТ",
	"The First Bastion stands. The brood is broken — for now.": "Первый Бастион выстоял. Выводок сломлен — пока что.",
	"Sector %02d is now available.": "Сектор %02d теперь доступен.",
	"NEXT SECTOR": "СЛЕДУЮЩИЙ СЕКТОР",
	"REPLAY": "ПОВТОРИТЬ",
	"BASE INTEGRITY LOST": "ПРОЧНОСТЬ БАЗЫ ПОТЕРЯНА",
	"OUTPOST OVERRUN": "АВАНПОСТ ПРОРВАН",
	"The brood reached the First Bastion. Rebuild the defence and try again.": "Выводок прорвался к Первому Бастиону. Перестройте оборону и попробуйте снова.",
	"The base falls the moment a single arachnid gets through. Rebuild and hold every road.": "База падает, как только прорывается хотя бы один арахнид. Перестройте оборону и удержите все дороги.",
	"RETRY SECTOR": "ПОВТОРИТЬ СЕКТОР",
	"RETRY FROM WAVE %d": "ПОВТОРИТЬ С ВОЛНЫ %d",
	"Checkpoint: wave %d cleared — all towers and credits will be restored.": "Контрольная точка: волна %d пройдена — все башни и кредиты будут восстановлены.",
	"Checkpoint restored — wave %d cleared.": "Контрольная точка восстановлена — волна %d пройдена.",

	# --- Gameplay notifications -----------------------------------------
	"Sector %d — %s": "Сектор %d — %s",
	"Command Relay stipend: +%d credits": "Дотация командного ретранслятора: +%d кредитов",
	"Base integrity -%d": "Прочность базы -%d",
	"Base repaired +%d integrity": "База отремонтирована: +%d прочности",
	"BROOD TYRANT DETECTED": "ОБНАРУЖЕН ТИРАН ВЫВОДКА",
	"The Brood Tyrant enters the field!": "Тиран выводка выходит на поле!",
	"Elite frenzy — it is charging!": "Ярость элиты — она идёт на таран!",
	"Brood Tyrant: Hatchlings! It calls the brood.": "Тиран выводка: потомство! Он зовёт выводок.",
	"Brood Tyrant: Carapace Surge! Shields online.": "Тиран выводка: всплеск панциря! Щиты активны.",
	"Brood Tyrant: FINAL FURY — it is enraged!": "Тиран выводка: ФИНАЛЬНАЯ ЯРОСТЬ — он в бешенстве!",
	"Arachnid Elite approaching!": "Приближается элитный арахнид!",
	"Ability not unlocked in this sector.": "Способность не открыта в этом секторе.",
	"Ability is cooling down or out of charges.": "Способность перезаряжается или заряды кончились.",
	"Select a target area for %s.": "Выберите зону для %s.",
	"Supply drop recovered: +%d credits": "Груз найден: +%d кредитов",
	"Game speed: %dx": "Скорость игры: %dx",
	"Audio muted": "Звук отключён",
	"Audio unmuted": "Звук включён",
	"BREACH! One arachnid reached the base.": "ПРОРЫВ! Один арахнид добрался до базы.",
	"The Brood Tyrant summons its brood!": "Тиран выводка призывает своё потомство!",
	"The Brood Tyrant hardens its carapace!": "Тиран выводка укрепляет панцирь!",
	"The Brood Tyrant is enraged. Finish it!": "Тиран выводка в ярости. Добейте его!",
	"The Brood Tyrant has fallen!": "Тиран выводка пал!",
	"Unknown Sector": "Неизвестный сектор",
	"Sector %d": "Сектор %d",

	# --- Save errors ------------------------------------------------------
	"Save file could not be opened. Defaults loaded.": "Не удалось открыть сохранение. Загружены значения по умолчанию.",
	"Save file was unreadable. Defaults loaded.": "Сохранение повреждено. Загружены значения по умолчанию.",
	"Save file could not be written.": "Не удалось записать сохранение.",
	"Save version was unsupported; safe defaults were used.": "Версия сохранения не поддерживается; применены безопасные значения.",

	# --- Build placement reasons -----------------------------------------
	"Outside grid": "Вне сетки",
	"Road": "Дорога",
	"Blocked": "Заблокировано",
	"Occupied": "Занято",
	"Too far from road": "Слишком далеко от дороги",
	"Unavailable": "Недоступно",
	"Not enough credits": "Недостаточно кредитов",

	# --- Entry gates ------------------------------------------------------
	"ENTRY ALPHA": "ВХОД АЛЬФА",
	"ENTRY BETA": "ВХОД БЕТА",
	"FIRST BASTION": "ПЕРВЫЙ БАСТИОН",

	# --- Tower names ------------------------------------------------------
	"Pulse Turret": "Импульсная турель",
	"Siege Cannon": "Осадная пушка",
	"Flame Vent": "Пламенный выхлоп",
	"Arc Coil": "Дуговая катушка",
	"Missile Battery": "Ракетная батарея",
	"Cryo Emitter": "Криоизлучатель",
	"Rail Sniper": "Рельсовый снайпер",
	"Command Relay": "Командный ретранслятор",
	"Mine Layer": "Минный заградитель",
	"Orbital Lance": "Орбитальное копьё",

	# --- Tower roles ------------------------------------------------------
	"Reliable single-target": "Надёжное одиночное поражение",
	"Heavy splash": "Тяжёлый урон по площади",
	"Close area denial": "Ближний контроль зоны",
	"Chain lightning": "Цепная молния",
	"Anti-swarm / anti-air": "Против толпы и воздуха",
	"Crowd control": "Контроль толпы",
	"Long-range precision": "Дальняя точность",
	"Support / economy": "Поддержка и экономика",
	"Trap defence": "Минная оборона",
	"Late-game ultimate": "Ультимативная башня поздней игры",

	# --- Damage types -----------------------------------------------------
	"kinetic": "кинетический",
	"explosive": "взрывной",
	"fire": "огненный",
	"frost": "морозный",
	"electric": "электрический",
	"energy": "энергетический",
	"support": "поддержка",
	"corrosive": "кислотный",

	# --- Tower descriptions ----------------------------------------------
	"Compact twin-barrel kinetic turret. Cheap, fast and dependable on both roads.": "Компактная двухствольная кинетическая турель. Дешёвая, быстрая и надёжная на обеих дорогах.",
	"Slow explosive shells that punish clustered and armoured arachnids.": "Медленные разрывные снаряды наказывают скученных и бронированных арахнидов.",
	"Short-range ignition vent. Sets every ground enemy in the ring alight.": "Короткодистанционный поджиг. Поджигает всех наземных врагов в радиусе.",
	"Arcs of static leap between nearby enemies. One of the few early anti-air towers.": "Разряды статики перескакивают между врагами. Одна из немногих ранних башен против воздуха.",
	"Homing missile cells. The dedicated answer to flyers and tight groups.": "Ячейки самонаводящихся ракет. Лучший ответ летающим и плотным группам.",
	"Cryogenic shells chill an area, slowing ground and flying enemies.": "Криогенные снаряды охлаждают зону, замедляя наземных и летающих врагов.",
	"Hypervelocity rail shot. Deletes high-value targets before they reach the base.": "Гиперскоростной рельсовый выстрел. Уничтожает важные цели до подхода к базе.",
	"Buffs nearby towers and pays a credit stipend at the end of each wave.": "Усиливает ближайшие башни и платит кредитную дотацию в конце каждой волны.",
	"Scatters proximity mines on nearby road cells. Excellent at chokepoints.": "Разбрасывает мины на ближних дорожных клетках. Отлично работает в узких местах.",
	"Charges a delayed orbital beam onto the densest enemy cluster.": "Заряжает отложенный орбитальный луч по самой плотной группе врагов.",

	# --- Upgrade names ----------------------------------------------------
	"Servo Tuning": "Настройка сервоприводов",
	"Armour Piercer": "Бронебойные снаряды",
	"Skyfire Barrels": "Стволы «Небесный огонь»",
	"Fragment Shells": "Осколочные снаряды",
	"HEAT Loader": "Заряжающий ПТУР",
	"Siege Breaker": "Осадный разрушитель",
	"Wide Nozzle": "Широкое сопло",
	"Fuel Agitator": "Топливный агитатор",
	"White-Hot Vent": "Раскалённое сопло",
	"Capacitor Bank": "Батарея конденсаторов",
	"Overcharge": "Перегрузка",
	"Storm Crown": "Корона бури",
	"Twin Rack": "Сдвоенная установка",
	"Guidance Suite": "Система наведения",
	"Saturation Rack": "Установка насыщения",
	"Cryo Mix": "Криосмесь",
	"Deep Freeze": "Глубокая заморозка",
	"Absolute Zero": "Абсолютный ноль",
	"Tungsten Slug": "Вольфрамовый снаряд",
	"Extended Rails": "Удлинённые рельсы",
	"Executioner Rounds": "Снаряды палача",
	"Signal Array": "Сигнальная антенна",
	"Targeting Uplink": "Канал наведения",
	"Orbital Command": "Орбитальное командование",
	"Larger Payload": "Увеличенный заряд",
	"Rapid Dispenser": "Быстрый дозатор",
	"Cluster Mines": "Кластерные мины",
	"Focused Lens": "Сфокусированная линза",
	"Reactor Tap": "Отвод реактора",
	"Godspear Protocol": "Протокол «Копьё богов»",

	# --- Upgrade descriptions --------------------------------------------
	"Faster tracking and a harder hitting bolt.": "Быстрее наведение и мощнее снаряд.",
	"Dense penetrator rounds ignore more plating.": "Плотные бронебойные снаряды лучше пробивают броню.",
	"Specialised flak shells let the turret hit flyers.": "Специальные зенитные снаряды позволяют турели бить летающих.",
	"Wider blast radius and more shrapnel.": "Шире радиус взрыва и больше осколков.",
	"High-explosive anti-tank charge burns through plating.": "Кумулятивный заряд прожигает броню.",
	"Massive shells crack even elite carapaces.": "Массивные снаряды раскалывают даже панцири элиты.",
	"Longer reach and a hotter burn.": "Дальше достаёт и сильнее жжёт.",
	"Sticky fuel keeps burning after the vent stops.": "Липкое топливо горит и после отключения.",
	"Ceramic-lined vent turns the road into a furnace.": "Керамическое сопло превращает дорогу в печь.",
	"Extra charge feeds one more chain.": "Дополнительный заряд даёт ещё одну цепь.",
	"Faster discharge and a stronger stun field.": "Быстрее разряд и сильнее поле оглушения.",
	"A crown of coils chains through entire swarms.": "Корона катушек прошивает целые рои.",
	"Adds a second missile to every salvo.": "Добавляет вторую ракету в каждый залп.",
	"Better tracking and a faster reload.": "Лучше отслеживание и быстрее перезарядка.",
	"Three missiles per salvo saturate the road.": "Три ракеты за залп накрывают дорогу.",
	"Colder burst and a larger freezing cloud.": "Холоднее взрыв и больше морозное облако.",
	"The chill clings to carapace much longer.": "Холод держится на панцире гораздо дольше.",
	"A wide field of near-solid air.": "Широкое поле почти твёрдого воздуха.",
	"Denser round with better armour defeat.": "Плотнее снаряд и лучше пробитие брони.",
	"Longer accelerator stretches the kill zone.": "Длиннее ускоритель — шире зона поражения.",
	"Finishes wounded elites in a single shot.": "Добивает раненых элитных одним выстрелом.",
	"Wider command aura and a larger stipend.": "Шире аура команды и больше дотация.",
	"Nearby towers fire harder and faster.": "Ближайшие башни бьют сильнее и быстрее.",
	"Battlefield-wide coordination and rich stipends.": "Координация всего поля боя и щедрые дотации.",
	"Mines hit harder and deploy quicker.": "Мины бьют сильнее и ставятся быстрее.",
	"A motorised hatch lays traps continuously.": "Моторизованный люк непрерывно ставит ловушки.",
	"Each mine seeds a lethal fragmentation ring.": "Каждая мина создаёт смертельное кольцо осколков.",
	"Tighter beam, far more damage.": "Уже луч, намного больше урона.",
	"Direct reactor feed accelerates the charge cycle.": "Прямое питание от реактора ускоряет зарядку.",
	"The full lance of the orbiting platform.": "Полная мощь орбитальной платформы.",

	# --- Enemy names ------------------------------------------------------
	"Dust Scout": "Пыльный разведчик",
	"Regolith Worker": "Реголитовый рабочий",
	"Chitin Warrior": "Хитиновый воин",
	"Acid Spitter": "Кислотный плеватель",
	"Brood Weaver": "Ткач выводка",
	"Burrower": "Землерой",
	"Shieldbearer": "Щитоносец",
	"Rift Flyer": "Разломный летун",
	"Arachnid Elite": "Элитный арахнид",
	"Brood Tyrant": "Тиран выводка",

	# --- Enemy roles ------------------------------------------------------
	"Fast swarm": "Быстрый рой",
	"Swarm": "Рой",
	"Standard melee": "Обычный ближний бой",
	"Ranged": "Дальний бой",
	"Support": "Поддержка",
	"Ambusher": "Засадник",
	"Armoured": "Бронированный",
	"Air": "Воздух",
	"Mini-boss": "Мини-босс",
	"Boss": "Босс",

	# --- Enemy tips/descriptions -----------------------------------------
	"A quick, fragile runner that probes both roads in packs.": "Быстрый и хрупкий бегун, прощупывающий обе дороги стаями.",
	"Slow, cheap and endless. Splash damage clears them efficiently.": "Медленные, дешёвые и бесконечные. Урон по площади эффективно их вычищает.",
	"Balanced frontline arachnid with hardened plates.": "Сбалансированный фронтовой арахнид с закалёнными пластинами.",
	"Stops near towers and spits corrosive acid, disabling them briefly.": "Останавливается у башен и плюёт едкой кислотой, ненадолго отключая их.",
	"Pulses regenerative silk into nearby arachnids. Kill it first.": "Пульсирует восстанавливающим шёлком в ближайших арахнидов. Убивайте первым.",
	"Dives under the regolith and surfaces near the defences.": "Ныряет под реголит и всплывает у самой обороны.",
	"Projects a regenerating energy shield. Electric damage breaks it quickly.": "Проецирует восстанавливающийся энергощит. Электрический урон быстро его ломает.",
	"Hovers above the road. Only anti-air towers can engage it.": "Парит над дорогой. Только противовоздушные башни могут его достать.",
	"A hulking command breed with heavy plating and a vicious charge.": "Огромный командный вид с тяжёлой бронёй и яростным рывком.",
	"The Brood Tyrant. Three phases, summons, a shield surge and a final enrage.": "Тиран выводка. Три фазы, призыв потомства, всплеск щита и финальная ярость.",

	# --- Level names ------------------------------------------------------
	"Landing Zone": "Зона высадки",
	"Supply Route": "Маршрут снабжения",
	"Canyon Junction": "Каньонная развилка",
	"Relay Station": "Станция ретрансляции",
	"Ore Field": "Рудное поле",
	"Broken Pipeline": "Разрушенный трубопровод",
	"Dust Basin": "Пыльный бассейн",
	"Excavation Site": "Раскопки",
	"Solar Array": "Солнечная батарея",
	"Command Ridge": "Командный хребет",
	"Red Divide": "Красный рубеж",
	"Stormline": "Штормовая линия",
	"Deep Crater": "Глубокий кратер",
	"Black Ridge": "Чёрный хребет",
	"First Bastion": "Первый Бастион",

	# --- Level descriptions / briefings ----------------------------------
	"The first outpost. Learn placement, upgrades and wave timing.": "Первый аванпост. Освойте размещение, улучшения и тайминг волн.",
	"Two supply roads cross under the cargo cranes. Make the first upgrade decision.": "Две дороги снабжения пересекаются под грузовыми кранами. Примите первое решение об улучшении.",
	"The roads cross above the canyon throat. Stack area damage on the junction.": "Дороги пересекаются над горловиной каньона. Соберите урон по площади на развилке.",
	"Antenna masts and solar relays split the lanes. Burn the early swarm.": "Антенные мачты и солнечные ретрансляторы разделяют полосы. Сожгите ранний рой.",
	"The first Arachnid Elite surfaces among the ore crushers. Sell and rebuild.": "Первый элитный арахнид всплывает среди рудных дробилок. Продавайте и перестраивайтесь.",
	"Armoured shieldbearers guard the ruptured pipeline. Bring corrosion and splash.": "Бронированные щитоносцы охраняют разорванный трубопровод. Возьмите кислоту и урон по площади.",
	"Dust storms hide the first rift flyers. Anti-air coverage is mandatory.": "Пыльные бури скрывают первых разломных летунов. ПВО обязательно.",
	"Burrowers tunnel beneath the dig site. Watch the road at the central intersection.": "Землерои прокладывают туннели под раскопками. Следите за дорогой на центральном перекрёстке.",
	"Brood weavers and shieldbearers advance under the solar mirrors. Prioritise the healers.": "Ткачи выводка и щитоносцы наступают под солнечными зеркалами. В первую очередь убивайте лекарей.",
	"Command Ridge is the last easy posting. Mixed waves hit both roads at once.": "Командный хребет — последний лёгкий пост. Смешанные волны бьют по обеим дорогам сразу.",
	"A tight economy and a divided road. Every credit and every ability matters.": "Скупная экономика и разделённая дорога. Каждый кредит и каждая способность важны.",
	"Static storms feed the arachnids. Fast waves, slows and chokepoint defence.": "Статические бури питают арахнидов. Быстрые волны, замедления и оборона узких мест.",
	"Heavy armour, burrowers, flyers and healers in one crushing descent.": "Тяжёлая броня, землерои, летуны и лекари в одном сокрушительном натиске.",
	"Elite broods dominate a ridge with very little buildable ground. Hold the crossings.": "Элитные выводки господствуют на хребте с малым числом мест для строительства. Удержите переправы.",
	"The final assault of the Brood Tyrant. Full roster, full abilities, no mercy.": "Финальный штурм Тирана выводка. Полный состав, все способности, без пощады.",

	# --- Abilities (kept for when the feature is re-enabled) -------------
	"Orbital Strike": "Орбитальный удар",
	"EMP Pulse": "ЭМИ-импульс",
	"Reinforcement Drones": "Дроны подкрепления",
	"Emergency Repair": "Экстренный ремонт",
	"Supply Drop": "Сброс припасов",
	"Mark a zone. After a short delay the orbital platform delivers a heavy explosive strike.": "Отметьте зону. После короткой задержки орбитальная платформа наносит тяжёлый взрывной удар.",
	"Stuns and slows every arachnid in the zone, and overloads energy shields.": "Оглушает и замедляет всех арахнидов в зоне, перегружая энергощиты.",
	"Deploys two autonomous gun drones over a road section for fourteen seconds.": "Разворачивает два автономных боевых дрона над участком дороги на четырнадцать секунд.",
	"Restores 25 base integrity. Limited to two charges per level.": "Восстанавливает 25 прочности базы. Не более двух зарядов на уровень.",
	"Calls down a credit cache. Limited to two charges per level.": "Вызывает тайник с кредитами. Не более двух зарядов на уровень.",

	# --- Field manual -----------------------------------------------------
	"MISSION": "ЗАДАЧА",
	"Two hostile roads run left to right and cross somewhere on the map. Arachnids follow those roads toward the First Bastion on the right. Build towers on the visible square grid beside the roads and stop every wave. A single arachnid that reaches the base destroys it — the sector must be restarted.": "Две вражеские дороги идут слева направо и где-то пересекаются. Арахниды движутся по ним к Первому Бастиону справа. Стройте башни на видимой квадратной сетке рядом с дорогами и отбивайте каждую волну. Один арахнид, дошедший до базы, уничтожает её — сектор придётся начать заново.",
	"CONTROLS": "УПРАВЛЕНИЕ",
	"[b]Left click[/b] build / select · [b]Right click[/b] cancel · [b]1–0[/b] choose tower · [b]Space[/b] send next wave early": "[b]ЛКМ[/b] строить / выбрать · [b]ПКМ[/b] отмена · [b]1–0[/b] выбор башни · [b]Пробел[/b] досрочный вызов волны",
	"[b]U[/b] upgrade selected tower · [b]X[/b] or [b]Delete[/b] sell · [b]Tab[/b] cycle towers · [b]F1/F2/F3[/b] or top-bar buttons set 1x/2x/3x speed · [b]Esc[/b] pause / cancel · [b]M[/b] mute": "[b]U[/b] улучшить выбранную башню · [b]X[/b] или [b]Delete[/b] продать · [b]Tab[/b] переключение башен · [b]F1/F2/F3[/b] или кнопки сверху задают скорость 1x/2x/3x · [b]Esc[/b] пауза / отмена · [b]M[/b] звук",
	"Abilities are temporarily disabled by user request. Their code and data remain in the project and can be re-enabled later.": "Способности временно отключены по требованию пользователя. Их код и данные остаются в проекте и могут быть включены позже.",
	"TOWERS": "БАШНИ",
	"Every tower can be upgraded three times (Mk 1 to Mk 4). Selling returns 70% of the credits invested. Some towers cannot hit flying enemies until an upgrade unlocks it — check the inspector panel.": "Каждую башню можно улучшить трижды (Мк 1–Мк 4). Продажа возвращает 70% вложенных кредитов. Некоторые башни не могут бить летающих до открытия улучшения — проверяйте панель башни.",
	"HOSTILES": "ПРОТИВНИКИ",
	"Shields absorb damage and regenerate if you stop firing. Burrowers become untargetable while underground. Healers restore nearby arachnids. Spitters disable towers. Flying enemies ignore road-blocking tactics and require anti-air coverage. Elites frenzy below half health; the Brood Tyrant has three escalating phases.": "Щиты поглощают урон и восстанавливаются, если прекратить огонь. Землерои становятся неуязвимы под землёй. Лекари восстанавливают ближайших арахнидов. Плеватели отключают башни. Летающие игнорируют наземные заслоны и требуют ПВО. Элитные впадают в ярость ниже половины здоровья; у Тирана выводка три усиливающиеся фазы.",
	"TACTICS": "ТАКТИКА",
	"Build where two roads cross or run close together so one tower covers both. Command Relays buff nearby tower damage and rate — place them beside your kill zone, not on the front line. Send waves early for bonus credits when you are confident.": "Стройте там, где дороги пересекаются или идут рядом, чтобы одна башня накрывала обе. Командные ретрансляторы усиливают урон и скорость ближайших башен — ставьте их рядом с зоной поражения, а не на передовой. Вызывайте волны досрочно за бонусные кредиты, когда уверены в обороне.",
	"The campaign runs 15 sectors: five easy, five medium and five very hard. Stars depend on remaining base integrity (80%+ = 3 stars, 45%+ = 2 stars). Progress, best stars and settings are stored locally.": "Кампания состоит из 15 секторов: пять лёгких, пять средних и пять очень сложных. Звёзды зависят от оставшейся прочности базы (80%+ = 3 звезды, 45%+ = 2 звезды). Прогресс, лучшие звёзды и настройки хранятся локально.",
}

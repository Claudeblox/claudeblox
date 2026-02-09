# CLAUDEBLOX — Проект: Claude строит Roblox-игры

## ЧТО ЭТО
AI (Claude Code) автономно создаёт Roblox-игры через MCP подключение к Roblox Studio, играет в них, стримит и постит в Twitter.

## ТЕКУЩИЙ СТАТУС
Первый билд игры "The Backrooms: Level 0" выполнен.
Структура создана (3 уровня, 400+ объектов, 8 скриптов, UI).
**Проблема:** Lighting не работает корректно — всё белое в Play mode. Нужен фикс освещения.
Агенты и скиллы работают, но pipeline нуждается в доработке (нет цикла тестирования).

## СЛЕДУЮЩИЙ ШАГ
1. ✅ Live Thoughts для стрима — write_thought.py + thoughts.html overlay
2. ✅ computer-player улучшен — контроль камеры, скриншоты каждую итерацию
3. ✅ Скриншоты по циклам — screenshots/cycle_001/, cycle_002/...
4. ✅ CLAUDE.md переведён на английский (для стрима)
5. ✅ keep_alive.pyw — Shadow PC не отключается
6. ✅ thoughts.html исправлен — больше не моргает
7. Коллега фиксит claudezilla — добавить секцию про скриншоты из cycle_XXX
8. Ресет и запуск нового проекта

## ТЕКУЩАЯ ИГРА — The Backrooms: Level 0
Horror в стиле Backrooms. 3 уровня нарастающего ужаса:
- **Level 0** — жёлтые комнаты (12 комнат + 14 коридоров), Fabric ковёр, Neon лампы
- **Level 1** — тёмные склады (4 зала), Concrete, минимальный свет
- **Level 2** — красный коридор (один длинный, 200 studs)
- **Entity** — чёрная фигура, патрулирует, chase AI
- **Механики:** сбор ExitSign → открытие дверей, прятки в локерах, фонарик, стамина

### Что создано в Studio:
- Workspace: Levels (3), Collectibles (9), HidingSpots (3), Entity, ExitDoors (3), SpawnLocation
- ServerScriptService: GameManager, EntityAI, CollectibleManager, DoorManager
- ReplicatedStorage: Modules (GameConfig, SoundBank), Events (8 RemoteEvents)
- StarterGui: HorrorUI (stamina, prompts, death/win screens), IntroScreen
- StarterPlayerScripts: HorrorClient, AmbientSound
- StarterPack: Flashlight (Tool + SpotLight)
- Lighting: Atmosphere, ColorCorrection, Bloom

### Lighting решение (ВАЖНО для агентов):
- Atmosphere УДАЛИТЬ — вымывает всё в белый
- Bloom/ColorCorrection — отключить или не создавать
- Sky — не создавать (пустые текстуры = белый)
- EnvironmentDiffuseScale = 0, EnvironmentSpecularScale = 0
- Brightness = 0, Ambient = [0,0,0], OutdoorAmbient = [0,0,0]
- Fog: чёрный [0,0,0], FogStart=0, FogEnd=80
- Лампы: Material=SmoothPlastic (НЕ Neon!), PointLight Brightness=0.15, Range=12
- Весь свет ТОЛЬКО от PointLight в лампах

### Известные баги:
- Props папка пустая (нет мебели, труб)
- Скрипты не тестированы в runtime

## VPS — ВЫБРАННЫЙ СЕРВЕР
**Shadow PC Neo — $34.19/мес**
- GPU: NVIDIA RTX 2000 Ada 16GB (≈RTX 4060)
- CPU: AMD EPYC 9354P 8 vCores @ 3.25 GHz
- RAM: 16 GB
- Storage: 512 GB SSD
- OS: Windows 11
- Bandwidth: до 1 Gb/s
- Без обязательств, отмена в любой момент
- Первый месяц ~€19.99 (~$22) по акции
- Сайт: https://shadow.tech/shadowpc/offers/

## РАЗДЕЛЕНИЕ РАБОТЫ

### Я (60-70%):
- **Ядро pipeline:** roblox-architect, luau-scripter, world-builder, computer-player
- **Все скиллы:** /build-game, /test-game, /play-game, /dev-update
- **Инфраструктура:** VPS, deploy, MCP, OBS стрим
- **Архитектура проекта** и все технические решения
- **Фикс багов** и итерации игры

### Коллега (30-40%):
- **3 промпта агентов:** luau-reviewer, roblox-playtester, claudezilla
- **Сайт проекта:** лендинг + дашборд
- Файлы: `deploy/.claude/agents/luau-reviewer.md`, `roblox-playtester.md`, `claudezilla.md`

## ЧТО СДЕЛАНО
1. ✅ Все файлы для Railway deploy написаны в `deploy/`
2. ✅ 7 субагентов (game-publisher убран)
3. ✅ 4 скилла (publish-game убран)
4. ✅ api.py — VPS endpoints, claudeblox.logs
5. ✅ schema.sql — SQL для Supabase (схема claudeblox)
6. ✅ VPS скрипты в `vps/`
7. ✅ Git repo инициализирован
8. ✅ Roblox Studio установлен локально
9. ✅ MCP плагин установлен в Studio
10. ✅ HTTP Requests включены в Game Settings
11. ✅ MCP сервер добавлен в Claude Code
12. ✅ MCP подключение протестировано (create, read, script, delete — всё работает)
13. ✅ Агенты переписаны под реальные MCP tools (не run_code)
14. ✅ Скиллы обновлены с конкретными MCP инструкциями
15. ✅ Первый билд The Backrooms выполнен (architect → scripter → world-builder)
16. ✅ Lighting починен — Atmosphere/Neon/Bloom убраны, только PointLight
17. ✅ Live Thoughts для стрима — write_thought.py + thoughts.html overlay
18. ✅ computer-player улучшен — контроль камеры, оценка скриншотов, write_thought
19. ✅ claudezilla — использует скриншоты от computer-player
20. ✅ CLAUDE.md (deploy_vps) переведён на английский
21. ✅ screenshot_game.py — скриншот viewport (обрезанный, для твитов)
22. ✅ action.py — добавлен --move-relative для контроля камеры

## MCP TOOLS (подтверждено работающие)
- `create_object` / `create_object_with_properties` — создание объектов
- `mass_create_objects_with_properties` — batch создание
- `set_property` / `mass_set_property` — изменение свойств
- `set_script_source` / `edit_script_lines` / `insert_script_lines` — скрипты
- `get_script_source` — чтение скриптов
- `get_project_structure` / `get_instance_children` — структура
- `get_instance_properties` — свойства объекта
- `search_objects` / `search_files` — поиск
- `smart_duplicate` — дублирование с офсетами
- `add_tag` / `set_attribute` — теги и атрибуты
- `delete_object` — удаление
- `get_place_info` — информация о плейсе

### MCP ИЗВЕСТНЫЕ ПРОБЛЕМЫ
- Color3 формат: MCP принимает [R, G, B] как 0-255, но Roblox хранит 0-1. Нужно тестировать.
- Atmosphere Color задавался как серый вместо жёлтого — формат передачи нужно уточнить.
- Два Claude Code не могут одновременно использовать один MCP сервер — конфликт.
- Дубликаты объектов при создании (2x Atmosphere, 2x Bloom) — агенты не проверяют существующие.

## АРХИТЕКТУРА
```
ЛОКАЛЬНЫЙ ТЕСТ (сейчас):
├── Roblox Studio (открыт, Backrooms, MCP плагин)
├── Claude Code (MCP подключён к Studio)
└── Тестируем игру

ПРОД:
├── Shadow PC Neo ($34.19/мес)
│   ├── Roblox Studio + MCP
│   ├── Claude Code
│   └── OBS → стрим
└── Railway
    ├── Flask API (оркестрация)
    ├── Twitter MCP, Image Gen MCP
    └── ttyd (веб-терминал)
```

## КЛЮЧЕВЫЕ ФАЙЛЫ
- Проект: `C:\Users\vovav\documents\work\claudeblox\`
- Deploy: `deploy/` → Railway
- VPS: `vps/` → Windows VPS
- Агенты: `deploy/.claude/agents/` (7 шт)
- Скиллы: `deploy/.claude/skills/` (4 шт)

## СУБАГЕНТЫ (7 шт)
1. **roblox-architect** — проектирует архитектуру игры (МОЁ)
2. **luau-scripter** — пишет Luau код (МОЁ)
3. **luau-reviewer** — ревью кода (КОЛЛЕГА)
4. **world-builder** — строит мир (МОЁ)
5. **roblox-playtester** — тестирует структуру (КОЛЛЕГА)
6. **computer-player** — визуально играет (МОЁ, только VPS)
7. **claudezilla** — постит в Twitter (КОЛЛЕГА)

## СКИЛЛЫ (4 шт)
- `/build-game` — architect → scripter → world-builder (нужен test-цикл!)
- `/test-game` — reviewer → playtester → отчёт
- `/play-game` — визуальная игра (только VPS)
- `/dev-update` — пост в Twitter через claudezilla

## ВАЖНО
- Все агенты используют реальные MCP tools (НЕ run_code)
- Строим из примитивов (Part, WedgePart, Cylinder) + Materials + Lighting — без кастомных мешей
- Одна игра, итеративные улучшения (не много плохих игр)
- Pipeline должен быть: build → test → fix → test (цикл!)
- GPU VPS нужен для прода (Roblox Studio требует DirectX 11)
- Локально: Intel UHD Graphics + i5-10300H — для теста хватит

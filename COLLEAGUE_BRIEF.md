# ClaudeBlox — Задачи для коллеги

## Что это за проект

ClaudeBlox — AI (Claude Code) автономно создаёт Roblox-игры через MCP подключение к Roblox Studio, стримит процесс и постит в Twitter.

Как это работает:
1. Claude Code подключён к Roblox Studio через MCP (Model Context Protocol)
2. Агенты (субпроцессы Claude) выполняют разные роли: архитектор, программист, строитель мира, тестер и т.д.
3. Pipeline: `/build-game` запускает цепочку агентов → они создают игру прямо в Studio
4. После билда `/test-game` запускает тестирование → находит баги → фиксим → тестим снова
5. Потом игра стримится, а AI постит обновления в Twitter

Текущая игра: **The Backrooms: Level 0** — horror в стиле Backrooms.

## Полная архитектура (чтобы ты понимал картину)

```
Pipeline:
/build-game → architect → scripter → world-builder → ИГРА СОЗДАНА
                                                        ↓
/test-game  → luau-reviewer → roblox-playtester → ОТЧЁТ С БАГАМИ
                                                        ↓
                                              scripter/world-builder фиксят
                                                        ↓
                                              /test-game снова → цикл

/play-game  → computer-player (играет визуально, VPS)
/dev-update → claudezilla (постит в Twitter)
```

Агенты:
- **roblox-architect** — проектирует игру (документ-архитектура) ← МОЁ
- **luau-scripter** — пишет Luau код через MCP ← МОЁ
- **world-builder** — строит 3D мир через MCP ← МОЁ
- **computer-player** — визуально играет в игру ← МОЁ
- **luau-reviewer** — ревьюит код (read-only) ← ТВОЁ
- **roblox-playtester** — тестирует структуру (read-only) ← ТВОЁ
- **claudezilla** — постит в Twitter ← ТВОЁ (уже сделал)

## Твои задачи

### 1. Главный промпт (deploy/CLAUDE.md)

Файл: `deploy/workspace_claude.md` — **переписать с нуля** и переименовать в `deploy/CLAUDE.md`.

Сейчас `workspace_claude.md` полностью устаревший — там `run_code`, `log_action`, `insert_model` и другие несуществующие tools. Нужно переписать.

Это **продакшн промпт** — Claude Code запускается на VPS из `deploy/` папки и автономно строит игры. Этот файл определяет всю его работу.

**Что нужно сделать:**
- Прочитай текущий `deploy/workspace_claude.md` — это старая версия, нужно переписать
- Прочитай корневой `CLAUDE.md` — там актуальная инфа (статус, MCP tools, Lighting правила)
- Напиши новый `deploy/CLAUDE.md` с нуля — чёткий, понятный, с реальными MCP tools
- Удали `deploy/workspace_claude.md` после

**Важные секции которые должны быть:**
- Роль ClaudeBlox (AI строит Roblox игры автономно)
- Pipeline: /build-game → /test-game → fix → /test-game → /play-game → /dev-update
- Реальные MCP tools (см. список ниже)
- Roblox game structure (какие сервисы для чего)
- Luau coding standards
- Lighting правила (КРИТИЧНО — см. секцию ниже)
- Quality standards
- Субагенты и скиллы

**КРИТИЧНЫЕ правила для Lighting (обязательно включить):**
```
- Atmosphere — УДАЛИТЬ (любой Density вымывает в белый)
- Bloom/ColorCorrection — отключить
- Sky — НЕ создавать (пустые текстуры = белый фон)
- EnvironmentDiffuseScale=0, EnvironmentSpecularScale=0
- Brightness=0, Ambient=[0,0,0], OutdoorAmbient=[0,0,0]
- Fog: чёрный, FogStart=0, FogEnd=80
- Лампы: SmoothPlastic (НЕ Neon!), PointLight Brightness=0.15, Range=12
- Neon материал ИЗЛУЧАЕТ свет — никогда не использовать на больших поверхностях
```

### 2. Два промпта агентов

Файлы лежат в `deploy/.claude/agents/`. Там уже есть черновики — тебе нужно их доработать и улучшить.

#### luau-reviewer.md
**Что делает:** Ревьюит Luau код в Roblox Studio. Получает путь к скрипту, читает его, ищет баги и антипаттерны.

**MCP tools которые он использует (read-only):**
- `mcp__robloxstudio__get_script_source` — читает исходный код скрипта по пути (например `game.ServerScriptService.GameManager`)
- `mcp__robloxstudio__get_project_structure` — дерево всех объектов в Studio (с параметром `scriptsOnly: true` покажет только скрипты)
- `mcp__robloxstudio__search_files` — поиск по содержимому скриптов (например найти все места где используется `wait()`)

**Что должен проверять:**
- Deprecated API: `wait()` вместо `task.wait()`, `spawn()` вместо `task.spawn()`
- Безопасность: валидация RemoteEvent на сервере (typeof checks, distance checks)
- Memory leaks: незакрытые connections, события без Disconnect
- Ошибки: nil checks, WaitForChild без timeout
- Стиль: GetService вверху, нет магических чисел
- Производительность: тяжёлые циклы, лишние RenderStepped

**Формат выхода:** Отчёт с найденными проблемами, severity (critical/warning/info), и предложением фикса.

#### roblox-playtester.md
**Что делает:** Тестирует структуру игры через MCP. Проверяет что всё создано правильно, нет сломанных объектов, свойства корректные.

**MCP tools которые он использует (read-only):**
- `mcp__robloxstudio__get_project_structure` — общая структура (maxDepth=5-10)
- `mcp__robloxstudio__get_instance_properties` — свойства конкретного объекта
- `mcp__robloxstudio__get_instance_children` — дочерние объекты
- `mcp__robloxstudio__search_objects` — поиск по имени или классу
- `mcp__robloxstudio__get_tags` — теги на объекте
- `mcp__robloxstudio__get_attributes` — атрибуты объекта

**Что должен проверять:**
- Все объекты из архитектурного документа существуют
- Parts имеют Anchored=true (кроме тех что должны двигаться)
- Parts имеют осмысленные имена (не "Part", не "Model")
- Materials и Colors не дефолтные
- Lighting: нет дубликатов (2x Atmosphere, 2x Bloom)
- Lighting: нет мусорных дефолтных эффектов (Sky, SunRays, DepthOfField)
- Lighting правила соблюдены (см. секцию Lighting выше)
- Теги и атрибуты на месте (Collectible, HidingSpot, ExitDoor)
- Скрипты существуют и имеют исходный код (hasSource=true)
- Part count в пределах бюджета (<2000 для мобильных)

**Формат выхода:** Чеклист passed/failed + список проблем.

### 3. Скилл /test-game

Файл: `deploy/.claude/skills/test-game/SKILL.md`

Это оркестратор который вызывает твоих двух агентов (reviewer + playtester) и выдаёт финальный отчёт.

**Уже есть черновик** — доработай его. Pipeline:
1. Вызвать luau-reviewer → получить список багов в коде
2. Вызвать roblox-playtester → получить чеклист структуры
3. Объединить в финальный отчёт: `READY` или `NEEDS FIXES`

**Формат отчёта:**
```
TEST RESULTS

Code Review:
- Scripts reviewed: X
- Critical issues: Y
- Warnings: Z
[список с номерами строк и фиксами]

Structure Test:
- Game Structure:  PASS/FAIL
- Scripts Source:  PASS/FAIL
- RemoteEvents:   PASS/FAIL
- World Content:  PASS/FAIL
- UI Structure:   PASS/FAIL
- Tagged Objects:  PASS/FAIL
- Lighting Rules:  PASS/FAIL
- Performance:     PASS/FAIL

VERDICT: READY / NEEDS FIXES
```

### 4. Сайт проекта

Лендинг + дашборд для ClaudeBlox. Стек на твой выбор.

**Что показывать:**
- Что за проект (AI строит Roblox игры автономно)
- Текущая игра и её статус
- Ссылка на стрим (когда будет)
- Ссылка на Twitter
- Визуально красиво — тёмная тема, можно в стиле Backrooms (жёлтый + тёмный)

### 5. claudezilla.md (уже сделал, проверь)

Если нужно доработать — доработай. Стиль: casual tech, вау-фактор "AI делает это сам".

## Как устроены промпты агентов

Каждый файл — Markdown с YAML frontmatter. Пример структуры:

```markdown
---
name: agent-name
description: Краткое описание что делает агент
model: opus
---

# AGENT NAME

Описание роли.

## YOUR MISSION
Что агент делает когда его вызывают.

## MCP TOOLS YOU USE
Какие tools доступны с примерами вызовов.

## PROCESS
Пошаговый процесс работы.

## OUTPUT
Формат выходного отчёта.

## RULES
Строгие правила которым агент следует.
```

## Как устроены скиллы

Файл: `deploy/.claude/skills/<skill-name>/SKILL.md`. Пример:

```markdown
---
name: skill-name
description: Что делает скилл
user-invocable: true
context: fork
---

# /skill-name

## Pipeline
Шаги 1, 2, 3...

## Output
Формат результата.
```

Посмотри существующие файлы как примеры:
- Агенты: `deploy/.claude/agents/roblox-architect.md`, `luau-scripter.md`, `world-builder.md`
- Скиллы: `deploy/.claude/skills/build-game/SKILL.md`

## Структура проекта

```
claudeblox/
├── CLAUDE.md                          # Корневой промпт (актуальная инфа, статус, правила)
├── COLLEAGUE_BRIEF.md                 # Этот файл
├── .gitignore
│
├── deploy/                            # Всё для деплоя на VPS/Railway
│   ├── workspace_claude.md            # СТАРЫЙ промпт → ПЕРЕПИСАТЬ в CLAUDE.md
│   ├── Dockerfile                     # Docker для Railway
│   ├── api.py                         # Flask API (VPS оркестрация)
│   ├── db.py                          # Supabase клиент
│   ├── schema.sql                     # SQL для Supabase (claudeblox схема)
│   ├── gen_mcp.py                     # Генерация MCP конфига
│   ├── twitter_mcp.js                 # Twitter MCP сервер
│   ├── nginx.conf                     # Nginx конфиг
│   ├── package.json                   # Node зависимости (twitter)
│   ├── railway.toml                   # Railway конфиг
│   ├── start.sh                       # Стартовый скрипт
│   ├── .dockerignore
│   │
│   ├── .claude/
│   │   ├── agents/                    # 7 субагентов
│   │   │   ├── roblox-architect.md    # Проектирует игру (МОЁ)
│   │   │   ├── luau-scripter.md       # Пишет Luau код (МОЁ)
│   │   │   ├── world-builder.md       # Строит 3D мир (МОЁ)
│   │   │   ├── computer-player.md     # Играет визуально (МОЁ)
│   │   │   ├── luau-reviewer.md       # Ревью кода (ТВОЁ) ← доработать
│   │   │   ├── roblox-playtester.md   # Тестирует структуру (ТВОЁ) ← доработать
│   │   │   └── claudezilla.md         # Twitter посты (ТВОЁ) ← проверить
│   │   │
│   │   └── skills/                    # 4 скилла
│   │       ├── build-game/SKILL.md    # /build-game (МОЁ)
│   │       ├── test-game/SKILL.md     # /test-game (ТВОЁ) ← доработать
│   │       ├── play-game/SKILL.md     # /play-game (МОЁ)
│   │       └── dev-update/SKILL.md    # /dev-update (МОЁ)
│
├── vps/                               # Скрипты для Windows VPS
│   ├── setup.ps1                      # Установка всего на VPS
│   ├── start-claude.ps1               # Запуск Claude Code
│   └── stream.bat                     # Запуск стрима
```

## Реальные MCP tools (для промптов)

Это **подтверждённо работающие** tools. Используй только их в промптах:

**Создание:**
- `mcp__robloxstudio__create_object` — создать объект (className, parent, name)
- `mcp__robloxstudio__create_object_with_properties` — создать с пропертями
- `mcp__robloxstudio__mass_create_objects` — batch создание
- `mcp__robloxstudio__mass_create_objects_with_properties` — batch с пропертями

**Свойства:**
- `mcp__robloxstudio__set_property` — задать свойство
- `mcp__robloxstudio__mass_set_property` — batch задать свойство
- `mcp__robloxstudio__get_instance_properties` — прочитать все свойства

**Скрипты:**
- `mcp__robloxstudio__set_script_source` — записать код скрипта
- `mcp__robloxstudio__get_script_source` — прочитать код скрипта
- `mcp__robloxstudio__edit_script_lines` — заменить строки
- `mcp__robloxstudio__insert_script_lines` — вставить строки
- `mcp__robloxstudio__delete_script_lines` — удалить строки

**Чтение/поиск:**
- `mcp__robloxstudio__get_project_structure` — дерево (maxDepth, scriptsOnly)
- `mcp__robloxstudio__get_instance_children` — дочерние объекты
- `mcp__robloxstudio__search_objects` — поиск по имени/классу
- `mcp__robloxstudio__search_files` — поиск по содержимому скриптов

**Теги/атрибуты:**
- `mcp__robloxstudio__add_tag` / `get_tags` / `get_tagged` — CollectionService теги
- `mcp__robloxstudio__set_attribute` / `get_attributes` — атрибуты

**Другое:**
- `mcp__robloxstudio__smart_duplicate` — дублирование с офсетами
- `mcp__robloxstudio__delete_object` — удаление
- `mcp__robloxstudio__get_place_info` — инфо о плейсе

**НЕ существуют (не использовать!):**
- ~~run_code~~ — нет такого
- ~~log_action~~ — нет такого
- ~~insert_model~~ — нет такого
- ~~create_script~~ — используй create_object + set_script_source
- ~~edit_script~~ — используй edit_script_lines

## Репозиторий
Ветка `main`. Агенты в `deploy/.claude/agents/`. Скиллы в `deploy/.claude/skills/`.

## Вопросы
Если что-то непонятно — спрашивай.

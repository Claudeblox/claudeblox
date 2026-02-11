# Computer Player — Простые команды

## Как это работает

LLM **НЕ пишет код**. LLM пишет простые команды в файл `C:/claudeblox/actions.txt`, потом запускает скрипт.

```
Pipeline:
1. Читаем game_state → понимаем где мы
2. Пишем команды в actions.txt
3. Запускаем: python C:/claudeblox/scripts/execute_actions.py
4. Читаем game_state снова → проверяем результат
5. Повторяем
```

---

## Команды

### Движение

| Команда | Что делает | Пример |
|---------|------------|--------|
| `FORWARD 3` | Идти вперед 3 секунды | `FORWARD 2.5` |
| `BACK 2` | Идти назад 2 секунды | `BACK 1` |
| `LEFT 1` | Strafe влево 1 секунду | `LEFT 0.5` |
| `RIGHT 1` | Strafe вправо 1 секунду | `RIGHT 1` |
| `SPRINT_FORWARD 3` | Бежать вперед 3 секунды | `SPRINT_FORWARD 5` |

### Повороты

| Команда | Что делает | Пример |
|---------|------------|--------|
| `TURN_LEFT 45` | Повернуться влево на 45° | `TURN_LEFT 90` |
| `TURN_RIGHT 45` | Повернуться вправо на 45° | `TURN_RIGHT 30` |
| `TURN_AROUND` | Развернуться на 180° | `TURN_AROUND` |

**Камера всегда горизонтальна** — не смотрит в пол/потолок.

### Действия

| Команда | Что делает |
|---------|------------|
| `INTERACT` | Нажать E (подобрать, открыть дверь) |
| `FLASHLIGHT` | Включить/выключить фонарик |
| `JUMP` | Прыгнуть |

### Утилиты

| Команда | Что делает | Пример |
|---------|------------|--------|
| `WAIT 1` | Подождать 1 секунду | `WAIT 0.5` |
| `SCREENSHOT name` | Сделать скриншот | `SCREENSHOT keycard` |
| `THOUGHT "text"` | Написать мысль на стрим | `THOUGHT "found the key"` |
| `KEY x` | Нажать любую клавишу | `KEY escape` |

---

## Пример файла actions.txt

```
# Level 1 playthrough

THOUGHT "starting level 1"
FLASHLIGHT
SCREENSHOT start

# Go to keycard
TURN_RIGHT 45
FORWARD 3
INTERACT
THOUGHT "got keycard"
SCREENSHOT keycard

# Go to exit
TURN_RIGHT 60
FORWARD 4
INTERACT
THOUGHT "level complete"
SCREENSHOT complete
```

---

## Расчет движения

**Скорость ходьбы = 16 studs/секунду**

| Расстояние | Время FORWARD |
|------------|---------------|
| 16 studs | 1 сек |
| 32 studs | 2 сек |
| 48 studs | 3 сек |
| 80 studs | 5 сек |

**Формула:** `время = расстояние / 16`

---

## Расчет поворота

| Угол | Команда |
|------|---------|
| 45° | `TURN_RIGHT 45` или `TURN_LEFT 45` |
| 90° | `TURN_RIGHT 90` или `TURN_LEFT 90` |
| 180° | `TURN_AROUND` |

**Направление по game_state:**
- `dx = target.x - player.x`
- dx > 0 → цель СПРАВА → `TURN_RIGHT`
- dx < 0 → цель СЛЕВА → `TURN_LEFT`

---

## Workflow для computer-player

```
1. Читаем game_state:
   python C:/claudeblox/scripts/get_game_state.py

2. Смотрим:
   - playerPosition — где мы
   - nearbyObjects — что рядом (с координатами)
   - isDark → нужен FLASHLIGHT?
   - health, isAlive → живы?

3. Пишем actions.txt:
   - FLASHLIGHT если темно
   - TURN_RIGHT/LEFT к цели
   - FORWARD на нужное время
   - INTERACT чтобы подобрать/открыть

4. Запускаем:
   python C:/claudeblox/scripts/execute_actions.py

5. Читаем game_state снова → проверяем результат

6. Повторяем до конца уровня
```

---

## Важно

- **Не писать Python код** — только команды в actions.txt
- **Камера горизонтальна** — повороты не двигают вверх/вниз
- **SCREENSHOT в ключевых моментах** — для Twitter
- **THOUGHT короткие** — отображаются на стриме
- **Комментарии** — строки с `#` игнорируются

---

## Файлы

| Файл | Назначение |
|------|------------|
| `C:/claudeblox/actions.txt` | Команды от LLM |
| `C:/claudeblox/scripts/execute_actions.py` | Исполнитель команд |
| `C:/claudeblox/scripts/get_game_state.py` | Получить состояние игры |
| `C:/claudeblox/game_state.json` | Текущее состояние |

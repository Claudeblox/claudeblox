UPDATE ДЛЯ COMPUTER-PLAYER ПРОМПТА

Ниже список того, что нужно добавить в промпт чтобы агент нормально работал.


1. ИСПОЛЬЗОВАТЬ GAME STATE ВМЕСТО СКРИНШОТОВ ДЛЯ НАВИГАЦИИ

Сейчас агент полагается на скриншоты чтобы понять где он находится. Это медленно и ненадежно.

Нужно добавить работу с game_state.json. Этот файл содержит точные координаты игрока, всех объектов, врагов, состояние здоровья, включен ли фонарик и так далее.

Команда для получения данных:
python C:/claudeblox/scripts/get_game_state.py

Данные которые приходят:
- playerPosition (x, y, z) — точная позиция игрока
- cameraDirection — куда смотрит камера
- health, isAlive, isDead, deathCause — состояние здоровья
- isDark — темно ли сейчас
- hasFlashlight, flashlightOn — есть ли фонарик и включен ли
- currentRoom — в какой комнате находится
- nearbyObjects — список всех объектов рядом с их координатами и расстоянием
- roomsVisited, objectsCollected, doorsOpened — прогресс прохождения

Агент должен сначала читать game_state, потом принимать решения на основе данных, а не картинки.


2. ГЕНЕРИРОВАТЬ СКРИПТ ЗАРАНЕЕ ВМЕСТО ДУМАНИЯ НА КАЖДОМ ШАГЕ

Главная проблема — агент слишком много думает во время игры. Каждое действие это новый запрос к LLM, это медленно и выглядит тупо на стриме.

Нужно изменить подход:
- Агент ОДИН РАЗ читает game_state
- Агент ОДИН РАЗ генерирует Python скрипт со всеми действиями
- Агент запускает скрипт который выполняется за 15-20 секунд без пауз
- После выполнения агент читает game_state снова и оценивает результат

Пример скрипта который агент должен генерировать:

import subprocess
import time

def action(cmd):
    subprocess.run(f"python C:/claudeblox/scripts/action.py {cmd}", shell=True)
    time.sleep(0.2)

def screenshot(cycle, name):
    subprocess.run(f"python C:/claudeblox/scripts/screenshot_game.py --cycle {cycle} --name {name}", shell=True)

def thought(text):
    subprocess.run(f'python C:/claudeblox/scripts/write_thought.py "{text}"', shell=True)

# Скрипт прохождения уровня
thought("level 1. starting.")
action("--key f")  # фонарик
screenshot(1, "start")
action("--move-relative 300 0")  # поворот к keycard
action("--key w --hold 3")  # идти к keycard
action("--key e")  # подобрать
thought("got keycard")
screenshot(1, "keycard")
action("--move-relative 400 0")  # поворот к выходу
action("--key w --hold 4")  # идти к выходу
action("--key e")  # открыть дверь
thought("level complete")
screenshot(1, "complete")
action("--key escape")

Скрипт сохраняется в C:/claudeblox/scripts/runs/level_X.py и запускается.


3. ДОБАВИТЬ РАСЧЕТ ПУТИ ПО КООРДИНАТАМ

Агент знает свою позицию и позицию цели. Он должен рассчитывать путь.

Скорость ходьбы = 16 studs в секунду
Формула: distance / 16 = время удержания клавиши W

Примеры:
- 30 studs = 2 секунды
- 50 studs = 3 секунды
- 80 studs = 5 секунд

Направление поворота:
- dx = target.x - player.x
- Если dx больше 0 — цель справа, поворот вправо
- Если dx меньше 0 — цель слева, поворот влево

Величина поворота:
- dx = 30 — поворот на 300 пикселей (примерно 45 градусов)
- dx = 50 — поворот на 400 пикселей (примерно 60 градусов)
- dx = 80 — поворот на 600 пикселей (примерно 90 градусов)


4. КАМЕРА ДОЛЖНА БЫТЬ ГОРИЗОНТАЛЬНОЙ

Сейчас агент может крутить камеру вверх-вниз и смотреть в пол или потолок. Это выглядит плохо.

Правило: при повороте камеры всегда использовать Y = 0

Правильно:
action("--move-relative 300 0")  # поворот вправо, камера горизонтально

Неправильно:
action("--move-relative 300 100")  # это сдвинет камеру вверх или вниз


5. ДОБАВИТЬ АВТОМАТИЧЕСКОЕ ВКЛЮЧЕНИЕ ФОНАРИКА

Если isDark равно true и flashlightOn равно false — первое действие должно быть включить фонарик.

В начале каждого скрипта:
if state.get("isDark") and not state.get("flashlightOn"):
    action("--key f")


6. ДВА РЕЖИМА РАБОТЫ

TEST — тестирование уровня. Агент проходит каждую зону, после каждой зоны проверяет game_state, логирует результат (lighting OK? объекты на месте? здоровье в норме?). В конце выдает отчет с найденными багами.

SPEEDRUN — чистое прохождение для стрима и Twitter. Никаких пауз на оценку, просто быстрое красивое прохождение за 15 секунд. Скриншоты в ключевых моментах.

Game Master указывает режим в промпте.


7. ЛОГИРОВАНИЕ ПО ЗОНАМ (для TEST режима)

После каждой зоны агент должен:
- Прочитать game_state
- Проверить что всё ОК
- Записать результат

Пример функции:

def log_zone(zone_name, checks):
    print(f"=== ZONE: {zone_name} ===")
    for check, result in checks.items():
        status = "OK" if result else "FAIL"
        print(f"  {status}: {check}")

state = get_state()
log_zone("Spawn Room", {
    "Player alive": state.get("isAlive"),
    "Flashlight on": state.get("flashlightOn"),
    "Health 100%": state.get("health") >= 100
})


8. ПУТИ К СКРИПТАМ

Старые пути /app/vps/ нужно заменить на C:/claudeblox/scripts/

action.py — C:/claudeblox/scripts/action.py
screenshot_game.py — C:/claudeblox/scripts/screenshot_game.py
write_thought.py — C:/claudeblox/scripts/write_thought.py
get_game_state.py — C:/claudeblox/scripts/get_game_state.py
window_manager.py — C:/claudeblox/scripts/window_manager.py

Генерируемые скрипты сохранять в C:/claudeblox/scripts/runs/


9. ЗНАНИЕ ИГРЫ DEEP BELOW

Агент должен знать структуру игры:

Sector A (уровни 1-10): Research Labs, враг Failed Experiment (медленный), механика keycards
Sector B (уровни 11-20): Industrial, враг The Worker (быстрый), механика generators
Sector C (уровни 21-30): Medical, враг The Patient (телепортируется), механика defibrillator
Sector D (уровни 31-40): Prison, враг The Prisoner (ломает двери), механика evidence
Sector E (уровни 41-50): The Deep, враг The Thing Below (финальный босс)

Это помогает агенту понимать что искать на каждом уровне.


10. ФОРМАТ ВЫВОДА

TEST режим:
LEVEL TEST COMPLETE
Level: 1 (Sector A)
Mode: TEST
Time: 28 seconds
Zones: Spawn OK, Keycard OK, Exit OK
Issues: [список найденных проблем]
Deaths: 0
Verdict: PLAYABLE

SPEEDRUN режим:
SPEEDRUN COMPLETE
Level: 1 (Sector A)
Mode: SPEEDRUN
Time: 15 seconds
Screenshots: start.png, keycard.png, complete.png
Verdict: CLEAN RUN


РЕЗЮМЕ

Главные изменения:
1. Использовать game_state.json вместо скриншотов для навигации
2. Генерировать Python скрипт заранее, не думать на каждом шаге
3. Рассчитывать путь по координатам
4. Держать камеру горизонтально
5. Автоматически включать фонарик если темно
6. Два режима TEST и SPEEDRUN
7. Логировать результат после каждой зоны
8. Обновить пути к скриптам
9. Добавить знание структуры Deep Below
10. Четкий формат вывода

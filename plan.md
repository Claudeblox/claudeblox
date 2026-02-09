# ПЛАН — ФИНАЛЬНЫЙ ДЕПЛОЙ CLAUDEBLOX

**СТАТУС: ГОТОВО К ТЕСТУ**

## СДЕЛАНО:
- [x] English output в CLAUDE.md
- [x] Camera rules добавлены
- [x] Auto-publish скрипт (publish.py)
- [x] Twitter MCP простая версия (без database)
- [x] IDLE сцена для OBS (idle_scene.html)
- [x] state.json — обновляется реже (только milestones)

---

## ПОДГОТОВКА

### 1. Claude Code на английском
- [ ] В `deploy/CLAUDE.md` добавить: "ALL OUTPUT IN ENGLISH. No Russian in terminal, logs, tweets."
- [ ] Проверить промпты агентов

### 2. Pump.fun токен
- [ ] Зайти на pump.fun
- [ ] Подключить кошелёк (Phantom/Solflare)
- [ ] Create token: название, тикер, описание, картинка
- [ ] Запустить (~0.02 SOL)

### 3. Очистить Roblox Studio
- [ ] File → New (новый пустой плейс)
- [ ] Сохранить как новый файл

### 4. Очистить сессию Claude
- [ ] Удалить `C:\claudeblox\gamemaster\state.json` (если хочешь с нуля)
- [ ] Или оставить если хочешь продолжить

### 5. Проверить run_forever.bat
- [ ] Запустить: `cd C:\claudeblox\deploy && .\run_forever.bat`
- [ ] Убедиться что Claude стартует
- [ ] Убедиться что делает твит
- [ ] Ctrl+C → проверить что рестартится через 10 сек

---

## КРИТИЧНЫЕ ФИКСЫ

### 6. КАМЕРА — УЁБИЩНАЯ
**Проблема:** Камера скачет туда-сюда, ужасный игровой опыт.

**Что сделать:**
- [ ] Исправить CameraController в StarterPlayerScripts
- [ ] Или убрать кастомную камеру и использовать дефолтную Roblox
- [ ] Для horror: заблокировать в first-person (CameraMode = LockFirstPerson)
- [ ] Протестировать что камера плавная

**Добавить в промпт luau-scripter:**
```
CAMERA RULES:
- First person locked for horror games
- NO custom camera scripts unless specifically needed
- If custom camera — must be SMOOTH, no jerky movement
- Test camera before completing level
```

---

## АВТОМАТИЧЕСКАЯ ПУБЛИКАЦИЯ

### 7. Auto-publish после каждого уровня
**Проблема:** Сейчас игра только в Studio. Люди не могут играть пока не опубликуешь вручную.

**Решение — Roblox Open Cloud API:**
- [ ] Зайти в Creator Dashboard → Credentials
- [ ] Создать API Key с правами на публикацию
- [ ] Написать `C:\claudeblox\scripts\publish.py`:
```python
import requests

API_KEY = "..."
UNIVERSE_ID = "..."
PLACE_ID = "..."

# Upload and publish
```

- [ ] В CLAUDE.md добавить:
```
ПОСЛЕ ЗАВЕРШЕНИЯ УРОВНЯ:
1. Вызвать: python C:/claudeblox/scripts/publish.py
2. Дождаться "Published successfully"
3. Твитнуть: "level X is live. go play: [link]"
```

**Pipeline:**
```
Claude строит Level → готово → publish.py → игра на Roblox.com → твит с ссылкой
```

---

## TWITTER API

### 8. Проверить Twitter
- [ ] API ключи настроены?
- [ ] Тестовый твит работает?
- [ ] MCP Twitter подключён?

---

## ЗАПУСК

### Порядок действий:
1. [ ] Исправить камеру
2. [ ] Настроить auto-publish
3. [ ] Проверить Twitter API
4. [ ] Очистить Studio / начать новый плейс
5. [ ] Запустить токен на Pump.fun
6. [ ] Запустить стрим (OBS)
7. [ ] Запустить `run_forever.bat`
8. [ ] Скинуть первый твит инвестору
9. [ ] Мониторить / спать

---

## ЗАМЕТКИ

- **Публикация:** После каждого уровня — авто-паблиш, чтобы люди могли играть
- **Камера:** Должна быть плавная, first-person для horror
- **Английский:** Весь output Claude на английском
- **State:** state.json сохраняет прогресс между сессиями

# /deploy

Git commit + push и PowerShell команды для обновления файлов на Shadow PC.

## Инструкции

1. Выполни `git status` чтобы увидеть изменённые файлы
2. Выполни `git add -A && git commit -m "Update" && git push`
3. Для каждого изменённого/добавленного файла из deploy_vps/ сгенерируй PowerShell команду:
   - Файл `deploy_vps/X` → скачать в `C:\claudeblox\X`
   - URL: `https://raw.githubusercontent.com/Claudeblox/claudeblox/master/deploy_vps/X`
   - Формат: `Invoke-WebRequest -Uri "URL" -OutFile "PATH"`
4. Объедини все команды в одну строку через `;`
5. Выведи готовую команду для копирования

## Пример вывода

```powershell
Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Claudeblox/claudeblox/master/deploy_vps/CLAUDE.md" -OutFile "C:\claudeblox\CLAUDE.md"; Invoke-WebRequest -Uri "https://raw.githubusercontent.com/Claudeblox/claudeblox/master/deploy_vps/.claude/agents/computer-player.md" -OutFile "C:\claudeblox\.claude\agents\computer-player.md"
```

# Быстрый старт и перезапуск сервера

Короткая шпаргалка: как запустить, перезапустить и остановить локальный сервер игры
без чтения остальной документации. Игра в браузере: **http://127.0.0.1:8787/**

## Запустить

- **Windows:** двойной клик по `start.bat`
- **macOS / Linux:** `./start.sh`
- **Вручную:** `node tools/serve.mjs 8787 --open`

## Перезапустить

- **Windows:** двойной клик по `restart.bat`
- **macOS / Linux:** `./restart.sh`

`restart.bat` / `restart.sh` останавливают только сервер этого проекта на порту 8787
и запускают его заново, после чего открывают браузер.

Одной командой из PowerShell в папке проекта, без скрипта:

```powershell
$c = Get-NetTCPConnection -LocalPort 8787 -State Listen -ErrorAction SilentlyContinue; if ($c) { $c | Select-Object -ExpandProperty OwningProcess -Unique | ForEach-Object { Stop-Process -Id $_ -Force } }; Start-Sleep 1; Start-Process node 'tools/serve.mjs 8787 --open' -WorkingDirectory $PWD
```

Она завершает **любой** процесс на порту 8787 (скрипты `restart.*` делают это аккуратнее — только сервер этого проекта).

Одной командой в bash (macOS / Linux, из папки проекта):

```bash
kill "$(lsof -ti tcp:8787)" 2>/dev/null; sleep 0.5; node tools/serve.mjs 8787 --open
```

## Остановить

- Закрыть окно сервера или нажать `Ctrl+C` в нём.
- Или освободить порт: `Get-NetTCPConnection -LocalPort 8787 -State Listen | ForEach-Object { Stop-Process -Id $_.OwningProcess -Force }` (PowerShell),
  `kill "$(lsof -ti tcp:8787)"` (macOS / Linux).

## Проверить, что сервер жив

```powershell
Invoke-WebRequest http://127.0.0.1:8787/ -UseBasicParsing | Select-Object StatusCode
```

```bash
curl -I http://127.0.0.1:8787/
```

Ожидается `200`. Если порт 8787 занят другой программой, `tools/serve.mjs` сам
возьмёт следующий свободный порт и напишет реальный адрес в консоль — смотрите её
вывод, а не только адрес из документации.

## Другие частые команды

```bash
godot --path .                                        # запустить игру в Godot
godot --headless --path . --fixed-fps 60 res://tests/TestRunner.tscn   # тесты
godot --headless --path . --export-release "Web" web/index.html        # пересобрать Web-экспорт
node tools/check-pages.mjs                            # проверка перед публикацией
```

Порт и корень сервера можно задать аргументами: `node tools/serve.mjs [порт] [корень] [--open]`.

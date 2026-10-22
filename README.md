# Pinkmine

## Description:

Pinkmine — кроссплатформенная система управления проектами для небольших команд. В ней создаются проекты, формируется команда с ролями (администратор системы, менеджер проекта, участник команды), а задачи ведутся списком и на Канбан-доске с фильтрацией по статусу, типу, сроку, исполнителю и тегу. Задача проходит статусы «Новая», «В работе», «На проверке», «Отложена», «Готова», «Закрыта», а исполнитель получает уведомления о назначении, комментариях и просрочке. Система состоит из веб-клиента, мобильного приложения для Android на Flutter и сервера с REST API на Python и Flask. Для работы с задачами через AI-ассистента реализован MCP-сервер.

## Installation:

1. Клонировать репозитории проекта:

```bash
git clone https://github.com/fpmi-hci-2026/hci-10-project-group-3.git
git clone https://github.com/fpmi-hci-2026/hci-10-backend-api-group-9.git
git clone https://github.com/fpmi-hci-2026/hci-10-frontend-group-9.git
git clone https://github.com/fpmi-hci-2026/hci-10-mobile-group-9.git
```

2. Mock-сервер API по спецификации OpenAPI:

```bash
cd hci-10-backend-api-group-9/api
pip install flask pyyaml jsonschema
python mock/mock_server.py --port 4010
```

3. MCP-сервер:

```bash
cd hci-10-backend-api-group-9/mcp-server
pip install -r requirements.txt
python -m pinkmine_mcp --reset
```

4. Сервер на Flask, веб-клиент и мобильное приложение: TO-DO, дополняется при реализации.

## Sub modules:

| Репозиторий | Описание |
|---|---|
| [hci-10-backend-api-group-9](https://github.com/fpmi-hci-2026/hci-10-backend-api-group-9) | Сервер на Python и Flask: REST API (спецификация OpenAPI, mock-сервер, тесты, коллекция Bruno) и MCP-сервер |
| [hci-10-frontend-group-9](https://github.com/fpmi-hci-2026/hci-10-frontend-group-9) | Веб-клиент: Канбан-доска, список задач, команда, роли и права |
| [hci-10-mobile-group-9](https://github.com/fpmi-hci-2026/hci-10-mobile-group-9) | Мобильное приложение для Android на Flutter: «Мои задачи», смена статуса, push-уведомления, офлайн-режим |

## Usage:

- Документация проекта: [вики](https://github.com/fpmi-hci-2026/hci-10-project-group-3/wiki).
- Отчёты по лабораторным работам:
  - [Лабораторная работа 1](docs/reports/lab1.pdf)
  - [Лабораторная работа 2](docs/reports/lab2.pdf)
  - [Лабораторная работа 3](docs/reports/lab3.pdf)
- Схема базы данных: [docs/pinkmine_schema.sql](docs/pinkmine_schema.sql), описание на странице [Схема базы данных](https://github.com/fpmi-hci-2026/hci-10-project-group-3/wiki/Database-Schema).
- Спецификация API: [docs/api/openapi.yaml](docs/api/openapi.yaml), описание и примеры запросов на странице [API-проекта](https://github.com/fpmi-hci-2026/hci-10-project-group-3/wiki/Project-API).
- Документация API в Swagger UI: в папке `docs` выполнить `python -m http.server 8000` и открыть http://localhost:8000/api/.
- MCP-сервер для Claude Desktop, Cursor и MCP Inspector: страница [MCP-сервер](https://github.com/fpmi-hci-2026/hci-10-project-group-3/wiki/MCP-Server).

## Contributing:

Команда группы 10, ФПМИ БГУ:

- Беглецов Герман
- Сидорская Дарья
- Яхновец Владислав

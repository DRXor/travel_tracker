# TravelTracker

Rails-приложение для планирования поездок: поездки, остановки маршрута и пункты подготовки.

## Запуск

    bundle install
    bin/rails db:migrate
    bin/rails server

Приложение откроется на http://localhost:3000. Страница с элементами интерфейса: `/ui-kit`.

## Тесты

    bin/rails test test/models

Тесты моделей лежат в `test/models/`:

- `trip_test.rb`: длительность поездки, метка «Скоро», процент готовности, смена статусов, валидации
- `stop_test.rb`: автоматическая нумерация остановок, перенумерация после удаления, каскадное удаление
- `checklist_item_test.rb`: значение по умолчанию, переключение отметки, валидации

## Схема базы данных

```mermaid
erDiagram
    USER ||--o{ TRIP : "has many"
    TRIP ||--o{ STOP : "has many"
    TRIP ||--o{ CHECKLIST_ITEM : "has many"

    USER {
        bigint id PK
        string name
        string email
        string password_digest
    }
    TRIP {
        bigint id PK
        bigint user_id FK
        string name
        string destination
        date start_date
        date end_date
        integer status "0 draft, 1 planned, 2 completed, 3 cancelled"
        decimal budget
        text description
    }
    STOP {
        bigint id PK
        bigint trip_id FK
        string name
        integer position
    }
    CHECKLIST_ITEM {
        bigint id PK
        bigint trip_id FK
        string title
        boolean done
    }
```

## Модели

**User** — пользователь приложения. Ему принадлежат поездки (`has_many :trips`).

**Trip** — поездка. Статусы: черновик, запланирована, завершена, отменена.
Методы бизнес-логики:

- `duration_days` — сколько дней длится поездка (включая первый и последний)
- `soon?` — запланированная поездка стартует в ближайшие 14 дней
- `progress_percent` — процент выполненных пунктов подготовки
- `complete` — завершить запланированную поездку
- `cancel` — отменить поездку (завершённую отменить нельзя)
- `restore_to_draft` — вернуть отменённую поездку в черновики

**Stop** — остановка маршрута. Новая остановка автоматически встаёт в конец списка, а после удаления номера остальных пересчитываются без пропусков.

**ChecklistItem** — пункт подготовки к поездке (билеты, отель, виза). Метод `toggle_done!` переключает отметку о выполнении.
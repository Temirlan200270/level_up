# Solo Leveling System

Геймифицированное приложение в духе «Поднятия уровня в одиночку»: профиль охотника, ежедневные квесты, инвентарь, магазин, дерево навыков и чат с «Системой» на базе внешних LLM.

## Возможности

- **Профиль охотника** — имя, уровень, опыт, распределение характеристик, статистика по квестам.
- **Квесты** — активные и завершённые; ежедневные задания с дедлайном; награды: опыт, очки статов (если заданы у квеста), случайный дроп (золото / предметы).
- **Инвентарь и экипировка** — слоты, расходники с эффектами (например, множитель опыта), продажа предметов.
- **Магазин** — покупка предметов за золото.
- **Навыки** — изучение за очки навыков, активные навыки с перезарядкой, прокачка уровней.
- **Настройки** — язык интерфейса (RU / EN), ключи и модели для нескольких AI-провайдеров, сброс прогресса.
- **Чат «Системы»** — ответы в стиле лора через выбранный API (требуется ключ в настройках).

## Стек технологий

| Область | Технология |
|--------|------------|
| UI | Flutter (Material 3), тёмная тема |
| Состояние | [flutter_riverpod](https://pub.dev/packages/flutter_riverpod) |
| Локальное хранение охотника / квестов / языка | [Hive](https://pub.dev/packages/hive) |
| Настройки AI (провайдер, модель, ключи) | [shared_preferences](https://pub.dev/packages/shared_preferences) |
| HTTP к LLM | [http](https://pub.dev/packages/http) |
| Локализация строк | JSON в `assets/translations/` + сервис переводов |
| Облако (опционально) | [supabase_flutter](https://pub.dev/packages/supabase_flutter) — аккаунт и таблица `game_backups` |

## Supabase (облако и аккаунты)

Проект в облаке можно создать вручную или через CI; схема в репозитории описана в **plan.md**. Минимум в БД:

- `public.profiles` — строка на пользователя (создаётся триггером после регистрации в Auth).
- `public.game_backups` — один JSON-снимок на пользователя (`payload` = тот же формат, что `DatabaseService.exportGameBackupJson()`).

Включена **RLS**: доступ только к своим строкам (`auth.uid()`).

### Сборка с облаком

Ключи не хранятся в коде. Передайте URL и **anon** (или publishable) ключ из [Supabase Dashboard](https://supabase.com/dashboard) → Project Settings → API:

```bash
flutter run \
  --dart-define=SUPABASE_URL=https://<project-ref>.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=<anon_or_publishable_key>
```

Без этих флагов приложение работает только локально (Hive + экспорт JSON). В **настройках** → «Облачная синхронизация»: регистрация/вход, выгрузка и восстановление бэкапа.

Если включено подтверждение email в Auth, после регистрации проверьте почту или отключите подтверждение в Dashboard для разработки.

## Требования

- Flutter SDK, совместимый с **Dart ^3.9.2** (см. `pubspec.yaml`).
- Для функций ИИ — действующий API-ключ выбранного провайдера (настраивается в приложении).

## Установка и запуск

```bash
# Клонировать репозиторий и перейти в каталог проекта
cd level_up

# Зависимости
flutter pub get

# Проверка анализатора (опционально)
flutter analyze

# Запуск на подключённом устройстве / эмуляторе
flutter run
```

Сборка релиза — стандартно для целевой платформы (`flutter build apk`, `flutter build ios` и т.д.).

### Android: ошибка установки Build-Tools 35

Плагины Flutter тянут **compileSdk 36**; Gradle иногда пытается скачать **build-tools;35.0.0** и падает на сети. В `android/app/build.gradle.kts` зафиксировано **`buildToolsVersion = "36.1.0"`** — используйте установленный набор инструментов 36.1.0.

Если папки `%LOCALAPPDATA%\Android\sdk\build-tools\36.1.0` нет:

1. **Android Studio** → *Settings* → *Languages & Frameworks* → *Android SDK* → вкладка **SDK Tools** → включите **Android SDK Build-Tools 36.1** (или актуальную 36.x) → *Apply*.
2. Или в терминале (путь к `sdkmanager` подстройте под свою установку cmdline-tools):

```bat
"%LOCALAPPDATA%\Android\Sdk\cmdline-tools\latest\bin\sdkmanager.bat" "build-tools;36.1.0" "platforms;android-36"
```

## Структура проекта

```
lib/
├── main.dart                 # Точка входа: Hive, переводы, ежедневные квесты, ProviderScope
└── src/
    ├── app.dart              # MaterialApp, локаль, нижняя навигация
    ├── core/                 # Тема, хелперы переводов
    ├── data/                 # Статические данные предметов и навыков
    ├── features/             # Экраны: охотник, квесты, инвентарь, магазин, навыки, настройки, чат
    ├── models/               # Hunter, Quest, Item, Skill, Stats, Buff, enum’ы
    └── services/             # DatabaseService, AIService, провайдеры Riverpod
assets/
└── translations/             # ru.json, en.json
```

## Локализация

- Язык по умолчанию при первом запуске задаётся в логике приложения (Hive `settings`, ключ `language`).
- Строки подгружаются из `assets/translations/*.json`. Смена языка в настройках обновляет провайдер языка и переводы без перекомпиляции ресурсов Flutter.

## Искусственный интеллект (чат и генерация)

- В **настройках** можно выбрать провайдера, модель и сохранить API-ключ (хранится локально через `SharedPreferences`).
- Поддерживаемые сценарии в коде: запросы к OpenAI-совместимым эндпоинтам, Gemini, OpenRouter, Hugging Face Inference, Anthropic Claude (см. `lib/src/services/ai_service.dart` и `ai_provider_model.dart`).
- Без ключа чат «Системы» показывает экран-подсказку перейти в настройки.

## Данные и сохранение

- **Охотник**, **квесты**, **язык интерфейса (Hive settings)** — в коробках Hive после `DatabaseService.init()` в `main.dart`.
- Сброс прогресса в настройках очищает охотника и квесты в Hive.

## Дорожная карта

Планы по фазам и актуальные чеклисты: [**plan.md**](plan.md).

## Версия

Согласно `pubspec.yaml`: **1.0.0+1**.

## Полезные ссылки

- [Документация Flutter](https://docs.flutter.dev/)
- [Riverpod](https://riverpod.dev/)

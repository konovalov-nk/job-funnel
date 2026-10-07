# OpenJobData mirror

Локальное зеркало [OpenJobData](https://openjobdata.com/) из публичного Hugging Face
bucket `Invicto69/Jobs-Dataset-bucket`.

## Что публикует источник

- `data/full/part-*.parquet`: текущий полный snapshot, включая `entire_json` и
  `job_model_json`.
- `data/minimal/part-*.parquet`: компактная проекция без двух тяжелых JSON-полей.
- `data/{full,minimal}/changes/YYYY-MM-DD.parquet`: новые и измененные вакансии,
  включая смену статуса на `closed`.
- `data/companies/companies.parquet`: справочник компаний.

Поле `jobs.id` является ключом для upsert. Сначала следует обновлять компании,
затем вакансии.

Источник заявляет ежедневное обновление, но не фиксирует время публикации.
Почасовых данных нет: timer только обнаруживает очередной daily-файл вскоре после
его появления. Bucket mutable и без истории версий, а в опубликованных daily
файлах уже наблюдались пропуски, поэтому утилита сохраняет manifest успешной
синхронизации и архивирует delta перед ее перезаписью upstream.

## Загрузка

Полный вариант (`full`, около 30 GiB с историческими delta):

```bash
make dry-run
make sync
```

Компактный вариант (`minimal`, около 0.6 GiB):

```bash
make sync-minimal
```

Весь bucket, то есть одновременно `full` и `minimal`:

```bash
make sync-all
```

Первый запуск создает `.venv` и устанавливает официальный `huggingface_hub`.
HF token не обязателен для публичного bucket. При необходимости более высоких
лимитов можно определить `HF_TOKEN` в окружении процесса.

Данные появятся в `data/openjobdata`, manifests в `state/openjobdata`. Утилита:

- не удаляет локальные файлы, исчезнувшие upstream;
- повторно скачивает измененные файлы по размеру/mtime через `hf sync`;
- сверяет source manifest до и после загрузки;
- проверяет наличие, размер и Parquet envelope каждого локального файла;
- не допускает одновременных запусков.

Пути можно изменить переменными `OPENJOBDATA_DATA_DIR` и
`OPENJOBDATA_STATE_DIR`, вариант по умолчанию переменной
`OPENJOBDATA_VARIANT=full`.

## SQL-запросы через DuckDB

DuckDB запускается официальным Docker-образом `duckdb/duckdb:1.5.5` в Compose
namespace `openjobdata`. Открыть интерактивную SQL-консоль:

```bash
make query
```

При запуске автоматически создаются views поверх актуальных Parquet:

- `jobs`: текущий snapshot вакансий;
- `companies`: компании;
- `job_changes`: исторические daily delta с колонкой `filename`.

Примеры запросов в консоли:

```sql
SELECT status, count(*) FROM jobs GROUP BY status;

SELECT j.title, c.name AS company, j.country, j.apply_url
FROM jobs j
LEFT JOIN companies c ON c.id = j.company_id
WHERE j.status = 'active' AND j.is_remote
LIMIT 50;
```

Выйти: `.quit`. Быстрый неинтерактивный пример:

```bash
make query-example
```

Compose монтирует исходные данные read-only. Постоянный каталог DuckDB находится
в `duckdb/` и не попадает в git. Snapshot `jobs` не нужно объединять с
`job_changes`: изменения нужны для upsert в отдельное материализованное
хранилище, а snapshot уже содержит актуальное состояние.

## Evidence dashboard

Запустить web-dashboard в том же Compose namespace `openjobdata`:

```bash
make evidence
```

Открыть http://localhost:3000. Dashboard показывает daily churn, концентрацию по
компаниям, пересечение потоков открытия/закрытия, возраст обнаруженных вакансий,
географию и крупнейшие компании. Evidence извлекает только агрегаты, не весь
`full` dataset.

После появления нового daily-файла обновить агрегаты dashboard:

```bash
make evidence-refresh
```

Логи и остановка:

```bash
make evidence-logs
make evidence-down
```

## Автообновление

Установить user-level systemd timer с polling раз в час:

```bash
make install-timer
make status
```

Логи:

```bash
make logs
```

Запустить обновление немедленно:

```bash
systemctl --user start openjobdata-sync.service
```

Чтобы timer работал после logout без активной пользовательской сессии, на
сервере может потребоваться один раз выполнить от root:

```bash
loginctl enable-linger "$USER"
```

## Ограничения источника

- Собственный scraper/normalization pipeline OpenJobData не опубликован.
- API `api.openjobdata.com` отдает статистику, а не сами вакансии.
- Нет SLA, гарантии непрерывности delta и schema compatibility policy.
- В metadata заявлена MIT, но отдельного `LICENSE` и ясного лицензирования
  текстов вакансий третьих сторон нет. Для перепубликации нужен legal review.
- Из-за возможных пропусков delta для production-БД нужен периодический rebuild
  или reconciliation с `part-*.parquet`: для `minimal` ежедневно/раз в несколько
  дней, для `full` еженедельно и при обнаружении gap.

Официальные ссылки:

- https://openjobdata.com/documentation
- https://huggingface.co/buckets/Invicto69/Jobs-Dataset-bucket
- https://huggingface.co/docs/huggingface_hub/main/en/guides/buckets

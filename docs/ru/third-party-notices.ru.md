# Уведомления о сторонних компонентах

Этот репозиторий содержит небольшой установочный скрипт и документацию. Он **не включает**, не копирует и не распространяет исходный код `libfprint`, `fprintd` или `libfprint-CS9711`.

Установщик скачивает и собирает на машине пользователя следующий upstream-проект:

- `ericlinagora/libfprint-CS9711`
  - URL: <https://github.com/ericlinagora/libfprint-CS9711>
  - протестированный commit: `c242a40fcc51aec5b57d877bdf3edfe8cb4883fd`
  - upstream license: GNU Lesser General Public License v2.1 (`LGPL-2.1`), унаследована от `libfprint`

Связанные upstream-проекты:

- `libfprint`: <https://gitlab.freedesktop.org/libfprint/libfprint>
- `fprintd`: <https://gitlab.freedesktop.org/libfprint/fprintd>

## Разделение лицензий

Файлы в этом репозитории лицензированы согласно файлу `LICENSE`.

Эта лицензия относится только к установщику и документации. Она **не перелицензирует** upstream `libfprint`, `fprintd` или fork `libfprint-CS9711`. Эти проекты остаются под своими лицензиями и copyright notices.

Когда установщик собирает и устанавливает `libfprint-CS9711`, итоговая библиотека регулируется условиями upstream LGPL-2.1. Перед использованием или распространением собранной библиотеки следует ознакомиться с upstream-лицензией.

## Нет распространения бинарников

Этот репозиторий не публикует готовые бинарники `libfprint-CS9711` или `libfprint`. Он только автоматизирует локальную сборку из зафиксированного upstream commit.

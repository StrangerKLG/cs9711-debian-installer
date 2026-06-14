# Благодарности и связанные проекты

Этот проект — небольшая обёртка-установщик и документация вокруг уже существующих open-source проектов для fingerprint.

## Основные upstream-проекты

- `libfprint`: <https://gitlab.freedesktop.org/libfprint/libfprint>
- `fprintd`: <https://gitlab.freedesktop.org/libfprint/fprintd>
- Community fork CS9711, который использует установщик: <https://github.com/ericlinagora/libfprint-CS9711>
  - протестированный commit: `c242a40fcc51aec5b57d877bdf3edfe8cb4883fd`

## Проверенное устройство

Сканер, на котором проводился тест, был куплен здесь:

- <https://www.ozon.ru/product/usb-skaner-otpechatkov-paltsev-windows-hello-dl-ya-pk-noutbuka-chernoe-1410552111/>

Это **не реклама и не партнёрская рекомендация**. Ссылка нужна только для указания точного устройства, которое было куплено и проверено.

## Ссылки на документацию

- ArchWiki fprint: <https://wiki.archlinux.org/title/Fprint>
- Debian PAM documentation: <https://wiki.debian.org/PAM>

## AI disclosure

Скрипт установки и документация в этом репозитории были подготовлены AI-агентом под руководством и проверкой человека, на основе ручных логов тестирования и проверенной установки Debian 13.

AI-агент не создавал драйвер отпечатка. Поддержка CS9711 взята из community fork, указанного выше. Этот проект только автоматизирует и документирует проверенный процесс установки.

Перед запуском прочитайте скрипт. Он меняет системные библиотеки, udev-правила и, опционально, PAM-конфигурацию.

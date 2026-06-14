# Проверка в чистой Debian 13 VM

Эта инструкция — для теста установщика в чистой VM Debian 13.

## 1. Установить Debian 13 в VirtualBox

Рекомендуемые настройки VM:

- OS: Debian 64-bit
- RAM: 2–4 GB
- CPU: 2 cores
- Disk: 25+ GB
- USB Controller: USB 3.0/xHCI
- USB filter для сканера:

```text
Vendor ID: 2541
Product ID: 0236
Name: Chipsailing CS9711Fingprint
```

Для стабильной картинки в VirtualBox/KDE:

```text
Graphics: VMSVGA
Video memory: 128 MB
3D acceleration: off
```

Если нужна текстовая загрузка:

```text
GRUB_CMDLINE_LINUX_DEFAULT="quiet nomodeset"
GRUB_TERMINAL=console
GRUB_GFXPAYLOAD_LINUX=text
```

Затем:

```bash
sudo update-grub
sudo reboot
```


## 1.1 Подключить USB-сканер к запущенной VM

Для теста в VirtualBox недостаточно просто вставить сканер в USB основной системы. Его нужно пробросить в виртуальную машину:

```text
Окно VirtualBox VM → Устройства → USB → Chipsailing CS9711Fingprint
```

или выбрать устройство с USB ID `2541:0236`.

Пункт меню должен стать отмеченным галочкой. После этого проверьте внутри VM:

```bash
lsusb
```

Ожидаемый результат: одна из строк содержит `2541:0236`.

На реальной физической Linux-машине этот шаг пропускается полностью: там нет проброса USB через VirtualBox, сканер просто должен быть вставлен в USB.

## 2. Скачать проект

```bash
git clone https://github.com/StrangerKLG/cs9711-debian-installer.git
cd cs9711-debian-installer
```

## 3. Драйвер + запись пальца + проверка

```bash
sudo ./install.sh --user "$USER" --driver-only --enroll --verify --yes
```

Во время `enroll` прикладывайте один и тот же палец несколько раз, слегка меняя положение.

Нужный результат:

```text
verify-match
```

Если получили `verify-no-match`, повторите запись пальца.

## 4. Включить sudo по отпечатку

```bash
sudo ./install.sh --user "$USER" --no-driver --sudo --yes
```

Проверка:

```bash
sudo -k && sudo true
```

Ожидаемое поведение: `sudo` просит приложить палец. Если отпечаток не сработал или истёк timeout, пароль остаётся fallback-вариантом.

## 5. Включить SDDM и Polkit

Для KDE/SDDM VM:

```bash
sudo ./install.sh --user "$USER" --no-driver --sddm --polkit --yes
```

Проверки:

- SDDM: выйти из сессии → нажать Enter в поле пароля → приложить палец.
- KDE/Polkit: открыть административное действие, дождаться окна “Требуется аутентификация” → приложить палец.

## 6. Что не проверяем

Не включайте глобальный `common-auth`. Скрипт специально не делает этого.

KDE lockscreen и KDE Wallet намеренно не включаются на отпечаток.


## Troubleshooting: команда превратилась в `truesudo`

Если терминал пишет:

```text
sudo: truesudo: команда не найдена
```

значит PDF-просмотрщик или буфер обмена склеил две строки в одну. Проверку `sudo` нужно запустить одной явной строкой:

```bash
sudo -k && sudo true
```

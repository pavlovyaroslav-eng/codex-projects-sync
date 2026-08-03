FLSUN V400 — финальная конфигурация и резервная копия
Дата: 2026-07-17

ФИНАЛЬНЫЕ НАСТРОЙКИ KLIPPER
- max_velocity: 400 mm/s
- max_accel: 8000 mm/s^2
- max_accel_to_decel: 5000 mm/s^2
- square_corner_velocity: 5 mm/s
- max_z_velocity: 100 mm/s
- max_z_accel: 1500 mm/s^2
- Pressure Advance: 0.020
- Сохранённый Z-offset: -0.91 mm
- Активный профиль поверхности: default (7x7)
- TMC A/B/C: run_current 1.5 A, SpreadCycle
- PRINT_START: LED_ON, восстановление лимитов, G28, загрузка mesh default
- PRINT_END: отключение нагрева и вентилятора, восстановление лимитов, G28

ФИНАЛЬНЫЙ ПРОФИЛЬ ORCASLICER
- Принтер: V400
- Процесс: 0.16mm PETG Quality Small Details V400 USER
- Филамент: PETG Quality Small Details V400 USER
- Максимальный объёмный расход: 11 mm^3/s
- Сопло: 230 C, включая первый слой
- Стол: 80 C, включая первый слой
- Максимальный обдув: 25%
- Скорости: outer 100, inner 150, infill 160, travel 350 mm/s
- Ускорения: default 3500, outer 2000, travel 7000 mm/s^2

ПРОФИЛЬ PETG-CF
- Имя: PETG-CF V400 USER
- Тип: PETG-CF
- Сопло: 245 C, допустимый диапазон 230-270 C
- Стол: 80 C, включая первый слой
- Начальный максимальный объёмный расход: 8 mm^3/s
- Коэффициент потока: 0.95
- Обдув: 0-30%, нависания до 40%
- Требование: износостойкое сопло HRC 40 или выше

АРХИВЫ
1. FLSUN_V400_COMPLETE_BACKUP_20260717_FINAL.tar.gz
   Содержит Klipper printer_1, Moonraker, savedVariables1.cfg,
   printer_data_1 и systemd units klipper-1/moonraker-1.
   SHA256: 449587c3ccaf222a86274bec342e1320e80e985854a907a24a605c4e2c99faf1

2. OrcaSlicer_USER_PROFILES_20260717_FINAL_WITH_PETG_CF.zip
   Содержит OrcaSlicer/user/default со всеми пользовательскими профилями,
   включая PETG-CF V400 USER.
   SHA256: 97561e13806e0a807f7ccb5ef20d958ebe2d8ef541411d922853c2b6fbb96148

Копия архива принтера также оставлена на Speeder Pad:
/home/pi/printer_data/gcodes/backups/FLSUN_V400_COMPLETE_BACKUP_20260717_FINAL.tar.gz

Перед восстановлением остановить соответствующие сервисы и сделать свежую
копию текущих файлов. Не заменять конфигурацию работающего принтера вслепую.

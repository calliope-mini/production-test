## Requirements
- Raspberry Pi 3b
- Raspberry Pi OS 32bit,
- JLink Arm 32bit  https://www.segger.com/downloads/jlink/JLink_Linux_arm.tgz, tried with version 7.88k

## Description
This folder contains a tool for headless production programming of Calliope mini 3. It consists of 1 shell script, 1 service and several JLink Commandfiles. The service runs the infinite-loop script, which executes the following steps: 
1. Wait for VTarget of JLink programming adapter (VTarget higher than 2V means the programming adapter is connected)
2. Recover NRF52820 device (remove Access Port Protection)
3. Flash DAPLink Firmware to NRF52820
4. Wait until Calliope mini 3 is mounted in OS via VFS
5. Copy NRF52833 firmware
6. Light up green ACT led 
7. Wait for tests to be done and disconnection of Calliope mini 3

## Raspberry Pi Preparation Steps:
- create Raspberry Pi OS 32bit (port of debian bullseye, 2023-05-03) with user "pi", choose password, internet connection not necessary
- install ARM 32bit JLINK https://www.segger.com/downloads/jlink/JLink_Linux_arm.deb with sudo apt install JLinkXXX.deb
- get control of ACT led in /boot/config.txt by adding to the bottom:
dtparam=act_led_trigger=none
dtparam=act_led_activelow=off
- clone this repo
- copy service to systemd with sudo cp prodprog.service /lib/systemd/system/
- reload services with sudo systemctl daemon-reload
- enable service with sudo systemctl enable prodprog.service
- start service with sudo systemctl start prodprog.service
- disable automounting of removable media in file browser -> edit -> preferences 

## Exchange firmware files: 
- DAPLink USB Firmware (NRF52820): modify flash.jlink
- Application Demo Firmware (NRF52833): modify prodprog.sh

## Hardware Setup
### JLink 20p JTAG Connector -> mini3: 
-  1 VTref -> mini3 3V Edge
-  7 TMS -> mini3 SWDIO NRF52820 testpoint
-  9 TCK -> mini3 SWDCLK NRF52820 testpoint
- 19 5V  -> mini3 5V USB testpoint
- 20 GND -> mini3 GND Edge
### RPI USB A  -> mini3:
- USB D+ -> mini3 USB D+ testpoint
- USB D- -> mini3 USB D- testpoint

## Monitoring
- systemctl status prodprog.service
  - To check if service is started
- journalctl -f -u prodprog.service
  - To see console output of service
- prodprog.log contains minimal logging info of production-programming
- recover.log contains info of last NRF52820 recovery
- flash.log contains info of last NRF52820 flashing task

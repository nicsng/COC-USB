# COC-USB
Maintaining the chain of custody for digital evidence is a critical challenge in forensic investigations, particularly in ensuring the confidentiality, integrity, and availability of the evidence. This research aims to present a proof of concept demonstrating that a disk storage device can accurately track its usage while preserving the confidentiality of sensitive information, maintaining the integrity of the evidence, and ensuring its availability for analysis. The proposed solution seeks to strengthen the reliability and security of digital forensic processes.

# Prerequisites
## Hardware
Raspberry Pi (tested on Raspberry Pi Zero 2W)

## Software
Raspberry Pi OS
Python 3.11 or higher

# Setup
## Method 1
1. Clone the Repository
```
git clone https://github.com/nicsng/COC-USB.git
cd COC-USB
```

2. Set Up the Virtual Environment:
```
python3 -m venv websocket-env
source websocket-env/bin/activate
```

3. Install Dependencies
```
pip install -r requirements.txt
```

4. Copy files from the repo into their respective folders
   Windows
```
sudo cp windows/composite_usb /usr/bin/composite_usb
sudo cp windows/ctf_gadget.service /etc/systemd/system/
sudo cp windows/ctf_gadget2.service /etc/systemd/system/
```

Linux
```
sudo cp linux/composite_usb /usr/bin/composite_usb
sudo cp linux/ctf_gadget.service /etc/systemd/system/
sudo cp linux/ctf_gadget2.service /etc/systemd/system/
```

## Method 2: Raspberry Pi Imager
1. [Download Raspberry Pi Imager.](https://www.raspberrypi.com/software/)

2. Select Your Hardware
Choose Raspberry Pi Zero 2W.

3. Download the Operating System you are targeting
For Windows or Linux, select "Custom OS" and download the required OS. <br>[Windows](https://github.com/nicsng/COC-USB/releases/tag/Windows) | 
[Linux](https://github.com/nicsng/COC-USB/releases/tag/Linux)

5. Select Your microSD Card
Insert and choose the correct microSD card.

6. Flash the OS
Flash the downloaded OS image to the microSD card.

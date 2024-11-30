# COC-USB
A innovative way to maintain integrity for Chain of Custody  

# Prerequisites
## Hardware
Raspberry Pi (tested on Raspberry Pi Zero 2W)

## Software
Raspberry Pi OS
Python 3.11 or higher

# Installation
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
   cp windows/composite_usb /usr/bin/composite_usb
   cp windows/ctf_gadget.server -> /etc/systemd/system/
   cp windows/ctf_gadget2.server -> /etc/systemd/system/   
   ```
   
   Linux
   ```
   cp linux/composite_usb -> /usr/bin/composite_usb
   cp linux/ctf_gadget.server -> /etc/systemd/system/
   cp linux/ctf_gadget2.server -> /etc/systemd/system/
   ```

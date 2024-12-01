
# COC-USB
Maintaining the chain of custody for digital evidence is a critical challenge in forensic investigations, 
particularly in ensuring the confidentiality, integrity, and availability of the evidence. This research aims 
to present a proof of concept demonstrating that a disk storage device can accurately track its usage while 
preserving the confidentiality of sensitive information, maintaining the integrity of the evidence, and 
ensuring its availability for analysis. The proposed solution seeks to strengthen the reliability and security 
of digital forensic processes.

# Prerequisites
## Hardware
Raspberry Pi (tested on Raspberry Pi Zero 2W)

## Software
Raspberry Pi OS
Python 3.11 or higher

# Setup
## Method 1: Build from scratch
### Step 1: Prepare the Raspberry Pi
1. Download [Raspberry Pi Imager](https://www.raspberrypi.com/software/).
2. Select your Hardware: Choose ```Raspberry Pi Zero 2W```
3. Select OS: Choose ```Raspberry Pi OS (64-bit)```
4. Select your MicroSD Card:
- Ensure a minimum of 32GB capacity
5. In Advanced Options, Enable SSH and connect it to a hotspot or home network. Set a username and password.
5. Flash the Image to your microSD card and insert it into the Pi.

### Step 2: SSH into the pi 
1. Boot the Raspberry Pi and identify its IP address through your router or hotspot settings.
```
ssh pi@<ip_address>
```

### Step 3: Update the System
```
sudo apt update -y && sudo apt dist-upgrade -y && sudo apt upgrade -y && sudo apt full-upgrade -y && sudo apt autoremove -y
```

### Step 4: Install prerequisites
1. Install Required Dependencies for the project:
   ```
   sudo apt install python3 python3-venv isc-dhcp-server -y
   ```

### Step 5: Modify System Configuration<br>
#### Step 5.1: Configure ```/boot/firmware/config.txt```
1. Edit the file:
```
sudo nano /boot/firmware/config.txt
```
2. Update the following:
```
max_framebuffer=2
dtoverlay=dwc2
```

#### Step 5.2: Configure ```/etc/modules-load.d/modules.conf```
1. Edit the file:
```
sudo nano /etc/modules-load.d/modules.conf
```
2. Add the following:
```
i2c-dev
dwc2
libcomposite
```
3. Reboot the Raspberry Pi:
```
sudo reboot
```

### Step 6: Setup USB Composite Gadget
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
sudo cp windows/ctf_gadget.service /etc/systemd/system/ctf_gadget.service
sudo cp windows/ctf_gadget2.service /etc/systemd/system/ctf_gadget2.service
```

Linux
```
sudo cp linux/composite_usb /usr/bin/composite_usb
sudo cp linux/ctf_gadget.service /etc/systemd/system/ctf_gadget.service
sudo cp linux/ctf_gadget2.service /etc/systemd/system/ctf_gadget2.service
```

5. Configure ```rc.local```
1. Edit ```/etc/rc.local```
```
sudo nano /etc/rc.local
```
2. Add the following before ```Exit 0```
```
/usr/bin/composite_usb
```

### Step 8: Configure DHCP
1. Edit /etc/dhcp/dhcpd.conf:
```
sudo nano /etc/dhcp/dhcpd.conf
```
2. Add:
```
subnet 10.0.0.0 netmask 255.255.255.0 {
  range 10.0.0.2 10.0.0.10;
  option routers 10.0.0.1;
}
```
3. Edit ```/etc/default/isc-dhcp-server```
```
sudo nano /etc/default/isc-dhcp-server
```
4. Update:
```
INTERFACESv4="usb0"
```
5. Restart DHCP Server:
```
sudo systemctl restart isc-dhcp-server.service
```

### Step 9: Set Up the USB Disk Image
Step 9.1: Create and Format the Image
1. Create the CTF_Gadget directory:
```
mkdir /home/pi/CTF_Gadget/
```
2. Create the disk image file:
```
sudo dd if=/dev/zero of=/home/pi/CTF_Gadget/usbdisk.img bs=1M count=3072
```
3. Attach the image as a loop device:
```
sudo losetup -fP /home/pi/CTF_Gadget/usbdisk.img
```
4. Format the image as FAT32:
```
sudo mkfs.vfat -F 32 /dev/loop0
```
5. Detach the loop device:
```
sudo losetup -d /dev/loop0
```

### **Step 10: Final Steps**
1. Reboot the Raspberry Pi:
   ```bash
   sudo reboot
   ```

2. Test the gadget functionality by connecting the Pi to a host device and ensuring it operates as intended.


## Method 2: Flashing Pre-made Image
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

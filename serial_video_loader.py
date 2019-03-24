"""Video script.

Script for loading and sending videos through serial port.

Run using the -i flag to start a python interactive session after running the
script

    $ python -i serial_video_loader.py

Juan Escarate - UTFSM
"""
import cv2
import serial
import sys
import argparse
import numpy as np

DEFAULT_IMAGE_SIZE = (512, 384)
DEFAULT_FRAMES_TO_SHOW = 200

# Parse command line arguments. At least a serial port name is needed
parser = argparse.ArgumentParser(
    description='Send and validate commands over serial port.')

parser.add_argument('img', nargs='?', default=None, help='image to load')
parser.add_argument('-b', default=4000000, type=int, help='baudrate')
parser.add_argument('-t', nargs=1, default=1, type=float, help='timeout')
parser.add_argument('-p', choices=['O', 'E', 'N'], default='N', help='parity')

args = parser.parse_args(sys.argv[1:])

# Create and open the serial port
serial_port = serial.Serial()
serial_port.baudrate = args.b
serial_port.timeout = args.t
serial_port.parity = args.p

# Open a serial port
def open_COM(COM):
    serial_port.port = COM
    serial_port.open()

# Function to extract frames 
def FrameCapture(path_file, COM, size = DEFAULT_IMAGE_SIZE, frames_to_show = DEFAULT_FRAMES_TO_SHOW): 
    # Limit the frames to show to 227 because of the size of the DDR2
    if (frames_to_show > DEFAULT_FRAMES_TO_SHOW):
        frames_to_show = DEFAULT_FRAMES_TO_SHOW
    
    # Call the function to open the serial port 'COM'
    open_COM(COM)
    
    # Path to video file
    video = cv2.VideoCapture(path_file)

    # Used as counter variable 
    count = 0
  
    # Extract the video and resize 
    success, image = video.read()
    while success: 
        # video object calls read 
        # function extract frames 
        success, image = video.read()
        resize = cv2.resize(image, size, interpolation = cv2.INTER_LINEAR)
        rgb = np.array(resize[...,::-1])
        rgb = rgb.ravel()
        frame = bytearray(rgb)
        
        # Send through serial port the frames
        serial_port.write(frame)

        # Repeat to send the frames we choose 
        count += 1
        if(count == frames_to_show):
            break

        # To finish the while loop press the 'ESC' key
        if cv2.waitKey(10) == 27:                     
            break

    serial_port.close()
        
    print("File sent!")
 
    
 

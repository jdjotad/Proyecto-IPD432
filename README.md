# Video filters in Nexys 4 DDR
This project is a Systemverilog version of a video processor implemented in a Nexys 4 DDR which contains 4 simple filters like dithering, colour scramble, grayscale and the original view. 


[![Github Issues](http://githubbadges.herokuapp.com/badges/badgerbadgerbadger/issues.svg?style=flat-square)](https://github.com/jdjotad/Proyecto-IPD432/issues) [![Pending Pull-Requests](http://githubbadges.herokuapp.com/badges/badgerbadgerbadger/pulls.svg?style=flat-square)](https://github.com/jdjotad/Proyecto-IPD432/pulls)


## Requirements
This project was made to test a Nexys 4 DDR so you will need Vivado from Xilinx. We provide a python code to send through serial port a video up to 200 frames (limited by the script) and to run that python script you will need the next packages:
- ![Opencv](https://pypi.org/project/opencv-python/)
- ![Pyserial](https://github.com/pyserial/pyserial)
- ![Numpy](https://pypi.org/project/numpy/#description)

### IP SETUPS

**MIG**

![Recordit GIF](https://github.com/jdjotad/Proyecto-IPD432/blob/master/video_mig.gif)

**CLOCK WIZARD**

**FIFO**

**BRAM**


## Features
We approached this repo ![DDR RAM Controller](https://github.com/alonsorb/ddr-ram-controller-mig) with a high performance DDR controller to save a piece of video in the DDR2 SRAM of the Nexys 4 DDR and show a it in a screen with VGA port. The fpga show a resolution of 1024x768 pixels by our especifications, at a 78.8[MHz] clock. 

The uart was configurated with an input clock of 100[MHz] and a baud rate of 4M of baud rate (if you change this in the code remember to change it in the python script).

The code provided as a DDR controller let us save up to 128 bits per address but we send the pixels in RGB and 8 bits per colour so we saved 5 pixels by address, equivalent to 120 of 128 bits, losing 8 bits per address. To be sure of the address of reading we didn't approach the throughput gave by the DDR controller because just when the data from the DDR is valid we enable the reading of the DDR.

Because of the quantity of BRAM we can use the resolution we used to save a frame is 512x384, to keep the aspect ratio and is easier to reach a 1024x768 frame. To show a 1024x768 frame, each pixel should be shown 4 times or equally in a 2x2 square.


## Usage of python script
After installing the [Requirements](#requirements) packages you should call the next function in python IDLE 
```shell
>> FrameCapture(path_file, COM, size, frames_to_show)
```
If you want to use terminal or command prompt
```shell
$ python -i serial_video_loader.py
>> FrameCapture(path_file, COM, size, frames_to_show)
```

|Input Name|Description|Examples|
|:------------:|:---------:|:-------------:|
|path_file|Path where the video is saved|"/home/jotad/Desktop/corto.mkv"<br>"corto.mkv" (if the video file is in the same folder of the script)|
|COM|Serial port where the fpga is connected|"COM4"<br>"/dev/ttyUSB1"|
|size|Resolution to resize the original video. The default value is 512x384. We recommend to not change this value.|(512,384)<br>(1024,768)|
|frames_to_show|The quantity of frames to send through the serial port to save in the DDR. After testing (not exhaustively so you can update it) we limited this value to 200 frames, if you put any value higher than 200 it will send 200 frames|10<br>150|

We provide the next example running the scrpt with python IDLE in Ubuntu:
```shell
>> FrameCapture('corto_original.mkv', '/dev/ttyUSB1', frames_to_show = 200)
```
And running in terminal
```shell
$ cd Desktop
$ python -i serial_video_loader.py
>> FrameCapture('corto_original.mkv', '/dev/ttyUSB1', frames_to_show = 200)
```
## Future features

---

## Contributing

> To get started...

### Step 1

- **Option 1**
    - Fork this repo!

- **Option 2**
    - Clone this repo to your local machine using `https://github.com/jdjotad/Proyecto-IPD432.git`
    - Make changes to the project approaching some features we could not finish (read at [Future features](#future-features))
    - Try adding video filters and create for a pull request (look for step 2)
    

### Step 2

- 🔃 Create a new pull request using <a href="https://github.com/jdjotad/Proyecto-IPD432/compare" target="_blank">`https://github.com/jdjotad/Proyecto-IPD432/compare`</a>.

---

## Team


| <a href="https://github.com/jdjotad" target="_blank">**Juan Escarate's repo**</a> | <a href="https://github.com/Carlosfhz" target="_blank">**Carlos Fernandez's repo**</a> | 
| :---: |:---:|
| [![Juan Escárate](https://github.com/github.png?size=40)](https://github.com/jdjotad)    | [![Carlos Fernández](https://github.com/github.png?size=40)](https://github.com/Carlosfhz) |
| <a href="https://github.com/jdjotad" target="_blank">`github.com/jdjotad`</a> | <a href="https://github.com/Carlosfhz" target="_blank">`github.com/Carlosfhz`</a> |


---

## FAQ

- **How to implement this project?**
    - You just need to create a new project and add all the design, ip and constraints sources. Then select the fpga model of Nexys 4 DDR (xc7a100tcsg324-1 in our case) and write the bitstream. Then program the fpga and run the python script to send the video to the fpga, remember to connect the VGA port.
- **Why I can't edit the ip cores?**
    - We created the ip cores in Vivado 2018.3 and it can change between Vivado versions so if you can't re-customize just create it from 'IP Catalog' and configure with your own specifications.

---

## Support

If you have any question reach us by these mails

- Juan Escárate - juan.escarate@sansano.usm.cl
- Carlos Fernández - carlos.fernandezh@sansano.usm.cl

---

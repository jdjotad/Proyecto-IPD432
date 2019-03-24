# Video filters in Nexys 4 DDR
This project is a Systemverilog version of a video processor implemented in a Nexys 4 DDR which contains 4 simple filters like dithering, colour scramble, grayscale and the original view. 


[![Build Status](http://img.shields.io/travis/badges/badgerbadgerbadger.svg?style=flat-square)](https://travis-ci.org/badges/badgerbadgerbadger) [![Dependency Status](http://img.shields.io/gemnasium/badges/badgerbadgerbadger.svg?style=flat-square)](https://gemnasium.com/badges/badgerbadgerbadger) [![Coverage Status](http://img.shields.io/coveralls/badges/badgerbadgerbadger.svg?style=flat-square)](https://coveralls.io/r/badges/badgerbadgerbadger) [![Code Climate](http://img.shields.io/codeclimate/github/badges/badgerbadgerbadger.svg?style=flat-square)](https://codeclimate.com/github/badges/badgerbadgerbadger) [![Github Issues](http://githubbadges.herokuapp.com/badges/badgerbadgerbadger/issues.svg?style=flat-square)](https://github.com/jdjotad/Proyecto-IPD432/issues) [![Pending Pull-Requests](http://githubbadges.herokuapp.com/badges/badgerbadgerbadger/pulls.svg?style=flat-square)](https://github.com/jdjotad/Proyecto-IPD432/pulls) [![Gem Version](http://img.shields.io/gem/v/badgerbadgerbadger.svg?style=flat-square)](https://rubygems.org/gems/badgerbadgerbadger) [![License](http://img.shields.io/:license-mit-blue.svg?style=flat-square)](http://badges.mit-license.org) [![Badges](http://img.shields.io/:badges-9/9-ff6799.svg?style=flat-square)](https://github.com/badges/badgerbadgerbadger)


## Requirements
This project was made to test a Nexys 4 DDR so you will need Vivado from Xilinx. We provide a python code to send through serial port a video up to 200 frames (limited by the script) and to run that python script you will need the next packages:
- ![Opencv](https://pypi.org/project/opencv-python/)
- ![Pyserial](https://github.com/pyserial/pyserial)
- ![Numpy](https://pypi.org/project/numpy/#description)

### IP SETUPS

**MIG**

![Recordit GIF](https://github.com/jdjotad/Proyecto-IPD432/blob/master/video_mig.gif)


## Features
We approached this code ![DDR RAM Controller](https://github.com/alonsorb/ddr-ram-controller-mig) to save a piece of video in the DDR2 SRAM of the Nexys 4 DDR and show a it in a screen with VGA port. The fpga is capable to show a resolution of 1024x768 pixels, by our especifications at a 78.8[MHz] clock. 
The code provided as a DDR controller let us save up to 128 bits per address but we send the pixels in RGB and 8 bits per colour so we saved 5 pixels by address, equivalent to 120 of 128 bits losing 8 bits per address.
## Usage

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

> Or Contributors/People

| <a href="https://github.com/jdjotad" target="_blank">**Juan Escarate's repo**</a> | <a href="https://github.com/Carlosfhz" target="_blank">**Carlos Fernandez's repo**</a> | 
| :---: |:---:|
| [![Juan Escárate](https://github.com/github.png?size=40)](https://github.com/jdjotad)    | [![Carlos Fernández](https://github.com/github.png?size=40)](https://github.com/Carlosfhz) |
| <a href="https://github.com/jdjotad" target="_blank">`github.com/jdjotad`</a> | <a href="https://github.com/Carlosfhz" target="_blank">`github.com/Carlosfhz`</a> |


---

## FAQ

- **How do I do *specifically* so and so?**
    - No problem! Just do this.

---

## Support

If you have any question reach us by these mails

- Juan Escárate - juan.escarate@sansano.usm.cl
- Carlos Fernández - carlos.fernandezh@sansano.usm.cl

---

* System overview
  * BeagleBone Rev A6

* Build environment
  * ubuntu 14.04 64bits
  	$ cd tool && tar -jxvf arm-2014.05-29-arm-none-linux-gnueabi-i686-pc-linux-gnu.tar.bz2
  	# setup runtime for the 32bits toolchain
    $ sudo dpkg --add-architecture i386
    $ sudo apt-get install gcc-multilib g++-multilib

* Build
  * make dist

* Install
  * copy dist/* to SD card boot partition in root directory

* Check dependent shared library for a <application> 
  * objdump -p <application> | grep NEEDED

* Directory tree:
  * proj.mk
  * Makefile
      project scope Makefile
  * prebuilt/
      prebuilt files, copy to final system image
  * package/
      software packages
  * tool/
    * toolchain/
        Sourcery CodeBench Lite for Arm GNU/Linux Release
  * dist/
    * distributed files

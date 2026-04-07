### A HUGE SHOUTOUT to the people and organisations who made this project possible:
1) [FaresMQA](https://github.com/FaresMQA/), for the [dotfiles](https://github.com/FaresMQA/manjaro-hyprland).
2) [Noa Himesaka](https://github.com/NoaHimesaka1873/),  one who maintained the project for a whole year.
3) [The Manjaro Team, of course](https://manjaro.org)
4) [Jetbrains](https://github.com/jetbrains) for their IDEs
5) And who could forget [ChatGPT](https://chatgpt.com) which did help me find all the alternatives for obsolete packages
# Prerequisites
1) A 4 GB stick
2) A macOS or a Linux system preferably (Windows may work as well)
3) 10 GB of free space
4) A basic understanding how computers
Optional: basic bash scripting knowledge.

Note: I do not use Windows, so I cannot garuntee that it works.
# Downloading and creating the ISO
For each edition, there will be 2 files to download. the filenames ending with `.z01` and `.zip`. You will need to download both. The files starting with `sha` are files that contain encrypted keys to verify the integrity. Its often best to download and test the ISO, but if you're okay with taking a small risk you can skip it.

To create the ISO you would have to perform based on the operating system:\
### Windows:
Before we start, let's turn on File extensions. In File Explorer go to View tab, 
Open Command Prompt as Administrator and type the following
```cmd
copy /B manjaro-*.z* manjaro.iso.zip
```
After the command finished, you can now unzip the ISO normally in File Explorer and you can delete the `manjaro.iso.zip` file. Keep the `.z01` and the other `.zip` for backup. You can skip to Flashing to your USB Stick.

### macOS, Linux, and *nix systems:
Open Terminal (Or Console on some Linux Systems) and do and type `cat`. Then open you open your file browser and drag the `.z01` file into the terminal.Then press the spacebar and then repeat for the `.zip` file. Then type `> manjaro .iso.zip`, and press Enter.
```bash
cat manjaro-xfce-26.04-t2-260407-linux618-t2.iso.z01 manjaro-xfce-26.04-t2-260407-linux618-t2.iso.zip > manjaro.iso.zip
```
Now unzip the file like normal and you you are ready to move on the next step.

# Flashing the USB 
### Windows:
Download the [rufus](https://github.com/pbatard/rufus/releases/download/v4.12/rufus-4.12.exe) utility, which helps copying the contents of the ISO. Do not do this manually.
<img width="472" height="569" alt="image" src="https://github.com/user-attachments/assets/00e14e9f-7277-44bb-9ee2-c4ca685f7fe2" />

Under the device menu, select your device. Please be sure that it is your USB stick. 

Select the ISO using the "Select" button and click OK. There will be a popup saying that you have to use in ISO/Hybrid Mode, you SHOULD click OK. If not restart the application and select the ISO and the device again. 
You can leave the rest as default. If you wish, you can set the allocation size to 1024 for the best read/write speed

## macOS, Linux, *nix based OSes
Now this is the tricky part. In macOS(Or any other unix system), open the disk utility. You should se under "disk identifier", that you should see `disk0`,`disk1`, or `disk2` followed by `s1` or `s2`,etc. We only need the `disk0` or whatever is listed in that text box. If it's mentioned `disk0`, then your USB file is located at `/dev/disk0`, and etc for `disk1`,`disk2`, etc

On Linux you can use your disk utility manager, but it is easier to use the command line. Type `lsblk` and you should see a list of your drives. You can locate it using the sizes given, and use it to match the USB size on the drive. It should be having `sda` or `sdb`, etc. Ignore the ones followed by a number at the end, as that is your partitions. So assuming that your device is recognised as `sda`, your device file is `/dev/sda`.

Now why is that important? Well all unix based systems recognise files as a file, and that's how it works. Now let's use `dd` to flash the image to the drive. Type `sudo dd if=`. Open your File Manager, drag and drop your ISO in the terminal. Then press Space, then type `if=`, and then type the device file(no spaces).
Assuming that your device `/dev/sda` or `/dev/disk1`
```
sudo dd if=manjaro.iso of=/dev/sda status=progress
```
Note that input file and output file(`if` and `of`) can differ, so don't copy this command blindly. Note that all the contents of the drive will be erased, so backup the data if required. Now you can press enter to start writing to the disk. Let it finish copying the data to the disk, this will take atleast 15-30 mins, depending on the speed of the drive.
# TLDR
Haha, got you. Unless you're a tech savvy guy, you'll have to read the documentation to understand how to create a USB drive. This is essential for your linux journey. Don't worry, it isn't that complicated once you learn it.
(*nix based systems only)
Assuming your drive is `/dev/sda` and your chosen OS is 26.04 T-2 XFCE,
```sh
cd ~/Downloads
cat manjaro-xfce-26.04-t2-260407-linux618-t2.iso.z01 manjaro-xfce-26.04-t2-260407-linux618-t2.iso.zip > manjaro.iso.zip # The split archive may differ
unzip manjaro.iso.zip
sudo dd if=manjaro-xfce-26.04-t2-260407-linux618-t2.iso of=/dev/sda bs=1M status=progress
```
Don't remove `status=progress` unless you want to stare at a blank terminal.

# Note for the tech savvy
1) This "Get started" page is written for everyone, even for the "I just want a working computer" guy
2) Do not use balena Etcher. In my experience, its known to break the ISOs from my end. The classic Rufus in DD mode does the same effect. On Linux/*nix based systems (Including macOS) the classic terminal is enough. *Use Balena Etcher at your own risk*
# Final note
You have now successfully have  created a Installation Media, you can now refer to the [t2linux.org](https://t2linux.org) for question. Note that this is no longer endorsed by the Linux T2 community, so please contact me through Github Discussions. This project is a fork of a discontinued Manjaro Watanare, a T2 Linux Operating system. It is currently maintained as a ameutur project.


![20250823_010835](https://github.com/user-attachments/assets/8688cacf-d952-409d-94af-bc1824356b18)

# <ins>Move Anything (previously Move Control Surface)</ins>

## What is this project?
Move Anything is a framework that lets you write your own code for the Ableton Move. It gives you access to:
* The pads (note number, velocity, and polyphonic aftertouch values)
* The 9 endless encoders with relative and absolute values available
* Capacitive touch messages.
* All buttons.
* Setting the colors of everything that can have a color set.
* Display as a 128x64 1 bit framebuffer (it's just balck and white);
* Audio from the line-in and mic
* Audio out through the speakers and line out
* MIDI in/out via the USB-A port. You can also connect multiple USB-MIDI devices to the USB-A port using a hub and receive and send MIDI to all of them.
* Move Anything is non-destructive and lives alongside the regular Move software. You can quickly launch Move Anything using a key combination from the regular Move software, and quickly return to the regular Move software when you're done.

## Contributors
@talktogreg, @impbox, @deets, @bobbyd

## Community
Join us on Discord: https://discord.gg/Zn33eRvTyK

## Here are some examples of things people have made so far (DM me to be included here!)
* TODO: Add all the cool stuff that's been made so far.

* Messing about with the M8 Launch Pad Pro Emulation and mapped knobs
[![M8 LPP Emulation Jam Session](https://img.youtube.com/vi/YHt6c-Pq5Bc/0.jpg)](https://www.youtube.com/watch?v=YHt6c-Pq5Bc)


## Stupid stuff I did based on the knowledge gained on this project
[![DOOM on MOVE](https://img.youtube.com/vi/ZuNeumcc7-s/0.jpg)](https://www.youtube.com/watch?v=ZuNeumcc7-s)


## How do I actually create a script?
* Scripts are writting in modern Javascript (es2023). This makes it super fast and safe to try out new ideas and get things working quickly!
* The underlying core is written in C and can be reused for your own projects.
* TODO: Example Hello World script showing how to use all the features.

<br>
<br>
<br>
<br>
<br>
<br>



## Old Description follows 👇 👇 👇 👇 👇 👇 👇 👇 👇 


Move Control Surface
====================

## What is this?
1. An emulation of the Launch Pad Pro on the Ableton Move to be used with the Dirtywave M8. The Move is a USB host for the M8 and can charge it. All 9 knobs are mappable on the M8 while in LPP mode. Poly aftertouch is sent as CC1 and is also mappabe on M8.

2. A framework to develop control surface scripts in Javascript. This supports tansforming MIDI in arbitrary ways both coming from the pads, knobs and controls, and also transforming and retransmitting external midi.

3. A framework to capture keypresses while the Move's original software is running and to launch custom software, and to return to the Move software once finished.

4. As a bonus, there's an additional option to install "pages of sets" that gives you unlimited pages of sets on the Ableton Move.

## Installation

### Quick Start (macOS & Linux)
1. **Back up your sets** - While we haven't lost any data, it's always good to be safe!

2. **Turn on your Move** and make sure it's connected to the same network as your computer.

3. **Run the installer**:
   ```bash
   curl -L https://raw.githubusercontent.com/bobbydigitales/move-anything/main/install.sh | sh
   ```

That's it! The installer will automatically:
- ✅ Check your network connection to the Move
- ✅ Generate SSH keys if needed
- ✅ Guide you through SSH setup
- ✅ Download and install Move Anything
- ✅ Optionally install "Pages of Sets" feature

### Installation Options
The installer supports several options:

```bash
# Full installation with SSH setup
./install.sh

# Skip SSH setup (if already configured)
./install.sh --skip-ssh

# Force overwrite existing installation
./install.sh --force

# Development mode (use local package)
./install.sh --dev

# Show help
./install.sh --help
```

### Windows Installation
On Windows, you can use Git Bash (comes with Git for Windows):
1. Install Git for Windows: https://git-scm.com/downloads/win
2. Launch Git Bash
3. Run the installer command above

### Pages of Sets Feature
The installer will ask if you want to install "Pages of Sets" - an optional feature that gives you unlimited pages of sets on the Move by holding Shift + Left/Right arrows. 

⚠️ **Warning**: This feature rearranges your sets and changes their colors. You can install it later by running the installer again.

## Usage of the M8 Launchpad Pro emulation
<img width="5664" height="2788" alt="move_LPP_instructions_v2" src="https://github.com/user-attachments/assets/27d0cf29-35be-4c64-9fc2-52d3f33686dd" />

1. Once installed, to launch the m8 integration, hold shift(...) then touch the volume knob and the jog wheel. Toggle Launch Pad Pro control surface mode on the M8 and the Move should come show you the session mode.

2. To see the bottom half of the Launch Pad Pro, click the wheel, the mode button you're on will flash to show you'e on the bottom half.

3. To launch Beat Repeat mode, hold shift(...), press session (the arrow pointing left on the left of the move), then click the wheel to show the bottom half of the Move.

4. All 9 knobs send MIDI CC's on channel 4. Poly aftertouch is mapped to CC1 on channel 4.

5. To exit M8 control surface mode and go back to Move, hold shift(...) and click the jog wheel in.

## Usage of "Pages of Sets"
_**Note that when you change pages your live session is killed and restarted with the new page**_

1. To change pages hold shift(...) and press the left or right arrow.
2. If a page doesn't exist, it will be created.
3. Samples, Track presets, Recordings and Effects presets are shared between all pages.
2. http://move.local will show the Sets from the current page.

## After installing a new Move build
**After an update to a new Move build, you will need to re-run the install script.**

## Troubleshooting
If it's not working, you can get help in our Discord server: https://discord.gg/gePd9annTJ


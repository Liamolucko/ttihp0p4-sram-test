This is a modified version of the IHP sg13cmos5l PDK's single-port 1024x8 SRAM macro (which is the same as the sg13g2 one), which can be found at https://github.com/IHP-GmbH/IHP-Open-PDK/tree/main/ihp-sg13g2/libs.ref/sg13g2_sram.

The only change is to extend the macro's vertical power straps on Metal4 beyond the bounds of the macro, so that they can be connected to a power ring surrounding it. This is necessary because Tiny Tapeout reserves the TopMetal1 layer for itself, leaving us with only the Metal1-Metal4 layers. The macro uses all of these layers, making it impossible to power it using ordinary power straps over the top in Tiny Tapeout.

This change is performed using the `extend_pdn.py` Python script.

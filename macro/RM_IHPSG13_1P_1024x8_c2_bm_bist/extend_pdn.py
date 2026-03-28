# Some IHP pre-generated SRAM macros use Sky130A 235/4 layers instead of 189/4
# This causes GDS to fatally crash after properly generating the blackbox, so we fix it here.
#
# Source and credit:
# https://github.com/FPGA-Research/heichips25-tapeout/blob/main/scripts/convert_layers.py
#
# Tracked PDK issue:
# https://github.com/IHP-GmbH/IHP-Open-PDK/issues/615

import os
import pya
import re


def main():
    TARGET_DIR: str = os.path.dirname(os.path.abspath(__file__))
    TARGET_GDS: str = "RM_IHPSG13_1P_1024x8_c2_bm_bist.gds"
    TARGET_LEF: str = "RM_IHPSG13_1P_1024x8_c2_bm_bist.lef"
    TARGET_GDS_PATH: str = os.path.join(TARGET_DIR, TARGET_GDS)
    TARGET_LEF_PATH: str = os.path.join(TARGET_DIR, TARGET_LEF)

    layout = pya.Layout()
    layout.read(TARGET_GDS_PATH)
    top_cell = layout.top_cell()
    top = top_cell.dbbox().top

    metal4_drawing = layout.layer(50, 0)
    metal4_pin = layout.layer(50, 2)

    extend_pdn(top_cell, top, metal4_drawing, metal4_pin)
    layout.write(TARGET_GDS_PATH)

    # please let me know if there are any LEF libraries I can replace this garbage
    # with...
    result = ""
    with open(TARGET_LEF_PATH, "r") as f:
        lines = f.read().splitlines()

    metal4 = False
    obs = False
    while len(lines) > 0:
        line = lines.pop(0)

        if "SIZE" in line:
            _, width, _, height, _ = line.split()
            bottom_re = re.compile(r"RECT (-?[\d.]+) 0 (-?[\d.]+) (-?[\d.]+)")
            top_re = re.compile(rf"RECT (-?[\d.]+) (-?[\d.]+) (-?[\d.]+) {height}")

        if "LAYER Metal4" in line:
            metal4 = True
        elif "LAYER" in line:
            metal4 = False

        if "OBS" in line:
            obs = True

        if metal4 and not obs:
            line = bottom_re.sub(rf"RECT \1 -19 \2 \3", line)
            line = top_re.sub(rf"RECT \1 \2 \3 {float(height) + 19}", line)

        result += line + "\n"

    with open(TARGET_LEF_PATH, "w") as f:
        f.write(result)

def extend_pdn(cell, top, metal4_drawing, metal4_pin):
    print(cell.name)

    # modifying while iterating is invalid, apparently
    shapes = [*cell.shapes(metal4_pin)]
    for shape in shapes:
        box = shape.dbox
        if box is not None and box.top == top:
            box.top = box.top + 19
            shape.dbox = box
        if box is not None and box.bottom <= 0:
            box.bottom = -19
            shape.dbox = box
        # the shapes from metal4_drawing aren't playing nice, just add extra ones from
        # metal4_pin...
        cell.shapes(metal4_drawing).insert(shape)

    for c in cell.each_child_cell():
        extend_pdn(cell.layout().cell(c), top, metal4_drawing, metal4_pin)


if __name__ == "__main__":
    main()

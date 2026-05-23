import numpy as np
import matplotlib.pyplot as plt

FUNC = lambda x: (np.sin(2 * np.pi * x) + 1) / 2
DEPTH = 14
WIDTH = 12
FILE_NAME = "assets/sin.mif"


if __name__ == "__main__":
    x = np.arange(0, 2 ** WIDTH)
    x_norm = np.linspace(0, 1, 2 ** WIDTH)
    y = FUNC(x_norm) * (2 ** DEPTH - 1)
    y_int = y.round().astype(int)
    with open(FILE_NAME, "w") as f:
        f.write(f"DEPTH = {2 ** WIDTH};\n")
        f.write(f"WIDTH = {DEPTH};\n")
        f.write("ADDRESS_RADIX = BIN;\n")
        f.write("DATA_RADIX = BIN;\n")
        f.write("CONTENT\n")
        f.write("BEGIN\n")
        for i in range(2 ** WIDTH):
            addr_bin = format(i, f"0{WIDTH}b")
            data_bin = format(y_int[i], f"0{DEPTH}b")
            f.write(f"{addr_bin} : {data_bin};\n")
        f.write("END;\n")

    plt.step(x, y_int)
    plt.show()

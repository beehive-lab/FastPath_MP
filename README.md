# FastPath_MP

## Description
This repository stores the source code of FastPath_MP, an FPGA-based multi-path architecture 
for direct access from FPGA to NVMe SSD.
In particular it includes three modules:
- The FastPath_MP FPGA architecture implemented in `Bluespec`.
- The `libfnvme` library that implements the C-based API that applications can utilize to communicate with FastPath_MP.
- The modified NVMe driver in the Linux kernel (`linux-4.4-zynq`) for the Xilinx Zynq 7000 SoC.

## License
The three modules of FastPath_MP are licensed as follows:
|  Module | License  |
|---|---|
| FastPath_MP Bluespec System Verilog | [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)|
| Libfnvme Library | [![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](https://opensource.org/licenses/Apache-2.0)|
| Modified NVMe driver | [![License: GPL v2](https://img.shields.io/badge/License-GPL%20v2-blue.svg)](https://www.gnu.org/licenses/old-licenses/gpl-2.0.en.html)|

## Acknowledgements
This work was partially supported by EU Horizon 2020 grants: (i) EuroEXA (ID: 754337); and (ii) E2Data (ID: 780245) with
hardware platforms from Kaleao Limited. 
[A. Stratikopoulos](https://personalpages.manchester.ac.uk/staff/athanasios.stratikopoulos/) was funded by an Arm Ltd. & EPSRC iCASE PhD Scholarship during this work. 
[Prof. Mikel Luján](http://apt.cs.manchester.ac.uk/people/mlujan/) is funded by an Arm/RAEng Research Chair Award and a Royal Society Wolfson Fellowship.

## Citation
If you are using FastPath_MP, please use the following citation:

```bibtex
@article{10.1145/3423134,
author = {Stratikopoulos, Athanasios and Kotselidis, Christos and Goodacre, John and Luj\'{a}n, Mikel},
title = {FastPath_MP: Low Overhead & Energy-Efficient FPGA-Based Storage Multi-Paths},
year = {2020},
issue_date = {December 2020},
publisher = {Association for Computing Machinery},
address = {New York, NY, USA},
volume = {17},
number = {4},
issn = {1544-3566},
url = {https://doi.org/10.1145/3423134},
doi = {10.1145/3423134}
}
```


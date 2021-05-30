# median-filter

This project showcases a median filter implemented on a Nexys4 DDR FPGA. Matlab was used to send an image to the FPGA via UART, and the image was stored in DDR2 memory using AXI Stream/Lite interfaces. A pipelined median filter was designed to process the image.

This project was completed as a course assignment and is divided into several parts. Part 1 contains the system required to receive, store, and send the image between Matlab and the FPGA. Part 2 contains the median filter itself. Part 3 contains the entire system.

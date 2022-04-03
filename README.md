# SRAM tester for DECA

Looking for a way to test the SRAM part of the Mister dual memory 32MB SDRAM + 2 MB SRAM I found this [article from Salvador Canas](https://projects.digilentinc.com/salvador-canas/a-practical-introduction-to-sram-memories-using-an-fpga-i-3f3992) and [this second part](https://projects.digilentinc.com/salvador-canas/a-practical-introduction-to-sram-memories-using-an-fpga-ii-a18801).  Here you can find his [github repo](https://github.com/salcanmor/SRAM-tester-for-Cmod-A7-35T/tree/master/basic%20controller).


I modified his Xilinx code to work with my Altera DECA FPGA. I changed also the UART module he was using as I did not get any valid serial output.

Serial terminal:   

```
picocom --imap crcrlf /dev/ttyUSB0 
```

See this [video](deca_sram.mp4)

There are two versions, a very basic controller and v2 which is a more advanced and efficient controller.

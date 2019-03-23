onbreak {quit -force}
onerror {quit -force}

asim -t 1ps +access +r +m+Top_module -L xil_defaultlib -L xpm -L blk_mem_gen_v8_4_2 -L fifo_generator_v13_2_3 -L unisims_ver -L unimacro_ver -L secureip -O5 xil_defaultlib.Top_module xil_defaultlib.glbl

do {wave.do}

view wave
view structure

do {Top_module.udo}

run -all

endsim

quit -force

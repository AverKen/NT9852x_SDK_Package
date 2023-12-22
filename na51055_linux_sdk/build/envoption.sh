# DO NOT USE SAPCE AT LEFT SIDE AND RIGHT SIDE OF EQUAL. 
# e.g DO NOT USE 'NVT_FPGA = OFF', but rather 'NVT_FPGA=OFF'
export NVT_FPGA=OFF
export NVT_EMULATION=OFF

# this setting only for RTOS. (linux has write-hard a9)
# cortex-a53
# cortex-a9
export RTOS_CPU_TYPE=cortex-a9

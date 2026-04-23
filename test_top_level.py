import cocotb
from cocotb.triggers import FallingEdge, Timer, RisingEdge

async def generate_clock(dut):
    while True:
        dut.clk.value = 0
        await Timer(1, unit='ns')
        dut.clk.value = 1
        await Timer(1, unit='ns')

@cocotb.test()
async def custom_fib(dut):
    dut.rst_n.value = 0
    cocotb.start_soon(generate_clock(dut))
    for _ in range(5):
        await FallingEdge(dut.clk)
    dut.rst_n.value = 1

    for i in range(5000):
        await FallingEdge(dut.clk)
        pc_out = int(dut.pc_inst.pc_out.value)
        
        if pc_out == 0x8:
            a0 = int(dut.regfile_inst.registers[10].value)
            cocotb.log.info(f'Program hit infinite loop at cycle {i}. a0 = {a0}')
            assert a0 == 42, f'Test Failed! a0 is {a0}, expected 42 (success)'
            return
            
    assert False, 'Simulation timed out safely before reaching PC 0x8'

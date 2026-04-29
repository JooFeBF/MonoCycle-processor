import cocotb
from cocotb.triggers import FallingEdge, Timer, RisingEdge
from cocotb.clock import Clock

@cocotb.test()
async def custom_fib(dut):
    dut.rst_n.value = 0
    dut.clk.value = 0
    cocotb.start_soon(Clock(dut.CLOCK_50, 20, units="ns").start())
    for _ in range(5):
        await FallingEdge(dut.CLOCK_50)
    dut.rst_n.value = 1

    for i in range(5000):
        dut.clk.value = 1
        for _ in range(5):
            await FallingEdge(dut.CLOCK_50)
        dut.clk.value = 0
        for _ in range(5):
            await FallingEdge(dut.CLOCK_50)
            
        pc_out = int(dut.pc_inst.pc_out.value)
        
        if pc_out == 0x8:
            a0 = int(dut.regfile_inst.registers[10].value)
            cocotb.log.info(f'Program hit infinite loop at cycle {i}. a0 = {a0}')
            assert a0 == 42, f'Test Failed! a0 is {a0}, expected 42 (success)'
            return
            
    assert False, 'Simulation timed out safely before reaching PC 0x8'

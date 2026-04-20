import cocotb
from cocotb.triggers import FallingEdge, Timer, RisingEdge

async def generate_clock(dut):
    for _ in range(200):
        dut.clk.value = 0
        await Timer(1, unit="ns")
        dut.clk.value = 1
        await Timer(1, unit="ns")

@cocotb.test()
async def custom_fib(dut):
    dut.rst_n.value = 0
    cocotb.start_soon(generate_clock(dut))
    for _ in range(5):
        await FallingEdge(dut.clk)
    dut.rst_n.value = 1

    for i in range(12):
        await FallingEdge(dut.clk)
        pc_out = int(dut.pc_inst.pc_out.value)
        imem_addr = int(dut.imem_inst.address.value)
        instr = int(dut.imem_inst.instruction.value)
        cocotb.log.info(f"Cycle {i}, pc_out: 0x{pc_out:x}, imem_addr: 0x{imem_addr:x}, instr: 0x{instr:08x}")

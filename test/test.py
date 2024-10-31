# SPDX-FileCopyrightText: © 2024 Tiny Tapeout
# SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import ClockCycles

@cocotb.test()
async def test_project(dut):
    dut._log.info("Start")

    # Create a clock with a period of 1 ns
    clock = Clock(dut.clk, 1, units="ns")
    cocotb.start_soon(clock.start())

    # Apply reset
    dut.rst_n.value = 0
    await ClockCycles(dut.clk, 10)
    dut.rst_n.value = 1

    # Initial input
    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 10)

    # Apply a stimulus
    dut.ui_in.value = 100
    await ClockCycles(dut.clk, 10)

    dut.ui_in.value = 0
    await ClockCycles(dut.clk, 100)

    # Monitor the outputs
    # for _ in range(20):
    #     await ClockCycles(dut.clk, 1)
    #     dut._log.info(f"Neuron state: {dut.uo_out.value}, Spike: {dut.uio_out.value[7]}")

    # Run the simulation longer if needed
    await ClockCycles(dut.clk, 100)

    dut._log.info("Finished")
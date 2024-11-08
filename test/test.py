import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge

async def initialize_dut(dut):
  clock = Clock(dut.clk, 10, units="ns")
  cocotb.start_soon(clock.start())
  
  dut.rst_n.value = 0
  dut.ena.value = 0
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  
  await RisingEdge(dut.clk)
  await RisingEdge(dut.clk)
  dut.rst_n.value = 1
  dut.ena.value = 1

async def run_pattern_test(dut, pattern, name):
  # Set pattern and coupling strength
  dut.ui_in.value = 0b10000000 | pattern  # High base current + pattern
  dut.uio_in.value = 0x60  # Strong coupling strength
  
  print(f"\nTesting {name} (Pattern {pattern})")
  print("Time: Neuron1 Neuron2")
  print("-----------------------")
  
  for i in range(200):
      await RisingEdge(dut.clk)
      spike1 = dut.uo_out.value.integer & 0x1
      spike2 = (dut.uo_out.value.integer & 0x2) >> 1
      
      if spike1 or spike2:
          print(f"{i:4d}:   {spike1}      {spike2}")

@cocotb.test()
async def test_all_patterns(dut):
  await initialize_dut(dut)
  
  # Test different firing patterns
  patterns = [
      (0b000, "Independent firing"),
      (0b001, "Synchronized firing"),
      (0b010, "Opposed firing"),
      (0b011, "Weak coupling")
  ]
  
  for pattern, name in patterns:
      await run_pattern_test(dut, pattern, name)
      await RisingEdge(dut.clk)
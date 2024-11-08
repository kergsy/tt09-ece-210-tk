import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, Timer, ClockCycles
from cocotb.utils import get_sim_time

async def initialize_dut(dut):
  """Initialize the DUT and start clock"""
  clock = Clock(dut.clk, 10, units="ns")
  cocotb.start_soon(clock.start())
  
  # Initialize inputs
  dut.ui_in.value = 0
  dut.uio_in.value = 0
  dut.ena.value = 0
  dut.rst_n.value = 1
  
  # Reset sequence
  await RisingEdge(dut.clk)
  dut.rst_n.value = 0
  await ClockCycles(dut.clk, 2)
  dut.rst_n.value = 1
  dut.ena.value = 1

async def monitor_spikes(dut, duration, pattern_name):
  """Monitor and log spike activity"""
  spike_count = 0
  transitions = 0
  last_spikes = 0
  
  for _ in range(duration):
      await RisingEdge(dut.clk)
      spikes = dut.uo_out.value.integer & 0xF  # Only consider the lower 4 bits
      if spikes != last_spikes:
          transitions += 1
          if spikes != 0:
              new_spikes = bin(spikes).count('1')
              spike_count += new_spikes
              dut._log.info(f"Time {get_sim_time('ns'):>5}ns - {pattern_name} - "
                            f"Spikes: {format(spikes, '04b')} (Count: {spike_count})")
      last_spikes = spikes
  
  return spike_count, transitions

async def test_pattern(dut, pattern, base_current, coupling, name, duration=500):
  """Test a specific firing pattern"""
  # Set pattern and parameters (ensuring 8-bit values)
  dut.ui_in.value = ((base_current & 0x1F) << 3) | (pattern & 0x7)
  dut.uio_in.value = coupling & 0xFF
  
  dut._log.info(f"\nTesting {name} pattern")
  dut._log.info(f"Base current: {base_current}, Coupling: {coupling}")
  
  # Monitor activity
  spike_count, transitions = await monitor_spikes(dut, duration, name)
  return spike_count, transitions

@cocotb.test()
async def test_lif_ring_patterns(dut):
  """Test all firing patterns of the LIF ring oscillator"""
  await initialize_dut(dut)
  
  total_spikes = 0
  total_transitions = 0
  
  # Test configurations (adjusted base currents and coupling strengths)
  patterns = [
      (0, 8, 0,   "Independent"),    # No coupling
      (1, 8, 50,  "Wave"),          # Medium neighbor coupling
      (2, 8, 80,  "Synchronous"),   # Strong all-to-all coupling
      (3, 8, 40,  "Clustered"),     # Medium pair-wise coupling
      (4, 8, 100, "Burst")          # Very strong neighbor coupling
  ]
  
  # Run tests for each pattern
  for pattern, base_current, coupling, name in patterns:
      spikes, transitions = await test_pattern(
          dut, pattern, base_current, coupling, name, duration=1000
      )
      total_spikes += spikes
      total_transitions += transitions
      
      # Add delay between patterns
      await ClockCycles(dut.clk, 50)
  
  # Report results
  dut._log.info("\nTest Complete!")
  dut._log.info(f"Total spikes: {total_spikes}")
  dut._log.info(f"Total pattern transitions: {total_transitions}")

SPDX-FileCopyrightText: © 2024 Tiny Tapeout
SPDX-License-Identifier: Apache-2.0

import cocotb
from cocotb.clock import Clock
from cocotb.triggers import RisingEdge, ClockCycles
from cocotb.utils import get_sim_time

@cocotb.test()
async def test_lif_neuron(dut):
  """Test the simplified LIF neuron design."""
  # Create a clock with a period of 10ns
  clock = Clock(dut.clk, 10, units="ns")
  cocotb.start_soon(clock.start())

  # Reset the design
  dut.rst_n.value = 0
  dut.ena.value = 0
  dut.ui_in.value = 0  # External input current
  await ClockCycles(dut.clk, 5)
  dut.rst_n.value = 1
  dut.ena.value = 1

  # Initialize variables
  total_cycles = 1000  # Total simulation cycles
  input_current = 10   # Initial external input current
  dut.ui_in.value = input_current

  dut._log.info("Starting test of the LIF neuron")

  # Monitor the neuron over time
  for cycle in range(total_cycles):
      await RisingEdge(dut.clk)

      # Optionally, modify the input current at specific cycles
      if cycle == 500:
          input_current = 20  # Increase the external input current
          dut.ui_in.value = input_current
          dut._log.info(f"Cycle {cycle}: Increased input current to {input_current}")

      # Read the neuron's state and spike output
      neuron_state = dut.uio_out.value.integer
      spike = dut.uo_out.value.integer & 0x1  # Extract the spike bit

      # Log the neuron's activity
      dut._log.info(
          f"Cycle {cycle:4}: Input={input_current}, State={neuron_state}, Spike={spike}"
      )

  dut._log.info("Test completed.")

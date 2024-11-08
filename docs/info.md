<!---

This file is used to generate your project datasheet. Please fill in the information below and delete any unused
sections.

You can also include images in this folder and reference them in the markdown. Each image must be less than
512 kb in size, and the combined size of all images must be less than 1 MB.
-->

## How it works

The system implements two coupled Leaky Integrate and Fire (LIF) neurons that can operate in different firing patterns. Each neuron models basic biological neuron behavior through several key mechanisms:

### Core Components

1. Membrane Potential
- Accumulates charge based on input current
- Leaks charge over time (LEAK_RATE = 5)
- Fires when reaching threshold (THRESHOLD = 200)
- Resets after firing (RESET_POTENTIAL = 50)

2. Refractory Period
- After firing, neuron enters a refractory period (REFRACTORY_PERIOD = 10 cycles)
- Cannot fire during refractory period
- Prevents rapid re-firing and helps maintain rhythm

3. Phase Counter
- Each neuron has an independent phase counter
- Helps coordinate timing between neurons
- Enables phase-locked firing patterns

### Firing Patterns

The system supports four distinct firing patterns, controlled by pattern_select[2:0]:

1. Independent Firing (000)
- Neurons fire based only on their base current
- No coupling between neurons
- Used as baseline behavior

2. Synchronized Firing (001)
- Strong excitatory coupling (2x coupling_in)
- When one neuron fires, it encourages the other to fire
- Results in synchronized firing patterns

3. Opposed Firing (010)
- Strong inhibitory coupling (4x coupling_in)
- When one neuron fires, it suppresses the other
- Phase offset ensures alternating firing pattern

4. Weak Coupling (011)
- Half-strength coupling (0.5x coupling_in)
- Subtle interaction between neurons
- Maintains individual firing patterns with slight influence

### Input/Output Interface

Inputs:
- ui_in[7:3]: Base current (determines basic firing rate)
- ui_in[2:0]: Pattern select
- uio_in[7:0]: Coupling strength
- clk: System clock
- rst_n: Active-low reset
- ena: Enable signal

Outputs:
- uo_out[1:0]: Spike outputs (1 bit per neuron)
- uio_out[7:0]: First neuron's membrane potential
- uio_oe[7:0]: I/O enable (set to inputs)

## How to test

1. Basic Functionality Test
- Set base current (ui_in[7:3]) to mid-range value (e.g., 16)
- Set pattern_select to 000 (independent firing)
- Verify both neurons fire periodically
- Check membrane potential builds up and resets

2. Pattern Testing
For each pattern (000 through 011):
- Set appropriate pattern_select bits
- Set coupling strength (uio_in) to mid-range (e.g., 0x60)
- Observe firing patterns for 200+ clock cycles
- Verify expected behavior:
  * 000: Independent periodic firing
  * 001: Synchronized firing
  * 010: Alternating firing
  * 011: Weakly influenced firing

3. Parameter Sensitivity
- Vary base current to test different firing rates
- Adjust coupling strength to test interaction strength
- Verify stable operation across parameter ranges

4. Reset and Enable Testing
- Test reset functionality (rst_n)
- Verify enable signal (ena) properly controls operation
- Check proper initialization of all registers

5. Edge Cases
- Test minimum base current for firing
- Test maximum coupling strength
- Verify proper handling of overflow conditions
- Check behavior during simultaneous firing attempts

6. Using Cocotb
- Run provided test bench
- Monitor spike outputs and membrane potentials
- Verify timing relationships between neurons
- Check phase relationships in different modes

## External hardware

N/A.
# 🎛️ FPGA-Based 4th-Order IIR Low Pass Filter

![Platform](https://img.shields.io/badge/Platform-Basys3%20Artix--7-red)
![Language](https://img.shields.io/badge/Language-Verilog%20HDL-blue)
![Tool](https://img.shields.io/badge/Tool-Xilinx%20Vivado-orange)
![MATLAB](https://img.shields.io/badge/Coefficients-MATLAB-yellow)
![Status](https://img.shields.io/badge/Status-Complete-brightgreen)

## 📌 Overview
4th-order IIR low pass filter implemented in Verilog HDL on Basys3 (Artix-7) FPGA using Direct Form II structure. Filter coefficients are in Q14 fixed-point format. The system generates test signals internally, filters them, and displays frequency and amplitude on 7-segment display and LED bar graph.

## 🏗️ System Architecture

```
Switch Input (SW0 = 50Hz, SW1 = 350Hz)
      |
      v
Signal Generator (LUT-based sine tables)
      |
      v
1kHz Sample Enable (from 100MHz clock)
      |
      v
IIR Filter (Direct Form II — Q14 coefficients)
      |
      v
Zero-Crossing Frequency Estimator
Peak Amplitude Detector
      |
      v
7-Segment Display (Frequency)
16-LED Bar Graph (Amplitude)
```

## ✨ Features
- 4th-order IIR filter — Direct Form II structure
- Q14 fixed-point coefficient representation
- 48-bit multipliers preventing MAC overflow
- Signed saturation clamping to 16-bit range (±32767)
- Pre-stored sine wave LUTs for 50Hz and 350Hz test signals
- 1kHz sample rate derived from 100MHz onboard clock
- Zero-crossing frequency estimator with windowed analysis
- Peak amplitude detector with LED bar graph output
- Testbench verifying pass-band (50Hz) and stop-band (350Hz)

## 📁 Repository Structure

```
basys3-iir-filter/
├── src/
│   ├── top_iir.v          ← Top level — signal gen + display
│   └── iir_filter.v       ← Core IIR filter module
├── testbench/
│   └── tb_top_iir.v       ← Testbench — 50Hz and 350Hz tests
├── constraints/
│   └── basys3.xdc         ← Pin constraints
└── README.md
```

## 🔬 Key Concepts Demonstrated

| Concept | Where Used |
|---|---|
| Direct Form II IIR structure | iir_filter.v |
| Q14 fixed-point arithmetic | Coefficient representation |
| 48-bit MAC overflow prevention | Multiplier width in iir_filter.v |
| Signed saturation logic | y_next assignment |
| LUT-based signal generation | sig50, sig350 tables in top_iir.v |
| Zero-crossing frequency detection | top_iir.v |
| Peak amplitude windowing | top_iir.v |

## 🛠️ Filter Specifications

| Parameter | Value |
|---|---|
| Filter Type | IIR Low Pass |
| Order | 4th Order |
| Structure | Direct Form II |
| Arithmetic | Q14 Fixed-Point |
| Sample Rate | 1 kHz |
| FPGA Clock | 100 MHz |
| Test Signals | 50Hz (pass) and 350Hz (stop) |

## 🔢 Q14 Coefficients

| Coefficient | Value | Description |
|---|---|---|
| B0 | 588 | Feed-forward |
| B1 | 690 | Feed-forward |
| B2 | 1053 | Feed-forward |
| B3 | 690 | Feed-forward |
| B4 | 588 | Feed-forward |
| A1 | -30123 | Feedback |
| A2 | 26089 | Feedback |
| A3 | -10476 | Feedback |
| A4 | 1736 | Feedback |

## ▶️ How to Run

**Simulation:**
```
1. Open Vivado → Create Project
2. Add src/*.v as Design Sources
3. Add testbench/tb_top_iir.v as Simulation Source
4. Run Behavioral Simulation
5. Observe LED output:
   SW0 ON (50Hz)  → LEDs show amplitude (pass-band)
   SW1 ON (350Hz) → LEDs show low/no output (stop-band)
```

**Hardware:**
```
1. Add constraints/basys3.xdc
2. Run Synthesis → Implementation → Generate Bitstream
3. Program Basys3 via Hardware Manager
4. SW0 ON → 50Hz signal → frequency shown on 7-seg
5. SW1 ON → 350Hz signal → attenuated output
```

## 👤 Author
**Raghavendra Palukuri**  
M.Tech VLSI & ES — DIAT Pune (DRDO)  
📧 raghavapalukuri25p@gmail.com  
🔗 [LinkedIn](https://www.linkedin.com/in/raghavendra-palukuri)

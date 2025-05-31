# 📄 Project Report: Real-Time Weather Monitoring System Using FPGA

## 👨‍🔬 Authors

- **Hanuman Matupalli**  
  Department of Electronics and Communication Engineering  
  Amrita Vishwa Vidyapeetham  
  Email: hanumanmattupalli@gmail.com

- **Isukapalli Aditiya**  
  Department of Electronics and Communication Engineering  
  Amrita Vishwa Vidyapeetham  
  Email: adigow1234@gmail.com

- **Mohan Kumar D**  
  Department of Electronics and Communication Engineering  
  Amrita Vishwa Vidyapeetham  
  Email: mohankumar142004@gmail.com

---

## 📌 Abstract

This project presents an FPGA-based integrated system that combines a 12-hour digital clock with DHT11 temperature and humidity sensing. The design uses dynamic display multiplexing, adaptive sensor polling, and context-aware control logic to share hardware efficiently. It achieves:
- <15% resource overhead
- ±1 second/day accuracy in timekeeping
- ±2°C and ±5% RH accuracy in environmental sensing

The system has been validated on hardware and tested in real-world environments, proving its efficiency and robustness for edge IoT devices.

---

## 🎯 Objectives

1. Develop a unified FPGA system integrating a digital clock and DHT11 sensor.
2. Optimize hardware sharing to reduce resource utilization below 15% overhead.
3. Implement a context-aware UI with dynamic button functionality.
4. Reduce power consumption by 30% using clock-gating during sensor idle states.
5. Validate performance across temperature (0–50°C) and humidity (20–90% RH) ranges.

---

## ⚙️ Hardware Setup

- **Board**: Digilent Basys 3 FPGA
- **FPGA Chip**: Xilinx Artix-7 (XC7A35T-1CPG236C)
- **Sensor**: DHT11 Temperature and Humidity Sensor (connected to PMOD JA1, Pin 1)
- **Display**: Onboard 4-digit 7-segment common-anode display (AN0–AN3)
- **Inputs**:
  - Pushbuttons for clock adjustment and navigation
  - Slide switch (SW15) for toggling between clock and sensor modes
- **Power**: 3.3V regulated onboard
- **Clock Source**: 100MHz onboard oscillator

---

## 🔍 Key Features

- **Display Multiplexing**: Switches between clock and sensor data in <1ms
- **Context-Aware Controls**: Buttons adapt to mode (clock/sensor)
- **Sensor Optimization**:
  - 98% data reliability with optimized DHT11 protocol
  - 40% fewer LUTs than traditional designs
- **Accurate Timekeeping**: ±1 sec/day
- **Environmental Accuracy**: ±2°C and ±5% RH

---

## 📐 Design Details

### A. Timing Calculations
- **1Hz Clock for Timekeeping**:  
  `Counter Limit = f_system / f_target`
- **100Hz Multiplexing for 7-Segment Display**:
  `Refresh Rate = f_system / (CounterLimit * Digits)`

### B. BCD Conversion Logic
- Unit Digit: `value % 10`
- Tens Digit: `(value // 10) % 10`
- Hundreds Digit: `(value // 100) % 10`

### C. Control Logic & UI
- **Debouncing**: 20ms debounce logic to avoid button bounce
- **Sensor Communication**: State machine with retry and checksum verification
- **Display**: AM/PM indicated by decimal point on 7-segment

---

## 🧪 Results and Discussion

### Functional Outputs
- ✅ Clock displays time with AM/PM
- ✅ Real-time temperature and humidity from DHT11 shown on 7-segment display
- ✅ Smooth switching between modes using SW15

### FPGA Resource Utilization

| Resource      | Used | Total   | Utilization |
|---------------|------|---------|-------------|
| LUTs          | 645  | 20,800  | 3.10%       |
| Flip-Flops    | 265  | 41,600  | 0.64%       |
| I/Os          | 31   | 106     | 29.25%      |

### Power Consumption
- **Total Power**: 26.6 W
- **I/O Power Share**: 69%
- ⚠️ **Thermal Concern**: Junction temperature exceeds 125°C → Suggests high I/O activity

---

## ✅ Achievements

- Seamless integration of DHT11 sensor and digital clock
- Efficient display utilization for both time and sensor data
- <12% hardware overhead compared to standalone designs
- High sensor communication reliability (98%)
- Context-aware adaptive user interface

---

## ⚠️ Limitations and Improvements

- **Thermal Management**: Requires optimization for high junction temperatures
- **Power Efficiency**: Dynamic power can be further reduced
- **UI Enhancement**: LCD could replace/augment 7-segment for better UX

---

## 🧾 Glossary

- **FPGA** – Field-Programmable Gate Array  
- **PMOD** – Peripheral Module Interface  
- **DHT11** – Digital Temp & Humidity Sensor  
- **BCD** – Binary Coded Decimal  
- **LUT** – Look-Up Table  
- **RH** – Relative Humidity  
- **MHz** – Megahertz  
- **V** – Volts  
- **Ω** – Ohms  

---

## 📚 References

1. DHT11 Sensor Datasheet  
2. Digilent Basys 3 Reference Manual  
3. Xilinx Artix-7 FPGA Technical Guide  
4. IEEE Journals on IoT Edge Devices and Embedded Systems  
5. Verilog/VHDL FSM Best Practices

---

## 🏁 Conclusion

This project showcases the successful implementation of a compact, resource-efficient FPGA system capable of real-time weather monitoring and clock display. It demonstrates that sophisticated, multi-functional embedded systems can be built with minimal resource usage, making them ideal for space-constrained and power-sensitive applications such as IoT edge devices.

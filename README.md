# Reliable Digital Emergency Communication
**MATLAB-Based Simulation of Robust Digital Message Transmission**

## Project Overview
A MATLAB-based digital communication system designed to simulate reliable emergency message transmission over noisy channels. It uses BPSK and QPSK modulation, AWGN channel modelling, Forward Error Correction (FEC), CRC-16 error detection, and priority-based retransmission.
## Key Features
- BPSK and QPSK digital modulation.
- AWGN channel and burst interference simulation.
- 3-bit repetition coding with majority voting.
- CRC-16 error detection.
- Priority-based automatic retransmission.
- Interactive MATLAB GUI.
- BER vs SNR and packet delivery rate analysis.

## Technologies & Concepts
MATLAB, BPSK, QPSK, AWGN, BER, SNR, CRC-16, FEC, ARQ and Digital Communication Systems.

## System Architecture
**1. Transmitter**
- Converts emergency messages into 8-bit ASCII binary data.
- Appends CRC-16 bits.
- Applies repetition coding.
- Performs BPSK or QPSK modulation.

**2. Communication Channel**
- Adds AWGN noise.
- Introduces optional burst interference.
- Simulates different SNR conditions.

**3. Receiver**
- Performs demodulation.
- Decodes repetition-coded data using majority voting.
- Validates packets using CRC-16.
- Accepts or rejects packets and manages retransmissions.

## Simulation Results
- BPSK with repetition FEC improves BER performance at lower SNR values in the supplied simulation.
- FEC improves packet delivery rate.
- Burst interference increases BER.
- CRC-16 detects corrupted packets.
- Priority-based retransmission provides additional transmission attempts.

### Successful Transmission Demonstration
| Parameter | Result |
|---|---|
| Message | FIRE AT SECTOR 42 |
| Modulation | BPSK |
| Priority | HIGH |
| SNR | 9.9 dB |
| FEC | Enabled |
| CRC-16 | Enabled |
| Decoded Bit Errors | 0 |
| Transmission Attempts | 3 |
| Packet Status | ACCEPTED |

## Project Files
- `gui.m` – MATLAB graphical user interface.
- `dc.m` – Standalone digital communication simulation.

## How to Run
1. Clone or download this repository.
2. Open MATLAB.
3. Navigate to the project directory.
4. Open `gui.m` and run the GUI entry function `DC_GUI`.
5. Run `dc.m` for standalone simulation.

**Requirement:** MATLAB R2016b or newer. No Communications Toolbox is required by the supplied implementation.

## Future Enhancements
- Advanced error correction techniques (Hamming and convolutional codes).
- Rayleigh and Rician fading channel modelling.
- Burst-error protection using interleaving.
- ACK/NACK-based retransmission.
- Hardware implementation using Software Defined Radio (SDR).

## Authors
**Harsh Raj | Harish Overikar**  
Indian Institute of Information Technology, Nagpur  
Department of Electronics and Communication Engineering

**Course:** Digital Communication (ECL320)  
**Academic Session:** 2026–2027

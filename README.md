
## Overview
This project involves hardware-software co-design of a RISC-V based platform aiming to create a DNN accelerator and an RISC-V based microprocessor to interface with the accelerator. The DNN accelerator uses a systolic array architecture with Processing Elements (PEs) containing Multiply-Accumulate (MAC) units and activation functions. We are using open-source RISC-V compatible cores, specifically choosing the Cheshire platform built around CVA6 cores by PULP organization, to interface with the accelerator.

### Accelerator
- **PE (Processing Element)**: Contains MAC unit and activation function.
- **Systolic Array**: Composed of multiple PEs arranged in a grid.
- **Accelerator Top**: Top module integrating the systolic array.

### Processor
- **Cheshire**: An open-source platform built around CVA6 cores by the PULP organization.

## Contents
This repository contains my contributions to the project.

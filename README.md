# Interrupt-Driven Serial I/O Driver (Motorola 68000 & DUART 68681)

Low-level bare-metal device driver and I/O subsystem implemented in **Motorola 68000 (M68k) Assembly**, developed for the Computer Architecture course at **Universidad Politécnica de Madrid (UPM)**.

---

###  Architecture & Technical Highlights

* **Processor & Controller:** Motorola 68000 CISC microprocessor interfacing with the **MC68681 DUART** (Dual Universal Asynchronous Receiver/Transmitter).
* **Interrupt-Driven Concurrency:** Non-blocking serial communications managed via Vectored Interrupts (Vector `$40` / Level 4 interrupt request) and hardware Interrupt Service Routine (`RTI`).
* **Critical Sections & Synchronization:** Atomic masking of the Status Register (`SR`) interrupt bits to prevent race conditions during write/transmit enable sequences.
* **Buffer & Memory Management:** Direct stack frame manipulation (`LINK`/`UNLK`), FIFO circular buffer management, and standard exception vectoring (Address Error, Bus Error, Privilege Violation, Illegal Instructions).

---

###  Subroutine Interface

* **`INIT`:** Configures DUART registers (38,400 baud, 8-bit characters, full-duplex), installs the `RTI` address into the interrupt vector table, and initializes internal circular buffers.
* **`SCAN`:** Non-blocking routine to extract received character blocks from internal line buffers (`LEECAR`) into target memory addresses.
* **`PRINT`:** Non-blocking buffered transmission routine that writes character blocks (`ESCCAR`) and enables dynamic transmission interrupts when buffers contain active payloads.
* **`RTI` (Interrupt Service Routine):** Evaluates Interrupt Status Register (`ISR`) for line events, handles async RX/TX transfers, drains FIFO pipelines, and clears active masks to prevent interrupt storms.

---

###  Environment & Tools

* **Assembler:** `68kasm` (Motorola S-record generator)
* **Simulator:** BSVC (Motorola 68000 Hardware Emulator on Unix/Linux)

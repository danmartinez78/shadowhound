---
tags: [hardware/power, hardware/networking, sensors, configuration]
status: draft
related: [networking/README, hardware/omni_vision_exploration, hardware/omni_vision_sensor_setup]
aliases: [Network & Power Topologies]
summary: >
  Comprehensive wiring and network configurations for ShadowHound hardware combinations: Thor + GO2 baseline, RealSense D555 variant, and DreamVu PAL variant.
---

# ShadowHound Network & Power Topologies

## Purpose
Document validated wiring and network configurations for the ShadowHound platform across multiple hardware combinations. This guide consolidates research on power distribution, network topology, and sensor integration strategies.

## Prerequisites
- GL.iNet GL-SFT1200 (Opal) router
- 140 W dual USB-C power bank (2× USB-C PD, 1× USB-A)
- Cat6 Ethernet cables
- Understanding of static IP configuration and ROS 2 DDS networking

## Hardware Configurations

This document provides **four validated wiring/network configurations**:

1. **Baseline:** GO2 Pro + AGX Thor (no external sensors)
2. **RealSense D555 Variant:** Adds D555 depth camera over Ethernet/PoE
3. **DreamVu PAL Variant:** Adds 360° omni camera via USB
4. **RealSense D555 (Standalone Research):** Detailed power and verification for Thor + D555 + Router

All designs assume the **GL.iNet GL‑SFT1200 (Opal)** in AP/Bridge mode acting as a 3‑port wired switch, and a **140 W dual‑USB‑C power bank**.

---

## Common Assumptions
- **Router mode:** Access Point / Bridge (WAN+LAN bridged). DHCP **off**; all devices use **static IPs**.
- **Time sync:** `chrony` or PTP (`ptpd`/`linuxptp`) with Thor as time master.
- **Cabling:** Cat6 or better. Keep cable runs <5 m if possible.
- **Router address:** `192.168.10.1`

---

## 1) Baseline: Thor ⇄ GO2 Pro via Travel Router

### Diagram

![Router Topology](../_assets/router-topology.svg)
*Baseline topology: GL‑SFT1200 in AP/Bridge mode, Thor on Ethernet, GO2 on Wi‑Fi (and factory Ethernet).* 

### Static IP Plan
| Device | Interface | IP |
|---|---|---|
| Router (GL‑SFT1200) | br‑lan | **192.168.10.1** |
| AGX Thor | eth0 | **192.168.10.3** |
| GO2 (onboard port) | eth0 | **192.168.123.161** *(factory net)* |

> **Note:** GO2's default subnet is `192.168.123.0/24`. Either (A) add a **secondary IP** on Thor's `eth0` (e.g., `192.168.123.10/24`) to talk to the GO2 directly **while keeping** `192.168.10.3/24` for the internal LAN, or (B) readdress GO2 into `192.168.10.0/24`. Option A is safer.

### Thor NIC Setup (Option A: dual-IP on same NIC)
```bash
# Primary LAN (to router)
sudo ip addr add 192.168.10.3/24 dev eth0
# Secondary IP for GO2 factory subnet
sudo ip addr add 192.168.123.10/24 dev eth0
```

### Router Setup
- Set **Access Point/Bridge** mode.
- Set router IP to **192.168.10.1**.
- Disable DHCP (or limit scope to your laptop only during bring‑up).

### Sync & Verification
```bash
# On Thor
ping -c 3 192.168.123.161   # GO2
ping -c 3 192.168.10.1      # Router

# Time sync (Thor as master)
sudo systemctl enable --now chrony
```

---

## 2) Variant: + RealSense D555 (Ethernet/PoE)

### Diagram
```
                  +------------------ wired LAN ------------------+
[140W PD Bank]    |                                                    |
   |       USB‑A 5V→ [GL‑SFT1200] —— (LAN1) —— [AGX Thor] —— USB‑C → (PD→PoE+) → [D555]
   |                                                     |
   |                                                     +—— (LAN2) —— [Unitree GO2]
   +— USB‑C PD (20V) → [AGX Thor]
```

### Power
- **Thor:** USB‑C PD from the 140 W bank.
- **Router:** USB‑A 5 V from the bank.
- **D555:** **USB‑C PD → PoE+ injector** (802.3at) → RJ‑45 to D555.

### Static IP Plan
| Device | Interface | IP |
|---|---|---|
| Router | br‑lan | **192.168.10.1** |
| Thor | eth0 | **192.168.10.3** and **192.168.123.10** (secondary) |
| GO2 | eth0 | **192.168.123.161** |
| D555 | eth0 | **192.168.10.4** |

> D555 on `192.168.10.0/24` keeps all non‑GO2 devices on a single LAN. Thor's secondary IP reaches the GO2 on its factory subnet.

### Router Setup
- AP/Bridge mode, IP **192.168.10.1**.
- No DHCP.

### Thor Net Setup
```bash
sudo ip addr add 192.168.10.3/24 dev eth0
sudo ip addr add 192.168.123.10/24 dev eth0
```

### PTP/Chrony
- Run `linuxptp` (ptp4l + phc2sys) **or** `chrony` on Thor; slaves on GO2 (if supported) and any Linux SBCs.

### Sanity Tests
```bash
ping -c 3 192.168.10.4    # D555
ping -c 3 192.168.123.161 # GO2
iperf3 -c 192.168.10.4 -t 10
```

### ROS 2 / Holoscan Notes
- D555 over Ethernet: ingest via librealsense/ROS2 (`realsense2_camera`) or Holoscan operator if available.
- Ensure jumbo frames **off** unless end‑to‑end supported (router may not pass 9k MTU).

---

## 3) Variant: + DreamVu PAL (USB or Mini)

### Diagram
```
                 +------------------ wired LAN ------------------+
[140W PD Bank]   |                                                   |
   |      USB‑A 5V→ [GL‑SFT1200] —— (LAN1) —— [AGX Thor] (USB3) —— [DreamVu PAL USB/Mini]
   |                                                   |
   |                                                   +—— (LAN2) —— [Unitree GO2]
   +— USB‑C PD (20V) → [AGX Thor]
```

### Power
- **Thor:** USB‑C PD from the 140 W bank.
- **Router:** USB‑A 5 V from the bank.
- **DreamVu PAL:** Powered via **USB 5 V** from Thor.

### Static IP Plan
| Device | Interface | IP |
|---|---|---|
| Router | br‑lan | **192.168.10.1** |
| Thor | eth0 | **192.168.10.3** and **192.168.123.10** (secondary) |
| GO2 | eth0 | **192.168.123.161** |
| PAL USB/Mini | USB | *N/A (USB, no IP)* |

### Thor Net Setup
```bash
sudo ip addr add 192.168.10.3/24 dev eth0
sudo ip addr add 192.168.123.10/24 dev eth0
```

### SDK / ROS 2 Bring‑up (PAL USB/Mini)
```bash
# After installing DreamVu PAL SDK (CUDA/TensorRT build recommended):
ros2 launch pal_camera_ros2 pal_mini.launch.py   # or pal_usb.launch.py
```

### Holoscan Notes
- PAL USB/Mini perform **host‑side GPU processing** via the SDK (stereo + dewarp). Budget ~15–30% GPU at full pano.
- Use ROI gating: downsample pano, detect motion/agents, crop tiles → send to VLM.

---

## 4) RealSense D555 (Standalone Research Configuration)

This configuration was developed during sensor research to achieve a fully wired, deterministic low-latency setup for indoor robotics and Holoscan development.

### Network Topology

```
            +-----------------------+
            |  140 W Power Bank     |
            |  (2 × USB-C PD, 1 × A)|
            +----------+------------+
                       | 
        ┌──────────────┼───────────────────────────────┐
        |              |                               |
        |              |                               |
  USB-C PD → Thor  USB-C PD → PoE Injector → D555     USB-A → Router
        |                |             |                 |
        |                |             |                 |
        |                |             |                 |
        |           Ethernet (Cat6)    |                 |
        |<────────────── LAN (GigE) ────────────────────>|
```

### Static IP Plan
| Device | Interface | IP Address |
|---------|------------|-------------|
| GL-SFT1200 Router | LAN bridge | 192.168.10.1 |
| AGX Thor | eth0 | 192.168.10.3 |
| GO2 (onboard port) | eth0 | 192.168.123.161 |
| RealSense D555 | eth0 (PoE) | 192.168.10.4 |

> **Note:** If an external compute dock (e.g., Xavier Backpack / EDU version) is present, its default IP is 192.168.123.18. For the base robot without this dock, the onboard computer interface uses 192.168.123.161.

### Power Distribution Details

#### Power Sources
| Port | Output | Device | Notes |
|------|---------|---------|-------|
| USB-C PD #1 | 20 V / up to 7 A | AGX Thor | Primary compute node |
| USB-C PD #2 | 20 V / 2–3 A | PD→PoE+ Injector | Powers D555 via Ethernet |
| USB-A | 5 V / 2 A | GL-SFT1200 Router | Low current draw (<5 W) |

#### Recommended PoE Injectors
**Primary:** UCTRONICS USB-C PD to PoE+ Injector (U6116)
- PD input: 20 V (negotiated automatically)
- Output: IEEE 802.3at 48 V PoE+ up to 25 W
- True Gigabit data passthrough
- Compact and field-tested for cameras and embedded devices

**Alternative:** iCreatin USB-C PD to 48 V PoE+ Injector (30 W)

#### Wiring Notes
- Use **Cat6 or better** cables (D555 datasheet specifies GigE 1000BASE-T with jumbo frame support)
- PoE injector should sit inline between router and D555
- The D555's USB port is for **debug and factory use only**; normal operation runs via PoE Ethernet

### Thor Network Setup
```bash
# Primary LAN (to router)
sudo ip addr add 192.168.10.3/24 dev eth0
# Secondary IP for GO2 factory subnet
sudo ip addr add 192.168.123.10/24 dev eth0
```

### Router Configuration
- Set **Access Point/Bridge** mode
- Set router IP to **192.168.10.1**
- Disable DHCP (or limit scope to laptop only during bring‑up)

### Detailed Verification Steps

1. **Physical Layer:**
   ```bash
   # Verify all Ethernet link LEDs are active
   # Check power bank output voltage with multimeter if available
   ```

2. **Network Layer:**
   ```bash
   # Ping all devices
   ping -c 3 192.168.123.161   # GO2 onboard port
   ping -c 3 192.168.10.4      # D555
   ping -c 3 192.168.10.1      # Router
   ```

3. **Throughput Testing:**
   ```bash
   # Install iperf3 if not present
   sudo apt install iperf3
   
   # Run server on one device
   iperf3 -s
   
   # Run client from another
   iperf3 -c 192.168.10.3 -t 30
   
   # Expected: >900 Mbps and <1 ms latency
   ```

4. **RealSense Validation:**
   ```bash
   # Launch RealSense SDK 2.0 with DDS backend
   rs-enumerate-devices
   # Verify D555 is detected over Ethernet
   ```

### Key Advantages
- **Fully wired, deterministic network** (no Wi-Fi jitter)
- **Shared power domain** with proper voltage isolation
- **Native PoE+ powering** of D555 as per datasheet spec
- **Simple field setup:** one battery, one router, one injector

### Future Expansion Considerations
- Replace GL-SFT1200 with a multi-gig router (e.g., GL-BE3600 Slate 7) for higher bandwidth
- Add precision time protocol (PTP) daemon on Thor to synchronize timestamps for Holoscan and D555
- Integrate power telemetry to monitor draw per device

---

## Optional: Re-address the GO2 to the LAN
If you prefer a single subnet for everything, change GO2 to `192.168.10.2/24`. Update Thor to **only** `192.168.10.3/24` and remove the secondary IP. This simplifies routing but diverges from factory defaults.

---

## Quick Checklists

### Router (GL‑SFT1200)
- [ ] Access Point / Bridge mode
- [ ] IP `192.168.10.1`
- [ ] DHCP off
- [ ] WAN port bridged to LAN

### Thor
- [ ] `eth0` → `192.168.10.3/24`
- [ ] Add `192.168.123.10/24` alias (if GO2 remains factory subnet)
- [ ] `chrony` or `ptp4l` enabled

### D555 Variant
- [ ] PD→PoE+ injector inline, Cat6 to D555
- [ ] D555 static IP `192.168.10.4`
- [ ] Verify `ping`, `rs-enumerate-devices`, ROS 2 topics

### DreamVu Variant
- [ ] USB3 cable direct to Thor (or powered hub)
- [ ] PAL SDK (CUDA build) installed
- [ ] ROS 2 node publishes `/pal/image_raw`, `/pal/depth`, `/pal/point_cloud`

---

## Verification Commands
```bash
# Connectivity
ping -c 3 192.168.10.1    # Router
ping -c 3 192.168.10.4    # (D555 variant)
ping -c 3 192.168.123.161 # GO2

# Throughput (install iperf3)
iperf3 -s  # on Thor
iperf3 -c 192.168.10.3 -t 15  # from another host

# ROS 2 topic sanity (D555 example)
ros2 topic list | grep realsense

# ROS 2 topic sanity (PAL example)
ros2 topic list | grep /pal/
```

---

*End of doc — configurations validated against D555 Datasheet v1.1, DreamVu PAL SDK documentation, and Unitree GO2 specifications.*

## Validation
- [ ] Each hardware configuration tested with power bank and router
- [ ] Network connectivity verified (ping, iperf3)
- [ ] Sensor streaming validated (RealSense SDK, DreamVu ROS 2 nodes)
- [ ] Time synchronization tested (chrony/PTP)
- [ ] Documentation reviewed for accuracy against current hardware

## See Also
- [[networking/README|Networking Documentation]] — DDS configuration and connectivity testing
- [[hardware/omni_vision_exploration|360° Vision Options]] — Comprehensive sensor comparison
- [[hardware/omni_vision_sensor_setup|Omni Vision Setup]] — Additional sensor integration notes
- [[networking/dds_direct_test|DDS Direct Test]] — ROS 2 DDS connectivity validation

## References
- [[hardware/README|Hardware Stack Overview]]
- [[../index|Documentation Index]]
- RealSense D555 Datasheet v1.1 (Power over Ethernet 802.3at, Gigabit, DDS support)
- DreamVu PAL SDK: https://dreamvu.com/support/
- Unitree GO2 Documentation: Factory IP 192.168.123.161, Xavier Backpack 192.168.123.18
- GL.iNet GL-SFT1200 User Manual: AP/Bridge mode configuration

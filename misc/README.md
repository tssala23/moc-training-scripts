# Misc

Sub effort to understand the impacts of containerization on basic network 
performance outside of training

## Basic hardware

The systems we are working are 
[Lenovo SD665-N servers](https://lenovopress.lenovo.com/lp1613-thinksystem-sd665-n-v3-server)
. We think the following diagrams are key to understanding the performance

![block socket diagram](https://lenovopress.lenovo.com/assets/images/LP1613/SD665-N%20V3%20block%20diagram%202-socket.png)



### NUMA CPU affinity

Display numa details

`lscpu --extended` 

### PCI 

#### Devices

``` bash
sh-5.1# lspci
00:00.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14a4 (rev 01)
00:00.2 IOMMU: Advanced Micro Devices, Inc. [AMD] Device 149e (rev 01)
00:00.3 Generic system peripheral [0807]: Advanced Micro Devices, Inc. [AMD] Device 14a6
00:01.0 Host bridge: Lenovo Device 781d (rev 01)
00:01.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01)
00:02.0 Host bridge: Lenovo Device 781d (rev 01)
00:03.0 Host bridge: Lenovo Device 781d (rev 01)
00:04.0 Host bridge: Lenovo Device 781d (rev 01)
00:05.0 Host bridge: Lenovo Device 781d (rev 01)
00:05.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14aa (rev 01)
00:07.0 Host bridge: Lenovo Device 781d (rev 01)
00:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01)
00:14.0 SMBus: Advanced Micro Devices, Inc. [AMD] FCH SMBus Controller (rev 71)
00:14.3 ISA bridge: Advanced Micro Devices, Inc. [AMD] FCH LPC Bridge (rev 51)
00:18.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14ad
00:18.1 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14ae
00:18.2 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14af
00:18.3 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14b0
00:18.4 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14b1
00:18.5 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14b2
00:18.6 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14b3
00:18.7 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14b4
00:19.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14ad
00:19.1 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14ae
00:19.2 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14af
00:19.3 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14b0
00:19.4 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14b1
00:19.5 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14b2
00:19.6 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14b3
00:19.7 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14b4
01:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
02:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
02:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
03:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
04:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
05:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
06:00.0 3D controller: NVIDIA Corporation GH100 [H100 SXM5 80GB] (rev a1)
07:00.0 Ethernet controller: Intel Corporation I210 Gigabit Network Connection (rev 03)
08:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Device 14ac (rev 01)
08:00.1 System peripheral: Advanced Micro Devices, Inc. [AMD] Device 14dc
08:00.4 USB controller: Advanced Micro Devices, Inc. [AMD] Device 14c9 (rev da)
08:00.5 Encryption controller: Advanced Micro Devices, Inc. [AMD] Genoa CCP/PSP 4.0 Device
20:00.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14a4 (rev 01)
20:00.2 IOMMU: Advanced Micro Devices, Inc. [AMD] Device 149e (rev 01)
20:00.3 Generic system peripheral [0807]: Advanced Micro Devices, Inc. [AMD] Device 14a6
20:01.0 Host bridge: Lenovo Device 781d (rev 01)
20:01.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01)
20:02.0 Host bridge: Lenovo Device 781d (rev 01)
20:03.0 Host bridge: Lenovo Device 781d (rev 01)
20:04.0 Host bridge: Lenovo Device 781d (rev 01)
20:05.0 Host bridge: Lenovo Device 781d (rev 01)
20:07.0 Host bridge: Lenovo Device 781d (rev 01)
20:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01)
21:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
22:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
22:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
23:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
24:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
25:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
26:00.0 3D controller: NVIDIA Corporation GH100 [H100 SXM5 80GB] (rev a1)
27:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Device 14ac (rev 01)
27:00.1 System peripheral: Advanced Micro Devices, Inc. [AMD] Device 14dc
40:00.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14a4 (rev 01)
40:00.2 IOMMU: Advanced Micro Devices, Inc. [AMD] Device 149e (rev 01)
40:00.3 Generic system peripheral [0807]: Advanced Micro Devices, Inc. [AMD] Device 14a6
40:01.0 Host bridge: Lenovo Device 781d (rev 01)
40:01.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01)
40:01.3 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01)
40:02.0 Host bridge: Lenovo Device 781d (rev 01)
40:03.0 Host bridge: Lenovo Device 781d (rev 01)
40:04.0 Host bridge: Lenovo Device 781d (rev 01)
40:05.0 Host bridge: Lenovo Device 781d (rev 01)
40:07.0 Host bridge: Lenovo Device 781d (rev 01)
40:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01)
41:00.0 Non-Volatile memory controller: Micron Technology Inc 7450 PRO NVMe SSD (rev 01)
42:00.0 Ethernet controller: Mellanox Technologies MT2894 Family [ConnectX-6 Lx]
42:00.1 Ethernet controller: Mellanox Technologies MT2894 Family [ConnectX-6 Lx]
43:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Device 14ac (rev 01)
43:00.1 System peripheral: Advanced Micro Devices, Inc. [AMD] Device 14dc
60:00.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14a4 (rev 01)
60:00.2 IOMMU: Advanced Micro Devices, Inc. [AMD] Device 149e (rev 01)
60:00.3 Generic system peripheral [0807]: Advanced Micro Devices, Inc. [AMD] Device 14a6
60:01.0 Host bridge: Lenovo Device 781d (rev 01)
60:01.2 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01)
60:01.3 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01)
60:02.0 Host bridge: Lenovo Device 781d (rev 01)
60:03.0 Host bridge: Lenovo Device 781d (rev 01)
60:04.0 Host bridge: Lenovo Device 781d (rev 01)
60:05.0 Host bridge: Lenovo Device 781d (rev 01)
60:05.3 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14aa (rev 01)
60:07.0 Host bridge: Lenovo Device 781d (rev 01)
60:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01)
61:00.0 Non-Volatile memory controller: Samsung Electronics Co Ltd NVMe SSD Controller PM174X
63:00.0 PCI bridge: ASPEED Technology, Inc. AST1150 PCI-to-PCI Bridge (rev 06)
64:00.0 VGA compatible controller: ASPEED Technology, Inc. ASPEED Graphics Family (rev 52)
65:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Device 14ac (rev 01)
65:00.1 System peripheral: Advanced Micro Devices, Inc. [AMD] Device 14dc
65:00.4 USB controller: Advanced Micro Devices, Inc. [AMD] Device 14c9 (rev da)
80:00.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14a4 (rev 01)
80:00.2 IOMMU: Advanced Micro Devices, Inc. [AMD] Device 149e (rev 01)
80:00.3 Generic system peripheral [0807]: Advanced Micro Devices, Inc. [AMD] Device 14a6
80:01.0 Host bridge: Lenovo Device 781d (rev 01)
80:02.0 Host bridge: Lenovo Device 781d (rev 01)
80:03.0 Host bridge: Lenovo Device 781d (rev 01)
80:04.0 Host bridge: Lenovo Device 781d (rev 01)
80:05.0 Host bridge: Lenovo Device 781d (rev 01)
80:07.0 Host bridge: Lenovo Device 781d (rev 01)
80:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01)
81:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Device 14ac (rev 01)
81:00.1 System peripheral: Advanced Micro Devices, Inc. [AMD] Device 14dc
81:00.5 Encryption controller: Advanced Micro Devices, Inc. [AMD] Genoa CCP/PSP 4.0 Device
a0:00.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14a4 (rev 01)
a0:00.2 IOMMU: Advanced Micro Devices, Inc. [AMD] Device 149e (rev 01)
a0:00.3 Generic system peripheral [0807]: Advanced Micro Devices, Inc. [AMD] Device 14a6
a0:01.0 Host bridge: Lenovo Device 781d (rev 01)
a0:01.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01)
a0:02.0 Host bridge: Lenovo Device 781d (rev 01)
a0:03.0 Host bridge: Lenovo Device 781d (rev 01)
a0:04.0 Host bridge: Lenovo Device 781d (rev 01)
a0:05.0 Host bridge: Lenovo Device 781d (rev 01)
a0:07.0 Host bridge: Lenovo Device 781d (rev 01)
a0:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01)
a1:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
a2:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
a2:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
a3:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
a4:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
a5:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
a6:00.0 3D controller: NVIDIA Corporation GH100 [H100 SXM5 80GB] (rev a1)
a7:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Device 14ac (rev 01)
a7:00.1 System peripheral: Advanced Micro Devices, Inc. [AMD] Device 14dc
c0:00.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14a4 (rev 01)
c0:00.2 IOMMU: Advanced Micro Devices, Inc. [AMD] Device 149e (rev 01)
c0:00.3 Generic system peripheral [0807]: Advanced Micro Devices, Inc. [AMD] Device 14a6
c0:01.0 Host bridge: Lenovo Device 781d (rev 01)
c0:01.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01)
c0:02.0 Host bridge: Lenovo Device 781d (rev 01)
c0:03.0 Host bridge: Lenovo Device 781d (rev 01)
c0:04.0 Host bridge: Lenovo Device 781d (rev 01)
c0:05.0 Host bridge: Lenovo Device 781d (rev 01)
c0:07.0 Host bridge: Lenovo Device 781d (rev 01)
c0:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01)
c1:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
c2:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
c2:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
c3:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
c4:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
c5:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
c6:00.0 3D controller: NVIDIA Corporation GH100 [H100 SXM5 80GB] (rev a1)
c7:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Device 14ac (rev 01)
c7:00.1 System peripheral: Advanced Micro Devices, Inc. [AMD] Device 14dc
e0:00.0 Host bridge: Advanced Micro Devices, Inc. [AMD] Device 14a4 (rev 01)
e0:00.2 IOMMU: Advanced Micro Devices, Inc. [AMD] Device 149e (rev 01)
e0:00.3 Generic system peripheral [0807]: Advanced Micro Devices, Inc. [AMD] Device 14a6
e0:01.0 Host bridge: Lenovo Device 781d (rev 01)
e0:02.0 Host bridge: Lenovo Device 781d (rev 01)
e0:03.0 Host bridge: Lenovo Device 781d (rev 01)
e0:04.0 Host bridge: Lenovo Device 781d (rev 01)
e0:05.0 Host bridge: Lenovo Device 781d (rev 01)
e0:07.0 Host bridge: Lenovo Device 781d (rev 01)
e0:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01)
e1:00.0 Non-Essential Instrumentation [1300]: Advanced Micro Devices, Inc. [AMD] Device 14ac (rev 01)
e1:00.1 System peripheral: Advanced Micro Devices, Inc. [AMD] Device 14dc
```

##### NICS

On page 28 of this [nvidia connectx-7 manual](https://docs.nvidia.com/nvidia-connectx-7-adapter-cards-user-manual.pdf)
it tells us to do the following to identify our nics:

``` bash
$ occon node/mocr4pcc02u31 -- lspci |grep mellanox -i
Starting pod/mocr4pcc02u31-debug-7vzkw ...
To use host binaries, run `chroot /host`
01:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
02:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
02:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
03:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
04:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
05:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
21:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
22:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
22:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
23:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
24:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
25:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
42:00.0 Ethernet controller: Mellanox Technologies MT2894 Family [ConnectX-6 Lx]
42:00.1 Ethernet controller: Mellanox Technologies MT2894 Family [ConnectX-6 Lx]
a1:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
a2:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
a2:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
a3:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
a4:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
a5:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
c1:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
c2:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
c2:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
c3:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
c4:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
c5:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge]
```

Ok greping out for controller we get

``` bash
$ occon node/mocr4pcc02u31 -- lspci |grep mellanox -i | grep controller
Starting pod/mocr4pcc02u31-debug-sc9qv ...
To use host binaries, run `chroot /host`

Removing debug pod ...
03:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
23:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
42:00.0 Ethernet controller: Mellanox Technologies MT2894 Family [ConnectX-6 Lx]
42:00.1 Ethernet controller: Mellanox Technologies MT2894 Family [ConnectX-6 Lx]
a3:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
c3:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
$ 
```

This means we do indeed have four MT2910 ConnectX-7 controllers. According to
the manual this is a 4 "card" "Single-port Socket Direct Card (2x PCIe x16) 
ConnectX-7 Card Configuration.

``` 
03:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
23:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
a3:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
c3:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
```

I assume this each card has its own "slot" 03,23,a3,c3

##### CX-7 detail and speeds

According to this [Intel Manual](https://www.intel.com/content/www/us/en/docs/programmable/683501/22-4-8-0-0/using-lspci-utility-to-read-negotiated.html)
We can run this to determine the negotiated speed of a NIC and see details

``` bash
sh-5.1# lspci | grep -i 'controller.*MT2910' | while read bdf rest; do lspci -s $bdf -vvv; done
03:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
	DeviceName: Nvidia 4-chip VPI CX7 - 1
	Subsystem: Mellanox Technologies Device 0055
	Control: I/O- Mem+ BusMaster+ SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx+
	Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort- >SERR- <PERR- INTx-
	Latency: 0, Cache Line Size: 64 bytes
	Interrupt: pin A routed to IRQ 702
	NUMA node: 0
	IOMMU group: 39
	Region 0: Memory at 38044000000 (64-bit, prefetchable) [size=32M]
	Expansion ROM at f6800000 [disabled] [size=1M]
	Capabilities: [60] Express (v2) Endpoint, MSI 00
		DevCap:	MaxPayload 512 bytes, PhantFunc 0, Latency L0s unlimited, L1 unlimited
			ExtTag+ AttnBtn- AttnInd- PwrInd- RBE+ FLReset+ SlotPowerLimit 0.000W
		DevCtl:	CorrErr- NonFatalErr+ FatalErr+ UnsupReq-
			RlxdOrd+ ExtTag+ PhantFunc- AuxPwr- NoSnoop+ FLReset-
			MaxPayload 256 bytes, MaxReadReq 512 bytes
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
			ClockPM- Surprise- LLActRep- BwNot- ASPMOptComp+
		LnkCtl:	ASPM Disabled; RCB 64 bytes, Disabled- CommClk+
			ExtSynch- ClockPM- AutWidDis- BWInt- AutBWInt-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
			TrErr- Train- SlotClk+ DLActive- BWMgmt- ABWMgmt-
		DevCap2: Completion Timeout: Range ABC, TimeoutDis+ NROPrPrP- LTR-
			 10BitTagComp+ 10BitTagReq+ OBFF Not Supported, ExtFmt- EETLPPrefix-
			 EmergencyPowerReduction Not Supported, EmergencyPowerReductionInit-
			 FRS- TPHComp- ExtTPHComp-
			 AtomicOpsCap: 32bit- 64bit- 128bitCAS-
		DevCtl2: Completion Timeout: 50us to 50ms, TimeoutDis- LTR- OBFF Disabled,
			 AtomicOpsCtl: ReqEn-
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCtl2: Target Link Speed: 32GT/s, EnterCompliance- SpeedDis-
			 Transmit Margin: Normal Operating Range, EnterModifiedCompliance- ComplianceSOS-
			 Compliance De-emphasis: -6dB
		LnkSta2: Current De-emphasis Level: -6dB, EqualizationComplete+ EqualizationPhase1+
			 EqualizationPhase2+ EqualizationPhase3+ LinkEqualizationRequest-
			 Retimer- 2Retimers- CrosslinkRes: unsupported
	Capabilities: [48] Vital Product Data
		Product Name: Nvidia ConnectX-7 4-chip VPI PCIe Gen5 Mezz Controller
		Read-only fields:
			[PN] Part number: SN37B23797
			[V2] Vendor specific: 03KH787
			[SN] Serial number: X1LM37Z004B
			[V3] Vendor specific: 225918281035ee118000a088c227c450
			[MN] Manufacture ID: A3
			[VA] Vendor specific: LNV:MODL=MCX750500B-0D00:CNLY=23:PKTY=9:PHTY=32779:MN=LNV:CSKU=V2:UUID=V3
			[V0] Vendor specific: Nvidia ConnectX-7 4-chip VPI PCIe Gen5 Mezz Controller
			[VU] Vendor specific: X1LM37Z004BMLNXS0D0F0 
			[RV] Reserved: checksum good, 3 byte(s) reserved
		End
	Capabilities: [9c] MSI-X: Enable+ Count=64 Masked-
		Vector table: BAR=0 offset=00002000
		PBA: BAR=0 offset=00003000
	Capabilities: [c0] Vendor Specific Information: Len=18 <?>
	Capabilities: [40] Power Management version 3
		Flags: PMEClk- DSI- D1- D2- AuxCurrent=375mA PME(D0-,D1-,D2-,D3hot-,D3cold+)
		Status: D0 NoSoftRst+ PME-Enable- DSel=0 DScale=0 PME-
	Capabilities: [100 v1] Advanced Error Reporting
		UESta:	DLP- SDES- TLP- FCP- CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP- ECRC- UnsupReq- ACSViol-
		UEMsk:	DLP- SDES- TLP- FCP- CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP- ECRC- UnsupReq- ACSViol-
		UESvrt:	DLP+ SDES- TLP- FCP+ CmpltTO- CmpltAbrt- UnxCmplt- RxOF+ MalfTLP+ ECRC- UnsupReq- ACSViol-
		CESta:	RxErr- BadTLP- BadDLLP- Rollover- Timeout- AdvNonFatalErr-
		CEMsk:	RxErr- BadTLP- BadDLLP- Rollover- Timeout- AdvNonFatalErr+
		AERCap:	First Error Pointer: 04, ECRCGenCap+ ECRCGenEn- ECRCChkCap+ ECRCChkEn-
			MultHdrRecCap- MultHdrRecEn- TLPPfxPres- HdrLogCap-
		HeaderLog: 00000000 00000000 00000000 00000000
	Capabilities: [150 v1] Alternative Routing-ID Interpretation (ARI)
		ARICap:	MFVC- ACS-, Next Function: 0
		ARICtl:	MFVC- ACS-, Function Group: 0
	Capabilities: [180 v1] Single Root I/O Virtualization (SR-IOV)
		IOVCap:	Migration-, Interrupt Message Number: 000
		IOVCtl:	Enable- Migration- Interrupt- MSE- ARIHierarchy+
		IOVSta:	Migration-
		Initial VFs: 16, Total VFs: 16, Number of VFs: 0, Function Dependency Link: 00
		VF offset: 1, stride: 1, Device ID: 101e
		Supported Page Size: 000007ff, System Page Size: 00000001
		Region 0: Memory at 0000038046000000 (64-bit, prefetchable)
		VF Migration: offset: 00000000, BIR: 0
	Capabilities: [1c0 v1] Secondary PCI Express
		LnkCtl3: LnkEquIntrruptEn- PerformEqu-
		LaneErrStat: 0
	Capabilities: [320 v1] Lane Margining at the Receiver <?>
	Capabilities: [370 v1] Physical Layer 16.0 GT/s <?>
	Capabilities: [3b0 v1] Extended Capability ID 0x2a
	Capabilities: [420 v1] Data Link Feature <?>
	Kernel driver in use: mlx5_core
lspci: Unable to load libkmod resources: error -2

23:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
	DeviceName: Nvidia 4-chip VPI CX7 - 2
	Subsystem: Mellanox Technologies Device 0055
	Control: I/O- Mem+ BusMaster+ SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx+
	Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort- >SERR- <PERR- INTx-
	Latency: 0, Cache Line Size: 64 bytes
	Interrupt: pin A routed to IRQ 637
	NUMA node: 0
	IOMMU group: 55
	Region 0: Memory at 48044000000 (64-bit, prefetchable) [size=32M]
	Expansion ROM at c4800000 [disabled] [size=1M]
	Capabilities: [60] Express (v2) Endpoint, MSI 00
		DevCap:	MaxPayload 512 bytes, PhantFunc 0, Latency L0s unlimited, L1 unlimited
			ExtTag+ AttnBtn- AttnInd- PwrInd- RBE+ FLReset+ SlotPowerLimit 0.000W
		DevCtl:	CorrErr- NonFatalErr+ FatalErr+ UnsupReq-
			RlxdOrd+ ExtTag+ PhantFunc- AuxPwr- NoSnoop+ FLReset-
			MaxPayload 256 bytes, MaxReadReq 512 bytes
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
			ClockPM- Surprise- LLActRep- BwNot- ASPMOptComp+
		LnkCtl:	ASPM Disabled; RCB 64 bytes, Disabled- CommClk+
			ExtSynch- ClockPM- AutWidDis- BWInt- AutBWInt-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
			TrErr- Train- SlotClk+ DLActive- BWMgmt- ABWMgmt-
		DevCap2: Completion Timeout: Range ABC, TimeoutDis+ NROPrPrP- LTR-
			 10BitTagComp+ 10BitTagReq+ OBFF Not Supported, ExtFmt- EETLPPrefix-
			 EmergencyPowerReduction Not Supported, EmergencyPowerReductionInit-
			 FRS- TPHComp- ExtTPHComp-
			 AtomicOpsCap: 32bit- 64bit- 128bitCAS-
		DevCtl2: Completion Timeout: 50us to 50ms, TimeoutDis- LTR- OBFF Disabled,
			 AtomicOpsCtl: ReqEn-
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCtl2: Target Link Speed: 32GT/s, EnterCompliance- SpeedDis-
			 Transmit Margin: Normal Operating Range, EnterModifiedCompliance- ComplianceSOS-
			 Compliance De-emphasis: -6dB
		LnkSta2: Current De-emphasis Level: -6dB, EqualizationComplete+ EqualizationPhase1+
			 EqualizationPhase2+ EqualizationPhase3+ LinkEqualizationRequest-
			 Retimer- 2Retimers- CrosslinkRes: unsupported
	Capabilities: [48] Vital Product Data
		Product Name: Nvidia ConnectX-7 4-chip VPI PCIe Gen5 Mezz Controller
		Read-only fields:
			[PN] Part number: SN37B23797
			[V2] Vendor specific: 03KH787
			[SN] Serial number: X1LM37Z004B
			[V3] Vendor specific: 225918281035ee118000a088c227c450
			[MN] Manufacture ID: A3
			[VA] Vendor specific: LNV:MODL=MCX750500B-0D00:CNLY=23:PKTY=9:PHTY=32779:MN=LNV:CSKU=V2:UUID=V3
			[V0] Vendor specific: Nvidia ConnectX-7 4-chip VPI PCIe Gen5 Mezz Controller
			[VU] Vendor specific: X1LM37Z004BMLNXS0D0F0 
			[RV] Reserved: checksum good, 3 byte(s) reserved
		End
	Capabilities: [9c] MSI-X: Enable+ Count=64 Masked-
		Vector table: BAR=0 offset=00002000
		PBA: BAR=0 offset=00003000
	Capabilities: [c0] Vendor Specific Information: Len=18 <?>
	Capabilities: [40] Power Management version 3
		Flags: PMEClk- DSI- D1- D2- AuxCurrent=375mA PME(D0-,D1-,D2-,D3hot-,D3cold+)
		Status: D0 NoSoftRst+ PME-Enable- DSel=0 DScale=0 PME-
	Capabilities: [100 v1] Advanced Error Reporting
		UESta:	DLP- SDES- TLP- FCP- CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP- ECRC- UnsupReq- ACSViol-
		UEMsk:	DLP- SDES- TLP- FCP- CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP- ECRC- UnsupReq- ACSViol-
		UESvrt:	DLP+ SDES- TLP- FCP+ CmpltTO- CmpltAbrt- UnxCmplt- RxOF+ MalfTLP+ ECRC- UnsupReq- ACSViol-
		CESta:	RxErr- BadTLP- BadDLLP- Rollover- Timeout- AdvNonFatalErr-
		CEMsk:	RxErr- BadTLP- BadDLLP- Rollover- Timeout- AdvNonFatalErr+
		AERCap:	First Error Pointer: 04, ECRCGenCap+ ECRCGenEn- ECRCChkCap+ ECRCChkEn-
			MultHdrRecCap- MultHdrRecEn- TLPPfxPres- HdrLogCap-
		HeaderLog: 00000000 00000000 00000000 00000000
	Capabilities: [150 v1] Alternative Routing-ID Interpretation (ARI)
		ARICap:	MFVC- ACS-, Next Function: 0
		ARICtl:	MFVC- ACS-, Function Group: 0
	Capabilities: [180 v1] Single Root I/O Virtualization (SR-IOV)
		IOVCap:	Migration-, Interrupt Message Number: 000
		IOVCtl:	Enable- Migration- Interrupt- MSE- ARIHierarchy+
		IOVSta:	Migration-
		Initial VFs: 16, Total VFs: 16, Number of VFs: 0, Function Dependency Link: 00
		VF offset: 1, stride: 1, Device ID: 101e
		Supported Page Size: 000007ff, System Page Size: 00000001
		Region 0: Memory at 0000048046000000 (64-bit, prefetchable)
		VF Migration: offset: 00000000, BIR: 0
	Capabilities: [1c0 v1] Secondary PCI Express
		LnkCtl3: LnkEquIntrruptEn- PerformEqu-
		LaneErrStat: 0
	Capabilities: [320 v1] Lane Margining at the Receiver <?>
	Capabilities: [370 v1] Physical Layer 16.0 GT/s <?>
	Capabilities: [3b0 v1] Extended Capability ID 0x2a
	Capabilities: [420 v1] Data Link Feature <?>
	Kernel driver in use: mlx5_core
lspci: Unable to load libkmod resources: error -2

a3:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
	DeviceName: Nvidia 4-chip VPI CX7 - 3
	Subsystem: Mellanox Technologies Device 0055
	Control: I/O- Mem+ BusMaster+ SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx+
	Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort- >SERR- <PERR- INTx-
	Latency: 0, Cache Line Size: 64 bytes
	Interrupt: pin A routed to IRQ 832
	NUMA node: 1
	IOMMU group: 99
	Region 0: Memory at 78044000000 (64-bit, prefetchable) [size=32M]
	Expansion ROM at b0800000 [disabled] [size=1M]
	Capabilities: [60] Express (v2) Endpoint, MSI 00
		DevCap:	MaxPayload 512 bytes, PhantFunc 0, Latency L0s unlimited, L1 unlimited
			ExtTag+ AttnBtn- AttnInd- PwrInd- RBE+ FLReset+ SlotPowerLimit 0.000W
		DevCtl:	CorrErr- NonFatalErr+ FatalErr+ UnsupReq-
			RlxdOrd+ ExtTag+ PhantFunc- AuxPwr- NoSnoop+ FLReset-
			MaxPayload 256 bytes, MaxReadReq 512 bytes
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
			ClockPM- Surprise- LLActRep- BwNot- ASPMOptComp+
		LnkCtl:	ASPM Disabled; RCB 64 bytes, Disabled- CommClk+
			ExtSynch- ClockPM- AutWidDis- BWInt- AutBWInt-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
			TrErr- Train- SlotClk+ DLActive- BWMgmt- ABWMgmt-
		DevCap2: Completion Timeout: Range ABC, TimeoutDis+ NROPrPrP- LTR-
			 10BitTagComp+ 10BitTagReq+ OBFF Not Supported, ExtFmt- EETLPPrefix-
			 EmergencyPowerReduction Not Supported, EmergencyPowerReductionInit-
			 FRS- TPHComp- ExtTPHComp-
			 AtomicOpsCap: 32bit- 64bit- 128bitCAS-
		DevCtl2: Completion Timeout: 50us to 50ms, TimeoutDis- LTR- OBFF Disabled,
			 AtomicOpsCtl: ReqEn-
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCtl2: Target Link Speed: 32GT/s, EnterCompliance- SpeedDis-
			 Transmit Margin: Normal Operating Range, EnterModifiedCompliance- ComplianceSOS-
			 Compliance De-emphasis: -6dB
		LnkSta2: Current De-emphasis Level: -6dB, EqualizationComplete+ EqualizationPhase1+
			 EqualizationPhase2+ EqualizationPhase3+ LinkEqualizationRequest-
			 Retimer- 2Retimers- CrosslinkRes: unsupported
	Capabilities: [48] Vital Product Data
		Product Name: Nvidia ConnectX-7 4-chip VPI PCIe Gen5 Mezz Controller
		Read-only fields:
			[PN] Part number: SN37B23797
			[V2] Vendor specific: 03KH787
			[SN] Serial number: X1LM37Z004B
			[V3] Vendor specific: 225918281035ee118000a088c227c450
			[MN] Manufacture ID: A3
			[VA] Vendor specific: LNV:MODL=MCX750500B-0D00:CNLY=23:PKTY=9:PHTY=32779:MN=LNV:CSKU=V2:UUID=V3
			[V0] Vendor specific: Nvidia ConnectX-7 4-chip VPI PCIe Gen5 Mezz Controller
			[VU] Vendor specific: X1LM37Z004BMLNXS0D0F0 
			[RV] Reserved: checksum good, 3 byte(s) reserved
		End
	Capabilities: [9c] MSI-X: Enable+ Count=64 Masked-
		Vector table: BAR=0 offset=00002000
		PBA: BAR=0 offset=00003000
	Capabilities: [c0] Vendor Specific Information: Len=18 <?>
	Capabilities: [40] Power Management version 3
		Flags: PMEClk- DSI- D1- D2- AuxCurrent=375mA PME(D0-,D1-,D2-,D3hot-,D3cold+)
		Status: D0 NoSoftRst+ PME-Enable- DSel=0 DScale=0 PME-
	Capabilities: [100 v1] Advanced Error Reporting
		UESta:	DLP- SDES- TLP- FCP- CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP- ECRC- UnsupReq- ACSViol-
		UEMsk:	DLP- SDES- TLP- FCP- CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP- ECRC- UnsupReq- ACSViol-
		UESvrt:	DLP+ SDES- TLP- FCP+ CmpltTO- CmpltAbrt- UnxCmplt- RxOF+ MalfTLP+ ECRC- UnsupReq- ACSViol-
		CESta:	RxErr- BadTLP- BadDLLP- Rollover- Timeout- AdvNonFatalErr-
		CEMsk:	RxErr- BadTLP- BadDLLP- Rollover- Timeout- AdvNonFatalErr+
		AERCap:	First Error Pointer: 04, ECRCGenCap+ ECRCGenEn- ECRCChkCap+ ECRCChkEn-
			MultHdrRecCap- MultHdrRecEn- TLPPfxPres- HdrLogCap-
		HeaderLog: 00000000 00000000 00000000 00000000
	Capabilities: [150 v1] Alternative Routing-ID Interpretation (ARI)
		ARICap:	MFVC- ACS-, Next Function: 0
		ARICtl:	MFVC- ACS-, Function Group: 0
	Capabilities: [180 v1] Single Root I/O Virtualization (SR-IOV)
		IOVCap:	Migration-, Interrupt Message Number: 000
		IOVCtl:	Enable- Migration- Interrupt- MSE- ARIHierarchy+
		IOVSta:	Migration-
		Initial VFs: 16, Total VFs: 16, Number of VFs: 0, Function Dependency Link: 00
		VF offset: 1, stride: 1, Device ID: 101e
		Supported Page Size: 000007ff, System Page Size: 00000001
		Region 0: Memory at 0000078046000000 (64-bit, prefetchable)
		VF Migration: offset: 00000000, BIR: 0
	Capabilities: [1c0 v1] Secondary PCI Express
		LnkCtl3: LnkEquIntrruptEn- PerformEqu-
		LaneErrStat: 0
	Capabilities: [320 v1] Lane Margining at the Receiver <?>
	Capabilities: [370 v1] Physical Layer 16.0 GT/s <?>
	Capabilities: [3b0 v1] Extended Capability ID 0x2a
	Capabilities: [420 v1] Data Link Feature <?>
	Kernel driver in use: mlx5_core
lspci: Unable to load libkmod resources: error -2

c3:00.0 Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]
	DeviceName: Nvidia 4-chip VPI CX7 - 4
	Subsystem: Mellanox Technologies Device 0055
	Control: I/O- Mem+ BusMaster+ SpecCycle- MemWINV- VGASnoop- ParErr- Stepping- SERR- FastB2B- DisINTx+
	Status: Cap+ 66MHz- UDF- FastB2B- ParErr- DEVSEL=fast >TAbort- <TAbort- <MAbort- >SERR- <PERR- INTx-
	Latency: 0, Cache Line Size: 64 bytes
	Interrupt: pin A routed to IRQ 767
	NUMA node: 1
	IOMMU group: 77
	Region 0: Memory at 60044000000 (64-bit, prefetchable) [size=32M]
	Expansion ROM at ba800000 [disabled] [size=1M]
	Capabilities: [60] Express (v2) Endpoint, MSI 00
		DevCap:	MaxPayload 512 bytes, PhantFunc 0, Latency L0s unlimited, L1 unlimited
			ExtTag+ AttnBtn- AttnInd- PwrInd- RBE+ FLReset+ SlotPowerLimit 0.000W
		DevCtl:	CorrErr- NonFatalErr+ FatalErr+ UnsupReq-
			RlxdOrd+ ExtTag+ PhantFunc- AuxPwr- NoSnoop+ FLReset-
			MaxPayload 256 bytes, MaxReadReq 512 bytes
		DevSta:	CorrErr- NonFatalErr- FatalErr- UnsupReq- AuxPwr- TransPend-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
			ClockPM- Surprise- LLActRep- BwNot- ASPMOptComp+
		LnkCtl:	ASPM Disabled; RCB 64 bytes, Disabled- CommClk+
			ExtSynch- ClockPM- AutWidDis- BWInt- AutBWInt-
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
			TrErr- Train- SlotClk+ DLActive- BWMgmt- ABWMgmt-
		DevCap2: Completion Timeout: Range ABC, TimeoutDis+ NROPrPrP- LTR-
			 10BitTagComp+ 10BitTagReq+ OBFF Not Supported, ExtFmt- EETLPPrefix-
			 EmergencyPowerReduction Not Supported, EmergencyPowerReductionInit-
			 FRS- TPHComp- ExtTPHComp-
			 AtomicOpsCap: 32bit- 64bit- 128bitCAS-
		DevCtl2: Completion Timeout: 50us to 50ms, TimeoutDis- LTR- OBFF Disabled,
			 AtomicOpsCtl: ReqEn-
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCtl2: Target Link Speed: 32GT/s, EnterCompliance- SpeedDis-
			 Transmit Margin: Normal Operating Range, EnterModifiedCompliance- ComplianceSOS-
			 Compliance De-emphasis: -6dB
		LnkSta2: Current De-emphasis Level: -6dB, EqualizationComplete+ EqualizationPhase1+
			 EqualizationPhase2+ EqualizationPhase3+ LinkEqualizationRequest-
			 Retimer- 2Retimers- CrosslinkRes: unsupported
	Capabilities: [48] Vital Product Data
		Product Name: Nvidia ConnectX-7 4-chip VPI PCIe Gen5 Mezz Controller
		Read-only fields:
			[PN] Part number: SN37B23797
			[V2] Vendor specific: 03KH787
			[SN] Serial number: X1LM37Z004B
			[V3] Vendor specific: 225918281035ee118000a088c227c450
			[MN] Manufacture ID: A3
			[VA] Vendor specific: LNV:MODL=MCX750500B-0D00:CNLY=23:PKTY=9:PHTY=32779:MN=LNV:CSKU=V2:UUID=V3
			[V0] Vendor specific: Nvidia ConnectX-7 4-chip VPI PCIe Gen5 Mezz Controller
			[VU] Vendor specific: X1LM37Z004BMLNXS0D0F0 
			[RV] Reserved: checksum good, 3 byte(s) reserved
		End
	Capabilities: [9c] MSI-X: Enable+ Count=64 Masked-
		Vector table: BAR=0 offset=00002000
		PBA: BAR=0 offset=00003000
	Capabilities: [c0] Vendor Specific Information: Len=18 <?>
	Capabilities: [40] Power Management version 3
		Flags: PMEClk- DSI- D1- D2- AuxCurrent=375mA PME(D0-,D1-,D2-,D3hot-,D3cold+)
		Status: D0 NoSoftRst+ PME-Enable- DSel=0 DScale=0 PME-
	Capabilities: [100 v1] Advanced Error Reporting
		UESta:	DLP- SDES- TLP- FCP- CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP- ECRC- UnsupReq- ACSViol-
		UEMsk:	DLP- SDES- TLP- FCP- CmpltTO- CmpltAbrt- UnxCmplt- RxOF- MalfTLP- ECRC- UnsupReq- ACSViol-
		UESvrt:	DLP+ SDES- TLP- FCP+ CmpltTO- CmpltAbrt- UnxCmplt- RxOF+ MalfTLP+ ECRC- UnsupReq- ACSViol-
		CESta:	RxErr- BadTLP- BadDLLP- Rollover- Timeout- AdvNonFatalErr-
		CEMsk:	RxErr- BadTLP- BadDLLP- Rollover- Timeout- AdvNonFatalErr+
		AERCap:	First Error Pointer: 04, ECRCGenCap+ ECRCGenEn- ECRCChkCap+ ECRCChkEn-
			MultHdrRecCap- MultHdrRecEn- TLPPfxPres- HdrLogCap-
		HeaderLog: 00000000 00000000 00000000 00000000
	Capabilities: [150 v1] Alternative Routing-ID Interpretation (ARI)
		ARICap:	MFVC- ACS-, Next Function: 0
		ARICtl:	MFVC- ACS-, Function Group: 0
	Capabilities: [180 v1] Single Root I/O Virtualization (SR-IOV)
		IOVCap:	Migration-, Interrupt Message Number: 000
		IOVCtl:	Enable- Migration- Interrupt- MSE- ARIHierarchy+
		IOVSta:	Migration-
		Initial VFs: 16, Total VFs: 16, Number of VFs: 0, Function Dependency Link: 00
		VF offset: 1, stride: 1, Device ID: 101e
		Supported Page Size: 000007ff, System Page Size: 00000001
		Region 0: Memory at 0000060046000000 (64-bit, prefetchable)
		VF Migration: offset: 00000000, BIR: 0
	Capabilities: [1c0 v1] Secondary PCI Express
		LnkCtl3: LnkEquIntrruptEn- PerformEqu-
		LaneErrStat: 0
	Capabilities: [320 v1] Lane Margining at the Receiver <?>
	Capabilities: [370 v1] Physical Layer 16.0 GT/s <?>
	Capabilities: [3b0 v1] Extended Capability ID 0x2a
	Capabilities: [420 v1] Data Link Feature <?>
	Kernel driver in use: mlx5_core
lspci: Unable to load libkmod resources: error -2
sh-5.1# 
```

To zoom in on the link capability and speeds 

``` bash
sh-5.1# lspci  | grep -i 'controller.*MT2910' | while read bdf rest; do lspci -s $bdf -vvv; done | grep -E 'LnkCap|LnkSta' 
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkSta2: Current De-emphasis Level: -6dB, EqualizationComplete+ EqualizationPhase1+
lspci: Unable to load libkmod resources: error -2
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkSta2: Current De-emphasis Level: -6dB, EqualizationComplete+ EqualizationPhase1+
lspci: Unable to load libkmod resources: error -2
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkSta2: Current De-emphasis Level: -6dB, EqualizationComplete+ EqualizationPhase1+
lspci: Unable to load libkmod resources: error -2
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkSta:	Speed 32GT/s (ok), Width x16 (ok)
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkSta2: Current De-emphasis Level: -6dB, EqualizationComplete+ EqualizationPhase1+
lspci: Unable to load libkmod resources: error -2
```

To understand the numa locality

``` bash
sh-5.1# lspci  | grep -i 'controller.*MT2910' | while read bdf rest; do echo $bdf $(lspci -s $bdf -vvv| grep -E -i 'Numa'); done 
lspci: Unable to load libkmod resources: error -2
03:00.0 NUMA node: 0
lspci: Unable to load libkmod resources: error -2
23:00.0 NUMA node: 0
lspci: Unable to load libkmod resources: error -2
a3:00.0 NUMA node: 1
lspci: Unable to load libkmod resources: error -2
c3:00.0 NUMA node: 1
```

#### Network interface to device details

wrote lsnic script that produces the following output 

``` bash
$ ocpods | dopods /root/lsnic | grep MT2910
if:eno6np0 type:pci mac:a0:88:c2:27:c2:d8 ipaddr:"" pciaddr:23:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno5np0 type:pci mac:a0:88:c2:27:c2:dc ipaddr:"" pciaddr:03:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno8np0 type:pci mac:a0:88:c2:27:c2:d0 ipaddr:"" pciaddr:c3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno7np0 type:pci mac:a0:88:c2:27:c2:d4 ipaddr:"192.168.50.119/24 169.254.0.2/17 fe80::a288:c2ff:fe27:c2d4/64" pciaddr:a3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno6np0 type:pci mac:a0:88:c2:27:c0:d8 ipaddr:"" pciaddr:23:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno5np0 type:pci mac:a0:88:c2:27:c0:dc ipaddr:"" pciaddr:03:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno8np0 type:pci mac:a0:88:c2:27:c0:d0 ipaddr:"" pciaddr:c3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno7np0 type:pci mac:a0:88:c2:27:c0:d4 ipaddr:"192.168.50.145/24 169.254.0.2/17 fe80::a288:c2ff:fe27:c0d4/64" pciaddr:a3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno6np0 type:pci mac:a0:88:c2:27:be:28 ipaddr:"" pciaddr:23:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno5np0 type:pci mac:a0:88:c2:27:be:2c ipaddr:"" pciaddr:03:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno8np0 type:pci mac:a0:88:c2:27:be:20 ipaddr:"" pciaddr:c3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno7np0 type:pci mac:a0:88:c2:27:be:24 ipaddr:"192.168.50.157/24 169.254.0.2/17 fe80::a288:c2ff:fe27:be24/64" pciaddr:a3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno6np0 type:pci mac:a0:88:c2:27:bb:d8 ipaddr:"" pciaddr:23:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno5np0 type:pci mac:a0:88:c2:27:bb:dc ipaddr:"" pciaddr:03:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno8np0 type:pci mac:a0:88:c2:27:bb:d0 ipaddr:"" pciaddr:c3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno7np0 type:pci mac:a0:88:c2:27:bb:d4 ipaddr:"192.168.50.18/24 169.254.0.2/17 fe80::a288:c2ff:fe27:bbd4/64" pciaddr:a3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno6np0 type:pci mac:a0:88:c2:27:c4:88 ipaddr:"" pciaddr:23:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno5np0 type:pci mac:a0:88:c2:27:c4:8c ipaddr:"" pciaddr:03:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno8np0 type:pci mac:a0:88:c2:27:c4:80 ipaddr:"" pciaddr:c3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno7np0 type:pci mac:a0:88:c2:27:c4:84 ipaddr:"192.168.50.171/24 169.254.0.2/17 192.168.50.251/32 fe80::a288:c2ff:fe27:c484/64" pciaddr:a3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno6np0 type:pci mac:a0:88:c2:27:c0:88 ipaddr:"" pciaddr:23:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno5np0 type:pci mac:a0:88:c2:27:c0:8c ipaddr:"" pciaddr:03:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno8np0 type:pci mac:a0:88:c2:27:c0:80 ipaddr:"" pciaddr:c3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno7np0 type:pci mac:a0:88:c2:27:c0:84 ipaddr:"192.168.50.57/24 169.254.0.2/17 fe80::a288:c2ff:fe27:c084/64" pciaddr:a3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno6np0 type:pci mac:a0:88:c2:27:c4:58 ipaddr:"" pciaddr:23:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno5np0 type:pci mac:a0:88:c2:27:c4:5c ipaddr:"" pciaddr:03:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno8np0 type:pci mac:a0:88:c2:27:c4:50 ipaddr:"" pciaddr:c3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno7np0 type:pci mac:a0:88:c2:27:c4:54 ipaddr:"192.168.50.65/24 169.254.0.2/17 fe80::a288:c2ff:fe27:c454/64" pciaddr:a3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno6np0 type:pci mac:a0:88:c2:27:c5:68 ipaddr:"" pciaddr:23:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno5np0 type:pci mac:a0:88:c2:27:c5:6c ipaddr:"" pciaddr:03:00.0 link:UP ip:UP mtu:1500 numanode:0 cpulist:0-127,256-383 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno8np0 type:pci mac:a0:88:c2:27:c5:60 ipaddr:"" pciaddr:c3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
if:eno7np0 type:pci mac:a0:88:c2:27:c5:64 ipaddr:"192.168.50.153/24 169.254.0.2/17 fe80::a288:c2ff:fe27:c564/64" pciaddr:a3:00.0 link:UP ip:UP mtu:1500 numanode:1 cpulist:128-255,384-511 driver:mlx5_core dver:"28.37.1014" pcilnkspd:"32.0 GT/s PCIe" pcilnkwdth:16 pciinfo:"Ethernet controller: Mellanox Technologies MT2910 Family [ConnectX-7]"
```

#### Topology

``` bash
$ occon node/mocr4pcc02u31 -- lspci -t -vvv
Starting pod/mocr4pcc02u31-debug-p5btq ...
To use host binaries, run `chroot /host`
-+-[0000:e0]-+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14a4
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Device 149e
 |           +-00.3  Advanced Micro Devices, Inc. [AMD] Device 14a6
 |           +-01.0  Lenovo Device 781d
 |           +-02.0  Lenovo Device 781d
 |           +-03.0  Lenovo Device 781d
 |           +-04.0  Lenovo Device 781d
 |           +-05.0  Lenovo Device 781d
 |           +-07.0  Lenovo Device 781d
 |           \-07.1-[e1]--+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14ac
 |                        \-00.1  Advanced Micro Devices, Inc. [AMD] Device 14dc
 +-[0000:c0]-+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14a4
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Device 149e
 |           +-00.3  Advanced Micro Devices, Inc. [AMD] Device 14a6
 |           +-01.0  Lenovo Device 781d
 |           +-01.1-[c1-c6]----00.0-[c2-c6]--+-00.0-[c3]----00.0  Mellanox Technologies MT2910 Family [ConnectX-7]
 |           |                               \-02.0-[c4-c6]----00.0-[c5-c6]----00.0-[c6]----00.0  NVIDIA Corporation GH100 [H100 SXM5 80GB]
 |           +-02.0  Lenovo Device 781d
 |           +-03.0  Lenovo Device 781d
 |           +-04.0  Lenovo Device 781d
 |           +-05.0  Lenovo Device 781d
 |           +-07.0  Lenovo Device 781d
 |           \-07.1-[c7]--+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14ac
 |                        \-00.1  Advanced Micro Devices, Inc. [AMD] Device 14dc
 +-[0000:a0]-+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14a4
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Device 149e
 |           +-00.3  Advanced Micro Devices, Inc. [AMD] Device 14a6
 |           +-01.0  Lenovo Device 781d
 |           +-01.1-[a1-a6]----00.0-[a2-a6]--+-00.0-[a3]----00.0  Mellanox Technologies MT2910 Family [ConnectX-7]
 |           |                               \-02.0-[a4-a6]----00.0-[a5-a6]----00.0-[a6]----00.0  NVIDIA Corporation GH100 [H100 SXM5 80GB]
 |           +-02.0  Lenovo Device 781d
 |           +-03.0  Lenovo Device 781d
 |           +-04.0  Lenovo Device 781d
 |           +-05.0  Lenovo Device 781d
 |           +-07.0  Lenovo Device 781d
 |           \-07.1-[a7]--+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14ac
 |                        \-00.1  Advanced Micro Devices, Inc. [AMD] Device 14dc
 +-[0000:80]-+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14a4
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Device 149e
 |           +-00.3  Advanced Micro Devices, Inc. [AMD] Device 14a6
 |           +-01.0  Lenovo Device 781d
 |           +-02.0  Lenovo Device 781d
 |           +-03.0  Lenovo Device 781d
 |           +-04.0  Lenovo Device 781d
 |           +-05.0  Lenovo Device 781d
 |           +-07.0  Lenovo Device 781d
 |           \-07.1-[81]--+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14ac
 |                        +-00.1  Advanced Micro Devices, Inc. [AMD] Device 14dc
 |                        \-00.5  Advanced Micro Devices, Inc. [AMD] Genoa CCP/PSP 4.0 Device
 +-[0000:60]-+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14a4
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Device 149e
 |           +-00.3  Advanced Micro Devices, Inc. [AMD] Device 14a6
 |           +-01.0  Lenovo Device 781d
 |           +-01.2-[61]----00.0  Samsung Electronics Co Ltd NVMe SSD Controller PM174X
 |           +-01.3-[62]--
 |           +-02.0  Lenovo Device 781d
 |           +-03.0  Lenovo Device 781d
 |           +-04.0  Lenovo Device 781d
 |           +-05.0  Lenovo Device 781d
 |           +-05.3-[63-64]----00.0-[64]----00.0  ASPEED Technology, Inc. ASPEED Graphics Family
 |           +-07.0  Lenovo Device 781d
 |           \-07.1-[65]--+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14ac
 |                        +-00.1  Advanced Micro Devices, Inc. [AMD] Device 14dc
 |                        \-00.4  Advanced Micro Devices, Inc. [AMD] Device 14c9
 +-[0000:40]-+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14a4
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Device 149e
 |           +-00.3  Advanced Micro Devices, Inc. [AMD] Device 14a6
 |           +-01.0  Lenovo Device 781d
 |           +-01.1-[41]----00.0  Micron Technology Inc 7450 PRO NVMe SSD
 |           +-01.3-[42]--+-00.0  Mellanox Technologies MT2894 Family [ConnectX-6 Lx]
 |           |            \-00.1  Mellanox Technologies MT2894 Family [ConnectX-6 Lx]
 |           +-02.0  Lenovo Device 781d
 |           +-03.0  Lenovo Device 781d
 |           +-04.0  Lenovo Device 781d
 |           +-05.0  Lenovo Device 781d
 |           +-07.0  Lenovo Device 781d
 |           \-07.1-[43]--+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14ac
 |                        \-00.1  Advanced Micro Devices, Inc. [AMD] Device 14dc
 +-[0000:20]-+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14a4
 |           +-00.2  Advanced Micro Devices, Inc. [AMD] Device 149e
 |           +-00.3  Advanced Micro Devices, Inc. [AMD] Device 14a6
 |           +-01.0  Lenovo Device 781d
 |           +-01.1-[21-26]----00.0-[22-26]--+-00.0-[23]----00.0  Mellanox Technologies MT2910 Family [ConnectX-7]
 |           |                               \-02.0-[24-26]----00.0-[25-26]----00.0-[26]----00.0  NVIDIA Corporation GH100 [H100 SXM5 80GB]
 |           +-02.0  Lenovo Device 781d
 |           +-03.0  Lenovo Device 781d
 |           +-04.0  Lenovo Device 781d
 |           +-05.0  Lenovo Device 781d
 |           +-07.0  Lenovo Device 781d
 |           \-07.1-[27]--+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14ac
 |                        \-00.1  Advanced Micro Devices, Inc. [AMD] Device 14dc
 \-[0000:00]-+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14a4
             +-00.2  Advanced Micro Devices, Inc. [AMD] Device 149e
             +-00.3  Advanced Micro Devices, Inc. [AMD] Device 14a6
             +-01.0  Lenovo Device 781d
             +-01.1-[01-06]----00.0-[02-06]--+-00.0-[03]----00.0  Mellanox Technologies MT2910 Family [ConnectX-7]
             |                               \-02.0-[04-06]----00.0-[05-06]----00.0-[06]----00.0  NVIDIA Corporation GH100 [H100 SXM5 80GB]
             +-02.0  Lenovo Device 781d
             +-03.0  Lenovo Device 781d
             +-04.0  Lenovo Device 781d
             +-05.0  Lenovo Device 781d
             +-05.1-[07]----00.0  Intel Corporation I210 Gigabit Network Connection
             +-07.0  Lenovo Device 781d
             +-07.1-[08]--+-00.0  Advanced Micro Devices, Inc. [AMD] Device 14ac
             |            +-00.1  Advanced Micro Devices, Inc. [AMD] Device 14dc
             |            +-00.4  Advanced Micro Devices, Inc. [AMD] Device 14c9
             |            \-00.5  Advanced Micro Devices, Inc. [AMD] Genoa CCP/PSP 4.0 Device
             +-14.0  Advanced Micro Devices, Inc. [AMD] FCH SMBus Controller
             +-14.3  Advanced Micro Devices, Inc. [AMD] FCH LPC Bridge
             +-18.0  Advanced Micro Devices, Inc. [AMD] Device 14ad
             +-18.1  Advanced Micro Devices, Inc. [AMD] Device 14ae
             +-18.2  Advanced Micro Devices, Inc. [AMD] Device 14af
             +-18.3  Advanced Micro Devices, Inc. [AMD] Device 14b0
             +-18.4  Advanced Micro Devices, Inc. [AMD] Device 14b1
             +-18.5  Advanced Micro Devices, Inc. [AMD] Device 14b2
             +-18.6  Advanced Micro Devices, Inc. [AMD] Device 14b3
             +-18.7  Advanced Micro Devices, Inc. [AMD] Device 14b4
             +-19.0  Advanced Micro Devices, Inc. [AMD] Device 14ad
             +-19.1  Advanced Micro Devices, Inc. [AMD] Device 14ae
             +-19.2  Advanced Micro Devices, Inc. [AMD] Device 14af
             +-19.3  Advanced Micro Devices, Inc. [AMD] Device 14b0
             +-19.4  Advanced Micro Devices, Inc. [AMD] Device 14b1
             +-19.5  Advanced Micro Devices, Inc. [AMD] Device 14b2
             +-19.6  Advanced Micro Devices, Inc. [AMD] Device 14b3
             \-19.7  Advanced Micro Devices, Inc. [AMD] Device 14b4
```
#### GPU to NIC

Really usful juniper nvidia guide

- https://www.juniper.net/documentation/us/en/software/jvd/jvd-ai-dc-apstra-nvidia-weka/nvidia.html

`nvidia-smi topo -m`


![H100 NIC Topology](https://www.juniper.net/documentation/us/en/software/jvd/jvd-ai-dc-apstra-nvidia-weka/media/image55.png)

#### Speeds
Display pci bridge speeds

`lspci -vv | grep -E 'PCI bridge|LnkCap'`


``` shell
$ occon node/mocr4pcc02u31 -- lspci -vv | grep -E 'PCI bridge|LnkCap'
Starting pod/mocr4pcc02u31-debug-lm7mr ...
To use host binaries, run `chroot /host`
00:01.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L1, Exit Latency L1 <64us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
00:05.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14aa (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 2.5GT/s, Width x1, ASPM L1, Exit Latency L1 <64us
		LnkCap2: Supported Link Speeds: 2.5GT/s, Crosslink- Retimer- 2Retimers- DRS-
00:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
01:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
02:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #1, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
02:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #3, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
04:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
05:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #1, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L1, Exit Latency L1 <4us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 2.5GT/s, Width x1, ASPM L0s L1, Exit Latency L0s <2us, L1 <16us
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
20:01.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L1, Exit Latency L1 <64us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
20:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
21:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
22:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #1, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
22:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #3, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
24:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
25:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #1, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L1, Exit Latency L1 <4us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
40:01.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x4, ASPM L1, Exit Latency L1 <64us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
40:01.3 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #2, Speed 16GT/s, Width x4, ASPM L1, Exit Latency L1 <64us
		LnkCap2: Supported Link Speeds: 2.5-16GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
40:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 16GT/s, Width x4, ASPM L0s L1, Exit Latency L0s <256ns, L1 unlimited
		LnkCap2: Supported Link Speeds: 2.5-16GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 16GT/s, Width x8, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-16GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 16GT/s, Width x8, ASPM not supported
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
60:01.2 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #1, Speed 32GT/s, Width x4, ASPM L1, Exit Latency L1 <64us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
60:01.3 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #247, Speed 32GT/s, Width x4, ASPM L1, Exit Latency L1 <64us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
60:05.3 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14aa (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #2, Speed 8GT/s, Width x1, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-8GT/s, Crosslink- Retimer- 2Retimers- DRS-
60:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x4, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
63:00.0 PCI bridge: ASPEED Technology, Inc. AST1150 PCI-to-PCI Bridge (rev 06) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 5GT/s, Width x1, ASPM L0s L1, Exit Latency L0s <1us, L1 <64us
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
80:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
a0:01.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L1, Exit Latency L1 <64us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
a0:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
a1:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
a2:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #1, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
a2:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #3, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
a4:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
a5:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #1, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L1, Exit Latency L1 <4us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
c0:01.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14ab (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L1, Exit Latency L1 <64us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
c0:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
c1:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
c2:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #1, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
c2:02.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #3, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
c4:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
c5:00.0 PCI bridge: Mellanox Technologies MT2910 Family [ConnectX-7 PCIe Bridge] (prog-if 00 [Normal decode])
		LnkCap:	Port #1, Speed 32GT/s, Width x16, ASPM not supported
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer- 2Retimers- DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L1, Exit Latency L1 <4us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
e0:07.1 PCI bridge: Advanced Micro Devices, Inc. [AMD] Device 14a7 (rev 01) (prog-if 00 [Normal decode])
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
		LnkCap2: Supported Link Speeds: 2.5-32GT/s, Crosslink- Retimer+ 2Retimers+ DRS-

Removing debug pod ...
		LnkCap:	Port #0, Speed 32GT/s, Width x16, ASPM L0s L1, Exit Latency L0s <64ns, L1 <1us
$ 

```

## iperf3 testing

To do a reasonable job of exploring what can be achived within an 
openshift container vs baremetal access (no containerization -- 
baremetal networking and no namespaces).

References:

- https://downloads.es.net/public/iperf/iperf3.3.18.tar.gz
- https://software.es.net/iperf/invoking.html
- https://fasterdata.es.net/performance-testing/network-troubleshooting-tools/iperf/
 


### Source and building 

see src/doiperf3

### server flags

### client flags 

#### tcp

#### udp


### ociperf <name> <wrks|pods> [list]


# ESI Networking for H100 testing cluster (Barcelona)

``` shell
MOC-R4PCC02U15,a0:88:c2:27:c2:d0,swp16s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,192.168.208.15,rdma-net,999
MOC-R4PCC02U15,a0:88:c2:27:c2:d4,swp16s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,192.168.50.119,barcelona-net,581
MOC-R4PCC02U15,a0:88:c2:27:c2:d8,swp40s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U15,a0:88:c2:27:c2:dc,swp40s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U16,a0:88:c2:27:c0:d0,swp15s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U16,a0:88:c2:27:c0:d4,swp15s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,192.168.50.145,barcelona-net,581
MOC-R4PCC02U16,a0:88:c2:27:c0:d8,swp39s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U16,a0:88:c2:27:c0:dc,swp39s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U24,a0:88:c2:27:be:20,swp11s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U24,a0:88:c2:27:be:24,swp11s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,192.168.50.157,barcelona-net,581
MOC-R4PCC02U24,a0:88:c2:27:be:28,swp35s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U24,a0:88:c2:27:be:2c,swp35s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U25,a0:88:c2:27:bb:d0,swp10s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U25,a0:88:c2:27:bb:d4,swp10s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,192.168.50.18,barcelona-net,581
MOC-R4PCC02U25,a0:88:c2:27:bb:d8,swp34s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U25,a0:88:c2:27:bb:dc,swp34s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U29,a0:88:c2:27:c4:80,swp8s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U29,a0:88:c2:27:c4:84,swp8s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,192.168.50.171,barcelona-net,581
MOC-R4PCC02U29,a0:88:c2:27:c4:88,swp32s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U29,a0:88:c2:27:c4:8c,swp32s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U30,a0:88:c2:27:c0:80,swp7s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U30,a0:88:c2:27:c0:84,swp7s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,192.168.50.57,barcelona-net,581
MOC-R4PCC02U30,a0:88:c2:27:c0:88,swp31s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U30,a0:88:c2:27:c0:8c,swp31s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U31,a0:88:c2:27:c4:50,swp6s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U31,a0:88:c2:27:c4:54,swp6s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,192.168.50.65,barcelona-net,581
MOC-R4PCC02U31,a0:88:c2:27:c4:58,swp30s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U31,a0:88:c2:27:c4:5c,swp30s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U32,a0:88:c2:27:c5:60,swp5s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U32,a0:88:c2:27:c5:64,swp5s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,192.168.50.153,barcelona-net,581
MOC-R4PCC02U32,a0:88:c2:27:c5:68,swp29s0,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
MOC-R4PCC02U32,a0:88:c2:27:c5:6c,swp29s1,MOC-R4PCC02-SW-TORS,b0:cf:0e:c2:99:ff,,,
```

## tcp settings

``` shell
net.core.mem_pcpu_rsv = 256
net.core.optmem_max = 81920
net.core.rmem_default = 212992
net.core.rmem_max = 212992
net.core.wmem_default = 212992
net.core.wmem_max = 212992
net.ipv4.fib_sync_mem = 524288
net.ipv4.igmp_max_memberships = 20
net.ipv4.tcp_mem = 18531756	24709011	37063512
net.ipv4.tcp_rmem = 4096	131072	6291456
net.ipv4.tcp_wmem = 4096	16384	4194304
net.ipv4.udp_mem = 37063515	49418023	74127030
net.ipv4.udp_rmem_min = 4096
net.ipv4.udp_wmem_min = 4096
vm.hugetlb_optimize_vmemmap = 0
vm.lowmem_reserve_ratio = 256	256	32	0	0
vm.memory_failure_early_kill = 0
vm.memory_failure_recovery = 1
vm.nr_hugepages_mempolicy = 0
vm.overcommit_memory = 1
```

## network container hacking

### SRIO-V
0. view interface 

``` shell
ip link show dev eno6np0
ip addr show dev eno6np0
realpath -L /sys/class/net/eno6np0/device
echo $(cat /sys/class/net/eno6np0/address) \
	$(lspci -s $(basename $(realpath -L /sys/class/net/eno6np0/device)))
```

1. if it has an address lets bring it down for good measure 

``` shell
ip addr del <cider> dev enp
```

2. see if there are already any virtual functions

``` shell
cat /sys/class/net/eno6np0/device/sriov_numvfs
lspci | grep "Virtual"
```

3. create a virtual function

``` shell
echo 1 > /sys/class/net/eno6np0/device/sriov_numvfs
cat /sys/class/net/eno6np0/device/sriov_numvfs
ls -l  /sys/class/net
```

look for an interface who's path is a prefix of the iterface that you created
the virtual function on 

4. configure the interface associated with the virtual function with an ip and test

``` shell
ip addr add 192.168.216.29/24 dev eno6v0
ip link set dev eno6v0 mtu 9000 
ip addr show dev eno6v0 
ping 192.168.216.32
```

At this point we have an interface that is backed by a virtual function of 
our nic.

### add a inteface to an existing container's

Our goal now is to hand the virtual function over to a container in a pod
that already exists on the node

1. First remove the ip from the inteface so that we can hand it over

``` shell
ip addr del 192.168.216.29/24  dev eno6v0
```

2. list netns namespaces

If you are using a debug container be sure to `chroot /host` so that you are
looking at the default namespaces 

``` shell
ip netns
```

find a process of the pod who's network namespace you want to modify

My hack is to exec a shell into the pod and then ps looking for a process
that I can identify in the debug pod
``` shell
(.pyenv) $ oc exec torchrun-multipod-1 -it -- /bin/bash
root@torchrun-multipod-1:/workspace# ip link
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0@if441: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc noqueue state UP mode DEFAULT group default 
    link/ether 0a:58:0a:82:00:68 brd ff:ff:ff:ff:ff:ff link-netnsid 0
root@torchrun-multipod-1:/workspace# ps auxgww
USER         PID %CPU %MEM    VSZ   RSS TTY      STAT START   TIME COMMAND
root           1  0.0  0.0   4364     0 ?        Ss   16:12   0:03 /bin/bash /workspace/run.sh 2 4 1 0 d12 newoc2nodes 8 4
root        3832  0.0  0.0   4628     0 pts/0    Ss   17:16   0:00 /bin/bash
root        3996  0.0  0.0   2792     0 ?        S    17:18   0:00 sleep 1
root        3997  0.0  0.0   7064     0 pts/0    R+   17:18   0:00 ps auxgww
root@torchrun-multipod-1:/workspace# 
```

Now in the debug pod

``` shell

sh-5.1# ps auxgww | grep workspace
root     1952156  0.0  0.0   4364     0 ?        Ss   16:12   0:03 /bin/bash /workspace/run.sh 2 4 1 0 d12 newoc2nodes 8 4
root     2127367  0.0  0.0   3332     0 pts/0    S+   17:24   0:00 grep workspace
sh-5.1# ip netns identify 1952156
089031ca-6400-479f-a2b2-1c87b3edad54
sh-5.1# ip netns pids 089031ca-6400-479f-a2b2-1c87b3edad54
1952156
2107080
2132668
sh-5.1# ps auxgww | grep -E '1952156|2107080|2132668'
root     1952156  0.0  0.0   4364     0 ?        Ss   16:12   0:03 /bin/bash /workspace/run.sh 2 4 1 0 d12 newoc2nodes 8 4
root     2107080  0.0  0.0   4628     0 pts/0    Ss+  17:16   0:00 /bin/bash
root     2133861  0.0  0.0   3464     0 pts/0    R+   17:27   0:00 grep -E 1952156|2107080|2132668
```

ok let us now move the nic to the netns of the pod

``` shell
sh-5.1# ip netns identify 1952156
089031ca-6400-479f-a2b2-1c87b3edad54
sh-5.1# ip link set eno6v0 netns 089031ca-6400-479f-a2b2-1c87b3edad54
sh-5.1# ip link show dev eno6v0
444: eno6v0: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 9000 qdisc mq state UP mode DEFAULT group default qlen 1000
    link/ether 5a:56:06:e8:d3:38 brd ff:ff:ff:ff:ff:ff
    altname enp35s0v0
sh-5.1# ip link set eno6v0 netns 089031ca-6400-479f-a2b2-1c87b3edad54
sh-5.1# ip link show dev eno6v0
Device "eno6v0" does not exist.
sh-5.1# ip netns exec 089031ca-6400-479f-a2b2-1c87b3edad54 ip link show
1: lo: <LOOPBACK,UP,LOWER_UP> mtu 65536 qdisc noqueue state UNKNOWN mode DEFAULT group default qlen 1000
    link/loopback 00:00:00:00:00:00 brd 00:00:00:00:00:00
2: eth0@if441: <BROADCAST,MULTICAST,UP,LOWER_UP> mtu 1400 qdisc noqueue state UP mode DEFAULT group default 
    link/ether 0a:58:0a:82:00:68 brd ff:ff:ff:ff:ff:ff link-netns fe41c389-230c-4179-a362-9816fbfac544
444: eno6v0: <BROADCAST,MULTICAST> mtu 9000 qdisc noop state DOWN mode DEFAULT group default qlen 1000
    link/ether 5a:56:06:e8:d3:38 brd ff:ff:ff:ff:ff:ff
    altname enp35s0v0
sh-5.1# ip netns exec 089031ca-6400-479f-a2b2-1c87b3edad54 ip link set mtu 9000 dev eno6v0
sh-5.1# ip netns exec 089031ca-6400-479f-a2b2-1c87b3edad54 ip addr add 192.168.216.29/24 dev eno6v0
sh-5.1# ip netns exec 089031ca-6400-479f-a2b2-1c87b3edad54 ip link set eno6v0 up
```

Now in the pod 

``` shell
exec 5<>/dev/tcp/192.168.216.32/12345
echo hello >&5
```

On the destination host

``` shell
mocr4pcc02u32# socat - tcp-listen:12345
hello
```




---
title: QEMU<->ACPI BIOS PCI hotplug interface
source: https://www.qemu.org/docs/master/specs/acpi_pci_hotplug.html
author:
published:
created: 2026-06-30
description:
tags:
  - clippings
---
QEMU supports PCI hotplug via ACPI, for PCI bus 0. This document describes the interface between QEMU and the ACPI BIOS.

## ACPI GPE block (IO ports 0xafe0-0xafe3, <mark style="background:#40a9ff">byte access</mark>)

Generic ACPI GPE block. **Bit 1 (GPE.1) used to ==notify PCI hotplug/eject event to ACPI BIOS==, via ==SCI== interrupt**.

## PCI slot injection notification pending (IO port 0xae00-0xae03, 4-byte access)

**==Slot injection== notification pending. One bit per slot.**

Read by ACPI BIOS GPE.1 handler to notify OS of injection events. **Read-only.**

## PCI slot removal notification (IO port 0xae04-0xae07, 4-byte access)

**==Slot removal== notification pending. One bit per slot.**

Read by ACPI BIOS GPE.1 handler to notify OS of removal events. **Read-only.**

## PCI device eject (IO port 0xae08-0xae0b, 4-byte access)

Write: Used by ACPI BIOS ==**`_EJ0==`**== method to request device removal.== One bit per slot.

Read: Hotplug features register. Used by platform to identify features available. Current base feature set (no bits set):
- Read-only “up” register @0xae00, 4-byte access, bit per slot
- Read-only “down” register @0xae04, 4-byte access, bit per slot
- Read/<mark style="background:#fdbfff">write</mark>  “eject” register @0xae08, 4-byte access, **write: bit per slot eject, read: hotplug feature set**
- Read-only hotplug capable register @0xae0c, 4-byte access, bit per slot

## PCI removability status (IO port 0xae0c-0xae0f, 4-byte access)

Used by **ACPI BIOS `_RMV` method** to indicate removability status to OS. One bit per slot. Read-only.

```ad-missing
少两个新加入的寄存器
```

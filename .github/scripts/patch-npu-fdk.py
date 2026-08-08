#!/usr/bin/env python3
"""Patch known build issues in the airoha-npu-fdk tree before compiling.

Issue 1: mt7996_fragment_queue_consumer.c passes a volatile uint8_t* to
__builtin_assume_aligned() which expects const void*; clang -Werror rejects
the discarded qualifier. Wrap the argument in an explicit (const void *) cast.
"""
import sys
from pathlib import Path

root = Path(__file__).resolve().parent.parent  # repo root when run from .github/scripts
if len(sys.argv) > 1:
    root = Path(sys.argv[1])

p = root / "src/an7581/services/wifi/mt7996_fragment_queue_consumer.c"
s = p.read_text(encoding="utf-8")

old = """  packet_words = __builtin_assume_aligned(
      consumer->packet_cached_memory +
          (uint32_t)packet_id * NPU_WIFI_MT7996_PACKET_QUEUE_PACKET_SIZE,
      sizeof(uint32_t));"""

new = """  packet_words = __builtin_assume_aligned(
      (const void *)(consumer->packet_cached_memory +
          (uint32_t)packet_id * NPU_WIFI_MT7996_PACKET_QUEUE_PACKET_SIZE),
      sizeof(uint32_t));"""

if old not in s:
    print("WARN: volatile-cast pattern not found; skipping (may already be patched)")
else:
    p.write_text(s.replace(old, new), encoding="utf-8")
    print("patched mt7996_fragment_queue_consumer.c volatile cast")

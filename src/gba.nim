import os
import sdl2

import gba/[apu, bus, cpu, display, keypad, ppu, scheduler, types]

proc newGBA(bios, rom: string): GBA =
  new result
  result.scheduler = newScheduler()
  result.apu = newAPU(result)
  result.bus = newBus(result, bios, rom)
  result.display = newDisplay()
  result.cpu = newCPU(result)
  result.ppu = newPPU(result)
  result.keypad = newKeypad(result)

proc runFrame(gba: GBA) =
  for _ in 0 ..< 280896:
    gba.cpu.tick()
    gba.scheduler.tick(1)

proc checkKeyInput(gba: GBA) =
  var event = sdl2.defaultEvent
  while pollEvent(event):
    case event.kind
    of QuitEvent: quit "quit event"
    of KeyDown, KeyUp: gba.keypad.keyEvent(cast[KeyboardEventObj](event))
    else: discard

proc loop(gba: GBA) {.cdecl.} =
  runFrame(gba)
  checkKeyInput(gba)

discard sdl2.init(INIT_EVERYTHING)

when defined(emscripten):
  type em_arg_callback_func = proc(data: pointer) {.cdecl.}
  proc emscripten_set_main_loop(fun: proc() {.cdecl.}, fps, simulate_infinite_loop: cint) {.header: "<emscripten.h>".}
  proc emscripten_set_main_loop_arg(fun: em_arg_callback_func, arg: pointer, fps, simulate_infinite_loop: cint) {.header: "<emscripten.h>".}
  proc emscripten_cancel_main_loop() {.header: "<emscripten.h>".}
  proc initFromEmscripten() {.exportc.} =
    var gba = newGBA("bios.bin", "rom.gba")
    emscripten_set_main_loop_arg(cast[em_arg_callback_func](loop), cast[pointer](gba), -1, 1)
else:
  if paramCount() != 2: quit "Run with ./gba /path/to/bios /path/to/rom"
  var gba = newGBA(paramStr(1), paramStr(2))
  while true: loop(gba)

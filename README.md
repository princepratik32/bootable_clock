# bootable_clock

A clock that displays time having booted from EFI.

- It is x86_64 code built with [FASM](https://flatassembler.net/).
- Needs qemu and ovfm.
- It uses UEFI spec 2.8.

1. Create a directory called `drive`
2. Assemble like `fasm clock_fasm.asm drive/clock`
3. Run qemu like `qemu-system-x86_64 -bios /usr/share/qemu/OVMF.fd -net none -drive format=raw,file=fat:rw:drive/ -monitor stdio`
4. Once you have the EFI console on qemu, run it like this `FS0:\clock`.
5. If you want it to run automatically, replace `ret` with `jmp $` in `main`, assemble & place the binary at this location/name `drive/EFI/BOOT/BOOTx64.EFI`.

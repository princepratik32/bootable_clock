format pe64 efi
entry main

section '.text' executable readable

;; Some useful macros
macro add_shadow_space
{
	sub rsp, 32
}

macro remove_shadow_space
{
	add rsp, 32
}

macro save_base_pointer
{
	push rbp;
	mov rbp, rsp;
}

macro restore_base_pointer
{
	mov rsp, rbp;
	pop rbp;
}

;; Some useful constants
shadow_space_size = 32
return_address_size = 8

main:
	save_base_pointer
	sub rsp, 16

	;; RDX contains a pointer to the System Table when
	;; our application is called.
	mov [system_table], rdx

	add_shadow_space
	call get_time_string
	remove_shadow_space

	;;mov rax, 0x0033003A00320031
	;;push rax
	;;push string
	add_shadow_space
	call print_string_to_con_out
	remove_shadow_space

	restore_base_pointer
	;;ret

	;; For when we load the program automatically from EFI,
	;; this will keep it from exiting promptly
	jmp $

;; A procedure to print a string to console out
print_string_to_con_out:
	save_base_pointer

	;; rdx + 64 is the address of the
	;; pointer to ConOut, and [rdx + 64] is the pointer itself.
	mov rcx, [system_table]
	mov rcx, [rcx + 64]

	;; Now, RCX contains the ConOut pointer. Thus, the address of
	;; the OutputString function is at rcx + 8. We'll move this
	;; function into RAX:
	mov rax, [rcx + 8]

	;; We already have the ConOut pointer in RCX. Let's load the
	;; string pointer into RDX from Stack:
	mov rdx, rbp	;; getting the param from caller's stack
	add rdx, 8
	add rdx, return_address_size
	add rdx, shadow_space_size
;;	mov rdx, [rdx]

	;; Now we can call the OutputText function, whose address is
	;; in the RAX register:

	add_shadow_space
	call rax
	remove_shadow_space

	restore_base_pointer
	ret

;; A procedure that takes a number on caller's stack and puts an upto 3 char long string onto
;; the caller's stack. Do not give a number that doesn't fit in 3 characters when converted
;; i.e. max number in decimal is 999 if you exceed this limit, the behavior is undefined.
int_to_string:
	save_base_pointer

	mov rax, rbp	;; getting the param from caller's stack
	add rax, 8
	add rax, return_address_size
	add rax, shadow_space_size
	mov rax, [rax]

	mov r13, 0	;; the final result string

	;; store the number like "123" in r13 like "321".
	;; Read about endianness.
L1:
	sal r13, 16	;; shift 2 byte left. As per UEFI specs, each char is USC-2 encoding
	mov rdx, 0	;; rdx must be 0 [just the rule for x86_64]
	mov rcx, 0xA	;; divide by 0xA
	div rcx
	add rdx, 0x30	;; convert digit to ascii character
	or r13, rdx	;; save the remainder
	and rax, 0xFFFFFFFFFFFFFFFF	;; check if rax is 0, i.e. we're done
	jnz L1

	mov rax, rbp	;; store it back on caller's stack
	add rax, 8
	add rax, return_address_size
	add rax, shadow_space_size
	mov [rax], r13

	restore_base_pointer
	ret

;; A procedure that reads the system time and returns a string of the format "hh:mm" in 24 hour format
get_time_string:
	save_base_pointer

	;; rdx + 88 is the address of the
	;; pointer to EFI_RUNTIME_SERVICES, and [rdx + 88] is the pointer itself.
	mov rcx, [system_table]
	mov rcx, [rcx + 88]

	;; Now, RCX contains the EFI_RUNTIME_SERVICES pointer. Thus, the address of
	;; the EFI_GET_TIME function is at rcx + 24. We'll move this
	;; function into RAX:
	mov rax, [rcx + 24]


	sub rsp, 16	;; allocate space for EFI_TIME struct
	mov rcx, rsp

	add_shadow_space
	call rax
	remove_shadow_space

	mov r13, [rsp + 4]	;; read the hours from the EFI_TIME struct
	and r13, 0xFF	;; because we need all other bits to be 0 so that we only read 1 number

	sub rsp, 8
	push r13	;; Convert hour number to string
	add_shadow_space
	call int_to_string
	remove_shadow_space
	pop r13
	add rsp, 8

	mov r8, r13	;; Some trickery to pad 0 for a single digit hour time
	mov r9, 0xFFFF0000
	and r8, r9
	jnz continue_1
	sal r13, 16
	mov r9, 0x0030
	add r13, r9

continue_1:
	mov r9, 0x3A00000000	;; add a ':' character
	or r13, r9

	mov r14, [rsp + 5]	;; read the minutes from the EFI_TIME struct
	and r14, 0xFF	;; because we need all other bits to be 0 so that we only read 1 number

	sub rsp, 16
	push r13	;; save important value of r13 [because the called procedure could mess with it]
	push r14	;; Convert hour number to string
	add_shadow_space
	call int_to_string
	remove_shadow_space
	pop r14
	pop r13	;; restore r13
	add rsp, 16

	mov r8, r14	;; Some trickery to pad 0 for a single digit hour time
	mov r9, 0xFFFF0000
	and r8, r9
	jnz continue_2
	sal r14, 16
	mov r9, 0x0030
	add r14, r9

continue_2:
	mov r15, r14	;; make a copy of minutes string
	and r15, 0xFFFF ;; extract most significant number char from hour string
	shl r15, 48
	or r13, r15	;; attach most significant minutes character to 'hh:' string.
			;; Remember everything is in reverse because of little endianness.

	mov rax, rbp	;; store it back on caller's stack
	add rax, 8
	add rax, return_address_size
	add rax, shadow_space_size
	mov [rax], r13

	mov r12, r14
	mov r9, 0xFFFF0000
	and r12, r9
	shr r12, 16

	mov rax, rbp	;; store it back on caller's stack
	add rax, 16
	add rax, return_address_size
	add rax, shadow_space_size
	mov [rax], r12

	restore_base_pointer
	ret

section '.data' readable writable
	string du 'Hello, World!', 0xD, 0xA, 0
	system_table dq 0
	number dq 876

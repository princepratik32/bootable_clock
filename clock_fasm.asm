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
	sub rsp, 8

	;; RDX contains a pointer to the System Table when
	;; our application is called.
	mov [system_table], rdx

	push number
	add_shadow_space
	call int_to_string
	remove_shadow_space

	;;mov rax, 0x0000003100320033
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

	;; TODO: finish this procedure
	restore_base_pointer
	ret

section '.data' readable writable
	string du 'Hello, World!', 0xD, 0xA, 0
	system_table dq 0
	number dq 876

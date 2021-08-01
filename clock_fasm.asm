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

	push string

	add_shadow_space
	call print_string_to_con_out
	remove_shadow_space

	restore_base_pointer
	ret

	;; For when we load the program automatically from EFI,
	;; this will keep it from exiting promptly
	;; jmp $

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
	mov rdx, [rbp + 8 + return_address_size + shadow_space_size]

	;; Now we can call the OutputText function, whose address is
	;; in the RAX register:

	add_shadow_space
	call rax
	remove_shadow_space

	restore_base_pointer
	ret

section '.data' readable writable
	string du 'Hello, World!', 0xD, 0xA, 0
	system_table dq 0

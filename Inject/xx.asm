.data

public	xapi, xtid
public	xdll
public	xxend

public xsect_cr_api, xsect_handle

public xsio_api

xfunc	proc
		sub		rsp, 28h

		mov		rax, [xsect_cr_api]
		; save old code
		mov		rcx, [rax]
		mov		[old_code2], rcx

		; hook NtCreateSection
		lea		rcx, xsseccr
		mov		[rax-8], rcx
		mov		ecx, 0fff225ffh
		mov		[rax], ecx
		or		ecx, -1
		mov		[rax+4], cx

		xor		rax, rax
		mov	[xsect_handle_idx], rax

		;;;;;;;;; call NtSetInfoObj
;		mov		rcx, [xsect_handle]
;		mov		edx, 4
;		lea		r8, [ohai_inherit]
;		mov		r9d, 4

;		mov		byte ptr [r8], 0
;		mov		byte ptr [r8+1], 1
;		call	[xsio_api]


		;;;;;;;
		; call ldrloaddll
		xor		rcx, rcx
		xor		rdx, rdx
		lea		r8, [xdll]
		lea		r9, [xmod]
		call	qword ptr [xapi]

		; store status
		mov		[xapi], rax

		; restore code
	
		mov		rax, [xsect_cr_api]
		mov		rcx, [old_code2]
		mov		[rax], rcx


		add		rsp, 28h
		ret
xfunc	endp


xsseccr	proc
;  OUT PHANDLE             SectionHandle,		RCX
;  IN ULONG                DesiredAccess,
;  IN POBJECT_ATTRIBUTES   ObjectAttributes OPTIONAL,
;  IN PLARGE_INTEGER       MaximumSize OPTIONAL,
;  IN ULONG                PageAttributess,				+28h
;  IN ULONG                SectionAttributes,			+30h
;  IN HANDLE               FileHandle OPTIONAL );		+38h

		; if TID doesn't match - just go to the API directly
		mov		eax, gs:[48h]
		cmp		eax, [xtid]
		jne		@syscall

		; map can be called for static dependencies too, so mark to run once
		; (assuming that our module mapping will be called first, which is good for now)

		mov		rax, [rsp+38h]
		test	rax, rax
		jz		@syscall

;		mov		rax, [xfile]
;		test	rax, rax
;		jnz		@1
		; save file on first use
;		mov		[xfile], rax

@1:
		; check if the same file
;		cmp		[xfile], rax
;		jz		@2
	
		; not same file, quit and mark
;		xor		eax, eax
;		mov		[xtid], eax
;		jmp		@syscall

@2:
		test	rcx, rcx
		jz		@syscall

		; since Windows10 loader can decide to retry loading, closing the section handle each time, we keep an array of these,
		; returning a new one each time

		mov		rax, [xsect_handle_idx]
		lea		rdx, [xsect_handle]
		lea		rax, [rdx + rax*8]
		mov		rax, [rax]
		mov		[rcx], rax
		inc		[xsect_handle_idx]

		xor		rax, rax
		ret


@syscall:
		mov     r10,rcx
		mov     eax,4Ah
		syscall
		ret

xsseccr	endp



		ALIGN	16
xapi	dq	?
xtid	dd	?

xsio_api	dq	?

xsect_cr_api	dq	?
xsect_handle	dq	100 dup(?)
xsect_handle_idx	dq	?

xdll	db	1024 dup(?)

xxend	proc
xxend	endp

xfile	dq	?

xmod	dq	?
old_code2 dq	?

ohai_inherit	db	?
ohai_protect	db	?

end
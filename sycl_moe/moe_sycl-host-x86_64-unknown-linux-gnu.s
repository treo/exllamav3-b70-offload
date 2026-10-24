	.att_syntax
	.file	"moe_sycl.cpp"
	.text
	.globl	_ZN8moe_sycl12MoeSyclLayer4initEPN4sycl3_V15queueERKNS_11LayerParamsERKSt6vectorINS_9MatrixSrcESaIS9_EESD_SD_ # -- Begin function _ZN8moe_sycl12MoeSyclLayer4initEPN4sycl3_V15queueERKNS_11LayerParamsERKSt6vectorINS_9MatrixSrcESaIS9_EESD_SD_
	.p2align	1
	.prefalign	4, .Lfunc_end0, nop
	.type	_ZN8moe_sycl12MoeSyclLayer4initEPN4sycl3_V15queueERKNS_11LayerParamsERKSt6vectorINS_9MatrixSrcESaIS9_EESD_SD_,@function
_ZN8moe_sycl12MoeSyclLayer4initEPN4sycl3_V15queueERKNS_11LayerParamsERKSt6vectorINS_9MatrixSrcESaIS9_EESD_SD_: # 
.Lfunc_begin0:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception0
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$120, %rsp
	.cfi_def_cfa_offset 176
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rsi, 8(%rdi)
	movups	(%rdx), %xmm0
	movups	13(%rdx), %xmm1
	movups	%xmm0, 16(%rdi)
	movups	%xmm1, 29(%rdi)
	movslq	16(%rdi), %r15
	leaq	(,%r15,4), %rax
	leaq	(%rax,%rax,2), %r13
	movq	%r13, %rax
	shrq	$60, %rax
	jne	.LBB0_58
# %bb.1:
	movq	%rsi, %r14
	movq	%rdi, %r12
	movq	%r9, 88(%rsp)                   # 8-byte Spill
	testl	%r15d, %r15d
	movq	%rsi, 56(%rsp)                  # 8-byte Spill
	je	.LBB0_2
# %bb.3:
	movq	%r15, %rax
	shlq	$5, %rax
	movq	%r12, (%rsp)                    # 8-byte Spill
	leaq	(%rax,%rax,2), %r14
	movq	%r14, %rdi
	movq	%r8, %rbp
	movq	%rcx, %r12
	callq	_Znwm
	movq	%rax, %rbx
	movq	%rax, %rdi
	xorl	%esi, %esi
	movq	%r14, %rdx
	callq	_intel_fast_memset@PLT
	movq	%r12, %rcx
	movq	%rbp, %r8
	leaq	(%rbx,%r13,8), %rax
	movq	%rax, 8(%rsp)                   # 8-byte Spill
	movq	%rbx, %rbp
	addq	%r14, %rbp
	movq	56(%rsp), %r14                  # 8-byte Reload
	movq	(%rsp), %r12                    # 8-byte Reload
	testl	%r15d, %r15d
	jg	.LBB0_5
	jmp	.LBB0_13
.LBB0_2:
	movq	$0, 8(%rsp)                     # 8-byte Folded Spill
	xorl	%ebx, %ebx
	xorl	%ebp, %ebp
	testl	%r15d, %r15d
	jle	.LBB0_13
.LBB0_5:
	movq	(%rcx), %rcx
	leaq	(,%r15,8), %rdi
	leaq	(%rdi,%rdi,8), %rdx
	movq	%r15, %rax
	shlq	$4, %rax
	leaq	(%rax,%rax,2), %rsi
	leaq	(%rdi,%rdi,2), %rdi
	addq	$24, %rcx
	movq	%r15, %r11
	movq	%rbx, %r9
	.p2align	4
.LBB0_6:                                # =>This Inner Loop Header: Depth=1
	movq	-24(%rcx), %r10
	movq	%r10, (%r9)
	movq	-16(%rcx), %r10
	movq	%r10, (%r9,%rdi)
	movq	-8(%rcx), %r10
	movq	%r10, (%r9,%rsi)
	movq	(%rcx), %r10
	movq	%r10, (%r9,%rdx)
	addq	$8, %r9
	addq	$32, %rcx
	decq	%r11
	jne	.LBB0_6
# %bb.7:
	testl	%r15d, %r15d
	jle	.LBB0_13
# %bb.8:
	movq	(%r8), %rdx
	leaq	(%r15,%r15,4), %rcx
	movq	%rcx, %rsi
	shlq	$4, %rsi
	addq	%rbx, %rsi
	addq	$24, %rdx
	imulq	$56, %r15, %rdi
	addq	%rbx, %rdi
	movq	%r15, %r8
	shlq	$5, %r8
	addq	%rbx, %r8
	leaq	(%rbx,%r15,8), %r9
	xorl	%r10d, %r10d
	.p2align	4
.LBB0_9:                                # =>This Inner Loop Header: Depth=1
	movq	-24(%rdx), %r11
	movq	%r11, (%r9,%r10,8)
	movq	-16(%rdx), %r11
	movq	%r11, (%r8,%r10,8)
	movq	-8(%rdx), %r11
	movq	%r11, (%rdi,%r10,8)
	movq	(%rdx), %r11
	movq	%r11, (%rsi,%r10,8)
	incq	%r10
	addq	$32, %rdx
	cmpq	%r10, %r15
	jne	.LBB0_9
# %bb.10:
	testl	%r15d, %r15d
	jle	.LBB0_13
# %bb.11:
	movq	88(%rsp), %rdx                  # 8-byte Reload
	movq	(%rdx), %rdx
	imulq	$88, %r15, %rsi
	addq	%rbx, %rsi
	addq	$24, %rdx
	movq	%r15, %rdi
	shlq	$6, %rdi
	addq	%rbx, %rdi
	leaq	(%rbx,%rcx,8), %rcx
	addq	%rbx, %rax
	xorl	%r8d, %r8d
	.p2align	4
.LBB0_12:                               # =>This Inner Loop Header: Depth=1
	movq	-24(%rdx), %r9
	movq	%r9, (%rax,%r8,8)
	movq	-16(%rdx), %r9
	movq	%r9, (%rcx,%r8,8)
	movq	-8(%rdx), %r9
	movq	%r9, (%rdi,%r8,8)
	movq	(%rdx), %r9
	movq	%r9, (%rsi,%r8,8)
	incq	%r8
	addq	$32, %rdx
	cmpq	%r8, %r15
	jne	.LBB0_12
.LBB0_13:
	xorps	%xmm0, %xmm0
	movups	%xmm0, 32(%rsp)                 # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 16(%rsp)                 # AlignMOV convert to UnAlignMOV 
	movq	$.L.str, 64(%rsp)
	movq	$.L.str.1, 72(%rsp)
	movabsq	$55834574935, %rax              # imm = 0xD00000057
	movq	%rax, 80(%rsp)
.Ltmp0:                                 # EH_LABEL
	leaq	112(%rsp), %rdi
	movq	%r14, %rsi
	callq	_ZNK4sycl3_V15queue10get_deviceEv
.Ltmp1:                                 # EH_LABEL
# %bb.14:
.Ltmp2:                                 # EH_LABEL
	leaq	96(%rsp), %rdi
	movq	%r14, %rsi
	callq	_ZNK4sycl3_V15queue11get_contextEv
.Ltmp3:                                 # EH_LABEL
# %bb.15:
.Ltmp5:                                 # EH_LABEL
	subq	%rbx, %rbp
	leaq	112(%rsp), %rdx
	leaq	96(%rsp), %rcx
	leaq	16(%rsp), %r8
	leaq	64(%rsp), %r9
	movl	$8, %edi
	movq	%rbp, %rsi
	callq	_ZN4sycl3_V120aligned_alloc_deviceEmmRKNS0_6deviceERKNS0_7contextERKNS0_13property_listERKNS0_6detail13code_locationE
.Ltmp6:                                 # EH_LABEL
# %bb.16:
	movabsq	$4294967297, %r15               # imm = 0x100000001
	movq	104(%rsp), %r14
	testq	%r14, %r14
	je	.LBB0_24
# %bb.17:
	movq	8(%r14), %rcx
	cmpq	%r15, %rcx
	jne	.LBB0_19
# %bb.18:
	movq	$0, 8(%r14)
	movq	(%r14), %rcx
	movq	%r14, %rdi
	movq	%rax, %r13
	callq	*16(%rcx)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	movq	%r13, %rax
	jmp	.LBB0_24
.LBB0_19:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB0_21
# %bb.20:
	leal	-1(%rcx), %edx
	movl	%edx, 8(%r14)
	cmpl	$1, %ecx
	je	.LBB0_23
.LBB0_24:
	movq	%rax, 80(%r12)
	movq	24(%rsp), %r14
	movq	32(%rsp), %r13
	cmpq	%r13, %r14
	je	.LBB0_36
# %bb.25:
	movq	%rbp, (%rsp)                    # 8-byte Spill
	jmp	.LBB0_26
	.p2align	4
.LBB0_28:                               #   in Loop: Header=BB0_26 Depth=1
	movq	$0, 8(%rbp)
	movq	(%rbp), %rax
	movq	%rbp, %rdi
	callq	*16(%rax)
	movq	(%rbp), %rax
	movq	%rbp, %rdi
	callq	*24(%rax)
.LBB0_34:                               #   in Loop: Header=BB0_26 Depth=1
	addq	$16, %r14
	cmpq	%r13, %r14
	je	.LBB0_35
.LBB0_26:                               # =>This Inner Loop Header: Depth=1
	movq	8(%r14), %rbp
	testq	%rbp, %rbp
	je	.LBB0_34
# %bb.27:                               #   in Loop: Header=BB0_26 Depth=1
	movq	8(%rbp), %rax
	cmpq	%r15, %rax
	je	.LBB0_28
# %bb.29:                               #   in Loop: Header=BB0_26 Depth=1
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB0_31
# %bb.30:                               #   in Loop: Header=BB0_26 Depth=1
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbp)
	cmpl	$1, %eax
	jne	.LBB0_34
	jmp	.LBB0_33
.LBB0_31:                               #   in Loop: Header=BB0_26 Depth=1
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbp)
	cmpl	$1, %eax
	jne	.LBB0_34
.LBB0_33:                               #   in Loop: Header=BB0_26 Depth=1
	movq	%rbp, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB0_34
.LBB0_35:
	movq	24(%rsp), %r14
	movq	(%rsp), %rbp                    # 8-byte Reload
.LBB0_36:
	testq	%r14, %r14
	je	.LBB0_38
# %bb.37:
	movq	40(%rsp), %rsi
	subq	%r14, %rsi
	movq	%r14, %rdi
	callq	_ZdlPvm
.LBB0_38:
	movq	80(%r12), %rdx
	movq	$.L.str, 16(%rsp)
	movq	$.L.str.1, 24(%rsp)
	movabsq	$34359738456, %rax              # imm = 0x800000058
	movq	%rax, 32(%rsp)
.Ltmp8:                                 # EH_LABEL
	leaq	64(%rsp), %rdi
	leaq	16(%rsp), %r9
	movq	56(%rsp), %rsi                  # 8-byte Reload
	movq	%rbx, %rcx
	movq	%rbp, %r8
	callq	_ZN4sycl3_V15queue6memcpyEPvPKvmRKNS0_6detail13code_locationE
.Ltmp9:                                 # EH_LABEL
# %bb.39:
.Ltmp11:                                # EH_LABEL
	leaq	64(%rsp), %rdi
	callq	_ZN4sycl3_V15event4waitEv
.Ltmp12:                                # EH_LABEL
# %bb.40:
	movq	72(%rsp), %r14
	testq	%r14, %r14
	je	.LBB0_48
# %bb.41:
	movq	8(%r14), %rax
	cmpq	%r15, %rax
	jne	.LBB0_43
# %bb.42:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	testq	%rbx, %rbx
	jne	.LBB0_49
	jmp	.LBB0_50
.LBB0_43:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB0_45
# %bb.44:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	je	.LBB0_47
.LBB0_48:
	testq	%rbx, %rbx
	je	.LBB0_50
.LBB0_49:
	movq	8(%rsp), %rsi                   # 8-byte Reload
	subq	%rbx, %rsi
	movq	%rbx, %rdi
	callq	_ZdlPvm
.LBB0_50:
	addq	$120, %rsp
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB0_21:
	.cfi_def_cfa_offset 176
	movl	$-1, %ecx
	lock		xaddl	%ecx, 8(%r14)
	cmpl	$1, %ecx
	jne	.LBB0_24
.LBB0_23:
	movq	%r14, %rdi
	movq	%rax, %r14
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	movq	%r14, %rax
	jmp	.LBB0_24
.LBB0_45:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB0_48
.LBB0_47:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	testq	%rbx, %rbx
	jne	.LBB0_49
	jmp	.LBB0_50
.LBB0_58:
	movl	$.L.str.19, %edi
	callq	_ZSt20__throw_length_errorPKc
.LBB0_54:
.Ltmp13:                                # EH_LABEL
	movq	%rax, %r14
	leaq	64(%rsp), %rdi
	callq	_ZN4sycl3_V15eventD2Ev
	jmp	.LBB0_55
.LBB0_53:
.Ltmp10:                                # EH_LABEL
	movq	%rax, %r14
	jmp	.LBB0_55
.LBB0_59:
.Ltmp7:                                 # EH_LABEL
	movq	%rax, %r14
	leaq	96(%rsp), %rdi
	callq	_ZN4sycl3_V17contextD2Ev
	jmp	.LBB0_52
.LBB0_51:
.Ltmp4:                                 # EH_LABEL
	movq	%rax, %r14
.LBB0_52:
	leaq	16(%rsp), %rdi
	callq	_ZN4sycl3_V16detail16PropertyListBaseD2Ev
.LBB0_55:
	testq	%rbx, %rbx
	je	.LBB0_57
# %bb.56:
	movq	8(%rsp), %rsi                   # 8-byte Reload
	subq	%rbx, %rsi
	movq	%rbx, %rdi
	callq	_ZdlPvm
.LBB0_57:
	movq	%r14, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end0:
	.size	_ZN8moe_sycl12MoeSyclLayer4initEPN4sycl3_V15queueERKNS_11LayerParamsERKSt6vectorINS_9MatrixSrcESaIS9_EESD_SD_, .Lfunc_end0-_ZN8moe_sycl12MoeSyclLayer4initEPN4sycl3_V15queueERKNS_11LayerParamsERKSt6vectorINS_9MatrixSrcESaIS9_EESD_SD_
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table0:
.Lexception0:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end0-.Lcst_begin0
.Lcst_begin0:
	.uleb128 .Lfunc_begin0-.Lfunc_begin0    # >> Call Site 1 <<
	.uleb128 .Ltmp0-.Lfunc_begin0           #   Call between .Lfunc_begin0 and .Ltmp0
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp0-.Lfunc_begin0           # >> Call Site 2 <<
	.uleb128 .Ltmp3-.Ltmp0                  #   Call between .Ltmp0 and .Ltmp3
	.uleb128 .Ltmp4-.Lfunc_begin0           #     jumps to .Ltmp4
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp5-.Lfunc_begin0           # >> Call Site 3 <<
	.uleb128 .Ltmp6-.Ltmp5                  #   Call between .Ltmp5 and .Ltmp6
	.uleb128 .Ltmp7-.Lfunc_begin0           #     jumps to .Ltmp7
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp6-.Lfunc_begin0           # >> Call Site 4 <<
	.uleb128 .Ltmp8-.Ltmp6                  #   Call between .Ltmp6 and .Ltmp8
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp8-.Lfunc_begin0           # >> Call Site 5 <<
	.uleb128 .Ltmp9-.Ltmp8                  #   Call between .Ltmp8 and .Ltmp9
	.uleb128 .Ltmp10-.Lfunc_begin0          #     jumps to .Ltmp10
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp11-.Lfunc_begin0          # >> Call Site 6 <<
	.uleb128 .Ltmp12-.Ltmp11                #   Call between .Ltmp11 and .Ltmp12
	.uleb128 .Ltmp13-.Lfunc_begin0          #     jumps to .Ltmp13
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp12-.Lfunc_begin0          # >> Call Site 7 <<
	.uleb128 .Lfunc_end0-.Ltmp12            #   Call between .Ltmp12 and .Lfunc_end0
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end0:
	.p2align	2, 0x0
                                        # -- End function
	.section	.text._ZN4sycl3_V16detail16PropertyListBaseD2Ev,"axG",@progbits,_ZN4sycl3_V16detail16PropertyListBaseD2Ev,comdat
	.weak	_ZN4sycl3_V16detail16PropertyListBaseD2Ev # -- Begin function _ZN4sycl3_V16detail16PropertyListBaseD2Ev
	.p2align	1
	.prefalign	4, .Lfunc_end1, nop
	.type	_ZN4sycl3_V16detail16PropertyListBaseD2Ev,@function
_ZN4sycl3_V16detail16PropertyListBaseD2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%r15
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%r13
	.cfi_def_cfa_offset 32
	pushq	%r12
	.cfi_def_cfa_offset 40
	pushq	%rbx
	.cfi_def_cfa_offset 48
	.cfi_offset %rbx, -48
	.cfi_offset %r12, -40
	.cfi_offset %r13, -32
	.cfi_offset %r14, -24
	.cfi_offset %r15, -16
	movq	%rdi, %r14
	movq	8(%rdi), %rbx
	movq	16(%rdi), %r12
	cmpq	%r12, %rbx
	je	.LBB1_12
# %bb.1:
	movabsq	$4294967297, %r13               # imm = 0x100000001
	jmp	.LBB1_2
	.p2align	4
.LBB1_4:                                #   in Loop: Header=BB1_2 Depth=1
	movq	$0, 8(%r15)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*16(%rax)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*24(%rax)
.LBB1_10:                               #   in Loop: Header=BB1_2 Depth=1
	addq	$16, %rbx
	cmpq	%r12, %rbx
	je	.LBB1_11
.LBB1_2:                                # =>This Inner Loop Header: Depth=1
	movq	8(%rbx), %r15
	testq	%r15, %r15
	je	.LBB1_10
# %bb.3:                                #   in Loop: Header=BB1_2 Depth=1
	movq	8(%r15), %rax
	cmpq	%r13, %rax
	je	.LBB1_4
# %bb.5:                                #   in Loop: Header=BB1_2 Depth=1
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB1_7
# %bb.6:                                #   in Loop: Header=BB1_2 Depth=1
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB1_10
	jmp	.LBB1_9
.LBB1_7:                                #   in Loop: Header=BB1_2 Depth=1
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB1_10
.LBB1_9:                                #   in Loop: Header=BB1_2 Depth=1
	movq	%r15, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB1_10
.LBB1_11:
	movq	8(%r14), %rbx
.LBB1_12:
	testq	%rbx, %rbx
	je	.LBB1_13
# %bb.14:
	movq	24(%r14), %rsi
	subq	%rbx, %rsi
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	jmp	_ZdlPvm                         # TAILCALL
.LBB1_13:
	.cfi_def_cfa_offset 48
	popq	%rbx
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end1:
	.size	_ZN4sycl3_V16detail16PropertyListBaseD2Ev, .Lfunc_end1-_ZN4sycl3_V16detail16PropertyListBaseD2Ev
	.cfi_endproc
                                        # -- End function
	.section	.text._ZN4sycl3_V15eventD2Ev,"axG",@progbits,_ZN4sycl3_V15eventD2Ev,comdat
	.weak	_ZN4sycl3_V15eventD2Ev          # -- Begin function _ZN4sycl3_V15eventD2Ev
	.p2align	1
	.prefalign	4, .Lfunc_end2, nop
	.type	_ZN4sycl3_V15eventD2Ev,@function
_ZN4sycl3_V15eventD2Ev:                 # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	8(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB2_6
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB2_2
# %bb.7:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB2_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB2_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB2_8
.LBB2_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB2_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB2_6
.LBB2_8:
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end2:
	.size	_ZN4sycl3_V15eventD2Ev, .Lfunc_end2-_ZN4sycl3_V15eventD2Ev
	.cfi_endproc
                                        # -- End function
	.text
	.globl	_ZN8moe_sycl12MoeSyclLayerD2Ev  # -- Begin function _ZN8moe_sycl12MoeSyclLayerD2Ev
	.p2align	1
	.prefalign	4, .Lfunc_end3, nop
	.type	_ZN8moe_sycl12MoeSyclLayerD2Ev,@function
_ZN8moe_sycl12MoeSyclLayerD2Ev:         # 
.Lfunc_begin1:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception1
# %bb.0:
	pushq	%r15
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%r13
	.cfi_def_cfa_offset 32
	pushq	%r12
	.cfi_def_cfa_offset 40
	pushq	%rbx
	.cfi_def_cfa_offset 48
	subq	$32, %rsp
	.cfi_def_cfa_offset 80
	.cfi_offset %rbx, -48
	.cfi_offset %r12, -40
	.cfi_offset %r13, -32
	.cfi_offset %r14, -24
	.cfi_offset %r15, -16
	movq	%rdi, %rbx
	movq	80(%rdi), %rdi
	movabsq	$184683593821, %r14             # imm = 0x2B0000005D
	testq	%rdi, %rdi
	je	.LBB3_3
# %bb.1:
	movq	8(%rbx), %rsi
	movq	$.L.str, 8(%rsp)
	movq	$.L.str.3, 16(%rsp)
	movq	%r14, 24(%rsp)
.Ltmp14:                                # EH_LABEL
	leaq	8(%rsp), %rdx
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.Ltmp15:                                # EH_LABEL
# %bb.2:
	movq	$0, 80(%rbx)
.LBB3_3:
	movq	88(%rbx), %rdi
	testq	%rdi, %rdi
	je	.LBB3_6
# %bb.4:
	movq	8(%rbx), %rsi
	movq	$.L.str, 8(%rsp)
	movq	$.L.str.3, 16(%rsp)
	movq	%r14, 24(%rsp)
.Ltmp16:                                # EH_LABEL
	leaq	8(%rsp), %rdx
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.Ltmp17:                                # EH_LABEL
# %bb.5:
	movq	$0, 88(%rbx)
.LBB3_6:
	movq	128(%rbx), %rdi
	testq	%rdi, %rdi
	je	.LBB3_9
# %bb.7:
	movq	8(%rbx), %rsi
	movq	$.L.str, 8(%rsp)
	movq	$.L.str.3, 16(%rsp)
	movq	%r14, 24(%rsp)
.Ltmp18:                                # EH_LABEL
	leaq	8(%rsp), %rdx
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.Ltmp19:                                # EH_LABEL
# %bb.8:
	movq	$0, 128(%rbx)
.LBB3_9:
	movq	136(%rbx), %rdi
	testq	%rdi, %rdi
	je	.LBB3_12
# %bb.10:
	movq	8(%rbx), %rsi
	movq	$.L.str, 8(%rsp)
	movq	$.L.str.3, 16(%rsp)
	movq	%r14, 24(%rsp)
.Ltmp20:                                # EH_LABEL
	leaq	8(%rsp), %rdx
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.Ltmp21:                                # EH_LABEL
# %bb.11:
	movq	$0, 136(%rbx)
.LBB3_12:
	movq	144(%rbx), %rdi
	testq	%rdi, %rdi
	je	.LBB3_15
# %bb.13:
	movq	8(%rbx), %rsi
	movq	$.L.str, 8(%rsp)
	movq	$.L.str.3, 16(%rsp)
	movq	%r14, 24(%rsp)
.Ltmp22:                                # EH_LABEL
	leaq	8(%rsp), %rdx
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.Ltmp23:                                # EH_LABEL
# %bb.14:
	movq	$0, 144(%rbx)
.LBB3_15:
	movq	152(%rbx), %rdi
	testq	%rdi, %rdi
	je	.LBB3_18
# %bb.16:
	movq	8(%rbx), %rsi
	movq	$.L.str, 8(%rsp)
	movq	$.L.str.3, 16(%rsp)
	movq	%r14, 24(%rsp)
.Ltmp24:                                # EH_LABEL
	leaq	8(%rsp), %rdx
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.Ltmp25:                                # EH_LABEL
# %bb.17:
	movq	$0, 152(%rbx)
.LBB3_18:
	movq	160(%rbx), %rdi
	testq	%rdi, %rdi
	je	.LBB3_21
# %bb.19:
	movq	8(%rbx), %rsi
	movq	$.L.str, 8(%rsp)
	movq	$.L.str.3, 16(%rsp)
	movq	%r14, 24(%rsp)
.Ltmp26:                                # EH_LABEL
	leaq	8(%rsp), %rdx
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.Ltmp27:                                # EH_LABEL
# %bb.20:
	movq	$0, 160(%rbx)
.LBB3_21:
	movq	56(%rbx), %r14
	movq	64(%rbx), %r12
	cmpq	%r12, %r14
	je	.LBB3_33
# %bb.22:
	movabsq	$4294967297, %r13               # imm = 0x100000001
	jmp	.LBB3_23
	.p2align	4
.LBB3_25:                               #   in Loop: Header=BB3_23 Depth=1
	movq	$0, 8(%r15)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*16(%rax)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*24(%rax)
.LBB3_31:                               #   in Loop: Header=BB3_23 Depth=1
	addq	$16, %r14
	cmpq	%r12, %r14
	je	.LBB3_32
.LBB3_23:                               # =>This Inner Loop Header: Depth=1
	movq	8(%r14), %r15
	testq	%r15, %r15
	je	.LBB3_31
# %bb.24:                               #   in Loop: Header=BB3_23 Depth=1
	movq	8(%r15), %rax
	cmpq	%r13, %rax
	je	.LBB3_25
# %bb.26:                               #   in Loop: Header=BB3_23 Depth=1
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB3_28
# %bb.27:                               #   in Loop: Header=BB3_23 Depth=1
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB3_31
	jmp	.LBB3_30
.LBB3_28:                               #   in Loop: Header=BB3_23 Depth=1
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB3_31
.LBB3_30:                               #   in Loop: Header=BB3_23 Depth=1
	movq	%r15, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB3_31
.LBB3_32:
	movq	56(%rbx), %r14
.LBB3_33:
	testq	%r14, %r14
	je	.LBB3_35
# %bb.34:
	movq	72(%rbx), %rsi
	subq	%r14, %rsi
	movq	%r14, %rdi
	callq	_ZdlPvm
.LBB3_35:
	addq	$32, %rsp
	.cfi_def_cfa_offset 48
	popq	%rbx
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	retq
.LBB3_36:
	.cfi_def_cfa_offset 80
.Ltmp28:                                # EH_LABEL
	movq	%rax, %rdi
	callq	__clang_call_terminate
.Lfunc_end3:
	.size	_ZN8moe_sycl12MoeSyclLayerD2Ev, .Lfunc_end3-_ZN8moe_sycl12MoeSyclLayerD2Ev
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table3:
.Lexception1:
	.byte	255                             # @LPStart Encoding = omit
	.byte	3                               # @TType Encoding = udata4
	.uleb128 .Lttbase0-.Lttbaseref0
.Lttbaseref0:
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end1-.Lcst_begin1
.Lcst_begin1:
	.uleb128 .Ltmp14-.Lfunc_begin1          # >> Call Site 1 <<
	.uleb128 .Ltmp27-.Ltmp14                #   Call between .Ltmp14 and .Ltmp27
	.uleb128 .Ltmp28-.Lfunc_begin1          #     jumps to .Ltmp28
	.byte	1                               #   On action: 1
	.uleb128 .Ltmp27-.Lfunc_begin1          # >> Call Site 2 <<
	.uleb128 .Lfunc_end3-.Ltmp27            #   Call between .Ltmp27 and .Lfunc_end3
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end1:
	.byte	1                               # >> Action Record 1 <<
                                        #   Catch TypeInfo 1
	.byte	0                               #   No further actions
	.p2align	2, 0x0
                                        # >> Catch TypeInfos <<
	.long	0                               # TypeInfo 1
.Lttbase0:
	.p2align	2, 0x0
                                        # -- End function
	.section	.text.__clang_call_terminate,"axG",@progbits,__clang_call_terminate,comdat
	.hidden	__clang_call_terminate          # -- Begin function __clang_call_terminate
	.weak	__clang_call_terminate
	.prefalign	4, .Lfunc_end4, nop
	.type	__clang_call_terminate,@function
__clang_call_terminate:                 # 
	.cfi_startproc
# %bb.0:
	pushq	%rax
	.cfi_def_cfa_offset 16
	callq	__cxa_begin_catch
	callq	_ZSt9terminatev
.Lfunc_end4:
	.size	__clang_call_terminate, .Lfunc_end4-__clang_call_terminate
	.cfi_endproc
                                        # -- End function
	.text
	.globl	_ZN8moe_sycl12MoeSyclLayer9ensure_wsEii # -- Begin function _ZN8moe_sycl12MoeSyclLayer9ensure_wsEii
	.p2align	1
	.prefalign	4, .Lfunc_end5, nop
	.type	_ZN8moe_sycl12MoeSyclLayer9ensure_wsEii,@function
_ZN8moe_sycl12MoeSyclLayer9ensure_wsEii: # 
	.cfi_startproc
# %bb.0:
	cmpl	48(%rdi), %esi
	jle	.LBB5_2
# %bb.1:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%rbx
	.cfi_def_cfa_offset 40
	pushq	%rax
	.cfi_def_cfa_offset 48
	.cfi_offset %rbx, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	leaq	128(%rdi), %rax
	movslq	%esi, %r14
	leaq	(,%r14,8), %r15
	movslq	20(%rdi), %rdx
	imulq	%r15, %rdx
	movq	%rdi, %rbx
	movl	%esi, %ebp
	movq	%rax, %rsi
	callq	_ZZN8moe_sycl12MoeSyclLayer9ensure_wsEiiENKUlRPT_mE_clIfEEDaS3_m
	leaq	136(%rbx), %rsi
	movslq	24(%rbx), %rdx
	imulq	%r15, %rdx
	movq	%rbx, %rdi
	callq	_ZZN8moe_sycl12MoeSyclLayer9ensure_wsEiiENKUlRPT_mE_clIfEEDaS3_m
	leaq	144(%rbx), %rsi
	shlq	$2, %r14
	movslq	24(%rbx), %rdx
	imulq	%r14, %rdx
	movq	%rbx, %rdi
	callq	_ZZN8moe_sycl12MoeSyclLayer9ensure_wsEiiENKUlRPT_mE_clIfEEDaS3_m
	leaq	152(%rbx), %rsi
	movslq	24(%rbx), %rdx
	imulq	%r14, %rdx
	movq	%rbx, %rdi
	callq	_ZZN8moe_sycl12MoeSyclLayer9ensure_wsEiiENKUlRPT_mE_clIfEEDaS3_m
	leaq	160(%rbx), %rsi
	movslq	20(%rbx), %rdx
	imulq	%r14, %rdx
	movq	%rbx, %rdi
	callq	_ZZN8moe_sycl12MoeSyclLayer9ensure_wsEiiENKUlRPT_mE_clIfEEDaS3_m
	movl	%ebp, 48(%rbx)
	addq	$8, %rsp
	.cfi_def_cfa_offset 40
	popq	%rbx
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	.cfi_restore %rbx
	.cfi_restore %r14
	.cfi_restore %r15
	.cfi_restore %rbp
.LBB5_2:
	retq
.Lfunc_end5:
	.size	_ZN8moe_sycl12MoeSyclLayer9ensure_wsEii, .Lfunc_end5-_ZN8moe_sycl12MoeSyclLayer9ensure_wsEii
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZZN8moe_sycl12MoeSyclLayer9ensure_wsEiiENKUlRPT_mE_clIfEEDaS3_m
	.prefalign	4, .Lfunc_end6, nop
	.type	_ZZN8moe_sycl12MoeSyclLayer9ensure_wsEiiENKUlRPT_mE_clIfEEDaS3_m,@function
_ZZN8moe_sycl12MoeSyclLayer9ensure_wsEiiENKUlRPT_mE_clIfEEDaS3_m: # 
.Lfunc_begin2:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception2
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$104, %rsp
	.cfi_def_cfa_offset 160
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rdx, %r14
	movq	%rsi, %r15
	movq	%rdi, %r13
	movq	(%rsi), %rdi
	testq	%rdi, %rdi
	je	.LBB6_2
# %bb.1:
	movq	8(%r13), %rsi
	movq	$.L.str, (%rsp)
	movq	$.L.str.3, 8(%rsp)
	movabsq	$68719476837, %rax              # imm = 0x1000000065
	movq	%rax, 16(%rsp)
	movq	%rsp, %rdx
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.LBB6_2:
	movq	8(%r13), %r12
	xorps	%xmm0, %xmm0
	movups	%xmm0, 16(%rsp)                 # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, (%rsp)                   # AlignMOV convert to UnAlignMOV 
	movq	$.L.str, 32(%rsp)
	movq	$.L.str.3, 40(%rsp)
	movabsq	$55834574951, %rax              # imm = 0xD00000067
	movq	%rax, 48(%rsp)
.Ltmp29:                                # EH_LABEL
	leaq	80(%rsp), %rdi
	movq	%r12, %rsi
	callq	_ZNK4sycl3_V15queue10get_deviceEv
.Ltmp30:                                # EH_LABEL
# %bb.3:
.Ltmp31:                                # EH_LABEL
	leaq	64(%rsp), %rdi
	movq	%r12, %rsi
	callq	_ZNK4sycl3_V15queue11get_contextEv
.Ltmp32:                                # EH_LABEL
# %bb.4:
	shlq	$2, %r14
.Ltmp34:                                # EH_LABEL
	leaq	80(%rsp), %rdx
	leaq	64(%rsp), %rcx
	movq	%rsp, %r8
	leaq	32(%rsp), %r9
	movl	$4, %edi
	movq	%r14, %rsi
	callq	_ZN4sycl3_V120aligned_alloc_deviceEmmRKNS0_6deviceERKNS0_7contextERKNS0_13property_listERKNS0_6detail13code_locationE
.Ltmp35:                                # EH_LABEL
# %bb.5:
	movabsq	$4294967297, %rbp               # imm = 0x100000001
	movq	72(%rsp), %r12
	testq	%r12, %r12
	je	.LBB6_14
# %bb.6:
	movq	8(%r12), %rcx
	cmpq	%rbp, %rcx
	jne	.LBB6_8
# %bb.7:
	movq	$0, 8(%r12)
	movq	(%r12), %rcx
	movq	%r12, %rdi
	movq	%rax, %rbx
	callq	*16(%rcx)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*24(%rax)
.LBB6_13:
	movq	%rbx, %rax
	jmp	.LBB6_14
.LBB6_8:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB6_10
# %bb.9:
	leal	-1(%rcx), %edx
	movl	%edx, 8(%r12)
	cmpl	$1, %ecx
	je	.LBB6_12
.LBB6_14:
	movq	%rax, (%r15)
	movq	8(%rsp), %r12
	movq	16(%rsp), %rbx
	cmpq	%rbx, %r12
	je	.LBB6_26
# %bb.15:
	movq	%r13, 56(%rsp)                  # 8-byte Spill
	jmp	.LBB6_16
	.p2align	4
.LBB6_18:                               #   in Loop: Header=BB6_16 Depth=1
	movq	$0, 8(%r13)
	movq	(%r13), %rax
	movq	%r13, %rdi
	callq	*16(%rax)
	movq	(%r13), %rax
	movq	%r13, %rdi
	callq	*24(%rax)
.LBB6_24:                               #   in Loop: Header=BB6_16 Depth=1
	addq	$16, %r12
	cmpq	%rbx, %r12
	je	.LBB6_25
.LBB6_16:                               # =>This Inner Loop Header: Depth=1
	movq	8(%r12), %r13
	testq	%r13, %r13
	je	.LBB6_24
# %bb.17:                               #   in Loop: Header=BB6_16 Depth=1
	movq	8(%r13), %rax
	cmpq	%rbp, %rax
	je	.LBB6_18
# %bb.19:                               #   in Loop: Header=BB6_16 Depth=1
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB6_21
# %bb.20:                               #   in Loop: Header=BB6_16 Depth=1
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r13)
	cmpl	$1, %eax
	jne	.LBB6_24
	jmp	.LBB6_23
.LBB6_21:                               #   in Loop: Header=BB6_16 Depth=1
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r13)
	cmpl	$1, %eax
	jne	.LBB6_24
.LBB6_23:                               #   in Loop: Header=BB6_16 Depth=1
	movq	%r13, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB6_24
.LBB6_25:
	movq	8(%rsp), %r12
	movq	56(%rsp), %r13                  # 8-byte Reload
.LBB6_26:
	testq	%r12, %r12
	je	.LBB6_28
# %bb.27:
	movq	24(%rsp), %rsi
	subq	%r12, %rsi
	movq	%r12, %rdi
	callq	_ZdlPvm
.LBB6_28:
	movq	8(%r13), %rsi
	movq	(%r15), %rdx
	movq	$.L.str, (%rsp)
	movq	$.L.str.3, 8(%rsp)
	movabsq	$51539607657, %rax              # imm = 0xC00000069
	movq	%rax, 16(%rsp)
	leaq	88(%rsp), %rdi
	movq	%rsp, %r9
	xorl	%ecx, %ecx
	movq	%r14, %r8
	callq	_ZN4sycl3_V15queue6memsetEPvimRKNS0_6detail13code_locationE
	movq	96(%rsp), %r14
	testq	%r14, %r14
	je	.LBB6_36
# %bb.29:
	movq	8(%r14), %rax
	cmpq	%rbp, %rax
	jne	.LBB6_31
# %bb.30:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	jmp	.LBB6_36
.LBB6_31:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB6_33
# %bb.32:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	je	.LBB6_35
.LBB6_36:
	movq	8(%r13), %rbx
	movq	$.L.str, (%rsp)
	movq	$.L.str.3, 8(%rsp)
	movabsq	$51539607658, %rax              # imm = 0xC0000006A
	movq	%rax, 16(%rsp)
	leaq	32(%rsp), %r14
	movq	%rsp, %rsi
	movq	%r14, %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tC1ERKNS1_13code_locationE
.Ltmp37:                                # EH_LABEL
	movq	%r14, %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_t5queryEv
.Ltmp38:                                # EH_LABEL
# %bb.37:
.Ltmp39:                                # EH_LABEL
	movq	%rbx, %rdi
	movq	%rax, %rsi
	callq	_ZN4sycl3_V15queue10wait_proxyERKNS0_6detail13code_locationE
.Ltmp40:                                # EH_LABEL
# %bb.38:
	leaq	32(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
	addq	$104, %rsp
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB6_10:
	.cfi_def_cfa_offset 160
	movl	$-1, %ecx
	lock		xaddl	%ecx, 8(%r12)
	cmpl	$1, %ecx
	jne	.LBB6_14
.LBB6_12:
	movq	%r12, %rdi
	movq	%rax, %rbx
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB6_13
.LBB6_33:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB6_36
.LBB6_35:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB6_36
.LBB6_42:
.Ltmp36:                                # EH_LABEL
	movq	%rax, %rbx
	leaq	64(%rsp), %rdi
	callq	_ZN4sycl3_V17contextD2Ev
	jmp	.LBB6_40
.LBB6_43:
.Ltmp41:                                # EH_LABEL
	movq	%rax, %rbx
	leaq	32(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.LBB6_39:
.Ltmp33:                                # EH_LABEL
	movq	%rax, %rbx
.LBB6_40:
	movq	%rsp, %rdi
	callq	_ZN4sycl3_V16detail16PropertyListBaseD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end6:
	.size	_ZZN8moe_sycl12MoeSyclLayer9ensure_wsEiiENKUlRPT_mE_clIfEEDaS3_m, .Lfunc_end6-_ZZN8moe_sycl12MoeSyclLayer9ensure_wsEiiENKUlRPT_mE_clIfEEDaS3_m
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table6:
.Lexception2:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end2-.Lcst_begin2
.Lcst_begin2:
	.uleb128 .Lfunc_begin2-.Lfunc_begin2    # >> Call Site 1 <<
	.uleb128 .Ltmp29-.Lfunc_begin2          #   Call between .Lfunc_begin2 and .Ltmp29
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp29-.Lfunc_begin2          # >> Call Site 2 <<
	.uleb128 .Ltmp32-.Ltmp29                #   Call between .Ltmp29 and .Ltmp32
	.uleb128 .Ltmp33-.Lfunc_begin2          #     jumps to .Ltmp33
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp34-.Lfunc_begin2          # >> Call Site 3 <<
	.uleb128 .Ltmp35-.Ltmp34                #   Call between .Ltmp34 and .Ltmp35
	.uleb128 .Ltmp36-.Lfunc_begin2          #     jumps to .Ltmp36
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp35-.Lfunc_begin2          # >> Call Site 4 <<
	.uleb128 .Ltmp37-.Ltmp35                #   Call between .Ltmp35 and .Ltmp37
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp37-.Lfunc_begin2          # >> Call Site 5 <<
	.uleb128 .Ltmp40-.Ltmp37                #   Call between .Ltmp37 and .Ltmp40
	.uleb128 .Ltmp41-.Lfunc_begin2          #     jumps to .Ltmp41
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp40-.Lfunc_begin2          # >> Call Site 6 <<
	.uleb128 .Lfunc_end6-.Ltmp40            #   Call between .Ltmp40 and .Lfunc_end6
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end2:
	.p2align	2, 0x0
                                        # -- End function
	.section	.rodata.cst4,"aM",@progbits,4
	.p2align	2, 0x0                          # -- Begin function _ZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfi
.LCPI7_0:
	.long	0x7f800000                      #  +Inf
	.section	.rodata.cst16,"aM",@progbits,16
	.p2align	4, 0x0
.LCPI7_1:
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	8                               # 0x8
.LCPI7_2:
	.long	96                              # 0x60
	.long	96                              # 0x60
	.long	96                              # 0x60
	.long	96                              # 0x60
.LCPI7_3:
	.long	0                               # 0x0
	.long	16                              # 0x10
	.long	128                             # 0x80
	.long	144                             # 0x90
.LCPI7_4:
	.short	255                             # 0xff
	.short	0                               # 0x0
	.short	255                             # 0xff
	.short	0                               # 0x0
	.short	255                             # 0xff
	.short	0                               # 0x0
	.short	255                             # 0xff
	.short	0                               # 0x0
.LCPI7_5:
	.byte	0                               # 0x0
	.byte	1                               # 0x1
	.byte	2                               # 0x2
	.byte	3                               # 0x3
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
	.zero	1
.LCPI7_6:
	.byte	0                               # 0x0
	.byte	1                               # 0x1
	.byte	2                               # 0x2
	.byte	3                               # 0x3
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.byte	0                               # 0x0
	.text
	.globl	_ZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfi
	.p2align	1
	.prefalign	4, .Lfunc_end7, nop
	.type	_ZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfi,@function
_ZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfi: # 
.Lfunc_begin3:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception3
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$824, %rsp                      # imm = 0x338
	.cfi_def_cfa_offset 880
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rcx, %r15
	movl	%edx, %ebp
	movq	%rsi, 600(%rsp)                 # 8-byte Spill
	movq	%rdi, %rbx
	movslq	880(%rsp), %r14
	movq	%r8, 672(%rsp)
	movq	%r9, 664(%rsp)
	movl	20(%rdi), %eax
	movl	%eax, 8(%rsp)
	movl	24(%rdi), %eax
	movl	%eax, 28(%rsp)
	movl	28(%rdi), %eax
	addl	%eax, %eax
	addl	32(%rdi), %eax
	movl	%eax, 212(%rsp)
	movl	16(%rdi), %ecx
	movl	%ecx, 60(%rsp)
	shll	$2, %eax
	movl	%eax, 208(%rsp)
	movzbl	44(%rdi), %eax
	movb	%al, 7(%rsp)
	cmpb	$1, %al
	movl	$2, %eax
	sbbl	$0, %eax
	movl	%eax, 204(%rsp)
	movl	36(%rdi), %eax
	movl	%eax, 200(%rsp)
	movss	40(%rdi), %xmm0                 # xmm0 = mem[0],zero,zero,zero
	xorps	%xmm1, %xmm1
	cmpneqss	%xmm0, %xmm1
	andps	%xmm1, %xmm0
	movss	.LCPI7_0(%rip), %xmm2           # xmm2 = [+Inf,0.0E+0,0.0E+0,0.0E+0]
	andnps	%xmm2, %xmm1
	orps	%xmm0, %xmm1
	movss	%xmm1, 196(%rsp)
	movq	8(%rdi), %r12
                                        # implicit-def: $edx
	movl	%ebp, %esi
	callq	_ZN8moe_sycl12MoeSyclLayer9ensure_wsEii
	movl	%ebp, 56(%rsp)
	movslq	%ebp, %rax
	shlq	$3, %rax
	leaq	(%rax,%rax,4), %rdx
	addq	$56, %rdx
	andq	$-64, %rdx
	movq	%rdx, 304(%rsp)                 # 8-byte Spill
	leaq	(%rdx,%r14,4), %r14
	addq	$64, %r14
	movq	32(%r15), %r13
	movq	%r15, 608(%rsp)                 # 8-byte Spill
	subq	24(%r15), %r13
	andq	$-64, %r14
	addq	%r14, %r13
	cmpq	96(%rbx), %r13
	movq	%r12, 168(%rsp)                 # 8-byte Spill
	jbe	.LBB7_36
# %bb.1:
	movq	104(%rbx), %rdi
	testq	%rdi, %rdi
	je	.LBB7_3
# %bb.2:
	movq	$.L.str, 336(%rsp)
	movq	$.L.str.2, 344(%rsp)
	movabsq	$90194313358, %rax              # imm = 0x150000008E
	movq	%rax, 352(%rsp)
	leaq	336(%rsp), %rdx
	movq	%r12, %rsi
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.LBB7_3:
	movq	112(%rbx), %rdi
	testq	%rdi, %rdi
	je	.LBB7_5
# %bb.4:
	movq	$.L.str, 336(%rsp)
	movq	$.L.str.2, 344(%rsp)
	movabsq	$94489280655, %rax              # imm = 0x160000008F
	movq	%rax, 352(%rsp)
	leaq	336(%rsp), %rdx
	movq	%r12, %rsi
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.LBB7_5:
	movq	$.L.str, 336(%rsp)
	movq	$.L.str.2, 344(%rsp)
	movabsq	$107374182544, %rax             # imm = 0x1900000090
	movq	%rax, 352(%rsp)
	leaq	336(%rsp), %rdx
	movq	%r13, %rdi
	movq	%r12, %rsi
	callq	_ZN4sycl3_V111malloc_hostEmRKNS0_5queueERKNS0_6detail13code_locationE
	movq	%rax, 104(%rbx)
	movq	$.L.str, 336(%rsp)
	movq	$.L.str.2, 344(%rsp)
	movabsq	$111669149841, %rax             # imm = 0x1A00000091
	movq	%rax, 352(%rsp)
	leaq	336(%rsp), %rdx
	movq	%r13, %rdi
	movq	%r12, %rsi
	callq	_ZN4sycl3_V111malloc_hostEmRKNS0_5queueERKNS0_6detail13code_locationE
	movq	%rax, 112(%rbx)
	movq	88(%rbx), %rdi
	testq	%rdi, %rdi
	je	.LBB7_7
# %bb.6:
	movq	$.L.str, 336(%rsp)
	movq	$.L.str.2, 344(%rsp)
	movabsq	$94489280658, %rax              # imm = 0x1600000092
	movq	%rax, 352(%rsp)
	leaq	336(%rsp), %rdx
	movq	%r12, %rsi
	callq	_ZN4sycl3_V14freeEPvRKNS0_5queueERKNS0_6detail13code_locationE
.LBB7_7:
	xorps	%xmm0, %xmm0
	movups	%xmm0, 352(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 336(%rsp)                # AlignMOV convert to UnAlignMOV 
	movq	$.L.str, 680(%rsp)
	movq	$.L.str.2, 688(%rsp)
	movabsq	$128849019027, %rax             # imm = 0x1E00000093
	movq	%rax, 696(%rsp)
.Ltmp42:                                # EH_LABEL
	leaq	128(%rsp), %rdi
	movq	%r12, %rsi
	callq	_ZNK4sycl3_V15queue10get_deviceEv
.Ltmp43:                                # EH_LABEL
# %bb.8:
.Ltmp44:                                # EH_LABEL
	leaq	216(%rsp), %rdi
	movq	%r12, %rsi
	callq	_ZNK4sycl3_V15queue11get_contextEv
.Ltmp45:                                # EH_LABEL
# %bb.9:
.Ltmp47:                                # EH_LABEL
	leaq	128(%rsp), %rdx
	leaq	216(%rsp), %rcx
	leaq	336(%rsp), %r8
	leaq	680(%rsp), %r9
	movl	$1, %edi
	movq	%r13, %rsi
	callq	_ZN4sycl3_V120aligned_alloc_deviceEmmRKNS0_6deviceERKNS0_7contextERKNS0_13property_listERKNS0_6detail13code_locationE
.Ltmp48:                                # EH_LABEL
# %bb.10:
	movq	%r14, 176(%rsp)                 # 8-byte Spill
	movq	224(%rsp), %rbp
	testq	%rbp, %rbp
	je	.LBB7_16
# %bb.11:
	movq	8(%rbp), %rcx
	movabsq	$4294967297, %rdx               # imm = 0x100000001
	cmpq	%rdx, %rcx
	jne	.LBB7_14
# %bb.12:
	movq	$0, 8(%rbp)
	movq	(%rbp), %rcx
	movq	%rbp, %rdi
	movq	%rax, %r14
	callq	*16(%rcx)
	movq	(%rbp), %rax
	movq	%rbp, %rdi
	callq	*24(%rax)
.LBB7_13:
	movq	%r14, %rax
	jmp	.LBB7_16
.LBB7_14:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_141
# %bb.15:
	leal	-1(%rcx), %edx
	movl	%edx, 8(%rbp)
	cmpl	$1, %ecx
	je	.LBB7_142
.LBB7_16:
	movq	%rax, 88(%rbx)
	movq	344(%rsp), %rbp
	movq	352(%rsp), %r14
	cmpq	%r14, %rbp
	jne	.LBB7_19
	jmp	.LBB7_26
	.p2align	4
.LBB7_17:                               #   in Loop: Header=BB7_19 Depth=1
	movq	$0, 8(%r12)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*16(%rax)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*24(%rax)
.LBB7_18:                               #   in Loop: Header=BB7_19 Depth=1
	addq	$16, %rbp
	cmpq	%r14, %rbp
	je	.LBB7_25
.LBB7_19:                               # =>This Inner Loop Header: Depth=1
	movq	8(%rbp), %r12
	testq	%r12, %r12
	je	.LBB7_18
# %bb.20:                               #   in Loop: Header=BB7_19 Depth=1
	movq	8(%r12), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	je	.LBB7_17
# %bb.21:                               #   in Loop: Header=BB7_19 Depth=1
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_23
# %bb.22:                               #   in Loop: Header=BB7_19 Depth=1
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r12)
	cmpl	$1, %eax
	jne	.LBB7_18
	jmp	.LBB7_24
.LBB7_23:                               #   in Loop: Header=BB7_19 Depth=1
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r12)
	cmpl	$1, %eax
	jne	.LBB7_18
.LBB7_24:                               #   in Loop: Header=BB7_19 Depth=1
	movq	%r12, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB7_18
.LBB7_25:
	movq	344(%rsp), %rbp
	movq	168(%rsp), %r12                 # 8-byte Reload
.LBB7_26:
	testq	%rbp, %rbp
	movq	176(%rsp), %r14                 # 8-byte Reload
	je	.LBB7_28
# %bb.27:
	movq	360(%rsp), %rsi
	subq	%rbp, %rsi
	movq	%rbp, %rdi
	callq	_ZdlPvm
.LBB7_28:
	movq	88(%rbx), %rdx
	movq	$.L.str, 336(%rsp)
	movq	$.L.str.2, 344(%rsp)
	movabsq	$47244640404, %rax              # imm = 0xB00000094
	movq	%rax, 352(%rsp)
	leaq	808(%rsp), %rdi
	leaq	336(%rsp), %r9
	movq	%r12, %rsi
	xorl	%ecx, %ecx
	movq	%r13, %r8
	callq	_ZN4sycl3_V15queue6memsetEPvimRKNS0_6detail13code_locationE
	movq	816(%rsp), %rbp
	testq	%rbp, %rbp
	je	.LBB7_33
# %bb.29:
	movq	8(%rbp), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB7_31
# %bb.30:
	movq	$0, 8(%rbp)
	movq	(%rbp), %rax
	movq	%rbp, %rdi
	callq	*16(%rax)
	movq	(%rbp), %rax
	movq	%rbp, %rdi
	callq	*24(%rax)
	jmp	.LBB7_33
.LBB7_31:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_143
# %bb.32:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbp)
	cmpl	$1, %eax
	je	.LBB7_144
.LBB7_33:
	movq	$.L.str, 336(%rsp)
	movq	$.L.str.2, 344(%rsp)
	movabsq	$47244640405, %rax              # imm = 0xB00000095
	movq	%rax, 352(%rsp)
	leaq	680(%rsp), %r12
	leaq	336(%rsp), %rsi
	movq	%r12, %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tC1ERKNS1_13code_locationE
.Ltmp50:                                # EH_LABEL
	movq	%r12, %rdi
	movq	168(%rsp), %r12                 # 8-byte Reload
	callq	_ZN4sycl3_V16detail14tls_code_loc_t5queryEv
.Ltmp51:                                # EH_LABEL
# %bb.34:
.Ltmp52:                                # EH_LABEL
	movq	%r12, %rdi
	movq	%rax, %rsi
	callq	_ZN4sycl3_V15queue10wait_proxyERKNS0_6detail13code_locationE
.Ltmp53:                                # EH_LABEL
# %bb.35:
	leaq	680(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
	movq	%r13, 96(%rbx)
	movslq	56(%rsp), %rax
	shlq	$3, %rax
.LBB7_36:
	leaq	(%rax,%rax,4), %rdx
	movzbl	120(%rbx), %eax
	movl	%eax, %ecx
	xorb	$1, %cl
	movb	%cl, 120(%rbx)
	movq	104(%rbx,%rax,8), %rbp
	movq	%rbp, %rdi
	movq	600(%rsp), %rsi                 # 8-byte Reload
	callq	_intel_fast_memcpy@PLT
	movq	304(%rsp), %rax                 # 8-byte Reload
	leaq	(%rax,%rbp), %rdi
	movq	608(%rsp), %r15                 # 8-byte Reload
	movq	(%r15), %rsi
	movq	8(%r15), %rdx
	subq	%rsi, %rdx
	callq	_intel_fast_memcpy@PLT
	leaq	(%r14,%rbp), %rdi
	movq	24(%r15), %rsi
	movq	32(%r15), %rdx
	subq	%rsi, %rdx
	callq	_intel_fast_memcpy@PLT
	movq	88(%rbx), %rdx
	movq	$.L.str, 336(%rsp)
	movq	$.L.str.2, 344(%rsp)
	movabsq	$107374182560, %rax             # imm = 0x19000000A0
	movq	%rax, 352(%rsp)
	leaq	648(%rsp), %r15
	leaq	336(%rsp), %r9
	movq	%r15, %rdi
	movq	%r12, %rsi
	movq	%rbp, %rcx
	movq	%r13, %r8
	callq	_ZN4sycl3_V15queue6memcpyEPvPKvmRKNS0_6detail13code_locationE
	cmpb	$0, (%rbx)
	je	.LBB7_49
# %bb.37:
	leaq	56(%rbx), %rdi
	movq	56(%rbx), %r13
	movq	64(%rbx), %r12
	cmpq	%r13, %r12
	je	.LBB7_48
# %bb.38:
	movq	%r14, 176(%rsp)                 # 8-byte Spill
	movq	%r13, %r14
	jmp	.LBB7_41
	.p2align	4
.LBB7_39:                               #   in Loop: Header=BB7_41 Depth=1
	movq	$0, 8(%rbp)
	movq	(%rbp), %rax
	movq	%rbp, %rdi
	callq	*16(%rax)
	movq	(%rbp), %rax
	movq	%rbp, %rdi
	callq	*24(%rax)
.LBB7_40:                               #   in Loop: Header=BB7_41 Depth=1
	addq	$16, %r14
	cmpq	%r12, %r14
	je	.LBB7_47
.LBB7_41:                               # =>This Inner Loop Header: Depth=1
	movq	8(%r14), %rbp
	testq	%rbp, %rbp
	je	.LBB7_40
# %bb.42:                               #   in Loop: Header=BB7_41 Depth=1
	movq	8(%rbp), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	je	.LBB7_39
# %bb.43:                               #   in Loop: Header=BB7_41 Depth=1
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_45
# %bb.44:                               #   in Loop: Header=BB7_41 Depth=1
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbp)
	cmpl	$1, %eax
	jne	.LBB7_40
	jmp	.LBB7_46
.LBB7_45:                               #   in Loop: Header=BB7_41 Depth=1
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbp)
	cmpl	$1, %eax
	jne	.LBB7_40
.LBB7_46:                               #   in Loop: Header=BB7_41 Depth=1
	movq	%rbp, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB7_40
.LBB7_47:
	movq	%r13, 64(%rbx)
	movq	176(%rsp), %r14                 # 8-byte Reload
	leaq	56(%rbx), %rdi
.LBB7_48:
.Ltmp55:                                # EH_LABEL
	leaq	648(%rsp), %rsi
	callq	_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_
.Ltmp56:                                # EH_LABEL
	movq	168(%rsp), %r12                 # 8-byte Reload
.LBB7_49:
	movq	%r15, 88(%rsp)
	movq	%r12, 96(%rsp)
	movq	%rbx, 104(%rsp)
	movq	80(%rbx), %rax
	movq	%rax, 16(%rsp)
	movq	88(%rbx), %rax
	movq	%rax, 184(%rsp)
	movq	304(%rsp), %rcx                 # 8-byte Reload
	addq	%rax, %rcx
	movq	%rcx, 640(%rsp)
	addq	%rax, %r14
	movq	%r14, 632(%rsp)
	movq	128(%rbx), %rax
	movq	%rax, 328(%rsp)
	movq	136(%rbx), %rax
	movq	%rax, 624(%rsp)
	movq	144(%rbx), %rax
	movq	%rax, 616(%rsp)
	movq	152(%rbx), %rax
	movq	%rax, 320(%rsp)
	movq	160(%rbx), %rax
	movl	8(%rsp), %ecx
	leal	127(%rcx), %edx
	testl	%ecx, %ecx
	cmovnsl	%ecx, %edx
	movq	%rax, 312(%rsp)
	sarl	$7, %edx
	movl	%edx, 64(%rsp)
	leaq	64(%rsp), %rax
	movq	%rax, 336(%rsp)
	leaq	56(%rsp), %rax
	movq	%rax, 344(%rsp)
	leaq	204(%rsp), %rbp
	movq	%rbp, 352(%rsp)
	leaq	7(%rsp), %r14
	movq	%r14, 360(%rsp)
	leaq	184(%rsp), %r12
	movq	%r12, 368(%rsp)
	leaq	16(%rsp), %rax
	movq	%rax, 376(%rsp)
	movq	%r15, %rcx
	leaq	60(%rsp), %r15
	movq	%r15, 384(%rsp)
	leaq	328(%rsp), %rax
	movq	%rax, 392(%rsp)
	leaq	8(%rsp), %rax
	movq	%rax, 400(%rsp)
	leaq	672(%rsp), %rax
	movq	%rax, 408(%rsp)
	movq	$.L.str, 680(%rsp)
	movq	$.L.str.3, 688(%rsp)
	movabsq	$73014444195, %rax              # imm = 0x11000000A3
	movq	%rax, 696(%rsp)
	movq	%rcx, 128(%rsp)
	leaq	336(%rsp), %rax
	movq	%rax, 136(%rsp)
	leaq	128(%rsp), %rax
	movq	%rax, 32(%rsp)
	movq	$_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE_EEDaSG_EUlSK_E_E4callEPKvSK_, 40(%rsp)
.Ltmp58:                                # EH_LABEL
	leaq	216(%rsp), %rdi
	leaq	680(%rsp), %rsi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tC1ERKNS1_13code_locationE
.Ltmp59:                                # EH_LABEL
# %bb.50:
	movl	$0, 152(%rsp)
.Ltmp60:                                # EH_LABEL
	leaq	216(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_t5queryEv
.Ltmp61:                                # EH_LABEL
# %bb.51:
	xorl	%r9d, %r9d
	cmpb	$0, 224(%rsp)
	sete	%r9b
.Ltmp62:                                # EH_LABEL
	leaq	112(%rsp), %rdi
	leaq	32(%rsp), %rdx
	leaq	152(%rsp), %rcx
	movq	168(%rsp), %rsi                 # 8-byte Reload
	movq	%rax, %r8
	callq	_ZNK4sycl3_V15queue22submit_with_event_implERKNS0_6detail19type_erased_cgfo_tyERKNS2_3_V114SubmissionInfoERKNS2_13code_locationEb
.Ltmp63:                                # EH_LABEL
# %bb.52:
	leaq	216(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
	movq	88(%rsp), %rax
	movups	112(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	xorps	%xmm1, %xmm1
	movups	%xmm1, 112(%rsp)                # AlignMOV convert to UnAlignMOV 
	movq	8(%rax), %r13
	movups	%xmm0, (%rax)
	testq	%r13, %r13
	je	.LBB7_57
# %bb.53:
	movq	8(%r13), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB7_55
# %bb.54:
	movq	$0, 8(%r13)
	movq	(%r13), %rax
	movq	%r13, %rdi
	callq	*16(%rax)
	movq	(%r13), %rax
	movq	%r13, %rdi
	callq	*24(%rax)
	jmp	.LBB7_57
.LBB7_55:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_123
# %bb.56:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r13)
	cmpl	$1, %eax
	je	.LBB7_124
.LBB7_57:
	movq	120(%rsp), %r13
	testq	%r13, %r13
	je	.LBB7_62
# %bb.58:
	movq	8(%r13), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB7_60
# %bb.59:
	movq	$0, 8(%r13)
	movq	(%r13), %rax
	movq	%r13, %rdi
	callq	*16(%rax)
	movq	(%r13), %rax
	movq	%r13, %rdi
	callq	*24(%rax)
	cmpb	$0, (%rbx)
	jne	.LBB7_63
	jmp	.LBB7_64
.LBB7_60:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_125
# %bb.61:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r13)
	cmpl	$1, %eax
	je	.LBB7_126
.LBB7_62:
	cmpb	$0, (%rbx)
	je	.LBB7_64
.LBB7_63:
	addq	$56, %rbx
	movq	88(%rsp), %rsi
.Ltmp65:                                # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_
.Ltmp66:                                # EH_LABEL
.LBB7_64:
	movq	%rbp, %r10
	movq	%r12, %r13
	movq	%r14, %r12
	movq	%r15, %rdi
	xorps	%xmm0, %xmm0
	movups	%xmm0, 576(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 560(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 544(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 528(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 512(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 496(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 480(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 464(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 448(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 432(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 416(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 400(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 384(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 368(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 352(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 336(%rsp)                # AlignMOV convert to UnAlignMOV 
	xorl	%eax, %eax
	movdqu	.LCPI7_1(%rip), %xmm1           # xmm1 = [8,8,8,8]
                                        # AlignMOV convert to UnAlignMOV 
	movdqu	.LCPI7_2(%rip), %xmm2           # xmm2 = [96,96,96,96]
                                        # AlignMOV convert to UnAlignMOV 
	movdqu	.LCPI7_3(%rip), %xmm3           # xmm3 = [0,16,128,144]
                                        # AlignMOV convert to UnAlignMOV 
	leaq	336(%rsp), %rcx
	movq	%rcx, %xmm4
	pshufd	$68, %xmm4, %xmm4               # xmm4 = xmm4[0,1,0,1]
	movdqu	.LCPI7_4(%rip), %xmm5           # xmm5 = [255,0,255,0,255,0,255,0]
                                        # AlignMOV convert to UnAlignMOV 
	movd	.LCPI7_6(%rip), %xmm6           # xmm6 = [0,1,2,3,0,0,0,0,0,0,0,0,0,0,0,0]
	.p2align	4
.LBB7_65:                               # =>This Inner Loop Header: Depth=1
	movd	%eax, %xmm7
	pshufd	$0, %xmm7, %xmm8                # xmm8 = xmm7[0,0,0,0]
	movdqa	%xmm8, %xmm7
	psrld	$5, %xmm7
	movdqa	%xmm8, %xmm9
	paddd	%xmm9, %xmm9
	pand	%xmm1, %xmm9
	paddd	%xmm7, %xmm9
	movdqa	%xmm8, %xmm7
	pslld	$2, %xmm7
	pand	%xmm2, %xmm7
	paddd	%xmm9, %xmm7
	paddd	%xmm3, %xmm7
	movdqa	%xmm7, %xmm9
	punpckldq	%xmm0, %xmm9            # xmm9 = xmm9[0],xmm0[0],xmm9[1],xmm0[1]
	punpckhdq	%xmm0, %xmm7            # xmm7 = xmm7[2],xmm0[2],xmm7[3],xmm0[3]
	paddq	%xmm4, %xmm7
	paddq	%xmm4, %xmm9
	pand	%xmm5, %xmm8
	packuswb	%xmm8, %xmm8
	packuswb	%xmm8, %xmm8
	por	%xmm6, %xmm8
	movd	%xmm8, %ecx
	movq	%xmm9, %rdx
	movb	%cl, (%rdx)
	pshufd	$238, %xmm9, %xmm8              # xmm8 = xmm9[2,3,2,3]
	movq	%xmm8, %rdx
	movb	%ch, (%rdx)
	movl	%ecx, %edx
	shrl	$16, %edx
	movq	%xmm7, %rsi
	movb	%dl, (%rsi)
	shrl	$24, %ecx
	pshufd	$238, %xmm7, %xmm7              # xmm7 = xmm7[2,3,2,3]
	movq	%xmm7, %rdx
	movb	%cl, (%rdx)
	cmpl	$252, %eax
	leal	4(%rax), %eax
                                        # kill: def $eax killed $eax def $rax
	jb	.LBB7_65
# %bb.66:
	leaq	8(%rsp), %rax
	movq	%rax, 680(%rsp)
	leaq	28(%rsp), %rax
	movq	%rax, 688(%rsp)
	leaq	56(%rsp), %r14
	movq	%r14, %rbp
	movq	%r14, 696(%rsp)
	movq	%r10, 704(%rsp)
	leaq	88(%rsp), %rax
	movq	%rax, 712(%rsp)
	leaq	208(%rsp), %rax
	movq	%rax, 720(%rsp)
	movq	%r12, 728(%rsp)
	movq	%r13, 736(%rsp)
	leaq	16(%rsp), %r15
	movq	%r15, 744(%rsp)
	movq	%rdi, 752(%rsp)
	leaq	320(%rsp), %rax
	movq	%rax, 760(%rsp)
	leaq	328(%rsp), %rax
	movq	%rax, 768(%rsp)
	leaq	336(%rsp), %rax
	movq	%rax, 776(%rsp)
	leaq	212(%rsp), %rax
	movq	%rax, 784(%rsp)
	leaq	312(%rsp), %rax
	movq	%rax, 792(%rsp)
	leaq	624(%rsp), %rbx
	movq	%rbx, 800(%rsp)
.Ltmp68:                                # EH_LABEL
	leaq	680(%rsp), %rdi
	xorl	%esi, %esi
	callq	_ZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEb
.Ltmp69:                                # EH_LABEL
# %bb.67:
	movl	28(%rsp), %eax
	leal	127(%rax), %ecx
	testl	%eax, %eax
	cmovnsl	%eax, %ecx
	sarl	$7, %ecx
	movl	%ecx, 52(%rsp)
	leaq	52(%rsp), %r14
	movq	%r14, 216(%rsp)
	movq	%rbp, 224(%rsp)
	movq	%r13, 232(%rsp)
	movq	%r15, 240(%rsp)
	leaq	60(%rsp), %rax
	movq	%rax, 248(%rsp)
	movq	%r12, 256(%rsp)
	movq	%rbx, 264(%rsp)
	leaq	28(%rsp), %r13
	movq	%r13, 272(%rsp)
	leaq	200(%rsp), %rax
	movq	%rax, 280(%rsp)
	leaq	196(%rsp), %rax
	movq	%rax, 288(%rsp)
	leaq	616(%rsp), %r15
	movq	%r15, 296(%rsp)
	movq	104(%rsp), %rbx
	movq	88(%rsp), %rax
	movq	96(%rsp), %r12
	movq	$.L.str, 128(%rsp)
	movq	$.L.str.3, 136(%rsp)
	movabsq	$73014444195, %rcx              # imm = 0x11000000A3
	movq	%rcx, 144(%rsp)
	movq	%rax, 112(%rsp)
	leaq	216(%rsp), %rax
	movq	%rax, 120(%rsp)
	leaq	112(%rsp), %rax
	movq	%rax, 152(%rsp)
	movq	$_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE0_EEDaSG_EUlSK_E_E4callEPKvSK_, 160(%rsp)
.Ltmp70:                                # EH_LABEL
	leaq	32(%rsp), %rdi
	leaq	128(%rsp), %rsi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tC1ERKNS1_13code_locationE
.Ltmp71:                                # EH_LABEL
# %bb.68:
	movl	$0, 12(%rsp)
.Ltmp72:                                # EH_LABEL
	leaq	32(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_t5queryEv
.Ltmp73:                                # EH_LABEL
# %bb.69:
	xorl	%r9d, %r9d
	cmpb	$0, 40(%rsp)
	sete	%r9b
.Ltmp74:                                # EH_LABEL
	leaq	64(%rsp), %rdi
	leaq	152(%rsp), %rdx
	leaq	12(%rsp), %rcx
	movq	%r12, %rsi
	movq	%rax, %r8
	callq	_ZNK4sycl3_V15queue22submit_with_event_implERKNS0_6detail19type_erased_cgfo_tyERKNS2_3_V114SubmissionInfoERKNS2_13code_locationEb
.Ltmp75:                                # EH_LABEL
# %bb.70:
	leaq	32(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
	movq	88(%rsp), %rax
	movups	64(%rsp), %xmm0                 # AlignMOV convert to UnAlignMOV 
	pxor	%xmm1, %xmm1
	movdqu	%xmm1, 64(%rsp)                 # AlignMOV convert to UnAlignMOV 
	movq	8(%rax), %r12
	movups	%xmm0, (%rax)
	testq	%r12, %r12
	leaq	16(%rsp), %rdx
	je	.LBB7_76
# %bb.71:
	movq	8(%r12), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB7_74
# %bb.72:
	movq	$0, 8(%r12)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*16(%rax)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*24(%rax)
.LBB7_73:
	leaq	16(%rsp), %rdx
	jmp	.LBB7_76
.LBB7_74:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_127
# %bb.75:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r12)
	cmpl	$1, %eax
	je	.LBB7_128
.LBB7_76:
	movq	72(%rsp), %r12
	testq	%r12, %r12
	je	.LBB7_82
# %bb.77:
	movq	8(%r12), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB7_80
# %bb.78:
	movq	$0, 8(%r12)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*16(%rax)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*24(%rax)
.LBB7_79:
	leaq	16(%rsp), %rdx
	jmp	.LBB7_82
.LBB7_80:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_129
# %bb.81:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r12)
	cmpl	$1, %eax
	je	.LBB7_130
.LBB7_82:
	cmpb	$0, (%rbx)
	movq	88(%rsp), %rsi
	je	.LBB7_85
# %bb.83:
	addq	$56, %rbx
.Ltmp77:                                # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_
.Ltmp78:                                # EH_LABEL
# %bb.84:
	movq	%r13, %rdi
	movq	88(%rsp), %rsi
	leaq	16(%rsp), %rdx
	jmp	.LBB7_86
.LBB7_85:
	movq	%r13, %rdi
.LBB7_86:
	movl	28(%rsp), %eax
	leal	127(%rax), %ecx
	testl	%eax, %eax
	cmovnsl	%eax, %ecx
	sarl	$7, %ecx
	movl	%ecx, 52(%rsp)
	movq	%r14, 216(%rsp)
	movq	%rbp, 224(%rsp)
	leaq	184(%rsp), %rax
	movq	%rax, 232(%rsp)
	movq	%rdx, 240(%rsp)
	leaq	60(%rsp), %r13
	movq	%r13, 248(%rsp)
	movq	%r15, 256(%rsp)
	movq	%rdi, 264(%rsp)
	leaq	320(%rsp), %rax
	movq	%rax, 272(%rsp)
	movq	96(%rsp), %r12
	movq	104(%rsp), %rbx
	movq	$.L.str, 128(%rsp)
	movq	$.L.str.3, 136(%rsp)
	movabsq	$73014444195, %rax              # imm = 0x11000000A3
	movq	%rax, 144(%rsp)
	movq	%rsi, 112(%rsp)
	leaq	216(%rsp), %rax
	movq	%rax, 120(%rsp)
	leaq	112(%rsp), %rax
	movq	%rax, 152(%rsp)
	movq	$_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE1_EEDaSG_EUlSK_E_E4callEPKvSK_, 160(%rsp)
.Ltmp80:                                # EH_LABEL
	leaq	32(%rsp), %rdi
	leaq	128(%rsp), %rsi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tC1ERKNS1_13code_locationE
.Ltmp81:                                # EH_LABEL
# %bb.87:
	movl	$0, 12(%rsp)
.Ltmp82:                                # EH_LABEL
	leaq	32(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_t5queryEv
.Ltmp83:                                # EH_LABEL
# %bb.88:
	xorl	%r9d, %r9d
	cmpb	$0, 40(%rsp)
	sete	%r9b
.Ltmp84:                                # EH_LABEL
	leaq	64(%rsp), %rdi
	leaq	152(%rsp), %rdx
	leaq	12(%rsp), %rcx
	movq	%r12, %rsi
	movq	%rax, %r8
	callq	_ZNK4sycl3_V15queue22submit_with_event_implERKNS0_6detail19type_erased_cgfo_tyERKNS2_3_V114SubmissionInfoERKNS2_13code_locationEb
.Ltmp85:                                # EH_LABEL
# %bb.89:
	leaq	32(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
	movq	88(%rsp), %rax
	movups	64(%rsp), %xmm0                 # AlignMOV convert to UnAlignMOV 
	pxor	%xmm1, %xmm1
	movdqu	%xmm1, 64(%rsp)                 # AlignMOV convert to UnAlignMOV 
	movq	8(%rax), %r12
	movups	%xmm0, (%rax)
	testq	%r12, %r12
	je	.LBB7_94
# %bb.90:
	movq	8(%r12), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB7_92
# %bb.91:
	movq	$0, 8(%r12)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*16(%rax)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*24(%rax)
	jmp	.LBB7_94
.LBB7_92:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_131
# %bb.93:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r12)
	cmpl	$1, %eax
	je	.LBB7_132
.LBB7_94:
	movq	72(%rsp), %r12
	testq	%r12, %r12
	je	.LBB7_99
# %bb.95:
	movq	8(%r12), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB7_97
# %bb.96:
	movq	$0, 8(%r12)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*16(%rax)
	movq	(%r12), %rax
	movq	%r12, %rdi
	callq	*24(%rax)
	cmpb	$0, (%rbx)
	jne	.LBB7_100
	jmp	.LBB7_101
.LBB7_97:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_133
# %bb.98:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r12)
	cmpl	$1, %eax
	je	.LBB7_134
.LBB7_99:
	cmpb	$0, (%rbx)
	je	.LBB7_101
.LBB7_100:
	addq	$56, %rbx
	movq	88(%rsp), %rsi
.Ltmp87:                                # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_
.Ltmp88:                                # EH_LABEL
.LBB7_101:
.Ltmp90:                                # EH_LABEL
	leaq	680(%rsp), %rdi
	movl	$1, %esi
	callq	_ZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEb
.Ltmp91:                                # EH_LABEL
	leaq	184(%rsp), %rdx
	leaq	16(%rsp), %rsi
# %bb.102:
	movl	8(%rsp), %eax
	leal	127(%rax), %ecx
	testl	%eax, %eax
	cmovnsl	%eax, %ecx
	sarl	$7, %ecx
	movl	%ecx, 52(%rsp)
	movq	%r14, 216(%rsp)
	leaq	880(%rsp), %rax
	movq	%rax, 224(%rsp)
	leaq	640(%rsp), %rax
	movq	%rax, 232(%rsp)
	leaq	632(%rsp), %rax
	movq	%rax, 240(%rsp)
	movq	%rdx, 248(%rsp)
	movq	%rsi, 256(%rsp)
	movq	%r13, 264(%rsp)
	leaq	312(%rsp), %rax
	movq	%rax, 272(%rsp)
	leaq	8(%rsp), %rax
	movq	%rax, 280(%rsp)
	leaq	664(%rsp), %rax
	movq	%rax, 288(%rsp)
	movq	104(%rsp), %rbx
	movq	88(%rsp), %rax
	movq	96(%rsp), %r12
	movq	$.L.str, 128(%rsp)
	movq	$.L.str.3, 136(%rsp)
	movabsq	$73014444195, %rcx              # imm = 0x11000000A3
	movq	%rcx, 144(%rsp)
	movq	%rax, 112(%rsp)
	leaq	216(%rsp), %rax
	movq	%rax, 120(%rsp)
	leaq	112(%rsp), %rax
	movq	%rax, 152(%rsp)
	movq	$_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE2_EEDaSG_EUlSK_E_E4callEPKvSK_, 160(%rsp)
.Ltmp93:                                # EH_LABEL
	leaq	32(%rsp), %rdi
	leaq	128(%rsp), %rsi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tC1ERKNS1_13code_locationE
.Ltmp94:                                # EH_LABEL
# %bb.103:
	movl	$0, 12(%rsp)
.Ltmp95:                                # EH_LABEL
	leaq	32(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_t5queryEv
.Ltmp96:                                # EH_LABEL
# %bb.104:
	xorl	%r9d, %r9d
	cmpb	$0, 40(%rsp)
	sete	%r9b
.Ltmp97:                                # EH_LABEL
	leaq	64(%rsp), %rdi
	leaq	152(%rsp), %rdx
	leaq	12(%rsp), %rcx
	movq	%r12, %rsi
	movq	%rax, %r8
	callq	_ZNK4sycl3_V15queue22submit_with_event_implERKNS0_6detail19type_erased_cgfo_tyERKNS2_3_V114SubmissionInfoERKNS2_13code_locationEb
.Ltmp98:                                # EH_LABEL
# %bb.105:
	leaq	32(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
	movq	88(%rsp), %rax
	movups	64(%rsp), %xmm0                 # AlignMOV convert to UnAlignMOV 
	pxor	%xmm1, %xmm1
	movdqu	%xmm1, 64(%rsp)                 # AlignMOV convert to UnAlignMOV 
	movq	8(%rax), %r14
	movups	%xmm0, (%rax)
	testq	%r14, %r14
	je	.LBB7_110
# %bb.106:
	movq	8(%r14), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB7_108
# %bb.107:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	jmp	.LBB7_110
.LBB7_108:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_135
# %bb.109:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	je	.LBB7_136
.LBB7_110:
	movq	72(%rsp), %r14
	testq	%r14, %r14
	je	.LBB7_115
# %bb.111:
	movq	8(%r14), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB7_113
# %bb.112:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	cmpb	$0, (%rbx)
	jne	.LBB7_116
	jmp	.LBB7_117
.LBB7_113:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_137
# %bb.114:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	je	.LBB7_138
.LBB7_115:
	cmpb	$0, (%rbx)
	je	.LBB7_117
.LBB7_116:
	addq	$56, %rbx
	movq	88(%rsp), %rsi
.Ltmp100:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_
.Ltmp101:                               # EH_LABEL
.LBB7_117:
	movq	656(%rsp), %rbx
	testq	%rbx, %rbx
	je	.LBB7_122
# %bb.118:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB7_120
# %bb.119:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
	jmp	.LBB7_122
.LBB7_120:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB7_139
# %bb.121:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB7_140
.LBB7_122:
	addq	$824, %rsp                      # imm = 0x338
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB7_123:
	.cfi_def_cfa_offset 880
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r13)
	cmpl	$1, %eax
	jne	.LBB7_57
.LBB7_124:
	movq	%r13, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB7_57
.LBB7_125:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r13)
	cmpl	$1, %eax
	jne	.LBB7_62
.LBB7_126:
	movq	%r13, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	cmpb	$0, (%rbx)
	jne	.LBB7_63
	jmp	.LBB7_64
.LBB7_127:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r12)
	cmpl	$1, %eax
	jne	.LBB7_76
.LBB7_128:
	movq	%r12, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB7_73
.LBB7_129:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r12)
	cmpl	$1, %eax
	jne	.LBB7_82
.LBB7_130:
	movq	%r12, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB7_79
.LBB7_131:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r12)
	cmpl	$1, %eax
	jne	.LBB7_94
.LBB7_132:
	movq	%r12, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB7_94
.LBB7_133:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r12)
	cmpl	$1, %eax
	jne	.LBB7_99
.LBB7_134:
	movq	%r12, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	cmpb	$0, (%rbx)
	jne	.LBB7_100
	jmp	.LBB7_101
.LBB7_135:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB7_110
.LBB7_136:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB7_110
.LBB7_137:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB7_115
.LBB7_138:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	cmpb	$0, (%rbx)
	jne	.LBB7_116
	jmp	.LBB7_117
.LBB7_139:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB7_122
.LBB7_140:
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB7_122
.LBB7_141:
	movl	$-1, %ecx
	lock		xaddl	%ecx, 8(%rbp)
	cmpl	$1, %ecx
	jne	.LBB7_16
.LBB7_142:
	movq	%rbp, %rdi
	movq	%rax, %r14
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB7_13
.LBB7_143:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbp)
	cmpl	$1, %eax
	jne	.LBB7_33
.LBB7_144:
	movq	%rbp, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB7_33
.LBB7_145:
.Ltmp49:                                # EH_LABEL
	movq	%rax, %rbx
	leaq	216(%rsp), %rdi
	callq	_ZN4sycl3_V17contextD2Ev
	jmp	.LBB7_149
.LBB7_146:
.Ltmp57:                                # EH_LABEL
	jmp	.LBB7_157
.LBB7_147:
.Ltmp54:                                # EH_LABEL
	movq	%rax, %rbx
	leaq	680(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.LBB7_148:
.Ltmp46:                                # EH_LABEL
	movq	%rax, %rbx
.LBB7_149:
	leaq	336(%rsp), %rdi
	callq	_ZN4sycl3_V16detail16PropertyListBaseD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.LBB7_150:
.Ltmp102:                               # EH_LABEL
	jmp	.LBB7_157
.LBB7_151:
.Ltmp89:                                # EH_LABEL
	jmp	.LBB7_157
.LBB7_152:
.Ltmp79:                                # EH_LABEL
	jmp	.LBB7_157
.LBB7_153:
.Ltmp67:                                # EH_LABEL
	jmp	.LBB7_157
.LBB7_154:
.Ltmp99:                                # EH_LABEL
	jmp	.LBB7_159
.LBB7_155:
.Ltmp86:                                # EH_LABEL
	jmp	.LBB7_159
.LBB7_156:
.Ltmp92:                                # EH_LABEL
.LBB7_157:
	movq	%rax, %rbx
	jmp	.LBB7_162
.LBB7_158:
.Ltmp76:                                # EH_LABEL
.LBB7_159:
	movq	%rax, %rbx
	leaq	32(%rsp), %rdi
	jmp	.LBB7_161
.LBB7_160:
.Ltmp64:                                # EH_LABEL
	movq	%rax, %rbx
	leaq	216(%rsp), %rdi
.LBB7_161:
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
.LBB7_162:
	leaq	648(%rsp), %rdi
	callq	_ZN4sycl3_V15eventD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end7:
	.size	_ZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfi, .Lfunc_end7-_ZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfi
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table7:
.Lexception3:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end3-.Lcst_begin3
.Lcst_begin3:
	.uleb128 .Lfunc_begin3-.Lfunc_begin3    # >> Call Site 1 <<
	.uleb128 .Ltmp42-.Lfunc_begin3          #   Call between .Lfunc_begin3 and .Ltmp42
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp42-.Lfunc_begin3          # >> Call Site 2 <<
	.uleb128 .Ltmp45-.Ltmp42                #   Call between .Ltmp42 and .Ltmp45
	.uleb128 .Ltmp46-.Lfunc_begin3          #     jumps to .Ltmp46
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp47-.Lfunc_begin3          # >> Call Site 3 <<
	.uleb128 .Ltmp48-.Ltmp47                #   Call between .Ltmp47 and .Ltmp48
	.uleb128 .Ltmp49-.Lfunc_begin3          #     jumps to .Ltmp49
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp48-.Lfunc_begin3          # >> Call Site 4 <<
	.uleb128 .Ltmp50-.Ltmp48                #   Call between .Ltmp48 and .Ltmp50
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp50-.Lfunc_begin3          # >> Call Site 5 <<
	.uleb128 .Ltmp53-.Ltmp50                #   Call between .Ltmp50 and .Ltmp53
	.uleb128 .Ltmp54-.Lfunc_begin3          #     jumps to .Ltmp54
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp53-.Lfunc_begin3          # >> Call Site 6 <<
	.uleb128 .Ltmp55-.Ltmp53                #   Call between .Ltmp53 and .Ltmp55
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp55-.Lfunc_begin3          # >> Call Site 7 <<
	.uleb128 .Ltmp56-.Ltmp55                #   Call between .Ltmp55 and .Ltmp56
	.uleb128 .Ltmp57-.Lfunc_begin3          #     jumps to .Ltmp57
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp58-.Lfunc_begin3          # >> Call Site 8 <<
	.uleb128 .Ltmp59-.Ltmp58                #   Call between .Ltmp58 and .Ltmp59
	.uleb128 .Ltmp67-.Lfunc_begin3          #     jumps to .Ltmp67
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp60-.Lfunc_begin3          # >> Call Site 9 <<
	.uleb128 .Ltmp63-.Ltmp60                #   Call between .Ltmp60 and .Ltmp63
	.uleb128 .Ltmp64-.Lfunc_begin3          #     jumps to .Ltmp64
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp63-.Lfunc_begin3          # >> Call Site 10 <<
	.uleb128 .Ltmp65-.Ltmp63                #   Call between .Ltmp63 and .Ltmp65
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp65-.Lfunc_begin3          # >> Call Site 11 <<
	.uleb128 .Ltmp66-.Ltmp65                #   Call between .Ltmp65 and .Ltmp66
	.uleb128 .Ltmp67-.Lfunc_begin3          #     jumps to .Ltmp67
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp68-.Lfunc_begin3          # >> Call Site 12 <<
	.uleb128 .Ltmp69-.Ltmp68                #   Call between .Ltmp68 and .Ltmp69
	.uleb128 .Ltmp92-.Lfunc_begin3          #     jumps to .Ltmp92
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp70-.Lfunc_begin3          # >> Call Site 13 <<
	.uleb128 .Ltmp71-.Ltmp70                #   Call between .Ltmp70 and .Ltmp71
	.uleb128 .Ltmp79-.Lfunc_begin3          #     jumps to .Ltmp79
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp72-.Lfunc_begin3          # >> Call Site 14 <<
	.uleb128 .Ltmp75-.Ltmp72                #   Call between .Ltmp72 and .Ltmp75
	.uleb128 .Ltmp76-.Lfunc_begin3          #     jumps to .Ltmp76
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp75-.Lfunc_begin3          # >> Call Site 15 <<
	.uleb128 .Ltmp77-.Ltmp75                #   Call between .Ltmp75 and .Ltmp77
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp77-.Lfunc_begin3          # >> Call Site 16 <<
	.uleb128 .Ltmp78-.Ltmp77                #   Call between .Ltmp77 and .Ltmp78
	.uleb128 .Ltmp79-.Lfunc_begin3          #     jumps to .Ltmp79
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp80-.Lfunc_begin3          # >> Call Site 17 <<
	.uleb128 .Ltmp81-.Ltmp80                #   Call between .Ltmp80 and .Ltmp81
	.uleb128 .Ltmp89-.Lfunc_begin3          #     jumps to .Ltmp89
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp82-.Lfunc_begin3          # >> Call Site 18 <<
	.uleb128 .Ltmp85-.Ltmp82                #   Call between .Ltmp82 and .Ltmp85
	.uleb128 .Ltmp86-.Lfunc_begin3          #     jumps to .Ltmp86
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp85-.Lfunc_begin3          # >> Call Site 19 <<
	.uleb128 .Ltmp87-.Ltmp85                #   Call between .Ltmp85 and .Ltmp87
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp87-.Lfunc_begin3          # >> Call Site 20 <<
	.uleb128 .Ltmp88-.Ltmp87                #   Call between .Ltmp87 and .Ltmp88
	.uleb128 .Ltmp89-.Lfunc_begin3          #     jumps to .Ltmp89
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp90-.Lfunc_begin3          # >> Call Site 21 <<
	.uleb128 .Ltmp91-.Ltmp90                #   Call between .Ltmp90 and .Ltmp91
	.uleb128 .Ltmp92-.Lfunc_begin3          #     jumps to .Ltmp92
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp93-.Lfunc_begin3          # >> Call Site 22 <<
	.uleb128 .Ltmp94-.Ltmp93                #   Call between .Ltmp93 and .Ltmp94
	.uleb128 .Ltmp102-.Lfunc_begin3         #     jumps to .Ltmp102
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp95-.Lfunc_begin3          # >> Call Site 23 <<
	.uleb128 .Ltmp98-.Ltmp95                #   Call between .Ltmp95 and .Ltmp98
	.uleb128 .Ltmp99-.Lfunc_begin3          #     jumps to .Ltmp99
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp98-.Lfunc_begin3          # >> Call Site 24 <<
	.uleb128 .Ltmp100-.Ltmp98               #   Call between .Ltmp98 and .Ltmp100
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp100-.Lfunc_begin3         # >> Call Site 25 <<
	.uleb128 .Ltmp101-.Ltmp100              #   Call between .Ltmp100 and .Ltmp101
	.uleb128 .Ltmp102-.Lfunc_begin3         #     jumps to .Ltmp102
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp101-.Lfunc_begin3         # >> Call Site 26 <<
	.uleb128 .Lfunc_end7-.Ltmp101           #   Call between .Ltmp101 and .Lfunc_end7
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end3:
	.p2align	2, 0x0
                                        # -- End function
	.section	.text._ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_,"axG",@progbits,_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_,comdat
	.weak	_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_ # -- Begin function _ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_
	.p2align	1
	.prefalign	4, .Lfunc_end8, nop
	.type	_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_,@function
_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	pushq	%rax
	.cfi_def_cfa_offset 64
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	8(%rdi), %r13
	cmpq	16(%rdi), %r13
	je	.LBB8_8
# %bb.1:
	movups	(%rsi), %xmm0
	movq	8(%rsi), %rax
	movups	%xmm0, (%r13)
	testq	%rax, %rax
	je	.LBB8_7
# %bb.2:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB8_4
# %bb.3:
	movl	8(%rax), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%rax)
	cmpl	$-1, %ecx
	jne	.LBB8_6
	jmp	.LBB8_30
.LBB8_8:
	movq	%rdi, (%rsp)                    # 8-byte Spill
	movq	(%rdi), %r15
	movq	%r13, %r14
	subq	%r15, %r14
	movabsq	$9223372036854775792, %rax      # imm = 0x7FFFFFFFFFFFFFF0
	cmpq	%rax, %r14
	je	.LBB8_29
# %bb.9:
	movq	%rsi, %rbp
	movq	%r14, %rbx
	sarq	$4, %rbx
	cmpq	$1, %rbx
	adcq	%rbx, %rbx
	movabsq	$576460752303423487, %rax       # imm = 0x7FFFFFFFFFFFFFF
	cmpq	%rax, %rbx
	cmovaeq	%rax, %rbx
	shlq	$4, %rbx
	movq	%rbx, %rdi
	callq	_Znwm
	movq	%rax, %r12
	movups	(%rbp), %xmm0
	movq	8(%rbp), %rax
	movups	%xmm0, (%r12,%r14)
	testq	%rax, %rax
	je	.LBB8_14
# %bb.10:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB8_12
# %bb.11:
	movl	8(%rax), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%rax)
	cmpl	$-1, %ecx
	jne	.LBB8_14
	jmp	.LBB8_30
.LBB8_4:
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%rax)
	cmpl	$-1, %ecx
	je	.LBB8_30
.LBB8_6:
	movq	8(%rdi), %r13
.LBB8_7:
	addq	$16, %r13
	movq	%r13, 8(%rdi)
	jmp	.LBB8_18
.LBB8_12:
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%rax)
	cmpl	$-1, %ecx
	je	.LBB8_30
.LBB8_14:
	movq	%r12, %rbp
	cmpq	%r13, %r15
	je	.LBB8_15
# %bb.19:
	addq	$-16, %r14
	shrq	$4, %r14
	leaq	1(%r14), %rbp
	movq	%rbp, %rax
	shrq	$2, %rax
	je	.LBB8_22
# %bb.20:
	xorl	%ecx, %ecx
	xorps	%xmm0, %xmm0
	.p2align	4
.LBB8_21:                               # =>This Inner Loop Header: Depth=1
	leaq	(%r15,%rcx), %rdx
	movups	(%rdx), %xmm1
	movups	%xmm1, (%r12,%rcx)
	movups	16(%rdx), %xmm1
	movups	%xmm1, 16(%r12,%rcx)
	movups	%xmm0, 16(%rdx)
	movups	%xmm0, (%rdx)
	movups	32(%rdx), %xmm1
	movups	%xmm1, 32(%r12,%rcx)
	movups	48(%rdx), %xmm1
	movups	%xmm1, 48(%r12,%rcx)
	movups	%xmm0, 48(%rdx)
	movups	%xmm0, 32(%rdx)
	addq	$64, %rcx
	decq	%rax
	jne	.LBB8_21
.LBB8_22:
	movq	%rbp, %rax
	andq	$-4, %rax
	subq	%rax, %r14
	je	.LBB8_27
# %bb.23:
	cmpq	$1, %r14
	je	.LBB8_26
# %bb.24:
	cmpq	$2, %r14
	jne	.LBB8_28
# %bb.25:
	movq	%rax, %rcx
	shlq	$4, %rcx
	movups	32(%r15,%rcx), %xmm0
	movq	$0, 40(%r15,%rcx)
	movups	%xmm0, 32(%r12,%rcx)
	movq	$0, 32(%r15,%rcx)
.LBB8_26:
	movq	%rax, %rcx
	shlq	$4, %rcx
	movups	16(%r15,%rcx), %xmm0
	movq	$0, 24(%r15,%rcx)
	movups	%xmm0, 16(%r12,%rcx)
	movq	$0, 16(%r15,%rcx)
.LBB8_27:
	shlq	$4, %rax
	movups	(%r15,%rax), %xmm0
	movq	$0, 8(%r15,%rax)
	movups	%xmm0, (%r12,%rax)
	movq	$0, (%r15,%rax)
.LBB8_28:
	shlq	$4, %rbp
	addq	%r12, %rbp
.LBB8_15:
	testq	%r15, %r15
	movq	(%rsp), %r14                    # 8-byte Reload
	je	.LBB8_17
# %bb.16:
	movq	16(%r14), %rsi
	subq	%r15, %rsi
	movq	%r15, %rdi
	callq	_ZdlPvm
.LBB8_17:
	addq	$16, %rbp
	movq	%r12, (%r14)
	movq	%rbp, 8(%r14)
	addq	%rbx, %r12
	movq	%r12, 16(%r14)
.LBB8_18:
	addq	$8, %rsp
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB8_30:
	.cfi_def_cfa_offset 64
	ud2
.LBB8_29:
	movl	$.L.str.20, %edi
	callq	_ZSt20__throw_length_errorPKc
.Lfunc_end8:
	.size	_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_, .Lfunc_end8-_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_
	.cfi_endproc
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEb
	.prefalign	4, .Lfunc_end9, nop
	.type	_ZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEb,@function
_ZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEb: # 
.Lfunc_begin4:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception4
# %bb.0:
	pushq	%r15
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%r12
	.cfi_def_cfa_offset 32
	pushq	%rbx
	.cfi_def_cfa_offset 40
	subq	$280, %rsp                      # imm = 0x118
	.cfi_def_cfa_offset 320
	.cfi_offset %rbx, -40
	.cfi_offset %r12, -32
	.cfi_offset %r14, -24
	.cfi_offset %r15, -16
	movb	%sil, 15(%rsp)
	testl	%esi, %esi
	je	.LBB9_2
# %bb.1:
	movq	(%rdi), %rax
	movl	(%rax), %r9d
	movq	8(%rdi), %rcx
	movl	(%rcx), %r8d
	movq	16(%rdi), %rsi
	movq	24(%rdi), %rdx
	movl	(%rsi), %esi
	jmp	.LBB9_3
.LBB9_2:
	movq	8(%rdi), %rcx
	movl	(%rcx), %r9d
	movq	(%rdi), %rax
	movl	(%rax), %r8d
	movq	16(%rdi), %r10
	movq	24(%rdi), %rdx
	movl	(%rdx), %esi
	imull	(%r10), %esi
.LBB9_3:
	leal	127(%r9), %r10d
	leal	15(%r9), %r11d
	testl	%r9d, %r9d
	cmovnsl	%r9d, %r10d
	cmovnsl	%r9d, %r11d
	sarl	$7, %r10d
	leal	15(%r8), %r9d
	testl	%r8d, %r8d
	cmovnsl	%r8d, %r9d
	sarl	$4, %r9d
	sarl	$4, %r11d
	movl	%r11d, 24(%rsp)
	movl	%r9d, 20(%rsp)
	movl	%r10d, 16(%rsp)
	imull	%esi, %r10d
	movslq	%r10d, %rsi
	shlq	$7, %rsi
	movq	%rsi, 48(%rsp)
	movq	32(%rdi), %r12
	movq	40(%rdi), %rsi
	movq	%rsi, 128(%rsp)
	leaq	48(%rsp), %rsi
	movq	%rsi, 136(%rsp)
	leaq	16(%rsp), %rsi
	movq	%rsi, 144(%rsp)
	leaq	15(%rsp), %rsi
	movq	%rsi, 152(%rsp)
	movq	%rdx, 160(%rsp)
	movups	48(%rdi), %xmm0
	movups	%xmm0, 168(%rsp)
	movups	64(%rdi), %xmm0
	movups	%xmm0, 184(%rsp)
	movq	80(%rdi), %rdx
	movq	%rdx, 200(%rsp)
	movq	%rcx, 208(%rsp)
	movq	88(%rdi), %rcx
	movq	%rcx, 216(%rsp)
	movq	%rax, 224(%rsp)
	movups	96(%rdi), %xmm0
	movups	%xmm0, 232(%rsp)
	leaq	24(%rsp), %rax
	movq	%rax, 248(%rsp)
	leaq	20(%rsp), %rax
	movq	%rax, 256(%rsp)
	movups	112(%rdi), %xmm0
	movups	%xmm0, 264(%rsp)
	movq	16(%r12), %rbx
	movq	(%r12), %rax
	movq	8(%r12), %r14
	movq	$.L.str, 104(%rsp)
	movq	$.L.str.3, 112(%rsp)
	movabsq	$73014444195, %rcx              # imm = 0x11000000A3
	movq	%rcx, 120(%rsp)
	movq	%rax, 88(%rsp)
	leaq	128(%rsp), %rax
	movq	%rax, 96(%rsp)
	leaq	88(%rsp), %rax
	movq	%rax, 72(%rsp)
	movq	$_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZZNS5_7forwardES8_iSB_SD_SE_iENKUlbE_clEbEUlRNS0_7handlerEE_EEDaSG_EUlSL_E_E4callEPKvSL_, 80(%rsp)
	leaq	56(%rsp), %r15
	leaq	104(%rsp), %rsi
	movq	%r15, %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tC1ERKNS1_13code_locationE
	movl	$0, 28(%rsp)
.Ltmp103:                               # EH_LABEL
	movq	%r15, %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_t5queryEv
.Ltmp104:                               # EH_LABEL
# %bb.4:
	xorl	%r9d, %r9d
	cmpb	$0, 64(%rsp)
	sete	%r9b
.Ltmp105:                               # EH_LABEL
	leaq	32(%rsp), %rdi
	leaq	72(%rsp), %rdx
	leaq	28(%rsp), %rcx
	movq	%r14, %rsi
	movq	%rax, %r8
	callq	_ZNK4sycl3_V15queue22submit_with_event_implERKNS0_6detail19type_erased_cgfo_tyERKNS2_3_V114SubmissionInfoERKNS2_13code_locationEb
.Ltmp106:                               # EH_LABEL
# %bb.5:
	movabsq	$4294967297, %r15               # imm = 0x100000001
	leaq	56(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
	movq	(%r12), %rax
	movups	32(%rsp), %xmm0                 # AlignMOV convert to UnAlignMOV 
	xorps	%xmm1, %xmm1
	movups	%xmm1, 32(%rsp)                 # AlignMOV convert to UnAlignMOV 
	movq	8(%rax), %r14
	movups	%xmm0, (%rax)
	testq	%r14, %r14
	je	.LBB9_13
# %bb.6:
	movq	8(%r14), %rax
	cmpq	%r15, %rax
	jne	.LBB9_8
# %bb.7:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	jmp	.LBB9_13
.LBB9_8:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB9_10
# %bb.9:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	je	.LBB9_12
.LBB9_13:
	movq	40(%rsp), %r14
	testq	%r14, %r14
	je	.LBB9_21
# %bb.14:
	movq	8(%r14), %rax
	cmpq	%r15, %rax
	jne	.LBB9_16
# %bb.15:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	cmpb	$0, (%rbx)
	jne	.LBB9_22
	jmp	.LBB9_23
.LBB9_16:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB9_18
# %bb.17:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	je	.LBB9_20
.LBB9_21:
	cmpb	$0, (%rbx)
	je	.LBB9_23
.LBB9_22:
	addq	$56, %rbx
	movq	(%r12), %rsi
	movq	%rbx, %rdi
	callq	_ZNSt6vectorIN4sycl3_V15eventESaIS2_EE9push_backERKS2_
.LBB9_23:
	addq	$280, %rsp                      # imm = 0x118
	.cfi_def_cfa_offset 40
	popq	%rbx
	.cfi_def_cfa_offset 32
	popq	%r12
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	retq
.LBB9_10:
	.cfi_def_cfa_offset 320
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB9_13
.LBB9_12:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB9_13
.LBB9_18:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB9_21
.LBB9_20:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	cmpb	$0, (%rbx)
	jne	.LBB9_22
	jmp	.LBB9_23
.LBB9_24:
.Ltmp107:                               # EH_LABEL
	movq	%rax, %rbx
	leaq	56(%rsp), %rdi
	callq	_ZN4sycl3_V16detail14tls_code_loc_tD1Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end9:
	.size	_ZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEb, .Lfunc_end9-_ZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEb
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table9:
.Lexception4:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end4-.Lcst_begin4
.Lcst_begin4:
	.uleb128 .Lfunc_begin4-.Lfunc_begin4    # >> Call Site 1 <<
	.uleb128 .Ltmp103-.Lfunc_begin4         #   Call between .Lfunc_begin4 and .Ltmp103
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp103-.Lfunc_begin4         # >> Call Site 2 <<
	.uleb128 .Ltmp106-.Ltmp103              #   Call between .Ltmp103 and .Ltmp106
	.uleb128 .Ltmp107-.Lfunc_begin4         #     jumps to .Ltmp107
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp106-.Lfunc_begin4         # >> Call Site 3 <<
	.uleb128 .Lfunc_end9-.Ltmp106           #   Call between .Ltmp106 and .Lfunc_end9
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end4:
	.p2align	2, 0x0
                                        # -- End function
	.section	.text._ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv,"axG",@progbits,_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv,comdat
	.weak	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # -- Begin function _ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	.p2align	1
	.prefalign	4, .Lfunc_end10, nop
	.type	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv,@function
_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	%rdi, %rbx
	movq	(%rdi), %rax
	callq	*16(%rax)
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB10_2
# %bb.1:
	movl	12(%rbx), %eax
	leal	-1(%rax), %ecx
	movl	%ecx, 12(%rbx)
	cmpl	$1, %eax
	jne	.LBB10_4
.LBB10_5:
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB10_2:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 12(%rbx)
	cmpl	$1, %eax
	je	.LBB10_5
.LBB10_4:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.Lfunc_end10:
	.size	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv, .Lfunc_end10-_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	.cfi_endproc
                                        # -- End function
	.section	.text._ZN4sycl3_V17contextD2Ev,"axG",@progbits,_ZN4sycl3_V17contextD2Ev,comdat
	.weak	_ZN4sycl3_V17contextD2Ev        # -- Begin function _ZN4sycl3_V17contextD2Ev
	.p2align	1
	.prefalign	4, .Lfunc_end11, nop
	.type	_ZN4sycl3_V17contextD2Ev,@function
_ZN4sycl3_V17contextD2Ev:               # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	8(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB11_6
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB11_2
# %bb.7:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB11_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB11_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB11_8
.LBB11_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB11_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB11_6
.LBB11_8:
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end11:
	.size	_ZN4sycl3_V17contextD2Ev, .Lfunc_end11-_ZN4sycl3_V17contextD2Ev
	.cfi_endproc
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE_EEDaSG_EUlSK_E_E4callEPKvSK_
	.prefalign	4, .Lfunc_end12, nop
	.type	_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE_EEDaSG_EUlSK_E_E4callEPKvSK_,@function
_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE_EEDaSG_EUlSK_E_E4callEPKvSK_: # 
.Lfunc_begin5:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception5
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$376, %rsp                      # imm = 0x178
	.cfi_def_cfa_offset 432
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rsi, %rbx
	movq	%rdi, %r14
	movq	(%rdi), %rax
	movups	(%rax), %xmm0
	movq	8(%rax), %rax
	movups	%xmm0, 48(%rsp)                 # AlignMOV convert to UnAlignMOV 
	testq	%rax, %rax
	je	.LBB12_5
# %bb.1:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB12_3
# %bb.2:
	movl	8(%rax), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%rax)
	cmpl	$-1, %ecx
	jne	.LBB12_5
	jmp	.LBB12_66
.LBB12_3:
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%rax)
	cmpl	$-1, %ecx
	je	.LBB12_66
.LBB12_5:
.Ltmp108:                               # EH_LABEL
	leaq	48(%rsp), %rsi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler10depends_onENS0_5eventE
.Ltmp109:                               # EH_LABEL
# %bb.6:
	movq	56(%rsp), %r15
	testq	%r15, %r15
	je	.LBB12_14
# %bb.7:
	movq	8(%r15), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB12_9
# %bb.8:
	movq	$0, 8(%r15)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*16(%rax)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*24(%rax)
	jmp	.LBB12_14
.LBB12_9:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB12_11
# %bb.10:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$1, %eax
	je	.LBB12_13
.LBB12_14:
	movq	8(%r14), %rbp
	movq	$.L.str, 88(%rsp)
	movq	$.L.str.3, 96(%rsp)
	movabsq	$188978561205, %rax             # imm = 0x2C000000B5
	movq	%rax, 104(%rsp)
	movq	104(%rsp), %rax
	movq	%rax, 16(%rsp)
	movups	88(%rsp), %xmm0
	movups	%xmm0, (%rsp)
	leaq	112(%rsp), %rdi
	movl	$128, %esi
	movq	%rbx, %rdx
	callq	_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE
	movq	(%rbp), %rax
	movq	8(%rbp), %rcx
	movslq	(%rax), %r13
	movslq	(%rcx), %r12
	movq	16(%rbp), %rax
	movslq	(%rax), %r15
	movq	24(%rbp), %rax
	movq	32(%rbp), %rcx
	movzbl	(%rax), %eax
	movb	%al, 39(%rsp)                   # 1-byte Spill
	movq	(%rcx), %rax
	movq	%rax, 80(%rsp)                  # 8-byte Spill
	movq	40(%rbp), %rax
	movq	(%rax), %rax
	movq	%rax, 72(%rsp)                  # 8-byte Spill
	movq	48(%rbp), %rax
	movl	(%rax), %eax
	movl	%eax, 44(%rsp)                  # 4-byte Spill
	movq	56(%rbp), %rax
	movq	(%rax), %rax
	movq	%rax, 64(%rsp)                  # 8-byte Spill
	movq	64(%rbp), %rax
	movl	(%rax), %eax
	movl	%eax, 40(%rsp)                  # 4-byte Spill
	movups	112(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 336(%rsp)                # 16-byte Spill
                                        # AlignMOV convert to UnAlignMOV 
	movq	120(%rsp), %r14
	testq	%r14, %r14
	je	.LBB12_19
# %bb.15:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB12_17
# %bb.16:
	movl	8(%r14), %eax
	leal	1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$-1, %eax
	jne	.LBB12_19
	jmp	.LBB12_66
.LBB12_17:
	movl	$1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$-1, %eax
	je	.LBB12_66
.LBB12_19:
	movups	128(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 352(%rsp)                # AlignMOV convert to UnAlignMOV 
	movq	72(%rbp), %rax
	movq	(%rax), %rbp
.Ltmp111:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZNK4sycl3_V17handler7getTypeEv
.Ltmp112:                               # EH_LABEL
# %bb.20:
	testl	%eax, %eax
	jne	.LBB12_21
# %bb.24:
.Ltmp118:                               # EH_LABEL
	movl	$.L.str.5, %esi
	movl	$133, %edx
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler30verifyUsedKernelBundleInternalENS0_6detail11string_viewE
.Ltmp119:                               # EH_LABEL
# %bb.25:
	shlq	$7, %r13
	imulq	%r15, %r12
	movq	%r13, 184(%rsp)
	movq	%r12, 192(%rsp)
	leaq	200(%rsp), %rax
	movq	$128, 200(%rsp)
	movq	$1, 208(%rsp)
	leaq	216(%rsp), %rcx
	xorps	%xmm0, %xmm0
	movups	%xmm0, 216(%rsp)
	leaq	184(%rsp), %rdx
	movq	%rdx, 152(%rsp)
	movq	%rax, 160(%rsp)
	movq	%rcx, 168(%rsp)
	movq	$2, 176(%rsp)
.Ltmp120:                               # EH_LABEL
	movups	152(%rsp), %xmm0
	movups	168(%rsp), %xmm1
	movups	%xmm1, 16(%rsp)
	movups	%xmm0, (%rsp)
	movq	%rbx, %rdi
	xorl	%esi, %esi
	callq	_ZN4sycl3_V17handler20setNDRangeDescriptorENS0_6detail16nd_range_view_v113nd_range_viewEb
.Ltmp121:                               # EH_LABEL
# %bb.26:
.Ltmp122:                               # EH_LABEL
	movl	$96, %edi
	callq	_Znwm
.Ltmp123:                               # EH_LABEL
# %bb.27:
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rax)
	movl	%r15d, 8(%rax)
	movzbl	39(%rsp), %ecx                  # 1-byte Folded Reload
	movb	%cl, 12(%rax)
	movq	80(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 16(%rax)
	movq	72(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 24(%rax)
	movl	44(%rsp), %ecx                  # 4-byte Reload
	movl	%ecx, 32(%rax)
	movq	64(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 40(%rax)
	movl	40(%rsp), %ecx                  # 4-byte Reload
	movl	%ecx, 48(%rax)
	movups	336(%rsp), %xmm0                # 16-byte Reload
                                        # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 56(%rax)
	testq	%r14, %r14
	je	.LBB12_32
# %bb.28:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB12_30
# %bb.29:
	movl	8(%r14), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%r14)
	cmpl	$-1, %ecx
	je	.LBB12_66
.LBB12_32:
	movups	352(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 72(%rax)
	movq	%rbp, 88(%rax)
	movq	144(%rbx), %rdi
	movq	%rax, 144(%rbx)
	testq	%rdi, %rdi
	je	.LBB12_34
# %bb.33:
	movq	(%rdi), %rax
	callq	*16(%rax)
.LBB12_34:
.Ltmp124:                               # EH_LABEL
	movl	$_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE, %esi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler23instantiateKernelOnHostEPv
.Ltmp125:                               # EH_LABEL
# %bb.35:
	movq	144(%rbx), %rdi
	movq	(%rdi), %rax
.Ltmp126:                               # EH_LABEL
	callq	*(%rax)
.Ltmp127:                               # EH_LABEL
# %bb.36:
	movq	$.L.str.5, 64(%rbx)
	movq	$133, 72(%rbx)
.Ltmp128:                               # EH_LABEL
	movq	%rbx, %rdi
	movq	%rax, %rsi
	callq	_ZN4sycl3_V17handler13setKernelFuncEPv
.Ltmp129:                               # EH_LABEL
# %bb.37:
	movzbl	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip), %eax
	testb	%al, %al
	je	.LBB12_38
.LBB12_41:
	movq	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip), %rsi
.Ltmp133:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler22setDeviceKernelInfoPtrEPNS0_6detail16DeviceKernelInfoE
.Ltmp134:                               # EH_LABEL
# %bb.42:
.Ltmp135:                               # EH_LABEL
	movq	%rbx, %rdi
	movl	$1, %esi
	callq	_ZN4sycl3_V17handler7setTypeENS0_6detail6CGTypeE
.Ltmp136:                               # EH_LABEL
# %bb.43:
	movb	$0, 192(%rsp)
	movb	$0, 202(%rsp)
	movb	$0, 204(%rsp)
	movb	$0, 212(%rsp)
	movb	$0, 220(%rsp)
	movb	$0, 228(%rsp)
	movb	$0, 236(%rsp)
	movb	$0, 244(%rsp)
	movb	$0, 252(%rsp)
	movb	$0, 264(%rsp)
	movb	$0, 288(%rsp)
	movb	$0, 320(%rsp)
	movb	$1, 328(%rsp)
.Ltmp137:                               # EH_LABEL
	leaq	184(%rsp), %rsi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler25setKernelLaunchPropertiesERKNS0_6detail27kernel_launch_properties_v111PropsHolderIJNS0_3ext6oneapi12experimental23work_group_scratch_sizeENS5_5intel12experimental12cache_configENS7_17use_root_sync_keyENS7_23work_group_progress_keyENS7_22sub_group_progress_keyENS7_22work_item_progress_keyENS7_4cuda12cluster_sizeILi1EEENSH_ILi2EEENSH_ILi3EEEEEE
.Ltmp138:                               # EH_LABEL
# %bb.44:
	testq	%r14, %r14
	je	.LBB12_52
# %bb.45:
	movq	8(%r14), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB12_47
# %bb.46:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	jmp	.LBB12_52
.LBB12_47:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB12_49
# %bb.48:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	je	.LBB12_51
.LBB12_52:
	movq	120(%rsp), %rbx
	testq	%rbx, %rbx
	je	.LBB12_60
# %bb.53:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB12_55
# %bb.54:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
	jmp	.LBB12_60
.LBB12_55:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB12_57
# %bb.56:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB12_59
.LBB12_60:
	addq	$376, %rsp                      # imm = 0x178
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB12_30:
	.cfi_def_cfa_offset 432
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%r14)
	cmpl	$-1, %ecx
	jne	.LBB12_32
.LBB12_66:
	ud2
.LBB12_11:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB12_14
.LBB12_13:
	movq	%r15, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB12_14
.LBB12_49:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB12_52
.LBB12_51:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB12_52
.LBB12_57:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB12_60
.LBB12_59:
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB12_60
.LBB12_21:
	movl	$64, %edi
	callq	__cxa_allocate_exception
	movq	%rax, %r15
	movl	$1, %edi
	callq	_ZN4sycl3_V115make_error_codeENS0_4errcE
.Ltmp113:                               # EH_LABEL
	movl	$.L.str.7, %ecx
	movq	%r15, %rdi
	movl	%eax, %esi
	callq	_ZN4sycl3_V19exceptionC1ESt10error_codePKc
.Ltmp114:                               # EH_LABEL
# %bb.22:
.Ltmp116:                               # EH_LABEL
	movl	$_ZTIN4sycl3_V19exceptionE, %esi
	movl	$_ZN4sycl3_V19exceptionD1Ev, %edx
	movq	%r15, %rdi
	callq	__cxa_throw
.Ltmp117:                               # EH_LABEL
# %bb.23:
.LBB12_38:
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_acquire
	testl	%eax, %eax
	je	.LBB12_41
# %bb.39:
.Ltmp130:                               # EH_LABEL
	movl	$_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi2EEEE_EE, %edi
	callq	_ZN4sycl3_V16detail19getDeviceKernelInfoERKNS1_27compile_time_kernel_info_v123CompileTimeKernelInfoTyE
.Ltmp131:                               # EH_LABEL
# %bb.40:
	movq	%rax, _ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip)
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_release
	jmp	.LBB12_41
.LBB12_67:
.Ltmp132:                               # EH_LABEL
	movq	%rax, %rbx
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_abort
	jmp	.LBB12_63
.LBB12_62:
.Ltmp115:                               # EH_LABEL
	movq	%rax, %rbx
	movq	%r15, %rdi
	callq	__cxa_free_exception
	jmp	.LBB12_63
.LBB12_64:
.Ltmp110:                               # EH_LABEL
	movq	%rax, %rbx
	leaq	48(%rsp), %rdi
	callq	_ZN4sycl3_V15eventD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.LBB12_61:
.Ltmp139:                               # EH_LABEL
	movq	%rax, %rbx
.LBB12_63:
	movq	%r14, %rdi
	callq	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	leaq	112(%rsp), %rdi
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end12:
	.size	_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE_EEDaSG_EUlSK_E_E4callEPKvSK_, .Lfunc_end12-_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE_EEDaSG_EUlSK_E_E4callEPKvSK_
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table12:
.Lexception5:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end5-.Lcst_begin5
.Lcst_begin5:
	.uleb128 .Ltmp108-.Lfunc_begin5         # >> Call Site 1 <<
	.uleb128 .Ltmp109-.Ltmp108              #   Call between .Ltmp108 and .Ltmp109
	.uleb128 .Ltmp110-.Lfunc_begin5         #     jumps to .Ltmp110
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp109-.Lfunc_begin5         # >> Call Site 2 <<
	.uleb128 .Ltmp111-.Ltmp109              #   Call between .Ltmp109 and .Ltmp111
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp111-.Lfunc_begin5         # >> Call Site 3 <<
	.uleb128 .Ltmp123-.Ltmp111              #   Call between .Ltmp111 and .Ltmp123
	.uleb128 .Ltmp139-.Lfunc_begin5         #     jumps to .Ltmp139
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp123-.Lfunc_begin5         # >> Call Site 4 <<
	.uleb128 .Ltmp124-.Ltmp123              #   Call between .Ltmp123 and .Ltmp124
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp124-.Lfunc_begin5         # >> Call Site 5 <<
	.uleb128 .Ltmp138-.Ltmp124              #   Call between .Ltmp124 and .Ltmp138
	.uleb128 .Ltmp139-.Lfunc_begin5         #     jumps to .Ltmp139
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp138-.Lfunc_begin5         # >> Call Site 6 <<
	.uleb128 .Ltmp113-.Ltmp138              #   Call between .Ltmp138 and .Ltmp113
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp113-.Lfunc_begin5         # >> Call Site 7 <<
	.uleb128 .Ltmp114-.Ltmp113              #   Call between .Ltmp113 and .Ltmp114
	.uleb128 .Ltmp115-.Lfunc_begin5         #     jumps to .Ltmp115
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp116-.Lfunc_begin5         # >> Call Site 8 <<
	.uleb128 .Ltmp117-.Ltmp116              #   Call between .Ltmp116 and .Ltmp117
	.uleb128 .Ltmp139-.Lfunc_begin5         #     jumps to .Ltmp139
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp130-.Lfunc_begin5         # >> Call Site 9 <<
	.uleb128 .Ltmp131-.Ltmp130              #   Call between .Ltmp130 and .Ltmp131
	.uleb128 .Ltmp132-.Lfunc_begin5         #     jumps to .Ltmp132
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp131-.Lfunc_begin5         # >> Call Site 10 <<
	.uleb128 .Lfunc_end12-.Ltmp131          #   Call between .Ltmp131 and .Lfunc_end12
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end5:
	.p2align	2, 0x0
                                        # -- End function
	.section	.text._ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE,"axG",@progbits,_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE,comdat
	.weak	_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE # -- Begin function _ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE
	.p2align	1
	.prefalign	4, .Lfunc_end13, nop
	.type	_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE,@function
_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE: # 
.Lfunc_begin6:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception6
# %bb.0:
	pushq	%r15
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%r13
	.cfi_def_cfa_offset 32
	pushq	%r12
	.cfi_def_cfa_offset 40
	pushq	%rbx
	.cfi_def_cfa_offset 48
	subq	$128, %rsp
	.cfi_def_cfa_offset 176
	.cfi_offset %rbx, -48
	.cfi_offset %r12, -40
	.cfi_offset %r13, -32
	.cfi_offset %r14, -24
	.cfi_offset %r15, -16
	movq	%rdi, %rbx
	movups	176(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 96(%rsp)                 # AlignMOV convert to UnAlignMOV 
	movq	192(%rsp), %rax
	movq	%rax, 112(%rsp)
	movq	%rsi, 72(%rsp)
	movq	$1, 80(%rsp)
	movq	$1, 88(%rsp)
	xorps	%xmm0, %xmm0
	movups	%xmm0, 48(%rsp)                 # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 32(%rsp)                 # AlignMOV convert to UnAlignMOV 
.Ltmp140:                               # EH_LABEL
	movq	88(%rsp), %rax
	movq	%rax, 16(%rsp)
	movups	72(%rsp), %xmm0
	movups	%xmm0, (%rsp)
	leaq	32(%rsp), %rcx
	movl	$1, %esi
	movl	$4, %edx
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHostC2ENS0_5rangeILi3EEEiiRKNS0_13property_listE
.Ltmp141:                               # EH_LABEL
# %bb.1:
	movq	40(%rsp), %r14
	movq	48(%rsp), %r12
	cmpq	%r12, %r14
	je	.LBB13_13
# %bb.2:
	movabsq	$4294967297, %r13               # imm = 0x100000001
	jmp	.LBB13_3
	.p2align	4
.LBB13_5:                               #   in Loop: Header=BB13_3 Depth=1
	movq	$0, 8(%r15)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*16(%rax)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*24(%rax)
.LBB13_11:                              #   in Loop: Header=BB13_3 Depth=1
	addq	$16, %r14
	cmpq	%r12, %r14
	je	.LBB13_12
.LBB13_3:                               # =>This Inner Loop Header: Depth=1
	movq	8(%r14), %r15
	testq	%r15, %r15
	je	.LBB13_11
# %bb.4:                                #   in Loop: Header=BB13_3 Depth=1
	movq	8(%r15), %rax
	cmpq	%r13, %rax
	je	.LBB13_5
# %bb.6:                                #   in Loop: Header=BB13_3 Depth=1
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB13_8
# %bb.7:                                #   in Loop: Header=BB13_3 Depth=1
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB13_11
	jmp	.LBB13_10
.LBB13_8:                               #   in Loop: Header=BB13_3 Depth=1
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB13_11
.LBB13_10:                              #   in Loop: Header=BB13_3 Depth=1
	movq	%r15, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB13_11
.LBB13_12:
	movq	40(%rsp), %r14
.LBB13_13:
	testq	%r14, %r14
	je	.LBB13_15
# %bb.14:
	movq	56(%rsp), %rsi
	subq	%r14, %rsi
	movq	%r14, %rdi
	callq	_ZdlPvm
.LBB13_15:
	movb	$0, 16(%rbx)
	movq	$0, 17(%rbx)
	movq	$0, 24(%rbx)
	movq	(%rbx), %rsi
.Ltmp143:                               # EH_LABEL
	leaq	96(%rsp), %r8
	xorl	%edi, %edi
	movl	$2016, %edx                     # imm = 0x7E0
	movl	$1026, %ecx                     # imm = 0x402
	callq	_ZN4sycl3_V16detail23constructorNotificationEPvS2_NS0_6access6targetENS3_4modeERKNS1_13code_locationE
.Ltmp144:                               # EH_LABEL
# %bb.16:
.Ltmp145:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHost7getSizeEv
.Ltmp146:                               # EH_LABEL
# %bb.17:
.Ltmp147:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZNK4sycl3_V16detail21LocalAccessorBaseHost7getSizeEv
.Ltmp148:                               # EH_LABEL
# %bb.18:
	addq	$128, %rsp
	.cfi_def_cfa_offset 48
	popq	%rbx
	.cfi_def_cfa_offset 40
	popq	%r12
	.cfi_def_cfa_offset 32
	popq	%r13
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	retq
.LBB13_19:
	.cfi_def_cfa_offset 176
.Ltmp142:                               # EH_LABEL
	movq	%rax, %r14
	leaq	32(%rsp), %rdi
	callq	_ZN4sycl3_V16detail16PropertyListBaseD2Ev
	movq	%r14, %rdi
	callq	_Unwind_Resume@PLT
.LBB13_20:
.Ltmp149:                               # EH_LABEL
	movq	%rax, %r14
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev
	movq	%r14, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end13:
	.size	_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE, .Lfunc_end13-_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE
	.cfi_endproc
	.section	.gcc_except_table._ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE,"aG",@progbits,_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE,comdat
	.p2align	2, 0x0
GCC_except_table13:
.Lexception6:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end6-.Lcst_begin6
.Lcst_begin6:
	.uleb128 .Ltmp140-.Lfunc_begin6         # >> Call Site 1 <<
	.uleb128 .Ltmp141-.Ltmp140              #   Call between .Ltmp140 and .Ltmp141
	.uleb128 .Ltmp142-.Lfunc_begin6         #     jumps to .Ltmp142
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp141-.Lfunc_begin6         # >> Call Site 2 <<
	.uleb128 .Ltmp143-.Ltmp141              #   Call between .Ltmp141 and .Ltmp143
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp143-.Lfunc_begin6         # >> Call Site 3 <<
	.uleb128 .Ltmp148-.Ltmp143              #   Call between .Ltmp143 and .Ltmp148
	.uleb128 .Ltmp149-.Lfunc_begin6         #     jumps to .Ltmp149
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp148-.Lfunc_begin6         # >> Call Site 4 <<
	.uleb128 .Lfunc_end13-.Ltmp148          #   Call between .Ltmp148 and .Lfunc_end13
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end6:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	.prefalign	4, .Lfunc_end14, nop
	.type	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev,@function
_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	testq	%rdi, %rdi
	je	.LBB14_6
# %bb.1:
	movq	8(%rdi), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB14_2
# %bb.7:
	movq	$0, 8(%rdi)
	movq	(%rdi), %rax
	movq	%rdi, %rbx
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB14_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB14_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rdi)
	cmpl	$1, %eax
	je	.LBB14_8
.LBB14_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB14_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rdi)
	cmpl	$1, %eax
	jne	.LBB14_6
.LBB14_8:
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end14:
	.size	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev, .Lfunc_end14-_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	.cfi_endproc
                                        # -- End function
	.section	.text._ZN4sycl3_V19exceptionC1ESt10error_codePKc,"axG",@progbits,_ZN4sycl3_V19exceptionC1ESt10error_codePKc,comdat
	.weak	_ZN4sycl3_V19exceptionC1ESt10error_codePKc # -- Begin function _ZN4sycl3_V19exceptionC1ESt10error_codePKc
	.p2align	1
	.prefalign	4, .Lfunc_end15, nop
	.type	_ZN4sycl3_V19exceptionC1ESt10error_codePKc,@function
_ZN4sycl3_V19exceptionC1ESt10error_codePKc: # 
.Lfunc_begin7:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception7
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	subq	$16, %rsp
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -16
	movq	%rcx, %r8
	xorps	%xmm0, %xmm0
	movups	%xmm0, (%rsp)                   # AlignMOV convert to UnAlignMOV 
.Ltmp150:                               # EH_LABEL
	movq	%rsp, %rcx
	callq	_ZN4sycl3_V19exceptionC1ESt10error_codeSt10shared_ptrINS0_7contextEEPKc
.Ltmp151:                               # EH_LABEL
# %bb.1:
	movq	8(%rsp), %rbx
	testq	%rbx, %rbx
	je	.LBB15_9
# %bb.2:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB15_4
# %bb.3:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
	jmp	.LBB15_9
.LBB15_4:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB15_6
# %bb.5:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB15_8
.LBB15_9:
	addq	$16, %rsp
	.cfi_def_cfa_offset 16
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB15_6:
	.cfi_def_cfa_offset 32
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB15_9
.LBB15_8:
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB15_9
.LBB15_10:
.Ltmp152:                               # EH_LABEL
	movq	%rax, %rbx
	movq	%rsp, %rdi
	callq	_ZNSt12__shared_ptrIN4sycl3_V17contextELN9__gnu_cxx12_Lock_policyE2EED2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end15:
	.size	_ZN4sycl3_V19exceptionC1ESt10error_codePKc, .Lfunc_end15-_ZN4sycl3_V19exceptionC1ESt10error_codePKc
	.cfi_endproc
	.section	.gcc_except_table._ZN4sycl3_V19exceptionC1ESt10error_codePKc,"aG",@progbits,_ZN4sycl3_V19exceptionC1ESt10error_codePKc,comdat
	.p2align	2, 0x0
GCC_except_table15:
.Lexception7:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end7-.Lcst_begin7
.Lcst_begin7:
	.uleb128 .Ltmp150-.Lfunc_begin7         # >> Call Site 1 <<
	.uleb128 .Ltmp151-.Ltmp150              #   Call between .Ltmp150 and .Ltmp151
	.uleb128 .Ltmp152-.Lfunc_begin7         #     jumps to .Ltmp152
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp151-.Lfunc_begin7         # >> Call Site 2 <<
	.uleb128 .Lfunc_end15-.Ltmp151          #   Call between .Ltmp151 and .Lfunc_end15
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end7:
	.p2align	2, 0x0
                                        # -- End function
	.section	.text._ZNSt12__shared_ptrIN4sycl3_V17contextELN9__gnu_cxx12_Lock_policyE2EED2Ev,"axG",@progbits,_ZNSt12__shared_ptrIN4sycl3_V17contextELN9__gnu_cxx12_Lock_policyE2EED2Ev,comdat
	.weak	_ZNSt12__shared_ptrIN4sycl3_V17contextELN9__gnu_cxx12_Lock_policyE2EED2Ev # -- Begin function _ZNSt12__shared_ptrIN4sycl3_V17contextELN9__gnu_cxx12_Lock_policyE2EED2Ev
	.p2align	1
	.prefalign	4, .Lfunc_end16, nop
	.type	_ZNSt12__shared_ptrIN4sycl3_V17contextELN9__gnu_cxx12_Lock_policyE2EED2Ev,@function
_ZNSt12__shared_ptrIN4sycl3_V17contextELN9__gnu_cxx12_Lock_policyE2EED2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	8(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB16_6
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB16_2
# %bb.7:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB16_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB16_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB16_8
.LBB16_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB16_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB16_6
.LBB16_8:
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end16:
	.size	_ZNSt12__shared_ptrIN4sycl3_V17contextELN9__gnu_cxx12_Lock_policyE2EED2Ev, .Lfunc_end16-_ZNSt12__shared_ptrIN4sycl3_V17contextELN9__gnu_cxx12_Lock_policyE2EED2Ev
	.cfi_endproc
                                        # -- End function
	.text
	.prefalign	4, .Lfunc_end17, nop    # -- Begin function _ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.type	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi,@function
_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi: # 
	.cfi_startproc
# %bb.0:
	movl	%edi, %ecx
	shlq	$2, %rcx
	movq	_ZN4sycl3_V16detailL17kernel_signaturesE(%rcx,%rcx,2), %rax
	movl	_ZN4sycl3_V16detailL17kernel_signaturesE+8(%rcx,%rcx,2), %edx
	retq
.Lfunc_end17:
	.size	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi, .Lfunc_end17-_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.prefalign	4, .Lfunc_end18, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv: # 
	.cfi_startproc
# %bb.0:
	leaq	8(%rdi), %rax
	retq
.Lfunc_end18:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv, .Lfunc_end18-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.prefalign	4, .Lfunc_end19, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rdi)
	movq	64(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB19_6
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB19_2
# %bb.7:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB19_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB19_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB19_8
.LBB19_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB19_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB19_6
.LBB19_8:
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end19:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev, .Lfunc_end19-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.prefalign	4, .Lfunc_end20, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%r14
	.cfi_def_cfa_offset 16
	pushq	%rbx
	.cfi_def_cfa_offset 24
	pushq	%rax
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -24
	.cfi_offset %r14, -16
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rdi)
	movq	64(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB20_9
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB20_3
# %bb.2:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rdi, %r14
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
.LBB20_8:
	movq	%r14, %rdi
	jmp	.LBB20_9
.LBB20_3:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB20_5
# %bb.4:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB20_7
.LBB20_9:
	movl	$96, %esi
	addq	$8, %rsp
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	jmp	_ZdlPvm                         # TAILCALL
.LBB20_5:
	.cfi_def_cfa_offset 32
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB20_9
.LBB20_7:
	movq	%rdi, %r14
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB20_8
.Lfunc_end20:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev, .Lfunc_end20-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.cfi_endproc
                                        # -- End function
	.prefalign	4, .Lfunc_end21, nop    # -- Begin function _ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE
	.type	_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE,@function
_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE: # 
.Lfunc_begin8:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception8
# %bb.0:
	pushq	%r14
	.cfi_def_cfa_offset 16
	pushq	%rbx
	.cfi_def_cfa_offset 24
	pushq	%rax
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -24
	.cfi_offset %r14, -16
	movq	8(%rdi), %rax
	cmpl	$0, 4(%rax)
	jg	.LBB21_1
# %bb.4:
	addq	$8, %rsp
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	retq
.LBB21_1:
	.cfi_def_cfa_offset 32
	movslq	40(%rdi), %rcx
	movq	16(%rdi), %rdx
	xorl	%esi, %esi
	cmpb	$1, 4(%rdi)
	adcl	$3, %esi
	movslq	24(%rdi), %r8
	imulq	%r8, %rsi
	movslq	(%rax), %r8
	addq	%rsi, %r8
	movq	(%rdx,%r8,8), %r14
	movslq	8(%rax), %rax
	movq	80(%rdi), %rdx
	imulq	%rcx, %rax
	pinsrw	$0, (%rdx,%rax,2), %xmm0
	movq	%rdi, %rbx
	callq	__extendhfsf2@PLT
	movd	%xmm0, 4(%rsp)                  # 4-byte Folded Spill
	pinsrw	$0, (%r14), %xmm0
	callq	__extendhfsf2@PLT
	mulss	4(%rsp), %xmm0                  # 4-byte Folded Reload
	movss	%xmm0, 4(%rsp)                  # 4-byte Spill
	addq	$48, %rbx
	movq	%rbx, %rdi
	callq	_ZNK4sycl3_V16detail21LocalAccessorBaseHost6getPtrEv
	movss	4(%rsp), %xmm0                  # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%rax)
.Ltmp153:                               # EH_LABEL
	movl	$.L.str.8, %edi
	callq	_ZN4sycl3_V16detail24cannot_be_called_on_hostEPKc
.Ltmp154:                               # EH_LABEL
# %bb.2:
.LBB21_3:
.Ltmp155:                               # EH_LABEL
	movq	%rax, %rdi
	callq	__clang_call_terminate
.Lfunc_end21:
	.size	_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE, .Lfunc_end21-_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table21:
.Lexception8:
	.byte	255                             # @LPStart Encoding = omit
	.byte	3                               # @TType Encoding = udata4
	.uleb128 .Lttbase1-.Lttbaseref1
.Lttbaseref1:
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end8-.Lcst_begin8
.Lcst_begin8:
	.uleb128 .Lfunc_begin8-.Lfunc_begin8    # >> Call Site 1 <<
	.uleb128 .Ltmp153-.Lfunc_begin8         #   Call between .Lfunc_begin8 and .Ltmp153
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp153-.Lfunc_begin8         # >> Call Site 2 <<
	.uleb128 .Ltmp154-.Ltmp153              #   Call between .Ltmp153 and .Ltmp154
	.uleb128 .Ltmp155-.Lfunc_begin8         #     jumps to .Ltmp155
	.byte	1                               #   On action: 1
.Lcst_end8:
	.byte	1                               # >> Action Record 1 <<
                                        #   Catch TypeInfo 1
	.byte	0                               #   No further actions
	.p2align	2, 0x0
                                        # >> Catch TypeInfos <<
	.long	0                               # TypeInfo 1
.Lttbase1:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZZNS5_7forwardES8_iSB_SD_SE_iENKUlbE_clEbEUlRNS0_7handlerEE_EEDaSG_EUlSL_E_E4callEPKvSL_
	.prefalign	4, .Lfunc_end22, nop
	.type	_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZZNS5_7forwardES8_iSB_SD_SE_iENKUlbE_clEbEUlRNS0_7handlerEE_EEDaSG_EUlSL_E_E4callEPKvSL_,@function
_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZZNS5_7forwardES8_iSB_SD_SE_iENKUlbE_clEbEUlRNS0_7handlerEE_EEDaSG_EUlSL_E_E4callEPKvSL_: # 
.Lfunc_begin9:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception9
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$776, %rsp                      # imm = 0x308
	.cfi_def_cfa_offset 832
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rsi, %rbx
	movq	%rdi, %r14
	movq	(%rdi), %rax
	movups	(%rax), %xmm0
	movq	8(%rax), %rax
	movups	%xmm0, 112(%rsp)                # AlignMOV convert to UnAlignMOV 
	testq	%rax, %rax
	je	.LBB22_5
# %bb.1:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_3
# %bb.2:
	movl	8(%rax), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%rax)
	cmpl	$-1, %ecx
	jne	.LBB22_5
	jmp	.LBB22_115
.LBB22_3:
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%rax)
	cmpl	$-1, %ecx
	je	.LBB22_115
.LBB22_5:
.Ltmp156:                               # EH_LABEL
	leaq	112(%rsp), %rsi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler10depends_onENS0_5eventE
.Ltmp157:                               # EH_LABEL
# %bb.6:
	movq	120(%rsp), %r15
	testq	%r15, %r15
	je	.LBB22_14
# %bb.7:
	movq	8(%r15), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB22_9
# %bb.8:
	movq	$0, 8(%r15)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*16(%rax)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*24(%rax)
	jmp	.LBB22_14
.LBB22_9:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_11
# %bb.10:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$1, %eax
	je	.LBB22_13
.LBB22_14:
	movq	8(%r14), %r12
	movq	(%r12), %rax
	movslq	(%rax), %rbp
	movq	$.L.str, 80(%rsp)
	movq	$.L.str.3, 88(%rsp)
	movabsq	$201863463128, %rax             # imm = 0x2F000000D8
	movq	%rax, 96(%rsp)
	movq	%rbp, %rax
	shlq	$4, %rax
	movq	%rax, 184(%rsp)
	movq	$1, 192(%rsp)
	movq	$1, 200(%rsp)
	xorps	%xmm0, %xmm0
	movups	%xmm0, 352(%rsp)                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 336(%rsp)                # AlignMOV convert to UnAlignMOV 
.Ltmp159:                               # EH_LABEL
	movq	200(%rsp), %rax
	movq	%rax, 16(%rsp)
	movups	184(%rsp), %xmm0
	movups	%xmm0, (%rsp)
	leaq	48(%rsp), %rdi
	leaq	336(%rsp), %rcx
	movl	$1, %esi
	movl	$4, %edx
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHostC2ENS0_5rangeILi3EEEiiRKNS0_13property_listE
.Ltmp160:                               # EH_LABEL
# %bb.15:
	movq	344(%rsp), %r14
	movq	352(%rsp), %r13
	cmpq	%r13, %r14
	jne	.LBB22_16
# %bb.26:
	testq	%r14, %r14
	je	.LBB22_28
.LBB22_27:
	movq	360(%rsp), %rsi
	subq	%r14, %rsi
	movq	%r14, %rdi
	callq	_ZdlPvm
.LBB22_28:
	xorps	%xmm0, %xmm0
	movups	%xmm0, 64(%rsp)
	movq	48(%rsp), %rsi
.Ltmp162:                               # EH_LABEL
	leaq	80(%rsp), %r8
	xorl	%edi, %edi
	movl	$2016, %edx                     # imm = 0x7E0
	movl	$1026, %ecx                     # imm = 0x402
	callq	_ZN4sycl3_V16detail23constructorNotificationEPvS2_NS0_6access6targetENS3_4modeERKNS1_13code_locationE
.Ltmp163:                               # EH_LABEL
# %bb.29:
.Ltmp164:                               # EH_LABEL
	leaq	48(%rsp), %rdi
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHost7getSizeEv
.Ltmp165:                               # EH_LABEL
# %bb.30:
.Ltmp166:                               # EH_LABEL
	leaq	48(%rsp), %rdi
	callq	_ZNK4sycl3_V16detail21LocalAccessorBaseHost7getSizeEv
.Ltmp167:                               # EH_LABEL
# %bb.31:
	movq	$.L.str, 160(%rsp)
	movq	$.L.str.3, 168(%rsp)
	movabsq	$188978561241, %rax             # imm = 0x2C000000D9
	movq	%rax, 176(%rsp)
.Ltmp169:                               # EH_LABEL
	movq	176(%rsp), %rax
	movq	%rax, 16(%rsp)
	movups	160(%rsp), %xmm0
	movups	%xmm0, (%rsp)
	leaq	80(%rsp), %rdi
	movl	$128, %esi
	movq	%rbx, %rdx
	callq	_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE
.Ltmp170:                               # EH_LABEL
# %bb.32:
	shll	$3, %ebp
	movq	8(%r12), %rax
	movq	(%rax), %r13
	movq	16(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 336(%rsp)
	movq	24(%r12), %rax
	movzbl	(%rax), %eax
	movb	%al, 340(%rsp)
	movq	32(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 344(%rsp)
	movq	40(%r12), %rax
	movzbl	(%rax), %eax
	movb	%al, 348(%rsp)
	movq	48(%r12), %rax
	movq	(%rax), %rax
	movq	%rax, 352(%rsp)
	movq	56(%r12), %rax
	movq	(%rax), %rax
	movq	%rax, 360(%rsp)
	movq	64(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 368(%rsp)
	movq	72(%r12), %rax
	movq	(%rax), %rax
	movq	%rax, 376(%rsp)
	movq	80(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 384(%rsp)
	movq	88(%r12), %rax
	movq	(%rax), %rax
	movq	%rax, 392(%rsp)
	movq	96(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 400(%rsp)
	leaq	404(%rsp), %rdi
	movq	104(%r12), %rsi
	movl	$256, %edx                      # imm = 0x100
	callq	_intel_fast_memcpy@PLT
	movq	112(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 660(%rsp)
	movq	(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 664(%rsp)
	movl	%ebp, 668(%rsp)
	movq	48(%rsp), %rbp
	movq	56(%rsp), %r14
	movq	%rbp, 672(%rsp)
	movq	%r14, 680(%rsp)
	testq	%r14, %r14
	je	.LBB22_42
# %bb.33:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_40
# %bb.34:
	movl	8(%r14), %eax
	leal	1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$-1, %eax
	jne	.LBB22_42
	jmp	.LBB22_115
	.p2align	4
.LBB22_18:                              #   in Loop: Header=BB22_16 Depth=1
	movq	$0, 8(%r15)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*16(%rax)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*24(%rax)
.LBB22_24:                              #   in Loop: Header=BB22_16 Depth=1
	addq	$16, %r14
	cmpq	%r13, %r14
	je	.LBB22_25
.LBB22_16:                              # =>This Inner Loop Header: Depth=1
	movq	8(%r14), %r15
	testq	%r15, %r15
	je	.LBB22_24
# %bb.17:                               #   in Loop: Header=BB22_16 Depth=1
	movq	8(%r15), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	je	.LBB22_18
# %bb.19:                               #   in Loop: Header=BB22_16 Depth=1
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_21
# %bb.20:                               #   in Loop: Header=BB22_16 Depth=1
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB22_24
	jmp	.LBB22_23
.LBB22_21:                              #   in Loop: Header=BB22_16 Depth=1
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB22_24
.LBB22_23:                              #   in Loop: Header=BB22_16 Depth=1
	movq	%r15, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB22_24
.LBB22_25:
	movq	344(%rsp), %r14
	testq	%r14, %r14
	jne	.LBB22_27
	jmp	.LBB22_28
.LBB22_40:
	movl	$1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$-1, %eax
	je	.LBB22_115
.LBB22_42:
	leaq	64(%rsp), %rax
	movups	(%rax), %xmm0
	movups	%xmm0, 688(%rsp)
	movq	120(%r12), %rax
	movl	(%rax), %edx
	movl	%edx, 704(%rsp)
	movq	80(%rsp), %rsi
	movq	88(%rsp), %r15
	movq	%rsi, 712(%rsp)
	movq	%r15, 720(%rsp)
	testq	%r15, %r15
	je	.LBB22_47
# %bb.43:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_45
# %bb.44:
	movl	8(%r15), %eax
	leal	1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$-1, %eax
	jne	.LBB22_47
	jmp	.LBB22_115
.LBB22_45:
	movl	$1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$-1, %eax
	je	.LBB22_115
.LBB22_47:
	movq	%rsi, 128(%rsp)                 # 8-byte Spill
	movl	%edx, 44(%rsp)                  # 4-byte Spill
	movups	96(%rsp), %xmm0
	movups	%xmm0, 728(%rsp)
	movq	128(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 744(%rsp)
	movq	136(%r12), %rax
	movq	(%rax), %rax
	movq	%rax, 752(%rsp)
	movq	144(%r12), %rax
	movq	(%rax), %rax
	movq	%rax, 760(%rsp)
.Ltmp172:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZNK4sycl3_V17handler7getTypeEv
.Ltmp173:                               # EH_LABEL
# %bb.48:
	testl	%eax, %eax
	jne	.LBB22_49
# %bb.53:
.Ltmp179:                               # EH_LABEL
	movl	$.L.str.11, %esi
	movl	$146, %edx
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler30verifyUsedKernelBundleInternalENS0_6detail11string_viewE
.Ltmp180:                               # EH_LABEL
# %bb.54:
	movq	%r13, 136(%rsp)
	leaq	144(%rsp), %rax
	movq	$128, 144(%rsp)
	leaq	152(%rsp), %rcx
	movq	$0, 152(%rsp)
	leaq	136(%rsp), %rdx
	movq	%rdx, 184(%rsp)
	movq	%rax, 192(%rsp)
	movq	%rcx, 200(%rsp)
	movq	$1, 208(%rsp)
.Ltmp181:                               # EH_LABEL
	movups	184(%rsp), %xmm0
	movups	200(%rsp), %xmm1
	movups	%xmm1, 16(%rsp)
	movups	%xmm0, (%rsp)
	movq	%rbx, %rdi
	xorl	%esi, %esi
	callq	_ZN4sycl3_V17handler20setNDRangeDescriptorENS0_6detail16nd_range_view_v113nd_range_viewEb
.Ltmp182:                               # EH_LABEL
# %bb.55:
.Ltmp183:                               # EH_LABEL
	movl	$440, %edi                      # imm = 0x1B8
	callq	_Znwm
.Ltmp184:                               # EH_LABEL
# %bb.56:
	movq	%rax, %r12
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE+16, (%rax)
	movq	%rax, %rdi
	addq	$8, %rdi
	leaq	336(%rsp), %rsi
	movl	$336, %edx                      # imm = 0x150
	callq	_intel_fast_memcpy@PLT
	movq	%rbp, 344(%r12)
	movq	%r14, 352(%r12)
	testq	%r14, %r14
	movl	44(%rsp), %edx                  # 4-byte Reload
	movq	128(%rsp), %rsi                 # 8-byte Reload
	je	.LBB22_61
# %bb.57:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_59
# %bb.58:
	movl	8(%r14), %eax
	leal	1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$-1, %eax
	jne	.LBB22_61
	jmp	.LBB22_115
.LBB22_59:
	movl	$1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$-1, %eax
	je	.LBB22_115
.LBB22_61:
	leaq	688(%rsp), %rax
	movups	(%rax), %xmm0
	movups	%xmm0, 360(%r12)
	movl	%edx, 376(%r12)
	movq	%rsi, 384(%r12)
	movq	%r15, 392(%r12)
	testq	%r15, %r15
	je	.LBB22_66
# %bb.62:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_64
# %bb.63:
	movl	8(%r15), %eax
	leal	1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$-1, %eax
	je	.LBB22_115
.LBB22_66:
	leaq	728(%rsp), %rax
	movups	(%rax), %xmm0
	movups	%xmm0, 400(%r12)
	movups	16(%rax), %xmm0
	movups	%xmm0, 416(%r12)
	movq	32(%rax), %rax
	movq	%rax, 432(%r12)
	movq	144(%rbx), %rdi
	movq	%r12, 144(%rbx)
	testq	%rdi, %rdi
	je	.LBB22_68
# %bb.67:
	movq	(%rdi), %rax
	callq	*16(%rax)
.LBB22_68:
.Ltmp185:                               # EH_LABEL
	movl	$_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi1EEEZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESI_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE, %esi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler23instantiateKernelOnHostEPv
.Ltmp186:                               # EH_LABEL
# %bb.69:
	movq	144(%rbx), %rdi
	movq	(%rdi), %rax
.Ltmp187:                               # EH_LABEL
	callq	*(%rax)
.Ltmp188:                               # EH_LABEL
# %bb.70:
	movq	$.L.str.11, 64(%rbx)
	movq	$146, 72(%rbx)
.Ltmp189:                               # EH_LABEL
	movq	%rbx, %rdi
	movq	%rax, %rsi
	callq	_ZN4sycl3_V17handler13setKernelFuncEPv
.Ltmp190:                               # EH_LABEL
# %bb.71:
	movzbl	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip), %eax
	testb	%al, %al
	je	.LBB22_72
.LBB22_75:
	movq	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip), %rsi
.Ltmp194:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler22setDeviceKernelInfoPtrEPNS0_6detail16DeviceKernelInfoE
.Ltmp195:                               # EH_LABEL
# %bb.76:
.Ltmp196:                               # EH_LABEL
	movq	%rbx, %rdi
	movl	$1, %esi
	callq	_ZN4sycl3_V17handler7setTypeENS0_6detail6CGTypeE
.Ltmp197:                               # EH_LABEL
# %bb.77:
	movb	$0, 192(%rsp)
	movb	$0, 202(%rsp)
	movb	$0, 204(%rsp)
	movb	$0, 212(%rsp)
	movb	$0, 220(%rsp)
	movb	$0, 228(%rsp)
	movb	$0, 236(%rsp)
	movb	$0, 244(%rsp)
	movb	$0, 252(%rsp)
	movb	$0, 264(%rsp)
	movb	$0, 288(%rsp)
	movb	$0, 320(%rsp)
	movb	$1, 328(%rsp)
.Ltmp198:                               # EH_LABEL
	leaq	184(%rsp), %rsi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler25setKernelLaunchPropertiesERKNS0_6detail27kernel_launch_properties_v111PropsHolderIJNS0_3ext6oneapi12experimental23work_group_scratch_sizeENS5_5intel12experimental12cache_configENS7_17use_root_sync_keyENS7_23work_group_progress_keyENS7_22sub_group_progress_keyENS7_22work_item_progress_keyENS7_4cuda12cluster_sizeILi1EEENSH_ILi2EEENSH_ILi3EEEEEE
.Ltmp199:                               # EH_LABEL
# %bb.78:
	testq	%r15, %r15
	je	.LBB22_86
# %bb.79:
	movq	8(%r15), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB22_81
# %bb.80:
	movq	$0, 8(%r15)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*16(%rax)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*24(%rax)
	testq	%r14, %r14
	jne	.LBB22_87
	jmp	.LBB22_94
.LBB22_81:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_83
# %bb.82:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$1, %eax
	je	.LBB22_85
.LBB22_86:
	testq	%r14, %r14
	je	.LBB22_94
.LBB22_87:
	movq	8(%r14), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB22_89
# %bb.88:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	jmp	.LBB22_94
.LBB22_89:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_91
# %bb.90:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB22_94
	jmp	.LBB22_93
.LBB22_64:
	movl	$1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$-1, %eax
	jne	.LBB22_66
.LBB22_115:
	ud2
.LBB22_11:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB22_14
.LBB22_13:
	movq	%r15, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB22_14
.LBB22_83:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB22_86
.LBB22_85:
	movq	%r15, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	testq	%r14, %r14
	jne	.LBB22_87
	jmp	.LBB22_94
.LBB22_91:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	je	.LBB22_93
.LBB22_94:
	movq	88(%rsp), %rbx
	testq	%rbx, %rbx
	je	.LBB22_102
# %bb.95:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB22_97
# %bb.96:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
	jmp	.LBB22_102
.LBB22_97:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_99
# %bb.98:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB22_101
.LBB22_102:
	movq	56(%rsp), %rbx
	testq	%rbx, %rbx
	je	.LBB22_110
# %bb.103:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB22_105
# %bb.104:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
	jmp	.LBB22_110
.LBB22_105:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB22_107
# %bb.106:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB22_109
.LBB22_110:
	addq	$776, %rsp                      # imm = 0x308
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB22_99:
	.cfi_def_cfa_offset 832
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB22_102
.LBB22_101:
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB22_102
.LBB22_107:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB22_110
.LBB22_109:
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB22_110
.LBB22_93:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB22_94
.LBB22_49:
	movl	$64, %edi
	callq	__cxa_allocate_exception
	movq	%rax, %r14
	movl	$1, %edi
	callq	_ZN4sycl3_V115make_error_codeENS0_4errcE
.Ltmp174:                               # EH_LABEL
	movl	$.L.str.7, %ecx
	movq	%r14, %rdi
	movl	%eax, %esi
	callq	_ZN4sycl3_V19exceptionC1ESt10error_codePKc
.Ltmp175:                               # EH_LABEL
# %bb.50:
.Ltmp177:                               # EH_LABEL
	movl	$_ZTIN4sycl3_V19exceptionE, %esi
	movl	$_ZN4sycl3_V19exceptionD1Ev, %edx
	movq	%r14, %rdi
	callq	__cxa_throw
.Ltmp178:                               # EH_LABEL
# %bb.51:
.LBB22_72:
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_acquire
	testl	%eax, %eax
	je	.LBB22_75
# %bb.73:
.Ltmp191:                               # EH_LABEL
	movl	$_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESH_EUlNS0_7nd_itemILi1EEEE_EE, %edi
	callq	_ZN4sycl3_V16detail19getDeviceKernelInfoERKNS1_27compile_time_kernel_info_v123CompileTimeKernelInfoTyE
.Ltmp192:                               # EH_LABEL
# %bb.74:
	movq	%rax, _ZZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip)
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_release
	jmp	.LBB22_75
.LBB22_116:
.Ltmp193:                               # EH_LABEL
	movq	%rax, %rbx
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_abort
	jmp	.LBB22_113
.LBB22_52:
.Ltmp176:                               # EH_LABEL
	movq	%rax, %rbx
	movq	%r14, %rdi
	callq	__cxa_free_exception
	jmp	.LBB22_113
.LBB22_111:
.Ltmp171:                               # EH_LABEL
	jmp	.LBB22_37
.LBB22_35:
.Ltmp161:                               # EH_LABEL
	movq	%rax, %rbx
	leaq	336(%rsp), %rdi
	callq	_ZN4sycl3_V16detail16PropertyListBaseD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.LBB22_114:
.Ltmp158:                               # EH_LABEL
	movq	%rax, %rbx
	leaq	112(%rsp), %rdi
	callq	_ZN4sycl3_V15eventD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.LBB22_36:
.Ltmp168:                               # EH_LABEL
.LBB22_37:
	movq	%rax, %rbx
	jmp	.LBB22_38
.LBB22_112:
.Ltmp200:                               # EH_LABEL
	movq	%rax, %rbx
.LBB22_113:
	leaq	336(%rsp), %rdi
	callq	_ZZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEbENKUlRN4sycl3_V17handlerEE_clESE_ENUlNSC_7nd_itemILi1EEEE_D2Ev
	leaq	80(%rsp), %rdi
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev
.LBB22_38:
	leaq	48(%rsp), %rdi
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end22:
	.size	_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZZNS5_7forwardES8_iSB_SD_SE_iENKUlbE_clEbEUlRNS0_7handlerEE_EEDaSG_EUlSL_E_E4callEPKvSL_, .Lfunc_end22-_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZZNS5_7forwardES8_iSB_SD_SE_iENKUlbE_clEbEUlRNS0_7handlerEE_EEDaSG_EUlSL_E_E4callEPKvSL_
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table22:
.Lexception9:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end9-.Lcst_begin9
.Lcst_begin9:
	.uleb128 .Ltmp156-.Lfunc_begin9         # >> Call Site 1 <<
	.uleb128 .Ltmp157-.Ltmp156              #   Call between .Ltmp156 and .Ltmp157
	.uleb128 .Ltmp158-.Lfunc_begin9         #     jumps to .Ltmp158
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp157-.Lfunc_begin9         # >> Call Site 2 <<
	.uleb128 .Ltmp159-.Ltmp157              #   Call between .Ltmp157 and .Ltmp159
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp159-.Lfunc_begin9         # >> Call Site 3 <<
	.uleb128 .Ltmp160-.Ltmp159              #   Call between .Ltmp159 and .Ltmp160
	.uleb128 .Ltmp161-.Lfunc_begin9         #     jumps to .Ltmp161
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp162-.Lfunc_begin9         # >> Call Site 4 <<
	.uleb128 .Ltmp167-.Ltmp162              #   Call between .Ltmp162 and .Ltmp167
	.uleb128 .Ltmp168-.Lfunc_begin9         #     jumps to .Ltmp168
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp169-.Lfunc_begin9         # >> Call Site 5 <<
	.uleb128 .Ltmp170-.Ltmp169              #   Call between .Ltmp169 and .Ltmp170
	.uleb128 .Ltmp171-.Lfunc_begin9         #     jumps to .Ltmp171
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp170-.Lfunc_begin9         # >> Call Site 6 <<
	.uleb128 .Ltmp172-.Ltmp170              #   Call between .Ltmp170 and .Ltmp172
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp172-.Lfunc_begin9         # >> Call Site 7 <<
	.uleb128 .Ltmp184-.Ltmp172              #   Call between .Ltmp172 and .Ltmp184
	.uleb128 .Ltmp200-.Lfunc_begin9         #     jumps to .Ltmp200
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp184-.Lfunc_begin9         # >> Call Site 8 <<
	.uleb128 .Ltmp185-.Ltmp184              #   Call between .Ltmp184 and .Ltmp185
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp185-.Lfunc_begin9         # >> Call Site 9 <<
	.uleb128 .Ltmp199-.Ltmp185              #   Call between .Ltmp185 and .Ltmp199
	.uleb128 .Ltmp200-.Lfunc_begin9         #     jumps to .Ltmp200
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp199-.Lfunc_begin9         # >> Call Site 10 <<
	.uleb128 .Ltmp174-.Ltmp199              #   Call between .Ltmp199 and .Ltmp174
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp174-.Lfunc_begin9         # >> Call Site 11 <<
	.uleb128 .Ltmp175-.Ltmp174              #   Call between .Ltmp174 and .Ltmp175
	.uleb128 .Ltmp176-.Lfunc_begin9         #     jumps to .Ltmp176
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp177-.Lfunc_begin9         # >> Call Site 12 <<
	.uleb128 .Ltmp178-.Ltmp177              #   Call between .Ltmp177 and .Ltmp178
	.uleb128 .Ltmp200-.Lfunc_begin9         #     jumps to .Ltmp200
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp191-.Lfunc_begin9         # >> Call Site 13 <<
	.uleb128 .Ltmp192-.Ltmp191              #   Call between .Ltmp191 and .Ltmp192
	.uleb128 .Ltmp193-.Lfunc_begin9         #     jumps to .Ltmp193
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp192-.Lfunc_begin9         # >> Call Site 14 <<
	.uleb128 .Lfunc_end22-.Ltmp192          #   Call between .Ltmp192 and .Lfunc_end22
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end9:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEbENKUlRN4sycl3_V17handlerEE_clESE_ENUlNSC_7nd_itemILi1EEEE_D2Ev
	.prefalign	4, .Lfunc_end23, nop
	.type	_ZZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEbENKUlRN4sycl3_V17handlerEE_clESE_ENUlNSC_7nd_itemILi1EEEE_D2Ev,@function
_ZZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEbENKUlRN4sycl3_V17handlerEE_clESE_ENUlNSC_7nd_itemILi1EEEE_D2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%r15
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%rbx
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -32
	.cfi_offset %r14, -24
	.cfi_offset %r15, -16
	movabsq	$4294967297, %r14               # imm = 0x100000001
	movq	384(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB23_9
# %bb.1:
	movq	8(%rbx), %rax
	cmpq	%r14, %rax
	jne	.LBB23_3
# %bb.2:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rdi, %r15
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
.LBB23_8:
	movq	%r15, %rdi
	jmp	.LBB23_9
.LBB23_3:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB23_5
# %bb.4:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB23_7
.LBB23_9:
	movq	344(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB23_15
# %bb.10:
	movq	8(%rbx), %rax
	cmpq	%r14, %rax
	jne	.LBB23_11
# %bb.16:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB23_11:
	.cfi_def_cfa_offset 32
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB23_13
# %bb.12:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB23_17
.LBB23_15:
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	retq
.LBB23_5:
	.cfi_def_cfa_offset 32
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB23_9
.LBB23_7:
	movq	%rdi, %r15
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB23_8
.LBB23_13:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB23_15
.LBB23_17:
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end23:
	.size	_ZZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEbENKUlRN4sycl3_V17handlerEE_clESE_ENUlNSC_7nd_itemILi1EEEE_D2Ev, .Lfunc_end23-_ZZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEbENKUlRN4sycl3_V17handlerEE_clESE_ENUlNSC_7nd_itemILi1EEEE_D2Ev
	.cfi_endproc
                                        # -- End function
	.section	.text._ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev,"axG",@progbits,_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev,comdat
	.weak	_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev # -- Begin function _ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev
	.p2align	1
	.prefalign	4, .Lfunc_end24, nop
	.type	_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev,@function
_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	8(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB24_6
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB24_2
# %bb.7:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB24_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB24_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB24_8
.LBB24_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB24_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB24_6
.LBB24_8:
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end24:
	.size	_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev, .Lfunc_end24-_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev
	.cfi_endproc
                                        # -- End function
	.text
	.prefalign	4, .Lfunc_end25, nop    # -- Begin function _ZN4sycl3_V16detail18getKernelParamDescIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EENS1_19kernel_param_desc_tEi
	.type	_ZN4sycl3_V16detail18getKernelParamDescIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EENS1_19kernel_param_desc_tEi,@function
_ZN4sycl3_V16detail18getKernelParamDescIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EENS1_19kernel_param_desc_tEi: # 
	.cfi_startproc
# %bb.0:
                                        # kill: def $edi killed $edi def $rdi
	addl	$9, %edi
	shlq	$2, %rdi
	movq	_ZN4sycl3_V16detailL17kernel_signaturesE(%rdi,%rdi,2), %rax
	movl	_ZN4sycl3_V16detailL17kernel_signaturesE+8(%rdi,%rdi,2), %edx
	retq
.Lfunc_end25:
	.size	_ZN4sycl3_V16detail18getKernelParamDescIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EENS1_19kernel_param_desc_tEi, .Lfunc_end25-_ZN4sycl3_V16detail18getKernelParamDescIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EENS1_19kernel_param_desc_tEi
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EE6getPtrEv
	.prefalign	4, .Lfunc_end26, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EE6getPtrEv,@function
_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EE6getPtrEv: # 
	.cfi_startproc
# %bb.0:
	leaq	8(%rdi), %rax
	retq
.Lfunc_end26:
	.size	_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EE6getPtrEv, .Lfunc_end26-_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EE6getPtrEv
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED2Ev
	.prefalign	4, .Lfunc_end27, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED2Ev,@function
_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%r15
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%rbx
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -32
	.cfi_offset %r14, -24
	.cfi_offset %r15, -16
	movabsq	$4294967297, %r14               # imm = 0x100000001
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE+16, (%rdi)
	movq	392(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB27_9
# %bb.1:
	movq	8(%rbx), %rax
	cmpq	%r14, %rax
	jne	.LBB27_3
# %bb.2:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rdi, %r15
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
.LBB27_8:
	movq	%r15, %rdi
	jmp	.LBB27_9
.LBB27_3:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB27_5
# %bb.4:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB27_7
.LBB27_9:
	movq	352(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB27_15
# %bb.10:
	movq	8(%rbx), %rax
	cmpq	%r14, %rax
	jne	.LBB27_11
# %bb.16:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB27_11:
	.cfi_def_cfa_offset 32
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB27_13
# %bb.12:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB27_17
.LBB27_15:
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	retq
.LBB27_5:
	.cfi_def_cfa_offset 32
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB27_9
.LBB27_7:
	movq	%rdi, %r15
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB27_8
.LBB27_13:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB27_15
.LBB27_17:
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end27:
	.size	_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED2Ev, .Lfunc_end27-_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED2Ev
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED0Ev
	.prefalign	4, .Lfunc_end28, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED0Ev,@function
_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED0Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	%rdi, %rbx
	callq	_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED2Ev
	movl	$440, %esi                      # imm = 0x1B8
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZdlPvm                         # TAILCALL
.Lfunc_end28:
	.size	_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED0Ev, .Lfunc_end28-_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED0Ev
	.cfi_endproc
                                        # -- End function
	.prefalign	4, .Lfunc_end29, nop    # -- Begin function _ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi1EEEZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESI_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE
	.type	_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi1EEEZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESI_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE,@function
_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi1EEEZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESI_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE: # 
.Lfunc_begin10:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception10
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	pushq	%rax
	.cfi_def_cfa_offset 64
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rdi, %rbx
	movzbl	12(%rdi), %eax
	xorb	$1, %al
	xorl	%edx, %edx
	cmpb	$0, 4(%rdi)
	sete	%dl
	movzbl	%al, %ecx
	movl	$2, %eax
	cmovel	%ecx, %eax
	movq	16(%rdi), %rcx
	movl	4(%rcx), %ebp
	shll	$4, %edx
	movq	40(%rdi,%rdx), %rdx
	movq	%rdx, (%rsp)                    # 8-byte Spill
	cmpl	$0, 332(%rdi)
	jle	.LBB29_3
# %bb.1:
	movslq	(%rcx), %rcx
	movq	24(%rbx), %rdx
	movslq	32(%rbx), %rsi
	movzbl	%al, %eax
	imulq	%rsi, %rax
	addq	%rcx, %rax
	movq	(%rdx,%rax,8), %r13
	leaq	336(%rbx), %r14
	xorl	%r15d, %r15d
	.p2align	4
.LBB29_2:                               # =>This Inner Loop Header: Depth=1
	movslq	328(%rbx), %rcx
	movl	%r15d, %eax
	cltd
	idivl	%ecx
	movslq	%eax, %rdx
	imull	%ecx, %eax
	cltq
	imulq	%rcx, %rdx
	subq	%rax, %rdx
	addq	%r15, %rdx
	movl	(%r13,%rdx,4), %r12d
	movq	%r14, %rdi
	callq	_ZNK4sycl3_V16detail21LocalAccessorBaseHost6getPtrEv
	movl	%r12d, (%rax,%r15,4)
	subq	$-128, %r15
	movslq	332(%rbx), %rax
	cmpq	%rax, %r15
	jl	.LBB29_2
.LBB29_3:
	testl	%ebp, %ebp
	jle	.LBB29_5
# %bb.4:
	addq	$376, %rbx                      # imm = 0x178
	movq	(%rsp), %rax                    # 8-byte Reload
	movss	(%rax), %xmm0                   # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%rsp)                   # 4-byte Spill
	movq	%rbx, %rdi
	callq	_ZNK4sycl3_V16detail21LocalAccessorBaseHost6getPtrEv
	movss	(%rsp), %xmm0                   # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%rax)
.LBB29_5:
	movl	$64, %edi
	callq	__cxa_allocate_exception
	movq	%rax, %rbx
	movl	$12, %edi
	callq	_ZN4sycl3_V115make_error_codeENS0_4errcE
.Ltmp201:                               # EH_LABEL
	movl	$.L.str.9, %ecx
	movq	%rbx, %rdi
	movl	%eax, %esi
	callq	_ZN4sycl3_V19exceptionC1ESt10error_codePKc
.Ltmp202:                               # EH_LABEL
# %bb.6:
	movl	$_ZTIN4sycl3_V19exceptionE, %esi
	movl	$_ZN4sycl3_V19exceptionD1Ev, %edx
	movq	%rbx, %rdi
	callq	__cxa_throw
.LBB29_7:
.Ltmp203:                               # EH_LABEL
	movq	%rax, %r14
	movq	%rbx, %rdi
	callq	__cxa_free_exception
	movq	%r14, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end29:
	.size	_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi1EEEZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESI_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE, .Lfunc_end29-_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi1EEEZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESI_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table29:
.Lexception10:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end10-.Lcst_begin10
.Lcst_begin10:
	.uleb128 .Lfunc_begin10-.Lfunc_begin10  # >> Call Site 1 <<
	.uleb128 .Ltmp201-.Lfunc_begin10        #   Call between .Lfunc_begin10 and .Ltmp201
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp201-.Lfunc_begin10        # >> Call Site 2 <<
	.uleb128 .Ltmp202-.Ltmp201              #   Call between .Ltmp201 and .Ltmp202
	.uleb128 .Ltmp203-.Lfunc_begin10        #     jumps to .Ltmp203
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp202-.Lfunc_begin10        # >> Call Site 3 <<
	.uleb128 .Lfunc_end29-.Ltmp202          #   Call between .Ltmp202 and .Lfunc_end29
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end10:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE0_EEDaSG_EUlSK_E_E4callEPKvSK_
	.prefalign	4, .Lfunc_end30, nop
	.type	_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE0_EEDaSG_EUlSK_E_E4callEPKvSK_,@function
_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE0_EEDaSG_EUlSK_E_E4callEPKvSK_: # 
.Lfunc_begin11:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception11
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$392, %rsp                      # imm = 0x188
	.cfi_def_cfa_offset 448
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rsi, %rbx
	movq	%rdi, %r14
	movq	(%rdi), %rax
	movups	(%rax), %xmm0
	movq	8(%rax), %rax
	movups	%xmm0, 64(%rsp)                 # AlignMOV convert to UnAlignMOV 
	testq	%rax, %rax
	je	.LBB30_5
# %bb.1:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB30_3
# %bb.2:
	movl	8(%rax), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%rax)
	cmpl	$-1, %ecx
	jne	.LBB30_5
	jmp	.LBB30_66
.LBB30_3:
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%rax)
	cmpl	$-1, %ecx
	je	.LBB30_66
.LBB30_5:
.Ltmp204:                               # EH_LABEL
	leaq	64(%rsp), %rsi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler10depends_onENS0_5eventE
.Ltmp205:                               # EH_LABEL
# %bb.6:
	movq	72(%rsp), %r15
	testq	%r15, %r15
	je	.LBB30_14
# %bb.7:
	movq	8(%r15), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB30_9
# %bb.8:
	movq	$0, 8(%r15)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*16(%rax)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*24(%rax)
	jmp	.LBB30_14
.LBB30_9:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB30_11
# %bb.10:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$1, %eax
	je	.LBB30_13
.LBB30_14:
	movq	8(%r14), %r12
	movq	$.L.str, 104(%rsp)
	movq	$.L.str.3, 112(%rsp)
	movabsq	$188978561328, %rax             # imm = 0x2C00000130
	movq	%rax, 120(%rsp)
	movq	120(%rsp), %rax
	movq	%rax, 16(%rsp)
	movups	104(%rsp), %xmm0
	movups	%xmm0, (%rsp)
	leaq	128(%rsp), %rdi
	movl	$256, %esi                      # imm = 0x100
	movq	%rbx, %rdx
	callq	_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE
	movq	(%r12), %rax
	movq	8(%r12), %rcx
	movslq	(%rax), %r13
	movslq	(%rcx), %r15
	movq	16(%r12), %rax
	movq	24(%r12), %rcx
	movq	(%rax), %rbp
	movq	(%rcx), %rax
	movq	%rax, 96(%rsp)                  # 8-byte Spill
	movq	32(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 60(%rsp)                  # 4-byte Spill
	movq	40(%r12), %rax
	movzbl	(%rax), %eax
	movb	%al, 47(%rsp)                   # 1-byte Spill
	movq	48(%r12), %rax
	movq	(%rax), %rax
	movq	%rax, 88(%rsp)                  # 8-byte Spill
	movq	56(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 56(%rsp)                  # 4-byte Spill
	movups	128(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 352(%rsp)                # 16-byte Spill
                                        # AlignMOV convert to UnAlignMOV 
	movq	136(%rsp), %r14
	testq	%r14, %r14
	je	.LBB30_19
# %bb.15:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB30_17
# %bb.16:
	movl	8(%r14), %eax
	leal	1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$-1, %eax
	jne	.LBB30_19
	jmp	.LBB30_66
.LBB30_17:
	movl	$1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$-1, %eax
	je	.LBB30_66
.LBB30_19:
	movups	144(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 368(%rsp)                # AlignMOV convert to UnAlignMOV 
	movq	64(%r12), %rax
	movq	72(%r12), %rcx
	movl	(%rax), %eax
	movl	%eax, 52(%rsp)                  # 4-byte Spill
	movss	(%rcx), %xmm0                   # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 48(%rsp)                 # 4-byte Spill
	movq	80(%r12), %rax
	movq	(%rax), %r12
.Ltmp207:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZNK4sycl3_V17handler7getTypeEv
.Ltmp208:                               # EH_LABEL
# %bb.20:
	testl	%eax, %eax
	jne	.LBB30_21
# %bb.24:
.Ltmp214:                               # EH_LABEL
	movl	$.L.str.13, %esi
	movl	$134, %edx
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler30verifyUsedKernelBundleInternalENS0_6detail11string_viewE
.Ltmp215:                               # EH_LABEL
# %bb.25:
	shlq	$7, %r13
	movq	%r13, 200(%rsp)
	movq	%r15, 208(%rsp)
	leaq	216(%rsp), %rax
	movq	$128, 216(%rsp)
	movq	$1, 224(%rsp)
	leaq	232(%rsp), %rcx
	xorps	%xmm0, %xmm0
	movups	%xmm0, 232(%rsp)
	leaq	200(%rsp), %rdx
	movq	%rdx, 168(%rsp)
	movq	%rax, 176(%rsp)
	movq	%rcx, 184(%rsp)
	movq	$2, 192(%rsp)
.Ltmp216:                               # EH_LABEL
	movups	168(%rsp), %xmm0
	movups	184(%rsp), %xmm1
	movups	%xmm1, 16(%rsp)
	movups	%xmm0, (%rsp)
	movq	%rbx, %rdi
	xorl	%esi, %esi
	callq	_ZN4sycl3_V17handler20setNDRangeDescriptorENS0_6detail16nd_range_view_v113nd_range_viewEb
.Ltmp217:                               # EH_LABEL
# %bb.26:
.Ltmp218:                               # EH_LABEL
	movl	$96, %edi
	callq	_Znwm
.Ltmp219:                               # EH_LABEL
# %bb.27:
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rax)
	movq	%rbp, 8(%rax)
	movq	96(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 16(%rax)
	movl	60(%rsp), %ecx                  # 4-byte Reload
	movl	%ecx, 24(%rax)
	movzbl	47(%rsp), %ecx                  # 1-byte Folded Reload
	movb	%cl, 28(%rax)
	movq	88(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 32(%rax)
	movl	56(%rsp), %ecx                  # 4-byte Reload
	movl	%ecx, 40(%rax)
	movups	352(%rsp), %xmm0                # 16-byte Reload
                                        # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 48(%rax)
	testq	%r14, %r14
	je	.LBB30_32
# %bb.28:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB30_30
# %bb.29:
	movl	8(%r14), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%r14)
	cmpl	$-1, %ecx
	je	.LBB30_66
.LBB30_32:
	movups	368(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 64(%rax)
	movl	52(%rsp), %ecx                  # 4-byte Reload
	movl	%ecx, 80(%rax)
	movss	48(%rsp), %xmm0                 # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 84(%rax)
	movq	%r12, 88(%rax)
	movq	144(%rbx), %rdi
	movq	%rax, 144(%rbx)
	testq	%rdi, %rdi
	je	.LBB30_34
# %bb.33:
	movq	(%rdi), %rax
	callq	*16(%rax)
.LBB30_34:
.Ltmp220:                               # EH_LABEL
	movl	$_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE, %esi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler23instantiateKernelOnHostEPv
.Ltmp221:                               # EH_LABEL
# %bb.35:
	movq	144(%rbx), %rdi
	movq	(%rdi), %rax
.Ltmp222:                               # EH_LABEL
	callq	*(%rax)
.Ltmp223:                               # EH_LABEL
# %bb.36:
	movq	$.L.str.13, 64(%rbx)
	movq	$134, 72(%rbx)
.Ltmp224:                               # EH_LABEL
	movq	%rbx, %rdi
	movq	%rax, %rsi
	callq	_ZN4sycl3_V17handler13setKernelFuncEPv
.Ltmp225:                               # EH_LABEL
# %bb.37:
	movzbl	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip), %eax
	testb	%al, %al
	je	.LBB30_38
.LBB30_41:
	movq	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip), %rsi
.Ltmp229:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler22setDeviceKernelInfoPtrEPNS0_6detail16DeviceKernelInfoE
.Ltmp230:                               # EH_LABEL
# %bb.42:
.Ltmp231:                               # EH_LABEL
	movq	%rbx, %rdi
	movl	$1, %esi
	callq	_ZN4sycl3_V17handler7setTypeENS0_6detail6CGTypeE
.Ltmp232:                               # EH_LABEL
# %bb.43:
	movb	$0, 208(%rsp)
	movb	$0, 218(%rsp)
	movb	$0, 220(%rsp)
	movb	$0, 228(%rsp)
	movb	$0, 236(%rsp)
	movb	$0, 244(%rsp)
	movb	$0, 252(%rsp)
	movb	$0, 260(%rsp)
	movb	$0, 268(%rsp)
	movb	$0, 280(%rsp)
	movb	$0, 304(%rsp)
	movb	$0, 336(%rsp)
	movb	$1, 344(%rsp)
.Ltmp233:                               # EH_LABEL
	leaq	200(%rsp), %rsi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler25setKernelLaunchPropertiesERKNS0_6detail27kernel_launch_properties_v111PropsHolderIJNS0_3ext6oneapi12experimental23work_group_scratch_sizeENS5_5intel12experimental12cache_configENS7_17use_root_sync_keyENS7_23work_group_progress_keyENS7_22sub_group_progress_keyENS7_22work_item_progress_keyENS7_4cuda12cluster_sizeILi1EEENSH_ILi2EEENSH_ILi3EEEEEE
.Ltmp234:                               # EH_LABEL
# %bb.44:
	testq	%r14, %r14
	je	.LBB30_52
# %bb.45:
	movq	8(%r14), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB30_47
# %bb.46:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	jmp	.LBB30_52
.LBB30_47:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB30_49
# %bb.48:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	je	.LBB30_51
.LBB30_52:
	movq	136(%rsp), %rbx
	testq	%rbx, %rbx
	je	.LBB30_60
# %bb.53:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB30_55
# %bb.54:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
	jmp	.LBB30_60
.LBB30_55:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB30_57
# %bb.56:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB30_59
.LBB30_60:
	addq	$392, %rsp                      # imm = 0x188
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB30_30:
	.cfi_def_cfa_offset 448
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%r14)
	cmpl	$-1, %ecx
	jne	.LBB30_32
.LBB30_66:
	ud2
.LBB30_11:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB30_14
.LBB30_13:
	movq	%r15, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB30_14
.LBB30_49:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB30_52
.LBB30_51:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB30_52
.LBB30_57:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB30_60
.LBB30_59:
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB30_60
.LBB30_21:
	movl	$64, %edi
	callq	__cxa_allocate_exception
	movq	%rax, %r15
	movl	$1, %edi
	callq	_ZN4sycl3_V115make_error_codeENS0_4errcE
.Ltmp209:                               # EH_LABEL
	movl	$.L.str.7, %ecx
	movq	%r15, %rdi
	movl	%eax, %esi
	callq	_ZN4sycl3_V19exceptionC1ESt10error_codePKc
.Ltmp210:                               # EH_LABEL
# %bb.22:
.Ltmp212:                               # EH_LABEL
	movl	$_ZTIN4sycl3_V19exceptionE, %esi
	movl	$_ZN4sycl3_V19exceptionD1Ev, %edx
	movq	%r15, %rdi
	callq	__cxa_throw
.Ltmp213:                               # EH_LABEL
# %bb.23:
.LBB30_38:
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_acquire
	testl	%eax, %eax
	je	.LBB30_41
# %bb.39:
.Ltmp226:                               # EH_LABEL
	movl	$_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESG_EUlNS0_7nd_itemILi2EEEE_EE, %edi
	callq	_ZN4sycl3_V16detail19getDeviceKernelInfoERKNS1_27compile_time_kernel_info_v123CompileTimeKernelInfoTyE
.Ltmp227:                               # EH_LABEL
# %bb.40:
	movq	%rax, _ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip)
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_release
	jmp	.LBB30_41
.LBB30_67:
.Ltmp228:                               # EH_LABEL
	movq	%rax, %rbx
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_abort
	jmp	.LBB30_63
.LBB30_62:
.Ltmp211:                               # EH_LABEL
	movq	%rax, %rbx
	movq	%r15, %rdi
	callq	__cxa_free_exception
	jmp	.LBB30_63
.LBB30_64:
.Ltmp206:                               # EH_LABEL
	movq	%rax, %rbx
	leaq	64(%rsp), %rdi
	callq	_ZN4sycl3_V15eventD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.LBB30_61:
.Ltmp235:                               # EH_LABEL
	movq	%rax, %rbx
.LBB30_63:
	movq	%r14, %rdi
	callq	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE0_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	leaq	128(%rsp), %rdi
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end30:
	.size	_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE0_EEDaSG_EUlSK_E_E4callEPKvSK_, .Lfunc_end30-_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE0_EEDaSG_EUlSK_E_E4callEPKvSK_
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table30:
.Lexception11:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end11-.Lcst_begin11
.Lcst_begin11:
	.uleb128 .Ltmp204-.Lfunc_begin11        # >> Call Site 1 <<
	.uleb128 .Ltmp205-.Ltmp204              #   Call between .Ltmp204 and .Ltmp205
	.uleb128 .Ltmp206-.Lfunc_begin11        #     jumps to .Ltmp206
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp205-.Lfunc_begin11        # >> Call Site 2 <<
	.uleb128 .Ltmp207-.Ltmp205              #   Call between .Ltmp205 and .Ltmp207
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp207-.Lfunc_begin11        # >> Call Site 3 <<
	.uleb128 .Ltmp219-.Ltmp207              #   Call between .Ltmp207 and .Ltmp219
	.uleb128 .Ltmp235-.Lfunc_begin11        #     jumps to .Ltmp235
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp219-.Lfunc_begin11        # >> Call Site 4 <<
	.uleb128 .Ltmp220-.Ltmp219              #   Call between .Ltmp219 and .Ltmp220
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp220-.Lfunc_begin11        # >> Call Site 5 <<
	.uleb128 .Ltmp234-.Ltmp220              #   Call between .Ltmp220 and .Ltmp234
	.uleb128 .Ltmp235-.Lfunc_begin11        #     jumps to .Ltmp235
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp234-.Lfunc_begin11        # >> Call Site 6 <<
	.uleb128 .Ltmp209-.Ltmp234              #   Call between .Ltmp234 and .Ltmp209
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp209-.Lfunc_begin11        # >> Call Site 7 <<
	.uleb128 .Ltmp210-.Ltmp209              #   Call between .Ltmp209 and .Ltmp210
	.uleb128 .Ltmp211-.Lfunc_begin11        #     jumps to .Ltmp211
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp212-.Lfunc_begin11        # >> Call Site 8 <<
	.uleb128 .Ltmp213-.Ltmp212              #   Call between .Ltmp212 and .Ltmp213
	.uleb128 .Ltmp235-.Lfunc_begin11        #     jumps to .Ltmp235
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp226-.Lfunc_begin11        # >> Call Site 9 <<
	.uleb128 .Ltmp227-.Ltmp226              #   Call between .Ltmp226 and .Ltmp227
	.uleb128 .Ltmp228-.Lfunc_begin11        #     jumps to .Ltmp228
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp227-.Lfunc_begin11        # >> Call Site 10 <<
	.uleb128 .Lfunc_end30-.Ltmp227          #   Call between .Ltmp227 and .Lfunc_end30
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end11:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE0_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	.prefalign	4, .Lfunc_end31, nop
	.type	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE0_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev,@function
_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE0_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	testq	%rdi, %rdi
	je	.LBB31_6
# %bb.1:
	movq	8(%rdi), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB31_2
# %bb.7:
	movq	$0, 8(%rdi)
	movq	(%rdi), %rax
	movq	%rdi, %rbx
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB31_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB31_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rdi)
	cmpl	$1, %eax
	je	.LBB31_8
.LBB31_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB31_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rdi)
	cmpl	$1, %eax
	jne	.LBB31_6
.LBB31_8:
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end31:
	.size	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE0_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev, .Lfunc_end31-_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE0_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	.cfi_endproc
                                        # -- End function
	.prefalign	4, .Lfunc_end32, nop    # -- Begin function _ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.type	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi,@function
_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi: # 
	.cfi_startproc
# %bb.0:
                                        # kill: def $edi killed $edi def $rdi
	addl	$30, %edi
	shlq	$2, %rdi
	movq	_ZN4sycl3_V16detailL17kernel_signaturesE(%rdi,%rdi,2), %rax
	movl	_ZN4sycl3_V16detailL17kernel_signaturesE+8(%rdi,%rdi,2), %edx
	retq
.Lfunc_end32:
	.size	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi, .Lfunc_end32-_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.prefalign	4, .Lfunc_end33, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv: # 
	.cfi_startproc
# %bb.0:
	leaq	8(%rdi), %rax
	retq
.Lfunc_end33:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv, .Lfunc_end33-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.prefalign	4, .Lfunc_end34, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rdi)
	movq	56(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB34_6
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB34_2
# %bb.7:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB34_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB34_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB34_8
.LBB34_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB34_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB34_6
.LBB34_8:
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end34:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev, .Lfunc_end34-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.prefalign	4, .Lfunc_end35, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%r14
	.cfi_def_cfa_offset 16
	pushq	%rbx
	.cfi_def_cfa_offset 24
	pushq	%rax
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -24
	.cfi_offset %r14, -16
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rdi)
	movq	56(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB35_9
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB35_3
# %bb.2:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rdi, %r14
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
.LBB35_8:
	movq	%r14, %rdi
	jmp	.LBB35_9
.LBB35_3:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB35_5
# %bb.4:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB35_7
.LBB35_9:
	movl	$96, %esi
	addq	$8, %rsp
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	jmp	_ZdlPvm                         # TAILCALL
.LBB35_5:
	.cfi_def_cfa_offset 32
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB35_9
.LBB35_7:
	movq	%rdi, %r14
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB35_8
.Lfunc_end35:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev, .Lfunc_end35-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.cfi_endproc
                                        # -- End function
	.prefalign	4, .Lfunc_end36, nop    # -- Begin function _ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE
	.type	_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE,@function
_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE: # 
.Lfunc_begin12:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception12
# %bb.0:
	pushq	%r15
	.cfi_def_cfa_offset 16
	pushq	%r14
	.cfi_def_cfa_offset 24
	pushq	%rbx
	.cfi_def_cfa_offset 32
	subq	$16, %rsp
	.cfi_def_cfa_offset 48
	.cfi_offset %rbx, -32
	.cfi_offset %r14, -24
	.cfi_offset %r15, -16
	movq	(%rdi), %rax
	cmpl	$0, 4(%rax)
	jg	.LBB36_1
# %bb.8:
	addq	$16, %rsp
	.cfi_def_cfa_offset 32
	popq	%rbx
	.cfi_def_cfa_offset 24
	popq	%r14
	.cfi_def_cfa_offset 16
	popq	%r15
	.cfi_def_cfa_offset 8
	retq
.LBB36_1:
	.cfi_def_cfa_offset 48
	movzbl	20(%rdi), %eax
	movq	24(%rdi), %r14
	movslq	32(%rdi), %r15
	imulq	%rax, %r15
	shlq	$2, %r15
	addq	$40, %rdi
	testb	%al, %al
	jne	.LBB36_2
# %bb.5:
	movss	(%r14,%r15,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 12(%rsp)                 # 4-byte Spill
	callq	_ZNK4sycl3_V16detail21LocalAccessorBaseHost6getPtrEv
	movss	12(%rsp), %xmm0                 # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%rax)
.Ltmp239:                               # EH_LABEL
	movl	$.L.str.8, %edi
	callq	_ZN4sycl3_V16detail24cannot_be_called_on_hostEPKc
.Ltmp240:                               # EH_LABEL
# %bb.6:
.LBB36_2:
	movss	(%r14), %xmm0                   # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 12(%rsp)                 # 4-byte Spill
	movq	%rdi, %rbx
	callq	_ZNK4sycl3_V16detail21LocalAccessorBaseHost6getPtrEv
	movss	12(%rsp), %xmm0                 # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%rax)
	movss	(%r14,%r15,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 12(%rsp)                 # 4-byte Spill
	movq	%rbx, %rdi
	callq	_ZNK4sycl3_V16detail21LocalAccessorBaseHost6getPtrEv
	movss	12(%rsp), %xmm0                 # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 512(%rax)
.Ltmp236:                               # EH_LABEL
	movl	$.L.str.8, %edi
	callq	_ZN4sycl3_V16detail24cannot_be_called_on_hostEPKc
.Ltmp237:                               # EH_LABEL
# %bb.3:
.LBB36_4:
.Ltmp238:                               # EH_LABEL
	movq	%rax, %rdi
	callq	__clang_call_terminate
.LBB36_7:
.Ltmp241:                               # EH_LABEL
	movq	%rax, %rdi
	callq	__clang_call_terminate
.Lfunc_end36:
	.size	_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE, .Lfunc_end36-_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table36:
.Lexception12:
	.byte	255                             # @LPStart Encoding = omit
	.byte	3                               # @TType Encoding = udata4
	.uleb128 .Lttbase2-.Lttbaseref2
.Lttbaseref2:
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end12-.Lcst_begin12
.Lcst_begin12:
	.uleb128 .Lfunc_begin12-.Lfunc_begin12  # >> Call Site 1 <<
	.uleb128 .Ltmp239-.Lfunc_begin12        #   Call between .Lfunc_begin12 and .Ltmp239
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp239-.Lfunc_begin12        # >> Call Site 2 <<
	.uleb128 .Ltmp240-.Ltmp239              #   Call between .Ltmp239 and .Ltmp240
	.uleb128 .Ltmp241-.Lfunc_begin12        #     jumps to .Ltmp241
	.byte	1                               #   On action: 1
	.uleb128 .Ltmp240-.Lfunc_begin12        # >> Call Site 3 <<
	.uleb128 .Ltmp236-.Ltmp240              #   Call between .Ltmp240 and .Ltmp236
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp236-.Lfunc_begin12        # >> Call Site 4 <<
	.uleb128 .Ltmp237-.Ltmp236              #   Call between .Ltmp236 and .Ltmp237
	.uleb128 .Ltmp238-.Lfunc_begin12        #     jumps to .Ltmp238
	.byte	1                               #   On action: 1
.Lcst_end12:
	.byte	1                               # >> Action Record 1 <<
                                        #   Catch TypeInfo 1
	.byte	0                               #   No further actions
	.p2align	2, 0x0
                                        # >> Catch TypeInfos <<
	.long	0                               # TypeInfo 1
.Lttbase2:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE1_EEDaSG_EUlSK_E_E4callEPKvSK_
	.prefalign	4, .Lfunc_end37, nop
	.type	_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE1_EEDaSG_EUlSK_E_E4callEPKvSK_,@function
_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE1_EEDaSG_EUlSK_E_E4callEPKvSK_: # 
.Lfunc_begin13:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception13
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$376, %rsp                      # imm = 0x178
	.cfi_def_cfa_offset 432
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rsi, %rbx
	movq	%rdi, %r14
	movq	(%rdi), %rax
	movups	(%rax), %xmm0
	movq	8(%rax), %rax
	movups	%xmm0, 48(%rsp)                 # AlignMOV convert to UnAlignMOV 
	testq	%rax, %rax
	je	.LBB37_5
# %bb.1:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB37_3
# %bb.2:
	movl	8(%rax), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%rax)
	cmpl	$-1, %ecx
	jne	.LBB37_5
	jmp	.LBB37_66
.LBB37_3:
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%rax)
	cmpl	$-1, %ecx
	je	.LBB37_66
.LBB37_5:
.Ltmp242:                               # EH_LABEL
	leaq	48(%rsp), %rsi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler10depends_onENS0_5eventE
.Ltmp243:                               # EH_LABEL
# %bb.6:
	movq	56(%rsp), %r15
	testq	%r15, %r15
	je	.LBB37_14
# %bb.7:
	movq	8(%r15), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB37_9
# %bb.8:
	movq	$0, 8(%r15)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*16(%rax)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*24(%rax)
	jmp	.LBB37_14
.LBB37_9:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB37_11
# %bb.10:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$1, %eax
	je	.LBB37_13
.LBB37_14:
	movq	8(%r14), %r13
	movq	$.L.str, 88(%rsp)
	movq	$.L.str.3, 96(%rsp)
	movabsq	$188978561394, %rax             # imm = 0x2C00000172
	movq	%rax, 104(%rsp)
	movq	104(%rsp), %rax
	movq	%rax, 16(%rsp)
	movups	88(%rsp), %xmm0
	movups	%xmm0, (%rsp)
	leaq	112(%rsp), %rdi
	movl	$128, %esi
	movq	%rbx, %rdx
	callq	_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE
	movq	(%r13), %rax
	movq	8(%r13), %rcx
	movslq	(%rax), %r15
	movslq	(%rcx), %rbp
	movq	16(%r13), %rax
	movq	24(%r13), %rcx
	movq	(%rax), %r12
	movq	(%rcx), %rax
	movq	%rax, 80(%rsp)                  # 8-byte Spill
	movq	32(%r13), %rax
	movl	(%rax), %eax
	movl	%eax, 44(%rsp)                  # 4-byte Spill
	movups	112(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 336(%rsp)                # 16-byte Spill
                                        # AlignMOV convert to UnAlignMOV 
	movq	120(%rsp), %r14
	testq	%r14, %r14
	je	.LBB37_19
# %bb.15:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB37_17
# %bb.16:
	movl	8(%r14), %eax
	leal	1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$-1, %eax
	jne	.LBB37_19
	jmp	.LBB37_66
.LBB37_17:
	movl	$1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$-1, %eax
	je	.LBB37_66
.LBB37_19:
	movups	128(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 352(%rsp)                # AlignMOV convert to UnAlignMOV 
	movq	40(%r13), %rax
	movq	48(%r13), %rcx
	movq	(%rax), %rax
	movq	%rax, 72(%rsp)                  # 8-byte Spill
	movl	(%rcx), %eax
	movl	%eax, 40(%rsp)                  # 4-byte Spill
	movq	56(%r13), %rax
	movq	(%rax), %r13
.Ltmp245:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZNK4sycl3_V17handler7getTypeEv
.Ltmp246:                               # EH_LABEL
# %bb.20:
	testl	%eax, %eax
	jne	.LBB37_21
# %bb.24:
.Ltmp252:                               # EH_LABEL
	movl	$.L.str.15, %esi
	movl	$134, %edx
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler30verifyUsedKernelBundleInternalENS0_6detail11string_viewE
.Ltmp253:                               # EH_LABEL
# %bb.25:
	shlq	$7, %r15
	movq	%r15, 184(%rsp)
	movq	%rbp, 192(%rsp)
	leaq	200(%rsp), %rax
	movq	$128, 200(%rsp)
	movq	$1, 208(%rsp)
	leaq	216(%rsp), %rcx
	xorps	%xmm0, %xmm0
	movups	%xmm0, 216(%rsp)
	leaq	184(%rsp), %rdx
	movq	%rdx, 152(%rsp)
	movq	%rax, 160(%rsp)
	movq	%rcx, 168(%rsp)
	movq	$2, 176(%rsp)
.Ltmp254:                               # EH_LABEL
	movups	152(%rsp), %xmm0
	movups	168(%rsp), %xmm1
	movups	%xmm1, 16(%rsp)
	movups	%xmm0, (%rsp)
	movq	%rbx, %rdi
	xorl	%esi, %esi
	callq	_ZN4sycl3_V17handler20setNDRangeDescriptorENS0_6detail16nd_range_view_v113nd_range_viewEb
.Ltmp255:                               # EH_LABEL
# %bb.26:
.Ltmp256:                               # EH_LABEL
	movl	$88, %edi
	callq	_Znwm
.Ltmp257:                               # EH_LABEL
# %bb.27:
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rax)
	movq	%r12, 8(%rax)
	movq	80(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 16(%rax)
	movl	44(%rsp), %ecx                  # 4-byte Reload
	movl	%ecx, 24(%rax)
	movups	336(%rsp), %xmm0                # 16-byte Reload
                                        # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 32(%rax)
	testq	%r14, %r14
	je	.LBB37_32
# %bb.28:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB37_30
# %bb.29:
	movl	8(%r14), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%r14)
	cmpl	$-1, %ecx
	je	.LBB37_66
.LBB37_32:
	movups	352(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 48(%rax)
	movq	72(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 64(%rax)
	movl	40(%rsp), %ecx                  # 4-byte Reload
	movl	%ecx, 72(%rax)
	movq	%r13, 80(%rax)
	movq	144(%rbx), %rdi
	movq	%rax, 144(%rbx)
	testq	%rdi, %rdi
	je	.LBB37_34
# %bb.33:
	movq	(%rdi), %rax
	callq	*16(%rax)
.LBB37_34:
.Ltmp258:                               # EH_LABEL
	movl	$_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE, %esi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler23instantiateKernelOnHostEPv
.Ltmp259:                               # EH_LABEL
# %bb.35:
	movq	144(%rbx), %rdi
	movq	(%rdi), %rax
.Ltmp260:                               # EH_LABEL
	callq	*(%rax)
.Ltmp261:                               # EH_LABEL
# %bb.36:
	movq	$.L.str.15, 64(%rbx)
	movq	$134, 72(%rbx)
.Ltmp262:                               # EH_LABEL
	movq	%rbx, %rdi
	movq	%rax, %rsi
	callq	_ZN4sycl3_V17handler13setKernelFuncEPv
.Ltmp263:                               # EH_LABEL
# %bb.37:
	movzbl	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip), %eax
	testb	%al, %al
	je	.LBB37_38
.LBB37_41:
	movq	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip), %rsi
.Ltmp267:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler22setDeviceKernelInfoPtrEPNS0_6detail16DeviceKernelInfoE
.Ltmp268:                               # EH_LABEL
# %bb.42:
.Ltmp269:                               # EH_LABEL
	movq	%rbx, %rdi
	movl	$1, %esi
	callq	_ZN4sycl3_V17handler7setTypeENS0_6detail6CGTypeE
.Ltmp270:                               # EH_LABEL
# %bb.43:
	movb	$0, 192(%rsp)
	movb	$0, 202(%rsp)
	movb	$0, 204(%rsp)
	movb	$0, 212(%rsp)
	movb	$0, 220(%rsp)
	movb	$0, 228(%rsp)
	movb	$0, 236(%rsp)
	movb	$0, 244(%rsp)
	movb	$0, 252(%rsp)
	movb	$0, 264(%rsp)
	movb	$0, 288(%rsp)
	movb	$0, 320(%rsp)
	movb	$1, 328(%rsp)
.Ltmp271:                               # EH_LABEL
	leaq	184(%rsp), %rsi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler25setKernelLaunchPropertiesERKNS0_6detail27kernel_launch_properties_v111PropsHolderIJNS0_3ext6oneapi12experimental23work_group_scratch_sizeENS5_5intel12experimental12cache_configENS7_17use_root_sync_keyENS7_23work_group_progress_keyENS7_22sub_group_progress_keyENS7_22work_item_progress_keyENS7_4cuda12cluster_sizeILi1EEENSH_ILi2EEENSH_ILi3EEEEEE
.Ltmp272:                               # EH_LABEL
# %bb.44:
	testq	%r14, %r14
	je	.LBB37_52
# %bb.45:
	movq	8(%r14), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB37_47
# %bb.46:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	jmp	.LBB37_52
.LBB37_47:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB37_49
# %bb.48:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	je	.LBB37_51
.LBB37_52:
	movq	120(%rsp), %rbx
	testq	%rbx, %rbx
	je	.LBB37_60
# %bb.53:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB37_55
# %bb.54:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
	jmp	.LBB37_60
.LBB37_55:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB37_57
# %bb.56:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB37_59
.LBB37_60:
	addq	$376, %rsp                      # imm = 0x178
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB37_30:
	.cfi_def_cfa_offset 432
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%r14)
	cmpl	$-1, %ecx
	jne	.LBB37_32
.LBB37_66:
	ud2
.LBB37_11:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB37_14
.LBB37_13:
	movq	%r15, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB37_14
.LBB37_49:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB37_52
.LBB37_51:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB37_52
.LBB37_57:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB37_60
.LBB37_59:
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB37_60
.LBB37_21:
	movl	$64, %edi
	callq	__cxa_allocate_exception
	movq	%rax, %r15
	movl	$1, %edi
	callq	_ZN4sycl3_V115make_error_codeENS0_4errcE
.Ltmp247:                               # EH_LABEL
	movl	$.L.str.7, %ecx
	movq	%r15, %rdi
	movl	%eax, %esi
	callq	_ZN4sycl3_V19exceptionC1ESt10error_codePKc
.Ltmp248:                               # EH_LABEL
# %bb.22:
.Ltmp250:                               # EH_LABEL
	movl	$_ZTIN4sycl3_V19exceptionE, %esi
	movl	$_ZN4sycl3_V19exceptionD1Ev, %edx
	movq	%r15, %rdi
	callq	__cxa_throw
.Ltmp251:                               # EH_LABEL
# %bb.23:
.LBB37_38:
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_acquire
	testl	%eax, %eax
	je	.LBB37_41
# %bb.39:
.Ltmp264:                               # EH_LABEL
	movl	$_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESG_EUlNS0_7nd_itemILi2EEEE_EE, %edi
	callq	_ZN4sycl3_V16detail19getDeviceKernelInfoERKNS1_27compile_time_kernel_info_v123CompileTimeKernelInfoTyE
.Ltmp265:                               # EH_LABEL
# %bb.40:
	movq	%rax, _ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip)
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_release
	jmp	.LBB37_41
.LBB37_67:
.Ltmp266:                               # EH_LABEL
	movq	%rax, %rbx
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_abort
	jmp	.LBB37_63
.LBB37_62:
.Ltmp249:                               # EH_LABEL
	movq	%rax, %rbx
	movq	%r15, %rdi
	callq	__cxa_free_exception
	jmp	.LBB37_63
.LBB37_64:
.Ltmp244:                               # EH_LABEL
	movq	%rax, %rbx
	leaq	48(%rsp), %rdi
	callq	_ZN4sycl3_V15eventD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.LBB37_61:
.Ltmp273:                               # EH_LABEL
	movq	%rax, %rbx
.LBB37_63:
	movq	%r14, %rdi
	callq	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE1_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	leaq	112(%rsp), %rdi
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end37:
	.size	_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE1_EEDaSG_EUlSK_E_E4callEPKvSK_, .Lfunc_end37-_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE1_EEDaSG_EUlSK_E_E4callEPKvSK_
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table37:
.Lexception13:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end13-.Lcst_begin13
.Lcst_begin13:
	.uleb128 .Ltmp242-.Lfunc_begin13        # >> Call Site 1 <<
	.uleb128 .Ltmp243-.Ltmp242              #   Call between .Ltmp242 and .Ltmp243
	.uleb128 .Ltmp244-.Lfunc_begin13        #     jumps to .Ltmp244
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp243-.Lfunc_begin13        # >> Call Site 2 <<
	.uleb128 .Ltmp245-.Ltmp243              #   Call between .Ltmp243 and .Ltmp245
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp245-.Lfunc_begin13        # >> Call Site 3 <<
	.uleb128 .Ltmp257-.Ltmp245              #   Call between .Ltmp245 and .Ltmp257
	.uleb128 .Ltmp273-.Lfunc_begin13        #     jumps to .Ltmp273
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp257-.Lfunc_begin13        # >> Call Site 4 <<
	.uleb128 .Ltmp258-.Ltmp257              #   Call between .Ltmp257 and .Ltmp258
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp258-.Lfunc_begin13        # >> Call Site 5 <<
	.uleb128 .Ltmp272-.Ltmp258              #   Call between .Ltmp258 and .Ltmp272
	.uleb128 .Ltmp273-.Lfunc_begin13        #     jumps to .Ltmp273
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp272-.Lfunc_begin13        # >> Call Site 6 <<
	.uleb128 .Ltmp247-.Ltmp272              #   Call between .Ltmp272 and .Ltmp247
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp247-.Lfunc_begin13        # >> Call Site 7 <<
	.uleb128 .Ltmp248-.Ltmp247              #   Call between .Ltmp247 and .Ltmp248
	.uleb128 .Ltmp249-.Lfunc_begin13        #     jumps to .Ltmp249
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp250-.Lfunc_begin13        # >> Call Site 8 <<
	.uleb128 .Ltmp251-.Ltmp250              #   Call between .Ltmp250 and .Ltmp251
	.uleb128 .Ltmp273-.Lfunc_begin13        #     jumps to .Ltmp273
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp264-.Lfunc_begin13        # >> Call Site 9 <<
	.uleb128 .Ltmp265-.Ltmp264              #   Call between .Ltmp264 and .Ltmp265
	.uleb128 .Ltmp266-.Lfunc_begin13        #     jumps to .Ltmp266
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp265-.Lfunc_begin13        # >> Call Site 10 <<
	.uleb128 .Lfunc_end37-.Ltmp265          #   Call between .Ltmp265 and .Lfunc_end37
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end13:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE1_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	.prefalign	4, .Lfunc_end38, nop
	.type	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE1_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev,@function
_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE1_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	testq	%rdi, %rdi
	je	.LBB38_6
# %bb.1:
	movq	8(%rdi), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB38_2
# %bb.7:
	movq	$0, 8(%rdi)
	movq	(%rdi), %rax
	movq	%rdi, %rbx
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB38_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB38_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rdi)
	cmpl	$1, %eax
	je	.LBB38_8
.LBB38_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB38_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rdi)
	cmpl	$1, %eax
	jne	.LBB38_6
.LBB38_8:
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end38:
	.size	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE1_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev, .Lfunc_end38-_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE1_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	.cfi_endproc
                                        # -- End function
	.prefalign	4, .Lfunc_end39, nop    # -- Begin function _ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.type	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi,@function
_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi: # 
	.cfi_startproc
# %bb.0:
                                        # kill: def $edi killed $edi def $rdi
	addl	$40, %edi
	shlq	$2, %rdi
	movq	_ZN4sycl3_V16detailL17kernel_signaturesE(%rdi,%rdi,2), %rax
	movl	_ZN4sycl3_V16detailL17kernel_signaturesE+8(%rdi,%rdi,2), %edx
	retq
.Lfunc_end39:
	.size	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi, .Lfunc_end39-_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.prefalign	4, .Lfunc_end40, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv: # 
	.cfi_startproc
# %bb.0:
	leaq	8(%rdi), %rax
	retq
.Lfunc_end40:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv, .Lfunc_end40-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.prefalign	4, .Lfunc_end41, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rdi)
	movq	40(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB41_6
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB41_2
# %bb.7:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB41_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB41_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB41_8
.LBB41_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB41_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB41_6
.LBB41_8:
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end41:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev, .Lfunc_end41-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.prefalign	4, .Lfunc_end42, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%r14
	.cfi_def_cfa_offset 16
	pushq	%rbx
	.cfi_def_cfa_offset 24
	pushq	%rax
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -24
	.cfi_offset %r14, -16
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rdi)
	movq	40(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB42_9
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB42_3
# %bb.2:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rdi, %r14
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
.LBB42_8:
	movq	%r14, %rdi
	jmp	.LBB42_9
.LBB42_3:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB42_5
# %bb.4:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB42_7
.LBB42_9:
	movl	$88, %esi
	addq	$8, %rsp
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	jmp	_ZdlPvm                         # TAILCALL
.LBB42_5:
	.cfi_def_cfa_offset 32
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB42_9
.LBB42_7:
	movq	%rdi, %r14
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB42_8
.Lfunc_end42:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev, .Lfunc_end42-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.cfi_endproc
                                        # -- End function
	.prefalign	4, .Lfunc_end43, nop    # -- Begin function _ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE
	.type	_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE,@function
_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE: # 
.Lfunc_begin14:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception14
# %bb.0:
	pushq	%r14
	.cfi_def_cfa_offset 16
	pushq	%rbx
	.cfi_def_cfa_offset 24
	pushq	%rax
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -24
	.cfi_offset %r14, -16
	movq	(%rdi), %rax
	cmpl	$0, 4(%rax)
	jg	.LBB43_1
# %bb.4:
	addq	$8, %rsp
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	retq
.LBB43_1:
	.cfi_def_cfa_offset 32
	movslq	16(%rdi), %rcx
	leaq	(%rcx,%rcx,4), %rcx
	movslq	(%rax), %rax
	addq	%rcx, %rax
	movq	8(%rdi), %rcx
	movq	56(%rdi), %r14
	movq	(%rcx,%rax,8), %rax
	pinsrw	$0, (%rax), %xmm0
	movq	%rdi, %rbx
	callq	__extendhfsf2@PLT
	mulss	(%r14), %xmm0
	movss	%xmm0, 4(%rsp)                  # 4-byte Spill
	addq	$24, %rbx
	movq	%rbx, %rdi
	callq	_ZNK4sycl3_V16detail21LocalAccessorBaseHost6getPtrEv
	movss	4(%rsp), %xmm0                  # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%rax)
.Ltmp274:                               # EH_LABEL
	movl	$.L.str.8, %edi
	callq	_ZN4sycl3_V16detail24cannot_be_called_on_hostEPKc
.Ltmp275:                               # EH_LABEL
# %bb.2:
.LBB43_3:
.Ltmp276:                               # EH_LABEL
	movq	%rax, %rdi
	callq	__clang_call_terminate
.Lfunc_end43:
	.size	_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE, .Lfunc_end43-_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table43:
.Lexception14:
	.byte	255                             # @LPStart Encoding = omit
	.byte	3                               # @TType Encoding = udata4
	.uleb128 .Lttbase3-.Lttbaseref3
.Lttbaseref3:
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end14-.Lcst_begin14
.Lcst_begin14:
	.uleb128 .Lfunc_begin14-.Lfunc_begin14  # >> Call Site 1 <<
	.uleb128 .Ltmp274-.Lfunc_begin14        #   Call between .Lfunc_begin14 and .Ltmp274
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp274-.Lfunc_begin14        # >> Call Site 2 <<
	.uleb128 .Ltmp275-.Ltmp274              #   Call between .Ltmp274 and .Ltmp275
	.uleb128 .Ltmp276-.Lfunc_begin14        #     jumps to .Ltmp276
	.byte	1                               #   On action: 1
.Lcst_end14:
	.byte	1                               # >> Action Record 1 <<
                                        #   Catch TypeInfo 1
	.byte	0                               #   No further actions
	.p2align	2, 0x0
                                        # >> Catch TypeInfos <<
	.long	0                               # TypeInfo 1
.Lttbase3:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE2_EEDaSG_EUlSK_E_E4callEPKvSK_
	.prefalign	4, .Lfunc_end44, nop
	.type	_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE2_EEDaSG_EUlSK_E_E4callEPKvSK_,@function
_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE2_EEDaSG_EUlSK_E_E4callEPKvSK_: # 
.Lfunc_begin15:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception15
# %bb.0:
	pushq	%rbp
	.cfi_def_cfa_offset 16
	pushq	%r15
	.cfi_def_cfa_offset 24
	pushq	%r14
	.cfi_def_cfa_offset 32
	pushq	%r13
	.cfi_def_cfa_offset 40
	pushq	%r12
	.cfi_def_cfa_offset 48
	pushq	%rbx
	.cfi_def_cfa_offset 56
	subq	$392, %rsp                      # imm = 0x188
	.cfi_def_cfa_offset 448
	.cfi_offset %rbx, -56
	.cfi_offset %r12, -48
	.cfi_offset %r13, -40
	.cfi_offset %r14, -32
	.cfi_offset %r15, -24
	.cfi_offset %rbp, -16
	movq	%rsi, %rbx
	movq	%rdi, %r14
	movq	(%rdi), %rax
	movups	(%rax), %xmm0
	movq	8(%rax), %rax
	movups	%xmm0, 48(%rsp)                 # AlignMOV convert to UnAlignMOV 
	testq	%rax, %rax
	je	.LBB44_5
# %bb.1:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB44_3
# %bb.2:
	movl	8(%rax), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%rax)
	cmpl	$-1, %ecx
	jne	.LBB44_5
	jmp	.LBB44_66
.LBB44_3:
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%rax)
	cmpl	$-1, %ecx
	je	.LBB44_66
.LBB44_5:
.Ltmp277:                               # EH_LABEL
	leaq	48(%rsp), %rsi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler10depends_onENS0_5eventE
.Ltmp278:                               # EH_LABEL
# %bb.6:
	movq	56(%rsp), %r15
	testq	%r15, %r15
	je	.LBB44_14
# %bb.7:
	movq	8(%r15), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB44_9
# %bb.8:
	movq	$0, 8(%r15)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*16(%rax)
	movq	(%r15), %rax
	movq	%r15, %rdi
	callq	*24(%rax)
	jmp	.LBB44_14
.LBB44_9:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB44_11
# %bb.10:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r15)
	cmpl	$1, %eax
	je	.LBB44_13
.LBB44_14:
	movq	8(%r14), %r12
	movq	$.L.str, 104(%rsp)
	movq	$.L.str.3, 112(%rsp)
	movabsq	$188978561420, %rax             # imm = 0x2C0000018C
	movq	%rax, 120(%rsp)
	movq	120(%rsp), %rax
	movq	%rax, 16(%rsp)
	movups	104(%rsp), %xmm0
	movups	%xmm0, (%rsp)
	leaq	128(%rsp), %rdi
	movl	$128, %esi
	movq	%rbx, %rdx
	callq	_ZN4sycl3_V114local_accessorIfLi1EECI2NS0_19local_accessor_baseIfLi1ELNS0_6access4modeE1026ELNS4_11placeholderE0EEEILi1EvEENS0_5rangeILi1EEERNS0_7handlerENS0_6detail13code_locationE
	movq	(%r12), %rax
	movq	8(%r12), %rcx
	movslq	(%rax), %r13
	movslq	(%rcx), %r15
	movq	16(%r12), %rax
	movq	24(%r12), %rcx
	movq	(%rax), %rbp
	movq	(%rcx), %rax
	movq	%rax, 96(%rsp)                  # 8-byte Spill
	movq	32(%r12), %rax
	movq	(%rax), %rax
	movq	%rax, 88(%rsp)                  # 8-byte Spill
	movq	40(%r12), %rax
	movq	(%rax), %rax
	movq	%rax, 80(%rsp)                  # 8-byte Spill
	movq	48(%r12), %rax
	movl	(%rax), %eax
	movl	%eax, 44(%rsp)                  # 4-byte Spill
	movups	128(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 352(%rsp)                # 16-byte Spill
                                        # AlignMOV convert to UnAlignMOV 
	movq	136(%rsp), %r14
	testq	%r14, %r14
	je	.LBB44_19
# %bb.15:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB44_17
# %bb.16:
	movl	8(%r14), %eax
	leal	1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$-1, %eax
	jne	.LBB44_19
	jmp	.LBB44_66
.LBB44_17:
	movl	$1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$-1, %eax
	je	.LBB44_66
.LBB44_19:
	movups	144(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 368(%rsp)                # AlignMOV convert to UnAlignMOV 
	movq	56(%r12), %rax
	movq	64(%r12), %rcx
	movq	(%rax), %rax
	movq	%rax, 72(%rsp)                  # 8-byte Spill
	movl	(%rcx), %eax
	movl	%eax, 40(%rsp)                  # 4-byte Spill
	movq	72(%r12), %rax
	movq	(%rax), %r12
.Ltmp280:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZNK4sycl3_V17handler7getTypeEv
.Ltmp281:                               # EH_LABEL
# %bb.20:
	testl	%eax, %eax
	jne	.LBB44_21
# %bb.24:
.Ltmp287:                               # EH_LABEL
	movl	$.L.str.17, %esi
	movl	$134, %edx
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler30verifyUsedKernelBundleInternalENS0_6detail11string_viewE
.Ltmp288:                               # EH_LABEL
# %bb.25:
	shlq	$7, %r13
	movq	%r13, 200(%rsp)
	movq	%r15, 208(%rsp)
	leaq	216(%rsp), %rax
	movq	$128, 216(%rsp)
	movq	$1, 224(%rsp)
	leaq	232(%rsp), %rcx
	xorps	%xmm0, %xmm0
	movups	%xmm0, 232(%rsp)
	leaq	200(%rsp), %rdx
	movq	%rdx, 168(%rsp)
	movq	%rax, 176(%rsp)
	movq	%rcx, 184(%rsp)
	movq	$2, 192(%rsp)
.Ltmp289:                               # EH_LABEL
	movups	168(%rsp), %xmm0
	movups	184(%rsp), %xmm1
	movups	%xmm1, 16(%rsp)
	movups	%xmm0, (%rsp)
	movq	%rbx, %rdi
	xorl	%esi, %esi
	callq	_ZN4sycl3_V17handler20setNDRangeDescriptorENS0_6detail16nd_range_view_v113nd_range_viewEb
.Ltmp290:                               # EH_LABEL
# %bb.26:
.Ltmp291:                               # EH_LABEL
	movl	$104, %edi
	callq	_Znwm
.Ltmp292:                               # EH_LABEL
# %bb.27:
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rax)
	movq	%rbp, 8(%rax)
	movq	96(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 16(%rax)
	movq	88(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 24(%rax)
	movq	80(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 32(%rax)
	movl	44(%rsp), %ecx                  # 4-byte Reload
	movl	%ecx, 40(%rax)
	movups	352(%rsp), %xmm0                # 16-byte Reload
                                        # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 48(%rax)
	testq	%r14, %r14
	je	.LBB44_32
# %bb.28:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB44_30
# %bb.29:
	movl	8(%r14), %ecx
	leal	1(%rcx), %edx
	movl	%edx, 8(%r14)
	cmpl	$-1, %ecx
	je	.LBB44_66
.LBB44_32:
	movups	368(%rsp), %xmm0                # AlignMOV convert to UnAlignMOV 
	movups	%xmm0, 64(%rax)
	movq	72(%rsp), %rcx                  # 8-byte Reload
	movq	%rcx, 80(%rax)
	movl	40(%rsp), %ecx                  # 4-byte Reload
	movl	%ecx, 88(%rax)
	movq	%r12, 96(%rax)
	movq	144(%rbx), %rdi
	movq	%rax, 144(%rbx)
	testq	%rdi, %rdi
	je	.LBB44_34
# %bb.33:
	movq	(%rdi), %rax
	callq	*16(%rax)
.LBB44_34:
.Ltmp293:                               # EH_LABEL
	movl	$_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE, %esi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler23instantiateKernelOnHostEPv
.Ltmp294:                               # EH_LABEL
# %bb.35:
	movq	144(%rbx), %rdi
	movq	(%rdi), %rax
.Ltmp295:                               # EH_LABEL
	callq	*(%rax)
.Ltmp296:                               # EH_LABEL
# %bb.36:
	movq	$.L.str.17, 64(%rbx)
	movq	$134, 72(%rbx)
.Ltmp297:                               # EH_LABEL
	movq	%rbx, %rdi
	movq	%rax, %rsi
	callq	_ZN4sycl3_V17handler13setKernelFuncEPv
.Ltmp298:                               # EH_LABEL
# %bb.37:
	movzbl	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip), %eax
	testb	%al, %al
	je	.LBB44_38
.LBB44_41:
	movq	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip), %rsi
.Ltmp302:                               # EH_LABEL
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler22setDeviceKernelInfoPtrEPNS0_6detail16DeviceKernelInfoE
.Ltmp303:                               # EH_LABEL
# %bb.42:
.Ltmp304:                               # EH_LABEL
	movq	%rbx, %rdi
	movl	$1, %esi
	callq	_ZN4sycl3_V17handler7setTypeENS0_6detail6CGTypeE
.Ltmp305:                               # EH_LABEL
# %bb.43:
	movb	$0, 208(%rsp)
	movb	$0, 218(%rsp)
	movb	$0, 220(%rsp)
	movb	$0, 228(%rsp)
	movb	$0, 236(%rsp)
	movb	$0, 244(%rsp)
	movb	$0, 252(%rsp)
	movb	$0, 260(%rsp)
	movb	$0, 268(%rsp)
	movb	$0, 280(%rsp)
	movb	$0, 304(%rsp)
	movb	$0, 336(%rsp)
	movb	$1, 344(%rsp)
.Ltmp306:                               # EH_LABEL
	leaq	200(%rsp), %rsi
	movq	%rbx, %rdi
	callq	_ZN4sycl3_V17handler25setKernelLaunchPropertiesERKNS0_6detail27kernel_launch_properties_v111PropsHolderIJNS0_3ext6oneapi12experimental23work_group_scratch_sizeENS5_5intel12experimental12cache_configENS7_17use_root_sync_keyENS7_23work_group_progress_keyENS7_22sub_group_progress_keyENS7_22work_item_progress_keyENS7_4cuda12cluster_sizeILi1EEENSH_ILi2EEENSH_ILi3EEEEEE
.Ltmp307:                               # EH_LABEL
# %bb.44:
	testq	%r14, %r14
	je	.LBB44_52
# %bb.45:
	movq	8(%r14), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB44_47
# %bb.46:
	movq	$0, 8(%r14)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*16(%rax)
	movq	(%r14), %rax
	movq	%r14, %rdi
	callq	*24(%rax)
	jmp	.LBB44_52
.LBB44_47:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB44_49
# %bb.48:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%r14)
	cmpl	$1, %eax
	je	.LBB44_51
.LBB44_52:
	movq	136(%rsp), %rbx
	testq	%rbx, %rbx
	je	.LBB44_60
# %bb.53:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB44_55
# %bb.54:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
	jmp	.LBB44_60
.LBB44_55:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB44_57
# %bb.56:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB44_59
.LBB44_60:
	addq	$392, %rsp                      # imm = 0x188
	.cfi_def_cfa_offset 56
	popq	%rbx
	.cfi_def_cfa_offset 48
	popq	%r12
	.cfi_def_cfa_offset 40
	popq	%r13
	.cfi_def_cfa_offset 32
	popq	%r14
	.cfi_def_cfa_offset 24
	popq	%r15
	.cfi_def_cfa_offset 16
	popq	%rbp
	.cfi_def_cfa_offset 8
	retq
.LBB44_30:
	.cfi_def_cfa_offset 448
	movl	$1, %ecx
	lock		xaddl	%ecx, 8(%r14)
	cmpl	$-1, %ecx
	jne	.LBB44_32
.LBB44_66:
	ud2
.LBB44_11:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r15)
	cmpl	$1, %eax
	jne	.LBB44_14
.LBB44_13:
	movq	%r15, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB44_14
.LBB44_49:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%r14)
	cmpl	$1, %eax
	jne	.LBB44_52
.LBB44_51:
	movq	%r14, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB44_52
.LBB44_57:
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB44_60
.LBB44_59:
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB44_60
.LBB44_21:
	movl	$64, %edi
	callq	__cxa_allocate_exception
	movq	%rax, %r15
	movl	$1, %edi
	callq	_ZN4sycl3_V115make_error_codeENS0_4errcE
.Ltmp282:                               # EH_LABEL
	movl	$.L.str.7, %ecx
	movq	%r15, %rdi
	movl	%eax, %esi
	callq	_ZN4sycl3_V19exceptionC1ESt10error_codePKc
.Ltmp283:                               # EH_LABEL
# %bb.22:
.Ltmp285:                               # EH_LABEL
	movl	$_ZTIN4sycl3_V19exceptionE, %esi
	movl	$_ZN4sycl3_V19exceptionD1Ev, %edx
	movq	%r15, %rdi
	callq	__cxa_throw
.Ltmp286:                               # EH_LABEL
# %bb.23:
.LBB44_38:
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_acquire
	testl	%eax, %eax
	je	.LBB44_41
# %bb.39:
.Ltmp299:                               # EH_LABEL
	movl	$_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESG_EUlNS0_7nd_itemILi2EEEE_EE, %edi
	callq	_ZN4sycl3_V16detail19getDeviceKernelInfoERKNS1_27compile_time_kernel_info_v123CompileTimeKernelInfoTyE
.Ltmp300:                               # EH_LABEL
# %bb.40:
	movq	%rax, _ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info(%rip)
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_release
	jmp	.LBB44_41
.LBB44_67:
.Ltmp301:                               # EH_LABEL
	movq	%rax, %rbx
	movl	$_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info, %edi
	callq	__cxa_guard_abort
	jmp	.LBB44_63
.LBB44_62:
.Ltmp284:                               # EH_LABEL
	movq	%rax, %rbx
	movq	%r15, %rdi
	callq	__cxa_free_exception
	jmp	.LBB44_63
.LBB44_64:
.Ltmp279:                               # EH_LABEL
	movq	%rax, %rbx
	leaq	48(%rsp), %rdi
	callq	_ZN4sycl3_V15eventD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.LBB44_61:
.Ltmp308:                               # EH_LABEL
	movq	%rax, %rbx
.LBB44_63:
	movq	%r14, %rdi
	callq	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE2_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	leaq	128(%rsp), %rdi
	callq	_ZN4sycl3_V16detail21LocalAccessorBaseHostD2Ev
	movq	%rbx, %rdi
	callq	_Unwind_Resume@PLT
.Lfunc_end44:
	.size	_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE2_EEDaSG_EUlSK_E_E4callEPKvSK_, .Lfunc_end44-_ZN4sycl3_V16detail19type_erased_cgfo_ty7invokerIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlOT_E_clIZNS5_7forwardES8_iSB_SD_SE_iEUlRNS0_7handlerEE2_EEDaSG_EUlSK_E_E4callEPKvSK_
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table44:
.Lexception15:
	.byte	255                             # @LPStart Encoding = omit
	.byte	255                             # @TType Encoding = omit
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end15-.Lcst_begin15
.Lcst_begin15:
	.uleb128 .Ltmp277-.Lfunc_begin15        # >> Call Site 1 <<
	.uleb128 .Ltmp278-.Ltmp277              #   Call between .Ltmp277 and .Ltmp278
	.uleb128 .Ltmp279-.Lfunc_begin15        #     jumps to .Ltmp279
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp278-.Lfunc_begin15        # >> Call Site 2 <<
	.uleb128 .Ltmp280-.Ltmp278              #   Call between .Ltmp278 and .Ltmp280
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp280-.Lfunc_begin15        # >> Call Site 3 <<
	.uleb128 .Ltmp292-.Ltmp280              #   Call between .Ltmp280 and .Ltmp292
	.uleb128 .Ltmp308-.Lfunc_begin15        #     jumps to .Ltmp308
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp292-.Lfunc_begin15        # >> Call Site 4 <<
	.uleb128 .Ltmp293-.Ltmp292              #   Call between .Ltmp292 and .Ltmp293
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp293-.Lfunc_begin15        # >> Call Site 5 <<
	.uleb128 .Ltmp307-.Ltmp293              #   Call between .Ltmp293 and .Ltmp307
	.uleb128 .Ltmp308-.Lfunc_begin15        #     jumps to .Ltmp308
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp307-.Lfunc_begin15        # >> Call Site 6 <<
	.uleb128 .Ltmp282-.Ltmp307              #   Call between .Ltmp307 and .Ltmp282
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp282-.Lfunc_begin15        # >> Call Site 7 <<
	.uleb128 .Ltmp283-.Ltmp282              #   Call between .Ltmp282 and .Ltmp283
	.uleb128 .Ltmp284-.Lfunc_begin15        #     jumps to .Ltmp284
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp285-.Lfunc_begin15        # >> Call Site 8 <<
	.uleb128 .Ltmp286-.Ltmp285              #   Call between .Ltmp285 and .Ltmp286
	.uleb128 .Ltmp308-.Lfunc_begin15        #     jumps to .Ltmp308
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp299-.Lfunc_begin15        # >> Call Site 9 <<
	.uleb128 .Ltmp300-.Ltmp299              #   Call between .Ltmp299 and .Ltmp300
	.uleb128 .Ltmp301-.Lfunc_begin15        #     jumps to .Ltmp301
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp300-.Lfunc_begin15        # >> Call Site 10 <<
	.uleb128 .Lfunc_end44-.Ltmp300          #   Call between .Ltmp300 and .Lfunc_end44
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
.Lcst_end15:
	.p2align	2, 0x0
                                        # -- End function
	.text
	.p2align	1                               # -- Begin function _ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE2_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	.prefalign	4, .Lfunc_end45, nop
	.type	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE2_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev,@function
_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE2_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	testq	%rdi, %rdi
	je	.LBB45_6
# %bb.1:
	movq	8(%rdi), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB45_2
# %bb.7:
	movq	$0, 8(%rdi)
	movq	(%rdi), %rax
	movq	%rdi, %rbx
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB45_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB45_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rdi)
	cmpl	$1, %eax
	je	.LBB45_8
.LBB45_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB45_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rdi)
	cmpl	$1, %eax
	jne	.LBB45_6
.LBB45_8:
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end45:
	.size	_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE2_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev, .Lfunc_end45-_ZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE2_clESD_ENUlNSB_7nd_itemILi2EEEE_D2Ev
	.cfi_endproc
                                        # -- End function
	.prefalign	4, .Lfunc_end46, nop    # -- Begin function _ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.type	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi,@function
_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi: # 
	.cfi_startproc
# %bb.0:
                                        # kill: def $edi killed $edi def $rdi
	addl	$47, %edi
	shlq	$2, %rdi
	movq	_ZN4sycl3_V16detailL17kernel_signaturesE(%rdi,%rdi,2), %rax
	movl	_ZN4sycl3_V16detailL17kernel_signaturesE+8(%rdi,%rdi,2), %edx
	retq
.Lfunc_end46:
	.size	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi, .Lfunc_end46-_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.prefalign	4, .Lfunc_end47, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv: # 
	.cfi_startproc
# %bb.0:
	leaq	8(%rdi), %rax
	retq
.Lfunc_end47:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv, .Lfunc_end47-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.prefalign	4, .Lfunc_end48, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%rbx
	.cfi_def_cfa_offset 16
	.cfi_offset %rbx, -16
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rdi)
	movq	56(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB48_6
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB48_2
# %bb.7:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmpq	*24(%rax)                       # TAILCALL
.LBB48_2:
	.cfi_def_cfa_offset 16
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB48_4
# %bb.3:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB48_8
.LBB48_6:
	popq	%rbx
	.cfi_def_cfa_offset 8
	retq
.LBB48_4:
	.cfi_def_cfa_offset 16
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB48_6
.LBB48_8:
	movq	%rbx, %rdi
	popq	%rbx
	.cfi_def_cfa_offset 8
	jmp	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv # TAILCALL
.Lfunc_end48:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev, .Lfunc_end48-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.cfi_endproc
                                        # -- End function
	.p2align	1                               # -- Begin function _ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.prefalign	4, .Lfunc_end49, nop
	.type	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev,@function
_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev: # 
	.cfi_startproc
# %bb.0:
	pushq	%r14
	.cfi_def_cfa_offset 16
	pushq	%rbx
	.cfi_def_cfa_offset 24
	pushq	%rax
	.cfi_def_cfa_offset 32
	.cfi_offset %rbx, -24
	.cfi_offset %r14, -16
	movq	$_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE+16, (%rdi)
	movq	56(%rdi), %rbx
	testq	%rbx, %rbx
	je	.LBB49_9
# %bb.1:
	movq	8(%rbx), %rax
	movabsq	$4294967297, %rcx               # imm = 0x100000001
	cmpq	%rcx, %rax
	jne	.LBB49_3
# %bb.2:
	movq	$0, 8(%rbx)
	movq	(%rbx), %rax
	movq	%rdi, %r14
	movq	%rbx, %rdi
	callq	*16(%rax)
	movq	(%rbx), %rax
	movq	%rbx, %rdi
	callq	*24(%rax)
.LBB49_8:
	movq	%r14, %rdi
	jmp	.LBB49_9
.LBB49_3:
	cmpb	$0, __libc_single_threaded(%rip)
	je	.LBB49_5
# %bb.4:
	leal	-1(%rax), %ecx
	movl	%ecx, 8(%rbx)
	cmpl	$1, %eax
	je	.LBB49_7
.LBB49_9:
	movl	$104, %esi
	addq	$8, %rsp
	.cfi_def_cfa_offset 24
	popq	%rbx
	.cfi_def_cfa_offset 16
	popq	%r14
	.cfi_def_cfa_offset 8
	jmp	_ZdlPvm                         # TAILCALL
.LBB49_5:
	.cfi_def_cfa_offset 32
	movl	$-1, %eax
	lock		xaddl	%eax, 8(%rbx)
	cmpl	$1, %eax
	jne	.LBB49_9
.LBB49_7:
	movq	%rdi, %r14
	movq	%rbx, %rdi
	callq	_ZNSt16_Sp_counted_baseILN9__gnu_cxx12_Lock_policyE2EE24_M_release_last_use_coldEv
	jmp	.LBB49_8
.Lfunc_end49:
	.size	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev, .Lfunc_end49-_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.cfi_endproc
                                        # -- End function
	.prefalign	4, .Lfunc_end50, nop    # -- Begin function _ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE
	.type	_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE,@function
_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE: # 
.Lfunc_begin16:
	.cfi_startproc
	.cfi_personality 3, __gxx_personality_v0
	.cfi_lsda 3, .Lexception16
# %bb.0:
	pushq	%rax
	.cfi_def_cfa_offset 16
	movq	(%rdi), %rcx
	movslq	(%rcx), %rax
	cmpl	4(%rcx), %eax
	jl	.LBB50_1
# %bb.4:
	movq	88(%rdi), %rax
	movl	$0, (%rax)
	popq	%rax
	.cfi_def_cfa_offset 8
	retq
.LBB50_1:
	.cfi_def_cfa_offset 16
	movq	8(%rdi), %rcx
	movq	72(%rdi), %rdx
	movl	(%rcx,%rax,4), %eax
	movl	%eax, %ecx
	sarl	$2, %ecx
	andl	$3, %eax
	movslq	%ecx, %rcx
	leaq	(%rax,%rcx,4), %rax
	movslq	80(%rdi), %rcx
	imulq	%rax, %rcx
	movss	(%rdx,%rcx,4), %xmm0            # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, 4(%rsp)                  # 4-byte Spill
	addq	$40, %rdi
	callq	_ZNK4sycl3_V16detail21LocalAccessorBaseHost6getPtrEv
	movss	4(%rsp), %xmm0                  # 4-byte Reload
                                        # xmm0 = mem[0],zero,zero,zero
	movss	%xmm0, (%rax)
.Ltmp309:                               # EH_LABEL
	movl	$.L.str.8, %edi
	callq	_ZN4sycl3_V16detail24cannot_be_called_on_hostEPKc
.Ltmp310:                               # EH_LABEL
# %bb.2:
.LBB50_3:
.Ltmp311:                               # EH_LABEL
	movq	%rax, %rdi
	callq	__clang_call_terminate
.Lfunc_end50:
	.size	_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE, .Lfunc_end50-_ZN4sycl3_V16detail16runKernelWithArgINS0_7nd_itemILi2EEEZZN8moe_sycl12MoeSyclLayer7forwardEPKNS5_8ChunkDevEiRKNS5_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESH_EUlS4_E_Lb0EEEvT0_T_RKSt17integral_constantIbXT1_EE
	.cfi_endproc
	.section	.gcc_except_table,"a",@progbits
	.p2align	2, 0x0
GCC_except_table50:
.Lexception16:
	.byte	255                             # @LPStart Encoding = omit
	.byte	3                               # @TType Encoding = udata4
	.uleb128 .Lttbase4-.Lttbaseref4
.Lttbaseref4:
	.byte	1                               # Call site Encoding = uleb128
	.uleb128 .Lcst_end16-.Lcst_begin16
.Lcst_begin16:
	.uleb128 .Lfunc_begin16-.Lfunc_begin16  # >> Call Site 1 <<
	.uleb128 .Ltmp309-.Lfunc_begin16        #   Call between .Lfunc_begin16 and .Ltmp309
	.byte	0                               #     has no landing pad
	.byte	0                               #   On action: cleanup
	.uleb128 .Ltmp309-.Lfunc_begin16        # >> Call Site 2 <<
	.uleb128 .Ltmp310-.Ltmp309              #   Call between .Ltmp309 and .Ltmp310
	.uleb128 .Ltmp311-.Lfunc_begin16        #     jumps to .Ltmp311
	.byte	1                               #   On action: 1
.Lcst_end16:
	.byte	1                               # >> Action Record 1 <<
                                        #   Catch TypeInfo 1
	.byte	0                               #   No further actions
	.p2align	2, 0x0
                                        # >> Catch TypeInfos <<
	.long	0                               # TypeInfo 1
.Lttbase4:
	.p2align	2, 0x0
                                        # -- End function
	.type	.L.str,@object                  # 
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str:
	.asciz	"moe_sycl.cpp"
	.size	.L.str, 13

	.type	.L.str.1,@object                # 
.L.str.1:
	.asciz	"init"
	.size	.L.str.1, 5

	.type	.L.str.2,@object                # 
.L.str.2:
	.asciz	"forward"
	.size	.L.str.2, 8

	.type	.L.str.3,@object                # 
.L.str.3:
	.asciz	"operator()"
	.size	.L.str.3, 11

	.type	.L.str.5,@object                # 
.L.str.5:
	.asciz	"_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE_clESD_EUlNSB_7nd_itemILi2EEEE_"
	.size	.L.str.5, 134

	.type	.L.str.6,@object                # 
.L.str.6:
	.zero	1
	.size	.L.str.6, 1

	.type	_ZN4sycl3_V16detailL17kernel_signaturesE,@object # 
	.section	.rodata,"a",@progbits
	.p2align	4, 0x0
_ZN4sycl3_V16detailL17kernel_signaturesE:
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	0                               # 0x0
	.long	1                               # 0x1
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	16                              # 0x10
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	24                              # 0x18
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	32                              # 0x20
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	40                              # 0x28
	.long	0                               # 0x0
	.long	4064                            # 0xfe0
	.long	48                              # 0x30
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	80                              # 0x50
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	0                               # 0x0
	.long	1                               # 0x1
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	8                               # 0x8
	.long	1                               # 0x1
	.long	1                               # 0x1
	.long	12                              # 0xc
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	16                              # 0x10
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	24                              # 0x18
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	32                              # 0x20
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	40                              # 0x28
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	48                              # 0x30
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	56                              # 0x38
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	64                              # 0x40
	.long	1                               # 0x1
	.long	256                             # 0x100
	.long	68                              # 0x44
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	324                             # 0x144
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	328                             # 0x148
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	332                             # 0x14c
	.long	0                               # 0x0
	.long	4064                            # 0xfe0
	.long	336                             # 0x150
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	368                             # 0x170
	.long	0                               # 0x0
	.long	4064                            # 0xfe0
	.long	376                             # 0x178
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	408                             # 0x198
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	416                             # 0x1a0
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	424                             # 0x1a8
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	0                               # 0x0
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	16                              # 0x10
	.long	1                               # 0x1
	.long	1                               # 0x1
	.long	20                              # 0x14
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	24                              # 0x18
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	32                              # 0x20
	.long	0                               # 0x0
	.long	4064                            # 0xfe0
	.long	40                              # 0x28
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	72                              # 0x48
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	76                              # 0x4c
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	80                              # 0x50
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	0                               # 0x0
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	16                              # 0x10
	.long	0                               # 0x0
	.long	4064                            # 0xfe0
	.long	24                              # 0x18
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	56                              # 0x38
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	64                              # 0x40
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	72                              # 0x48
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	0                               # 0x0
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	8                               # 0x8
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	16                              # 0x10
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	24                              # 0x18
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	32                              # 0x20
	.long	0                               # 0x0
	.long	4064                            # 0xfe0
	.long	40                              # 0x28
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	72                              # 0x48
	.long	1                               # 0x1
	.long	4                               # 0x4
	.long	80                              # 0x50
	.long	3                               # 0x3
	.long	8                               # 0x8
	.long	88                              # 0x58
	.long	15                              # 0xf
	.long	3307312975                      # 0xc521974f
	.long	3307312975                      # 0xc521974f
	.size	_ZN4sycl3_V16detailL17kernel_signaturesE, 684

	.type	.L.str.7,@object                # 
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.7:
	.asciz	"Attempt to set multiple actions for the command group. Command group must consist of a single kernel or explicit memory operation."
	.size	.L.str.7, 131

	.type	_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
	.section	.rodata,"a",@progbits
	.p2align	3, 0x0
_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.quad	0
	.quad	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.size	_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 40

	.type	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
	.p2align	3, 0x0
_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.quad	_ZTVN10__cxxabiv120__si_class_type_infoE+16
	.quad	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE
	.quad	_ZTIN4sycl3_V16detail14HostKernelBaseE
	.size	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 24

	.type	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.asciz	"N4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE"
	.size	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 165

	.type	_ZTIN4sycl3_V16detail14HostKernelBaseE,@object # 
	.section	.rodata._ZTIN4sycl3_V16detail14HostKernelBaseE,"aG",@progbits,_ZTIN4sycl3_V16detail14HostKernelBaseE,comdat
	.weak	_ZTIN4sycl3_V16detail14HostKernelBaseE
	.p2align	3, 0x0
_ZTIN4sycl3_V16detail14HostKernelBaseE:
	.quad	_ZTVN10__cxxabiv117__class_type_infoE+16
	.quad	_ZTSN4sycl3_V16detail14HostKernelBaseE
	.size	_ZTIN4sycl3_V16detail14HostKernelBaseE, 16

	.type	_ZTSN4sycl3_V16detail14HostKernelBaseE,@object # 
	.section	.rodata._ZTSN4sycl3_V16detail14HostKernelBaseE,"aG",@progbits,_ZTSN4sycl3_V16detail14HostKernelBaseE,comdat
	.weak	_ZTSN4sycl3_V16detail14HostKernelBaseE
_ZTSN4sycl3_V16detail14HostKernelBaseE:
	.asciz	"N4sycl3_V16detail14HostKernelBaseE"
	.size	_ZTSN4sycl3_V16detail14HostKernelBaseE, 35

	.type	.L.str.8,@object                # 
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.8:
	.asciz	"local_accessor::get_pointer"
	.size	.L.str.8, 28

	.type	.L.str.9,@object                # 
.L.str.9:
	.asciz	"Barriers are not supported on host"
	.size	.L.str.9, 35

	.type	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,@object # 
	.local	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info
	.comm	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,8,8
	.type	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,@object # 
	.local	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info
	.comm	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,8,8
	.type	_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi2EEEE_EE,@object # 
	.section	.rodata,"a",@progbits
	.p2align	3, 0x0
_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi2EEEE_EE:
	.quad	.L.str.5
	.quad	133                             # 0x85
	.long	9                               # 0x9
	.byte	0                               # 0x0
	.zero	3
	.quad	.L.str.6
	.quad	0                               # 0x0
	.quad	.L.str.6
	.quad	0                               # 0x0
	.long	0                               # 0x0
	.long	0                               # 0x0
	.quad	88                              # 0x58
	.quad	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.byte	1                               # 0x1
	.zero	7
	.size	_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi2EEEE_EE, 88

	.type	.L.str.11,@object               # 
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.11:
	.asciz	"_ZTSZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlbE_clEbENKUlRN4sycl3_V17handlerEE_clESE_EUlNSC_7nd_itemILi1EEEE_"
	.size	.L.str.11, 147

	.type	_ZTVN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE,@object # 
	.section	.rodata,"a",@progbits
	.p2align	3, 0x0
_ZTVN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE:
	.quad	0
	.quad	_ZTIN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE
	.quad	_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EE6getPtrEv
	.quad	_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED2Ev
	.quad	_ZN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EED0Ev
	.size	_ZTVN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE, 40

	.type	_ZTIN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE,@object # 
	.p2align	3, 0x0
_ZTIN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE:
	.quad	_ZTVN10__cxxabiv120__si_class_type_infoE+16
	.quad	_ZTSN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE
	.quad	_ZTIN4sycl3_V16detail14HostKernelBaseE
	.size	_ZTIN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE, 24

	.type	_ZTSN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE,@object # 
_ZTSN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE:
	.asciz	"N4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE"
	.size	_ZTSN4sycl3_V16detail10HostKernelIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_SJ_Li1EEE, 178

	.type	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info,@object # 
	.local	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info
	.comm	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info,8,8
	.type	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info,@object # 
	.local	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info
	.comm	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EERNS1_16DeviceKernelInfoEvE4Info,8,8
	.type	_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESH_EUlNS0_7nd_itemILi1EEEE_EE,@object # 
	.p2align	3, 0x0
_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESH_EUlNS0_7nd_itemILi1EEEE_EE:
	.quad	.L.str.11
	.quad	146                             # 0x92
	.long	21                              # 0x15
	.byte	0                               # 0x0
	.zero	3
	.quad	.L.str.6
	.quad	0                               # 0x0
	.quad	.L.str.6
	.quad	0                               # 0x0
	.long	0                               # 0x0
	.long	0                               # 0x0
	.quad	432                             # 0x1b0
	.quad	_ZN4sycl3_V16detail18getKernelParamDescIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESG_EUlNS0_7nd_itemILi1EEEE_EENS1_19kernel_param_desc_tEi
	.byte	1                               # 0x1
	.zero	7
	.size	_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlbE_clEbENKUlRNS0_7handlerEE_clESH_EUlNS0_7nd_itemILi1EEEE_EE, 88

	.type	.L.str.13,@object               # 
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.13:
	.asciz	"_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE0_clESD_EUlNSB_7nd_itemILi2EEEE_"
	.size	.L.str.13, 135

	.type	_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
	.section	.rodata,"a",@progbits
	.p2align	3, 0x0
_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.quad	0
	.quad	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.size	_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 40

	.type	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
	.p2align	3, 0x0
_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.quad	_ZTVN10__cxxabiv120__si_class_type_infoE+16
	.quad	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE
	.quad	_ZTIN4sycl3_V16detail14HostKernelBaseE
	.size	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 24

	.type	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.asciz	"N4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE"
	.size	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 166

	.type	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,@object # 
	.local	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info
	.comm	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,8,8
	.type	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,@object # 
	.local	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info
	.comm	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,8,8
	.type	_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESG_EUlNS0_7nd_itemILi2EEEE_EE,@object # 
	.p2align	3, 0x0
_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESG_EUlNS0_7nd_itemILi2EEEE_EE:
	.quad	.L.str.13
	.quad	134                             # 0x86
	.long	10                              # 0xa
	.byte	0                               # 0x0
	.zero	3
	.quad	.L.str.6
	.quad	0                               # 0x0
	.quad	.L.str.6
	.quad	0                               # 0x0
	.long	0                               # 0x0
	.long	0                               # 0x0
	.quad	88                              # 0x58
	.quad	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.byte	1                               # 0x1
	.zero	7
	.size	_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE0_clESG_EUlNS0_7nd_itemILi2EEEE_EE, 88

	.type	.L.str.15,@object               # 
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.15:
	.asciz	"_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE1_clESD_EUlNSB_7nd_itemILi2EEEE_"
	.size	.L.str.15, 135

	.type	_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
	.section	.rodata,"a",@progbits
	.p2align	3, 0x0
_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.quad	0
	.quad	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.size	_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 40

	.type	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
	.p2align	3, 0x0
_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.quad	_ZTVN10__cxxabiv120__si_class_type_infoE+16
	.quad	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE
	.quad	_ZTIN4sycl3_V16detail14HostKernelBaseE
	.size	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 24

	.type	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.asciz	"N4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE"
	.size	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 166

	.type	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,@object # 
	.local	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info
	.comm	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,8,8
	.type	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,@object # 
	.local	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info
	.comm	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,8,8
	.type	_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESG_EUlNS0_7nd_itemILi2EEEE_EE,@object # 
	.p2align	3, 0x0
_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESG_EUlNS0_7nd_itemILi2EEEE_EE:
	.quad	.L.str.15
	.quad	134                             # 0x86
	.long	7                               # 0x7
	.byte	0                               # 0x0
	.zero	3
	.quad	.L.str.6
	.quad	0                               # 0x0
	.quad	.L.str.6
	.quad	0                               # 0x0
	.long	0                               # 0x0
	.long	0                               # 0x0
	.quad	80                              # 0x50
	.quad	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.byte	1                               # 0x1
	.zero	7
	.size	_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE1_clESG_EUlNS0_7nd_itemILi2EEEE_EE, 88

	.type	.L.str.17,@object               # 
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.17:
	.asciz	"_ZTSZZN8moe_sycl12MoeSyclLayer7forwardEPKNS_8ChunkDevEiRKNS_8TokenMapEPKtPfiENKUlRN4sycl3_V17handlerEE2_clESD_EUlNSB_7nd_itemILi2EEEE_"
	.size	.L.str.17, 135

	.type	_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
	.section	.rodata,"a",@progbits
	.p2align	3, 0x0
_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.quad	0
	.quad	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EE6getPtrEv
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED2Ev
	.quad	_ZN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EED0Ev
	.size	_ZTVN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 40

	.type	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
	.p2align	3, 0x0
_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.quad	_ZTVN10__cxxabiv120__si_class_type_infoE+16
	.quad	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE
	.quad	_ZTIN4sycl3_V16detail14HostKernelBaseE
	.size	_ZTIN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 24

	.type	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE,@object # 
_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE:
	.asciz	"N4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE"
	.size	_ZTSN4sycl3_V16detail10HostKernelIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_SI_Li2EEE, 166

	.type	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,@object # 
	.local	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info
	.comm	_ZZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,8,8
	.type	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,@object # 
	.local	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info
	.comm	_ZGVZN4sycl3_V16detail19getDeviceKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EERNS1_16DeviceKernelInfoEvE4Info,8,8
	.type	_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESG_EUlNS0_7nd_itemILi2EEEE_EE,@object # 
	.p2align	3, 0x0
_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESG_EUlNS0_7nd_itemILi2EEEE_EE:
	.quad	.L.str.17
	.quad	134                             # 0x86
	.long	9                               # 0x9
	.byte	0                               # 0x0
	.zero	3
	.quad	.L.str.6
	.quad	0                               # 0x0
	.quad	.L.str.6
	.quad	0                               # 0x0
	.long	0                               # 0x0
	.long	0                               # 0x0
	.quad	96                              # 0x60
	.quad	_ZN4sycl3_V16detail18getKernelParamDescIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS3_8ChunkDevEiRKNS3_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESF_EUlNS0_7nd_itemILi2EEEE_EENS1_19kernel_param_desc_tEi
	.byte	1                               # 0x1
	.zero	7
	.size	_ZN4sycl3_V16detail27compile_time_kernel_info_v121CompileTimeKernelInfoIZZN8moe_sycl12MoeSyclLayer7forwardEPKNS4_8ChunkDevEiRKNS4_8TokenMapEPKtPfiENKUlRNS0_7handlerEE2_clESG_EUlNS0_7nd_itemILi2EEEE_EE, 88

	.type	.L.str.19,@object               # 
	.section	.rodata.str1.1,"aMS",@progbits,1
.L.str.19:
	.asciz	"cannot create std::vector larger than max_size()"
	.size	.L.str.19, 49

	.type	.L.str.20,@object               # 
.L.str.20:
	.asciz	"vector::_M_realloc_append"
	.size	.L.str.20, 26

	.section	.deplibs,"MS",@llvm_dependent_libraries,1
	.ascii	"sycl-devicelib-host"
	.byte	0
	.globl	_ZN8moe_sycl12MoeSyclLayerD1Ev
	.type	_ZN8moe_sycl12MoeSyclLayerD1Ev,@function
_ZN8moe_sycl12MoeSyclLayerD1Ev = _ZN8moe_sycl12MoeSyclLayerD2Ev
	.ident	"Intel(R) oneAPI DPC++/C++ Compiler 2026.2.0 (2026.2.0.20261001)"
	.section	".note.GNU-stack","",@progbits

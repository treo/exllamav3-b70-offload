; ------------------------------------------------
; VC_asm9cea78f553115c9f_final.ll
; ------------------------------------------------
; ModuleID = 'Deserialized LLVM Module'
target datalayout = "e-p:64:64-p3:32:32-p6:32:32-i64:64-n8:16:32:64"
target triple = "genx64-unknown-unknown"

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16>, i32, i32, i32, i16, i32) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32>, <16 x i32>, i32, i32, i32, i16, i32, <16 x i1>) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32>, <128 x i32>, <64 x i32>, i32, i32, i32, i32, i32, i32) #0

; Function Attrs: nounwind memory(readwrite, inaccessiblemem: none, target_mem0: none, target_mem1: none)
define dllexport spir_kernel void @_ZTSZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_EUlNS4_7nd_itemILi1EEEE_(i32 %0, i32 %1, ptr addrspace(1) readonly align 4 captures(none) %2, ptr addrspace(1) readonly align 4 captures(none) %3, ptr addrspace(1) writeonly align 4 %4, ptr addrspace(1) writeonly align 4 %5, i32 %6, i32 %7, i32 %8, i32 %9, i32 %10, i32 %11, i32 %12, i32 %13, ptr addrspace(4) readonly align 4 captures(none) %14, i32 %15, i32 %16, <3 x i16> %impl.arg.llvm.genx.local.id16, <3 x i32> %impl.arg.llvm.genx.local.size, i64 %impl.arg.private.base) local_unnamed_addr #1 {
_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5:
  %17 = call <4 x i32> @llvm.genx.read.predef.reg.v4i32.v4i32(i32 14, <4 x i32> undef)
  %18 = call i32 @llvm.genx.rdregioni.i32.v4i32.i16(<4 x i32> %17, i32 0, i32 1, i32 1, i16 0, i32 undef)
  %19 = and i32 %18, -1073743089
  %20 = call <4 x i32> @llvm.genx.wrregioni.v4i32.i32.i16.i1(<4 x i32> %17, i32 %19, i32 0, i32 1, i32 1, i16 0, i32 undef, i1 true)
  %21 = call <4 x i32> @llvm.genx.write.predef.reg.v4i32.v4i32(i32 14, <4 x i32> %20)
  %22 = call <4 x i32> @llvm.genx.read.predef.reg.v4i32.v4i32(i32 14, <4 x i32> undef)
  %23 = call i32 @llvm.genx.rdregioni.i32.v4i32.i16(<4 x i32> %22, i32 0, i32 1, i32 1, i16 0, i32 undef)
  %24 = or i32 %23, 1073743040
  %25 = call <4 x i32> @llvm.genx.wrregioni.v4i32.i32.i16.i1(<4 x i32> %22, i32 %24, i32 0, i32 1, i32 1, i16 0, i32 undef, i1 true)
  %26 = call <4 x i32> @llvm.genx.write.predef.reg.v4i32.v4i32(i32 14, <4 x i32> %25)
  %27 = tail call noundef i32 @llvm.genx.group.id.x()
  %.bitcast484 = bitcast i32 %27 to <1 x i32>
  %28 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v3i32.i16(<3 x i32> %impl.arg.llvm.genx.local.size, i32 0, i32 1, i32 1, i16 0, i32 undef)
  %29 = call <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32> %28, <1 x i32> %.bitcast484, <1 x i32> zeroinitializer)
  %.lo486 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %29, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo486, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi485 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %29, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.imul.partial_join, <1 x i32> %.hi485, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.imul.recast = bitcast <2 x i32> %.imul.joined to i64
  %30 = call i16 @llvm.genx.rdregioni.i16.v3i16.i16(<3 x i16> %impl.arg.llvm.genx.local.id16, i32 0, i32 1, i32 1, i16 0, i32 0)
  %31 = zext i16 %30 to i64
  %32 = add nuw i64 %.imul.recast, %31
  %33 = bitcast i64 %32 to <2 x i32>
  %34 = call i32 @llvm.genx.rdregioni.i32.v2i32.i16(<2 x i32> %33, i32 2, i32 1, i32 2, i16 0, i32 undef)
  %35 = lshr i32 %34, 1
  %callarg.precopy701 = bitcast i32 %35 to i32
  %callarg.precopy702 = bitcast i32 %0 to i32
  %36 = call i32 @__vc_builtin_sdiv_i32__rtz_(i32 %callarg.precopy701, i32 %callarg.precopy702)
  %retval.postcopy = bitcast i32 %36 to i32
  %37 = mul i32 %retval.postcopy, %0
  %38 = sub i32 %35, %37
  %39 = ptrtoint ptr addrspace(1) %2 to i64
  %40 = ptrtoint ptr addrspace(1) %3 to i64
  %.iv32cast578 = bitcast i64 %39 to <2 x i32>
  %.iv32cast581 = bitcast i64 %40 to <2 x i32>
  %41 = icmp slt i32 %38, %1
  %.LoSplit579 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast578, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.LoSplit582 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast581, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %sel.lo = select i1 %41, <1 x i32> %.LoSplit579, <1 x i32> %.LoSplit582
  %int_emu.select.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.iv32cast581, <1 x i32> %sel.lo, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.HiSplit580 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast578, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %.HiSplit583 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %int_emu.select.partial_join, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %sel.hi = select i1 %41, <1 x i32> %.HiSplit580, <1 x i32> %.HiSplit583
  %int_emu.select.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %int_emu.select.partial_join, <1 x i32> %sel.hi, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %int_emu.select.recast = bitcast <2 x i32> %int_emu.select.joined to i64
  %42 = select i1 %41, i32 0, i32 %1
  %43 = sub nsw i32 %38, %42, !spirv.Decorations !22
  %callarg.precopy = bitcast i32 %retval.postcopy to i32
  %callarg.precopy700 = bitcast i32 %6 to i32
  %44 = call i32 @__vc_builtin_sdiv_i32__rtz_(i32 %callarg.precopy, i32 %callarg.precopy700)
  %45 = mul i32 %44, %6
  %46 = sub i32 %retval.postcopy, %45
  %47 = mul nsw i32 %46, %7, !spirv.Decorations !22
  %48 = call <2 x i32> @llvm.genx.constanti.v2i32(<2 x i32> <i32 1, i32 0>)
  %int_emu. = and <2 x i32> %33, %48
  %.not.HiSplit = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %int_emu., i32 0, i32 1, i32 2, i16 4, i32 undef)
  %49 = icmp eq <1 x i32> %.not.HiSplit, zeroinitializer
  %.not.LoSplit = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %int_emu., i32 0, i32 1, i32 2, i16 0, i32 undef)
  %50 = icmp eq <1 x i32> %.not.LoSplit, zeroinitializer
  %int_emu.cmp.eq. = and <1 x i1> %50, %49
  %int_emu.cmp.eq..toi = bitcast <1 x i1> %int_emu.cmp.eq. to i1
  %51 = select i1 %int_emu.cmp.eq..toi, i32 0, i32 %8
  %52 = add nsw i32 %47, %51, !spirv.Decorations !22
  %53 = sext i32 %1 to i64
  %.bitcast480 = bitcast i32 %1 to <1 x i32>
  %54 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast480, <1 x i32> splat (i32 24), <1 x i32> zeroinitializer)
  %.lo482 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %54, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.imul161.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo482, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi481 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %54, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.imul161.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.imul161.partial_join, <1 x i32> %.hi481, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.imul161.recast = bitcast <2 x i32> %.imul161.joined to i64
  %55 = add nsw i32 %8, -1, !spirv.Decorations !22
  %56 = sext i32 %10 to i64
  %57 = sext i32 %55 to i64
  %58 = sub nsw i64 %56, %57
  %.iv32cast471 = bitcast i64 %58 to <2 x i32>
  %.LoSplit469 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.imul161.joined, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.LoSplit472 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast471, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %59 = call <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32> %.LoSplit469, <1 x i32> %.LoSplit472, <1 x i32> zeroinitializer)
  %.LoSplit469695 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.imul161.joined, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.HiSplit473 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast471, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %60 = mul <1 x i32> %.LoSplit469695, %.HiSplit473
  %.HiSplit470 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.imul161.joined, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %.LoSplit472694 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast471, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %61 = mul <1 x i32> %.HiSplit470, %.LoSplit472694
  %.lo479 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %59, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %mul64partial_join474 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo479, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi478 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %59, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %62 = call <1 x i32> @llvm.genx.add3.v1i32.v1i32(<1 x i32> %61, <1 x i32> %.hi478, <1 x i32> %60)
  %mul64joined475 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %mul64partial_join474, <1 x i32> %62, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %mul64recast477 = bitcast <2 x i32> %mul64joined475 to i64
  %63 = sext i32 %52 to i64
  %64 = sext i32 %43 to i64
  %.bitcast464 = bitcast i32 %44 to <1 x i32>
  %.bitcast465 = bitcast i32 %10 to <1 x i32>
  %65 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast464, <1 x i32> %.bitcast465, <1 x i32> zeroinitializer)
  %.lo467 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %65, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.imul162.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo467, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi466 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %65, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.imul162.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.imul162.partial_join, <1 x i32> %.hi466, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.imul162.recast = bitcast <2 x i32> %.imul162.joined to i64
  %66 = sext i32 %52 to i64
  %reass.add = add nsw i64 %.imul162.recast, %66
  %reass.mul.iv32cast = bitcast i64 %reass.add to <2 x i32>
  %reass.mul.iv32cast455 = bitcast i64 %53 to <2 x i32>
  %reass.mul.LoSplit = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %reass.mul.iv32cast, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %reass.mul.LoSplit456 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %reass.mul.iv32cast455, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %67 = call <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32> %reass.mul.LoSplit, <1 x i32> %reass.mul.LoSplit456, <1 x i32> zeroinitializer)
  %reass.mul.LoSplit693 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %reass.mul.iv32cast, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %reass.mul.HiSplit457 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %reass.mul.iv32cast455, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %68 = mul <1 x i32> %reass.mul.LoSplit693, %reass.mul.HiSplit457
  %reass.mul.HiSplit = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %reass.mul.iv32cast, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %reass.mul.LoSplit456692 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %reass.mul.iv32cast455, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %69 = mul <1 x i32> %reass.mul.HiSplit, %reass.mul.LoSplit456692
  %.lo463 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %67, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %mul64partial_join458 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo463, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi462 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %67, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %70 = call <1 x i32> @llvm.genx.add3.v1i32.v1i32(<1 x i32> %69, <1 x i32> %.hi462, <1 x i32> %68)
  %mul64joined459 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %mul64partial_join458, <1 x i32> %70, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %mul64recast461 = bitcast <2 x i32> %mul64joined459 to i64
  %71 = sext i32 %43 to i64
  %72 = add i64 %mul64recast461, %71
  %.idx.iv32cast = bitcast i64 %72 to <2 x i32>
  %.idx.LoSplit = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.idx.iv32cast, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %73 = call <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32> %.idx.LoSplit, <1 x i32> splat (i32 96), <1 x i32> zeroinitializer)
  %.idx.HiSplit = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.idx.iv32cast, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %74 = mul <1 x i32> %.idx.HiSplit, splat (i32 96)
  %.lo454 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %73, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %mul64partial_join449 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo454, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi453 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %73, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %75 = add <1 x i32> %74, %.hi453
  %mul64joined450 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %mul64partial_join449, <1 x i32> %75, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %mul64recast452 = bitcast <2 x i32> %mul64joined450 to i64
  %76 = add i64 %int_emu.select.recast, %mul64recast452
  %77 = call <8 x i64> @llvm.vc.internal.lsc.load.ugm.v8i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %76, i16 1, i32 0, <8 x i64> undef)
  %.decomp.1633 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v8i64.i16.i1(<12 x i64> undef, <8 x i64> %77, i32 0, i32 8, i32 1, i16 0, i32 undef, i1 true)
  %78 = call <4 x i64> @llvm.vc.internal.lsc.load.ugm.v4i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 4, <2 x i8> zeroinitializer, i64 0, i64 %76, i16 1, i32 64, <4 x i64> undef)
  %.decomp.1634 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v4i64.i16.i1(<12 x i64> %.decomp.1633, <4 x i64> %78, i32 0, i32 4, i32 1, i16 64, i32 undef, i1 true)
  %.postcast522.decomp.1 = bitcast <12 x i64> %.decomp.1634 to <24 x i32>
  %79 = icmp eq i32 %8, 1
  %..imul161.LoSplit = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %mul64joined475, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.LoSplit469691 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.imul161.joined, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %sel.lo588 = select i1 %79, <1 x i32> %..imul161.LoSplit, <1 x i32> %.LoSplit469691
  %twoaddr = bitcast <2 x i32> %.imul161.joined to <2 x i32>
  %int_emu.select.partial_join590 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %twoaddr, <1 x i32> %sel.lo588, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %..imul161.HiSplit = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %mul64joined475, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %.HiSplit470690 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %int_emu.select.partial_join590, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %sel.hi589 = select i1 %79, <1 x i32> %..imul161.HiSplit, <1 x i32> %.HiSplit470690
  %int_emu.select.joined591 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %int_emu.select.partial_join590, <1 x i32> %sel.hi589, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %int_emu.select.recast593 = bitcast <2 x i32> %int_emu.select.joined591 to i64
  %80 = shl i64 %int_emu.select.recast593, 2
  %81 = add i64 %76, %80
  %.81618 = inttoptr i64 %81 to ptr addrspace(1)
  %82 = call i32 @llvm.genx.constanti.i32(i32 0)
  %83 = call i32 @llvm.genx.constanti.i32(i32 0)
  %84 = call i32 @llvm.genx.constanti.i32(i32 1)
  br i1 %79, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3_crit_edge, label %85

85:                                               ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5
  %86 = call <8 x i64> @llvm.vc.internal.lsc.load.ugm.v8i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %81, i16 1, i32 0, <8 x i64> undef)
  %.decomp.1637 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v8i64.i16.i1(<12 x i64> undef, <8 x i64> %86, i32 0, i32 8, i32 1, i16 0, i32 undef, i1 true)
  %87 = call <4 x i64> @llvm.vc.internal.lsc.load.ugm.v4i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 4, <2 x i8> zeroinitializer, i64 0, i64 %81, i16 1, i32 64, <4 x i64> undef)
  %.decomp.1638 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v4i64.i16.i1(<12 x i64> %.decomp.1637, <4 x i64> %87, i32 0, i32 4, i32 1, i16 64, i32 undef, i1 true)
  %.postcast519.decomp.1 = bitcast <12 x i64> %.decomp.1638 to <24 x i32>
  %88 = icmp eq i32 %8, 2
  br i1 %88, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread, label %89

89:                                               ; preds = %85
  %90 = shl i64 %.imul161.recast, 2
  %91 = add i64 %81, %90
  %92 = call <8 x i64> @llvm.vc.internal.lsc.load.ugm.v8i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %91, i16 1, i32 0, <8 x i64> undef)
  %.decomp.1641 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v8i64.i16.i1(<12 x i64> undef, <8 x i64> %92, i32 0, i32 8, i32 1, i16 0, i32 undef, i1 true)
  %93 = call <4 x i64> @llvm.vc.internal.lsc.load.ugm.v4i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 4, <2 x i8> zeroinitializer, i64 0, i64 %91, i16 1, i32 64, <4 x i64> undef)
  %.decomp.1642 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v4i64.i16.i1(<12 x i64> %.decomp.1641, <4 x i64> %93, i32 0, i32 4, i32 1, i16 64, i32 undef, i1 true)
  %.postcast516.decomp.1 = bitcast <12 x i64> %.decomp.1642 to <24 x i32>
  %94 = icmp eq i32 %8, 3
  br i1 %94, label %108, label %95

95:                                               ; preds = %89
  %96 = add i64 %91, %90
  %97 = call <8 x i64> @llvm.vc.internal.lsc.load.ugm.v8i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %96, i16 1, i32 0, <8 x i64> undef)
  %.decomp.1645 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v8i64.i16.i1(<12 x i64> undef, <8 x i64> %97, i32 0, i32 8, i32 1, i16 0, i32 undef, i1 true)
  %98 = call <4 x i64> @llvm.vc.internal.lsc.load.ugm.v4i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 4, <2 x i8> zeroinitializer, i64 0, i64 %96, i16 1, i32 64, <4 x i64> undef)
  %.decomp.1646 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v4i64.i16.i1(<12 x i64> %.decomp.1645, <4 x i64> %98, i32 0, i32 4, i32 1, i16 64, i32 undef, i1 true)
  %.postcast513.decomp.1 = bitcast <12 x i64> %.decomp.1646 to <24 x i32>
  %99 = icmp eq i32 %8, 4
  br i1 %99, label %104, label %100

100:                                              ; preds = %95
  %101 = add i64 %96, %90
  %102 = inttoptr i64 %101 to ptr addrspace(1)
  %103 = call i32 @llvm.genx.constanti.i32(i32 4)
  %phicopy711 = bitcast i32 %83 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3

104:                                              ; preds = %95
  %105 = shl i64 %mul64recast477, 2
  %106 = add i64 %96, %105
  %107 = inttoptr i64 %106 to ptr addrspace(1)
  %phicopy705 = bitcast i32 %82 to i32
  %phicopy720 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3

108:                                              ; preds = %89
  %109 = shl i64 %mul64recast477, 2
  %110 = add i64 %91, %109
  %111 = inttoptr i64 %110 to ptr addrspace(1)
  %phicopy704 = bitcast i32 %82 to i32
  %phicopy719 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread: ; preds = %85
  %112 = shl i64 %mul64recast477, 2
  %113 = add i64 %81, %112
  %114 = inttoptr i64 %113 to ptr addrspace(1)
  %phicopy703 = bitcast i32 %82 to i32
  %phicopy718 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3_crit_edge: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5
  %phicopy = bitcast i32 %82 to i32
  %phicopy717 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3_crit_edge, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread, %108, %104, %100
  %.sroa.12138.0179.decomp.1 = phi <24 x i32> [ %.postcast516.decomp.1, %100 ], [ %.postcast516.decomp.1, %104 ], [ undef, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ %.postcast516.decomp.1, %108 ], [ undef, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3_crit_edge ]
  %.sroa.7136.0170178.decomp.1 = phi <24 x i32> [ %.postcast519.decomp.1, %100 ], [ %.postcast519.decomp.1, %104 ], [ %.postcast519.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ %.postcast519.decomp.1, %108 ], [ undef, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3_crit_edge ]
  %.sroa.17140.0.decomp.1 = phi <24 x i32> [ %.postcast513.decomp.1, %100 ], [ %.postcast513.decomp.1, %104 ], [ undef, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ undef, %108 ], [ undef, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3_crit_edge ]
  %.81627.3 = phi i32 [ %103, %100 ], [ %phicopy705, %104 ], [ %phicopy703, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ %phicopy704, %108 ], [ %phicopy, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3_crit_edge ]
  %.81618.3 = phi ptr addrspace(1) [ %102, %100 ], [ %107, %104 ], [ %114, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ %111, %108 ], [ %.81618, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3_crit_edge ]
  %.8.3 = phi i32 [ %phicopy711, %100 ], [ %phicopy720, %104 ], [ %phicopy718, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ %phicopy719, %108 ], [ %phicopy717, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3_crit_edge ]
  %115 = bitcast i32 %9 to <1 x i32>
  %116 = call <1 x i32> @llvm.genx.constanti.v1i32(<1 x i32> splat (i32 19))
  %.constsplat610 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %116, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %constant = call <16 x i32> @llvm.genx.wrconstregion.v16i32.v8i32.i16.i1(<16 x i32> %.constsplat610, <8 x i32> splat (i32 31), i32 1, i32 8, i32 1, i16 32, i32 undef, i1 true)
  %117 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %115, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %118 = add <16 x i32> %117, %constant
  %119 = call <1 x i32> @llvm.genx.constanti.v1i32(<1 x i32> splat (i32 13))
  %.constsplat612 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %119, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %constant613 = call <16 x i32> @llvm.genx.wrconstregion.v16i32.v8i32.i16.i1(<16 x i32> %.constsplat612, <8 x i32> splat (i32 1), i32 1, i32 8, i32 1, i16 32, i32 undef, i1 true)
  %120 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %115, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %121 = add <16 x i32> %120, %constant613
  %122 = call <1 x i32> @llvm.genx.constanti.v1i32(<1 x i32> splat (i32 11))
  %.constsplat615 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %122, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %constant616 = call <16 x i32> @llvm.genx.wrconstregion.v16i32.v8i32.i16.i1(<16 x i32> %.constsplat615, <8 x i32> splat (i32 23), i32 1, i32 8, i32 1, i16 32, i32 undef, i1 true)
  %123 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %115, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %124 = add <16 x i32> %123, %constant616
  %125 = call <1 x i32> @llvm.genx.constanti.v1i32(<1 x i32> splat (i32 21))
  %.constsplat618 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %125, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %constant619 = call <16 x i32> @llvm.genx.wrconstregion.v16i32.v8i32.i16.i1(<16 x i32> %.constsplat618, <8 x i32> splat (i32 9), i32 1, i32 8, i32 1, i16 32, i32 undef, i1 true)
  %126 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %115, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %127 = add <16 x i32> %126, %constant619
  %128 = call <1 x i32> @llvm.genx.constanti.v1i32(<1 x i32> splat (i32 3))
  %.constsplat621 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %128, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %constant622 = call <16 x i32> @llvm.genx.wrconstregion.v16i32.v8i32.i16.i1(<16 x i32> %.constsplat621, <8 x i32> splat (i32 15), i32 1, i32 8, i32 1, i16 32, i32 undef, i1 true)
  %129 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %115, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %130 = add <16 x i32> %129, %constant622
  %131 = call <1 x i32> @llvm.genx.constanti.v1i32(<1 x i32> splat (i32 29))
  %.constsplat624 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %131, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %constant625 = call <16 x i32> @llvm.genx.wrconstregion.v16i32.v8i32.i16.i1(<16 x i32> %.constsplat624, <8 x i32> splat (i32 17), i32 1, i32 8, i32 1, i16 32, i32 undef, i1 true)
  %132 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %115, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %133 = add <16 x i32> %132, %constant625
  %134 = call <1 x i32> @llvm.genx.constanti.v1i32(<1 x i32> splat (i32 27))
  %.constsplat627 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %134, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %constant628 = call <16 x i32> @llvm.genx.wrconstregion.v16i32.v8i32.i16.i1(<16 x i32> %.constsplat627, <8 x i32> splat (i32 7), i32 1, i32 8, i32 1, i16 32, i32 undef, i1 true)
  %135 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %115, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %136 = add <16 x i32> %135, %constant628
  %137 = call <1 x i32> @llvm.genx.constanti.v1i32(<1 x i32> splat (i32 5))
  %.constsplat630 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %137, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %constant631 = call <16 x i32> @llvm.genx.wrconstregion.v16i32.v8i32.i16.i1(<16 x i32> %.constsplat630, <8 x i32> splat (i32 25), i32 1, i32 8, i32 1, i16 32, i32 undef, i1 true)
  %138 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32> %115, i32 0, i32 16, i32 0, i16 0, i32 undef)
  %139 = add <16 x i32> %138, %constant631
  %.idx2 = shl nsw i64 %63, 10
  %140 = ptrtoint ptr addrspace(4) %14 to i64
  %141 = add i64 %140, %.idx2
  %142 = inttoptr i64 %141 to ptr addrspace(4)
  %143 = icmp sgt i32 %8, 0
  br i1 %143, label %.lr.ph.preheader, label %._crit_edge

.lr.ph.preheader:                                 ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3
  %144 = ptrtoint ptr addrspace(1) %4 to i64
  %145 = ptrtoint ptr addrspace(1) %5 to i64
  %.iv32cast594 = bitcast i64 %144 to <2 x i32>
  %.iv32cast597 = bitcast i64 %145 to <2 x i32>
  %.LoSplit595 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast594, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.LoSplit598 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast597, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %sel.lo600 = select i1 %41, <1 x i32> %.LoSplit595, <1 x i32> %.LoSplit598
  %int_emu.select.partial_join602 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.iv32cast597, <1 x i32> %sel.lo600, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.HiSplit596 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast594, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %.HiSplit599 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %int_emu.select.partial_join602, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %sel.hi601 = select i1 %41, <1 x i32> %.HiSplit596, <1 x i32> %.HiSplit599
  %int_emu.select.joined603 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %int_emu.select.partial_join602, <1 x i32> %sel.hi601, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %int_emu.select.recast605 = bitcast <2 x i32> %int_emu.select.joined603 to i64
  %146 = sext i32 %46 to i64
  %147 = shl nsw i64 %146, 1
  %.cast606 = bitcast i64 %147 to <2 x i32>
  %int_emu.607 = or <2 x i32> %.cast606, %int_emu.
  %148 = sext i32 %12 to i64
  %.iv32cast440 = bitcast i64 %148 to <2 x i32>
  %.LoSplit438 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %int_emu.607, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.LoSplit441 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast440, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %149 = call <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32> %.LoSplit438, <1 x i32> %.LoSplit441, <1 x i32> zeroinitializer)
  %.LoSplit438689 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %int_emu.607, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.HiSplit442 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast440, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %150 = mul <1 x i32> %.LoSplit438689, %.HiSplit442
  %.HiSplit439 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %int_emu.607, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %.LoSplit441688 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast440, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %151 = mul <1 x i32> %.HiSplit439, %.LoSplit441688
  %.lo448 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %149, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %mul64partial_join443 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo448, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi447 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %149, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %152 = call <1 x i32> @llvm.genx.add3.v1i32.v1i32(<1 x i32> %151, <1 x i32> %.hi447, <1 x i32> %150)
  %mul64joined444 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %mul64partial_join443, <1 x i32> %152, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %mul64recast446 = bitcast <2 x i32> %mul64joined444 to i64
  %153 = sext i32 %13 to i64
  %154 = shl nsw i64 %153, 4
  %.idx3 = shl nsw i64 %64, 6
  %155 = add i64 %int_emu.select.recast605, %.idx3
  %.idx138 = shl nsw i64 %153, 3
  %.idx144 = shl nsw i64 %153, 5
  %156 = shl i64 %.imul161.recast, 2
  %157 = shl i64 %mul64recast477, 2
  %.iv32cast428 = bitcast i64 %154 to <2 x i32>
  %158 = shl i64 %153, 2
  %.bitcast422 = bitcast i32 %13 to <1 x i32>
  %159 = call i32 @llvm.genx.constanti.i32(i32 0)
  %160 = call i32 @llvm.genx.constanti.i32(i32 0)
  %161 = call i32 @llvm.genx.constanti.i32(i32 0)
  %phicopy731 = bitcast i32 %160 to i32
  %phicopy745 = bitcast ptr addrspace(4) %142 to ptr addrspace(4)
  br label %.lr.ph

.lr.ph:                                           ; preds = %861, %.lr.ph.preheader
  %.sroa.22.0 = phi <128 x i32> [ %.sroa.22.6, %861 ], [ undef, %.lr.ph.preheader ]
  %.sroa.0.0 = phi <128 x i32> [ %.sroa.0.6, %861 ], [ undef, %.lr.ph.preheader ]
  %.esimd23466.decomp.0 = phi <16 x i32> [ %.esimd23465.decomp.0, %861 ], [ undef, %.lr.ph.preheader ]
  %.esimd23466.decomp.1 = phi <24 x i32> [ %.esimd23465.decomp.1, %861 ], [ %.sroa.17140.0.decomp.1, %.lr.ph.preheader ]
  %.esimd18262.decomp.0 = phi <16 x i32> [ %.esimd18261.decomp.0, %861 ], [ undef, %.lr.ph.preheader ]
  %.esimd18262.decomp.1 = phi <24 x i32> [ %.esimd18261.decomp.1, %861 ], [ %.sroa.12138.0179.decomp.1, %.lr.ph.preheader ]
  %.esimd13058.decomp.0 = phi <16 x i32> [ %.esimd13057.decomp.0, %861 ], [ undef, %.lr.ph.preheader ]
  %.esimd13058.decomp.1 = phi <24 x i32> [ %.esimd13057.decomp.1, %861 ], [ %.sroa.7136.0170178.decomp.1, %.lr.ph.preheader ]
  %.esimd7849.decomp.0 = phi <16 x i32> [ %.esimd7850.decomp.0, %861 ], [ undef, %.lr.ph.preheader ]
  %.esimd7849.decomp.1 = phi <24 x i32> [ %.esimd7850.decomp.1, %861 ], [ %.postcast522.decomp.1, %.lr.ph.preheader ]
  %.esimd23845.decomp.0 = phi <16 x i32> [ %.esimd23846.decomp.0, %861 ], [ undef, %.lr.ph.preheader ]
  %.esimd23845.decomp.1 = phi <24 x i32> [ %.esimd23847.decomp.1, %861 ], [ undef, %.lr.ph.preheader ]
  %162 = phi i32 [ %865, %861 ], [ %159, %.lr.ph.preheader ]
  %163 = phi i32 [ %864, %861 ], [ %phicopy731, %.lr.ph.preheader ]
  %164 = phi i32 [ %863, %861 ], [ %161, %.lr.ph.preheader ]
  %165 = phi ptr addrspace(4) [ %862, %861 ], [ %phicopy745, %.lr.ph.preheader ]
  %.114 = phi i32 [ %.2, %861 ], [ %.8.3, %.lr.ph.preheader ]
  %.1161113 = phi ptr addrspace(1) [ %.21612, %861 ], [ %.81618.3, %.lr.ph.preheader ]
  %.1162012 = phi i32 [ %.21621, %861 ], [ %.81627.3, %.lr.ph.preheader ]
  %166 = icmp eq i32 %163, 0
  %167 = select i1 %166, <1 x i32> splat (i32 -1), <1 x i32> zeroinitializer
  %.sroa.22.0.split0 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %.sroa.22.0, i32 32, i32 32, i32 1, i16 0, i32 undef)
  %.split0570 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v1i32.i16(<1 x i32> %167, i32 0, i32 1, i32 0, i16 0, i32 undef)
  %.split0571 = xor <32 x i32> %.split0570, splat (i32 -1)
  %spec.select.split0 = and <32 x i32> %.sroa.22.0.split0, %.split0571
  %spec.select.split0.join0 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %.sroa.22.0, <32 x i32> %spec.select.split0, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %.sroa.22.0.split32 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %spec.select.split0.join0, i32 32, i32 32, i32 1, i16 128, i32 undef)
  %.split0570687 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v1i32.i16(<1 x i32> %167, i32 0, i32 1, i32 0, i16 0, i32 undef)
  %.split0571686 = xor <32 x i32> %.split0570687, splat (i32 -1)
  %spec.select.split32 = and <32 x i32> %.sroa.22.0.split32, %.split0571686
  %spec.select.split32.join32 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %spec.select.split0.join0, <32 x i32> %spec.select.split32, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %.sroa.22.0.split64 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %spec.select.split32.join32, i32 32, i32 32, i32 1, i16 256, i32 undef)
  %.split0570685 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v1i32.i16(<1 x i32> %167, i32 0, i32 1, i32 0, i16 0, i32 undef)
  %.split0571684 = xor <32 x i32> %.split0570685, splat (i32 -1)
  %spec.select.split64 = and <32 x i32> %.sroa.22.0.split64, %.split0571684
  %spec.select.split64.join64 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %spec.select.split32.join32, <32 x i32> %spec.select.split64, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %.sroa.22.0.split96 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %spec.select.split64.join64, i32 32, i32 32, i32 1, i16 384, i32 undef)
  %.split0570683 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v1i32.i16(<1 x i32> %167, i32 0, i32 1, i32 0, i16 0, i32 undef)
  %.split0571682 = xor <32 x i32> %.split0570683, splat (i32 -1)
  %spec.select.split96 = and <32 x i32> %.sroa.22.0.split96, %.split0571682
  %spec.select.split96.join96 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %spec.select.split64.join64, <32 x i32> %spec.select.split96, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %.sroa.0.0.split0 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %.sroa.0.0, i32 32, i32 32, i32 1, i16 0, i32 undef)
  %.split0570681 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v1i32.i16(<1 x i32> %167, i32 0, i32 1, i32 0, i16 0, i32 undef)
  %.split0571680 = xor <32 x i32> %.split0570681, splat (i32 -1)
  %spec.select164.split0 = and <32 x i32> %.sroa.0.0.split0, %.split0571680
  %spec.select164.split0.join0 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %.sroa.0.0, <32 x i32> %spec.select164.split0, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %.sroa.0.0.split32 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %spec.select164.split0.join0, i32 32, i32 32, i32 1, i16 128, i32 undef)
  %.split0570679 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v1i32.i16(<1 x i32> %167, i32 0, i32 1, i32 0, i16 0, i32 undef)
  %.split0571678 = xor <32 x i32> %.split0570679, splat (i32 -1)
  %spec.select164.split32 = and <32 x i32> %.sroa.0.0.split32, %.split0571678
  %spec.select164.split32.join32 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %spec.select164.split0.join0, <32 x i32> %spec.select164.split32, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %.sroa.0.0.split64 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %spec.select164.split32.join32, i32 32, i32 32, i32 1, i16 256, i32 undef)
  %.split0570677 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v1i32.i16(<1 x i32> %167, i32 0, i32 1, i32 0, i16 0, i32 undef)
  %.split0571676 = xor <32 x i32> %.split0570677, splat (i32 -1)
  %spec.select164.split64 = and <32 x i32> %.sroa.0.0.split64, %.split0571676
  %spec.select164.split64.join64 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %spec.select164.split32.join32, <32 x i32> %spec.select164.split64, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %.sroa.0.0.split96 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %spec.select164.split64.join64, i32 32, i32 32, i32 1, i16 384, i32 undef)
  %.split0570675 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v1i32.i16(<1 x i32> %167, i32 0, i32 1, i32 0, i16 0, i32 undef)
  %.split0571674 = xor <32 x i32> %.split0570675, splat (i32 -1)
  %spec.select164.split96 = and <32 x i32> %.sroa.0.0.split96, %.split0571674
  %spec.select164.split96.join96 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %spec.select164.split64.join64, <32 x i32> %spec.select164.split96, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %168 = call i1 @llvm.genx.constantpred.i1(i1 false)
  %.not203 = icmp eq i32 %.114, 0
  br i1 %.not203, label %169, label %.lr.ph._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4_crit_edge

.lr.ph._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4_crit_edge: ; preds = %.lr.ph
  %phicopy721 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4

169:                                              ; preds = %.lr.ph
  %170 = ptrtoint ptr addrspace(1) %.1161113 to i64
  %171 = call <8 x i64> @llvm.vc.internal.lsc.load.ugm.v8i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %170, i16 1, i32 0, <8 x i64> undef)
  %.decomp.1647 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v8i64.i16.i1(<12 x i64> undef, <8 x i64> %171, i32 0, i32 8, i32 1, i16 0, i32 undef, i1 true)
  %172 = call <4 x i64> @llvm.vc.internal.lsc.load.ugm.v4i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 4, <2 x i8> zeroinitializer, i64 0, i64 %170, i16 1, i32 64, <4 x i64> undef)
  %.decomp.1648 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v4i64.i16.i1(<12 x i64> %.decomp.1647, <4 x i64> %172, i32 0, i32 4, i32 1, i16 64, i32 undef, i1 true)
  %.postcast510.decomp.1 = bitcast <12 x i64> %.decomp.1648 to <24 x i32>
  %173 = add nsw i32 %.1162012, 1, !spirv.Decorations !22
  %174 = icmp eq i32 %173, %8
  br i1 %174, label %179, label %175

175:                                              ; preds = %169
  %176 = add i64 %170, %156
  %177 = inttoptr i64 %176 to ptr addrspace(1)
  %178 = call i1 @llvm.genx.constantpred.i1(i1 true)
  %phicopy712 = bitcast i32 %83 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4

179:                                              ; preds = %169
  %180 = add i64 %170, %157
  %181 = inttoptr i64 %180 to ptr addrspace(1)
  %phicopy706 = bitcast i32 %82 to i32
  %phicopy722 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4: ; preds = %.lr.ph._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4_crit_edge, %175, %179
  %.esimd23847.decomp.0 = phi <16 x i32> [ %.esimd23845.decomp.0, %.lr.ph._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4_crit_edge ], [ undef, %179 ], [ undef, %175 ]
  %.esimd23847.decomp.1 = phi <24 x i32> [ %.esimd23845.decomp.1, %.lr.ph._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4_crit_edge ], [ %.postcast510.decomp.1, %179 ], [ %.postcast510.decomp.1, %175 ]
  %.71626 = phi i32 [ %.1162012, %.lr.ph._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4_crit_edge ], [ %phicopy706, %179 ], [ %173, %175 ]
  %.71617 = phi ptr addrspace(1) [ %.1161113, %.lr.ph._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4_crit_edge ], [ %181, %179 ], [ %177, %175 ]
  %.not159 = phi i1 [ %168, %.lr.ph._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4_crit_edge ], [ %168, %179 ], [ %178, %175 ], !pred.index !24
  %.7 = phi i32 [ %phicopy721, %.lr.ph._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4_crit_edge ], [ %phicopy722, %179 ], [ %phicopy712, %175 ]
  %.esimd27.split0 = call <4 x i32> @llvm.genx.rdregioni.v4i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 4, i32 1, i16 64, i32 undef)
  %.esimd28.join0.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v4i32.i16.i1(<16 x i32> %.esimd7849.decomp.0, <4 x i32> %.esimd27.split0, i32 0, i32 4, i32 1, i16 36, i32 undef, i1 true)
  %.esimd27.split4 = call <2 x i32> @llvm.genx.rdregioni.v2i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 2, i32 1, i16 80, i32 undef)
  %.esimd28.join4.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v2i32.i16.i1(<16 x i32> %.esimd28.join0.decomp.0, <2 x i32> %.esimd27.split4, i32 0, i32 2, i32 1, i16 52, i32 undef, i1 true)
  %.esimd27.split6 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 1, i32 1, i16 88, i32 undef)
  %.esimd28.join6.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32> %.esimd28.join4.decomp.0, <1 x i32> %.esimd27.split6, i32 0, i32 1, i32 1, i16 60, i32 undef, i1 true)
  %.esimd29 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 1, i32 1, i16 92, i32 undef)
  %.esimd30.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32> %.esimd28.join6.decomp.0, <1 x i32> %.esimd29, i32 0, i32 1, i32 1, i16 32, i32 undef, i1 true)
  %.esimd31 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v16i32.i16(<16 x i32> %.esimd30.decomp.0, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %182 = shl <16 x i32> %.esimd31, %118
  %.esimd32 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 8, i32 1, i16 0, i32 undef)
  %183 = lshr <16 x i32> %.esimd32, %121
  %184 = or <16 x i32> %183, %182
  %185 = bitcast <16 x i32> %184 to <32 x i16>
  %.esimd33 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %185, i32 0, i32 16, i32 2, i16 2, i32 0)
  %186 = zext <16 x i16> %.esimd33 to <16 x i32>
  %187 = mul <16 x i32> %186, splat (i32 -2082680531)
  %.esimd34 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> undef, <16 x i32> %187, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %188 = lshr <16 x i32> %184, splat (i32 13)
  %189 = bitcast <16 x i32> %188 to <32 x i16>
  %.esimd35 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %189, i32 0, i32 16, i32 2, i16 0, i32 0)
  %190 = zext <16 x i16> %.esimd35 to <16 x i32>
  %191 = mul <16 x i32> %190, splat (i32 -2082680531)
  %.esimd36 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd34, <16 x i32> %191, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %192 = lshr <16 x i32> %184, splat (i32 10)
  %193 = bitcast <16 x i32> %192 to <32 x i16>
  %.esimd37 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %193, i32 0, i32 16, i32 2, i16 0, i32 0)
  %194 = zext <16 x i16> %.esimd37 to <16 x i32>
  %195 = mul <16 x i32> %194, splat (i32 -2082680531)
  %.esimd38 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> undef, <16 x i32> %195, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %196 = lshr <16 x i32> %184, splat (i32 7)
  %197 = bitcast <16 x i32> %196 to <32 x i16>
  %.esimd39 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %197, i32 0, i32 16, i32 2, i16 0, i32 0)
  %198 = zext <16 x i16> %.esimd39 to <16 x i32>
  %199 = mul <16 x i32> %198, splat (i32 -2082680531)
  %.esimd40 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd38, <16 x i32> %199, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %.esimd32673 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 8, i32 1, i16 0, i32 undef)
  %200 = shl <16 x i32> %.esimd32673, %124
  %.esimd42 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %201 = lshr <16 x i32> %.esimd42, %127
  %202 = or <16 x i32> %201, %200
  %203 = bitcast <16 x i32> %202 to <32 x i16>
  %.esimd43 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %203, i32 0, i32 16, i32 2, i16 2, i32 0)
  %204 = zext <16 x i16> %.esimd43 to <16 x i32>
  %205 = mul <16 x i32> %204, splat (i32 -2082680531)
  %.esimd44 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd36, <16 x i32> %205, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %206 = lshr <16 x i32> %202, splat (i32 13)
  %207 = bitcast <16 x i32> %206 to <32 x i16>
  %.esimd45 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %207, i32 0, i32 16, i32 2, i16 0, i32 0)
  %208 = zext <16 x i16> %.esimd45 to <16 x i32>
  %209 = mul <16 x i32> %208, splat (i32 -2082680531)
  %.esimd46 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd44, <16 x i32> %209, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %210 = lshr <16 x i32> %202, splat (i32 10)
  %211 = bitcast <16 x i32> %210 to <32 x i16>
  %.esimd47 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %211, i32 0, i32 16, i32 2, i16 0, i32 0)
  %212 = zext <16 x i16> %.esimd47 to <16 x i32>
  %213 = mul <16 x i32> %212, splat (i32 -2082680531)
  %.esimd48 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd40, <16 x i32> %213, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %214 = lshr <16 x i32> %202, splat (i32 7)
  %215 = bitcast <16 x i32> %214 to <32 x i16>
  %.esimd49 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %215, i32 0, i32 16, i32 2, i16 0, i32 0)
  %216 = zext <16 x i16> %.esimd49 to <16 x i32>
  %217 = mul <16 x i32> %216, splat (i32 -2082680531)
  %.esimd50 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd48, <16 x i32> %217, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %.esimd42672 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %218 = shl <16 x i32> %.esimd42672, %130
  %.esimd52 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 8, i32 1, i16 64, i32 undef)
  %219 = lshr <16 x i32> %.esimd52, %133
  %220 = or <16 x i32> %219, %218
  %221 = bitcast <16 x i32> %220 to <32 x i16>
  %.esimd53 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %221, i32 0, i32 16, i32 2, i16 2, i32 0)
  %222 = zext <16 x i16> %.esimd53 to <16 x i32>
  %223 = mul <16 x i32> %222, splat (i32 -2082680531)
  %.esimd54 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd46, <16 x i32> %223, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %224 = lshr <16 x i32> %220, splat (i32 13)
  %225 = bitcast <16 x i32> %224 to <32 x i16>
  %.esimd55 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %225, i32 0, i32 16, i32 2, i16 0, i32 0)
  %226 = zext <16 x i16> %.esimd55 to <16 x i32>
  %227 = mul <16 x i32> %226, splat (i32 -2082680531)
  %.esimd56 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd54, <16 x i32> %227, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %228 = lshr <16 x i32> %220, splat (i32 10)
  %229 = bitcast <16 x i32> %228 to <32 x i16>
  %.esimd57 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %229, i32 0, i32 16, i32 2, i16 0, i32 0)
  %230 = zext <16 x i16> %.esimd57 to <16 x i32>
  %231 = mul <16 x i32> %230, splat (i32 -2082680531)
  %.esimd58 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd50, <16 x i32> %231, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %232 = lshr <16 x i32> %220, splat (i32 7)
  %233 = bitcast <16 x i32> %232 to <32 x i16>
  %.esimd59 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %233, i32 0, i32 16, i32 2, i16 0, i32 0)
  %234 = zext <16 x i16> %.esimd59 to <16 x i32>
  %235 = mul <16 x i32> %234, splat (i32 -2082680531)
  %.esimd60 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd58, <16 x i32> %235, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %.esimd61 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 16, i32 1, i16 32, i32 undef)
  %236 = shl <16 x i32> %.esimd61, %136
  %.esimd52671 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd7849.decomp.1, i32 0, i32 8, i32 1, i16 64, i32 undef)
  %237 = lshr <16 x i32> %.esimd52671, %139
  %238 = or <16 x i32> %236, %237
  %239 = bitcast <16 x i32> %238 to <32 x i16>
  %.esimd63 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %239, i32 0, i32 16, i32 2, i16 2, i32 0)
  %240 = zext <16 x i16> %.esimd63 to <16 x i32>
  %241 = mul <16 x i32> %240, splat (i32 -2082680531)
  %.esimd64 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd56, <16 x i32> %241, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %242 = lshr <16 x i32> %238, splat (i32 13)
  %243 = bitcast <16 x i32> %242 to <32 x i16>
  %.esimd65 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %243, i32 0, i32 16, i32 2, i16 0, i32 0)
  %244 = zext <16 x i16> %.esimd65 to <16 x i32>
  %245 = mul <16 x i32> %244, splat (i32 -2082680531)
  %.esimd66 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd64, <16 x i32> %245, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %246 = lshr <16 x i32> %238, splat (i32 10)
  %247 = bitcast <16 x i32> %246 to <32 x i16>
  %.esimd67 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %247, i32 0, i32 16, i32 2, i16 0, i32 0)
  %248 = zext <16 x i16> %.esimd67 to <16 x i32>
  %249 = mul <16 x i32> %248, splat (i32 -2082680531)
  %.esimd68 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd60, <16 x i32> %249, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %250 = lshr <16 x i32> %238, splat (i32 7)
  %251 = bitcast <16 x i32> %250 to <32 x i16>
  %.esimd69 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %251, i32 0, i32 16, i32 2, i16 0, i32 0)
  %252 = zext <16 x i16> %.esimd69 to <16 x i32>
  %253 = mul <16 x i32> %252, splat (i32 -2082680531)
  %.esimd70 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd68, <16 x i32> %253, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %254 = ptrtoint ptr addrspace(4) %165 to i64
  %255 = call <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 8, <2 x i8> zeroinitializer, i64 0, i64 %254, i16 1, i32 0, <64 x i64> undef)
  %256 = call <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 8, <2 x i8> zeroinitializer, i64 0, i64 %254, i16 1, i32 512, <64 x i64> undef)
  %.postcast506.decomp.0 = bitcast <64 x i64> %255 to <128 x i32>
  %.postcast506.decomp.1 = bitcast <64 x i64> %256 to <128 x i32>
  %.esimd73 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast506.decomp.0, i32 0, i32 64, i32 1, i16 0, i32 undef)
  %.esimd74 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %spec.select164.split96.join96, <128 x i32> %.esimd66, <64 x i32> %.esimd73, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd73.1 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast506.decomp.0, i32 0, i32 64, i32 1, i16 256, i32 undef)
  %.esimd74.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %spec.select.split96.join96, <128 x i32> %.esimd66, <64 x i32> %.esimd73.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd73.1123 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast506.decomp.1, i32 0, i32 64, i32 1, i16 0, i32 undef)
  %.esimd74.1124 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd74, <128 x i32> %.esimd70, <64 x i32> %.esimd73.1123, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd73.1.1 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast506.decomp.1, i32 0, i32 64, i32 1, i16 256, i32 undef)
  %.esimd74.1.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd74.1, <128 x i32> %.esimd70, <64 x i32> %.esimd73.1.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %257 = add i64 %254, 1024
  %258 = inttoptr i64 %257 to ptr addrspace(4)
  %259 = add nsw i32 %163, 1, !spirv.Decorations !22
  %constant.split.ill0 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> zeroinitializer, i32 32, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %constant.split.ill32 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %constant.split.ill0, <32 x i32> zeroinitializer, i32 32, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %constant.split.ill64 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %constant.split.ill32, <32 x i32> zeroinitializer, i32 32, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %constant.split.ill96 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %constant.split.ill64, <32 x i32> zeroinitializer, i32 32, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %constant.split.ill0696 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> zeroinitializer, i32 32, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %constant.split.ill32697 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %constant.split.ill0696, <32 x i32> zeroinitializer, i32 32, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %constant.split.ill64698 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %constant.split.ill32697, <32 x i32> zeroinitializer, i32 32, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %constant.split.ill96699 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %constant.split.ill64698, <32 x i32> zeroinitializer, i32 32, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %260 = icmp eq i32 %259, %8
  br i1 %260, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13, label %261

261:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4
  %262 = add nuw nsw i32 %162, 1, !spirv.Decorations !25
  %263 = icmp slt i32 %262, %8
  br i1 %263, label %264, label %861

264:                                              ; preds = %261
  %265 = icmp eq i32 %259, 0
  br i1 %265, label %.loopexit3.loopexit, label %.loopexit3

.loopexit3.loopexit:                              ; preds = %264
  %phicopy734 = bitcast i32 %160 to i32
  %phicopy763 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy764 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy763, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy765 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy766 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy764, <32 x i32> %phicopy765, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy767 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy768 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy766, <32 x i32> %phicopy767, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy769 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy770 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy768, <32 x i32> %phicopy769, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %phicopy827 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy828 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy827, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy829 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy830 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy828, <32 x i32> %phicopy829, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy831 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy832 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy830, <32 x i32> %phicopy831, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy833 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy834 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy832, <32 x i32> %phicopy833, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  br label %.loopexit3

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4
  %266 = add nsw i32 %164, %44, !spirv.Decorations !22
  %267 = sext i32 %266 to i64
  %268 = add i64 %mul64recast446, %267
  %.iv32cast425 = bitcast i64 %268 to <2 x i32>
  %.LoSplit426670 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast425, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.HiSplit430 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %269 = mul <1 x i32> %.LoSplit426670, %.HiSplit430
  %.HiSplit427 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast425, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %.LoSplit429669 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %270 = mul <1 x i32> %.HiSplit427, %.LoSplit429669
  %.LoSplit426 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast425, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.LoSplit429 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %271 = call <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32> %.LoSplit426, <1 x i32> %.LoSplit429, <1 x i32> zeroinitializer)
  %.lo436 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %271, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %mul64partial_join431 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo436, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi435 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %271, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %272 = call <1 x i32> @llvm.genx.add3.v1i32.v1i32(<1 x i32> %270, <1 x i32> %.hi435, <1 x i32> %269)
  %mul64joined432 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %mul64partial_join431, <1 x i32> %272, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %mul64recast434 = bitcast <2 x i32> %mul64joined432 to i64
  %273 = shl i64 %mul64recast434, 2
  %274 = add i64 %155, %273
  %275 = bitcast <128 x i32> %.esimd74.1124 to <64 x i64>
  %.esimd75 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %275, i32 0, i32 8, i32 1, i16 0, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %274, i16 1, i32 0, <8 x i64> %.esimd75)
  %276 = add i64 %274, %158
  %.esimd75.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %275, i32 0, i32 8, i32 1, i16 64, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %276, i16 1, i32 0, <8 x i64> %.esimd75.1)
  %277 = add i64 %274, %.idx138
  %.esimd75.2 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %275, i32 0, i32 8, i32 1, i16 128, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %277, i16 1, i32 0, <8 x i64> %.esimd75.2)
  %278 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 12), <1 x i32> zeroinitializer)
  %.lo424 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %278, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx139.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo424, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi423 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %278, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx139.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx139.imul.partial_join, <1 x i32> %.hi423, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx139.imul.recast = bitcast <2 x i32> %.idx139.imul.joined to i64
  %279 = add i64 %274, %.idx139.imul.recast
  %.esimd75.3 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %275, i32 0, i32 8, i32 1, i16 192, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %279, i16 1, i32 0, <8 x i64> %.esimd75.3)
  %280 = add i64 %274, %154
  %.esimd75.4 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %275, i32 0, i32 8, i32 1, i16 256, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %280, i16 1, i32 0, <8 x i64> %.esimd75.4)
  %281 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 20), <1 x i32> zeroinitializer)
  %.lo421 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %281, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx141.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo421, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi420 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %281, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx141.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx141.imul.partial_join, <1 x i32> %.hi420, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx141.imul.recast = bitcast <2 x i32> %.idx141.imul.joined to i64
  %282 = add i64 %274, %.idx141.imul.recast
  %.esimd75.5 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %275, i32 0, i32 8, i32 1, i16 320, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %282, i16 1, i32 0, <8 x i64> %.esimd75.5)
  %283 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 24), <1 x i32> zeroinitializer)
  %.lo418 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %283, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx142.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo418, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi417 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %283, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx142.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx142.imul.partial_join, <1 x i32> %.hi417, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx142.imul.recast = bitcast <2 x i32> %.idx142.imul.joined to i64
  %284 = add i64 %274, %.idx142.imul.recast
  %.esimd75.6 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %275, i32 0, i32 8, i32 1, i16 384, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %284, i16 1, i32 0, <8 x i64> %.esimd75.6)
  %285 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 28), <1 x i32> zeroinitializer)
  %.lo415 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %285, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx143.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo415, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi414 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %285, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx143.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx143.imul.partial_join, <1 x i32> %.hi414, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx143.imul.recast = bitcast <2 x i32> %.idx143.imul.joined to i64
  %286 = add i64 %274, %.idx143.imul.recast
  %.esimd75.7 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %275, i32 0, i32 8, i32 1, i16 448, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %286, i16 1, i32 0, <8 x i64> %.esimd75.7)
  %287 = bitcast <128 x i32> %.esimd74.1.1 to <64 x i64>
  %288 = add i64 %274, %.idx144
  %.esimd75.1125 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %287, i32 0, i32 8, i32 1, i16 0, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %288, i16 1, i32 0, <8 x i64> %.esimd75.1125)
  %289 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 36), <1 x i32> zeroinitializer)
  %.lo412 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %289, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx145.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo412, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi411 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %289, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx145.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx145.imul.partial_join, <1 x i32> %.hi411, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx145.imul.recast = bitcast <2 x i32> %.idx145.imul.joined to i64
  %290 = add i64 %274, %.idx145.imul.recast
  %.esimd75.1.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %287, i32 0, i32 8, i32 1, i16 64, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %290, i16 1, i32 0, <8 x i64> %.esimd75.1.1)
  %291 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 40), <1 x i32> zeroinitializer)
  %.lo409 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %291, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx146.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo409, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi408 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %291, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx146.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx146.imul.partial_join, <1 x i32> %.hi408, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx146.imul.recast = bitcast <2 x i32> %.idx146.imul.joined to i64
  %292 = add i64 %274, %.idx146.imul.recast
  %.esimd75.2.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %287, i32 0, i32 8, i32 1, i16 128, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %292, i16 1, i32 0, <8 x i64> %.esimd75.2.1)
  %293 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 44), <1 x i32> zeroinitializer)
  %.lo406 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %293, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx147.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo406, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi405 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %293, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx147.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx147.imul.partial_join, <1 x i32> %.hi405, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx147.imul.recast = bitcast <2 x i32> %.idx147.imul.joined to i64
  %294 = add i64 %274, %.idx147.imul.recast
  %.esimd75.3.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %287, i32 0, i32 8, i32 1, i16 192, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %294, i16 1, i32 0, <8 x i64> %.esimd75.3.1)
  %295 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 48), <1 x i32> zeroinitializer)
  %.lo403 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %295, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx148.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo403, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi402 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %295, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx148.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx148.imul.partial_join, <1 x i32> %.hi402, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx148.imul.recast = bitcast <2 x i32> %.idx148.imul.joined to i64
  %296 = add i64 %274, %.idx148.imul.recast
  %.esimd75.4.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %287, i32 0, i32 8, i32 1, i16 256, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %296, i16 1, i32 0, <8 x i64> %.esimd75.4.1)
  %297 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 52), <1 x i32> zeroinitializer)
  %.lo400 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %297, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx149.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo400, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi399 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %297, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx149.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx149.imul.partial_join, <1 x i32> %.hi399, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx149.imul.recast = bitcast <2 x i32> %.idx149.imul.joined to i64
  %298 = add i64 %274, %.idx149.imul.recast
  %.esimd75.5.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %287, i32 0, i32 8, i32 1, i16 320, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %298, i16 1, i32 0, <8 x i64> %.esimd75.5.1)
  %299 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 56), <1 x i32> zeroinitializer)
  %.lo397 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %299, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx150.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo397, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi396 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %299, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx150.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx150.imul.partial_join, <1 x i32> %.hi396, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx150.imul.recast = bitcast <2 x i32> %.idx150.imul.joined to i64
  %300 = add i64 %274, %.idx150.imul.recast
  %.esimd75.6.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %287, i32 0, i32 8, i32 1, i16 384, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %300, i16 1, i32 0, <8 x i64> %.esimd75.6.1)
  %301 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 60), <1 x i32> zeroinitializer)
  %.lo394 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %301, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx151.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo394, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi393 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %301, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx151.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx151.imul.partial_join, <1 x i32> %.hi393, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx151.imul.recast = bitcast <2 x i32> %.idx151.imul.joined to i64
  %302 = add i64 %274, %.idx151.imul.recast
  %.esimd75.7.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %287, i32 0, i32 8, i32 1, i16 448, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %302, i16 1, i32 0, <8 x i64> %.esimd75.7.1)
  %303 = add nsw i32 %164, 1, !spirv.Decorations !22
  %304 = add nuw nsw i32 %162, 1, !spirv.Decorations !25
  %305 = icmp slt i32 %304, %8
  br i1 %305, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13..loopexit3_crit_edge, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13
  %phicopy732 = bitcast i32 %160 to i32
  %phicopy746 = bitcast ptr addrspace(4) %142 to ptr addrspace(4)
  br label %861

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13..loopexit3_crit_edge: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13
  %phicopy733 = bitcast i32 %160 to i32
  %phicopy747 = bitcast ptr addrspace(4) %142 to ptr addrspace(4)
  %phicopy755 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy756 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy755, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy757 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy758 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy756, <32 x i32> %phicopy757, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy759 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy760 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy758, <32 x i32> %phicopy759, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy761 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy762 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy760, <32 x i32> %phicopy761, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %phicopy819 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy820 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy819, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy821 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy822 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy820, <32 x i32> %phicopy821, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy823 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy824 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy822, <32 x i32> %phicopy823, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy825 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy826 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy824, <32 x i32> %phicopy825, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  br label %.loopexit3

.loopexit3:                                       ; preds = %264, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13..loopexit3_crit_edge, %.loopexit3.loopexit
  %.sroa.22.2 = phi <128 x i32> [ %.esimd74.1.1, %264 ], [ %phicopy762, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13..loopexit3_crit_edge ], [ %phicopy770, %.loopexit3.loopexit ]
  %.sroa.0.2 = phi <128 x i32> [ %.esimd74.1124, %264 ], [ %phicopy826, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13..loopexit3_crit_edge ], [ %phicopy834, %.loopexit3.loopexit ]
  %306 = phi ptr addrspace(4) [ %258, %264 ], [ %phicopy747, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13..loopexit3_crit_edge ], [ %258, %.loopexit3.loopexit ]
  %307 = phi i32 [ %164, %264 ], [ %303, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13..loopexit3_crit_edge ], [ %164, %.loopexit3.loopexit ]
  %308 = phi i32 [ %259, %264 ], [ %phicopy733, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13..loopexit3_crit_edge ], [ %phicopy734, %.loopexit3.loopexit ]
  %309 = call i1 @llvm.genx.constantpred.i1(i1 false)
  br i1 %.not159, label %310, label %.loopexit3._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3_crit_edge

.loopexit3._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3_crit_edge: ; preds = %.loopexit3
  %phicopy723 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3

310:                                              ; preds = %.loopexit3
  %311 = ptrtoint ptr addrspace(1) %.71617 to i64
  %312 = call <8 x i64> @llvm.vc.internal.lsc.load.ugm.v8i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %311, i16 1, i32 0, <8 x i64> undef)
  %.decomp.1 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v8i64.i16.i1(<12 x i64> undef, <8 x i64> %312, i32 0, i32 8, i32 1, i16 0, i32 undef, i1 true)
  %313 = call <4 x i64> @llvm.vc.internal.lsc.load.ugm.v4i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 4, <2 x i8> zeroinitializer, i64 0, i64 %311, i16 1, i32 64, <4 x i64> undef)
  %.decomp.1632 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v4i64.i16.i1(<12 x i64> %.decomp.1, <4 x i64> %313, i32 0, i32 4, i32 1, i16 64, i32 undef, i1 true)
  %.postcast505.decomp.1 = bitcast <12 x i64> %.decomp.1632 to <24 x i32>
  %314 = add nsw i32 %.71626, 1, !spirv.Decorations !22
  %315 = icmp eq i32 %314, %8
  br i1 %315, label %320, label %316

316:                                              ; preds = %310
  %317 = add i64 %311, %156
  %318 = inttoptr i64 %317 to ptr addrspace(1)
  %319 = call i1 @llvm.genx.constantpred.i1(i1 true)
  %phicopy713 = bitcast i32 %83 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3

320:                                              ; preds = %310
  %321 = add i64 %311, %157
  %322 = inttoptr i64 %321 to ptr addrspace(1)
  %phicopy707 = bitcast i32 %82 to i32
  %phicopy724 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3: ; preds = %.loopexit3._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3_crit_edge, %316, %320
  %.esimd7851.decomp.0 = phi <16 x i32> [ %.esimd30.decomp.0, %.loopexit3._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3_crit_edge ], [ undef, %320 ], [ undef, %316 ]
  %.esimd7851.decomp.1 = phi <24 x i32> [ %.esimd7849.decomp.1, %.loopexit3._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3_crit_edge ], [ %.postcast505.decomp.1, %320 ], [ %.postcast505.decomp.1, %316 ]
  %.61625 = phi i32 [ %.71626, %.loopexit3._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3_crit_edge ], [ %phicopy707, %320 ], [ %314, %316 ]
  %.61616 = phi ptr addrspace(1) [ %.71617, %.loopexit3._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3_crit_edge ], [ %322, %320 ], [ %318, %316 ]
  %.not180 = phi i1 [ %309, %.loopexit3._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3_crit_edge ], [ %309, %320 ], [ %319, %316 ], !pred.index !27
  %.6 = phi i32 [ %phicopy723, %.loopexit3._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3_crit_edge ], [ %phicopy724, %320 ], [ %phicopy713, %316 ]
  %.esimd79.split0 = call <4 x i32> @llvm.genx.rdregioni.v4i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 4, i32 1, i16 64, i32 undef)
  %.esimd80.join0.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v4i32.i16.i1(<16 x i32> %.esimd13058.decomp.0, <4 x i32> %.esimd79.split0, i32 0, i32 4, i32 1, i16 36, i32 undef, i1 true)
  %.esimd79.split4 = call <2 x i32> @llvm.genx.rdregioni.v2i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 2, i32 1, i16 80, i32 undef)
  %.esimd80.join4.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v2i32.i16.i1(<16 x i32> %.esimd80.join0.decomp.0, <2 x i32> %.esimd79.split4, i32 0, i32 2, i32 1, i16 52, i32 undef, i1 true)
  %.esimd79.split6 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 1, i32 1, i16 88, i32 undef)
  %.esimd80.join6.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32> %.esimd80.join4.decomp.0, <1 x i32> %.esimd79.split6, i32 0, i32 1, i32 1, i16 60, i32 undef, i1 true)
  %.esimd81 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 1, i32 1, i16 92, i32 undef)
  %.esimd82.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32> %.esimd80.join6.decomp.0, <1 x i32> %.esimd81, i32 0, i32 1, i32 1, i16 32, i32 undef, i1 true)
  %.esimd83 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v16i32.i16(<16 x i32> %.esimd82.decomp.0, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %323 = shl <16 x i32> %.esimd83, %118
  %.esimd84 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 8, i32 1, i16 0, i32 undef)
  %324 = lshr <16 x i32> %.esimd84, %121
  %325 = or <16 x i32> %324, %323
  %326 = bitcast <16 x i32> %325 to <32 x i16>
  %.esimd85 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %326, i32 0, i32 16, i32 2, i16 2, i32 0)
  %327 = zext <16 x i16> %.esimd85 to <16 x i32>
  %328 = mul <16 x i32> %327, splat (i32 -2082680531)
  %.esimd86 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> undef, <16 x i32> %328, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %329 = lshr <16 x i32> %325, splat (i32 13)
  %330 = bitcast <16 x i32> %329 to <32 x i16>
  %.esimd87 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %330, i32 0, i32 16, i32 2, i16 0, i32 0)
  %331 = zext <16 x i16> %.esimd87 to <16 x i32>
  %332 = mul <16 x i32> %331, splat (i32 -2082680531)
  %.esimd88 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd86, <16 x i32> %332, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %333 = lshr <16 x i32> %325, splat (i32 10)
  %334 = bitcast <16 x i32> %333 to <32 x i16>
  %.esimd89 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %334, i32 0, i32 16, i32 2, i16 0, i32 0)
  %335 = zext <16 x i16> %.esimd89 to <16 x i32>
  %336 = mul <16 x i32> %335, splat (i32 -2082680531)
  %.esimd90 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> undef, <16 x i32> %336, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %337 = lshr <16 x i32> %325, splat (i32 7)
  %338 = bitcast <16 x i32> %337 to <32 x i16>
  %.esimd91 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %338, i32 0, i32 16, i32 2, i16 0, i32 0)
  %339 = zext <16 x i16> %.esimd91 to <16 x i32>
  %340 = mul <16 x i32> %339, splat (i32 -2082680531)
  %.esimd92 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd90, <16 x i32> %340, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %.esimd84668 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 8, i32 1, i16 0, i32 undef)
  %341 = shl <16 x i32> %.esimd84668, %124
  %.esimd94 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %342 = lshr <16 x i32> %.esimd94, %127
  %343 = or <16 x i32> %342, %341
  %344 = bitcast <16 x i32> %343 to <32 x i16>
  %.esimd95 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %344, i32 0, i32 16, i32 2, i16 2, i32 0)
  %345 = zext <16 x i16> %.esimd95 to <16 x i32>
  %346 = mul <16 x i32> %345, splat (i32 -2082680531)
  %.esimd96 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd88, <16 x i32> %346, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %347 = lshr <16 x i32> %343, splat (i32 13)
  %348 = bitcast <16 x i32> %347 to <32 x i16>
  %.esimd97 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %348, i32 0, i32 16, i32 2, i16 0, i32 0)
  %349 = zext <16 x i16> %.esimd97 to <16 x i32>
  %350 = mul <16 x i32> %349, splat (i32 -2082680531)
  %.esimd98 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd96, <16 x i32> %350, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %351 = lshr <16 x i32> %343, splat (i32 10)
  %352 = bitcast <16 x i32> %351 to <32 x i16>
  %.esimd99 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %352, i32 0, i32 16, i32 2, i16 0, i32 0)
  %353 = zext <16 x i16> %.esimd99 to <16 x i32>
  %354 = mul <16 x i32> %353, splat (i32 -2082680531)
  %.esimd100 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd92, <16 x i32> %354, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %355 = lshr <16 x i32> %343, splat (i32 7)
  %356 = bitcast <16 x i32> %355 to <32 x i16>
  %.esimd101 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %356, i32 0, i32 16, i32 2, i16 0, i32 0)
  %357 = zext <16 x i16> %.esimd101 to <16 x i32>
  %358 = mul <16 x i32> %357, splat (i32 -2082680531)
  %.esimd102 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd100, <16 x i32> %358, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %.esimd94667 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %359 = shl <16 x i32> %.esimd94667, %130
  %.esimd104 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 8, i32 1, i16 64, i32 undef)
  %360 = lshr <16 x i32> %.esimd104, %133
  %361 = or <16 x i32> %360, %359
  %362 = bitcast <16 x i32> %361 to <32 x i16>
  %.esimd105 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %362, i32 0, i32 16, i32 2, i16 2, i32 0)
  %363 = zext <16 x i16> %.esimd105 to <16 x i32>
  %364 = mul <16 x i32> %363, splat (i32 -2082680531)
  %.esimd106 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd98, <16 x i32> %364, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %365 = lshr <16 x i32> %361, splat (i32 13)
  %366 = bitcast <16 x i32> %365 to <32 x i16>
  %.esimd107 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %366, i32 0, i32 16, i32 2, i16 0, i32 0)
  %367 = zext <16 x i16> %.esimd107 to <16 x i32>
  %368 = mul <16 x i32> %367, splat (i32 -2082680531)
  %.esimd108 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd106, <16 x i32> %368, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %369 = lshr <16 x i32> %361, splat (i32 10)
  %370 = bitcast <16 x i32> %369 to <32 x i16>
  %.esimd109 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %370, i32 0, i32 16, i32 2, i16 0, i32 0)
  %371 = zext <16 x i16> %.esimd109 to <16 x i32>
  %372 = mul <16 x i32> %371, splat (i32 -2082680531)
  %.esimd110 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd102, <16 x i32> %372, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %373 = lshr <16 x i32> %361, splat (i32 7)
  %374 = bitcast <16 x i32> %373 to <32 x i16>
  %.esimd111 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %374, i32 0, i32 16, i32 2, i16 0, i32 0)
  %375 = zext <16 x i16> %.esimd111 to <16 x i32>
  %376 = mul <16 x i32> %375, splat (i32 -2082680531)
  %.esimd112 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd110, <16 x i32> %376, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %.esimd113 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 16, i32 1, i16 32, i32 undef)
  %377 = shl <16 x i32> %.esimd113, %136
  %.esimd104666 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd13058.decomp.1, i32 0, i32 8, i32 1, i16 64, i32 undef)
  %378 = lshr <16 x i32> %.esimd104666, %139
  %379 = or <16 x i32> %377, %378
  %380 = bitcast <16 x i32> %379 to <32 x i16>
  %.esimd115 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %380, i32 0, i32 16, i32 2, i16 2, i32 0)
  %381 = zext <16 x i16> %.esimd115 to <16 x i32>
  %382 = mul <16 x i32> %381, splat (i32 -2082680531)
  %.esimd116 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd108, <16 x i32> %382, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %383 = lshr <16 x i32> %379, splat (i32 13)
  %384 = bitcast <16 x i32> %383 to <32 x i16>
  %.esimd117 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %384, i32 0, i32 16, i32 2, i16 0, i32 0)
  %385 = zext <16 x i16> %.esimd117 to <16 x i32>
  %386 = mul <16 x i32> %385, splat (i32 -2082680531)
  %.esimd118 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd116, <16 x i32> %386, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %387 = lshr <16 x i32> %379, splat (i32 10)
  %388 = bitcast <16 x i32> %387 to <32 x i16>
  %.esimd119 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %388, i32 0, i32 16, i32 2, i16 0, i32 0)
  %389 = zext <16 x i16> %.esimd119 to <16 x i32>
  %390 = mul <16 x i32> %389, splat (i32 -2082680531)
  %.esimd120 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd112, <16 x i32> %390, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %391 = lshr <16 x i32> %379, splat (i32 7)
  %392 = bitcast <16 x i32> %391 to <32 x i16>
  %.esimd121 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %392, i32 0, i32 16, i32 2, i16 0, i32 0)
  %393 = zext <16 x i16> %.esimd121 to <16 x i32>
  %394 = mul <16 x i32> %393, splat (i32 -2082680531)
  %.esimd122 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd120, <16 x i32> %394, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %395 = ptrtoint ptr addrspace(4) %306 to i64
  %396 = call <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 8, <2 x i8> zeroinitializer, i64 0, i64 %395, i16 1, i32 0, <64 x i64> undef)
  %397 = call <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 8, <2 x i8> zeroinitializer, i64 0, i64 %395, i16 1, i32 512, <64 x i64> undef)
  %.postcast501.decomp.0 = bitcast <64 x i64> %396 to <128 x i32>
  %.postcast501.decomp.1 = bitcast <64 x i64> %397 to <128 x i32>
  %.esimd125 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast501.decomp.0, i32 0, i32 64, i32 1, i16 0, i32 undef)
  %.esimd126 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.0.2, <128 x i32> %.esimd118, <64 x i32> %.esimd125, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd125.1 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast501.decomp.0, i32 0, i32 64, i32 1, i16 256, i32 undef)
  %.esimd126.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.22.2, <128 x i32> %.esimd118, <64 x i32> %.esimd125.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd125.1126 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast501.decomp.1, i32 0, i32 64, i32 1, i16 0, i32 undef)
  %.esimd126.1127 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd126, <128 x i32> %.esimd122, <64 x i32> %.esimd125.1126, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd125.1.1 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast501.decomp.1, i32 0, i32 64, i32 1, i16 256, i32 undef)
  %.esimd126.1.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd126.1, <128 x i32> %.esimd122, <64 x i32> %.esimd125.1.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %398 = add i64 %395, 1024
  %399 = inttoptr i64 %398 to ptr addrspace(4)
  %400 = add nsw i32 %308, 1, !spirv.Decorations !22
  %401 = icmp eq i32 %400, %8
  br i1 %401, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12, label %402

402:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3
  %403 = add nuw nsw i32 %162, 2, !spirv.Decorations !25
  %404 = icmp slt i32 %403, %8
  br i1 %404, label %405, label %861

405:                                              ; preds = %402
  %406 = icmp eq i32 %400, 0
  br i1 %406, label %.loopexit2.loopexit, label %.loopexit2

.loopexit2.loopexit:                              ; preds = %405
  %phicopy737 = bitcast i32 %160 to i32
  %phicopy779 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy780 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy779, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy781 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy782 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy780, <32 x i32> %phicopy781, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy783 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy784 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy782, <32 x i32> %phicopy783, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy785 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy786 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy784, <32 x i32> %phicopy785, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %phicopy843 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy844 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy843, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy845 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy846 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy844, <32 x i32> %phicopy845, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy847 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy848 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy846, <32 x i32> %phicopy847, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy849 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy850 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy848, <32 x i32> %phicopy849, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  br label %.loopexit2

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3
  %407 = add nsw i32 %307, %44, !spirv.Decorations !22
  %408 = sext i32 %407 to i64
  %409 = add i64 %mul64recast446, %408
  %.iv32cast380 = bitcast i64 %409 to <2 x i32>
  %.LoSplit381665 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast380, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.HiSplit385 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %410 = mul <1 x i32> %.LoSplit381665, %.HiSplit385
  %.HiSplit382 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast380, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %.LoSplit384664 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %411 = mul <1 x i32> %.HiSplit382, %.LoSplit384664
  %.LoSplit381 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast380, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.LoSplit384 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %412 = call <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32> %.LoSplit381, <1 x i32> %.LoSplit384, <1 x i32> zeroinitializer)
  %.lo391 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %412, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %mul64partial_join386 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo391, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi390 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %412, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %413 = call <1 x i32> @llvm.genx.add3.v1i32.v1i32(<1 x i32> %411, <1 x i32> %.hi390, <1 x i32> %410)
  %mul64joined387 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %mul64partial_join386, <1 x i32> %413, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %mul64recast389 = bitcast <2 x i32> %mul64joined387 to i64
  %414 = shl i64 %mul64recast389, 2
  %415 = add i64 %155, %414
  %416 = bitcast <128 x i32> %.esimd126.1127 to <64 x i64>
  %.esimd127 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %416, i32 0, i32 8, i32 1, i16 0, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %415, i16 1, i32 0, <8 x i64> %.esimd127)
  %417 = add i64 %415, %158
  %.esimd127.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %416, i32 0, i32 8, i32 1, i16 64, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %417, i16 1, i32 0, <8 x i64> %.esimd127.1)
  %418 = add i64 %415, %.idx138
  %.esimd127.2 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %416, i32 0, i32 8, i32 1, i16 128, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %418, i16 1, i32 0, <8 x i64> %.esimd127.2)
  %419 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 12), <1 x i32> zeroinitializer)
  %.lo379 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %419, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx153.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo379, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi378 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %419, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx153.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx153.imul.partial_join, <1 x i32> %.hi378, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx153.imul.recast = bitcast <2 x i32> %.idx153.imul.joined to i64
  %420 = add i64 %415, %.idx153.imul.recast
  %.esimd127.3 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %416, i32 0, i32 8, i32 1, i16 192, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %420, i16 1, i32 0, <8 x i64> %.esimd127.3)
  %421 = add i64 %415, %154
  %.esimd127.4 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %416, i32 0, i32 8, i32 1, i16 256, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %421, i16 1, i32 0, <8 x i64> %.esimd127.4)
  %422 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 20), <1 x i32> zeroinitializer)
  %.lo376 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %422, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx155.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo376, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi375 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %422, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx155.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx155.imul.partial_join, <1 x i32> %.hi375, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx155.imul.recast = bitcast <2 x i32> %.idx155.imul.joined to i64
  %423 = add i64 %415, %.idx155.imul.recast
  %.esimd127.5 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %416, i32 0, i32 8, i32 1, i16 320, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %423, i16 1, i32 0, <8 x i64> %.esimd127.5)
  %424 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 24), <1 x i32> zeroinitializer)
  %.lo373 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %424, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx156.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo373, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi372 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %424, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx156.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx156.imul.partial_join, <1 x i32> %.hi372, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx156.imul.recast = bitcast <2 x i32> %.idx156.imul.joined to i64
  %425 = add i64 %415, %.idx156.imul.recast
  %.esimd127.6 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %416, i32 0, i32 8, i32 1, i16 384, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %425, i16 1, i32 0, <8 x i64> %.esimd127.6)
  %426 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 28), <1 x i32> zeroinitializer)
  %.lo370 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %426, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx157.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo370, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi369 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %426, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx157.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx157.imul.partial_join, <1 x i32> %.hi369, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx157.imul.recast = bitcast <2 x i32> %.idx157.imul.joined to i64
  %427 = add i64 %415, %.idx157.imul.recast
  %.esimd127.7 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %416, i32 0, i32 8, i32 1, i16 448, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %427, i16 1, i32 0, <8 x i64> %.esimd127.7)
  %428 = bitcast <128 x i32> %.esimd126.1.1 to <64 x i64>
  %429 = add i64 %415, %.idx144
  %.esimd127.1128 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %428, i32 0, i32 8, i32 1, i16 0, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %429, i16 1, i32 0, <8 x i64> %.esimd127.1128)
  %430 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 36), <1 x i32> zeroinitializer)
  %.lo367 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %430, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx159.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo367, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi366 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %430, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx159.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx159.imul.partial_join, <1 x i32> %.hi366, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx159.imul.recast = bitcast <2 x i32> %.idx159.imul.joined to i64
  %431 = add i64 %415, %.idx159.imul.recast
  %.esimd127.1.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %428, i32 0, i32 8, i32 1, i16 64, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %431, i16 1, i32 0, <8 x i64> %.esimd127.1.1)
  %432 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 40), <1 x i32> zeroinitializer)
  %.lo364 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %432, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx160.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo364, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi363 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %432, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx160.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx160.imul.partial_join, <1 x i32> %.hi363, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx160.imul.recast = bitcast <2 x i32> %.idx160.imul.joined to i64
  %433 = add i64 %415, %.idx160.imul.recast
  %.esimd127.2.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %428, i32 0, i32 8, i32 1, i16 128, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %433, i16 1, i32 0, <8 x i64> %.esimd127.2.1)
  %434 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 44), <1 x i32> zeroinitializer)
  %.lo361 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %434, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx161.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo361, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi360 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %434, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx161.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx161.imul.partial_join, <1 x i32> %.hi360, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx161.imul.recast = bitcast <2 x i32> %.idx161.imul.joined to i64
  %435 = add i64 %415, %.idx161.imul.recast
  %.esimd127.3.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %428, i32 0, i32 8, i32 1, i16 192, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %435, i16 1, i32 0, <8 x i64> %.esimd127.3.1)
  %436 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 48), <1 x i32> zeroinitializer)
  %.lo358 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %436, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx162.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo358, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi357 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %436, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx162.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx162.imul.partial_join, <1 x i32> %.hi357, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx162.imul.recast = bitcast <2 x i32> %.idx162.imul.joined to i64
  %437 = add i64 %415, %.idx162.imul.recast
  %.esimd127.4.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %428, i32 0, i32 8, i32 1, i16 256, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %437, i16 1, i32 0, <8 x i64> %.esimd127.4.1)
  %438 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 52), <1 x i32> zeroinitializer)
  %.lo355 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %438, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx163.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo355, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi354 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %438, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx163.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx163.imul.partial_join, <1 x i32> %.hi354, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx163.imul.recast = bitcast <2 x i32> %.idx163.imul.joined to i64
  %439 = add i64 %415, %.idx163.imul.recast
  %.esimd127.5.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %428, i32 0, i32 8, i32 1, i16 320, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %439, i16 1, i32 0, <8 x i64> %.esimd127.5.1)
  %440 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 56), <1 x i32> zeroinitializer)
  %.lo352 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %440, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx164.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo352, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi351 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %440, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx164.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx164.imul.partial_join, <1 x i32> %.hi351, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx164.imul.recast = bitcast <2 x i32> %.idx164.imul.joined to i64
  %441 = add i64 %415, %.idx164.imul.recast
  %.esimd127.6.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %428, i32 0, i32 8, i32 1, i16 384, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %441, i16 1, i32 0, <8 x i64> %.esimd127.6.1)
  %442 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 60), <1 x i32> zeroinitializer)
  %.lo349 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %442, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx165.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo349, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi348 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %442, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx165.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx165.imul.partial_join, <1 x i32> %.hi348, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx165.imul.recast = bitcast <2 x i32> %.idx165.imul.joined to i64
  %443 = add i64 %415, %.idx165.imul.recast
  %.esimd127.7.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %428, i32 0, i32 8, i32 1, i16 448, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %443, i16 1, i32 0, <8 x i64> %.esimd127.7.1)
  %444 = add nsw i32 %307, 1, !spirv.Decorations !22
  %445 = add nuw nsw i32 %162, 2, !spirv.Decorations !25
  %446 = icmp slt i32 %445, %8
  br i1 %446, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12..loopexit2_crit_edge, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12
  %phicopy735 = bitcast i32 %160 to i32
  %phicopy748 = bitcast ptr addrspace(4) %142 to ptr addrspace(4)
  br label %861

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12..loopexit2_crit_edge: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12
  %phicopy736 = bitcast i32 %160 to i32
  %phicopy749 = bitcast ptr addrspace(4) %142 to ptr addrspace(4)
  %phicopy771 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy772 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy771, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy773 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy774 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy772, <32 x i32> %phicopy773, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy775 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy776 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy774, <32 x i32> %phicopy775, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy777 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy778 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy776, <32 x i32> %phicopy777, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %phicopy835 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy836 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy835, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy837 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy838 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy836, <32 x i32> %phicopy837, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy839 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy840 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy838, <32 x i32> %phicopy839, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy841 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy842 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy840, <32 x i32> %phicopy841, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  br label %.loopexit2

.loopexit2:                                       ; preds = %405, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12..loopexit2_crit_edge, %.loopexit2.loopexit
  %.sroa.22.3 = phi <128 x i32> [ %.esimd126.1.1, %405 ], [ %phicopy778, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12..loopexit2_crit_edge ], [ %phicopy786, %.loopexit2.loopexit ]
  %.sroa.0.3 = phi <128 x i32> [ %.esimd126.1127, %405 ], [ %phicopy842, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12..loopexit2_crit_edge ], [ %phicopy850, %.loopexit2.loopexit ]
  %447 = phi ptr addrspace(4) [ %399, %405 ], [ %phicopy749, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12..loopexit2_crit_edge ], [ %399, %.loopexit2.loopexit ]
  %448 = phi i32 [ %307, %405 ], [ %444, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12..loopexit2_crit_edge ], [ %307, %.loopexit2.loopexit ]
  %449 = phi i32 [ %400, %405 ], [ %phicopy736, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12..loopexit2_crit_edge ], [ %phicopy737, %.loopexit2.loopexit ]
  %450 = call i1 @llvm.genx.constantpred.i1(i1 false)
  br i1 %.not180, label %451, label %.loopexit2._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2_crit_edge

.loopexit2._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2_crit_edge: ; preds = %.loopexit2
  %phicopy725 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2

451:                                              ; preds = %.loopexit2
  %452 = ptrtoint ptr addrspace(1) %.61616 to i64
  %453 = call <8 x i64> @llvm.vc.internal.lsc.load.ugm.v8i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %452, i16 1, i32 0, <8 x i64> undef)
  %.decomp.1635 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v8i64.i16.i1(<12 x i64> undef, <8 x i64> %453, i32 0, i32 8, i32 1, i16 0, i32 undef, i1 true)
  %454 = call <4 x i64> @llvm.vc.internal.lsc.load.ugm.v4i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 4, <2 x i8> zeroinitializer, i64 0, i64 %452, i16 1, i32 64, <4 x i64> undef)
  %.decomp.1636 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v4i64.i16.i1(<12 x i64> %.decomp.1635, <4 x i64> %454, i32 0, i32 4, i32 1, i16 64, i32 undef, i1 true)
  %.postcast500.decomp.1 = bitcast <12 x i64> %.decomp.1636 to <24 x i32>
  %455 = add nsw i32 %.61625, 1, !spirv.Decorations !22
  %456 = icmp eq i32 %455, %8
  br i1 %456, label %461, label %457

457:                                              ; preds = %451
  %458 = add i64 %452, %156
  %459 = inttoptr i64 %458 to ptr addrspace(1)
  %460 = call i1 @llvm.genx.constantpred.i1(i1 true)
  %phicopy714 = bitcast i32 %83 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2

461:                                              ; preds = %451
  %462 = add i64 %452, %157
  %463 = inttoptr i64 %462 to ptr addrspace(1)
  %phicopy708 = bitcast i32 %82 to i32
  %phicopy726 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2: ; preds = %.loopexit2._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2_crit_edge, %457, %461
  %.esimd13059.decomp.0 = phi <16 x i32> [ %.esimd82.decomp.0, %.loopexit2._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2_crit_edge ], [ undef, %461 ], [ undef, %457 ]
  %.esimd13059.decomp.1 = phi <24 x i32> [ %.esimd13058.decomp.1, %.loopexit2._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2_crit_edge ], [ %.postcast500.decomp.1, %461 ], [ %.postcast500.decomp.1, %457 ]
  %.51624 = phi i32 [ %.61625, %.loopexit2._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2_crit_edge ], [ %phicopy708, %461 ], [ %455, %457 ]
  %.51615 = phi ptr addrspace(1) [ %.61616, %.loopexit2._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2_crit_edge ], [ %463, %461 ], [ %459, %457 ]
  %.not160 = phi i1 [ %450, %.loopexit2._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2_crit_edge ], [ %450, %461 ], [ %460, %457 ], !pred.index !28
  %.5 = phi i32 [ %phicopy725, %.loopexit2._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2_crit_edge ], [ %phicopy726, %461 ], [ %phicopy714, %457 ]
  %.esimd131.split0 = call <4 x i32> @llvm.genx.rdregioni.v4i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 4, i32 1, i16 64, i32 undef)
  %.esimd132.join0.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v4i32.i16.i1(<16 x i32> %.esimd18262.decomp.0, <4 x i32> %.esimd131.split0, i32 0, i32 4, i32 1, i16 36, i32 undef, i1 true)
  %.esimd131.split4 = call <2 x i32> @llvm.genx.rdregioni.v2i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 2, i32 1, i16 80, i32 undef)
  %.esimd132.join4.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v2i32.i16.i1(<16 x i32> %.esimd132.join0.decomp.0, <2 x i32> %.esimd131.split4, i32 0, i32 2, i32 1, i16 52, i32 undef, i1 true)
  %.esimd131.split6 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 1, i32 1, i16 88, i32 undef)
  %.esimd132.join6.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32> %.esimd132.join4.decomp.0, <1 x i32> %.esimd131.split6, i32 0, i32 1, i32 1, i16 60, i32 undef, i1 true)
  %.esimd133 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 1, i32 1, i16 92, i32 undef)
  %.esimd134.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32> %.esimd132.join6.decomp.0, <1 x i32> %.esimd133, i32 0, i32 1, i32 1, i16 32, i32 undef, i1 true)
  %.esimd135 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v16i32.i16(<16 x i32> %.esimd134.decomp.0, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %464 = shl <16 x i32> %.esimd135, %118
  %.esimd136 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 8, i32 1, i16 0, i32 undef)
  %465 = lshr <16 x i32> %.esimd136, %121
  %466 = or <16 x i32> %465, %464
  %467 = bitcast <16 x i32> %466 to <32 x i16>
  %.esimd137 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %467, i32 0, i32 16, i32 2, i16 2, i32 0)
  %468 = zext <16 x i16> %.esimd137 to <16 x i32>
  %469 = mul <16 x i32> %468, splat (i32 -2082680531)
  %.esimd138 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> undef, <16 x i32> %469, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %470 = lshr <16 x i32> %466, splat (i32 13)
  %471 = bitcast <16 x i32> %470 to <32 x i16>
  %.esimd139 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %471, i32 0, i32 16, i32 2, i16 0, i32 0)
  %472 = zext <16 x i16> %.esimd139 to <16 x i32>
  %473 = mul <16 x i32> %472, splat (i32 -2082680531)
  %.esimd140 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd138, <16 x i32> %473, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %474 = lshr <16 x i32> %466, splat (i32 10)
  %475 = bitcast <16 x i32> %474 to <32 x i16>
  %.esimd141 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %475, i32 0, i32 16, i32 2, i16 0, i32 0)
  %476 = zext <16 x i16> %.esimd141 to <16 x i32>
  %477 = mul <16 x i32> %476, splat (i32 -2082680531)
  %.esimd142 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> undef, <16 x i32> %477, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %478 = lshr <16 x i32> %466, splat (i32 7)
  %479 = bitcast <16 x i32> %478 to <32 x i16>
  %.esimd143 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %479, i32 0, i32 16, i32 2, i16 0, i32 0)
  %480 = zext <16 x i16> %.esimd143 to <16 x i32>
  %481 = mul <16 x i32> %480, splat (i32 -2082680531)
  %.esimd144 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd142, <16 x i32> %481, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %.esimd136663 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 8, i32 1, i16 0, i32 undef)
  %482 = shl <16 x i32> %.esimd136663, %124
  %.esimd146 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %483 = lshr <16 x i32> %.esimd146, %127
  %484 = or <16 x i32> %483, %482
  %485 = bitcast <16 x i32> %484 to <32 x i16>
  %.esimd147 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %485, i32 0, i32 16, i32 2, i16 2, i32 0)
  %486 = zext <16 x i16> %.esimd147 to <16 x i32>
  %487 = mul <16 x i32> %486, splat (i32 -2082680531)
  %.esimd148 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd140, <16 x i32> %487, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %488 = lshr <16 x i32> %484, splat (i32 13)
  %489 = bitcast <16 x i32> %488 to <32 x i16>
  %.esimd149 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %489, i32 0, i32 16, i32 2, i16 0, i32 0)
  %490 = zext <16 x i16> %.esimd149 to <16 x i32>
  %491 = mul <16 x i32> %490, splat (i32 -2082680531)
  %.esimd150 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd148, <16 x i32> %491, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %492 = lshr <16 x i32> %484, splat (i32 10)
  %493 = bitcast <16 x i32> %492 to <32 x i16>
  %.esimd151 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %493, i32 0, i32 16, i32 2, i16 0, i32 0)
  %494 = zext <16 x i16> %.esimd151 to <16 x i32>
  %495 = mul <16 x i32> %494, splat (i32 -2082680531)
  %.esimd152 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd144, <16 x i32> %495, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %496 = lshr <16 x i32> %484, splat (i32 7)
  %497 = bitcast <16 x i32> %496 to <32 x i16>
  %.esimd153 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %497, i32 0, i32 16, i32 2, i16 0, i32 0)
  %498 = zext <16 x i16> %.esimd153 to <16 x i32>
  %499 = mul <16 x i32> %498, splat (i32 -2082680531)
  %.esimd154 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd152, <16 x i32> %499, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %.esimd146662 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %500 = shl <16 x i32> %.esimd146662, %130
  %.esimd156 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 8, i32 1, i16 64, i32 undef)
  %501 = lshr <16 x i32> %.esimd156, %133
  %502 = or <16 x i32> %501, %500
  %503 = bitcast <16 x i32> %502 to <32 x i16>
  %.esimd157 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %503, i32 0, i32 16, i32 2, i16 2, i32 0)
  %504 = zext <16 x i16> %.esimd157 to <16 x i32>
  %505 = mul <16 x i32> %504, splat (i32 -2082680531)
  %.esimd158 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd150, <16 x i32> %505, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %506 = lshr <16 x i32> %502, splat (i32 13)
  %507 = bitcast <16 x i32> %506 to <32 x i16>
  %.esimd159 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %507, i32 0, i32 16, i32 2, i16 0, i32 0)
  %508 = zext <16 x i16> %.esimd159 to <16 x i32>
  %509 = mul <16 x i32> %508, splat (i32 -2082680531)
  %.esimd160 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd158, <16 x i32> %509, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %510 = lshr <16 x i32> %502, splat (i32 10)
  %511 = bitcast <16 x i32> %510 to <32 x i16>
  %.esimd161 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %511, i32 0, i32 16, i32 2, i16 0, i32 0)
  %512 = zext <16 x i16> %.esimd161 to <16 x i32>
  %513 = mul <16 x i32> %512, splat (i32 -2082680531)
  %.esimd162 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd154, <16 x i32> %513, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %514 = lshr <16 x i32> %502, splat (i32 7)
  %515 = bitcast <16 x i32> %514 to <32 x i16>
  %.esimd163 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %515, i32 0, i32 16, i32 2, i16 0, i32 0)
  %516 = zext <16 x i16> %.esimd163 to <16 x i32>
  %517 = mul <16 x i32> %516, splat (i32 -2082680531)
  %.esimd164 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd162, <16 x i32> %517, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %.esimd165 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 16, i32 1, i16 32, i32 undef)
  %518 = shl <16 x i32> %.esimd165, %136
  %.esimd156661 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd18262.decomp.1, i32 0, i32 8, i32 1, i16 64, i32 undef)
  %519 = lshr <16 x i32> %.esimd156661, %139
  %520 = or <16 x i32> %518, %519
  %521 = bitcast <16 x i32> %520 to <32 x i16>
  %.esimd167 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %521, i32 0, i32 16, i32 2, i16 2, i32 0)
  %522 = zext <16 x i16> %.esimd167 to <16 x i32>
  %523 = mul <16 x i32> %522, splat (i32 -2082680531)
  %.esimd168 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd160, <16 x i32> %523, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %524 = lshr <16 x i32> %520, splat (i32 13)
  %525 = bitcast <16 x i32> %524 to <32 x i16>
  %.esimd169 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %525, i32 0, i32 16, i32 2, i16 0, i32 0)
  %526 = zext <16 x i16> %.esimd169 to <16 x i32>
  %527 = mul <16 x i32> %526, splat (i32 -2082680531)
  %.esimd170 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd168, <16 x i32> %527, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %528 = lshr <16 x i32> %520, splat (i32 10)
  %529 = bitcast <16 x i32> %528 to <32 x i16>
  %.esimd171 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %529, i32 0, i32 16, i32 2, i16 0, i32 0)
  %530 = zext <16 x i16> %.esimd171 to <16 x i32>
  %531 = mul <16 x i32> %530, splat (i32 -2082680531)
  %.esimd172 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd164, <16 x i32> %531, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %532 = lshr <16 x i32> %520, splat (i32 7)
  %533 = bitcast <16 x i32> %532 to <32 x i16>
  %.esimd173 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %533, i32 0, i32 16, i32 2, i16 0, i32 0)
  %534 = zext <16 x i16> %.esimd173 to <16 x i32>
  %535 = mul <16 x i32> %534, splat (i32 -2082680531)
  %.esimd174 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd172, <16 x i32> %535, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %536 = ptrtoint ptr addrspace(4) %447 to i64
  %537 = call <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 8, <2 x i8> zeroinitializer, i64 0, i64 %536, i16 1, i32 0, <64 x i64> undef)
  %538 = call <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 8, <2 x i8> zeroinitializer, i64 0, i64 %536, i16 1, i32 512, <64 x i64> undef)
  %.postcast496.decomp.0 = bitcast <64 x i64> %537 to <128 x i32>
  %.postcast496.decomp.1 = bitcast <64 x i64> %538 to <128 x i32>
  %.esimd177 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast496.decomp.0, i32 0, i32 64, i32 1, i16 0, i32 undef)
  %.esimd178 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.0.3, <128 x i32> %.esimd170, <64 x i32> %.esimd177, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd177.1 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast496.decomp.0, i32 0, i32 64, i32 1, i16 256, i32 undef)
  %.esimd178.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.22.3, <128 x i32> %.esimd170, <64 x i32> %.esimd177.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd177.1129 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast496.decomp.1, i32 0, i32 64, i32 1, i16 0, i32 undef)
  %.esimd178.1130 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd178, <128 x i32> %.esimd174, <64 x i32> %.esimd177.1129, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd177.1.1 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast496.decomp.1, i32 0, i32 64, i32 1, i16 256, i32 undef)
  %.esimd178.1.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd178.1, <128 x i32> %.esimd174, <64 x i32> %.esimd177.1.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %539 = add i64 %536, 1024
  %540 = inttoptr i64 %539 to ptr addrspace(4)
  %541 = add nsw i32 %449, 1, !spirv.Decorations !22
  %542 = icmp eq i32 %541, %8
  br i1 %542, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11, label %543

543:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2
  %544 = add nuw nsw i32 %162, 3, !spirv.Decorations !25
  %545 = icmp slt i32 %544, %8
  br i1 %545, label %546, label %861

546:                                              ; preds = %543
  %547 = icmp eq i32 %541, 0
  br i1 %547, label %.loopexit1.loopexit, label %.loopexit1

.loopexit1.loopexit:                              ; preds = %546
  %phicopy740 = bitcast i32 %160 to i32
  %phicopy795 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy796 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy795, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy797 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy798 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy796, <32 x i32> %phicopy797, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy799 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy800 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy798, <32 x i32> %phicopy799, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy801 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy802 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy800, <32 x i32> %phicopy801, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %phicopy859 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy860 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy859, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy861 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy862 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy860, <32 x i32> %phicopy861, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy863 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy864 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy862, <32 x i32> %phicopy863, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy865 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy866 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy864, <32 x i32> %phicopy865, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  br label %.loopexit1

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2
  %548 = add nsw i32 %448, %44, !spirv.Decorations !22
  %549 = sext i32 %548 to i64
  %550 = add i64 %mul64recast446, %549
  %.iv32cast335 = bitcast i64 %550 to <2 x i32>
  %.LoSplit336660 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast335, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.HiSplit340 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %551 = mul <1 x i32> %.LoSplit336660, %.HiSplit340
  %.HiSplit337 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast335, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %.LoSplit339659 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %552 = mul <1 x i32> %.HiSplit337, %.LoSplit339659
  %.LoSplit336 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast335, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.LoSplit339 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %553 = call <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32> %.LoSplit336, <1 x i32> %.LoSplit339, <1 x i32> zeroinitializer)
  %.lo346 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %553, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %mul64partial_join341 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo346, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi345 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %553, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %554 = call <1 x i32> @llvm.genx.add3.v1i32.v1i32(<1 x i32> %552, <1 x i32> %.hi345, <1 x i32> %551)
  %mul64joined342 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %mul64partial_join341, <1 x i32> %554, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %mul64recast344 = bitcast <2 x i32> %mul64joined342 to i64
  %555 = shl i64 %mul64recast344, 2
  %556 = add i64 %155, %555
  %557 = bitcast <128 x i32> %.esimd178.1130 to <64 x i64>
  %.esimd179 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %557, i32 0, i32 8, i32 1, i16 0, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %556, i16 1, i32 0, <8 x i64> %.esimd179)
  %558 = add i64 %556, %158
  %.esimd179.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %557, i32 0, i32 8, i32 1, i16 64, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %558, i16 1, i32 0, <8 x i64> %.esimd179.1)
  %559 = add i64 %556, %.idx138
  %.esimd179.2 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %557, i32 0, i32 8, i32 1, i16 128, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %559, i16 1, i32 0, <8 x i64> %.esimd179.2)
  %560 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 12), <1 x i32> zeroinitializer)
  %.lo334 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %560, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx167.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo334, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi333 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %560, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx167.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx167.imul.partial_join, <1 x i32> %.hi333, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx167.imul.recast = bitcast <2 x i32> %.idx167.imul.joined to i64
  %561 = add i64 %556, %.idx167.imul.recast
  %.esimd179.3 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %557, i32 0, i32 8, i32 1, i16 192, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %561, i16 1, i32 0, <8 x i64> %.esimd179.3)
  %562 = add i64 %556, %154
  %.esimd179.4 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %557, i32 0, i32 8, i32 1, i16 256, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %562, i16 1, i32 0, <8 x i64> %.esimd179.4)
  %563 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 20), <1 x i32> zeroinitializer)
  %.lo331 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %563, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx169.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo331, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi330 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %563, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx169.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx169.imul.partial_join, <1 x i32> %.hi330, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx169.imul.recast = bitcast <2 x i32> %.idx169.imul.joined to i64
  %564 = add i64 %556, %.idx169.imul.recast
  %.esimd179.5 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %557, i32 0, i32 8, i32 1, i16 320, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %564, i16 1, i32 0, <8 x i64> %.esimd179.5)
  %565 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 24), <1 x i32> zeroinitializer)
  %.lo328 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %565, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx170.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo328, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi327 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %565, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx170.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx170.imul.partial_join, <1 x i32> %.hi327, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx170.imul.recast = bitcast <2 x i32> %.idx170.imul.joined to i64
  %566 = add i64 %556, %.idx170.imul.recast
  %.esimd179.6 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %557, i32 0, i32 8, i32 1, i16 384, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %566, i16 1, i32 0, <8 x i64> %.esimd179.6)
  %567 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 28), <1 x i32> zeroinitializer)
  %.lo325 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %567, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx171.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo325, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi324 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %567, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx171.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx171.imul.partial_join, <1 x i32> %.hi324, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx171.imul.recast = bitcast <2 x i32> %.idx171.imul.joined to i64
  %568 = add i64 %556, %.idx171.imul.recast
  %.esimd179.7 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %557, i32 0, i32 8, i32 1, i16 448, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %568, i16 1, i32 0, <8 x i64> %.esimd179.7)
  %569 = bitcast <128 x i32> %.esimd178.1.1 to <64 x i64>
  %570 = add i64 %556, %.idx144
  %.esimd179.1131 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %569, i32 0, i32 8, i32 1, i16 0, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %570, i16 1, i32 0, <8 x i64> %.esimd179.1131)
  %571 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 36), <1 x i32> zeroinitializer)
  %.lo322 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %571, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx173.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo322, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi321 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %571, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx173.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx173.imul.partial_join, <1 x i32> %.hi321, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx173.imul.recast = bitcast <2 x i32> %.idx173.imul.joined to i64
  %572 = add i64 %556, %.idx173.imul.recast
  %.esimd179.1.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %569, i32 0, i32 8, i32 1, i16 64, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %572, i16 1, i32 0, <8 x i64> %.esimd179.1.1)
  %573 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 40), <1 x i32> zeroinitializer)
  %.lo319 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %573, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx174.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo319, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi318 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %573, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx174.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx174.imul.partial_join, <1 x i32> %.hi318, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx174.imul.recast = bitcast <2 x i32> %.idx174.imul.joined to i64
  %574 = add i64 %556, %.idx174.imul.recast
  %.esimd179.2.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %569, i32 0, i32 8, i32 1, i16 128, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %574, i16 1, i32 0, <8 x i64> %.esimd179.2.1)
  %575 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 44), <1 x i32> zeroinitializer)
  %.lo316 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %575, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx175.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo316, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi315 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %575, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx175.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx175.imul.partial_join, <1 x i32> %.hi315, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx175.imul.recast = bitcast <2 x i32> %.idx175.imul.joined to i64
  %576 = add i64 %556, %.idx175.imul.recast
  %.esimd179.3.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %569, i32 0, i32 8, i32 1, i16 192, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %576, i16 1, i32 0, <8 x i64> %.esimd179.3.1)
  %577 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 48), <1 x i32> zeroinitializer)
  %.lo313 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %577, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx176.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo313, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi312 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %577, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx176.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx176.imul.partial_join, <1 x i32> %.hi312, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx176.imul.recast = bitcast <2 x i32> %.idx176.imul.joined to i64
  %578 = add i64 %556, %.idx176.imul.recast
  %.esimd179.4.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %569, i32 0, i32 8, i32 1, i16 256, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %578, i16 1, i32 0, <8 x i64> %.esimd179.4.1)
  %579 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 52), <1 x i32> zeroinitializer)
  %.lo310 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %579, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx177.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo310, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi309 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %579, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx177.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx177.imul.partial_join, <1 x i32> %.hi309, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx177.imul.recast = bitcast <2 x i32> %.idx177.imul.joined to i64
  %580 = add i64 %556, %.idx177.imul.recast
  %.esimd179.5.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %569, i32 0, i32 8, i32 1, i16 320, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %580, i16 1, i32 0, <8 x i64> %.esimd179.5.1)
  %581 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 56), <1 x i32> zeroinitializer)
  %.lo307 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %581, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx178.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo307, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi306 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %581, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx178.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx178.imul.partial_join, <1 x i32> %.hi306, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx178.imul.recast = bitcast <2 x i32> %.idx178.imul.joined to i64
  %582 = add i64 %556, %.idx178.imul.recast
  %.esimd179.6.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %569, i32 0, i32 8, i32 1, i16 384, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %582, i16 1, i32 0, <8 x i64> %.esimd179.6.1)
  %583 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 60), <1 x i32> zeroinitializer)
  %.lo304 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %583, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx179.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo304, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi303 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %583, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx179.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx179.imul.partial_join, <1 x i32> %.hi303, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx179.imul.recast = bitcast <2 x i32> %.idx179.imul.joined to i64
  %584 = add i64 %556, %.idx179.imul.recast
  %.esimd179.7.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %569, i32 0, i32 8, i32 1, i16 448, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %584, i16 1, i32 0, <8 x i64> %.esimd179.7.1)
  %585 = add nsw i32 %448, 1, !spirv.Decorations !22
  %586 = add nuw nsw i32 %162, 3, !spirv.Decorations !25
  %587 = icmp slt i32 %586, %8
  br i1 %587, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11..loopexit1_crit_edge, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11
  %phicopy738 = bitcast i32 %160 to i32
  %phicopy750 = bitcast ptr addrspace(4) %142 to ptr addrspace(4)
  br label %861

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11..loopexit1_crit_edge: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11
  %phicopy739 = bitcast i32 %160 to i32
  %phicopy751 = bitcast ptr addrspace(4) %142 to ptr addrspace(4)
  %phicopy787 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy788 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy787, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy789 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy790 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy788, <32 x i32> %phicopy789, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy791 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy792 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy790, <32 x i32> %phicopy791, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy793 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy794 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy792, <32 x i32> %phicopy793, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %phicopy851 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy852 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy851, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy853 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy854 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy852, <32 x i32> %phicopy853, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy855 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy856 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy854, <32 x i32> %phicopy855, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy857 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy858 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy856, <32 x i32> %phicopy857, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  br label %.loopexit1

.loopexit1:                                       ; preds = %546, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11..loopexit1_crit_edge, %.loopexit1.loopexit
  %.sroa.22.4 = phi <128 x i32> [ %.esimd178.1.1, %546 ], [ %phicopy794, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11..loopexit1_crit_edge ], [ %phicopy802, %.loopexit1.loopexit ]
  %.sroa.0.4 = phi <128 x i32> [ %.esimd178.1130, %546 ], [ %phicopy858, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11..loopexit1_crit_edge ], [ %phicopy866, %.loopexit1.loopexit ]
  %588 = phi ptr addrspace(4) [ %540, %546 ], [ %phicopy751, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11..loopexit1_crit_edge ], [ %540, %.loopexit1.loopexit ]
  %589 = phi i32 [ %448, %546 ], [ %585, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11..loopexit1_crit_edge ], [ %448, %.loopexit1.loopexit ]
  %590 = phi i32 [ %541, %546 ], [ %phicopy739, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11..loopexit1_crit_edge ], [ %phicopy740, %.loopexit1.loopexit ]
  %591 = call i1 @llvm.genx.constantpred.i1(i1 false)
  br i1 %.not160, label %592, label %.loopexit1._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1_crit_edge

.loopexit1._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1_crit_edge: ; preds = %.loopexit1
  %phicopy727 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1

592:                                              ; preds = %.loopexit1
  %593 = ptrtoint ptr addrspace(1) %.51615 to i64
  %594 = call <8 x i64> @llvm.vc.internal.lsc.load.ugm.v8i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %593, i16 1, i32 0, <8 x i64> undef)
  %.decomp.1639 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v8i64.i16.i1(<12 x i64> undef, <8 x i64> %594, i32 0, i32 8, i32 1, i16 0, i32 undef, i1 true)
  %595 = call <4 x i64> @llvm.vc.internal.lsc.load.ugm.v4i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 4, <2 x i8> zeroinitializer, i64 0, i64 %593, i16 1, i32 64, <4 x i64> undef)
  %.decomp.1640 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v4i64.i16.i1(<12 x i64> %.decomp.1639, <4 x i64> %595, i32 0, i32 4, i32 1, i16 64, i32 undef, i1 true)
  %.postcast495.decomp.1 = bitcast <12 x i64> %.decomp.1640 to <24 x i32>
  %596 = add nsw i32 %.51624, 1, !spirv.Decorations !22
  %597 = icmp eq i32 %596, %8
  br i1 %597, label %602, label %598

598:                                              ; preds = %592
  %599 = add i64 %593, %156
  %600 = inttoptr i64 %599 to ptr addrspace(1)
  %601 = call i1 @llvm.genx.constantpred.i1(i1 true)
  %phicopy715 = bitcast i32 %83 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1

602:                                              ; preds = %592
  %603 = add i64 %593, %157
  %604 = inttoptr i64 %603 to ptr addrspace(1)
  %phicopy709 = bitcast i32 %82 to i32
  %phicopy728 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1: ; preds = %.loopexit1._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1_crit_edge, %598, %602
  %.esimd18263.decomp.0 = phi <16 x i32> [ %.esimd134.decomp.0, %.loopexit1._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1_crit_edge ], [ undef, %602 ], [ undef, %598 ]
  %.esimd18263.decomp.1 = phi <24 x i32> [ %.esimd18262.decomp.1, %.loopexit1._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1_crit_edge ], [ %.postcast495.decomp.1, %602 ], [ %.postcast495.decomp.1, %598 ]
  %.41623 = phi i32 [ %.51624, %.loopexit1._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1_crit_edge ], [ %phicopy709, %602 ], [ %596, %598 ]
  %.41614 = phi ptr addrspace(1) [ %.51615, %.loopexit1._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1_crit_edge ], [ %604, %602 ], [ %600, %598 ]
  %.not181 = phi i1 [ %591, %.loopexit1._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1_crit_edge ], [ %591, %602 ], [ %601, %598 ], !pred.index !29
  %.4 = phi i32 [ %phicopy727, %.loopexit1._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1_crit_edge ], [ %phicopy728, %602 ], [ %phicopy715, %598 ]
  %.esimd183.split0 = call <4 x i32> @llvm.genx.rdregioni.v4i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 4, i32 1, i16 64, i32 undef)
  %.esimd184.join0.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v4i32.i16.i1(<16 x i32> %.esimd23466.decomp.0, <4 x i32> %.esimd183.split0, i32 0, i32 4, i32 1, i16 36, i32 undef, i1 true)
  %.esimd183.split4 = call <2 x i32> @llvm.genx.rdregioni.v2i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 2, i32 1, i16 80, i32 undef)
  %.esimd184.join4.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v2i32.i16.i1(<16 x i32> %.esimd184.join0.decomp.0, <2 x i32> %.esimd183.split4, i32 0, i32 2, i32 1, i16 52, i32 undef, i1 true)
  %.esimd183.split6 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 1, i32 1, i16 88, i32 undef)
  %.esimd184.join6.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32> %.esimd184.join4.decomp.0, <1 x i32> %.esimd183.split6, i32 0, i32 1, i32 1, i16 60, i32 undef, i1 true)
  %.esimd185 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 1, i32 1, i16 92, i32 undef)
  %.esimd186.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32> %.esimd184.join6.decomp.0, <1 x i32> %.esimd185, i32 0, i32 1, i32 1, i16 32, i32 undef, i1 true)
  %.esimd187 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v16i32.i16(<16 x i32> %.esimd186.decomp.0, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %605 = shl <16 x i32> %.esimd187, %118
  %.esimd188 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 8, i32 1, i16 0, i32 undef)
  %606 = lshr <16 x i32> %.esimd188, %121
  %607 = or <16 x i32> %606, %605
  %608 = bitcast <16 x i32> %607 to <32 x i16>
  %.esimd189 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %608, i32 0, i32 16, i32 2, i16 2, i32 0)
  %609 = zext <16 x i16> %.esimd189 to <16 x i32>
  %610 = mul <16 x i32> %609, splat (i32 -2082680531)
  %.esimd190 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> undef, <16 x i32> %610, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %611 = lshr <16 x i32> %607, splat (i32 13)
  %612 = bitcast <16 x i32> %611 to <32 x i16>
  %.esimd191 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %612, i32 0, i32 16, i32 2, i16 0, i32 0)
  %613 = zext <16 x i16> %.esimd191 to <16 x i32>
  %614 = mul <16 x i32> %613, splat (i32 -2082680531)
  %.esimd192 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd190, <16 x i32> %614, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %615 = lshr <16 x i32> %607, splat (i32 10)
  %616 = bitcast <16 x i32> %615 to <32 x i16>
  %.esimd193 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %616, i32 0, i32 16, i32 2, i16 0, i32 0)
  %617 = zext <16 x i16> %.esimd193 to <16 x i32>
  %618 = mul <16 x i32> %617, splat (i32 -2082680531)
  %.esimd194 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> undef, <16 x i32> %618, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %619 = lshr <16 x i32> %607, splat (i32 7)
  %620 = bitcast <16 x i32> %619 to <32 x i16>
  %.esimd195 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %620, i32 0, i32 16, i32 2, i16 0, i32 0)
  %621 = zext <16 x i16> %.esimd195 to <16 x i32>
  %622 = mul <16 x i32> %621, splat (i32 -2082680531)
  %.esimd196 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd194, <16 x i32> %622, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %.esimd188658 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 8, i32 1, i16 0, i32 undef)
  %623 = shl <16 x i32> %.esimd188658, %124
  %.esimd198 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %624 = lshr <16 x i32> %.esimd198, %127
  %625 = or <16 x i32> %624, %623
  %626 = bitcast <16 x i32> %625 to <32 x i16>
  %.esimd199 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %626, i32 0, i32 16, i32 2, i16 2, i32 0)
  %627 = zext <16 x i16> %.esimd199 to <16 x i32>
  %628 = mul <16 x i32> %627, splat (i32 -2082680531)
  %.esimd200 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd192, <16 x i32> %628, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %629 = lshr <16 x i32> %625, splat (i32 13)
  %630 = bitcast <16 x i32> %629 to <32 x i16>
  %.esimd201 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %630, i32 0, i32 16, i32 2, i16 0, i32 0)
  %631 = zext <16 x i16> %.esimd201 to <16 x i32>
  %632 = mul <16 x i32> %631, splat (i32 -2082680531)
  %.esimd202 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd200, <16 x i32> %632, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %633 = lshr <16 x i32> %625, splat (i32 10)
  %634 = bitcast <16 x i32> %633 to <32 x i16>
  %.esimd203 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %634, i32 0, i32 16, i32 2, i16 0, i32 0)
  %635 = zext <16 x i16> %.esimd203 to <16 x i32>
  %636 = mul <16 x i32> %635, splat (i32 -2082680531)
  %.esimd204 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd196, <16 x i32> %636, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %637 = lshr <16 x i32> %625, splat (i32 7)
  %638 = bitcast <16 x i32> %637 to <32 x i16>
  %.esimd205 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %638, i32 0, i32 16, i32 2, i16 0, i32 0)
  %639 = zext <16 x i16> %.esimd205 to <16 x i32>
  %640 = mul <16 x i32> %639, splat (i32 -2082680531)
  %.esimd206 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd204, <16 x i32> %640, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %.esimd198657 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %641 = shl <16 x i32> %.esimd198657, %130
  %.esimd208 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 8, i32 1, i16 64, i32 undef)
  %642 = lshr <16 x i32> %.esimd208, %133
  %643 = or <16 x i32> %642, %641
  %644 = bitcast <16 x i32> %643 to <32 x i16>
  %.esimd209 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %644, i32 0, i32 16, i32 2, i16 2, i32 0)
  %645 = zext <16 x i16> %.esimd209 to <16 x i32>
  %646 = mul <16 x i32> %645, splat (i32 -2082680531)
  %.esimd210 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd202, <16 x i32> %646, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %647 = lshr <16 x i32> %643, splat (i32 13)
  %648 = bitcast <16 x i32> %647 to <32 x i16>
  %.esimd211 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %648, i32 0, i32 16, i32 2, i16 0, i32 0)
  %649 = zext <16 x i16> %.esimd211 to <16 x i32>
  %650 = mul <16 x i32> %649, splat (i32 -2082680531)
  %.esimd212 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd210, <16 x i32> %650, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %651 = lshr <16 x i32> %643, splat (i32 10)
  %652 = bitcast <16 x i32> %651 to <32 x i16>
  %.esimd213 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %652, i32 0, i32 16, i32 2, i16 0, i32 0)
  %653 = zext <16 x i16> %.esimd213 to <16 x i32>
  %654 = mul <16 x i32> %653, splat (i32 -2082680531)
  %.esimd214 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd206, <16 x i32> %654, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %655 = lshr <16 x i32> %643, splat (i32 7)
  %656 = bitcast <16 x i32> %655 to <32 x i16>
  %.esimd215 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %656, i32 0, i32 16, i32 2, i16 0, i32 0)
  %657 = zext <16 x i16> %.esimd215 to <16 x i32>
  %658 = mul <16 x i32> %657, splat (i32 -2082680531)
  %.esimd216 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd214, <16 x i32> %658, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %.esimd217 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 16, i32 1, i16 32, i32 undef)
  %659 = shl <16 x i32> %.esimd217, %136
  %.esimd208656 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23466.decomp.1, i32 0, i32 8, i32 1, i16 64, i32 undef)
  %660 = lshr <16 x i32> %.esimd208656, %139
  %661 = or <16 x i32> %659, %660
  %662 = bitcast <16 x i32> %661 to <32 x i16>
  %.esimd219 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %662, i32 0, i32 16, i32 2, i16 2, i32 0)
  %663 = zext <16 x i16> %.esimd219 to <16 x i32>
  %664 = mul <16 x i32> %663, splat (i32 -2082680531)
  %.esimd220 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd212, <16 x i32> %664, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %665 = lshr <16 x i32> %661, splat (i32 13)
  %666 = bitcast <16 x i32> %665 to <32 x i16>
  %.esimd221 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %666, i32 0, i32 16, i32 2, i16 0, i32 0)
  %667 = zext <16 x i16> %.esimd221 to <16 x i32>
  %668 = mul <16 x i32> %667, splat (i32 -2082680531)
  %.esimd222 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd220, <16 x i32> %668, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %669 = lshr <16 x i32> %661, splat (i32 10)
  %670 = bitcast <16 x i32> %669 to <32 x i16>
  %.esimd223 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %670, i32 0, i32 16, i32 2, i16 0, i32 0)
  %671 = zext <16 x i16> %.esimd223 to <16 x i32>
  %672 = mul <16 x i32> %671, splat (i32 -2082680531)
  %.esimd224 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd216, <16 x i32> %672, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %673 = lshr <16 x i32> %661, splat (i32 7)
  %674 = bitcast <16 x i32> %673 to <32 x i16>
  %.esimd225 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %674, i32 0, i32 16, i32 2, i16 0, i32 0)
  %675 = zext <16 x i16> %.esimd225 to <16 x i32>
  %676 = mul <16 x i32> %675, splat (i32 -2082680531)
  %.esimd226 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd224, <16 x i32> %676, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %677 = ptrtoint ptr addrspace(4) %588 to i64
  %678 = call <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 8, <2 x i8> zeroinitializer, i64 0, i64 %677, i16 1, i32 0, <64 x i64> undef)
  %679 = call <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 8, <2 x i8> zeroinitializer, i64 0, i64 %677, i16 1, i32 512, <64 x i64> undef)
  %.postcast491.decomp.0 = bitcast <64 x i64> %678 to <128 x i32>
  %.postcast491.decomp.1 = bitcast <64 x i64> %679 to <128 x i32>
  %.esimd229 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast491.decomp.0, i32 0, i32 64, i32 1, i16 0, i32 undef)
  %.esimd230 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.0.4, <128 x i32> %.esimd222, <64 x i32> %.esimd229, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd229.1 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast491.decomp.0, i32 0, i32 64, i32 1, i16 256, i32 undef)
  %.esimd230.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.22.4, <128 x i32> %.esimd222, <64 x i32> %.esimd229.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd229.1132 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast491.decomp.1, i32 0, i32 64, i32 1, i16 0, i32 undef)
  %.esimd230.1133 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd230, <128 x i32> %.esimd226, <64 x i32> %.esimd229.1132, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd229.1.1 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast491.decomp.1, i32 0, i32 64, i32 1, i16 256, i32 undef)
  %.esimd230.1.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd230.1, <128 x i32> %.esimd226, <64 x i32> %.esimd229.1.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %680 = add i64 %677, 1024
  %681 = inttoptr i64 %680 to ptr addrspace(4)
  %682 = add nsw i32 %590, 1, !spirv.Decorations !22
  %683 = icmp eq i32 %682, %8
  br i1 %683, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10, label %684

684:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1
  %685 = add nuw nsw i32 %162, 4, !spirv.Decorations !25
  %686 = icmp slt i32 %685, %8
  br i1 %686, label %687, label %861

687:                                              ; preds = %684
  %688 = icmp eq i32 %682, 0
  br i1 %688, label %.loopexit.loopexit, label %.loopexit

.loopexit.loopexit:                               ; preds = %687
  %phicopy743 = bitcast i32 %160 to i32
  %phicopy811 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy812 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy811, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy813 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy814 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy812, <32 x i32> %phicopy813, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy815 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy816 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy814, <32 x i32> %phicopy815, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy817 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy818 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy816, <32 x i32> %phicopy817, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %phicopy875 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy876 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy875, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy877 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy878 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy876, <32 x i32> %phicopy877, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy879 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy880 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy878, <32 x i32> %phicopy879, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy881 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy882 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy880, <32 x i32> %phicopy881, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  br label %.loopexit

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1
  %689 = add nsw i32 %589, %44, !spirv.Decorations !22
  %690 = sext i32 %689 to i64
  %691 = add i64 %mul64recast446, %690
  %.iv32cast290 = bitcast i64 %691 to <2 x i32>
  %.LoSplit291655 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast290, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.HiSplit295 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %692 = mul <1 x i32> %.LoSplit291655, %.HiSplit295
  %.HiSplit292 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast290, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %.LoSplit294654 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %693 = mul <1 x i32> %.HiSplit292, %.LoSplit294654
  %.LoSplit291 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast290, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.LoSplit294 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %694 = call <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32> %.LoSplit291, <1 x i32> %.LoSplit294, <1 x i32> zeroinitializer)
  %.lo301 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %694, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %mul64partial_join296 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo301, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi300 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %694, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %695 = call <1 x i32> @llvm.genx.add3.v1i32.v1i32(<1 x i32> %693, <1 x i32> %.hi300, <1 x i32> %692)
  %mul64joined297 = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %mul64partial_join296, <1 x i32> %695, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %mul64recast299 = bitcast <2 x i32> %mul64joined297 to i64
  %696 = shl i64 %mul64recast299, 2
  %697 = add i64 %155, %696
  %698 = bitcast <128 x i32> %.esimd230.1133 to <64 x i64>
  %.esimd231 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %698, i32 0, i32 8, i32 1, i16 0, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %697, i16 1, i32 0, <8 x i64> %.esimd231)
  %699 = add i64 %697, %158
  %.esimd231.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %698, i32 0, i32 8, i32 1, i16 64, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %699, i16 1, i32 0, <8 x i64> %.esimd231.1)
  %700 = add i64 %697, %.idx138
  %.esimd231.2 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %698, i32 0, i32 8, i32 1, i16 128, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %700, i16 1, i32 0, <8 x i64> %.esimd231.2)
  %701 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 12), <1 x i32> zeroinitializer)
  %.lo289 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %701, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx181.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo289, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi288 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %701, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx181.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx181.imul.partial_join, <1 x i32> %.hi288, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx181.imul.recast = bitcast <2 x i32> %.idx181.imul.joined to i64
  %702 = add i64 %697, %.idx181.imul.recast
  %.esimd231.3 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %698, i32 0, i32 8, i32 1, i16 192, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %702, i16 1, i32 0, <8 x i64> %.esimd231.3)
  %703 = add i64 %697, %154
  %.esimd231.4 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %698, i32 0, i32 8, i32 1, i16 256, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %703, i16 1, i32 0, <8 x i64> %.esimd231.4)
  %704 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 20), <1 x i32> zeroinitializer)
  %.lo286 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %704, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx183.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo286, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi285 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %704, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx183.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx183.imul.partial_join, <1 x i32> %.hi285, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx183.imul.recast = bitcast <2 x i32> %.idx183.imul.joined to i64
  %705 = add i64 %697, %.idx183.imul.recast
  %.esimd231.5 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %698, i32 0, i32 8, i32 1, i16 320, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %705, i16 1, i32 0, <8 x i64> %.esimd231.5)
  %706 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 24), <1 x i32> zeroinitializer)
  %.lo283 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %706, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx184.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo283, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi282 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %706, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx184.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx184.imul.partial_join, <1 x i32> %.hi282, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx184.imul.recast = bitcast <2 x i32> %.idx184.imul.joined to i64
  %707 = add i64 %697, %.idx184.imul.recast
  %.esimd231.6 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %698, i32 0, i32 8, i32 1, i16 384, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %707, i16 1, i32 0, <8 x i64> %.esimd231.6)
  %708 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 28), <1 x i32> zeroinitializer)
  %.lo280 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %708, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx185.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo280, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi279 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %708, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx185.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx185.imul.partial_join, <1 x i32> %.hi279, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx185.imul.recast = bitcast <2 x i32> %.idx185.imul.joined to i64
  %709 = add i64 %697, %.idx185.imul.recast
  %.esimd231.7 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %698, i32 0, i32 8, i32 1, i16 448, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %709, i16 1, i32 0, <8 x i64> %.esimd231.7)
  %710 = bitcast <128 x i32> %.esimd230.1.1 to <64 x i64>
  %711 = add i64 %697, %.idx144
  %.esimd231.1134 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %710, i32 0, i32 8, i32 1, i16 0, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %711, i16 1, i32 0, <8 x i64> %.esimd231.1134)
  %712 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 36), <1 x i32> zeroinitializer)
  %.lo277 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %712, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx187.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo277, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi276 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %712, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx187.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx187.imul.partial_join, <1 x i32> %.hi276, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx187.imul.recast = bitcast <2 x i32> %.idx187.imul.joined to i64
  %713 = add i64 %697, %.idx187.imul.recast
  %.esimd231.1.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %710, i32 0, i32 8, i32 1, i16 64, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %713, i16 1, i32 0, <8 x i64> %.esimd231.1.1)
  %714 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 40), <1 x i32> zeroinitializer)
  %.lo274 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %714, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx188.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo274, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi273 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %714, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx188.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx188.imul.partial_join, <1 x i32> %.hi273, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx188.imul.recast = bitcast <2 x i32> %.idx188.imul.joined to i64
  %715 = add i64 %697, %.idx188.imul.recast
  %.esimd231.2.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %710, i32 0, i32 8, i32 1, i16 128, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %715, i16 1, i32 0, <8 x i64> %.esimd231.2.1)
  %716 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 44), <1 x i32> zeroinitializer)
  %.lo271 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %716, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx189.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo271, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi270 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %716, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx189.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx189.imul.partial_join, <1 x i32> %.hi270, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx189.imul.recast = bitcast <2 x i32> %.idx189.imul.joined to i64
  %717 = add i64 %697, %.idx189.imul.recast
  %.esimd231.3.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %710, i32 0, i32 8, i32 1, i16 192, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %717, i16 1, i32 0, <8 x i64> %.esimd231.3.1)
  %718 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 48), <1 x i32> zeroinitializer)
  %.lo268 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %718, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx190.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo268, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi267 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %718, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx190.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx190.imul.partial_join, <1 x i32> %.hi267, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx190.imul.recast = bitcast <2 x i32> %.idx190.imul.joined to i64
  %719 = add i64 %697, %.idx190.imul.recast
  %.esimd231.4.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %710, i32 0, i32 8, i32 1, i16 256, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %719, i16 1, i32 0, <8 x i64> %.esimd231.4.1)
  %720 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 52), <1 x i32> zeroinitializer)
  %.lo265 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %720, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx191.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo265, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi264 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %720, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx191.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx191.imul.partial_join, <1 x i32> %.hi264, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx191.imul.recast = bitcast <2 x i32> %.idx191.imul.joined to i64
  %721 = add i64 %697, %.idx191.imul.recast
  %.esimd231.5.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %710, i32 0, i32 8, i32 1, i16 320, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %721, i16 1, i32 0, <8 x i64> %.esimd231.5.1)
  %722 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 56), <1 x i32> zeroinitializer)
  %.lo262 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %722, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx192.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo262, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi261 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %722, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx192.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx192.imul.partial_join, <1 x i32> %.hi261, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx192.imul.recast = bitcast <2 x i32> %.idx192.imul.joined to i64
  %723 = add i64 %697, %.idx192.imul.recast
  %.esimd231.6.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %710, i32 0, i32 8, i32 1, i16 384, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %723, i16 1, i32 0, <8 x i64> %.esimd231.6.1)
  %724 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 60), <1 x i32> zeroinitializer)
  %.lo259 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %724, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx193.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo259, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi258 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %724, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx193.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx193.imul.partial_join, <1 x i32> %.hi258, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx193.imul.recast = bitcast <2 x i32> %.idx193.imul.joined to i64
  %725 = add i64 %697, %.idx193.imul.recast
  %.esimd231.7.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %710, i32 0, i32 8, i32 1, i16 448, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %725, i16 1, i32 0, <8 x i64> %.esimd231.7.1)
  %726 = add nsw i32 %589, 1, !spirv.Decorations !22
  %727 = add nuw nsw i32 %162, 4, !spirv.Decorations !25
  %728 = icmp slt i32 %727, %8
  br i1 %728, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10..loopexit_crit_edge, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10
  %phicopy741 = bitcast i32 %160 to i32
  %phicopy752 = bitcast ptr addrspace(4) %142 to ptr addrspace(4)
  br label %861

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10..loopexit_crit_edge: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10
  %phicopy742 = bitcast i32 %160 to i32
  %phicopy753 = bitcast ptr addrspace(4) %142 to ptr addrspace(4)
  %phicopy803 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy804 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy803, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy805 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy806 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy804, <32 x i32> %phicopy805, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy807 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy808 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy806, <32 x i32> %phicopy807, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy809 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy810 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy808, <32 x i32> %phicopy809, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  %phicopy867 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 0, i32 undef)
  %phicopy868 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> undef, <32 x i32> %phicopy867, i32 0, i32 32, i32 1, i16 0, i32 undef, i1 true)
  %phicopy869 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 128, i32 undef)
  %phicopy870 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy868, <32 x i32> %phicopy869, i32 0, i32 32, i32 1, i16 128, i32 undef, i1 true)
  %phicopy871 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 256, i32 undef)
  %phicopy872 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy870, <32 x i32> %phicopy871, i32 0, i32 32, i32 1, i16 256, i32 undef, i1 true)
  %phicopy873 = call <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32> %constant.split.ill96699, i32 0, i32 32, i32 1, i16 384, i32 undef)
  %phicopy874 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32> %phicopy872, <32 x i32> %phicopy873, i32 0, i32 32, i32 1, i16 384, i32 undef, i1 true)
  br label %.loopexit

.loopexit:                                        ; preds = %687, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10..loopexit_crit_edge, %.loopexit.loopexit
  %.sroa.22.5 = phi <128 x i32> [ %.esimd230.1.1, %687 ], [ %phicopy810, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10..loopexit_crit_edge ], [ %phicopy818, %.loopexit.loopexit ]
  %.sroa.0.5 = phi <128 x i32> [ %.esimd230.1133, %687 ], [ %phicopy874, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10..loopexit_crit_edge ], [ %phicopy882, %.loopexit.loopexit ]
  %729 = phi ptr addrspace(4) [ %681, %687 ], [ %phicopy753, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10..loopexit_crit_edge ], [ %681, %.loopexit.loopexit ]
  %730 = phi i32 [ %589, %687 ], [ %726, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10..loopexit_crit_edge ], [ %589, %.loopexit.loopexit ]
  %731 = phi i32 [ %682, %687 ], [ %phicopy742, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10..loopexit_crit_edge ], [ %phicopy743, %.loopexit.loopexit ]
  br i1 %.not181, label %732, label %.loopexit._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit_crit_edge

.loopexit._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit_crit_edge: ; preds = %.loopexit
  %phicopy729 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit

732:                                              ; preds = %.loopexit
  %733 = ptrtoint ptr addrspace(1) %.41614 to i64
  %734 = call <8 x i64> @llvm.vc.internal.lsc.load.ugm.v8i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %733, i16 1, i32 0, <8 x i64> undef)
  %.decomp.1643 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v8i64.i16.i1(<12 x i64> undef, <8 x i64> %734, i32 0, i32 8, i32 1, i16 0, i32 undef, i1 true)
  %735 = call <4 x i64> @llvm.vc.internal.lsc.load.ugm.v4i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 4, <2 x i8> zeroinitializer, i64 0, i64 %733, i16 1, i32 64, <4 x i64> undef)
  %.decomp.1644 = call <12 x i64> @llvm.genx.wrregioni.v12i64.v4i64.i16.i1(<12 x i64> %.decomp.1643, <4 x i64> %735, i32 0, i32 4, i32 1, i16 64, i32 undef, i1 true)
  %.postcast490.decomp.1 = bitcast <12 x i64> %.decomp.1644 to <24 x i32>
  %736 = add nsw i32 %.41623, 1, !spirv.Decorations !22
  %737 = icmp eq i32 %736, %8
  br i1 %737, label %741, label %738

738:                                              ; preds = %732
  %739 = add i64 %733, %156
  %740 = inttoptr i64 %739 to ptr addrspace(1)
  %phicopy716 = bitcast i32 %83 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit

741:                                              ; preds = %732
  %742 = add i64 %733, %157
  %743 = inttoptr i64 %742 to ptr addrspace(1)
  %phicopy710 = bitcast i32 %82 to i32
  %phicopy730 = bitcast i32 %84 to i32
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit: ; preds = %.loopexit._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit_crit_edge, %738, %741
  %.esimd23467.decomp.0 = phi <16 x i32> [ %.esimd186.decomp.0, %.loopexit._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit_crit_edge ], [ undef, %741 ], [ undef, %738 ]
  %.esimd23467.decomp.1 = phi <24 x i32> [ %.esimd23466.decomp.1, %.loopexit._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit_crit_edge ], [ %.postcast490.decomp.1, %741 ], [ %.postcast490.decomp.1, %738 ]
  %.31622 = phi i32 [ %.41623, %.loopexit._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit_crit_edge ], [ %phicopy710, %741 ], [ %736, %738 ]
  %.31613 = phi ptr addrspace(1) [ %.41614, %.loopexit._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit_crit_edge ], [ %743, %741 ], [ %740, %738 ]
  %.3 = phi i32 [ %phicopy729, %.loopexit._ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit_crit_edge ], [ %phicopy730, %741 ], [ %phicopy716, %738 ]
  %.esimd235.split0 = call <4 x i32> @llvm.genx.rdregioni.v4i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 4, i32 1, i16 64, i32 undef)
  %.esimd236.join0.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v4i32.i16.i1(<16 x i32> %.esimd23847.decomp.0, <4 x i32> %.esimd235.split0, i32 0, i32 4, i32 1, i16 36, i32 undef, i1 true)
  %.esimd235.split4 = call <2 x i32> @llvm.genx.rdregioni.v2i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 2, i32 1, i16 80, i32 undef)
  %.esimd236.join4.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v2i32.i16.i1(<16 x i32> %.esimd236.join0.decomp.0, <2 x i32> %.esimd235.split4, i32 0, i32 2, i32 1, i16 52, i32 undef, i1 true)
  %.esimd235.split6 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 1, i32 1, i16 88, i32 undef)
  %.esimd236.join6.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32> %.esimd236.join4.decomp.0, <1 x i32> %.esimd235.split6, i32 0, i32 1, i32 1, i16 60, i32 undef, i1 true)
  %.esimd237 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 1, i32 1, i16 92, i32 undef)
  %.esimd238.decomp.0 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32> %.esimd236.join6.decomp.0, <1 x i32> %.esimd237, i32 0, i32 1, i32 1, i16 32, i32 undef, i1 true)
  %.esimd240 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 8, i32 1, i16 0, i32 undef)
  %744 = lshr <16 x i32> %.esimd240, %121
  %.esimd239 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v16i32.i16(<16 x i32> %.esimd238.decomp.0, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %745 = shl <16 x i32> %.esimd239, %118
  %746 = or <16 x i32> %744, %745
  %747 = bitcast <16 x i32> %746 to <32 x i16>
  %.esimd241 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %747, i32 0, i32 16, i32 2, i16 2, i32 0)
  %748 = zext <16 x i16> %.esimd241 to <16 x i32>
  %749 = mul <16 x i32> %748, splat (i32 -2082680531)
  %.esimd242 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> undef, <16 x i32> %749, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %750 = lshr <16 x i32> %746, splat (i32 13)
  %751 = bitcast <16 x i32> %750 to <32 x i16>
  %.esimd243 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %751, i32 0, i32 16, i32 2, i16 0, i32 0)
  %752 = zext <16 x i16> %.esimd243 to <16 x i32>
  %753 = mul <16 x i32> %752, splat (i32 -2082680531)
  %.esimd244 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd242, <16 x i32> %753, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %754 = lshr <16 x i32> %746, splat (i32 10)
  %755 = bitcast <16 x i32> %754 to <32 x i16>
  %.esimd245 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %755, i32 0, i32 16, i32 2, i16 0, i32 0)
  %756 = zext <16 x i16> %.esimd245 to <16 x i32>
  %757 = mul <16 x i32> %756, splat (i32 -2082680531)
  %.esimd246 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> undef, <16 x i32> %757, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %758 = lshr <16 x i32> %746, splat (i32 7)
  %759 = bitcast <16 x i32> %758 to <32 x i16>
  %.esimd247 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %759, i32 0, i32 16, i32 2, i16 0, i32 0)
  %760 = zext <16 x i16> %.esimd247 to <16 x i32>
  %761 = mul <16 x i32> %760, splat (i32 -2082680531)
  %.esimd248 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd246, <16 x i32> %761, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %.esimd250 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %762 = lshr <16 x i32> %.esimd250, %127
  %.esimd240653 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 8, i32 1, i16 0, i32 undef)
  %763 = shl <16 x i32> %.esimd240653, %124
  %764 = or <16 x i32> %762, %763
  %765 = bitcast <16 x i32> %764 to <32 x i16>
  %.esimd251 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %765, i32 0, i32 16, i32 2, i16 2, i32 0)
  %766 = zext <16 x i16> %.esimd251 to <16 x i32>
  %767 = mul <16 x i32> %766, splat (i32 -2082680531)
  %.esimd252 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd244, <16 x i32> %767, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %768 = lshr <16 x i32> %764, splat (i32 13)
  %769 = bitcast <16 x i32> %768 to <32 x i16>
  %.esimd253 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %769, i32 0, i32 16, i32 2, i16 0, i32 0)
  %770 = zext <16 x i16> %.esimd253 to <16 x i32>
  %771 = mul <16 x i32> %770, splat (i32 -2082680531)
  %.esimd254 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd252, <16 x i32> %771, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %772 = lshr <16 x i32> %764, splat (i32 10)
  %773 = bitcast <16 x i32> %772 to <32 x i16>
  %.esimd255 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %773, i32 0, i32 16, i32 2, i16 0, i32 0)
  %774 = zext <16 x i16> %.esimd255 to <16 x i32>
  %775 = mul <16 x i32> %774, splat (i32 -2082680531)
  %.esimd256 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd248, <16 x i32> %775, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %776 = lshr <16 x i32> %764, splat (i32 7)
  %777 = bitcast <16 x i32> %776 to <32 x i16>
  %.esimd257 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %777, i32 0, i32 16, i32 2, i16 0, i32 0)
  %778 = zext <16 x i16> %.esimd257 to <16 x i32>
  %779 = mul <16 x i32> %778, splat (i32 -2082680531)
  %.esimd258 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd256, <16 x i32> %779, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %.esimd260 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 8, i32 1, i16 64, i32 undef)
  %780 = lshr <16 x i32> %.esimd260, %133
  %.esimd250652 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 8, i32 1, i16 32, i32 undef)
  %781 = shl <16 x i32> %.esimd250652, %130
  %782 = or <16 x i32> %780, %781
  %783 = bitcast <16 x i32> %782 to <32 x i16>
  %.esimd261 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %783, i32 0, i32 16, i32 2, i16 2, i32 0)
  %784 = zext <16 x i16> %.esimd261 to <16 x i32>
  %785 = mul <16 x i32> %784, splat (i32 -2082680531)
  %.esimd262 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd254, <16 x i32> %785, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %786 = lshr <16 x i32> %782, splat (i32 13)
  %787 = bitcast <16 x i32> %786 to <32 x i16>
  %.esimd263 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %787, i32 0, i32 16, i32 2, i16 0, i32 0)
  %788 = zext <16 x i16> %.esimd263 to <16 x i32>
  %789 = mul <16 x i32> %788, splat (i32 -2082680531)
  %.esimd264 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd262, <16 x i32> %789, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %790 = lshr <16 x i32> %782, splat (i32 10)
  %791 = bitcast <16 x i32> %790 to <32 x i16>
  %.esimd265 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %791, i32 0, i32 16, i32 2, i16 0, i32 0)
  %792 = zext <16 x i16> %.esimd265 to <16 x i32>
  %793 = mul <16 x i32> %792, splat (i32 -2082680531)
  %.esimd266 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd258, <16 x i32> %793, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %794 = lshr <16 x i32> %782, splat (i32 7)
  %795 = bitcast <16 x i32> %794 to <32 x i16>
  %.esimd267 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %795, i32 0, i32 16, i32 2, i16 0, i32 0)
  %796 = zext <16 x i16> %.esimd267 to <16 x i32>
  %797 = mul <16 x i32> %796, splat (i32 -2082680531)
  %.esimd268 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd266, <16 x i32> %797, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %.esimd260651 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 8, i32 1, i16 64, i32 undef)
  %798 = lshr <16 x i32> %.esimd260651, %139
  %.esimd269 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32> %.esimd23847.decomp.1, i32 0, i32 16, i32 1, i16 32, i32 undef)
  %799 = shl <16 x i32> %.esimd269, %136
  %800 = or <16 x i32> %799, %798
  %801 = bitcast <16 x i32> %800 to <32 x i16>
  %.esimd271 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %801, i32 0, i32 16, i32 2, i16 2, i32 0)
  %802 = zext <16 x i16> %.esimd271 to <16 x i32>
  %803 = mul <16 x i32> %802, splat (i32 -2082680531)
  %.esimd272 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd264, <16 x i32> %803, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %804 = lshr <16 x i32> %800, splat (i32 13)
  %805 = bitcast <16 x i32> %804 to <32 x i16>
  %.esimd273 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %805, i32 0, i32 16, i32 2, i16 0, i32 0)
  %806 = zext <16 x i16> %.esimd273 to <16 x i32>
  %807 = mul <16 x i32> %806, splat (i32 -2082680531)
  %.esimd274 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd272, <16 x i32> %807, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %808 = lshr <16 x i32> %800, splat (i32 10)
  %809 = bitcast <16 x i32> %808 to <32 x i16>
  %.esimd275 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %809, i32 0, i32 16, i32 2, i16 0, i32 0)
  %810 = zext <16 x i16> %.esimd275 to <16 x i32>
  %811 = mul <16 x i32> %810, splat (i32 -2082680531)
  %.esimd276 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd268, <16 x i32> %811, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %812 = lshr <16 x i32> %800, splat (i32 7)
  %813 = bitcast <16 x i32> %812 to <32 x i16>
  %.esimd277 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %813, i32 0, i32 16, i32 2, i16 0, i32 0)
  %814 = zext <16 x i16> %.esimd277 to <16 x i32>
  %815 = mul <16 x i32> %814, splat (i32 -2082680531)
  %.esimd278 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd276, <16 x i32> %815, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %816 = ptrtoint ptr addrspace(4) %729 to i64
  %817 = call <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 8, <2 x i8> zeroinitializer, i64 0, i64 %816, i16 1, i32 0, <64 x i64> undef)
  %818 = call <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 8, <2 x i8> zeroinitializer, i64 0, i64 %816, i16 1, i32 512, <64 x i64> undef)
  %.postcast.decomp.0 = bitcast <64 x i64> %817 to <128 x i32>
  %.postcast.decomp.1 = bitcast <64 x i64> %818 to <128 x i32>
  %.esimd281 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast.decomp.0, i32 0, i32 64, i32 1, i16 0, i32 undef)
  %.esimd282 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.0.5, <128 x i32> %.esimd274, <64 x i32> %.esimd281, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd281.1 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast.decomp.0, i32 0, i32 64, i32 1, i16 256, i32 undef)
  %.esimd282.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.22.5, <128 x i32> %.esimd274, <64 x i32> %.esimd281.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd281.1135 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast.decomp.1, i32 0, i32 64, i32 1, i16 0, i32 undef)
  %.esimd282.1136 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd282, <128 x i32> %.esimd278, <64 x i32> %.esimd281.1135, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd281.1.1 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32> %.postcast.decomp.1, i32 0, i32 64, i32 1, i16 256, i32 undef)
  %.esimd282.1.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd282.1, <128 x i32> %.esimd278, <64 x i32> %.esimd281.1.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %819 = add i64 %816, 1024
  %820 = inttoptr i64 %819 to ptr addrspace(4)
  %821 = add nsw i32 %731, 1, !spirv.Decorations !22
  %822 = icmp eq i32 %821, %8
  br i1 %822, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit, label %861

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit
  %823 = add nsw i32 %730, %44, !spirv.Decorations !22
  %824 = sext i32 %823 to i64
  %825 = add i64 %mul64recast446, %824
  %.iv32cast = bitcast i64 %825 to <2 x i32>
  %.LoSplit = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.LoSplit253 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %826 = call <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32> %.LoSplit, <1 x i32> %.LoSplit253, <1 x i32> zeroinitializer)
  %.LoSplit650 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %.HiSplit254 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %827 = mul <1 x i32> %.LoSplit650, %.HiSplit254
  %.HiSplit = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast, i32 0, i32 1, i32 2, i16 4, i32 undef)
  %.LoSplit253649 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32> %.iv32cast428, i32 0, i32 1, i32 2, i16 0, i32 undef)
  %828 = mul <1 x i32> %.HiSplit, %.LoSplit253649
  %.lo256 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %826, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %mul64partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo256, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi255 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %826, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %829 = call <1 x i32> @llvm.genx.add3.v1i32.v1i32(<1 x i32> %828, <1 x i32> %.hi255, <1 x i32> %827)
  %mul64joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %mul64partial_join, <1 x i32> %829, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %mul64recast = bitcast <2 x i32> %mul64joined to i64
  %830 = shl i64 %mul64recast, 2
  %831 = add i64 %155, %830
  %832 = bitcast <128 x i32> %.esimd282.1136 to <64 x i64>
  %.esimd283 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %832, i32 0, i32 8, i32 1, i16 0, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %831, i16 1, i32 0, <8 x i64> %.esimd283)
  %833 = add i64 %831, %158
  %.esimd283.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %832, i32 0, i32 8, i32 1, i16 64, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %833, i16 1, i32 0, <8 x i64> %.esimd283.1)
  %834 = add i64 %831, %.idx138
  %.esimd283.2 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %832, i32 0, i32 8, i32 1, i16 128, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %834, i16 1, i32 0, <8 x i64> %.esimd283.2)
  %835 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 12), <1 x i32> zeroinitializer)
  %.lo251 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %835, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx195.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo251, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi250 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %835, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx195.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx195.imul.partial_join, <1 x i32> %.hi250, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx195.imul.recast = bitcast <2 x i32> %.idx195.imul.joined to i64
  %836 = add i64 %831, %.idx195.imul.recast
  %.esimd283.3 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %832, i32 0, i32 8, i32 1, i16 192, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %836, i16 1, i32 0, <8 x i64> %.esimd283.3)
  %837 = add i64 %831, %154
  %.esimd283.4 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %832, i32 0, i32 8, i32 1, i16 256, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %837, i16 1, i32 0, <8 x i64> %.esimd283.4)
  %838 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 20), <1 x i32> zeroinitializer)
  %.lo248 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %838, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx197.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo248, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi247 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %838, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx197.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx197.imul.partial_join, <1 x i32> %.hi247, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx197.imul.recast = bitcast <2 x i32> %.idx197.imul.joined to i64
  %839 = add i64 %831, %.idx197.imul.recast
  %.esimd283.5 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %832, i32 0, i32 8, i32 1, i16 320, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %839, i16 1, i32 0, <8 x i64> %.esimd283.5)
  %840 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 24), <1 x i32> zeroinitializer)
  %.lo245 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %840, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx198.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo245, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi244 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %840, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx198.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx198.imul.partial_join, <1 x i32> %.hi244, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx198.imul.recast = bitcast <2 x i32> %.idx198.imul.joined to i64
  %841 = add i64 %831, %.idx198.imul.recast
  %.esimd283.6 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %832, i32 0, i32 8, i32 1, i16 384, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %841, i16 1, i32 0, <8 x i64> %.esimd283.6)
  %842 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 28), <1 x i32> zeroinitializer)
  %.lo242 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %842, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx199.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo242, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi241 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %842, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx199.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx199.imul.partial_join, <1 x i32> %.hi241, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx199.imul.recast = bitcast <2 x i32> %.idx199.imul.joined to i64
  %843 = add i64 %831, %.idx199.imul.recast
  %.esimd283.7 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %832, i32 0, i32 8, i32 1, i16 448, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %843, i16 1, i32 0, <8 x i64> %.esimd283.7)
  %844 = bitcast <128 x i32> %.esimd282.1.1 to <64 x i64>
  %845 = add i64 %831, %.idx144
  %.esimd283.1137 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %844, i32 0, i32 8, i32 1, i16 0, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %845, i16 1, i32 0, <8 x i64> %.esimd283.1137)
  %846 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 36), <1 x i32> zeroinitializer)
  %.lo239 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %846, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx201.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo239, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi238 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %846, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx201.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx201.imul.partial_join, <1 x i32> %.hi238, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx201.imul.recast = bitcast <2 x i32> %.idx201.imul.joined to i64
  %847 = add i64 %831, %.idx201.imul.recast
  %.esimd283.1.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %844, i32 0, i32 8, i32 1, i16 64, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %847, i16 1, i32 0, <8 x i64> %.esimd283.1.1)
  %848 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 40), <1 x i32> zeroinitializer)
  %.lo236 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %848, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx202.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo236, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi235 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %848, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx202.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx202.imul.partial_join, <1 x i32> %.hi235, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx202.imul.recast = bitcast <2 x i32> %.idx202.imul.joined to i64
  %849 = add i64 %831, %.idx202.imul.recast
  %.esimd283.2.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %844, i32 0, i32 8, i32 1, i16 128, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %849, i16 1, i32 0, <8 x i64> %.esimd283.2.1)
  %850 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 44), <1 x i32> zeroinitializer)
  %.lo233 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %850, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx203.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo233, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi232 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %850, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx203.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx203.imul.partial_join, <1 x i32> %.hi232, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx203.imul.recast = bitcast <2 x i32> %.idx203.imul.joined to i64
  %851 = add i64 %831, %.idx203.imul.recast
  %.esimd283.3.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %844, i32 0, i32 8, i32 1, i16 192, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %851, i16 1, i32 0, <8 x i64> %.esimd283.3.1)
  %852 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 48), <1 x i32> zeroinitializer)
  %.lo230 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %852, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx204.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo230, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi229 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %852, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx204.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx204.imul.partial_join, <1 x i32> %.hi229, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx204.imul.recast = bitcast <2 x i32> %.idx204.imul.joined to i64
  %853 = add i64 %831, %.idx204.imul.recast
  %.esimd283.4.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %844, i32 0, i32 8, i32 1, i16 256, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %853, i16 1, i32 0, <8 x i64> %.esimd283.4.1)
  %854 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 52), <1 x i32> zeroinitializer)
  %.lo227 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %854, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx205.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo227, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi226 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %854, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx205.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx205.imul.partial_join, <1 x i32> %.hi226, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx205.imul.recast = bitcast <2 x i32> %.idx205.imul.joined to i64
  %855 = add i64 %831, %.idx205.imul.recast
  %.esimd283.5.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %844, i32 0, i32 8, i32 1, i16 320, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %855, i16 1, i32 0, <8 x i64> %.esimd283.5.1)
  %856 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 56), <1 x i32> zeroinitializer)
  %.lo224 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %856, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx206.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo224, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi223 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %856, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx206.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx206.imul.partial_join, <1 x i32> %.hi223, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx206.imul.recast = bitcast <2 x i32> %.idx206.imul.joined to i64
  %857 = add i64 %831, %.idx206.imul.recast
  %.esimd283.6.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %844, i32 0, i32 8, i32 1, i16 384, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %857, i16 1, i32 0, <8 x i64> %.esimd283.6.1)
  %858 = call <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32> %.bitcast422, <1 x i32> splat (i32 60), <1 x i32> zeroinitializer)
  %.lo = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %858, i32 1, i32 1, i32 1, i16 0, i32 undef)
  %.idx207.imul.partial_join = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> undef, <1 x i32> %.lo, i32 0, i32 1, i32 2, i16 0, i32 undef, i1 true)
  %.hi = call <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32> %858, i32 1, i32 1, i32 1, i16 64, i32 undef)
  %.idx207.imul.joined = call <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32> %.idx207.imul.partial_join, <1 x i32> %.hi, i32 0, i32 1, i32 2, i16 4, i32 undef, i1 true)
  %.idx207.imul.recast = bitcast <2 x i32> %.idx207.imul.joined to i64
  %859 = add i64 %831, %.idx207.imul.recast
  %.esimd283.7.1 = call <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64> %844, i32 0, i32 8, i32 1, i16 448, i32 undef)
  call void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1> splat (i1 true), i8 3, i8 4, i8 5, <2 x i8> zeroinitializer, i64 0, i64 %859, i16 1, i32 0, <8 x i64> %.esimd283.7.1)
  %860 = add nsw i32 %730, 1, !spirv.Decorations !22
  %phicopy744 = bitcast i32 %160 to i32
  %phicopy754 = bitcast ptr addrspace(4) %142 to ptr addrspace(4)
  br label %861

861:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit, %684, %543, %402, %261, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit
  %.sroa.22.6 = phi <128 x i32> [ %.esimd282.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd282.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd230.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd230.1.1, %684 ], [ %.esimd178.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd178.1.1, %543 ], [ %.esimd126.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd126.1.1, %402 ], [ %.esimd74.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd74.1.1, %261 ]
  %.sroa.0.6 = phi <128 x i32> [ %.esimd282.1136, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd282.1136, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd230.1133, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd230.1133, %684 ], [ %.esimd178.1130, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd178.1130, %543 ], [ %.esimd126.1127, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd126.1127, %402 ], [ %.esimd74.1124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd74.1124, %261 ]
  %.esimd23465.decomp.0 = phi <16 x i32> [ %.esimd23467.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd23467.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd186.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd186.decomp.0, %684 ], [ %.esimd23466.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd23466.decomp.0, %543 ], [ %.esimd23466.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd23466.decomp.0, %402 ], [ %.esimd23466.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd23466.decomp.0, %261 ]
  %.esimd23465.decomp.1 = phi <24 x i32> [ %.esimd23467.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd23467.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd23466.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd23466.decomp.1, %684 ], [ %.esimd23466.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd23466.decomp.1, %543 ], [ %.esimd23466.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd23466.decomp.1, %402 ], [ %.esimd23466.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd23466.decomp.1, %261 ]
  %.esimd18261.decomp.0 = phi <16 x i32> [ %.esimd18263.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd18263.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd18263.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd18263.decomp.0, %684 ], [ %.esimd134.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd134.decomp.0, %543 ], [ %.esimd18262.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd18262.decomp.0, %402 ], [ %.esimd18262.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd18262.decomp.0, %261 ]
  %.esimd18261.decomp.1 = phi <24 x i32> [ %.esimd18263.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd18263.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd18263.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd18263.decomp.1, %684 ], [ %.esimd18262.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd18262.decomp.1, %543 ], [ %.esimd18262.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd18262.decomp.1, %402 ], [ %.esimd18262.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd18262.decomp.1, %261 ]
  %.esimd13057.decomp.0 = phi <16 x i32> [ %.esimd13059.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd13059.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd13059.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd13059.decomp.0, %684 ], [ %.esimd13059.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd13059.decomp.0, %543 ], [ %.esimd82.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd82.decomp.0, %402 ], [ %.esimd13058.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd13058.decomp.0, %261 ]
  %.esimd13057.decomp.1 = phi <24 x i32> [ %.esimd13059.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd13059.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd13059.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd13059.decomp.1, %684 ], [ %.esimd13059.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd13059.decomp.1, %543 ], [ %.esimd13058.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd13058.decomp.1, %402 ], [ %.esimd13058.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd13058.decomp.1, %261 ]
  %.esimd7850.decomp.0 = phi <16 x i32> [ %.esimd7851.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd7851.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd7851.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd7851.decomp.0, %684 ], [ %.esimd7851.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd7851.decomp.0, %543 ], [ %.esimd7851.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd7851.decomp.0, %402 ], [ %.esimd30.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd30.decomp.0, %261 ]
  %.esimd7850.decomp.1 = phi <24 x i32> [ %.esimd7851.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd7851.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd7851.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd7851.decomp.1, %684 ], [ %.esimd7851.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd7851.decomp.1, %543 ], [ %.esimd7851.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd7851.decomp.1, %402 ], [ %.esimd7849.decomp.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd7849.decomp.1, %261 ]
  %.esimd23846.decomp.0 = phi <16 x i32> [ %.esimd238.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd238.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd23847.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.esimd23847.decomp.0, %684 ], [ %.esimd23847.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.esimd23847.decomp.0, %543 ], [ %.esimd23847.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.esimd23847.decomp.0, %402 ], [ %.esimd23847.decomp.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.esimd23847.decomp.0, %261 ]
  %.21621 = phi i32 [ %.31622, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.31622, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.41623, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.41623, %684 ], [ %.51624, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.51624, %543 ], [ %.61625, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.61625, %402 ], [ %.71626, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.71626, %261 ]
  %.21612 = phi ptr addrspace(1) [ %.31613, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.31613, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.41614, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.41614, %684 ], [ %.51615, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.51615, %543 ], [ %.61616, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.61616, %402 ], [ %.71617, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.71617, %261 ]
  %.2 = phi i32 [ %.3, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.3, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.4, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %.4, %684 ], [ %.5, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %.5, %543 ], [ %.6, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %.6, %402 ], [ %.7, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %.7, %261 ]
  %862 = phi ptr addrspace(4) [ %phicopy754, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %820, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %phicopy752, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %681, %684 ], [ %phicopy750, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %540, %543 ], [ %phicopy748, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %399, %402 ], [ %phicopy746, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %258, %261 ]
  %863 = phi i32 [ %860, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %730, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %726, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %589, %684 ], [ %585, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %448, %543 ], [ %444, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %307, %402 ], [ %303, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %164, %261 ]
  %864 = phi i32 [ %phicopy744, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %821, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %phicopy741, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10._crit_edge ], [ %682, %684 ], [ %phicopy738, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11._crit_edge ], [ %541, %543 ], [ %phicopy735, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12._crit_edge ], [ %400, %402 ], [ %phicopy732, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13._crit_edge ], [ %259, %261 ]
  %865 = add nuw nsw i32 %162, 5, !spirv.Decorations !25
  %866 = icmp slt i32 %865, %8
  br i1 %866, label %.lr.ph, label %._crit_edge

._crit_edge:                                      ; preds = %861, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3
  ret void
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !30 i32 @llvm.genx.group.id.x() #0

; Function Attrs: nounwind willreturn memory(read)
; Unknown intrinsic
declare !internal_intrinsic_id !31 <8 x i64> @llvm.vc.internal.lsc.load.ugm.v8i64.v1i1.v2i8.i64(<1 x i1>, i8, i8, i8, <2 x i8>, i64, i64, i16, i32, <8 x i64>) #2

; Function Attrs: nounwind willreturn memory(read)
; Unknown intrinsic
declare !internal_intrinsic_id !31 <4 x i64> @llvm.vc.internal.lsc.load.ugm.v4i64.v1i1.v2i8.i64(<1 x i1>, i8, i8, i8, <2 x i8>, i64, i64, i16, i32, <4 x i64>) #2

; Function Attrs: nounwind willreturn memory(read)
; Unknown intrinsic
declare !internal_intrinsic_id !31 <64 x i64> @llvm.vc.internal.lsc.load.ugm.v64i64.v1i1.v2i8.i64(<1 x i1>, i8, i8, i8, <2 x i8>, i64, i64, i16, i32, <64 x i64>) #2

; Function Attrs: nounwind willreturn memory(write)
; Unknown intrinsic
declare !internal_intrinsic_id !32 void @llvm.vc.internal.lsc.store.ugm.v1i1.v2i8.i64.v8i64(<1 x i1>, i8, i8, i8, <2 x i8>, i64, i64, i16, i32, <8 x i64>) #3

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare <1 x float> @llvm.fma.v1f32(<1 x float>, <1 x float>, <1 x float>) #4

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !33 <1 x float> @llvm.genx.constantf.v1f32(<1 x float>) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 i32 @llvm.genx.rdregioni.i32.v2i32.i16(<2 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <1 x i32> @llvm.genx.rdregioni.v1i32.v2i32.i16(<2 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !35 <1 x i32> @llvm.genx.add3.v1i32.v1i32(<1 x i32>, <1 x i32>, <1 x i32>) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !36 <2 x i32> @llvm.genx.wrregioni.v2i32.v1i32.i16.i1(<2 x i32>, <1 x i32>, i32, i32, i32, i16, i32, i1) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <16 x i32> @llvm.genx.rdregioni.v16i32.v1i32.i16(<1 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !37 <1 x i32> @llvm.genx.absi.v1i32(<1 x i32>) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !38 <1 x float> @llvm.genx.inv.v1f32(<1 x float>) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !35 i32 @llvm.genx.add3.i32.i32(i32, i32, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !39 <32 x i32> @llvm.genx.umadw.v32i32.v1i32(<1 x i32>, <1 x i32>, <1 x i32>) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <1 x i32> @llvm.genx.rdregioni.v1i32.v32i32.i16(<32 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <32 x i32> @llvm.genx.rdregioni.v32i32.v1i32.i16(<1 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !40 <32 x i32> @llvm.genx.smadw.v32i32.v1i32(<1 x i32>, <1 x i32>, <1 x i32>) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 i16 @llvm.genx.rdregioni.i16.v3i16.i16(<3 x i16>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <8 x i64> @llvm.genx.rdregioni.v8i64.v64i64.i16(<64 x i64>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !36 <12 x i64> @llvm.genx.wrregioni.v12i64.v4i64.i16.i1(<12 x i64>, <4 x i64>, i32, i32, i32, i16, i32, i1) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !36 <12 x i64> @llvm.genx.wrregioni.v12i64.v8i64.i16.i1(<12 x i64>, <8 x i64>, i32, i32, i32, i16, i32, i1) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <1 x i32> @llvm.genx.rdregioni.v1i32.v3i32.i16(<3 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !36 <128 x i32> @llvm.genx.wrregioni.v128i32.v32i32.i16.i1(<128 x i32>, <32 x i32>, i32, i32, i32, i16, i32, i1) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <32 x i32> @llvm.genx.rdregioni.v32i32.v128i32.i16(<128 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none)
define internal spir_func i32 @__vc_builtin_sdiv_i32__rtz_(i32 noundef %0, i32 noundef %1) local_unnamed_addr #6 {
  %3 = call <4 x i32> @llvm.genx.read.predef.reg.v4i32.v4i32(i32 14, <4 x i32> undef)
  %4 = call <4 x i32> @llvm.genx.read.predef.reg.v4i32.v4i32(i32 14, <4 x i32> undef)
  %5 = call i32 @llvm.genx.rdregioni.i32.v4i32.i16(<4 x i32> %3, i32 0, i32 1, i32 1, i16 0, i32 undef)
  %6 = call i32 @llvm.genx.rdregioni.i32.v4i32.i16(<4 x i32> %4, i32 0, i32 1, i32 1, i16 0, i32 undef)
  %7 = and i32 %6, -1073743089
  %8 = call <4 x i32> @llvm.genx.wrregioni.v4i32.i32.i16.i1(<4 x i32> %3, i32 %7, i32 0, i32 1, i32 1, i16 0, i32 undef, i1 true)
  %9 = call <4 x i32> @llvm.genx.write.predef.reg.v4i32.v4i32(i32 14, <4 x i32> %8)
  %10 = call <4 x i32> @llvm.genx.read.predef.reg.v4i32.v4i32(i32 14, <4 x i32> undef)
  %11 = call i32 @llvm.genx.rdregioni.i32.v4i32.i16(<4 x i32> %10, i32 0, i32 1, i32 1, i16 0, i32 undef)
  %12 = or i32 %11, 1073743088
  %13 = call <4 x i32> @llvm.genx.wrregioni.v4i32.i32.i16.i1(<4 x i32> %10, i32 %12, i32 0, i32 1, i32 1, i16 0, i32 undef, i1 true)
  %14 = call <4 x i32> @llvm.genx.write.predef.reg.v4i32.v4i32(i32 14, <4 x i32> %13)
  %15 = bitcast i32 %0 to <1 x i32>
  %16 = bitcast i32 %1 to <1 x i32>
  %17 = tail call noundef <1 x i32> @llvm.genx.absi.v1i32(<1 x i32> %15)
  %18 = bitcast <1 x i32> %17 to i32
  %19 = tail call noundef <1 x i32> @llvm.genx.absi.v1i32(<1 x i32> %16)
  %20 = bitcast <1 x i32> %19 to i32
  %21 = tail call noundef <1 x i32> @llvm.genx.absi.v1i32(<1 x i32> %16)
  %22 = uitofp <1 x i32> %21 to <1 x float>
  %23 = bitcast <1 x float> %22 to float
  %24 = fptoui float %23 to i32
  %25 = sub i32 %20, %24
  %26 = bitcast i32 %25 to <1 x i32>
  %27 = uitofp <1 x i32> %26 to <1 x float>
  %28 = tail call noundef <1 x i32> @llvm.genx.absi.v1i32(<1 x i32> %15)
  %29 = uitofp <1 x i32> %28 to <1 x float>
  %30 = bitcast <1 x float> %29 to float
  %31 = fptoui float %30 to i32
  %32 = sub i32 %18, %31
  %33 = bitcast i32 %32 to <1 x i32>
  %34 = uitofp <1 x i32> %33 to <1 x float>
  %35 = tail call noundef <1 x float> @llvm.genx.inv.v1f32(<1 x float> %22)
  %36 = call <1 x float> @llvm.genx.constantf.v1f32(<1 x float> splat (float 0xBE98000000000000))
  %37 = tail call noundef <1 x float> @llvm.fma.v1f32(<1 x float> %35, <1 x float> %36, <1 x float> %35)
  %38 = fmul <1 x float> %37, %29
  %39 = fptoui <1 x float> %38 to <1 x i32>
  %40 = bitcast <1 x i32> %39 to i32
  %41 = uitofp <1 x i32> %39 to <1 x float>
  %42 = fneg <1 x float> %22
  %43 = tail call noundef <1 x float> @llvm.fma.v1f32(<1 x float> %42, <1 x float> %41, <1 x float> %29)
  %44 = fneg <1 x float> %27
  %45 = tail call noundef <1 x float> @llvm.fma.v1f32(<1 x float> %44, <1 x float> %41, <1 x float> %34)
  %46 = fadd <1 x float> %43, %45
  %47 = fmul <1 x float> %37, %46
  %48 = bitcast <1 x float> %47 to float
  %49 = fptoui float %48 to i32
  %50 = add i32 %40, %49
  %51 = xor i32 %1, %0
  %52 = ashr i32 %51, 31
  %53 = mul i32 %50, %20
  %54 = sub i32 %18, %53
  %55 = icmp uge i32 %54, %20
  %56 = select i1 %55, i32 1, i32 0
  %57 = call i32 @llvm.genx.add3.i32.i32(i32 %50, i32 %52, i32 %56)
  %58 = xor i32 %57, %52
  %59 = call <4 x i32> @llvm.genx.read.predef.reg.v4i32.v4i32(i32 14, <4 x i32> undef)
  %60 = call <4 x i32> @llvm.genx.wrregioni.v4i32.i32.i16.i1(<4 x i32> %59, i32 %5, i32 0, i32 1, i32 1, i16 0, i32 undef, i1 true)
  %61 = call <4 x i32> @llvm.genx.write.predef.reg.v4i32.v4i32(i32 14, <4 x i32> %60)
  ret i32 %58
}

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !41 <2 x i32> @llvm.genx.constanti.v2i32(<2 x i32>) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !41 <1 x i32> @llvm.genx.constanti.v1i32(<1 x i32>) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !42 <16 x i32> @llvm.genx.wrconstregion.v16i32.v8i32.i16.i1(<16 x i32>, <8 x i32>, i32, i32, i32, i16, i32, i1) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <4 x i32> @llvm.genx.rdregioni.v4i32.v24i32.i16(<24 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !36 <16 x i32> @llvm.genx.wrregioni.v16i32.v4i32.i16.i1(<16 x i32>, <4 x i32>, i32, i32, i32, i16, i32, i1) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <2 x i32> @llvm.genx.rdregioni.v2i32.v24i32.i16(<24 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !36 <16 x i32> @llvm.genx.wrregioni.v16i32.v2i32.i16.i1(<16 x i32>, <2 x i32>, i32, i32, i32, i16, i32, i1) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <1 x i32> @llvm.genx.rdregioni.v1i32.v24i32.i16(<24 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !36 <16 x i32> @llvm.genx.wrregioni.v16i32.v1i32.i16.i1(<16 x i32>, <1 x i32>, i32, i32, i32, i16, i32, i1) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <16 x i32> @llvm.genx.rdregioni.v16i32.v16i32.i16(<16 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <16 x i32> @llvm.genx.rdregioni.v16i32.v24i32.i16(<24 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 <64 x i32> @llvm.genx.rdregioni.v64i32.v128i32.i16(<128 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(read)
; Unknown intrinsic
declare !genx_intrinsic_id !43 <4 x i32> @llvm.genx.read.predef.reg.v4i32.v4i32(i32, <4 x i32>) #2

; Function Attrs: nounwind willreturn memory(write)
; Unknown intrinsic
declare !genx_intrinsic_id !44 <4 x i32> @llvm.genx.write.predef.reg.v4i32.v4i32(i32, <4 x i32>) #3

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !34 i32 @llvm.genx.rdregioni.i32.v4i32.i16(<4 x i32>, i32, i32, i32, i16, i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !36 <4 x i32> @llvm.genx.wrregioni.v4i32.i32.i16.i1(<4 x i32>, i32, i32, i32, i32, i16, i32, i1) #5

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(none)
declare i32 @llvm.ssa.copy.i32(i32 returned) #7

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !41 i32 @llvm.genx.constanti.i32(i32) #5

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !45 i1 @llvm.genx.constantpred.i1(i1) #5

attributes #0 = { mustprogress nofree nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind memory(readwrite, inaccessiblemem: none, target_mem0: none, target_mem1: none) "CMGenxMain" "VC.Stack.Amount"="0" "oclrt"="1" }
attributes #2 = { nounwind willreturn memory(read) }
attributes #3 = { nounwind willreturn memory(write) }
attributes #4 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #5 = { nounwind willreturn memory(none) }
attributes #6 = { mustprogress nofree noinline norecurse nosync nounwind willreturn memory(none) "CMFloatControl"="1264" "VC.Builtin" "no-trapping-math"="true" "stack-protector-buffer-size"="8" }
attributes #7 = { nocallback nofree nosync nounwind willreturn memory(none) }

!spirv.MemoryModel = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!spirv.Source = !{!1}
!opencl.spir.version = !{!2, !3}
!opencl.used.extensions = !{!4}
!opencl.used.optional.core.features = !{!4}
!spirv.Generator = !{!5}
!genx.kernels = !{!6}
!opencl.ocl.version = !{!3}
!opencl.cxx.version = !{!11}
!llvm.ident = !{!12}
!llvm.errno.tbaa = !{!13}
!llvm.module.flags = !{!17}
!genx.kernel.internal = !{!18}

!0 = !{i32 2, i32 2}
!1 = !{i32 0, i32 100000}
!2 = !{i32 1, i32 2}
!3 = !{i32 2, i32 0}
!4 = !{}
!5 = !{i16 6, i16 14}
!6 = !{ptr @_ZTSZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_EUlNS4_7nd_itemILi1EEEE_, !"_ZTSZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_EUlNS4_7nd_itemILi1EEEE_", !7, i32 0, !8, !9, !10, i32 0}
!7 = !{i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 24, i32 8, i32 96}
!8 = !{i32 152, i32 156, i32 160, i32 168, i32 176, i32 184, i32 192, i32 196, i32 200, i32 204, i32 208, i32 212, i32 216, i32 220, i32 224, i32 232, i32 236, i32 64, i32 128, i32 144}
!9 = !{i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0}
!10 = !{!"", !"", !"svmptr_t", !"svmptr_t", !"svmptr_t", !"svmptr_t", !"", !"", !"", !"", !"", !"", !"", !"", !"svmptr_t", !"", !"", !"", !"", !""}
!11 = !{i32 1, i32 0}
!12 = !{!"clang version 22.1.8 (Fedora 22.1.8-4.fc44)"}
!13 = !{!14, !14, i64 0}
!14 = !{!"int", !15, i64 0}
!15 = !{!"omnipotent char", !16, i64 0}
!16 = !{!"Simple C++ TBAA"}
!17 = !{i32 1, !"wchar_size", i32 4}
!18 = !{ptr @_ZTSZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_EUlNS4_7nd_itemILi1EEEE_, !19, !20, !4, !21, i32 0}
!19 = !{i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0}
!20 = !{i32 0, i32 1, i32 2, i32 3, i32 4, i32 5, i32 6, i32 7, i32 8, i32 9, i32 10, i32 11, i32 12, i32 13, i32 14, i32 15, i32 16, i32 17, i32 18, i32 19}
!21 = !{i32 -1, i32 -1, i32 255, i32 255, i32 255, i32 255, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 -1, i32 255, i32 -1, i32 -1, i32 255, i32 255, i32 255}
!22 = !{!23}
!23 = !{i32 4469}
!24 = !{i64 1}
!25 = !{!23, !26}
!26 = !{i32 4470}
!27 = !{i64 2}
!28 = !{i64 3}
!29 = !{i64 4}
!30 = !{i32 16247}
!31 = !{i32 16597}
!32 = !{i32 16628}
!33 = !{i32 16151}
!34 = !{i32 16349}
!35 = !{i32 16132}
!36 = !{i32 16554}
!37 = !{i32 16130}
!38 = !{i32 16253}
!39 = !{i32 16471}
!40 = !{i32 16383}
!41 = !{i32 16152}
!42 = !{i32 16548}
!43 = !{i32 16350}
!44 = !{i32 16549}
!45 = !{i32 16153}

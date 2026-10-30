; ------------------------------------------------
; VC_asm9cea78f553115c9f_optimized.ll
; ------------------------------------------------
; ModuleID = 'Deserialized LLVM Module'
target datalayout = "e-p:64:64-p3:32:32-p6:32:32-i64:64-n8:16:32:64"
target triple = "genx64-unknown-unknown"

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32>, <16 x i32>, i32, i32, i32, i16, i32, <16 x i1>) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32>, <8 x i32>, i32, i32, i32, i16, i32, <8 x i1>) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32>, <24 x i32>, i32, i32, i32, i16, i32, <24 x i1>) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32>, <7 x i32>, i32, i32, i32, i16, i32, <7 x i1>) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32>, <1 x i32>, i32, i32, i32, i16, i32, <1 x i1>) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16>, i32, i32, i32, i16, i32) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32>, <16 x i32>, i32, i32, i32, i16, i32, <16 x i1>) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32>, <128 x i32>, i32, i32, i32, i16, i32, <128 x i1>) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32>, <128 x i32>, <64 x i32>, i32, i32, i32, i32, i32, i32) #0

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: nounwind memory(readwrite, inaccessiblemem: none, target_mem0: none, target_mem1: none)
define dllexport spir_kernel void @_ZTSZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_EUlNS4_7nd_itemILi1EEEE_(i32 %0, i32 %1, ptr addrspace(1) readonly align 4 captures(none) %2, ptr addrspace(1) readonly align 4 captures(none) %3, ptr addrspace(1) writeonly align 4 %4, ptr addrspace(1) writeonly align 4 %5, i32 %6, i32 %7, i32 %8, i32 %9, i32 %10, i32 %11, i32 %12, i32 %13, ptr addrspace(4) readonly align 4 captures(none) %14, i32 %15, i32 %16, <3 x i16> %impl.arg.llvm.genx.local.id16, <3 x i32> %impl.arg.llvm.genx.local.size, i64 %impl.arg.private.base) local_unnamed_addr #1 {
_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5:
  %17 = extractelement <3 x i16> %impl.arg.llvm.genx.local.id16, i64 0
  %18 = tail call noundef i32 @llvm.genx.group.id.x()
  %19 = extractelement <3 x i32> %impl.arg.llvm.genx.local.size, i64 0
  %20 = zext i16 %17 to i64
  %.imul = tail call i64 @llvm.genx.uumul.i64.i32(i32 %19, i32 %18)
  %21 = add nuw i64 %.imul, %20
  %22 = trunc i64 %21 to i32
  %23 = lshr i32 %22, 1
  %24 = sdiv i32 %23, %0
  %25 = mul i32 %24, %0
  %26 = sub i32 %23, %25
  %27 = icmp slt i32 %26, %1
  %.v = select i1 %27, ptr addrspace(1) %2, ptr addrspace(1) %3
  %28 = select i1 %27, i32 0, i32 %1
  %29 = sub nsw i32 %26, %28, !spirv.Decorations !22
  %30 = sdiv i32 %24, %6
  %31 = mul i32 %30, %6
  %32 = sub i32 %24, %31
  %33 = mul nsw i32 %32, %7, !spirv.Decorations !22
  %34 = and i64 %21, 1
  %.not = icmp eq i64 %34, 0
  %35 = select i1 %.not, i32 0, i32 %8
  %36 = add nsw i32 %33, %35, !spirv.Decorations !22
  %37 = sext i32 %1 to i64
  %.imul161 = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %1, i32 24)
  %38 = sext i32 %10 to i64
  %39 = add nsw i32 %8, -1, !spirv.Decorations !22
  %40 = sext i32 %39 to i64
  %41 = sub nsw i64 %38, %40
  %42 = mul i64 %.imul161, %41
  %43 = sext i32 %36 to i64
  %44 = sext i32 %29 to i64
  %.imul162 = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %30, i32 %10)
  %reass.add = add nsw i64 %.imul162, %43
  %reass.mul = mul i64 %reass.add, %37
  %45 = add i64 %reass.mul, %44
  %.idx = mul i64 %45, 96
  %46 = getelementptr inbounds i8, ptr addrspace(1) %.v, i64 %.idx
  %47 = load <16 x i32>, ptr addrspace(1) %46, align 16
  %.esimd21 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> undef, <16 x i32> %47, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %48 = getelementptr inbounds nuw i8, ptr addrspace(1) %46, i64 64
  %49 = load <8 x i32>, ptr addrspace(1) %48, align 16
  %.esimd22 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd21, <8 x i32> %49, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd23 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> undef, <24 x i32> %.esimd22, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  %50 = icmp eq i32 %8, 1
  %..imul161 = select i1 %50, i64 %42, i64 %.imul161
  %.81618 = getelementptr inbounds i32, ptr addrspace(1) %46, i64 %..imul161
  br i1 %50, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3, label %51

51:                                               ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5
  %52 = load <16 x i32>, ptr addrspace(1) %.81618, align 16
  %.esimd21.1 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.esimd22, <16 x i32> %52, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %53 = getelementptr inbounds nuw i8, ptr addrspace(1) %.81618, i64 64
  %54 = load <8 x i32>, ptr addrspace(1) %53, align 16
  %.esimd22.1 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd21.1, <8 x i32> %54, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd23.1 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> undef, <24 x i32> %.esimd22.1, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  %55 = icmp eq i32 %8, 2
  br i1 %55, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread, label %57

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread: ; preds = %51
  %56 = getelementptr inbounds i32, ptr addrspace(1) %.81618, i64 %42
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3

57:                                               ; preds = %51
  %58 = getelementptr inbounds i32, ptr addrspace(1) %.81618, i64 %.imul161
  %59 = load <16 x i32>, ptr addrspace(1) %58, align 16
  %.esimd21.2 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.esimd22.1, <16 x i32> %59, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %60 = getelementptr inbounds nuw i8, ptr addrspace(1) %58, i64 64
  %61 = load <8 x i32>, ptr addrspace(1) %60, align 16
  %.esimd22.2 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd21.2, <8 x i32> %61, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd23.2 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> undef, <24 x i32> %.esimd22.2, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  %62 = icmp eq i32 %8, 3
  br i1 %62, label %63, label %65

63:                                               ; preds = %57
  %64 = getelementptr inbounds i32, ptr addrspace(1) %58, i64 %42
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3

65:                                               ; preds = %57
  %66 = getelementptr inbounds i32, ptr addrspace(1) %58, i64 %.imul161
  %67 = load <16 x i32>, ptr addrspace(1) %66, align 16
  %.esimd21.3 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.esimd22.2, <16 x i32> %67, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %68 = getelementptr inbounds nuw i8, ptr addrspace(1) %66, i64 64
  %69 = load <8 x i32>, ptr addrspace(1) %68, align 16
  %.esimd22.3 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd21.3, <8 x i32> %69, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd23.3 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> undef, <24 x i32> %.esimd22.3, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  %70 = icmp eq i32 %8, 4
  br i1 %70, label %73, label %71

71:                                               ; preds = %65
  %72 = getelementptr inbounds i32, ptr addrspace(1) %66, i64 %.imul161
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3

73:                                               ; preds = %65
  %74 = getelementptr inbounds i32, ptr addrspace(1) %66, i64 %42
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread, %63, %73, %71
  %.sroa.12138.0179 = phi <40 x i32> [ %.esimd23.2, %71 ], [ %.esimd23.2, %73 ], [ undef, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ %.esimd23.2, %63 ], [ undef, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.sroa.7136.0170178 = phi <40 x i32> [ %.esimd23.1, %71 ], [ %.esimd23.1, %73 ], [ %.esimd23.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ %.esimd23.1, %63 ], [ undef, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.sroa.17140.0 = phi <40 x i32> [ %.esimd23.3, %71 ], [ %.esimd23.3, %73 ], [ undef, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ undef, %63 ], [ undef, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.81627.3 = phi i32 [ 4, %71 ], [ 0, %73 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ 0, %63 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.81618.3 = phi ptr addrspace(1) [ %72, %71 ], [ %74, %73 ], [ %56, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ %64, %63 ], [ %.81618, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.8.3 = phi i32 [ 0, %71 ], [ 1, %73 ], [ 1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.1.thread ], [ 1, %63 ], [ 1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %75 = insertelement <16 x i32> poison, i32 %9, i64 0
  %76 = shufflevector <16 x i32> %75, <16 x i32> poison, <16 x i32> zeroinitializer
  %77 = add <16 x i32> %76, <i32 19, i32 19, i32 19, i32 19, i32 19, i32 19, i32 19, i32 19, i32 31, i32 31, i32 31, i32 31, i32 31, i32 31, i32 31, i32 31>
  %78 = add <16 x i32> %76, <i32 13, i32 13, i32 13, i32 13, i32 13, i32 13, i32 13, i32 13, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1, i32 1>
  %79 = add <16 x i32> %76, <i32 11, i32 11, i32 11, i32 11, i32 11, i32 11, i32 11, i32 11, i32 23, i32 23, i32 23, i32 23, i32 23, i32 23, i32 23, i32 23>
  %80 = add <16 x i32> %76, <i32 21, i32 21, i32 21, i32 21, i32 21, i32 21, i32 21, i32 21, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9, i32 9>
  %81 = add <16 x i32> %76, <i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 3, i32 15, i32 15, i32 15, i32 15, i32 15, i32 15, i32 15, i32 15>
  %82 = add <16 x i32> %76, <i32 29, i32 29, i32 29, i32 29, i32 29, i32 29, i32 29, i32 29, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17, i32 17>
  %83 = add <16 x i32> %76, <i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 27, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7, i32 7>
  %84 = add <16 x i32> %76, <i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 5, i32 25, i32 25, i32 25, i32 25, i32 25, i32 25, i32 25, i32 25>
  %.idx2 = shl nsw i64 %43, 10
  %85 = getelementptr inbounds i8, ptr addrspace(4) %14, i64 %.idx2
  %86 = icmp sgt i32 %8, 0
  br i1 %86, label %.lr.ph.preheader, label %._crit_edge

.lr.ph.preheader:                                 ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3
  %.v1628 = select i1 %27, ptr addrspace(1) %4, ptr addrspace(1) %5
  %87 = sext i32 %32 to i64
  %88 = shl nsw i64 %87, 1
  %89 = or disjoint i64 %88, %34
  %90 = sext i32 %12 to i64
  %91 = mul i64 %89, %90
  %92 = sext i32 %13 to i64
  %93 = shl nsw i64 %92, 4
  %.idx3 = shl nsw i64 %44, 6
  %invariant.gep = getelementptr i8, ptr addrspace(1) %.v1628, i64 %.idx3
  %.idx138 = shl nsw i64 %92, 3
  %.idx144 = shl nsw i64 %92, 5
  br label %.lr.ph

.lr.ph:                                           ; preds = %.lr.ph.preheader, %680
  %.sroa.22.0 = phi <128 x i32> [ %.sroa.22.6, %680 ], [ undef, %.lr.ph.preheader ]
  %.sroa.0.0 = phi <128 x i32> [ %.sroa.0.6, %680 ], [ undef, %.lr.ph.preheader ]
  %.esimd23466 = phi <40 x i32> [ %.esimd23465, %680 ], [ %.sroa.17140.0, %.lr.ph.preheader ]
  %.esimd18262 = phi <40 x i32> [ %.esimd18261, %680 ], [ %.sroa.12138.0179, %.lr.ph.preheader ]
  %.esimd13058 = phi <40 x i32> [ %.esimd13057, %680 ], [ %.sroa.7136.0170178, %.lr.ph.preheader ]
  %.esimd27854 = phi <128 x i32> [ %.esimd27855, %680 ], [ zeroinitializer, %.lr.ph.preheader ]
  %94 = phi <128 x i32> [ %681, %680 ], [ zeroinitializer, %.lr.ph.preheader ]
  %.esimd7849 = phi <40 x i32> [ %.esimd7850, %680 ], [ %.esimd23, %.lr.ph.preheader ]
  %.esimd23845 = phi <40 x i32> [ %.esimd23846, %680 ], [ undef, %.lr.ph.preheader ]
  %95 = phi i32 [ %685, %680 ], [ 0, %.lr.ph.preheader ]
  %96 = phi i32 [ %684, %680 ], [ 0, %.lr.ph.preheader ]
  %97 = phi i32 [ %683, %680 ], [ 0, %.lr.ph.preheader ]
  %98 = phi ptr addrspace(4) [ %682, %680 ], [ %85, %.lr.ph.preheader ]
  %.sroa.01451.044 = phi <256 x i32> [ %.esimd72, %680 ], [ undef, %.lr.ph.preheader ]
  %.sroa.01439.042 = phi <256 x i32> [ %.sroa.01439.1, %680 ], [ undef, %.lr.ph.preheader ]
  %.sroa.01427.039 = phi <256 x i32> [ %.sroa.01427.1, %680 ], [ undef, %.lr.ph.preheader ]
  %.sroa.01415.035 = phi <256 x i32> [ %.sroa.01415.1, %680 ], [ undef, %.lr.ph.preheader ]
  %.sroa.01403.030 = phi <256 x i32> [ %.sroa.01403.1, %680 ], [ undef, %.lr.ph.preheader ]
  %.sroa.0472.029 = phi <24 x i32> [ %.sroa.0472.1, %680 ], [ undef, %.lr.ph.preheader ]
  %.sroa.0466.027 = phi <24 x i32> [ %.sroa.0466.1, %680 ], [ undef, %.lr.ph.preheader ]
  %.sroa.0460.024 = phi <24 x i32> [ %.sroa.0460.1, %680 ], [ undef, %.lr.ph.preheader ]
  %.sroa.0454.020 = phi <24 x i32> [ %.sroa.0454.1, %680 ], [ undef, %.lr.ph.preheader ]
  %.sroa.0449.015 = phi <24 x i32> [ %.sroa.0449.1, %680 ], [ undef, %.lr.ph.preheader ]
  %.114 = phi i32 [ %.2, %680 ], [ %.8.3, %.lr.ph.preheader ]
  %.1161113 = phi ptr addrspace(1) [ %.21612, %680 ], [ %.81618.3, %.lr.ph.preheader ]
  %.1162012 = phi i32 [ %.21621, %680 ], [ %.81627.3, %.lr.ph.preheader ]
  %99 = icmp eq i32 %96, 0
  %spec.select = select i1 %99, <128 x i32> zeroinitializer, <128 x i32> %.sroa.22.0
  %spec.select164 = select i1 %99, <128 x i32> zeroinitializer, <128 x i32> %.sroa.0.0
  %.not203 = icmp eq i32 %.114, 0
  br i1 %.not203, label %100, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4

100:                                              ; preds = %.lr.ph
  %101 = load <16 x i32>, ptr addrspace(1) %.1161113, align 16
  %.esimd24 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0472.029, <16 x i32> %101, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %102 = getelementptr inbounds nuw i8, ptr addrspace(1) %.1161113, i64 64
  %103 = load <8 x i32>, ptr addrspace(1) %102, align 16
  %.esimd25 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd24, <8 x i32> %103, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd26 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd23845, <24 x i32> %.esimd25, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  %104 = add nsw i32 %.1162012, 1, !spirv.Decorations !22
  %105 = icmp eq i32 %104, %8
  br i1 %105, label %106, label %108

106:                                              ; preds = %100
  %107 = getelementptr inbounds i32, ptr addrspace(1) %.1161113, i64 %42
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4

108:                                              ; preds = %100
  %109 = getelementptr inbounds i32, ptr addrspace(1) %.1161113, i64 %.imul161
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4: ; preds = %108, %106, %.lr.ph
  %.esimd23847 = phi <40 x i32> [ %.esimd23845, %.lr.ph ], [ %.esimd26, %106 ], [ %.esimd26, %108 ]
  %.71626 = phi i32 [ %.1162012, %.lr.ph ], [ 0, %106 ], [ %104, %108 ]
  %.71617 = phi ptr addrspace(1) [ %.1161113, %.lr.ph ], [ %107, %106 ], [ %109, %108 ]
  %.not159 = phi i1 [ false, %.lr.ph ], [ false, %106 ], [ true, %108 ]
  %.7 = phi i32 [ 1, %.lr.ph ], [ 1, %106 ], [ 0, %108 ]
  %.sroa.0472.1 = phi <24 x i32> [ %.sroa.0472.029, %.lr.ph ], [ %.esimd25, %106 ], [ %.esimd25, %108 ]
  %.esimd27 = tail call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %.esimd7849, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd28 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %.esimd7849, <7 x i32> %.esimd27, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd29 = tail call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd28, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd30 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd28, <1 x i32> %.esimd29, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  %.esimd31 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd32 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 64, i32 40)
  %110 = lshr <16 x i32> %.esimd32, %78
  %111 = shl <16 x i32> %.esimd31, %77
  %112 = or <16 x i32> %110, %111
  %113 = bitcast <16 x i32> %112 to <32 x i16>
  %.esimd33 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %113, i32 0, i32 16, i32 2, i16 2, i32 0)
  %114 = zext <16 x i16> %.esimd33 to <16 x i32>
  %115 = mul <16 x i32> %114, splat (i32 -2082680531)
  %.esimd34 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %94, <16 x i32> %115, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %116 = lshr <16 x i32> %112, splat (i32 13)
  %117 = bitcast <16 x i32> %116 to <32 x i16>
  %.esimd35 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %117, i32 0, i32 16, i32 2, i16 0, i32 0)
  %118 = zext <16 x i16> %.esimd35 to <16 x i32>
  %119 = mul <16 x i32> %118, splat (i32 -2082680531)
  %.esimd36 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd34, <16 x i32> %119, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %120 = lshr <16 x i32> %112, splat (i32 10)
  %121 = bitcast <16 x i32> %120 to <32 x i16>
  %.esimd37 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %121, i32 0, i32 16, i32 2, i16 0, i32 0)
  %122 = zext <16 x i16> %.esimd37 to <16 x i32>
  %123 = mul <16 x i32> %122, splat (i32 -2082680531)
  %.esimd38 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd27854, <16 x i32> %123, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %124 = lshr <16 x i32> %112, splat (i32 7)
  %125 = bitcast <16 x i32> %124 to <32 x i16>
  %.esimd39 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %125, i32 0, i32 16, i32 2, i16 0, i32 0)
  %126 = zext <16 x i16> %.esimd39 to <16 x i32>
  %127 = mul <16 x i32> %126, splat (i32 -2082680531)
  %.esimd40 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd38, <16 x i32> %127, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %.esimd42 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 96, i32 40)
  %128 = lshr <16 x i32> %.esimd42, %80
  %129 = shl <16 x i32> %.esimd32, %79
  %130 = or <16 x i32> %128, %129
  %131 = bitcast <16 x i32> %130 to <32 x i16>
  %.esimd43 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %131, i32 0, i32 16, i32 2, i16 2, i32 0)
  %132 = zext <16 x i16> %.esimd43 to <16 x i32>
  %133 = mul <16 x i32> %132, splat (i32 -2082680531)
  %.esimd44 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd36, <16 x i32> %133, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %134 = lshr <16 x i32> %130, splat (i32 13)
  %135 = bitcast <16 x i32> %134 to <32 x i16>
  %.esimd45 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %135, i32 0, i32 16, i32 2, i16 0, i32 0)
  %136 = zext <16 x i16> %.esimd45 to <16 x i32>
  %137 = mul <16 x i32> %136, splat (i32 -2082680531)
  %.esimd46 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd44, <16 x i32> %137, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %138 = lshr <16 x i32> %130, splat (i32 10)
  %139 = bitcast <16 x i32> %138 to <32 x i16>
  %.esimd47 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %139, i32 0, i32 16, i32 2, i16 0, i32 0)
  %140 = zext <16 x i16> %.esimd47 to <16 x i32>
  %141 = mul <16 x i32> %140, splat (i32 -2082680531)
  %.esimd48 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd40, <16 x i32> %141, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %142 = lshr <16 x i32> %130, splat (i32 7)
  %143 = bitcast <16 x i32> %142 to <32 x i16>
  %.esimd49 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %143, i32 0, i32 16, i32 2, i16 0, i32 0)
  %144 = zext <16 x i16> %.esimd49 to <16 x i32>
  %145 = mul <16 x i32> %144, splat (i32 -2082680531)
  %.esimd50 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd48, <16 x i32> %145, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %.esimd52 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 128, i32 40)
  %146 = lshr <16 x i32> %.esimd52, %82
  %147 = shl <16 x i32> %.esimd42, %81
  %148 = or <16 x i32> %146, %147
  %149 = bitcast <16 x i32> %148 to <32 x i16>
  %.esimd53 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %149, i32 0, i32 16, i32 2, i16 2, i32 0)
  %150 = zext <16 x i16> %.esimd53 to <16 x i32>
  %151 = mul <16 x i32> %150, splat (i32 -2082680531)
  %.esimd54 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd46, <16 x i32> %151, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %152 = lshr <16 x i32> %148, splat (i32 13)
  %153 = bitcast <16 x i32> %152 to <32 x i16>
  %.esimd55 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %153, i32 0, i32 16, i32 2, i16 0, i32 0)
  %154 = zext <16 x i16> %.esimd55 to <16 x i32>
  %155 = mul <16 x i32> %154, splat (i32 -2082680531)
  %.esimd56 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd54, <16 x i32> %155, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %156 = lshr <16 x i32> %148, splat (i32 10)
  %157 = bitcast <16 x i32> %156 to <32 x i16>
  %.esimd57 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %157, i32 0, i32 16, i32 2, i16 0, i32 0)
  %158 = zext <16 x i16> %.esimd57 to <16 x i32>
  %159 = mul <16 x i32> %158, splat (i32 -2082680531)
  %.esimd58 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd50, <16 x i32> %159, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %160 = lshr <16 x i32> %148, splat (i32 7)
  %161 = bitcast <16 x i32> %160 to <32 x i16>
  %.esimd59 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %161, i32 0, i32 16, i32 2, i16 0, i32 0)
  %162 = zext <16 x i16> %.esimd59 to <16 x i32>
  %163 = mul <16 x i32> %162, splat (i32 -2082680531)
  %.esimd60 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd58, <16 x i32> %163, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %.esimd61 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 8, i32 8, i32 1, i16 96, i32 40)
  %164 = lshr <16 x i32> %.esimd52, %84
  %165 = shl <16 x i32> %.esimd61, %83
  %166 = or <16 x i32> %165, %164
  %167 = bitcast <16 x i32> %166 to <32 x i16>
  %.esimd63 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %167, i32 0, i32 16, i32 2, i16 2, i32 0)
  %168 = zext <16 x i16> %.esimd63 to <16 x i32>
  %169 = mul <16 x i32> %168, splat (i32 -2082680531)
  %.esimd64 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd56, <16 x i32> %169, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %170 = lshr <16 x i32> %166, splat (i32 13)
  %171 = bitcast <16 x i32> %170 to <32 x i16>
  %.esimd65 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %171, i32 0, i32 16, i32 2, i16 0, i32 0)
  %172 = zext <16 x i16> %.esimd65 to <16 x i32>
  %173 = mul <16 x i32> %172, splat (i32 -2082680531)
  %.esimd66 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd64, <16 x i32> %173, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %174 = lshr <16 x i32> %166, splat (i32 10)
  %175 = bitcast <16 x i32> %174 to <32 x i16>
  %.esimd67 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %175, i32 0, i32 16, i32 2, i16 0, i32 0)
  %176 = zext <16 x i16> %.esimd67 to <16 x i32>
  %177 = mul <16 x i32> %176, splat (i32 -2082680531)
  %.esimd68 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd60, <16 x i32> %177, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %178 = lshr <16 x i32> %166, splat (i32 7)
  %179 = bitcast <16 x i32> %178 to <32 x i16>
  %.esimd69 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %179, i32 0, i32 16, i32 2, i16 0, i32 0)
  %180 = zext <16 x i16> %.esimd69 to <16 x i32>
  %181 = mul <16 x i32> %180, splat (i32 -2082680531)
  %.esimd70 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd68, <16 x i32> %181, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %182 = load <128 x i32>, ptr addrspace(4) %98, align 16
  %.esimd71 = tail call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01451.044, <128 x i32> %182, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %183 = getelementptr inbounds nuw i8, ptr addrspace(4) %98, i64 512
  %184 = load <128 x i32>, ptr addrspace(4) %183, align 16
  %.esimd72 = tail call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd71, <128 x i32> %184, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  %.esimd73 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd72, i32 0, i32 64, i32 1, i16 0, i32 0)
  %.esimd74 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %spec.select164, <128 x i32> %.esimd66, <64 x i32> %.esimd73, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd73.1 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd72, i32 0, i32 64, i32 1, i16 256, i32 0)
  %.esimd74.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %spec.select, <128 x i32> %.esimd66, <64 x i32> %.esimd73.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd73.1123 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd72, i32 0, i32 64, i32 1, i16 512, i32 0)
  %.esimd74.1124 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd74, <128 x i32> %.esimd70, <64 x i32> %.esimd73.1123, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd73.1.1 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd72, i32 0, i32 64, i32 1, i16 768, i32 0)
  %.esimd74.1.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd74.1, <128 x i32> %.esimd70, <64 x i32> %.esimd73.1.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %185 = getelementptr inbounds nuw i8, ptr addrspace(4) %98, i64 1024
  %186 = add nsw i32 %96, 1, !spirv.Decorations !22
  %187 = icmp eq i32 %186, %8
  br i1 %187, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13, label %188

188:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4
  %189 = add nuw nsw i32 %95, 1, !spirv.Decorations !24
  %190 = icmp slt i32 %189, %8
  br i1 %190, label %213, label %680

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4
  %191 = add nsw i32 %97, %30, !spirv.Decorations !22
  %192 = sext i32 %191 to i64
  %193 = add i64 %91, %192
  %194 = mul i64 %193, %93
  %gep = getelementptr i32, ptr addrspace(1) %invariant.gep, i64 %194
  %.esimd75 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1124, i32 0, i32 16, i32 1, i16 0, i32 0)
  store <16 x i32> %.esimd75, ptr addrspace(1) %gep, align 16
  %.esimd75.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1124, i32 0, i32 16, i32 1, i16 64, i32 0)
  %195 = getelementptr inbounds i32, ptr addrspace(1) %gep, i64 %92
  store <16 x i32> %.esimd75.1, ptr addrspace(1) %195, align 16
  %.esimd75.2 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1124, i32 0, i32 16, i32 1, i16 128, i32 0)
  %196 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx138
  store <16 x i32> %.esimd75.2, ptr addrspace(1) %196, align 16
  %.esimd75.3 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1124, i32 0, i32 16, i32 1, i16 192, i32 0)
  %.idx139.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 12)
  %197 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx139.imul
  store <16 x i32> %.esimd75.3, ptr addrspace(1) %197, align 16
  %.esimd75.4 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1124, i32 0, i32 16, i32 1, i16 256, i32 0)
  %198 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %93
  store <16 x i32> %.esimd75.4, ptr addrspace(1) %198, align 16
  %.esimd75.5 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1124, i32 0, i32 16, i32 1, i16 320, i32 0)
  %.idx141.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 20)
  %199 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx141.imul
  store <16 x i32> %.esimd75.5, ptr addrspace(1) %199, align 16
  %.esimd75.6 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1124, i32 0, i32 16, i32 1, i16 384, i32 0)
  %.idx142.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 24)
  %200 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx142.imul
  store <16 x i32> %.esimd75.6, ptr addrspace(1) %200, align 16
  %.esimd75.7 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1124, i32 0, i32 16, i32 1, i16 448, i32 0)
  %.idx143.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 28)
  %201 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx143.imul
  store <16 x i32> %.esimd75.7, ptr addrspace(1) %201, align 16
  %.esimd75.1125 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1.1, i32 0, i32 16, i32 1, i16 0, i32 0)
  %202 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx144
  store <16 x i32> %.esimd75.1125, ptr addrspace(1) %202, align 16
  %.esimd75.1.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1.1, i32 0, i32 16, i32 1, i16 64, i32 0)
  %.idx145.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 36)
  %203 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx145.imul
  store <16 x i32> %.esimd75.1.1, ptr addrspace(1) %203, align 16
  %.esimd75.2.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1.1, i32 0, i32 16, i32 1, i16 128, i32 0)
  %.idx146.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 40)
  %204 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx146.imul
  store <16 x i32> %.esimd75.2.1, ptr addrspace(1) %204, align 16
  %.esimd75.3.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1.1, i32 0, i32 16, i32 1, i16 192, i32 0)
  %.idx147.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 44)
  %205 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx147.imul
  store <16 x i32> %.esimd75.3.1, ptr addrspace(1) %205, align 16
  %.esimd75.4.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1.1, i32 0, i32 16, i32 1, i16 256, i32 0)
  %.idx148.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 48)
  %206 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx148.imul
  store <16 x i32> %.esimd75.4.1, ptr addrspace(1) %206, align 16
  %.esimd75.5.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1.1, i32 0, i32 16, i32 1, i16 320, i32 0)
  %.idx149.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 52)
  %207 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx149.imul
  store <16 x i32> %.esimd75.5.1, ptr addrspace(1) %207, align 16
  %.esimd75.6.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1.1, i32 0, i32 16, i32 1, i16 384, i32 0)
  %.idx150.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 56)
  %208 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx150.imul
  store <16 x i32> %.esimd75.6.1, ptr addrspace(1) %208, align 16
  %.esimd75.7.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd74.1.1, i32 0, i32 16, i32 1, i16 448, i32 0)
  %.idx151.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 60)
  %209 = getelementptr inbounds i8, ptr addrspace(1) %gep, i64 %.idx151.imul
  store <16 x i32> %.esimd75.7.1, ptr addrspace(1) %209, align 16
  %210 = add nsw i32 %97, 1, !spirv.Decorations !22
  %211 = add nuw nsw i32 %95, 1, !spirv.Decorations !24
  %212 = icmp slt i32 %211, %8
  br i1 %212, label %.loopexit3, label %680

213:                                              ; preds = %188
  %214 = icmp eq i32 %186, 0
  br i1 %214, label %.loopexit3.loopexit, label %.loopexit3

.loopexit3.loopexit:                              ; preds = %213
  br label %.loopexit3

.loopexit3:                                       ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13, %.loopexit3.loopexit, %213
  %.sroa.22.2 = phi <128 x i32> [ %.esimd74.1.1, %213 ], [ zeroinitializer, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ zeroinitializer, %.loopexit3.loopexit ]
  %.sroa.0.2 = phi <128 x i32> [ %.esimd74.1124, %213 ], [ zeroinitializer, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ zeroinitializer, %.loopexit3.loopexit ]
  %215 = phi ptr addrspace(4) [ %185, %213 ], [ %85, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %185, %.loopexit3.loopexit ]
  %216 = phi i32 [ %97, %213 ], [ %210, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %97, %.loopexit3.loopexit ]
  %217 = phi i32 [ %186, %213 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ 0, %.loopexit3.loopexit ]
  br i1 %.not159, label %218, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3

218:                                              ; preds = %.loopexit3
  %219 = load <16 x i32>, ptr addrspace(1) %.71617, align 16
  %.esimd76 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0466.027, <16 x i32> %219, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %220 = getelementptr inbounds nuw i8, ptr addrspace(1) %.71617, i64 64
  %221 = load <8 x i32>, ptr addrspace(1) %220, align 16
  %.esimd77 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd76, <8 x i32> %221, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd78 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd30, <24 x i32> %.esimd77, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  %222 = add nsw i32 %.71626, 1, !spirv.Decorations !22
  %223 = icmp eq i32 %222, %8
  br i1 %223, label %224, label %226

224:                                              ; preds = %218
  %225 = getelementptr inbounds i32, ptr addrspace(1) %.71617, i64 %42
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3

226:                                              ; preds = %218
  %227 = getelementptr inbounds i32, ptr addrspace(1) %.71617, i64 %.imul161
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3: ; preds = %226, %224, %.loopexit3
  %.esimd7851 = phi <40 x i32> [ %.esimd30, %.loopexit3 ], [ %.esimd78, %224 ], [ %.esimd78, %226 ]
  %.61625 = phi i32 [ %.71626, %.loopexit3 ], [ 0, %224 ], [ %222, %226 ]
  %.61616 = phi ptr addrspace(1) [ %.71617, %.loopexit3 ], [ %225, %224 ], [ %227, %226 ]
  %.not180 = phi i1 [ false, %.loopexit3 ], [ false, %224 ], [ true, %226 ]
  %.6 = phi i32 [ 1, %.loopexit3 ], [ 1, %224 ], [ 0, %226 ]
  %.sroa.0466.2 = phi <24 x i32> [ %.sroa.0466.027, %.loopexit3 ], [ %.esimd77, %224 ], [ %.esimd77, %226 ]
  %.esimd79 = tail call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %.esimd13058, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd80 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %.esimd13058, <7 x i32> %.esimd79, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd81 = tail call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd80, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd82 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd80, <1 x i32> %.esimd81, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  %.esimd83 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd84 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 64, i32 40)
  %228 = lshr <16 x i32> %.esimd84, %78
  %229 = shl <16 x i32> %.esimd83, %77
  %230 = or <16 x i32> %228, %229
  %231 = bitcast <16 x i32> %230 to <32 x i16>
  %.esimd85 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %231, i32 0, i32 16, i32 2, i16 2, i32 0)
  %232 = zext <16 x i16> %.esimd85 to <16 x i32>
  %233 = mul <16 x i32> %232, splat (i32 -2082680531)
  %.esimd86 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd66, <16 x i32> %233, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %234 = lshr <16 x i32> %230, splat (i32 13)
  %235 = bitcast <16 x i32> %234 to <32 x i16>
  %.esimd87 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %235, i32 0, i32 16, i32 2, i16 0, i32 0)
  %236 = zext <16 x i16> %.esimd87 to <16 x i32>
  %237 = mul <16 x i32> %236, splat (i32 -2082680531)
  %.esimd88 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd86, <16 x i32> %237, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %238 = lshr <16 x i32> %230, splat (i32 10)
  %239 = bitcast <16 x i32> %238 to <32 x i16>
  %.esimd89 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %239, i32 0, i32 16, i32 2, i16 0, i32 0)
  %240 = zext <16 x i16> %.esimd89 to <16 x i32>
  %241 = mul <16 x i32> %240, splat (i32 -2082680531)
  %.esimd90 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd70, <16 x i32> %241, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %242 = lshr <16 x i32> %230, splat (i32 7)
  %243 = bitcast <16 x i32> %242 to <32 x i16>
  %.esimd91 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %243, i32 0, i32 16, i32 2, i16 0, i32 0)
  %244 = zext <16 x i16> %.esimd91 to <16 x i32>
  %245 = mul <16 x i32> %244, splat (i32 -2082680531)
  %.esimd92 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd90, <16 x i32> %245, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %.esimd94 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 96, i32 40)
  %246 = lshr <16 x i32> %.esimd94, %80
  %247 = shl <16 x i32> %.esimd84, %79
  %248 = or <16 x i32> %246, %247
  %249 = bitcast <16 x i32> %248 to <32 x i16>
  %.esimd95 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %249, i32 0, i32 16, i32 2, i16 2, i32 0)
  %250 = zext <16 x i16> %.esimd95 to <16 x i32>
  %251 = mul <16 x i32> %250, splat (i32 -2082680531)
  %.esimd96 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd88, <16 x i32> %251, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %252 = lshr <16 x i32> %248, splat (i32 13)
  %253 = bitcast <16 x i32> %252 to <32 x i16>
  %.esimd97 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %253, i32 0, i32 16, i32 2, i16 0, i32 0)
  %254 = zext <16 x i16> %.esimd97 to <16 x i32>
  %255 = mul <16 x i32> %254, splat (i32 -2082680531)
  %.esimd98 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd96, <16 x i32> %255, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %256 = lshr <16 x i32> %248, splat (i32 10)
  %257 = bitcast <16 x i32> %256 to <32 x i16>
  %.esimd99 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %257, i32 0, i32 16, i32 2, i16 0, i32 0)
  %258 = zext <16 x i16> %.esimd99 to <16 x i32>
  %259 = mul <16 x i32> %258, splat (i32 -2082680531)
  %.esimd100 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd92, <16 x i32> %259, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %260 = lshr <16 x i32> %248, splat (i32 7)
  %261 = bitcast <16 x i32> %260 to <32 x i16>
  %.esimd101 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %261, i32 0, i32 16, i32 2, i16 0, i32 0)
  %262 = zext <16 x i16> %.esimd101 to <16 x i32>
  %263 = mul <16 x i32> %262, splat (i32 -2082680531)
  %.esimd102 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd100, <16 x i32> %263, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %.esimd104 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 128, i32 40)
  %264 = lshr <16 x i32> %.esimd104, %82
  %265 = shl <16 x i32> %.esimd94, %81
  %266 = or <16 x i32> %264, %265
  %267 = bitcast <16 x i32> %266 to <32 x i16>
  %.esimd105 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %267, i32 0, i32 16, i32 2, i16 2, i32 0)
  %268 = zext <16 x i16> %.esimd105 to <16 x i32>
  %269 = mul <16 x i32> %268, splat (i32 -2082680531)
  %.esimd106 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd98, <16 x i32> %269, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %270 = lshr <16 x i32> %266, splat (i32 13)
  %271 = bitcast <16 x i32> %270 to <32 x i16>
  %.esimd107 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %271, i32 0, i32 16, i32 2, i16 0, i32 0)
  %272 = zext <16 x i16> %.esimd107 to <16 x i32>
  %273 = mul <16 x i32> %272, splat (i32 -2082680531)
  %.esimd108 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd106, <16 x i32> %273, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %274 = lshr <16 x i32> %266, splat (i32 10)
  %275 = bitcast <16 x i32> %274 to <32 x i16>
  %.esimd109 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %275, i32 0, i32 16, i32 2, i16 0, i32 0)
  %276 = zext <16 x i16> %.esimd109 to <16 x i32>
  %277 = mul <16 x i32> %276, splat (i32 -2082680531)
  %.esimd110 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd102, <16 x i32> %277, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %278 = lshr <16 x i32> %266, splat (i32 7)
  %279 = bitcast <16 x i32> %278 to <32 x i16>
  %.esimd111 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %279, i32 0, i32 16, i32 2, i16 0, i32 0)
  %280 = zext <16 x i16> %.esimd111 to <16 x i32>
  %281 = mul <16 x i32> %280, splat (i32 -2082680531)
  %.esimd112 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd110, <16 x i32> %281, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %.esimd113 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 8, i32 8, i32 1, i16 96, i32 40)
  %282 = lshr <16 x i32> %.esimd104, %84
  %283 = shl <16 x i32> %.esimd113, %83
  %284 = or <16 x i32> %283, %282
  %285 = bitcast <16 x i32> %284 to <32 x i16>
  %.esimd115 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %285, i32 0, i32 16, i32 2, i16 2, i32 0)
  %286 = zext <16 x i16> %.esimd115 to <16 x i32>
  %287 = mul <16 x i32> %286, splat (i32 -2082680531)
  %.esimd116 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd108, <16 x i32> %287, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %288 = lshr <16 x i32> %284, splat (i32 13)
  %289 = bitcast <16 x i32> %288 to <32 x i16>
  %.esimd117 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %289, i32 0, i32 16, i32 2, i16 0, i32 0)
  %290 = zext <16 x i16> %.esimd117 to <16 x i32>
  %291 = mul <16 x i32> %290, splat (i32 -2082680531)
  %.esimd118 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd116, <16 x i32> %291, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %292 = lshr <16 x i32> %284, splat (i32 10)
  %293 = bitcast <16 x i32> %292 to <32 x i16>
  %.esimd119 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %293, i32 0, i32 16, i32 2, i16 0, i32 0)
  %294 = zext <16 x i16> %.esimd119 to <16 x i32>
  %295 = mul <16 x i32> %294, splat (i32 -2082680531)
  %.esimd120 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd112, <16 x i32> %295, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %296 = lshr <16 x i32> %284, splat (i32 7)
  %297 = bitcast <16 x i32> %296 to <32 x i16>
  %.esimd121 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %297, i32 0, i32 16, i32 2, i16 0, i32 0)
  %298 = zext <16 x i16> %.esimd121 to <16 x i32>
  %299 = mul <16 x i32> %298, splat (i32 -2082680531)
  %.esimd122 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd120, <16 x i32> %299, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %300 = load <128 x i32>, ptr addrspace(4) %215, align 16
  %.esimd123 = tail call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01439.042, <128 x i32> %300, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %301 = getelementptr inbounds nuw i8, ptr addrspace(4) %215, i64 512
  %302 = load <128 x i32>, ptr addrspace(4) %301, align 16
  %.esimd124 = tail call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd123, <128 x i32> %302, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  %.esimd125 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd124, i32 0, i32 64, i32 1, i16 0, i32 0)
  %.esimd126 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.0.2, <128 x i32> %.esimd118, <64 x i32> %.esimd125, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd125.1 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd124, i32 0, i32 64, i32 1, i16 256, i32 0)
  %.esimd126.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.22.2, <128 x i32> %.esimd118, <64 x i32> %.esimd125.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd125.1126 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd124, i32 0, i32 64, i32 1, i16 512, i32 0)
  %.esimd126.1127 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd126, <128 x i32> %.esimd122, <64 x i32> %.esimd125.1126, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd125.1.1 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd124, i32 0, i32 64, i32 1, i16 768, i32 0)
  %.esimd126.1.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd126.1, <128 x i32> %.esimd122, <64 x i32> %.esimd125.1.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %303 = getelementptr inbounds nuw i8, ptr addrspace(4) %215, i64 1024
  %304 = add nsw i32 %217, 1, !spirv.Decorations !22
  %305 = icmp eq i32 %304, %8
  br i1 %305, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12, label %306

306:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3
  %307 = add nuw nsw i32 %95, 2, !spirv.Decorations !24
  %308 = icmp slt i32 %307, %8
  br i1 %308, label %331, label %680

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3
  %309 = add nsw i32 %216, %30, !spirv.Decorations !22
  %310 = sext i32 %309 to i64
  %311 = add i64 %91, %310
  %312 = mul i64 %311, %93
  %gep183 = getelementptr i32, ptr addrspace(1) %invariant.gep, i64 %312
  %.esimd127 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1127, i32 0, i32 16, i32 1, i16 0, i32 0)
  store <16 x i32> %.esimd127, ptr addrspace(1) %gep183, align 16
  %.esimd127.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1127, i32 0, i32 16, i32 1, i16 64, i32 0)
  %313 = getelementptr inbounds i32, ptr addrspace(1) %gep183, i64 %92
  store <16 x i32> %.esimd127.1, ptr addrspace(1) %313, align 16
  %.esimd127.2 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1127, i32 0, i32 16, i32 1, i16 128, i32 0)
  %314 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx138
  store <16 x i32> %.esimd127.2, ptr addrspace(1) %314, align 16
  %.esimd127.3 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1127, i32 0, i32 16, i32 1, i16 192, i32 0)
  %.idx153.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 12)
  %315 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx153.imul
  store <16 x i32> %.esimd127.3, ptr addrspace(1) %315, align 16
  %.esimd127.4 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1127, i32 0, i32 16, i32 1, i16 256, i32 0)
  %316 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %93
  store <16 x i32> %.esimd127.4, ptr addrspace(1) %316, align 16
  %.esimd127.5 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1127, i32 0, i32 16, i32 1, i16 320, i32 0)
  %.idx155.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 20)
  %317 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx155.imul
  store <16 x i32> %.esimd127.5, ptr addrspace(1) %317, align 16
  %.esimd127.6 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1127, i32 0, i32 16, i32 1, i16 384, i32 0)
  %.idx156.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 24)
  %318 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx156.imul
  store <16 x i32> %.esimd127.6, ptr addrspace(1) %318, align 16
  %.esimd127.7 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1127, i32 0, i32 16, i32 1, i16 448, i32 0)
  %.idx157.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 28)
  %319 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx157.imul
  store <16 x i32> %.esimd127.7, ptr addrspace(1) %319, align 16
  %.esimd127.1128 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1.1, i32 0, i32 16, i32 1, i16 0, i32 0)
  %320 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx144
  store <16 x i32> %.esimd127.1128, ptr addrspace(1) %320, align 16
  %.esimd127.1.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1.1, i32 0, i32 16, i32 1, i16 64, i32 0)
  %.idx159.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 36)
  %321 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx159.imul
  store <16 x i32> %.esimd127.1.1, ptr addrspace(1) %321, align 16
  %.esimd127.2.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1.1, i32 0, i32 16, i32 1, i16 128, i32 0)
  %.idx160.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 40)
  %322 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx160.imul
  store <16 x i32> %.esimd127.2.1, ptr addrspace(1) %322, align 16
  %.esimd127.3.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1.1, i32 0, i32 16, i32 1, i16 192, i32 0)
  %.idx161.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 44)
  %323 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx161.imul
  store <16 x i32> %.esimd127.3.1, ptr addrspace(1) %323, align 16
  %.esimd127.4.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1.1, i32 0, i32 16, i32 1, i16 256, i32 0)
  %.idx162.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 48)
  %324 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx162.imul
  store <16 x i32> %.esimd127.4.1, ptr addrspace(1) %324, align 16
  %.esimd127.5.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1.1, i32 0, i32 16, i32 1, i16 320, i32 0)
  %.idx163.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 52)
  %325 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx163.imul
  store <16 x i32> %.esimd127.5.1, ptr addrspace(1) %325, align 16
  %.esimd127.6.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1.1, i32 0, i32 16, i32 1, i16 384, i32 0)
  %.idx164.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 56)
  %326 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx164.imul
  store <16 x i32> %.esimd127.6.1, ptr addrspace(1) %326, align 16
  %.esimd127.7.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd126.1.1, i32 0, i32 16, i32 1, i16 448, i32 0)
  %.idx165.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 60)
  %327 = getelementptr inbounds i8, ptr addrspace(1) %gep183, i64 %.idx165.imul
  store <16 x i32> %.esimd127.7.1, ptr addrspace(1) %327, align 16
  %328 = add nsw i32 %216, 1, !spirv.Decorations !22
  %329 = add nuw nsw i32 %95, 2, !spirv.Decorations !24
  %330 = icmp slt i32 %329, %8
  br i1 %330, label %.loopexit2, label %680

331:                                              ; preds = %306
  %332 = icmp eq i32 %304, 0
  br i1 %332, label %.loopexit2.loopexit, label %.loopexit2

.loopexit2.loopexit:                              ; preds = %331
  br label %.loopexit2

.loopexit2:                                       ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12, %.loopexit2.loopexit, %331
  %.sroa.22.3 = phi <128 x i32> [ %.esimd126.1.1, %331 ], [ zeroinitializer, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ zeroinitializer, %.loopexit2.loopexit ]
  %.sroa.0.3 = phi <128 x i32> [ %.esimd126.1127, %331 ], [ zeroinitializer, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ zeroinitializer, %.loopexit2.loopexit ]
  %333 = phi ptr addrspace(4) [ %303, %331 ], [ %85, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %303, %.loopexit2.loopexit ]
  %334 = phi i32 [ %216, %331 ], [ %328, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %216, %.loopexit2.loopexit ]
  %335 = phi i32 [ %304, %331 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ 0, %.loopexit2.loopexit ]
  br i1 %.not180, label %336, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2

336:                                              ; preds = %.loopexit2
  %337 = load <16 x i32>, ptr addrspace(1) %.61616, align 16
  %.esimd128 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0460.024, <16 x i32> %337, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %338 = getelementptr inbounds nuw i8, ptr addrspace(1) %.61616, i64 64
  %339 = load <8 x i32>, ptr addrspace(1) %338, align 16
  %.esimd129 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd128, <8 x i32> %339, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd130 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd82, <24 x i32> %.esimd129, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  %340 = add nsw i32 %.61625, 1, !spirv.Decorations !22
  %341 = icmp eq i32 %340, %8
  br i1 %341, label %342, label %344

342:                                              ; preds = %336
  %343 = getelementptr inbounds i32, ptr addrspace(1) %.61616, i64 %42
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2

344:                                              ; preds = %336
  %345 = getelementptr inbounds i32, ptr addrspace(1) %.61616, i64 %.imul161
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2: ; preds = %344, %342, %.loopexit2
  %.esimd13059 = phi <40 x i32> [ %.esimd82, %.loopexit2 ], [ %.esimd130, %342 ], [ %.esimd130, %344 ]
  %.51624 = phi i32 [ %.61625, %.loopexit2 ], [ 0, %342 ], [ %340, %344 ]
  %.51615 = phi ptr addrspace(1) [ %.61616, %.loopexit2 ], [ %343, %342 ], [ %345, %344 ]
  %.not160 = phi i1 [ false, %.loopexit2 ], [ false, %342 ], [ true, %344 ]
  %.5 = phi i32 [ 1, %.loopexit2 ], [ 1, %342 ], [ 0, %344 ]
  %.sroa.0460.2 = phi <24 x i32> [ %.sroa.0460.024, %.loopexit2 ], [ %.esimd129, %342 ], [ %.esimd129, %344 ]
  %.esimd131 = tail call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %.esimd18262, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd132 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %.esimd18262, <7 x i32> %.esimd131, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd133 = tail call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd132, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd134 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd132, <1 x i32> %.esimd133, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  %.esimd135 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd136 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 64, i32 40)
  %346 = lshr <16 x i32> %.esimd136, %78
  %347 = shl <16 x i32> %.esimd135, %77
  %348 = or <16 x i32> %346, %347
  %349 = bitcast <16 x i32> %348 to <32 x i16>
  %.esimd137 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %349, i32 0, i32 16, i32 2, i16 2, i32 0)
  %350 = zext <16 x i16> %.esimd137 to <16 x i32>
  %351 = mul <16 x i32> %350, splat (i32 -2082680531)
  %.esimd138 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd118, <16 x i32> %351, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %352 = lshr <16 x i32> %348, splat (i32 13)
  %353 = bitcast <16 x i32> %352 to <32 x i16>
  %.esimd139 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %353, i32 0, i32 16, i32 2, i16 0, i32 0)
  %354 = zext <16 x i16> %.esimd139 to <16 x i32>
  %355 = mul <16 x i32> %354, splat (i32 -2082680531)
  %.esimd140 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd138, <16 x i32> %355, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %356 = lshr <16 x i32> %348, splat (i32 10)
  %357 = bitcast <16 x i32> %356 to <32 x i16>
  %.esimd141 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %357, i32 0, i32 16, i32 2, i16 0, i32 0)
  %358 = zext <16 x i16> %.esimd141 to <16 x i32>
  %359 = mul <16 x i32> %358, splat (i32 -2082680531)
  %.esimd142 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd122, <16 x i32> %359, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %360 = lshr <16 x i32> %348, splat (i32 7)
  %361 = bitcast <16 x i32> %360 to <32 x i16>
  %.esimd143 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %361, i32 0, i32 16, i32 2, i16 0, i32 0)
  %362 = zext <16 x i16> %.esimd143 to <16 x i32>
  %363 = mul <16 x i32> %362, splat (i32 -2082680531)
  %.esimd144 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd142, <16 x i32> %363, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %.esimd146 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 96, i32 40)
  %364 = lshr <16 x i32> %.esimd146, %80
  %365 = shl <16 x i32> %.esimd136, %79
  %366 = or <16 x i32> %364, %365
  %367 = bitcast <16 x i32> %366 to <32 x i16>
  %.esimd147 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %367, i32 0, i32 16, i32 2, i16 2, i32 0)
  %368 = zext <16 x i16> %.esimd147 to <16 x i32>
  %369 = mul <16 x i32> %368, splat (i32 -2082680531)
  %.esimd148 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd140, <16 x i32> %369, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %370 = lshr <16 x i32> %366, splat (i32 13)
  %371 = bitcast <16 x i32> %370 to <32 x i16>
  %.esimd149 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %371, i32 0, i32 16, i32 2, i16 0, i32 0)
  %372 = zext <16 x i16> %.esimd149 to <16 x i32>
  %373 = mul <16 x i32> %372, splat (i32 -2082680531)
  %.esimd150 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd148, <16 x i32> %373, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %374 = lshr <16 x i32> %366, splat (i32 10)
  %375 = bitcast <16 x i32> %374 to <32 x i16>
  %.esimd151 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %375, i32 0, i32 16, i32 2, i16 0, i32 0)
  %376 = zext <16 x i16> %.esimd151 to <16 x i32>
  %377 = mul <16 x i32> %376, splat (i32 -2082680531)
  %.esimd152 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd144, <16 x i32> %377, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %378 = lshr <16 x i32> %366, splat (i32 7)
  %379 = bitcast <16 x i32> %378 to <32 x i16>
  %.esimd153 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %379, i32 0, i32 16, i32 2, i16 0, i32 0)
  %380 = zext <16 x i16> %.esimd153 to <16 x i32>
  %381 = mul <16 x i32> %380, splat (i32 -2082680531)
  %.esimd154 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd152, <16 x i32> %381, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %.esimd156 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 128, i32 40)
  %382 = lshr <16 x i32> %.esimd156, %82
  %383 = shl <16 x i32> %.esimd146, %81
  %384 = or <16 x i32> %382, %383
  %385 = bitcast <16 x i32> %384 to <32 x i16>
  %.esimd157 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %385, i32 0, i32 16, i32 2, i16 2, i32 0)
  %386 = zext <16 x i16> %.esimd157 to <16 x i32>
  %387 = mul <16 x i32> %386, splat (i32 -2082680531)
  %.esimd158 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd150, <16 x i32> %387, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %388 = lshr <16 x i32> %384, splat (i32 13)
  %389 = bitcast <16 x i32> %388 to <32 x i16>
  %.esimd159 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %389, i32 0, i32 16, i32 2, i16 0, i32 0)
  %390 = zext <16 x i16> %.esimd159 to <16 x i32>
  %391 = mul <16 x i32> %390, splat (i32 -2082680531)
  %.esimd160 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd158, <16 x i32> %391, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %392 = lshr <16 x i32> %384, splat (i32 10)
  %393 = bitcast <16 x i32> %392 to <32 x i16>
  %.esimd161 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %393, i32 0, i32 16, i32 2, i16 0, i32 0)
  %394 = zext <16 x i16> %.esimd161 to <16 x i32>
  %395 = mul <16 x i32> %394, splat (i32 -2082680531)
  %.esimd162 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd154, <16 x i32> %395, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %396 = lshr <16 x i32> %384, splat (i32 7)
  %397 = bitcast <16 x i32> %396 to <32 x i16>
  %.esimd163 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %397, i32 0, i32 16, i32 2, i16 0, i32 0)
  %398 = zext <16 x i16> %.esimd163 to <16 x i32>
  %399 = mul <16 x i32> %398, splat (i32 -2082680531)
  %.esimd164 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd162, <16 x i32> %399, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %.esimd165 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 8, i32 8, i32 1, i16 96, i32 40)
  %400 = lshr <16 x i32> %.esimd156, %84
  %401 = shl <16 x i32> %.esimd165, %83
  %402 = or <16 x i32> %401, %400
  %403 = bitcast <16 x i32> %402 to <32 x i16>
  %.esimd167 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %403, i32 0, i32 16, i32 2, i16 2, i32 0)
  %404 = zext <16 x i16> %.esimd167 to <16 x i32>
  %405 = mul <16 x i32> %404, splat (i32 -2082680531)
  %.esimd168 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd160, <16 x i32> %405, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %406 = lshr <16 x i32> %402, splat (i32 13)
  %407 = bitcast <16 x i32> %406 to <32 x i16>
  %.esimd169 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %407, i32 0, i32 16, i32 2, i16 0, i32 0)
  %408 = zext <16 x i16> %.esimd169 to <16 x i32>
  %409 = mul <16 x i32> %408, splat (i32 -2082680531)
  %.esimd170 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd168, <16 x i32> %409, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %410 = lshr <16 x i32> %402, splat (i32 10)
  %411 = bitcast <16 x i32> %410 to <32 x i16>
  %.esimd171 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %411, i32 0, i32 16, i32 2, i16 0, i32 0)
  %412 = zext <16 x i16> %.esimd171 to <16 x i32>
  %413 = mul <16 x i32> %412, splat (i32 -2082680531)
  %.esimd172 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd164, <16 x i32> %413, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %414 = lshr <16 x i32> %402, splat (i32 7)
  %415 = bitcast <16 x i32> %414 to <32 x i16>
  %.esimd173 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %415, i32 0, i32 16, i32 2, i16 0, i32 0)
  %416 = zext <16 x i16> %.esimd173 to <16 x i32>
  %417 = mul <16 x i32> %416, splat (i32 -2082680531)
  %.esimd174 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd172, <16 x i32> %417, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %418 = load <128 x i32>, ptr addrspace(4) %333, align 16
  %.esimd175 = tail call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01427.039, <128 x i32> %418, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %419 = getelementptr inbounds nuw i8, ptr addrspace(4) %333, i64 512
  %420 = load <128 x i32>, ptr addrspace(4) %419, align 16
  %.esimd176 = tail call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd175, <128 x i32> %420, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  %.esimd177 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd176, i32 0, i32 64, i32 1, i16 0, i32 0)
  %.esimd178 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.0.3, <128 x i32> %.esimd170, <64 x i32> %.esimd177, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd177.1 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd176, i32 0, i32 64, i32 1, i16 256, i32 0)
  %.esimd178.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.22.3, <128 x i32> %.esimd170, <64 x i32> %.esimd177.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd177.1129 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd176, i32 0, i32 64, i32 1, i16 512, i32 0)
  %.esimd178.1130 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd178, <128 x i32> %.esimd174, <64 x i32> %.esimd177.1129, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd177.1.1 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd176, i32 0, i32 64, i32 1, i16 768, i32 0)
  %.esimd178.1.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd178.1, <128 x i32> %.esimd174, <64 x i32> %.esimd177.1.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %421 = getelementptr inbounds nuw i8, ptr addrspace(4) %333, i64 1024
  %422 = add nsw i32 %335, 1, !spirv.Decorations !22
  %423 = icmp eq i32 %422, %8
  br i1 %423, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11, label %424

424:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2
  %425 = add nuw nsw i32 %95, 3, !spirv.Decorations !24
  %426 = icmp slt i32 %425, %8
  br i1 %426, label %449, label %680

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2
  %427 = add nsw i32 %334, %30, !spirv.Decorations !22
  %428 = sext i32 %427 to i64
  %429 = add i64 %91, %428
  %430 = mul i64 %429, %93
  %gep185 = getelementptr i32, ptr addrspace(1) %invariant.gep, i64 %430
  %.esimd179 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1130, i32 0, i32 16, i32 1, i16 0, i32 0)
  store <16 x i32> %.esimd179, ptr addrspace(1) %gep185, align 16
  %.esimd179.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1130, i32 0, i32 16, i32 1, i16 64, i32 0)
  %431 = getelementptr inbounds i32, ptr addrspace(1) %gep185, i64 %92
  store <16 x i32> %.esimd179.1, ptr addrspace(1) %431, align 16
  %.esimd179.2 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1130, i32 0, i32 16, i32 1, i16 128, i32 0)
  %432 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx138
  store <16 x i32> %.esimd179.2, ptr addrspace(1) %432, align 16
  %.esimd179.3 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1130, i32 0, i32 16, i32 1, i16 192, i32 0)
  %.idx167.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 12)
  %433 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx167.imul
  store <16 x i32> %.esimd179.3, ptr addrspace(1) %433, align 16
  %.esimd179.4 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1130, i32 0, i32 16, i32 1, i16 256, i32 0)
  %434 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %93
  store <16 x i32> %.esimd179.4, ptr addrspace(1) %434, align 16
  %.esimd179.5 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1130, i32 0, i32 16, i32 1, i16 320, i32 0)
  %.idx169.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 20)
  %435 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx169.imul
  store <16 x i32> %.esimd179.5, ptr addrspace(1) %435, align 16
  %.esimd179.6 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1130, i32 0, i32 16, i32 1, i16 384, i32 0)
  %.idx170.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 24)
  %436 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx170.imul
  store <16 x i32> %.esimd179.6, ptr addrspace(1) %436, align 16
  %.esimd179.7 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1130, i32 0, i32 16, i32 1, i16 448, i32 0)
  %.idx171.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 28)
  %437 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx171.imul
  store <16 x i32> %.esimd179.7, ptr addrspace(1) %437, align 16
  %.esimd179.1131 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1.1, i32 0, i32 16, i32 1, i16 0, i32 0)
  %438 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx144
  store <16 x i32> %.esimd179.1131, ptr addrspace(1) %438, align 16
  %.esimd179.1.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1.1, i32 0, i32 16, i32 1, i16 64, i32 0)
  %.idx173.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 36)
  %439 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx173.imul
  store <16 x i32> %.esimd179.1.1, ptr addrspace(1) %439, align 16
  %.esimd179.2.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1.1, i32 0, i32 16, i32 1, i16 128, i32 0)
  %.idx174.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 40)
  %440 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx174.imul
  store <16 x i32> %.esimd179.2.1, ptr addrspace(1) %440, align 16
  %.esimd179.3.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1.1, i32 0, i32 16, i32 1, i16 192, i32 0)
  %.idx175.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 44)
  %441 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx175.imul
  store <16 x i32> %.esimd179.3.1, ptr addrspace(1) %441, align 16
  %.esimd179.4.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1.1, i32 0, i32 16, i32 1, i16 256, i32 0)
  %.idx176.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 48)
  %442 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx176.imul
  store <16 x i32> %.esimd179.4.1, ptr addrspace(1) %442, align 16
  %.esimd179.5.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1.1, i32 0, i32 16, i32 1, i16 320, i32 0)
  %.idx177.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 52)
  %443 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx177.imul
  store <16 x i32> %.esimd179.5.1, ptr addrspace(1) %443, align 16
  %.esimd179.6.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1.1, i32 0, i32 16, i32 1, i16 384, i32 0)
  %.idx178.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 56)
  %444 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx178.imul
  store <16 x i32> %.esimd179.6.1, ptr addrspace(1) %444, align 16
  %.esimd179.7.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd178.1.1, i32 0, i32 16, i32 1, i16 448, i32 0)
  %.idx179.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 60)
  %445 = getelementptr inbounds i8, ptr addrspace(1) %gep185, i64 %.idx179.imul
  store <16 x i32> %.esimd179.7.1, ptr addrspace(1) %445, align 16
  %446 = add nsw i32 %334, 1, !spirv.Decorations !22
  %447 = add nuw nsw i32 %95, 3, !spirv.Decorations !24
  %448 = icmp slt i32 %447, %8
  br i1 %448, label %.loopexit1, label %680

449:                                              ; preds = %424
  %450 = icmp eq i32 %422, 0
  br i1 %450, label %.loopexit1.loopexit, label %.loopexit1

.loopexit1.loopexit:                              ; preds = %449
  br label %.loopexit1

.loopexit1:                                       ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11, %.loopexit1.loopexit, %449
  %.sroa.22.4 = phi <128 x i32> [ %.esimd178.1.1, %449 ], [ zeroinitializer, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ zeroinitializer, %.loopexit1.loopexit ]
  %.sroa.0.4 = phi <128 x i32> [ %.esimd178.1130, %449 ], [ zeroinitializer, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ zeroinitializer, %.loopexit1.loopexit ]
  %451 = phi ptr addrspace(4) [ %421, %449 ], [ %85, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %421, %.loopexit1.loopexit ]
  %452 = phi i32 [ %334, %449 ], [ %446, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %334, %.loopexit1.loopexit ]
  %453 = phi i32 [ %422, %449 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ 0, %.loopexit1.loopexit ]
  br i1 %.not160, label %454, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1

454:                                              ; preds = %.loopexit1
  %455 = load <16 x i32>, ptr addrspace(1) %.51615, align 16
  %.esimd180 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0454.020, <16 x i32> %455, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %456 = getelementptr inbounds nuw i8, ptr addrspace(1) %.51615, i64 64
  %457 = load <8 x i32>, ptr addrspace(1) %456, align 16
  %.esimd181 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd180, <8 x i32> %457, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd182 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd134, <24 x i32> %.esimd181, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  %458 = add nsw i32 %.51624, 1, !spirv.Decorations !22
  %459 = icmp eq i32 %458, %8
  br i1 %459, label %460, label %462

460:                                              ; preds = %454
  %461 = getelementptr inbounds i32, ptr addrspace(1) %.51615, i64 %42
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1

462:                                              ; preds = %454
  %463 = getelementptr inbounds i32, ptr addrspace(1) %.51615, i64 %.imul161
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1: ; preds = %462, %460, %.loopexit1
  %.esimd18263 = phi <40 x i32> [ %.esimd134, %.loopexit1 ], [ %.esimd182, %460 ], [ %.esimd182, %462 ]
  %.41623 = phi i32 [ %.51624, %.loopexit1 ], [ 0, %460 ], [ %458, %462 ]
  %.41614 = phi ptr addrspace(1) [ %.51615, %.loopexit1 ], [ %461, %460 ], [ %463, %462 ]
  %.not181 = phi i1 [ false, %.loopexit1 ], [ false, %460 ], [ true, %462 ]
  %.4 = phi i32 [ 1, %.loopexit1 ], [ 1, %460 ], [ 0, %462 ]
  %.sroa.0454.2 = phi <24 x i32> [ %.sroa.0454.020, %.loopexit1 ], [ %.esimd181, %460 ], [ %.esimd181, %462 ]
  %.esimd183 = tail call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %.esimd23466, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd184 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %.esimd23466, <7 x i32> %.esimd183, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd185 = tail call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd184, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd186 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd184, <1 x i32> %.esimd185, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  %.esimd187 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd188 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 64, i32 40)
  %464 = lshr <16 x i32> %.esimd188, %78
  %465 = shl <16 x i32> %.esimd187, %77
  %466 = or <16 x i32> %464, %465
  %467 = bitcast <16 x i32> %466 to <32 x i16>
  %.esimd189 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %467, i32 0, i32 16, i32 2, i16 2, i32 0)
  %468 = zext <16 x i16> %.esimd189 to <16 x i32>
  %469 = mul <16 x i32> %468, splat (i32 -2082680531)
  %.esimd190 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd170, <16 x i32> %469, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %470 = lshr <16 x i32> %466, splat (i32 13)
  %471 = bitcast <16 x i32> %470 to <32 x i16>
  %.esimd191 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %471, i32 0, i32 16, i32 2, i16 0, i32 0)
  %472 = zext <16 x i16> %.esimd191 to <16 x i32>
  %473 = mul <16 x i32> %472, splat (i32 -2082680531)
  %.esimd192 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd190, <16 x i32> %473, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %474 = lshr <16 x i32> %466, splat (i32 10)
  %475 = bitcast <16 x i32> %474 to <32 x i16>
  %.esimd193 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %475, i32 0, i32 16, i32 2, i16 0, i32 0)
  %476 = zext <16 x i16> %.esimd193 to <16 x i32>
  %477 = mul <16 x i32> %476, splat (i32 -2082680531)
  %.esimd194 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd174, <16 x i32> %477, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %478 = lshr <16 x i32> %466, splat (i32 7)
  %479 = bitcast <16 x i32> %478 to <32 x i16>
  %.esimd195 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %479, i32 0, i32 16, i32 2, i16 0, i32 0)
  %480 = zext <16 x i16> %.esimd195 to <16 x i32>
  %481 = mul <16 x i32> %480, splat (i32 -2082680531)
  %.esimd196 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd194, <16 x i32> %481, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %.esimd198 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 96, i32 40)
  %482 = lshr <16 x i32> %.esimd198, %80
  %483 = shl <16 x i32> %.esimd188, %79
  %484 = or <16 x i32> %482, %483
  %485 = bitcast <16 x i32> %484 to <32 x i16>
  %.esimd199 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %485, i32 0, i32 16, i32 2, i16 2, i32 0)
  %486 = zext <16 x i16> %.esimd199 to <16 x i32>
  %487 = mul <16 x i32> %486, splat (i32 -2082680531)
  %.esimd200 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd192, <16 x i32> %487, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %488 = lshr <16 x i32> %484, splat (i32 13)
  %489 = bitcast <16 x i32> %488 to <32 x i16>
  %.esimd201 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %489, i32 0, i32 16, i32 2, i16 0, i32 0)
  %490 = zext <16 x i16> %.esimd201 to <16 x i32>
  %491 = mul <16 x i32> %490, splat (i32 -2082680531)
  %.esimd202 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd200, <16 x i32> %491, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %492 = lshr <16 x i32> %484, splat (i32 10)
  %493 = bitcast <16 x i32> %492 to <32 x i16>
  %.esimd203 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %493, i32 0, i32 16, i32 2, i16 0, i32 0)
  %494 = zext <16 x i16> %.esimd203 to <16 x i32>
  %495 = mul <16 x i32> %494, splat (i32 -2082680531)
  %.esimd204 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd196, <16 x i32> %495, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %496 = lshr <16 x i32> %484, splat (i32 7)
  %497 = bitcast <16 x i32> %496 to <32 x i16>
  %.esimd205 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %497, i32 0, i32 16, i32 2, i16 0, i32 0)
  %498 = zext <16 x i16> %.esimd205 to <16 x i32>
  %499 = mul <16 x i32> %498, splat (i32 -2082680531)
  %.esimd206 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd204, <16 x i32> %499, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %.esimd208 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 128, i32 40)
  %500 = lshr <16 x i32> %.esimd208, %82
  %501 = shl <16 x i32> %.esimd198, %81
  %502 = or <16 x i32> %500, %501
  %503 = bitcast <16 x i32> %502 to <32 x i16>
  %.esimd209 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %503, i32 0, i32 16, i32 2, i16 2, i32 0)
  %504 = zext <16 x i16> %.esimd209 to <16 x i32>
  %505 = mul <16 x i32> %504, splat (i32 -2082680531)
  %.esimd210 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd202, <16 x i32> %505, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %506 = lshr <16 x i32> %502, splat (i32 13)
  %507 = bitcast <16 x i32> %506 to <32 x i16>
  %.esimd211 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %507, i32 0, i32 16, i32 2, i16 0, i32 0)
  %508 = zext <16 x i16> %.esimd211 to <16 x i32>
  %509 = mul <16 x i32> %508, splat (i32 -2082680531)
  %.esimd212 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd210, <16 x i32> %509, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %510 = lshr <16 x i32> %502, splat (i32 10)
  %511 = bitcast <16 x i32> %510 to <32 x i16>
  %.esimd213 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %511, i32 0, i32 16, i32 2, i16 0, i32 0)
  %512 = zext <16 x i16> %.esimd213 to <16 x i32>
  %513 = mul <16 x i32> %512, splat (i32 -2082680531)
  %.esimd214 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd206, <16 x i32> %513, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %514 = lshr <16 x i32> %502, splat (i32 7)
  %515 = bitcast <16 x i32> %514 to <32 x i16>
  %.esimd215 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %515, i32 0, i32 16, i32 2, i16 0, i32 0)
  %516 = zext <16 x i16> %.esimd215 to <16 x i32>
  %517 = mul <16 x i32> %516, splat (i32 -2082680531)
  %.esimd216 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd214, <16 x i32> %517, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %.esimd217 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 8, i32 8, i32 1, i16 96, i32 40)
  %518 = lshr <16 x i32> %.esimd208, %84
  %519 = shl <16 x i32> %.esimd217, %83
  %520 = or <16 x i32> %519, %518
  %521 = bitcast <16 x i32> %520 to <32 x i16>
  %.esimd219 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %521, i32 0, i32 16, i32 2, i16 2, i32 0)
  %522 = zext <16 x i16> %.esimd219 to <16 x i32>
  %523 = mul <16 x i32> %522, splat (i32 -2082680531)
  %.esimd220 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd212, <16 x i32> %523, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %524 = lshr <16 x i32> %520, splat (i32 13)
  %525 = bitcast <16 x i32> %524 to <32 x i16>
  %.esimd221 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %525, i32 0, i32 16, i32 2, i16 0, i32 0)
  %526 = zext <16 x i16> %.esimd221 to <16 x i32>
  %527 = mul <16 x i32> %526, splat (i32 -2082680531)
  %.esimd222 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd220, <16 x i32> %527, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %528 = lshr <16 x i32> %520, splat (i32 10)
  %529 = bitcast <16 x i32> %528 to <32 x i16>
  %.esimd223 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %529, i32 0, i32 16, i32 2, i16 0, i32 0)
  %530 = zext <16 x i16> %.esimd223 to <16 x i32>
  %531 = mul <16 x i32> %530, splat (i32 -2082680531)
  %.esimd224 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd216, <16 x i32> %531, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %532 = lshr <16 x i32> %520, splat (i32 7)
  %533 = bitcast <16 x i32> %532 to <32 x i16>
  %.esimd225 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %533, i32 0, i32 16, i32 2, i16 0, i32 0)
  %534 = zext <16 x i16> %.esimd225 to <16 x i32>
  %535 = mul <16 x i32> %534, splat (i32 -2082680531)
  %.esimd226 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd224, <16 x i32> %535, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %536 = load <128 x i32>, ptr addrspace(4) %451, align 16
  %.esimd227 = tail call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01415.035, <128 x i32> %536, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %537 = getelementptr inbounds nuw i8, ptr addrspace(4) %451, i64 512
  %538 = load <128 x i32>, ptr addrspace(4) %537, align 16
  %.esimd228 = tail call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd227, <128 x i32> %538, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  %.esimd229 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd228, i32 0, i32 64, i32 1, i16 0, i32 0)
  %.esimd230 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.0.4, <128 x i32> %.esimd222, <64 x i32> %.esimd229, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd229.1 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd228, i32 0, i32 64, i32 1, i16 256, i32 0)
  %.esimd230.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.22.4, <128 x i32> %.esimd222, <64 x i32> %.esimd229.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd229.1132 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd228, i32 0, i32 64, i32 1, i16 512, i32 0)
  %.esimd230.1133 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd230, <128 x i32> %.esimd226, <64 x i32> %.esimd229.1132, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd229.1.1 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd228, i32 0, i32 64, i32 1, i16 768, i32 0)
  %.esimd230.1.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd230.1, <128 x i32> %.esimd226, <64 x i32> %.esimd229.1.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %539 = getelementptr inbounds nuw i8, ptr addrspace(4) %451, i64 1024
  %540 = add nsw i32 %453, 1, !spirv.Decorations !22
  %541 = icmp eq i32 %540, %8
  br i1 %541, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10, label %542

542:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1
  %543 = add nuw nsw i32 %95, 4, !spirv.Decorations !24
  %544 = icmp slt i32 %543, %8
  br i1 %544, label %567, label %680

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1
  %545 = add nsw i32 %452, %30, !spirv.Decorations !22
  %546 = sext i32 %545 to i64
  %547 = add i64 %91, %546
  %548 = mul i64 %547, %93
  %gep187 = getelementptr i32, ptr addrspace(1) %invariant.gep, i64 %548
  %.esimd231 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1133, i32 0, i32 16, i32 1, i16 0, i32 0)
  store <16 x i32> %.esimd231, ptr addrspace(1) %gep187, align 16
  %.esimd231.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1133, i32 0, i32 16, i32 1, i16 64, i32 0)
  %549 = getelementptr inbounds i32, ptr addrspace(1) %gep187, i64 %92
  store <16 x i32> %.esimd231.1, ptr addrspace(1) %549, align 16
  %.esimd231.2 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1133, i32 0, i32 16, i32 1, i16 128, i32 0)
  %550 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx138
  store <16 x i32> %.esimd231.2, ptr addrspace(1) %550, align 16
  %.esimd231.3 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1133, i32 0, i32 16, i32 1, i16 192, i32 0)
  %.idx181.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 12)
  %551 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx181.imul
  store <16 x i32> %.esimd231.3, ptr addrspace(1) %551, align 16
  %.esimd231.4 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1133, i32 0, i32 16, i32 1, i16 256, i32 0)
  %552 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %93
  store <16 x i32> %.esimd231.4, ptr addrspace(1) %552, align 16
  %.esimd231.5 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1133, i32 0, i32 16, i32 1, i16 320, i32 0)
  %.idx183.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 20)
  %553 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx183.imul
  store <16 x i32> %.esimd231.5, ptr addrspace(1) %553, align 16
  %.esimd231.6 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1133, i32 0, i32 16, i32 1, i16 384, i32 0)
  %.idx184.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 24)
  %554 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx184.imul
  store <16 x i32> %.esimd231.6, ptr addrspace(1) %554, align 16
  %.esimd231.7 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1133, i32 0, i32 16, i32 1, i16 448, i32 0)
  %.idx185.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 28)
  %555 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx185.imul
  store <16 x i32> %.esimd231.7, ptr addrspace(1) %555, align 16
  %.esimd231.1134 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1.1, i32 0, i32 16, i32 1, i16 0, i32 0)
  %556 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx144
  store <16 x i32> %.esimd231.1134, ptr addrspace(1) %556, align 16
  %.esimd231.1.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1.1, i32 0, i32 16, i32 1, i16 64, i32 0)
  %.idx187.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 36)
  %557 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx187.imul
  store <16 x i32> %.esimd231.1.1, ptr addrspace(1) %557, align 16
  %.esimd231.2.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1.1, i32 0, i32 16, i32 1, i16 128, i32 0)
  %.idx188.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 40)
  %558 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx188.imul
  store <16 x i32> %.esimd231.2.1, ptr addrspace(1) %558, align 16
  %.esimd231.3.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1.1, i32 0, i32 16, i32 1, i16 192, i32 0)
  %.idx189.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 44)
  %559 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx189.imul
  store <16 x i32> %.esimd231.3.1, ptr addrspace(1) %559, align 16
  %.esimd231.4.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1.1, i32 0, i32 16, i32 1, i16 256, i32 0)
  %.idx190.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 48)
  %560 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx190.imul
  store <16 x i32> %.esimd231.4.1, ptr addrspace(1) %560, align 16
  %.esimd231.5.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1.1, i32 0, i32 16, i32 1, i16 320, i32 0)
  %.idx191.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 52)
  %561 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx191.imul
  store <16 x i32> %.esimd231.5.1, ptr addrspace(1) %561, align 16
  %.esimd231.6.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1.1, i32 0, i32 16, i32 1, i16 384, i32 0)
  %.idx192.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 56)
  %562 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx192.imul
  store <16 x i32> %.esimd231.6.1, ptr addrspace(1) %562, align 16
  %.esimd231.7.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd230.1.1, i32 0, i32 16, i32 1, i16 448, i32 0)
  %.idx193.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 60)
  %563 = getelementptr inbounds i8, ptr addrspace(1) %gep187, i64 %.idx193.imul
  store <16 x i32> %.esimd231.7.1, ptr addrspace(1) %563, align 16
  %564 = add nsw i32 %452, 1, !spirv.Decorations !22
  %565 = add nuw nsw i32 %95, 4, !spirv.Decorations !24
  %566 = icmp slt i32 %565, %8
  br i1 %566, label %.loopexit, label %680

567:                                              ; preds = %542
  %568 = icmp eq i32 %540, 0
  br i1 %568, label %.loopexit.loopexit, label %.loopexit

.loopexit.loopexit:                               ; preds = %567
  br label %.loopexit

.loopexit:                                        ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10, %.loopexit.loopexit, %567
  %.sroa.22.5 = phi <128 x i32> [ %.esimd230.1.1, %567 ], [ zeroinitializer, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ zeroinitializer, %.loopexit.loopexit ]
  %.sroa.0.5 = phi <128 x i32> [ %.esimd230.1133, %567 ], [ zeroinitializer, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ zeroinitializer, %.loopexit.loopexit ]
  %569 = phi ptr addrspace(4) [ %539, %567 ], [ %85, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %539, %.loopexit.loopexit ]
  %570 = phi i32 [ %452, %567 ], [ %564, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %452, %.loopexit.loopexit ]
  %571 = phi i32 [ %540, %567 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ 0, %.loopexit.loopexit ]
  br i1 %.not181, label %572, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit

572:                                              ; preds = %.loopexit
  %573 = load <16 x i32>, ptr addrspace(1) %.41614, align 16
  %.esimd232 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0449.015, <16 x i32> %573, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %574 = getelementptr inbounds nuw i8, ptr addrspace(1) %.41614, i64 64
  %575 = load <8 x i32>, ptr addrspace(1) %574, align 16
  %.esimd233 = tail call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd232, <8 x i32> %575, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd234 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd186, <24 x i32> %.esimd233, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  %576 = add nsw i32 %.41623, 1, !spirv.Decorations !22
  %577 = icmp eq i32 %576, %8
  br i1 %577, label %578, label %580

578:                                              ; preds = %572
  %579 = getelementptr inbounds i32, ptr addrspace(1) %.41614, i64 %42
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit

580:                                              ; preds = %572
  %581 = getelementptr inbounds i32, ptr addrspace(1) %.41614, i64 %.imul161
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit: ; preds = %580, %578, %.loopexit
  %.esimd23467 = phi <40 x i32> [ %.esimd186, %.loopexit ], [ %.esimd234, %578 ], [ %.esimd234, %580 ]
  %.31622 = phi i32 [ %.41623, %.loopexit ], [ 0, %578 ], [ %576, %580 ]
  %.31613 = phi ptr addrspace(1) [ %.41614, %.loopexit ], [ %579, %578 ], [ %581, %580 ]
  %.3 = phi i32 [ 1, %.loopexit ], [ 1, %578 ], [ 0, %580 ]
  %.sroa.0449.2 = phi <24 x i32> [ %.sroa.0449.015, %.loopexit ], [ %.esimd233, %578 ], [ %.esimd233, %580 ]
  %.esimd235 = tail call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %.esimd23847, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd236 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %.esimd23847, <7 x i32> %.esimd235, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd237 = tail call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd236, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd238 = tail call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd236, <1 x i32> %.esimd237, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  %.esimd239 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd240 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 64, i32 40)
  %582 = lshr <16 x i32> %.esimd240, %78
  %583 = shl <16 x i32> %.esimd239, %77
  %584 = or <16 x i32> %582, %583
  %585 = bitcast <16 x i32> %584 to <32 x i16>
  %.esimd241 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %585, i32 0, i32 16, i32 2, i16 2, i32 0)
  %586 = zext <16 x i16> %.esimd241 to <16 x i32>
  %587 = mul <16 x i32> %586, splat (i32 -2082680531)
  %.esimd242 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd222, <16 x i32> %587, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %588 = lshr <16 x i32> %584, splat (i32 13)
  %589 = bitcast <16 x i32> %588 to <32 x i16>
  %.esimd243 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %589, i32 0, i32 16, i32 2, i16 0, i32 0)
  %590 = zext <16 x i16> %.esimd243 to <16 x i32>
  %591 = mul <16 x i32> %590, splat (i32 -2082680531)
  %.esimd244 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd242, <16 x i32> %591, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %592 = lshr <16 x i32> %584, splat (i32 10)
  %593 = bitcast <16 x i32> %592 to <32 x i16>
  %.esimd245 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %593, i32 0, i32 16, i32 2, i16 0, i32 0)
  %594 = zext <16 x i16> %.esimd245 to <16 x i32>
  %595 = mul <16 x i32> %594, splat (i32 -2082680531)
  %.esimd246 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd226, <16 x i32> %595, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %596 = lshr <16 x i32> %584, splat (i32 7)
  %597 = bitcast <16 x i32> %596 to <32 x i16>
  %.esimd247 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %597, i32 0, i32 16, i32 2, i16 0, i32 0)
  %598 = zext <16 x i16> %.esimd247 to <16 x i32>
  %599 = mul <16 x i32> %598, splat (i32 -2082680531)
  %.esimd248 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd246, <16 x i32> %599, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %.esimd250 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 96, i32 40)
  %600 = lshr <16 x i32> %.esimd250, %80
  %601 = shl <16 x i32> %.esimd240, %79
  %602 = or <16 x i32> %600, %601
  %603 = bitcast <16 x i32> %602 to <32 x i16>
  %.esimd251 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %603, i32 0, i32 16, i32 2, i16 2, i32 0)
  %604 = zext <16 x i16> %.esimd251 to <16 x i32>
  %605 = mul <16 x i32> %604, splat (i32 -2082680531)
  %.esimd252 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd244, <16 x i32> %605, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %606 = lshr <16 x i32> %602, splat (i32 13)
  %607 = bitcast <16 x i32> %606 to <32 x i16>
  %.esimd253 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %607, i32 0, i32 16, i32 2, i16 0, i32 0)
  %608 = zext <16 x i16> %.esimd253 to <16 x i32>
  %609 = mul <16 x i32> %608, splat (i32 -2082680531)
  %.esimd254 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd252, <16 x i32> %609, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %610 = lshr <16 x i32> %602, splat (i32 10)
  %611 = bitcast <16 x i32> %610 to <32 x i16>
  %.esimd255 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %611, i32 0, i32 16, i32 2, i16 0, i32 0)
  %612 = zext <16 x i16> %.esimd255 to <16 x i32>
  %613 = mul <16 x i32> %612, splat (i32 -2082680531)
  %.esimd256 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd248, <16 x i32> %613, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %614 = lshr <16 x i32> %602, splat (i32 7)
  %615 = bitcast <16 x i32> %614 to <32 x i16>
  %.esimd257 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %615, i32 0, i32 16, i32 2, i16 0, i32 0)
  %616 = zext <16 x i16> %.esimd257 to <16 x i32>
  %617 = mul <16 x i32> %616, splat (i32 -2082680531)
  %.esimd258 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd256, <16 x i32> %617, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %.esimd260 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 128, i32 40)
  %618 = lshr <16 x i32> %.esimd260, %82
  %619 = shl <16 x i32> %.esimd250, %81
  %620 = or <16 x i32> %618, %619
  %621 = bitcast <16 x i32> %620 to <32 x i16>
  %.esimd261 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %621, i32 0, i32 16, i32 2, i16 2, i32 0)
  %622 = zext <16 x i16> %.esimd261 to <16 x i32>
  %623 = mul <16 x i32> %622, splat (i32 -2082680531)
  %.esimd262 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd254, <16 x i32> %623, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %624 = lshr <16 x i32> %620, splat (i32 13)
  %625 = bitcast <16 x i32> %624 to <32 x i16>
  %.esimd263 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %625, i32 0, i32 16, i32 2, i16 0, i32 0)
  %626 = zext <16 x i16> %.esimd263 to <16 x i32>
  %627 = mul <16 x i32> %626, splat (i32 -2082680531)
  %.esimd264 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd262, <16 x i32> %627, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %628 = lshr <16 x i32> %620, splat (i32 10)
  %629 = bitcast <16 x i32> %628 to <32 x i16>
  %.esimd265 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %629, i32 0, i32 16, i32 2, i16 0, i32 0)
  %630 = zext <16 x i16> %.esimd265 to <16 x i32>
  %631 = mul <16 x i32> %630, splat (i32 -2082680531)
  %.esimd266 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd258, <16 x i32> %631, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %632 = lshr <16 x i32> %620, splat (i32 7)
  %633 = bitcast <16 x i32> %632 to <32 x i16>
  %.esimd267 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %633, i32 0, i32 16, i32 2, i16 0, i32 0)
  %634 = zext <16 x i16> %.esimd267 to <16 x i32>
  %635 = mul <16 x i32> %634, splat (i32 -2082680531)
  %.esimd268 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd266, <16 x i32> %635, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %.esimd269 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 8, i32 8, i32 1, i16 96, i32 40)
  %636 = lshr <16 x i32> %.esimd260, %84
  %637 = shl <16 x i32> %.esimd269, %83
  %638 = or <16 x i32> %637, %636
  %639 = bitcast <16 x i32> %638 to <32 x i16>
  %.esimd271 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %639, i32 0, i32 16, i32 2, i16 2, i32 0)
  %640 = zext <16 x i16> %.esimd271 to <16 x i32>
  %641 = mul <16 x i32> %640, splat (i32 -2082680531)
  %.esimd272 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd264, <16 x i32> %641, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %642 = lshr <16 x i32> %638, splat (i32 13)
  %643 = bitcast <16 x i32> %642 to <32 x i16>
  %.esimd273 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %643, i32 0, i32 16, i32 2, i16 0, i32 0)
  %644 = zext <16 x i16> %.esimd273 to <16 x i32>
  %645 = mul <16 x i32> %644, splat (i32 -2082680531)
  %.esimd274 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd272, <16 x i32> %645, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %646 = lshr <16 x i32> %638, splat (i32 10)
  %647 = bitcast <16 x i32> %646 to <32 x i16>
  %.esimd275 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %647, i32 0, i32 16, i32 2, i16 0, i32 0)
  %648 = zext <16 x i16> %.esimd275 to <16 x i32>
  %649 = mul <16 x i32> %648, splat (i32 -2082680531)
  %.esimd276 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd268, <16 x i32> %649, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %650 = lshr <16 x i32> %638, splat (i32 7)
  %651 = bitcast <16 x i32> %650 to <32 x i16>
  %.esimd277 = tail call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %651, i32 0, i32 16, i32 2, i16 0, i32 0)
  %652 = zext <16 x i16> %.esimd277 to <16 x i32>
  %653 = mul <16 x i32> %652, splat (i32 -2082680531)
  %.esimd278 = tail call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd276, <16 x i32> %653, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %654 = load <128 x i32>, ptr addrspace(4) %569, align 16
  %.esimd279 = tail call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01403.030, <128 x i32> %654, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %655 = getelementptr inbounds nuw i8, ptr addrspace(4) %569, i64 512
  %656 = load <128 x i32>, ptr addrspace(4) %655, align 16
  %.esimd280 = tail call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd279, <128 x i32> %656, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  %.esimd281 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd280, i32 0, i32 64, i32 1, i16 0, i32 0)
  %.esimd282 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.0.5, <128 x i32> %.esimd274, <64 x i32> %.esimd281, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd281.1 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd280, i32 0, i32 64, i32 1, i16 256, i32 0)
  %.esimd282.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.sroa.22.5, <128 x i32> %.esimd274, <64 x i32> %.esimd281.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd281.1135 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd280, i32 0, i32 64, i32 1, i16 512, i32 0)
  %.esimd282.1136 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd282, <128 x i32> %.esimd278, <64 x i32> %.esimd281.1135, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %.esimd281.1.1 = tail call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd280, i32 0, i32 64, i32 1, i16 768, i32 0)
  %.esimd282.1.1 = tail call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %.esimd282.1, <128 x i32> %.esimd278, <64 x i32> %.esimd281.1.1, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %657 = getelementptr inbounds nuw i8, ptr addrspace(4) %569, i64 1024
  %658 = add nsw i32 %571, 1, !spirv.Decorations !22
  %659 = icmp eq i32 %658, %8
  br i1 %659, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit, label %680

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit: ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit
  %660 = add nsw i32 %570, %30, !spirv.Decorations !22
  %661 = sext i32 %660 to i64
  %662 = add i64 %91, %661
  %663 = mul i64 %662, %93
  %gep189 = getelementptr i32, ptr addrspace(1) %invariant.gep, i64 %663
  %.esimd283 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1136, i32 0, i32 16, i32 1, i16 0, i32 0)
  store <16 x i32> %.esimd283, ptr addrspace(1) %gep189, align 16
  %.esimd283.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1136, i32 0, i32 16, i32 1, i16 64, i32 0)
  %664 = getelementptr inbounds i32, ptr addrspace(1) %gep189, i64 %92
  store <16 x i32> %.esimd283.1, ptr addrspace(1) %664, align 16
  %.esimd283.2 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1136, i32 0, i32 16, i32 1, i16 128, i32 0)
  %665 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx138
  store <16 x i32> %.esimd283.2, ptr addrspace(1) %665, align 16
  %.esimd283.3 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1136, i32 0, i32 16, i32 1, i16 192, i32 0)
  %.idx195.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 12)
  %666 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx195.imul
  store <16 x i32> %.esimd283.3, ptr addrspace(1) %666, align 16
  %.esimd283.4 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1136, i32 0, i32 16, i32 1, i16 256, i32 0)
  %667 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %93
  store <16 x i32> %.esimd283.4, ptr addrspace(1) %667, align 16
  %.esimd283.5 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1136, i32 0, i32 16, i32 1, i16 320, i32 0)
  %.idx197.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 20)
  %668 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx197.imul
  store <16 x i32> %.esimd283.5, ptr addrspace(1) %668, align 16
  %.esimd283.6 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1136, i32 0, i32 16, i32 1, i16 384, i32 0)
  %.idx198.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 24)
  %669 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx198.imul
  store <16 x i32> %.esimd283.6, ptr addrspace(1) %669, align 16
  %.esimd283.7 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1136, i32 0, i32 16, i32 1, i16 448, i32 0)
  %.idx199.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 28)
  %670 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx199.imul
  store <16 x i32> %.esimd283.7, ptr addrspace(1) %670, align 16
  %.esimd283.1137 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1.1, i32 0, i32 16, i32 1, i16 0, i32 0)
  %671 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx144
  store <16 x i32> %.esimd283.1137, ptr addrspace(1) %671, align 16
  %.esimd283.1.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1.1, i32 0, i32 16, i32 1, i16 64, i32 0)
  %.idx201.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 36)
  %672 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx201.imul
  store <16 x i32> %.esimd283.1.1, ptr addrspace(1) %672, align 16
  %.esimd283.2.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1.1, i32 0, i32 16, i32 1, i16 128, i32 0)
  %.idx202.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 40)
  %673 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx202.imul
  store <16 x i32> %.esimd283.2.1, ptr addrspace(1) %673, align 16
  %.esimd283.3.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1.1, i32 0, i32 16, i32 1, i16 192, i32 0)
  %.idx203.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 44)
  %674 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx203.imul
  store <16 x i32> %.esimd283.3.1, ptr addrspace(1) %674, align 16
  %.esimd283.4.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1.1, i32 0, i32 16, i32 1, i16 256, i32 0)
  %.idx204.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 48)
  %675 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx204.imul
  store <16 x i32> %.esimd283.4.1, ptr addrspace(1) %675, align 16
  %.esimd283.5.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1.1, i32 0, i32 16, i32 1, i16 320, i32 0)
  %.idx205.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 52)
  %676 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx205.imul
  store <16 x i32> %.esimd283.5.1, ptr addrspace(1) %676, align 16
  %.esimd283.6.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1.1, i32 0, i32 16, i32 1, i16 384, i32 0)
  %.idx206.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 56)
  %677 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx206.imul
  store <16 x i32> %.esimd283.6.1, ptr addrspace(1) %677, align 16
  %.esimd283.7.1 = tail call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %.esimd282.1.1, i32 0, i32 16, i32 1, i16 448, i32 0)
  %.idx207.imul = tail call i64 @llvm.genx.ssmul.i64.i32(i32 %13, i32 60)
  %678 = getelementptr inbounds i8, ptr addrspace(1) %gep189, i64 %.idx207.imul
  store <16 x i32> %.esimd283.7.1, ptr addrspace(1) %678, align 16
  %679 = add nsw i32 %570, 1, !spirv.Decorations !22
  br label %680

680:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10, %542, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11, %424, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12, %306, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13, %188
  %.sroa.22.6 = phi <128 x i32> [ %.esimd282.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd282.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd230.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd230.1.1, %542 ], [ %.esimd178.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd178.1.1, %424 ], [ %.esimd126.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd126.1.1, %306 ], [ %.esimd74.1.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.esimd74.1.1, %188 ]
  %.sroa.0.6 = phi <128 x i32> [ %.esimd282.1136, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd282.1136, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd230.1133, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd230.1133, %542 ], [ %.esimd178.1130, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd178.1130, %424 ], [ %.esimd126.1127, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd126.1127, %306 ], [ %.esimd74.1124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.esimd74.1124, %188 ]
  %.esimd23465 = phi <40 x i32> [ %.esimd23467, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd23467, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd186, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd186, %542 ], [ %.esimd23466, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd23466, %424 ], [ %.esimd23466, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd23466, %306 ], [ %.esimd23466, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.esimd23466, %188 ]
  %.esimd18261 = phi <40 x i32> [ %.esimd18263, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd18263, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd18263, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd18263, %542 ], [ %.esimd134, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd134, %424 ], [ %.esimd18262, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd18262, %306 ], [ %.esimd18262, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.esimd18262, %188 ]
  %.esimd13057 = phi <40 x i32> [ %.esimd13059, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd13059, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd13059, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd13059, %542 ], [ %.esimd13059, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd13059, %424 ], [ %.esimd82, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd82, %306 ], [ %.esimd13058, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.esimd13058, %188 ]
  %.esimd27855 = phi <128 x i32> [ %.esimd278, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd278, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd226, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd226, %542 ], [ %.esimd174, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd174, %424 ], [ %.esimd122, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd122, %306 ], [ %.esimd70, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.esimd70, %188 ]
  %681 = phi <128 x i32> [ %.esimd274, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd274, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd222, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd222, %542 ], [ %.esimd170, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd170, %424 ], [ %.esimd118, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd118, %306 ], [ %.esimd66, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.esimd66, %188 ]
  %.esimd7850 = phi <40 x i32> [ %.esimd7851, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd7851, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd7851, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd7851, %542 ], [ %.esimd7851, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd7851, %424 ], [ %.esimd7851, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd7851, %306 ], [ %.esimd30, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.esimd30, %188 ]
  %.esimd23846 = phi <40 x i32> [ %.esimd238, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd238, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd23847, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd23847, %542 ], [ %.esimd23847, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd23847, %424 ], [ %.esimd23847, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd23847, %306 ], [ %.esimd23847, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.esimd23847, %188 ]
  %.21621 = phi i32 [ %.31622, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.31622, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.41623, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.41623, %542 ], [ %.51624, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.51624, %424 ], [ %.61625, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.61625, %306 ], [ %.71626, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.71626, %188 ]
  %.21612 = phi ptr addrspace(1) [ %.31613, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.31613, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.41614, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.41614, %542 ], [ %.51615, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.51615, %424 ], [ %.61616, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.61616, %306 ], [ %.71617, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.71617, %188 ]
  %.2 = phi i32 [ %.3, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.3, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.4, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.4, %542 ], [ %.5, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.5, %424 ], [ %.6, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.6, %306 ], [ %.7, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.7, %188 ]
  %.sroa.0449.1 = phi <24 x i32> [ %.sroa.0449.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0449.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.sroa.0449.015, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0449.015, %542 ], [ %.sroa.0449.015, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0449.015, %424 ], [ %.sroa.0449.015, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0449.015, %306 ], [ %.sroa.0449.015, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0449.015, %188 ]
  %.sroa.0454.1 = phi <24 x i32> [ %.sroa.0454.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0454.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.sroa.0454.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0454.2, %542 ], [ %.sroa.0454.020, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0454.020, %424 ], [ %.sroa.0454.020, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0454.020, %306 ], [ %.sroa.0454.020, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0454.020, %188 ]
  %.sroa.0460.1 = phi <24 x i32> [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0460.2, %542 ], [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0460.2, %424 ], [ %.sroa.0460.024, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0460.024, %306 ], [ %.sroa.0460.024, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0460.024, %188 ]
  %.sroa.0466.1 = phi <24 x i32> [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0466.2, %542 ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0466.2, %424 ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0466.2, %306 ], [ %.sroa.0466.027, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0466.027, %188 ]
  %.sroa.01403.1 = phi <256 x i32> [ %.esimd280, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd280, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.sroa.01403.030, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.01403.030, %542 ], [ %.sroa.01403.030, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.01403.030, %424 ], [ %.sroa.01403.030, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.01403.030, %306 ], [ %.sroa.01403.030, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01403.030, %188 ]
  %.sroa.01415.1 = phi <256 x i32> [ %.esimd228, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd228, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd228, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd228, %542 ], [ %.sroa.01415.035, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.01415.035, %424 ], [ %.sroa.01415.035, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.01415.035, %306 ], [ %.sroa.01415.035, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01415.035, %188 ]
  %.sroa.01427.1 = phi <256 x i32> [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd176, %542 ], [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd176, %424 ], [ %.sroa.01427.039, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.01427.039, %306 ], [ %.sroa.01427.039, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01427.039, %188 ]
  %.sroa.01439.1 = phi <256 x i32> [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd124, %542 ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd124, %424 ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd124, %306 ], [ %.sroa.01439.042, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01439.042, %188 ]
  %682 = phi ptr addrspace(4) [ %85, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %657, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %85, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %539, %542 ], [ %85, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %421, %424 ], [ %85, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %303, %306 ], [ %85, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %185, %188 ]
  %683 = phi i32 [ %679, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %570, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %564, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %452, %542 ], [ %446, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %334, %424 ], [ %328, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %216, %306 ], [ %210, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %97, %188 ]
  %684 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %658, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %540, %542 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %422, %424 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %304, %306 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %186, %188 ]
  %685 = add nuw nsw i32 %95, 5, !spirv.Decorations !24
  %686 = icmp slt i32 %685, %8
  br i1 %686, label %.lr.ph, label %._crit_edge

._crit_edge:                                      ; preds = %680, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5.3
  ret void
}

; Function Attrs: mustprogress nofree nosync nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !26 i32 @llvm.genx.group.id.x() #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !27 i64 @llvm.genx.uumul.i64.i32(i32, i32) #2

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare !genx_intrinsic_id !28 i64 @llvm.genx.ssmul.i64.i32(i32, i32) #2

attributes #0 = { mustprogress nofree nosync nounwind willreturn memory(none) }
attributes #1 = { nounwind memory(readwrite, inaccessiblemem: none, target_mem0: none, target_mem1: none) "CMGenxMain" "oclrt"="1" }
attributes #2 = { nounwind willreturn memory(none) }

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
!10 = !{!"", !"", !"svmptr_t", !"svmptr_t", !"svmptr_t", !"svmptr_t", !"", !"", !"", !"", !"", !"", !"", !"", !"svmptr_t", !"", !""}
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
!24 = !{!23, !25}
!25 = !{i32 4470}
!26 = !{i32 16247}
!27 = !{i32 16514}
!28 = !{i32 16399}

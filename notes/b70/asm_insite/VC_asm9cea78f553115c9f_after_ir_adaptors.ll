; ------------------------------------------------
; VC_asm9cea78f553115c9f_after_ir_adaptors.ll
; ------------------------------------------------
; ModuleID = 'Deserialized LLVM Module'
target datalayout = "e-p:64:64-p3:32:32-p6:32:32-i64:64-n8:16:32:64"
target triple = "genx64-unknown-unknown"

%"class.sycl::_V1::ext::intel::esimd::simd.213.1" = type { %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0" }
%"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0" = type { <40 x i32> }
%"class.sycl::_V1::ext::intel::esimd::simd.5.3" = type { %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.6.2" }
%"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.6.2" = type { <128 x i32> }

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32>, <8 x i32>, i32, i32, i32, i16, i32, <8 x i1>) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32>, <16 x i32>, i32, i32, i32, i16, i32, <16 x i1>) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32>, <8 x i32>, i32, i32, i32, i16, i32, <8 x i1>) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32>, <24 x i32>, i32, i32, i32, i16, i32, <24 x i1>) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32>, <7 x i32>, i32, i32, i32, i16, i32, <7 x i1>) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32>, <1 x i32>, i32, i32, i32, i16, i32, <1 x i1>) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16>, i32, i32, i32, i16, i32) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32>, <16 x i32>, i32, i32, i32, i16, i32, <16 x i1>) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32>, <128 x i32>, i32, i32, i32, i16, i32, <128 x i1>) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32>, <128 x i32>, <64 x i32>, i32, i32, i32, i32, i32, i32) #0

; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: nounwind
define dllexport spir_kernel void @_ZTSZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_EUlNS4_7nd_itemILi1EEEE_(i32 %0, i32 %1, ptr addrspace(1) align 4 %2, ptr addrspace(1) align 4 %3, ptr addrspace(1) align 4 %4, ptr addrspace(1) align 4 %5, i32 %6, i32 %7, i32 %8, i32 %9, i32 %10, i32 %11, i32 %12, i32 %13, ptr addrspace(4) align 4 %14, i32 %15, i32 %16) #1 !spirv.ParameterDecorations !8 !intel_reqd_sub_group_size !13 {
  %18 = alloca [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], align 256, !spirv.Decorations !14
  %19 = alloca [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], align 512, !spirv.Decorations !16
  %20 = alloca [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], align 512, !spirv.Decorations !16
  %21 = alloca [1024 x i8], align 512, !spirv.Decorations !16
  store [1024 x i8] zeroinitializer, ptr %21, align 1
  %22 = addrspacecast ptr %19 to ptr addrspace(4)
  %23 = addrspacecast ptr %20 to ptr addrspace(4)
  %24 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 0) #0
  %25 = insertelement <3 x i64> poison, i64 %24, i32 0
  %26 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 1) #0
  %27 = insertelement <3 x i64> %25, i64 %26, i32 1
  %28 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 2) #0
  %29 = insertelement <3 x i64> %27, i64 %28, i32 2
  %30 = extractelement <3 x i64> %29, i32 0
  %31 = select i1 true, i64 %30, i64 0
  %32 = trunc i64 %31 to i32
  %33 = lshr i32 %32, 1
  %34 = sdiv i32 %33, %0
  %35 = mul i32 %34, %0
  %36 = sub i32 %33, %35
  %37 = icmp slt i32 %36, %1
  %.v = select i1 %37, ptr addrspace(1) %2, ptr addrspace(1) %3
  %38 = addrspacecast ptr addrspace(1) %.v to ptr addrspace(4)
  %.v1628 = select i1 %37, ptr addrspace(1) %4, ptr addrspace(1) %5
  %39 = addrspacecast ptr addrspace(1) %.v1628 to ptr addrspace(4)
  %40 = select i1 %37, i32 0, i32 %1
  %41 = sub nsw i32 %36, %40, !spirv.Decorations !18
  %42 = sdiv i32 %34, %6
  %43 = mul i32 %42, %6
  %44 = sub i32 %34, %43
  %45 = mul nsw i32 %44, %7, !spirv.Decorations !18
  %46 = and i64 %31, 1
  %.not = icmp eq i64 %46, 0
  %47 = select i1 %.not, i32 0, i32 %8
  %48 = add nsw i32 %45, %47, !spirv.Decorations !18
  %.esimd = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 19), <8 x i32> splat (i32 31), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %.esimd14 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 13), <8 x i32> splat (i32 1), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %49 = insertelement <16 x i32> undef, i32 %9, i32 0
  %50 = shufflevector <16 x i32> %49, <16 x i32> undef, <16 x i32> zeroinitializer
  %51 = add <16 x i32> %.esimd, %50
  %52 = add <16 x i32> %.esimd14, %50
  %.esimd15 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 11), <8 x i32> splat (i32 23), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %.esimd16 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 21), <8 x i32> splat (i32 9), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %53 = add <16 x i32> %.esimd15, %50
  %54 = add <16 x i32> %.esimd16, %50
  %.esimd17 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 3), <8 x i32> splat (i32 15), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %.esimd18 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 29), <8 x i32> splat (i32 17), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %55 = add <16 x i32> %.esimd17, %50
  %56 = add <16 x i32> %.esimd18, %50
  %.esimd19 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 27), <8 x i32> splat (i32 7), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %.esimd20 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 5), <8 x i32> splat (i32 25), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %57 = add <16 x i32> %.esimd19, %50
  %58 = add <16 x i32> %.esimd20, %50
  %59 = bitcast ptr %18 to ptr
  call void @llvm.lifetime.start.p0(ptr %18)
  %60 = sext i32 %1 to i64
  %61 = mul nsw i64 %60, 24, !spirv.Decorations !18
  %62 = sext i32 %10 to i64
  %63 = mul nsw i64 %62, %60, !spirv.Decorations !18
  %64 = mul i64 %63, 24
  %65 = add nsw i32 %8, -1, !spirv.Decorations !18
  %66 = sext i32 %65 to i64
  %67 = mul i64 %61, %66
  %68 = sub i64 %64, %67
  %69 = sext i32 %48 to i64
  %70 = mul nsw i64 %69, %60, !spirv.Decorations !18
  %71 = sext i32 %41 to i64
  %72 = add nsw i64 %70, %71, !spirv.Decorations !18
  %73 = sext i32 %42 to i64
  %74 = mul nsw i64 %73, %62, !spirv.Decorations !18
  %75 = mul i64 %74, %60
  %76 = add i64 %75, %72
  %77 = mul i64 %76, 24
  %78 = getelementptr inbounds i32, ptr addrspace(4) %38, i64 %77
  br label %79

79:                                               ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5, %17
  %.01619 = phi i32 [ 0, %17 ], [ %.81627, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.01610 = phi ptr addrspace(4) [ %78, %17 ], [ %.81618, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.0 = phi i32 [ 0, %17 ], [ %.8, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.sroa.0478.0 = phi <24 x i32> [ undef, %17 ], [ %.sroa.0478.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %80 = phi i32 [ 0, %17 ], [ %122, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %81 = icmp ult i32 %80, 4
  br i1 %81, label %101, label %82

82:                                               ; preds = %79
  %83 = bitcast ptr %19 to ptr
  call void @llvm.lifetime.start.p0(ptr %19)
  %84 = bitcast ptr %19 to ptr
  %85 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.6.2", ptr %84, i64 0, i32 0
  %86 = bitcast ptr %85 to ptr
  %87 = bitcast ptr %21 to ptr
  call void @llvm.memcpy.p0.p0.i64(ptr align 512 %86, ptr align 512 %87, i64 1024, i1 false)
  %88 = bitcast ptr %20 to ptr
  call void @llvm.lifetime.start.p0(ptr %20)
  %89 = shl nsw i64 %69, 8, !spirv.Decorations !18
  %90 = getelementptr inbounds i32, ptr addrspace(4) %14, i64 %89
  %91 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 4
  %92 = addrspacecast ptr %91 to ptr addrspace(4)
  %93 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 0
  %94 = addrspacecast ptr %93 to ptr addrspace(4)
  %95 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 1
  %96 = addrspacecast ptr %95 to ptr addrspace(4)
  %97 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 2
  %98 = addrspacecast ptr %97 to ptr addrspace(4)
  %99 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 3
  %100 = addrspacecast ptr %99 to ptr addrspace(4)
  br label %123

101:                                              ; preds = %79
  %102 = icmp sgt i32 %.0, 0
  br i1 %102, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5, label %103

103:                                              ; preds = %101
  %104 = zext i32 %80 to i64
  %105 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 %104
  %106 = addrspacecast ptr %105 to ptr addrspace(4)
  %107 = bitcast ptr addrspace(4) %.01610 to ptr addrspace(4)
  %108 = load <16 x i32>, ptr addrspace(4) %107, align 16
  %.esimd21 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0478.0, <16 x i32> %108, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %109 = getelementptr inbounds i32, ptr addrspace(4) %.01610, i64 16
  %110 = bitcast ptr addrspace(4) %109 to ptr addrspace(4)
  %111 = load <8 x i32>, ptr addrspace(4) %110, align 16
  %.esimd22 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd21, <8 x i32> %111, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %112 = bitcast ptr addrspace(4) %106 to ptr addrspace(4)
  %113 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %112, i64 0, i32 0
  %114 = load <40 x i32>, ptr addrspace(4) %113, align 256
  %.esimd23 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %114, <24 x i32> %.esimd22, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd23, ptr addrspace(4) %113, align 256
  %115 = add nsw i32 %.01619, 1, !spirv.Decorations !18
  %116 = icmp eq i32 %115, %8
  br i1 %116, label %117, label %120

117:                                              ; preds = %103
  %118 = add nsw i32 %.0, 1, !spirv.Decorations !18
  %119 = getelementptr inbounds i32, ptr addrspace(4) %.01610, i64 %68
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5

120:                                              ; preds = %103
  %121 = getelementptr inbounds i32, ptr addrspace(4) %.01610, i64 %61
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5: ; preds = %120, %117, %101
  %.81627 = phi i32 [ %.01619, %101 ], [ 0, %117 ], [ %115, %120 ]
  %.81618 = phi ptr addrspace(4) [ %.01610, %101 ], [ %119, %117 ], [ %121, %120 ]
  %.8 = phi i32 [ %.0, %101 ], [ %118, %117 ], [ %.0, %120 ]
  %.sroa.0478.1 = phi <24 x i32> [ %.sroa.0478.0, %101 ], [ %.esimd22, %117 ], [ %.esimd22, %120 ]
  %122 = add nuw nsw i32 %80, 1, !spirv.Decorations !20
  br label %79, !llvm.loop !22

123:                                              ; preds = %1086, %82
  %.11620 = phi i32 [ %.01619, %82 ], [ %.21621, %1086 ]
  %.11611 = phi ptr addrspace(4) [ %.01610, %82 ], [ %.21612, %1086 ]
  %.1 = phi i32 [ %.0, %82 ], [ %.2, %1086 ]
  %.sroa.0449.0 = phi <24 x i32> [ undef, %82 ], [ %.sroa.0449.1, %1086 ]
  %.sroa.0454.0 = phi <24 x i32> [ undef, %82 ], [ %.sroa.0454.1, %1086 ]
  %.sroa.0460.0 = phi <24 x i32> [ undef, %82 ], [ %.sroa.0460.1, %1086 ]
  %.sroa.0466.0 = phi <24 x i32> [ undef, %82 ], [ %.sroa.0466.1, %1086 ]
  %.sroa.0472.0 = phi <24 x i32> [ undef, %82 ], [ %.sroa.0472.1, %1086 ]
  %.sroa.01403.0 = phi <256 x i32> [ undef, %82 ], [ %.sroa.01403.1, %1086 ]
  %.sroa.01415.0 = phi <256 x i32> [ undef, %82 ], [ %.sroa.01415.1, %1086 ]
  %.sroa.01427.0 = phi <256 x i32> [ undef, %82 ], [ %.sroa.01427.1, %1086 ]
  %.sroa.01439.0 = phi <256 x i32> [ undef, %82 ], [ %.sroa.01439.1, %1086 ]
  %.sroa.01451.0 = phi <256 x i32> [ undef, %82 ], [ %.esimd72, %1086 ]
  %124 = phi ptr addrspace(4) [ %90, %82 ], [ %1087, %1086 ]
  %125 = phi i32 [ 0, %82 ], [ %1088, %1086 ]
  %126 = phi i32 [ 0, %82 ], [ %1089, %1086 ]
  %127 = phi i32 [ 0, %82 ], [ %1090, %1086 ]
  %128 = icmp slt i32 %127, %8
  br i1 %128, label %129, label %1091

129:                                              ; preds = %123
  %130 = icmp eq i32 %126, 0
  br i1 %130, label %.preheader, label %140

.preheader:                                       ; preds = %129
  br label %131

131:                                              ; preds = %134, %.preheader
  %132 = phi i32 [ %139, %134 ], [ 0, %.preheader ]
  %133 = icmp ult i32 %132, 2
  br i1 %133, label %134, label %.loopexit4

134:                                              ; preds = %131
  %135 = zext i32 %132 to i64
  %136 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr %20, i64 0, i64 %135
  %137 = addrspacecast ptr %136 to ptr addrspace(4)
  %138 = bitcast ptr addrspace(4) %137 to ptr addrspace(4)
  store <128 x i32> zeroinitializer, ptr addrspace(4) %138, align 512
  %139 = add nuw nsw i32 %132, 1, !spirv.Decorations !20
  br label %131, !llvm.loop !24

.loopexit4:                                       ; preds = %131
  br label %140

140:                                              ; preds = %.loopexit4, %129
  %141 = icmp sgt i32 %.1, 0
  br i1 %141, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4, label %142

142:                                              ; preds = %140
  %143 = bitcast ptr addrspace(4) %.11611 to ptr addrspace(4)
  %144 = load <16 x i32>, ptr addrspace(4) %143, align 16
  %.esimd24 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0472.0, <16 x i32> %144, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %145 = getelementptr inbounds i32, ptr addrspace(4) %.11611, i64 16
  %146 = bitcast ptr addrspace(4) %145 to ptr addrspace(4)
  %147 = load <8 x i32>, ptr addrspace(4) %146, align 16
  %.esimd25 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd24, <8 x i32> %147, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %148 = bitcast ptr addrspace(4) %92 to ptr addrspace(4)
  %149 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %148, i64 0, i32 0
  %150 = load <40 x i32>, ptr addrspace(4) %149, align 256
  %.esimd26 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %150, <24 x i32> %.esimd25, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd26, ptr addrspace(4) %149, align 256
  %151 = add nsw i32 %.11620, 1, !spirv.Decorations !18
  %152 = icmp eq i32 %151, %8
  br i1 %152, label %153, label %156

153:                                              ; preds = %142
  %154 = add nsw i32 %.1, 1, !spirv.Decorations !18
  %155 = getelementptr inbounds i32, ptr addrspace(4) %.11611, i64 %68
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4

156:                                              ; preds = %142
  %157 = getelementptr inbounds i32, ptr addrspace(4) %.11611, i64 %61
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4: ; preds = %156, %153, %140
  %.71626 = phi i32 [ %.11620, %140 ], [ 0, %153 ], [ %151, %156 ]
  %.71617 = phi ptr addrspace(4) [ %.11611, %140 ], [ %155, %153 ], [ %157, %156 ]
  %.7 = phi i32 [ %.1, %140 ], [ %154, %153 ], [ %.1, %156 ]
  %.sroa.0472.1 = phi <24 x i32> [ %.sroa.0472.0, %140 ], [ %.esimd25, %153 ], [ %.esimd25, %156 ]
  %158 = bitcast ptr addrspace(4) %94 to ptr addrspace(4)
  %159 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %158, i64 0, i32 0
  %160 = load <40 x i32>, ptr addrspace(4) %159, align 256
  %.esimd27 = call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %160, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd28 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %160, <7 x i32> %.esimd27, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd29 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd28, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd30 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd28, <1 x i32> %.esimd29, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  store <40 x i32> %.esimd30, ptr addrspace(4) %159, align 256
  %.esimd31 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd32 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 64, i32 40)
  %161 = lshr <16 x i32> %.esimd32, %52
  %162 = shl <16 x i32> %.esimd31, %51
  %163 = or <16 x i32> %162, %161
  %164 = bitcast <16 x i32> %163 to <32 x i16>
  %.esimd33 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %164, i32 0, i32 16, i32 2, i16 2, i32 0)
  %165 = zext <16 x i16> %.esimd33 to <16 x i32>
  %166 = mul <16 x i32> %165, splat (i32 -2082680531)
  %167 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  %168 = load <128 x i32>, ptr addrspace(4) %167, align 512
  %.esimd34 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %168, <16 x i32> %166, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %169 = lshr <16 x i32> %163, splat (i32 13)
  %170 = bitcast <16 x i32> %169 to <32 x i16>
  %.esimd35 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %170, i32 0, i32 16, i32 2, i16 0, i32 0)
  %171 = zext <16 x i16> %.esimd35 to <16 x i32>
  %172 = mul <16 x i32> %171, splat (i32 -2082680531)
  %.esimd36 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd34, <16 x i32> %172, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %173 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd36, ptr addrspace(4) %173, align 512
  %174 = lshr <16 x i32> %163, splat (i32 10)
  %175 = bitcast <16 x i32> %174 to <32 x i16>
  %.esimd37 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %175, i32 0, i32 16, i32 2, i16 0, i32 0)
  %176 = zext <16 x i16> %.esimd37 to <16 x i32>
  %177 = mul <16 x i32> %176, splat (i32 -2082680531)
  %178 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %22, i64 0, i64 1
  %179 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  %180 = load <128 x i32>, ptr addrspace(4) %179, align 512
  %.esimd38 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %180, <16 x i32> %177, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %181 = lshr <16 x i32> %163, splat (i32 7)
  %182 = bitcast <16 x i32> %181 to <32 x i16>
  %.esimd39 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %182, i32 0, i32 16, i32 2, i16 0, i32 0)
  %183 = zext <16 x i16> %.esimd39 to <16 x i32>
  %184 = mul <16 x i32> %183, splat (i32 -2082680531)
  %.esimd40 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd38, <16 x i32> %184, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %185 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd40, ptr addrspace(4) %185, align 512
  %.esimd42 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 96, i32 40)
  %186 = lshr <16 x i32> %.esimd42, %54
  %187 = shl <16 x i32> %.esimd32, %53
  %188 = or <16 x i32> %187, %186
  %189 = bitcast <16 x i32> %188 to <32 x i16>
  %.esimd43 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %189, i32 0, i32 16, i32 2, i16 2, i32 0)
  %190 = zext <16 x i16> %.esimd43 to <16 x i32>
  %191 = mul <16 x i32> %190, splat (i32 -2082680531)
  %.esimd44 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd36, <16 x i32> %191, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %192 = lshr <16 x i32> %188, splat (i32 13)
  %193 = bitcast <16 x i32> %192 to <32 x i16>
  %.esimd45 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %193, i32 0, i32 16, i32 2, i16 0, i32 0)
  %194 = zext <16 x i16> %.esimd45 to <16 x i32>
  %195 = mul <16 x i32> %194, splat (i32 -2082680531)
  %.esimd46 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd44, <16 x i32> %195, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %196 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd46, ptr addrspace(4) %196, align 512
  %197 = lshr <16 x i32> %188, splat (i32 10)
  %198 = bitcast <16 x i32> %197 to <32 x i16>
  %.esimd47 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %198, i32 0, i32 16, i32 2, i16 0, i32 0)
  %199 = zext <16 x i16> %.esimd47 to <16 x i32>
  %200 = mul <16 x i32> %199, splat (i32 -2082680531)
  %.esimd48 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd40, <16 x i32> %200, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %201 = lshr <16 x i32> %188, splat (i32 7)
  %202 = bitcast <16 x i32> %201 to <32 x i16>
  %.esimd49 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %202, i32 0, i32 16, i32 2, i16 0, i32 0)
  %203 = zext <16 x i16> %.esimd49 to <16 x i32>
  %204 = mul <16 x i32> %203, splat (i32 -2082680531)
  %.esimd50 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd48, <16 x i32> %204, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %205 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd50, ptr addrspace(4) %205, align 512
  %.esimd52 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 128, i32 40)
  %206 = lshr <16 x i32> %.esimd52, %56
  %207 = shl <16 x i32> %.esimd42, %55
  %208 = or <16 x i32> %207, %206
  %209 = bitcast <16 x i32> %208 to <32 x i16>
  %.esimd53 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %209, i32 0, i32 16, i32 2, i16 2, i32 0)
  %210 = zext <16 x i16> %.esimd53 to <16 x i32>
  %211 = mul <16 x i32> %210, splat (i32 -2082680531)
  %.esimd54 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd46, <16 x i32> %211, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %212 = lshr <16 x i32> %208, splat (i32 13)
  %213 = bitcast <16 x i32> %212 to <32 x i16>
  %.esimd55 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %213, i32 0, i32 16, i32 2, i16 0, i32 0)
  %214 = zext <16 x i16> %.esimd55 to <16 x i32>
  %215 = mul <16 x i32> %214, splat (i32 -2082680531)
  %.esimd56 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd54, <16 x i32> %215, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %216 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd56, ptr addrspace(4) %216, align 512
  %217 = lshr <16 x i32> %208, splat (i32 10)
  %218 = bitcast <16 x i32> %217 to <32 x i16>
  %.esimd57 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %218, i32 0, i32 16, i32 2, i16 0, i32 0)
  %219 = zext <16 x i16> %.esimd57 to <16 x i32>
  %220 = mul <16 x i32> %219, splat (i32 -2082680531)
  %.esimd58 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd50, <16 x i32> %220, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %221 = lshr <16 x i32> %208, splat (i32 7)
  %222 = bitcast <16 x i32> %221 to <32 x i16>
  %.esimd59 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %222, i32 0, i32 16, i32 2, i16 0, i32 0)
  %223 = zext <16 x i16> %.esimd59 to <16 x i32>
  %224 = mul <16 x i32> %223, splat (i32 -2082680531)
  %.esimd60 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd58, <16 x i32> %224, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %225 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd60, ptr addrspace(4) %225, align 512
  %.esimd61 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 8, i32 8, i32 1, i16 96, i32 40)
  %226 = lshr <16 x i32> %.esimd52, %58
  %227 = shl <16 x i32> %.esimd61, %57
  %228 = or <16 x i32> %227, %226
  %229 = bitcast <16 x i32> %228 to <32 x i16>
  %.esimd63 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %229, i32 0, i32 16, i32 2, i16 2, i32 0)
  %230 = zext <16 x i16> %.esimd63 to <16 x i32>
  %231 = mul <16 x i32> %230, splat (i32 -2082680531)
  %.esimd64 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd56, <16 x i32> %231, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %232 = lshr <16 x i32> %228, splat (i32 13)
  %233 = bitcast <16 x i32> %232 to <32 x i16>
  %.esimd65 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %233, i32 0, i32 16, i32 2, i16 0, i32 0)
  %234 = zext <16 x i16> %.esimd65 to <16 x i32>
  %235 = mul <16 x i32> %234, splat (i32 -2082680531)
  %.esimd66 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd64, <16 x i32> %235, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %236 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd66, ptr addrspace(4) %236, align 512
  %237 = lshr <16 x i32> %228, splat (i32 10)
  %238 = bitcast <16 x i32> %237 to <32 x i16>
  %.esimd67 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %238, i32 0, i32 16, i32 2, i16 0, i32 0)
  %239 = zext <16 x i16> %.esimd67 to <16 x i32>
  %240 = mul <16 x i32> %239, splat (i32 -2082680531)
  %.esimd68 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd60, <16 x i32> %240, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %241 = lshr <16 x i32> %228, splat (i32 7)
  %242 = bitcast <16 x i32> %241 to <32 x i16>
  %.esimd69 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %242, i32 0, i32 16, i32 2, i16 0, i32 0)
  %243 = zext <16 x i16> %.esimd69 to <16 x i32>
  %244 = mul <16 x i32> %243, splat (i32 -2082680531)
  %.esimd70 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd68, <16 x i32> %244, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %245 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd70, ptr addrspace(4) %245, align 512
  %246 = bitcast ptr addrspace(4) %124 to ptr addrspace(4)
  %247 = load <128 x i32>, ptr addrspace(4) %246, align 16
  %.esimd71 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01451.0, <128 x i32> %247, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %248 = getelementptr inbounds i32, ptr addrspace(4) %124, i64 128
  %249 = bitcast ptr addrspace(4) %248 to ptr addrspace(4)
  %250 = load <128 x i32>, ptr addrspace(4) %249, align 16
  %.esimd72 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd71, <128 x i32> %250, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  br label %251

251:                                              ; preds = %260, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4
  %252 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4 ], [ %261, %260 ]
  %253 = icmp ult i32 %252, 2
  br i1 %253, label %254, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit9

254:                                              ; preds = %251
  %255 = shl nuw nsw i32 %252, 7, !spirv.Decorations !20
  %256 = zext i32 %252 to i64
  br label %257

257:                                              ; preds = %262, %254
  %258 = phi i32 [ %275, %262 ], [ 0, %254 ]
  %259 = icmp ult i32 %258, 2
  br i1 %259, label %262, label %260

260:                                              ; preds = %257
  %261 = add nuw nsw i32 %252, 1, !spirv.Decorations !20
  br label %251, !llvm.loop !25

262:                                              ; preds = %257
  %263 = shl nuw nsw i32 %258, 6, !spirv.Decorations !20
  %264 = or i32 %255, %263
  %265 = trunc i32 %264 to i16
  %266 = shl nuw nsw i16 %265, 2, !spirv.Decorations !20
  %.esimd73 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd72, i32 0, i32 64, i32 1, i16 %266, i32 0)
  %267 = zext i32 %258 to i64
  %268 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %267
  %269 = bitcast ptr addrspace(4) %268 to ptr addrspace(4)
  %270 = load <128 x i32>, ptr addrspace(4) %269, align 512
  %271 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %22, i64 0, i64 %256
  %272 = bitcast ptr addrspace(4) %271 to ptr addrspace(4)
  %273 = load <128 x i32>, ptr addrspace(4) %272, align 512
  %.esimd74 = call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %270, <128 x i32> %273, <64 x i32> %.esimd73, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %274 = bitcast ptr addrspace(4) %268 to ptr addrspace(4)
  store <128 x i32> %.esimd74, ptr addrspace(4) %274, align 512
  %275 = add nuw nsw i32 %258, 1, !spirv.Decorations !20
  br label %257, !llvm.loop !26

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit9: ; preds = %251
  %276 = getelementptr inbounds i32, ptr addrspace(4) %124, i64 256
  %277 = add nsw i32 %126, 1, !spirv.Decorations !18
  %278 = icmp eq i32 %277, %8
  br i1 %278, label %282, label %279

279:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit9
  %280 = add nuw nsw i32 %127, 1, !spirv.Decorations !20
  %281 = icmp slt i32 %280, %8
  br i1 %281, label %323, label %1086

282:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit9
  %283 = add nsw i32 %42, %125, !spirv.Decorations !18
  %284 = sext i32 %44 to i64
  %285 = shl nsw i64 %284, 1, !spirv.Decorations !18
  %286 = or i64 %285, %46
  %287 = sext i32 %12 to i64
  %288 = mul i64 %286, %287
  %289 = sext i32 %283 to i64
  %290 = add i64 %288, %289
  %291 = shl i64 %290, 4
  %292 = sext i32 %13 to i64
  %293 = mul i64 %291, %292
  %294 = getelementptr inbounds i32, ptr addrspace(4) %39, i64 %293
  %295 = shl nsw i64 %71, 4, !spirv.Decorations !18
  %296 = getelementptr inbounds i32, ptr addrspace(4) %294, i64 %295
  br label %297

297:                                              ; preds = %306, %282
  %298 = phi i32 [ 0, %282 ], [ %307, %306 ]
  %299 = icmp ult i32 %298, 2
  br i1 %299, label %300, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13

300:                                              ; preds = %297
  %301 = zext i32 %298 to i64
  %302 = shl nuw nsw i32 %298, 3, !spirv.Decorations !20
  br label %303

303:                                              ; preds = %308, %300
  %304 = phi i32 [ %319, %308 ], [ 0, %300 ]
  %305 = icmp ult i32 %304, 8
  br i1 %305, label %308, label %306

306:                                              ; preds = %303
  %307 = add nuw nsw i32 %298, 1, !spirv.Decorations !20
  br label %297, !llvm.loop !27

308:                                              ; preds = %303
  %309 = trunc i32 %304 to i16
  %310 = shl nuw nsw i16 %309, 6, !spirv.Decorations !20
  %311 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %301
  %312 = bitcast ptr addrspace(4) %311 to ptr addrspace(4)
  %313 = load <128 x i32>, ptr addrspace(4) %312, align 512
  %.esimd75 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %313, i32 0, i32 16, i32 1, i16 %310, i32 0)
  %314 = or i32 %302, %304
  %315 = sext i32 %314 to i64
  %316 = mul nsw i64 %315, %292, !spirv.Decorations !18
  %317 = getelementptr inbounds i32, ptr addrspace(4) %296, i64 %316
  %318 = bitcast ptr addrspace(4) %317 to ptr addrspace(4)
  store <16 x i32> %.esimd75, ptr addrspace(4) %318, align 16
  %319 = add nuw nsw i32 %304, 1, !spirv.Decorations !20
  br label %303, !llvm.loop !28

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13: ; preds = %297
  %320 = add nsw i32 %125, 1, !spirv.Decorations !18
  %321 = add nuw nsw i32 %127, 1, !spirv.Decorations !20
  %322 = icmp slt i32 %321, %8
  br i1 %322, label %325, label %1086

323:                                              ; preds = %279
  %324 = icmp eq i32 %277, 0
  br i1 %324, label %325, label %337

325:                                              ; preds = %323, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13
  %326 = phi ptr addrspace(4) [ %276, %323 ], [ %90, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ]
  %327 = phi i32 [ %125, %323 ], [ %320, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ]
  br label %328

328:                                              ; preds = %331, %325
  %329 = phi i32 [ %336, %331 ], [ 0, %325 ]
  %330 = icmp ult i32 %329, 2
  br i1 %330, label %331, label %.loopexit3

331:                                              ; preds = %328
  %332 = zext i32 %329 to i64
  %333 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr %20, i64 0, i64 %332
  %334 = addrspacecast ptr %333 to ptr addrspace(4)
  %335 = bitcast ptr addrspace(4) %334 to ptr addrspace(4)
  store <128 x i32> zeroinitializer, ptr addrspace(4) %335, align 512
  %336 = add nuw nsw i32 %329, 1, !spirv.Decorations !20
  br label %328, !llvm.loop !29

.loopexit3:                                       ; preds = %328
  br label %337

337:                                              ; preds = %.loopexit3, %323
  %338 = phi ptr addrspace(4) [ %276, %323 ], [ %326, %.loopexit3 ]
  %339 = phi i32 [ %125, %323 ], [ %327, %.loopexit3 ]
  %340 = phi i32 [ %277, %323 ], [ 0, %.loopexit3 ]
  %341 = icmp sgt i32 %.7, 0
  br i1 %341, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3, label %342

342:                                              ; preds = %337
  %343 = bitcast ptr addrspace(4) %.71617 to ptr addrspace(4)
  %344 = load <16 x i32>, ptr addrspace(4) %343, align 16
  %.esimd76 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0466.0, <16 x i32> %344, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %345 = getelementptr inbounds i32, ptr addrspace(4) %.71617, i64 16
  %346 = bitcast ptr addrspace(4) %345 to ptr addrspace(4)
  %347 = load <8 x i32>, ptr addrspace(4) %346, align 16
  %.esimd77 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd76, <8 x i32> %347, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd78 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd30, <24 x i32> %.esimd77, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd78, ptr addrspace(4) %159, align 256
  %348 = add nsw i32 %.71626, 1, !spirv.Decorations !18
  %349 = icmp eq i32 %348, %8
  br i1 %349, label %350, label %353

350:                                              ; preds = %342
  %351 = add nsw i32 %.7, 1, !spirv.Decorations !18
  %352 = getelementptr inbounds i32, ptr addrspace(4) %.71617, i64 %68
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3

353:                                              ; preds = %342
  %354 = getelementptr inbounds i32, ptr addrspace(4) %.71617, i64 %61
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3: ; preds = %353, %350, %337
  %.61625 = phi i32 [ %.71626, %337 ], [ 0, %350 ], [ %348, %353 ]
  %.61616 = phi ptr addrspace(4) [ %.71617, %337 ], [ %352, %350 ], [ %354, %353 ]
  %.6 = phi i32 [ %.7, %337 ], [ %351, %350 ], [ %.7, %353 ]
  %.sroa.0466.2 = phi <24 x i32> [ %.sroa.0466.0, %337 ], [ %.esimd77, %350 ], [ %.esimd77, %353 ]
  %355 = bitcast ptr addrspace(4) %96 to ptr addrspace(4)
  %356 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %355, i64 0, i32 0
  %357 = load <40 x i32>, ptr addrspace(4) %356, align 256
  %.esimd79 = call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %357, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd80 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %357, <7 x i32> %.esimd79, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd81 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd80, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd82 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd80, <1 x i32> %.esimd81, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  store <40 x i32> %.esimd82, ptr addrspace(4) %356, align 256
  %.esimd83 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd84 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 64, i32 40)
  %358 = lshr <16 x i32> %.esimd84, %52
  %359 = shl <16 x i32> %.esimd83, %51
  %360 = or <16 x i32> %359, %358
  %361 = bitcast <16 x i32> %360 to <32 x i16>
  %.esimd85 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %361, i32 0, i32 16, i32 2, i16 2, i32 0)
  %362 = zext <16 x i16> %.esimd85 to <16 x i32>
  %363 = mul <16 x i32> %362, splat (i32 -2082680531)
  %.esimd86 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd66, <16 x i32> %363, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %364 = lshr <16 x i32> %360, splat (i32 13)
  %365 = bitcast <16 x i32> %364 to <32 x i16>
  %.esimd87 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %365, i32 0, i32 16, i32 2, i16 0, i32 0)
  %366 = zext <16 x i16> %.esimd87 to <16 x i32>
  %367 = mul <16 x i32> %366, splat (i32 -2082680531)
  %.esimd88 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd86, <16 x i32> %367, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %368 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd88, ptr addrspace(4) %368, align 512
  %369 = lshr <16 x i32> %360, splat (i32 10)
  %370 = bitcast <16 x i32> %369 to <32 x i16>
  %.esimd89 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %370, i32 0, i32 16, i32 2, i16 0, i32 0)
  %371 = zext <16 x i16> %.esimd89 to <16 x i32>
  %372 = mul <16 x i32> %371, splat (i32 -2082680531)
  %.esimd90 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd70, <16 x i32> %372, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %373 = lshr <16 x i32> %360, splat (i32 7)
  %374 = bitcast <16 x i32> %373 to <32 x i16>
  %.esimd91 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %374, i32 0, i32 16, i32 2, i16 0, i32 0)
  %375 = zext <16 x i16> %.esimd91 to <16 x i32>
  %376 = mul <16 x i32> %375, splat (i32 -2082680531)
  %.esimd92 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd90, <16 x i32> %376, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %377 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd92, ptr addrspace(4) %377, align 512
  %.esimd94 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 96, i32 40)
  %378 = lshr <16 x i32> %.esimd94, %54
  %379 = shl <16 x i32> %.esimd84, %53
  %380 = or <16 x i32> %379, %378
  %381 = bitcast <16 x i32> %380 to <32 x i16>
  %.esimd95 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %381, i32 0, i32 16, i32 2, i16 2, i32 0)
  %382 = zext <16 x i16> %.esimd95 to <16 x i32>
  %383 = mul <16 x i32> %382, splat (i32 -2082680531)
  %.esimd96 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd88, <16 x i32> %383, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %384 = lshr <16 x i32> %380, splat (i32 13)
  %385 = bitcast <16 x i32> %384 to <32 x i16>
  %.esimd97 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %385, i32 0, i32 16, i32 2, i16 0, i32 0)
  %386 = zext <16 x i16> %.esimd97 to <16 x i32>
  %387 = mul <16 x i32> %386, splat (i32 -2082680531)
  %.esimd98 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd96, <16 x i32> %387, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %388 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd98, ptr addrspace(4) %388, align 512
  %389 = lshr <16 x i32> %380, splat (i32 10)
  %390 = bitcast <16 x i32> %389 to <32 x i16>
  %.esimd99 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %390, i32 0, i32 16, i32 2, i16 0, i32 0)
  %391 = zext <16 x i16> %.esimd99 to <16 x i32>
  %392 = mul <16 x i32> %391, splat (i32 -2082680531)
  %.esimd100 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd92, <16 x i32> %392, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %393 = lshr <16 x i32> %380, splat (i32 7)
  %394 = bitcast <16 x i32> %393 to <32 x i16>
  %.esimd101 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %394, i32 0, i32 16, i32 2, i16 0, i32 0)
  %395 = zext <16 x i16> %.esimd101 to <16 x i32>
  %396 = mul <16 x i32> %395, splat (i32 -2082680531)
  %.esimd102 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd100, <16 x i32> %396, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %397 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd102, ptr addrspace(4) %397, align 512
  %.esimd104 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 128, i32 40)
  %398 = lshr <16 x i32> %.esimd104, %56
  %399 = shl <16 x i32> %.esimd94, %55
  %400 = or <16 x i32> %399, %398
  %401 = bitcast <16 x i32> %400 to <32 x i16>
  %.esimd105 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %401, i32 0, i32 16, i32 2, i16 2, i32 0)
  %402 = zext <16 x i16> %.esimd105 to <16 x i32>
  %403 = mul <16 x i32> %402, splat (i32 -2082680531)
  %.esimd106 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd98, <16 x i32> %403, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %404 = lshr <16 x i32> %400, splat (i32 13)
  %405 = bitcast <16 x i32> %404 to <32 x i16>
  %.esimd107 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %405, i32 0, i32 16, i32 2, i16 0, i32 0)
  %406 = zext <16 x i16> %.esimd107 to <16 x i32>
  %407 = mul <16 x i32> %406, splat (i32 -2082680531)
  %.esimd108 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd106, <16 x i32> %407, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %408 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd108, ptr addrspace(4) %408, align 512
  %409 = lshr <16 x i32> %400, splat (i32 10)
  %410 = bitcast <16 x i32> %409 to <32 x i16>
  %.esimd109 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %410, i32 0, i32 16, i32 2, i16 0, i32 0)
  %411 = zext <16 x i16> %.esimd109 to <16 x i32>
  %412 = mul <16 x i32> %411, splat (i32 -2082680531)
  %.esimd110 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd102, <16 x i32> %412, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %413 = lshr <16 x i32> %400, splat (i32 7)
  %414 = bitcast <16 x i32> %413 to <32 x i16>
  %.esimd111 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %414, i32 0, i32 16, i32 2, i16 0, i32 0)
  %415 = zext <16 x i16> %.esimd111 to <16 x i32>
  %416 = mul <16 x i32> %415, splat (i32 -2082680531)
  %.esimd112 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd110, <16 x i32> %416, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %417 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd112, ptr addrspace(4) %417, align 512
  %.esimd113 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 8, i32 8, i32 1, i16 96, i32 40)
  %418 = lshr <16 x i32> %.esimd104, %58
  %419 = shl <16 x i32> %.esimd113, %57
  %420 = or <16 x i32> %419, %418
  %421 = bitcast <16 x i32> %420 to <32 x i16>
  %.esimd115 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %421, i32 0, i32 16, i32 2, i16 2, i32 0)
  %422 = zext <16 x i16> %.esimd115 to <16 x i32>
  %423 = mul <16 x i32> %422, splat (i32 -2082680531)
  %.esimd116 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd108, <16 x i32> %423, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %424 = lshr <16 x i32> %420, splat (i32 13)
  %425 = bitcast <16 x i32> %424 to <32 x i16>
  %.esimd117 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %425, i32 0, i32 16, i32 2, i16 0, i32 0)
  %426 = zext <16 x i16> %.esimd117 to <16 x i32>
  %427 = mul <16 x i32> %426, splat (i32 -2082680531)
  %.esimd118 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd116, <16 x i32> %427, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %428 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd118, ptr addrspace(4) %428, align 512
  %429 = lshr <16 x i32> %420, splat (i32 10)
  %430 = bitcast <16 x i32> %429 to <32 x i16>
  %.esimd119 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %430, i32 0, i32 16, i32 2, i16 0, i32 0)
  %431 = zext <16 x i16> %.esimd119 to <16 x i32>
  %432 = mul <16 x i32> %431, splat (i32 -2082680531)
  %.esimd120 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd112, <16 x i32> %432, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %433 = lshr <16 x i32> %420, splat (i32 7)
  %434 = bitcast <16 x i32> %433 to <32 x i16>
  %.esimd121 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %434, i32 0, i32 16, i32 2, i16 0, i32 0)
  %435 = zext <16 x i16> %.esimd121 to <16 x i32>
  %436 = mul <16 x i32> %435, splat (i32 -2082680531)
  %.esimd122 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd120, <16 x i32> %436, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %437 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd122, ptr addrspace(4) %437, align 512
  %438 = bitcast ptr addrspace(4) %338 to ptr addrspace(4)
  %439 = load <128 x i32>, ptr addrspace(4) %438, align 16
  %.esimd123 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01439.0, <128 x i32> %439, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %440 = getelementptr inbounds i32, ptr addrspace(4) %338, i64 128
  %441 = bitcast ptr addrspace(4) %440 to ptr addrspace(4)
  %442 = load <128 x i32>, ptr addrspace(4) %441, align 16
  %.esimd124 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd123, <128 x i32> %442, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  br label %443

443:                                              ; preds = %452, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3
  %444 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3 ], [ %453, %452 ]
  %445 = icmp ult i32 %444, 2
  br i1 %445, label %446, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit8

446:                                              ; preds = %443
  %447 = shl nuw nsw i32 %444, 7, !spirv.Decorations !20
  %448 = zext i32 %444 to i64
  br label %449

449:                                              ; preds = %454, %446
  %450 = phi i32 [ %467, %454 ], [ 0, %446 ]
  %451 = icmp ult i32 %450, 2
  br i1 %451, label %454, label %452

452:                                              ; preds = %449
  %453 = add nuw nsw i32 %444, 1, !spirv.Decorations !20
  br label %443, !llvm.loop !30

454:                                              ; preds = %449
  %455 = shl nuw nsw i32 %450, 6, !spirv.Decorations !20
  %456 = or i32 %447, %455
  %457 = trunc i32 %456 to i16
  %458 = shl nuw nsw i16 %457, 2, !spirv.Decorations !20
  %.esimd125 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd124, i32 0, i32 64, i32 1, i16 %458, i32 0)
  %459 = zext i32 %450 to i64
  %460 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %459
  %461 = bitcast ptr addrspace(4) %460 to ptr addrspace(4)
  %462 = load <128 x i32>, ptr addrspace(4) %461, align 512
  %463 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %22, i64 0, i64 %448
  %464 = bitcast ptr addrspace(4) %463 to ptr addrspace(4)
  %465 = load <128 x i32>, ptr addrspace(4) %464, align 512
  %.esimd126 = call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %462, <128 x i32> %465, <64 x i32> %.esimd125, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %466 = bitcast ptr addrspace(4) %460 to ptr addrspace(4)
  store <128 x i32> %.esimd126, ptr addrspace(4) %466, align 512
  %467 = add nuw nsw i32 %450, 1, !spirv.Decorations !20
  br label %449, !llvm.loop !31

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit8: ; preds = %443
  %468 = getelementptr inbounds i32, ptr addrspace(4) %338, i64 256
  %469 = add nsw i32 %340, 1, !spirv.Decorations !18
  %470 = icmp eq i32 %469, %8
  br i1 %470, label %474, label %471

471:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit8
  %472 = add nuw nsw i32 %127, 2, !spirv.Decorations !20
  %473 = icmp slt i32 %472, %8
  br i1 %473, label %515, label %1086

474:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit8
  %475 = add nsw i32 %42, %339, !spirv.Decorations !18
  %476 = sext i32 %44 to i64
  %477 = shl nsw i64 %476, 1, !spirv.Decorations !18
  %478 = or i64 %477, %46
  %479 = sext i32 %12 to i64
  %480 = mul i64 %478, %479
  %481 = sext i32 %475 to i64
  %482 = add i64 %480, %481
  %483 = shl i64 %482, 4
  %484 = sext i32 %13 to i64
  %485 = mul i64 %483, %484
  %486 = getelementptr inbounds i32, ptr addrspace(4) %39, i64 %485
  %487 = shl nsw i64 %71, 4, !spirv.Decorations !18
  %488 = getelementptr inbounds i32, ptr addrspace(4) %486, i64 %487
  br label %489

489:                                              ; preds = %498, %474
  %490 = phi i32 [ 0, %474 ], [ %499, %498 ]
  %491 = icmp ult i32 %490, 2
  br i1 %491, label %492, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12

492:                                              ; preds = %489
  %493 = zext i32 %490 to i64
  %494 = shl nuw nsw i32 %490, 3, !spirv.Decorations !20
  br label %495

495:                                              ; preds = %500, %492
  %496 = phi i32 [ %511, %500 ], [ 0, %492 ]
  %497 = icmp ult i32 %496, 8
  br i1 %497, label %500, label %498

498:                                              ; preds = %495
  %499 = add nuw nsw i32 %490, 1, !spirv.Decorations !20
  br label %489, !llvm.loop !32

500:                                              ; preds = %495
  %501 = trunc i32 %496 to i16
  %502 = shl nuw nsw i16 %501, 6, !spirv.Decorations !20
  %503 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %493
  %504 = bitcast ptr addrspace(4) %503 to ptr addrspace(4)
  %505 = load <128 x i32>, ptr addrspace(4) %504, align 512
  %.esimd127 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %505, i32 0, i32 16, i32 1, i16 %502, i32 0)
  %506 = or i32 %494, %496
  %507 = sext i32 %506 to i64
  %508 = mul nsw i64 %507, %484, !spirv.Decorations !18
  %509 = getelementptr inbounds i32, ptr addrspace(4) %488, i64 %508
  %510 = bitcast ptr addrspace(4) %509 to ptr addrspace(4)
  store <16 x i32> %.esimd127, ptr addrspace(4) %510, align 16
  %511 = add nuw nsw i32 %496, 1, !spirv.Decorations !20
  br label %495, !llvm.loop !33

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12: ; preds = %489
  %512 = add nsw i32 %339, 1, !spirv.Decorations !18
  %513 = add nuw nsw i32 %127, 2, !spirv.Decorations !20
  %514 = icmp slt i32 %513, %8
  br i1 %514, label %517, label %1086

515:                                              ; preds = %471
  %516 = icmp eq i32 %469, 0
  br i1 %516, label %517, label %529

517:                                              ; preds = %515, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12
  %518 = phi ptr addrspace(4) [ %468, %515 ], [ %90, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ]
  %519 = phi i32 [ %339, %515 ], [ %512, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ]
  br label %520

520:                                              ; preds = %523, %517
  %521 = phi i32 [ %528, %523 ], [ 0, %517 ]
  %522 = icmp ult i32 %521, 2
  br i1 %522, label %523, label %.loopexit2

523:                                              ; preds = %520
  %524 = zext i32 %521 to i64
  %525 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr %20, i64 0, i64 %524
  %526 = addrspacecast ptr %525 to ptr addrspace(4)
  %527 = bitcast ptr addrspace(4) %526 to ptr addrspace(4)
  store <128 x i32> zeroinitializer, ptr addrspace(4) %527, align 512
  %528 = add nuw nsw i32 %521, 1, !spirv.Decorations !20
  br label %520, !llvm.loop !34

.loopexit2:                                       ; preds = %520
  br label %529

529:                                              ; preds = %.loopexit2, %515
  %530 = phi ptr addrspace(4) [ %468, %515 ], [ %518, %.loopexit2 ]
  %531 = phi i32 [ %339, %515 ], [ %519, %.loopexit2 ]
  %532 = phi i32 [ %469, %515 ], [ 0, %.loopexit2 ]
  %533 = icmp sgt i32 %.6, 0
  br i1 %533, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2, label %534

534:                                              ; preds = %529
  %535 = bitcast ptr addrspace(4) %.61616 to ptr addrspace(4)
  %536 = load <16 x i32>, ptr addrspace(4) %535, align 16
  %.esimd128 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0460.0, <16 x i32> %536, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %537 = getelementptr inbounds i32, ptr addrspace(4) %.61616, i64 16
  %538 = bitcast ptr addrspace(4) %537 to ptr addrspace(4)
  %539 = load <8 x i32>, ptr addrspace(4) %538, align 16
  %.esimd129 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd128, <8 x i32> %539, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd130 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd82, <24 x i32> %.esimd129, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd130, ptr addrspace(4) %356, align 256
  %540 = add nsw i32 %.61625, 1, !spirv.Decorations !18
  %541 = icmp eq i32 %540, %8
  br i1 %541, label %542, label %545

542:                                              ; preds = %534
  %543 = add nsw i32 %.6, 1, !spirv.Decorations !18
  %544 = getelementptr inbounds i32, ptr addrspace(4) %.61616, i64 %68
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2

545:                                              ; preds = %534
  %546 = getelementptr inbounds i32, ptr addrspace(4) %.61616, i64 %61
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2: ; preds = %545, %542, %529
  %.51624 = phi i32 [ %.61625, %529 ], [ 0, %542 ], [ %540, %545 ]
  %.51615 = phi ptr addrspace(4) [ %.61616, %529 ], [ %544, %542 ], [ %546, %545 ]
  %.5 = phi i32 [ %.6, %529 ], [ %543, %542 ], [ %.6, %545 ]
  %.sroa.0460.2 = phi <24 x i32> [ %.sroa.0460.0, %529 ], [ %.esimd129, %542 ], [ %.esimd129, %545 ]
  %547 = bitcast ptr addrspace(4) %98 to ptr addrspace(4)
  %548 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %547, i64 0, i32 0
  %549 = load <40 x i32>, ptr addrspace(4) %548, align 256
  %.esimd131 = call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %549, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd132 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %549, <7 x i32> %.esimd131, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd133 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd132, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd134 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd132, <1 x i32> %.esimd133, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  store <40 x i32> %.esimd134, ptr addrspace(4) %548, align 256
  %.esimd135 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd136 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 64, i32 40)
  %550 = lshr <16 x i32> %.esimd136, %52
  %551 = shl <16 x i32> %.esimd135, %51
  %552 = or <16 x i32> %551, %550
  %553 = bitcast <16 x i32> %552 to <32 x i16>
  %.esimd137 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %553, i32 0, i32 16, i32 2, i16 2, i32 0)
  %554 = zext <16 x i16> %.esimd137 to <16 x i32>
  %555 = mul <16 x i32> %554, splat (i32 -2082680531)
  %.esimd138 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd118, <16 x i32> %555, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %556 = lshr <16 x i32> %552, splat (i32 13)
  %557 = bitcast <16 x i32> %556 to <32 x i16>
  %.esimd139 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %557, i32 0, i32 16, i32 2, i16 0, i32 0)
  %558 = zext <16 x i16> %.esimd139 to <16 x i32>
  %559 = mul <16 x i32> %558, splat (i32 -2082680531)
  %.esimd140 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd138, <16 x i32> %559, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %560 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd140, ptr addrspace(4) %560, align 512
  %561 = lshr <16 x i32> %552, splat (i32 10)
  %562 = bitcast <16 x i32> %561 to <32 x i16>
  %.esimd141 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %562, i32 0, i32 16, i32 2, i16 0, i32 0)
  %563 = zext <16 x i16> %.esimd141 to <16 x i32>
  %564 = mul <16 x i32> %563, splat (i32 -2082680531)
  %.esimd142 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd122, <16 x i32> %564, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %565 = lshr <16 x i32> %552, splat (i32 7)
  %566 = bitcast <16 x i32> %565 to <32 x i16>
  %.esimd143 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %566, i32 0, i32 16, i32 2, i16 0, i32 0)
  %567 = zext <16 x i16> %.esimd143 to <16 x i32>
  %568 = mul <16 x i32> %567, splat (i32 -2082680531)
  %.esimd144 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd142, <16 x i32> %568, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %569 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd144, ptr addrspace(4) %569, align 512
  %.esimd146 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 96, i32 40)
  %570 = lshr <16 x i32> %.esimd146, %54
  %571 = shl <16 x i32> %.esimd136, %53
  %572 = or <16 x i32> %571, %570
  %573 = bitcast <16 x i32> %572 to <32 x i16>
  %.esimd147 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %573, i32 0, i32 16, i32 2, i16 2, i32 0)
  %574 = zext <16 x i16> %.esimd147 to <16 x i32>
  %575 = mul <16 x i32> %574, splat (i32 -2082680531)
  %.esimd148 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd140, <16 x i32> %575, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %576 = lshr <16 x i32> %572, splat (i32 13)
  %577 = bitcast <16 x i32> %576 to <32 x i16>
  %.esimd149 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %577, i32 0, i32 16, i32 2, i16 0, i32 0)
  %578 = zext <16 x i16> %.esimd149 to <16 x i32>
  %579 = mul <16 x i32> %578, splat (i32 -2082680531)
  %.esimd150 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd148, <16 x i32> %579, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %580 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd150, ptr addrspace(4) %580, align 512
  %581 = lshr <16 x i32> %572, splat (i32 10)
  %582 = bitcast <16 x i32> %581 to <32 x i16>
  %.esimd151 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %582, i32 0, i32 16, i32 2, i16 0, i32 0)
  %583 = zext <16 x i16> %.esimd151 to <16 x i32>
  %584 = mul <16 x i32> %583, splat (i32 -2082680531)
  %.esimd152 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd144, <16 x i32> %584, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %585 = lshr <16 x i32> %572, splat (i32 7)
  %586 = bitcast <16 x i32> %585 to <32 x i16>
  %.esimd153 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %586, i32 0, i32 16, i32 2, i16 0, i32 0)
  %587 = zext <16 x i16> %.esimd153 to <16 x i32>
  %588 = mul <16 x i32> %587, splat (i32 -2082680531)
  %.esimd154 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd152, <16 x i32> %588, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %589 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd154, ptr addrspace(4) %589, align 512
  %.esimd156 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 128, i32 40)
  %590 = lshr <16 x i32> %.esimd156, %56
  %591 = shl <16 x i32> %.esimd146, %55
  %592 = or <16 x i32> %591, %590
  %593 = bitcast <16 x i32> %592 to <32 x i16>
  %.esimd157 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %593, i32 0, i32 16, i32 2, i16 2, i32 0)
  %594 = zext <16 x i16> %.esimd157 to <16 x i32>
  %595 = mul <16 x i32> %594, splat (i32 -2082680531)
  %.esimd158 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd150, <16 x i32> %595, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %596 = lshr <16 x i32> %592, splat (i32 13)
  %597 = bitcast <16 x i32> %596 to <32 x i16>
  %.esimd159 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %597, i32 0, i32 16, i32 2, i16 0, i32 0)
  %598 = zext <16 x i16> %.esimd159 to <16 x i32>
  %599 = mul <16 x i32> %598, splat (i32 -2082680531)
  %.esimd160 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd158, <16 x i32> %599, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %600 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd160, ptr addrspace(4) %600, align 512
  %601 = lshr <16 x i32> %592, splat (i32 10)
  %602 = bitcast <16 x i32> %601 to <32 x i16>
  %.esimd161 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %602, i32 0, i32 16, i32 2, i16 0, i32 0)
  %603 = zext <16 x i16> %.esimd161 to <16 x i32>
  %604 = mul <16 x i32> %603, splat (i32 -2082680531)
  %.esimd162 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd154, <16 x i32> %604, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %605 = lshr <16 x i32> %592, splat (i32 7)
  %606 = bitcast <16 x i32> %605 to <32 x i16>
  %.esimd163 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %606, i32 0, i32 16, i32 2, i16 0, i32 0)
  %607 = zext <16 x i16> %.esimd163 to <16 x i32>
  %608 = mul <16 x i32> %607, splat (i32 -2082680531)
  %.esimd164 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd162, <16 x i32> %608, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %609 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd164, ptr addrspace(4) %609, align 512
  %.esimd165 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 8, i32 8, i32 1, i16 96, i32 40)
  %610 = lshr <16 x i32> %.esimd156, %58
  %611 = shl <16 x i32> %.esimd165, %57
  %612 = or <16 x i32> %611, %610
  %613 = bitcast <16 x i32> %612 to <32 x i16>
  %.esimd167 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %613, i32 0, i32 16, i32 2, i16 2, i32 0)
  %614 = zext <16 x i16> %.esimd167 to <16 x i32>
  %615 = mul <16 x i32> %614, splat (i32 -2082680531)
  %.esimd168 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd160, <16 x i32> %615, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %616 = lshr <16 x i32> %612, splat (i32 13)
  %617 = bitcast <16 x i32> %616 to <32 x i16>
  %.esimd169 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %617, i32 0, i32 16, i32 2, i16 0, i32 0)
  %618 = zext <16 x i16> %.esimd169 to <16 x i32>
  %619 = mul <16 x i32> %618, splat (i32 -2082680531)
  %.esimd170 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd168, <16 x i32> %619, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %620 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd170, ptr addrspace(4) %620, align 512
  %621 = lshr <16 x i32> %612, splat (i32 10)
  %622 = bitcast <16 x i32> %621 to <32 x i16>
  %.esimd171 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %622, i32 0, i32 16, i32 2, i16 0, i32 0)
  %623 = zext <16 x i16> %.esimd171 to <16 x i32>
  %624 = mul <16 x i32> %623, splat (i32 -2082680531)
  %.esimd172 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd164, <16 x i32> %624, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %625 = lshr <16 x i32> %612, splat (i32 7)
  %626 = bitcast <16 x i32> %625 to <32 x i16>
  %.esimd173 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %626, i32 0, i32 16, i32 2, i16 0, i32 0)
  %627 = zext <16 x i16> %.esimd173 to <16 x i32>
  %628 = mul <16 x i32> %627, splat (i32 -2082680531)
  %.esimd174 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd172, <16 x i32> %628, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %629 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd174, ptr addrspace(4) %629, align 512
  %630 = bitcast ptr addrspace(4) %530 to ptr addrspace(4)
  %631 = load <128 x i32>, ptr addrspace(4) %630, align 16
  %.esimd175 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01427.0, <128 x i32> %631, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %632 = getelementptr inbounds i32, ptr addrspace(4) %530, i64 128
  %633 = bitcast ptr addrspace(4) %632 to ptr addrspace(4)
  %634 = load <128 x i32>, ptr addrspace(4) %633, align 16
  %.esimd176 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd175, <128 x i32> %634, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  br label %635

635:                                              ; preds = %644, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2
  %636 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2 ], [ %645, %644 ]
  %637 = icmp ult i32 %636, 2
  br i1 %637, label %638, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit7

638:                                              ; preds = %635
  %639 = shl nuw nsw i32 %636, 7, !spirv.Decorations !20
  %640 = zext i32 %636 to i64
  br label %641

641:                                              ; preds = %646, %638
  %642 = phi i32 [ %659, %646 ], [ 0, %638 ]
  %643 = icmp ult i32 %642, 2
  br i1 %643, label %646, label %644

644:                                              ; preds = %641
  %645 = add nuw nsw i32 %636, 1, !spirv.Decorations !20
  br label %635, !llvm.loop !35

646:                                              ; preds = %641
  %647 = shl nuw nsw i32 %642, 6, !spirv.Decorations !20
  %648 = or i32 %639, %647
  %649 = trunc i32 %648 to i16
  %650 = shl nuw nsw i16 %649, 2, !spirv.Decorations !20
  %.esimd177 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd176, i32 0, i32 64, i32 1, i16 %650, i32 0)
  %651 = zext i32 %642 to i64
  %652 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %651
  %653 = bitcast ptr addrspace(4) %652 to ptr addrspace(4)
  %654 = load <128 x i32>, ptr addrspace(4) %653, align 512
  %655 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %22, i64 0, i64 %640
  %656 = bitcast ptr addrspace(4) %655 to ptr addrspace(4)
  %657 = load <128 x i32>, ptr addrspace(4) %656, align 512
  %.esimd178 = call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %654, <128 x i32> %657, <64 x i32> %.esimd177, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %658 = bitcast ptr addrspace(4) %652 to ptr addrspace(4)
  store <128 x i32> %.esimd178, ptr addrspace(4) %658, align 512
  %659 = add nuw nsw i32 %642, 1, !spirv.Decorations !20
  br label %641, !llvm.loop !36

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit7: ; preds = %635
  %660 = getelementptr inbounds i32, ptr addrspace(4) %530, i64 256
  %661 = add nsw i32 %532, 1, !spirv.Decorations !18
  %662 = icmp eq i32 %661, %8
  br i1 %662, label %666, label %663

663:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit7
  %664 = add nuw nsw i32 %127, 3, !spirv.Decorations !20
  %665 = icmp slt i32 %664, %8
  br i1 %665, label %707, label %1086

666:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit7
  %667 = add nsw i32 %42, %531, !spirv.Decorations !18
  %668 = sext i32 %44 to i64
  %669 = shl nsw i64 %668, 1, !spirv.Decorations !18
  %670 = or i64 %669, %46
  %671 = sext i32 %12 to i64
  %672 = mul i64 %670, %671
  %673 = sext i32 %667 to i64
  %674 = add i64 %672, %673
  %675 = shl i64 %674, 4
  %676 = sext i32 %13 to i64
  %677 = mul i64 %675, %676
  %678 = getelementptr inbounds i32, ptr addrspace(4) %39, i64 %677
  %679 = shl nsw i64 %71, 4, !spirv.Decorations !18
  %680 = getelementptr inbounds i32, ptr addrspace(4) %678, i64 %679
  br label %681

681:                                              ; preds = %690, %666
  %682 = phi i32 [ 0, %666 ], [ %691, %690 ]
  %683 = icmp ult i32 %682, 2
  br i1 %683, label %684, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11

684:                                              ; preds = %681
  %685 = zext i32 %682 to i64
  %686 = shl nuw nsw i32 %682, 3, !spirv.Decorations !20
  br label %687

687:                                              ; preds = %692, %684
  %688 = phi i32 [ %703, %692 ], [ 0, %684 ]
  %689 = icmp ult i32 %688, 8
  br i1 %689, label %692, label %690

690:                                              ; preds = %687
  %691 = add nuw nsw i32 %682, 1, !spirv.Decorations !20
  br label %681, !llvm.loop !37

692:                                              ; preds = %687
  %693 = trunc i32 %688 to i16
  %694 = shl nuw nsw i16 %693, 6, !spirv.Decorations !20
  %695 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %685
  %696 = bitcast ptr addrspace(4) %695 to ptr addrspace(4)
  %697 = load <128 x i32>, ptr addrspace(4) %696, align 512
  %.esimd179 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %697, i32 0, i32 16, i32 1, i16 %694, i32 0)
  %698 = or i32 %686, %688
  %699 = sext i32 %698 to i64
  %700 = mul nsw i64 %699, %676, !spirv.Decorations !18
  %701 = getelementptr inbounds i32, ptr addrspace(4) %680, i64 %700
  %702 = bitcast ptr addrspace(4) %701 to ptr addrspace(4)
  store <16 x i32> %.esimd179, ptr addrspace(4) %702, align 16
  %703 = add nuw nsw i32 %688, 1, !spirv.Decorations !20
  br label %687, !llvm.loop !38

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11: ; preds = %681
  %704 = add nsw i32 %531, 1, !spirv.Decorations !18
  %705 = add nuw nsw i32 %127, 3, !spirv.Decorations !20
  %706 = icmp slt i32 %705, %8
  br i1 %706, label %709, label %1086

707:                                              ; preds = %663
  %708 = icmp eq i32 %661, 0
  br i1 %708, label %709, label %721

709:                                              ; preds = %707, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11
  %710 = phi ptr addrspace(4) [ %660, %707 ], [ %90, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ]
  %711 = phi i32 [ %531, %707 ], [ %704, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ]
  br label %712

712:                                              ; preds = %715, %709
  %713 = phi i32 [ %720, %715 ], [ 0, %709 ]
  %714 = icmp ult i32 %713, 2
  br i1 %714, label %715, label %.loopexit1

715:                                              ; preds = %712
  %716 = zext i32 %713 to i64
  %717 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr %20, i64 0, i64 %716
  %718 = addrspacecast ptr %717 to ptr addrspace(4)
  %719 = bitcast ptr addrspace(4) %718 to ptr addrspace(4)
  store <128 x i32> zeroinitializer, ptr addrspace(4) %719, align 512
  %720 = add nuw nsw i32 %713, 1, !spirv.Decorations !20
  br label %712, !llvm.loop !39

.loopexit1:                                       ; preds = %712
  br label %721

721:                                              ; preds = %.loopexit1, %707
  %722 = phi ptr addrspace(4) [ %660, %707 ], [ %710, %.loopexit1 ]
  %723 = phi i32 [ %531, %707 ], [ %711, %.loopexit1 ]
  %724 = phi i32 [ %661, %707 ], [ 0, %.loopexit1 ]
  %725 = icmp sgt i32 %.5, 0
  br i1 %725, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1, label %726

726:                                              ; preds = %721
  %727 = bitcast ptr addrspace(4) %.51615 to ptr addrspace(4)
  %728 = load <16 x i32>, ptr addrspace(4) %727, align 16
  %.esimd180 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0454.0, <16 x i32> %728, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %729 = getelementptr inbounds i32, ptr addrspace(4) %.51615, i64 16
  %730 = bitcast ptr addrspace(4) %729 to ptr addrspace(4)
  %731 = load <8 x i32>, ptr addrspace(4) %730, align 16
  %.esimd181 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd180, <8 x i32> %731, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd182 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd134, <24 x i32> %.esimd181, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd182, ptr addrspace(4) %548, align 256
  %732 = add nsw i32 %.51624, 1, !spirv.Decorations !18
  %733 = icmp eq i32 %732, %8
  br i1 %733, label %734, label %737

734:                                              ; preds = %726
  %735 = add nsw i32 %.5, 1, !spirv.Decorations !18
  %736 = getelementptr inbounds i32, ptr addrspace(4) %.51615, i64 %68
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1

737:                                              ; preds = %726
  %738 = getelementptr inbounds i32, ptr addrspace(4) %.51615, i64 %61
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1: ; preds = %737, %734, %721
  %.41623 = phi i32 [ %.51624, %721 ], [ 0, %734 ], [ %732, %737 ]
  %.41614 = phi ptr addrspace(4) [ %.51615, %721 ], [ %736, %734 ], [ %738, %737 ]
  %.4 = phi i32 [ %.5, %721 ], [ %735, %734 ], [ %.5, %737 ]
  %.sroa.0454.2 = phi <24 x i32> [ %.sroa.0454.0, %721 ], [ %.esimd181, %734 ], [ %.esimd181, %737 ]
  %739 = bitcast ptr addrspace(4) %100 to ptr addrspace(4)
  %740 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %739, i64 0, i32 0
  %741 = load <40 x i32>, ptr addrspace(4) %740, align 256
  %.esimd183 = call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %741, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd184 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %741, <7 x i32> %.esimd183, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd185 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd184, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd186 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd184, <1 x i32> %.esimd185, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  store <40 x i32> %.esimd186, ptr addrspace(4) %740, align 256
  %.esimd187 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd188 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 64, i32 40)
  %742 = lshr <16 x i32> %.esimd188, %52
  %743 = shl <16 x i32> %.esimd187, %51
  %744 = or <16 x i32> %743, %742
  %745 = bitcast <16 x i32> %744 to <32 x i16>
  %.esimd189 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %745, i32 0, i32 16, i32 2, i16 2, i32 0)
  %746 = zext <16 x i16> %.esimd189 to <16 x i32>
  %747 = mul <16 x i32> %746, splat (i32 -2082680531)
  %.esimd190 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd170, <16 x i32> %747, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %748 = lshr <16 x i32> %744, splat (i32 13)
  %749 = bitcast <16 x i32> %748 to <32 x i16>
  %.esimd191 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %749, i32 0, i32 16, i32 2, i16 0, i32 0)
  %750 = zext <16 x i16> %.esimd191 to <16 x i32>
  %751 = mul <16 x i32> %750, splat (i32 -2082680531)
  %.esimd192 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd190, <16 x i32> %751, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %752 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd192, ptr addrspace(4) %752, align 512
  %753 = lshr <16 x i32> %744, splat (i32 10)
  %754 = bitcast <16 x i32> %753 to <32 x i16>
  %.esimd193 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %754, i32 0, i32 16, i32 2, i16 0, i32 0)
  %755 = zext <16 x i16> %.esimd193 to <16 x i32>
  %756 = mul <16 x i32> %755, splat (i32 -2082680531)
  %.esimd194 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd174, <16 x i32> %756, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %757 = lshr <16 x i32> %744, splat (i32 7)
  %758 = bitcast <16 x i32> %757 to <32 x i16>
  %.esimd195 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %758, i32 0, i32 16, i32 2, i16 0, i32 0)
  %759 = zext <16 x i16> %.esimd195 to <16 x i32>
  %760 = mul <16 x i32> %759, splat (i32 -2082680531)
  %.esimd196 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd194, <16 x i32> %760, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %761 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd196, ptr addrspace(4) %761, align 512
  %.esimd198 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 96, i32 40)
  %762 = lshr <16 x i32> %.esimd198, %54
  %763 = shl <16 x i32> %.esimd188, %53
  %764 = or <16 x i32> %763, %762
  %765 = bitcast <16 x i32> %764 to <32 x i16>
  %.esimd199 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %765, i32 0, i32 16, i32 2, i16 2, i32 0)
  %766 = zext <16 x i16> %.esimd199 to <16 x i32>
  %767 = mul <16 x i32> %766, splat (i32 -2082680531)
  %.esimd200 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd192, <16 x i32> %767, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %768 = lshr <16 x i32> %764, splat (i32 13)
  %769 = bitcast <16 x i32> %768 to <32 x i16>
  %.esimd201 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %769, i32 0, i32 16, i32 2, i16 0, i32 0)
  %770 = zext <16 x i16> %.esimd201 to <16 x i32>
  %771 = mul <16 x i32> %770, splat (i32 -2082680531)
  %.esimd202 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd200, <16 x i32> %771, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %772 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd202, ptr addrspace(4) %772, align 512
  %773 = lshr <16 x i32> %764, splat (i32 10)
  %774 = bitcast <16 x i32> %773 to <32 x i16>
  %.esimd203 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %774, i32 0, i32 16, i32 2, i16 0, i32 0)
  %775 = zext <16 x i16> %.esimd203 to <16 x i32>
  %776 = mul <16 x i32> %775, splat (i32 -2082680531)
  %.esimd204 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd196, <16 x i32> %776, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %777 = lshr <16 x i32> %764, splat (i32 7)
  %778 = bitcast <16 x i32> %777 to <32 x i16>
  %.esimd205 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %778, i32 0, i32 16, i32 2, i16 0, i32 0)
  %779 = zext <16 x i16> %.esimd205 to <16 x i32>
  %780 = mul <16 x i32> %779, splat (i32 -2082680531)
  %.esimd206 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd204, <16 x i32> %780, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %781 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd206, ptr addrspace(4) %781, align 512
  %.esimd208 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 128, i32 40)
  %782 = lshr <16 x i32> %.esimd208, %56
  %783 = shl <16 x i32> %.esimd198, %55
  %784 = or <16 x i32> %783, %782
  %785 = bitcast <16 x i32> %784 to <32 x i16>
  %.esimd209 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %785, i32 0, i32 16, i32 2, i16 2, i32 0)
  %786 = zext <16 x i16> %.esimd209 to <16 x i32>
  %787 = mul <16 x i32> %786, splat (i32 -2082680531)
  %.esimd210 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd202, <16 x i32> %787, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %788 = lshr <16 x i32> %784, splat (i32 13)
  %789 = bitcast <16 x i32> %788 to <32 x i16>
  %.esimd211 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %789, i32 0, i32 16, i32 2, i16 0, i32 0)
  %790 = zext <16 x i16> %.esimd211 to <16 x i32>
  %791 = mul <16 x i32> %790, splat (i32 -2082680531)
  %.esimd212 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd210, <16 x i32> %791, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %792 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd212, ptr addrspace(4) %792, align 512
  %793 = lshr <16 x i32> %784, splat (i32 10)
  %794 = bitcast <16 x i32> %793 to <32 x i16>
  %.esimd213 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %794, i32 0, i32 16, i32 2, i16 0, i32 0)
  %795 = zext <16 x i16> %.esimd213 to <16 x i32>
  %796 = mul <16 x i32> %795, splat (i32 -2082680531)
  %.esimd214 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd206, <16 x i32> %796, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %797 = lshr <16 x i32> %784, splat (i32 7)
  %798 = bitcast <16 x i32> %797 to <32 x i16>
  %.esimd215 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %798, i32 0, i32 16, i32 2, i16 0, i32 0)
  %799 = zext <16 x i16> %.esimd215 to <16 x i32>
  %800 = mul <16 x i32> %799, splat (i32 -2082680531)
  %.esimd216 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd214, <16 x i32> %800, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %801 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd216, ptr addrspace(4) %801, align 512
  %.esimd217 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 8, i32 8, i32 1, i16 96, i32 40)
  %802 = lshr <16 x i32> %.esimd208, %58
  %803 = shl <16 x i32> %.esimd217, %57
  %804 = or <16 x i32> %803, %802
  %805 = bitcast <16 x i32> %804 to <32 x i16>
  %.esimd219 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %805, i32 0, i32 16, i32 2, i16 2, i32 0)
  %806 = zext <16 x i16> %.esimd219 to <16 x i32>
  %807 = mul <16 x i32> %806, splat (i32 -2082680531)
  %.esimd220 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd212, <16 x i32> %807, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %808 = lshr <16 x i32> %804, splat (i32 13)
  %809 = bitcast <16 x i32> %808 to <32 x i16>
  %.esimd221 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %809, i32 0, i32 16, i32 2, i16 0, i32 0)
  %810 = zext <16 x i16> %.esimd221 to <16 x i32>
  %811 = mul <16 x i32> %810, splat (i32 -2082680531)
  %.esimd222 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd220, <16 x i32> %811, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %812 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd222, ptr addrspace(4) %812, align 512
  %813 = lshr <16 x i32> %804, splat (i32 10)
  %814 = bitcast <16 x i32> %813 to <32 x i16>
  %.esimd223 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %814, i32 0, i32 16, i32 2, i16 0, i32 0)
  %815 = zext <16 x i16> %.esimd223 to <16 x i32>
  %816 = mul <16 x i32> %815, splat (i32 -2082680531)
  %.esimd224 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd216, <16 x i32> %816, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %817 = lshr <16 x i32> %804, splat (i32 7)
  %818 = bitcast <16 x i32> %817 to <32 x i16>
  %.esimd225 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %818, i32 0, i32 16, i32 2, i16 0, i32 0)
  %819 = zext <16 x i16> %.esimd225 to <16 x i32>
  %820 = mul <16 x i32> %819, splat (i32 -2082680531)
  %.esimd226 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd224, <16 x i32> %820, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %821 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd226, ptr addrspace(4) %821, align 512
  %822 = bitcast ptr addrspace(4) %722 to ptr addrspace(4)
  %823 = load <128 x i32>, ptr addrspace(4) %822, align 16
  %.esimd227 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01415.0, <128 x i32> %823, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %824 = getelementptr inbounds i32, ptr addrspace(4) %722, i64 128
  %825 = bitcast ptr addrspace(4) %824 to ptr addrspace(4)
  %826 = load <128 x i32>, ptr addrspace(4) %825, align 16
  %.esimd228 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd227, <128 x i32> %826, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  br label %827

827:                                              ; preds = %836, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1
  %828 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1 ], [ %837, %836 ]
  %829 = icmp ult i32 %828, 2
  br i1 %829, label %830, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit6

830:                                              ; preds = %827
  %831 = shl nuw nsw i32 %828, 7, !spirv.Decorations !20
  %832 = zext i32 %828 to i64
  br label %833

833:                                              ; preds = %838, %830
  %834 = phi i32 [ %851, %838 ], [ 0, %830 ]
  %835 = icmp ult i32 %834, 2
  br i1 %835, label %838, label %836

836:                                              ; preds = %833
  %837 = add nuw nsw i32 %828, 1, !spirv.Decorations !20
  br label %827, !llvm.loop !40

838:                                              ; preds = %833
  %839 = shl nuw nsw i32 %834, 6, !spirv.Decorations !20
  %840 = or i32 %831, %839
  %841 = trunc i32 %840 to i16
  %842 = shl nuw nsw i16 %841, 2, !spirv.Decorations !20
  %.esimd229 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd228, i32 0, i32 64, i32 1, i16 %842, i32 0)
  %843 = zext i32 %834 to i64
  %844 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %843
  %845 = bitcast ptr addrspace(4) %844 to ptr addrspace(4)
  %846 = load <128 x i32>, ptr addrspace(4) %845, align 512
  %847 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %22, i64 0, i64 %832
  %848 = bitcast ptr addrspace(4) %847 to ptr addrspace(4)
  %849 = load <128 x i32>, ptr addrspace(4) %848, align 512
  %.esimd230 = call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %846, <128 x i32> %849, <64 x i32> %.esimd229, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %850 = bitcast ptr addrspace(4) %844 to ptr addrspace(4)
  store <128 x i32> %.esimd230, ptr addrspace(4) %850, align 512
  %851 = add nuw nsw i32 %834, 1, !spirv.Decorations !20
  br label %833, !llvm.loop !41

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit6: ; preds = %827
  %852 = getelementptr inbounds i32, ptr addrspace(4) %722, i64 256
  %853 = add nsw i32 %724, 1, !spirv.Decorations !18
  %854 = icmp eq i32 %853, %8
  br i1 %854, label %858, label %855

855:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit6
  %856 = add nuw nsw i32 %127, 4, !spirv.Decorations !20
  %857 = icmp slt i32 %856, %8
  br i1 %857, label %899, label %1086

858:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit6
  %859 = add nsw i32 %42, %723, !spirv.Decorations !18
  %860 = sext i32 %44 to i64
  %861 = shl nsw i64 %860, 1, !spirv.Decorations !18
  %862 = or i64 %861, %46
  %863 = sext i32 %12 to i64
  %864 = mul i64 %862, %863
  %865 = sext i32 %859 to i64
  %866 = add i64 %864, %865
  %867 = shl i64 %866, 4
  %868 = sext i32 %13 to i64
  %869 = mul i64 %867, %868
  %870 = getelementptr inbounds i32, ptr addrspace(4) %39, i64 %869
  %871 = shl nsw i64 %71, 4, !spirv.Decorations !18
  %872 = getelementptr inbounds i32, ptr addrspace(4) %870, i64 %871
  br label %873

873:                                              ; preds = %882, %858
  %874 = phi i32 [ 0, %858 ], [ %883, %882 ]
  %875 = icmp ult i32 %874, 2
  br i1 %875, label %876, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10

876:                                              ; preds = %873
  %877 = zext i32 %874 to i64
  %878 = shl nuw nsw i32 %874, 3, !spirv.Decorations !20
  br label %879

879:                                              ; preds = %884, %876
  %880 = phi i32 [ %895, %884 ], [ 0, %876 ]
  %881 = icmp ult i32 %880, 8
  br i1 %881, label %884, label %882

882:                                              ; preds = %879
  %883 = add nuw nsw i32 %874, 1, !spirv.Decorations !20
  br label %873, !llvm.loop !42

884:                                              ; preds = %879
  %885 = trunc i32 %880 to i16
  %886 = shl nuw nsw i16 %885, 6, !spirv.Decorations !20
  %887 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %877
  %888 = bitcast ptr addrspace(4) %887 to ptr addrspace(4)
  %889 = load <128 x i32>, ptr addrspace(4) %888, align 512
  %.esimd231 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %889, i32 0, i32 16, i32 1, i16 %886, i32 0)
  %890 = or i32 %878, %880
  %891 = sext i32 %890 to i64
  %892 = mul nsw i64 %891, %868, !spirv.Decorations !18
  %893 = getelementptr inbounds i32, ptr addrspace(4) %872, i64 %892
  %894 = bitcast ptr addrspace(4) %893 to ptr addrspace(4)
  store <16 x i32> %.esimd231, ptr addrspace(4) %894, align 16
  %895 = add nuw nsw i32 %880, 1, !spirv.Decorations !20
  br label %879, !llvm.loop !43

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10: ; preds = %873
  %896 = add nsw i32 %723, 1, !spirv.Decorations !18
  %897 = add nuw nsw i32 %127, 4, !spirv.Decorations !20
  %898 = icmp slt i32 %897, %8
  br i1 %898, label %901, label %1086

899:                                              ; preds = %855
  %900 = icmp eq i32 %853, 0
  br i1 %900, label %901, label %913

901:                                              ; preds = %899, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10
  %902 = phi ptr addrspace(4) [ %852, %899 ], [ %90, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ]
  %903 = phi i32 [ %723, %899 ], [ %896, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ]
  br label %904

904:                                              ; preds = %907, %901
  %905 = phi i32 [ %912, %907 ], [ 0, %901 ]
  %906 = icmp ult i32 %905, 2
  br i1 %906, label %907, label %.loopexit

907:                                              ; preds = %904
  %908 = zext i32 %905 to i64
  %909 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr %20, i64 0, i64 %908
  %910 = addrspacecast ptr %909 to ptr addrspace(4)
  %911 = bitcast ptr addrspace(4) %910 to ptr addrspace(4)
  store <128 x i32> zeroinitializer, ptr addrspace(4) %911, align 512
  %912 = add nuw nsw i32 %905, 1, !spirv.Decorations !20
  br label %904, !llvm.loop !44

.loopexit:                                        ; preds = %904
  br label %913

913:                                              ; preds = %.loopexit, %899
  %914 = phi ptr addrspace(4) [ %852, %899 ], [ %902, %.loopexit ]
  %915 = phi i32 [ %723, %899 ], [ %903, %.loopexit ]
  %916 = phi i32 [ %853, %899 ], [ 0, %.loopexit ]
  %917 = icmp sgt i32 %.4, 0
  br i1 %917, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit, label %918

918:                                              ; preds = %913
  %919 = bitcast ptr addrspace(4) %.41614 to ptr addrspace(4)
  %920 = load <16 x i32>, ptr addrspace(4) %919, align 16
  %.esimd232 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0449.0, <16 x i32> %920, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %921 = getelementptr inbounds i32, ptr addrspace(4) %.41614, i64 16
  %922 = bitcast ptr addrspace(4) %921 to ptr addrspace(4)
  %923 = load <8 x i32>, ptr addrspace(4) %922, align 16
  %.esimd233 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd232, <8 x i32> %923, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd234 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd186, <24 x i32> %.esimd233, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd234, ptr addrspace(4) %740, align 256
  %924 = add nsw i32 %.41623, 1, !spirv.Decorations !18
  %925 = icmp eq i32 %924, %8
  br i1 %925, label %926, label %929

926:                                              ; preds = %918
  %927 = add nsw i32 %.4, 1, !spirv.Decorations !18
  %928 = getelementptr inbounds i32, ptr addrspace(4) %.41614, i64 %68
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit

929:                                              ; preds = %918
  %930 = getelementptr inbounds i32, ptr addrspace(4) %.41614, i64 %61
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit: ; preds = %929, %926, %913
  %.31622 = phi i32 [ %.41623, %913 ], [ 0, %926 ], [ %924, %929 ]
  %.31613 = phi ptr addrspace(4) [ %.41614, %913 ], [ %928, %926 ], [ %930, %929 ]
  %.3 = phi i32 [ %.4, %913 ], [ %927, %926 ], [ %.4, %929 ]
  %.sroa.0449.2 = phi <24 x i32> [ %.sroa.0449.0, %913 ], [ %.esimd233, %926 ], [ %.esimd233, %929 ]
  %931 = bitcast ptr addrspace(4) %92 to ptr addrspace(4)
  %932 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %931, i64 0, i32 0
  %933 = load <40 x i32>, ptr addrspace(4) %932, align 256
  %.esimd235 = call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %933, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd236 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %933, <7 x i32> %.esimd235, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd237 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd236, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd238 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd236, <1 x i32> %.esimd237, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  store <40 x i32> %.esimd238, ptr addrspace(4) %932, align 256
  %.esimd239 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd240 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 64, i32 40)
  %934 = lshr <16 x i32> %.esimd240, %52
  %935 = shl <16 x i32> %.esimd239, %51
  %936 = or <16 x i32> %935, %934
  %937 = bitcast <16 x i32> %936 to <32 x i16>
  %.esimd241 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %937, i32 0, i32 16, i32 2, i16 2, i32 0)
  %938 = zext <16 x i16> %.esimd241 to <16 x i32>
  %939 = mul <16 x i32> %938, splat (i32 -2082680531)
  %.esimd242 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd222, <16 x i32> %939, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %940 = lshr <16 x i32> %936, splat (i32 13)
  %941 = bitcast <16 x i32> %940 to <32 x i16>
  %.esimd243 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %941, i32 0, i32 16, i32 2, i16 0, i32 0)
  %942 = zext <16 x i16> %.esimd243 to <16 x i32>
  %943 = mul <16 x i32> %942, splat (i32 -2082680531)
  %.esimd244 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd242, <16 x i32> %943, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %944 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd244, ptr addrspace(4) %944, align 512
  %945 = lshr <16 x i32> %936, splat (i32 10)
  %946 = bitcast <16 x i32> %945 to <32 x i16>
  %.esimd245 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %946, i32 0, i32 16, i32 2, i16 0, i32 0)
  %947 = zext <16 x i16> %.esimd245 to <16 x i32>
  %948 = mul <16 x i32> %947, splat (i32 -2082680531)
  %.esimd246 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd226, <16 x i32> %948, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %949 = lshr <16 x i32> %936, splat (i32 7)
  %950 = bitcast <16 x i32> %949 to <32 x i16>
  %.esimd247 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %950, i32 0, i32 16, i32 2, i16 0, i32 0)
  %951 = zext <16 x i16> %.esimd247 to <16 x i32>
  %952 = mul <16 x i32> %951, splat (i32 -2082680531)
  %.esimd248 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd246, <16 x i32> %952, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %953 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd248, ptr addrspace(4) %953, align 512
  %.esimd250 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 96, i32 40)
  %954 = lshr <16 x i32> %.esimd250, %54
  %955 = shl <16 x i32> %.esimd240, %53
  %956 = or <16 x i32> %955, %954
  %957 = bitcast <16 x i32> %956 to <32 x i16>
  %.esimd251 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %957, i32 0, i32 16, i32 2, i16 2, i32 0)
  %958 = zext <16 x i16> %.esimd251 to <16 x i32>
  %959 = mul <16 x i32> %958, splat (i32 -2082680531)
  %.esimd252 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd244, <16 x i32> %959, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %960 = lshr <16 x i32> %956, splat (i32 13)
  %961 = bitcast <16 x i32> %960 to <32 x i16>
  %.esimd253 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %961, i32 0, i32 16, i32 2, i16 0, i32 0)
  %962 = zext <16 x i16> %.esimd253 to <16 x i32>
  %963 = mul <16 x i32> %962, splat (i32 -2082680531)
  %.esimd254 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd252, <16 x i32> %963, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %964 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd254, ptr addrspace(4) %964, align 512
  %965 = lshr <16 x i32> %956, splat (i32 10)
  %966 = bitcast <16 x i32> %965 to <32 x i16>
  %.esimd255 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %966, i32 0, i32 16, i32 2, i16 0, i32 0)
  %967 = zext <16 x i16> %.esimd255 to <16 x i32>
  %968 = mul <16 x i32> %967, splat (i32 -2082680531)
  %.esimd256 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd248, <16 x i32> %968, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %969 = lshr <16 x i32> %956, splat (i32 7)
  %970 = bitcast <16 x i32> %969 to <32 x i16>
  %.esimd257 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %970, i32 0, i32 16, i32 2, i16 0, i32 0)
  %971 = zext <16 x i16> %.esimd257 to <16 x i32>
  %972 = mul <16 x i32> %971, splat (i32 -2082680531)
  %.esimd258 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd256, <16 x i32> %972, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %973 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd258, ptr addrspace(4) %973, align 512
  %.esimd260 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 128, i32 40)
  %974 = lshr <16 x i32> %.esimd260, %56
  %975 = shl <16 x i32> %.esimd250, %55
  %976 = or <16 x i32> %975, %974
  %977 = bitcast <16 x i32> %976 to <32 x i16>
  %.esimd261 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %977, i32 0, i32 16, i32 2, i16 2, i32 0)
  %978 = zext <16 x i16> %.esimd261 to <16 x i32>
  %979 = mul <16 x i32> %978, splat (i32 -2082680531)
  %.esimd262 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd254, <16 x i32> %979, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %980 = lshr <16 x i32> %976, splat (i32 13)
  %981 = bitcast <16 x i32> %980 to <32 x i16>
  %.esimd263 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %981, i32 0, i32 16, i32 2, i16 0, i32 0)
  %982 = zext <16 x i16> %.esimd263 to <16 x i32>
  %983 = mul <16 x i32> %982, splat (i32 -2082680531)
  %.esimd264 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd262, <16 x i32> %983, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %984 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd264, ptr addrspace(4) %984, align 512
  %985 = lshr <16 x i32> %976, splat (i32 10)
  %986 = bitcast <16 x i32> %985 to <32 x i16>
  %.esimd265 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %986, i32 0, i32 16, i32 2, i16 0, i32 0)
  %987 = zext <16 x i16> %.esimd265 to <16 x i32>
  %988 = mul <16 x i32> %987, splat (i32 -2082680531)
  %.esimd266 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd258, <16 x i32> %988, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %989 = lshr <16 x i32> %976, splat (i32 7)
  %990 = bitcast <16 x i32> %989 to <32 x i16>
  %.esimd267 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %990, i32 0, i32 16, i32 2, i16 0, i32 0)
  %991 = zext <16 x i16> %.esimd267 to <16 x i32>
  %992 = mul <16 x i32> %991, splat (i32 -2082680531)
  %.esimd268 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd266, <16 x i32> %992, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %993 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd268, ptr addrspace(4) %993, align 512
  %.esimd269 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 8, i32 8, i32 1, i16 96, i32 40)
  %994 = lshr <16 x i32> %.esimd260, %58
  %995 = shl <16 x i32> %.esimd269, %57
  %996 = or <16 x i32> %995, %994
  %997 = bitcast <16 x i32> %996 to <32 x i16>
  %.esimd271 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %997, i32 0, i32 16, i32 2, i16 2, i32 0)
  %998 = zext <16 x i16> %.esimd271 to <16 x i32>
  %999 = mul <16 x i32> %998, splat (i32 -2082680531)
  %.esimd272 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd264, <16 x i32> %999, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %1000 = lshr <16 x i32> %996, splat (i32 13)
  %1001 = bitcast <16 x i32> %1000 to <32 x i16>
  %.esimd273 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %1001, i32 0, i32 16, i32 2, i16 0, i32 0)
  %1002 = zext <16 x i16> %.esimd273 to <16 x i32>
  %1003 = mul <16 x i32> %1002, splat (i32 -2082680531)
  %.esimd274 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd272, <16 x i32> %1003, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %1004 = bitcast ptr addrspace(4) %22 to ptr addrspace(4)
  store <128 x i32> %.esimd274, ptr addrspace(4) %1004, align 512
  %1005 = lshr <16 x i32> %996, splat (i32 10)
  %1006 = bitcast <16 x i32> %1005 to <32 x i16>
  %.esimd275 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %1006, i32 0, i32 16, i32 2, i16 0, i32 0)
  %1007 = zext <16 x i16> %.esimd275 to <16 x i32>
  %1008 = mul <16 x i32> %1007, splat (i32 -2082680531)
  %.esimd276 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd268, <16 x i32> %1008, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %1009 = lshr <16 x i32> %996, splat (i32 7)
  %1010 = bitcast <16 x i32> %1009 to <32 x i16>
  %.esimd277 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %1010, i32 0, i32 16, i32 2, i16 0, i32 0)
  %1011 = zext <16 x i16> %.esimd277 to <16 x i32>
  %1012 = mul <16 x i32> %1011, splat (i32 -2082680531)
  %.esimd278 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd276, <16 x i32> %1012, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %1013 = bitcast ptr addrspace(4) %178 to ptr addrspace(4)
  store <128 x i32> %.esimd278, ptr addrspace(4) %1013, align 512
  %1014 = bitcast ptr addrspace(4) %914 to ptr addrspace(4)
  %1015 = load <128 x i32>, ptr addrspace(4) %1014, align 16
  %.esimd279 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01403.0, <128 x i32> %1015, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %1016 = getelementptr inbounds i32, ptr addrspace(4) %914, i64 128
  %1017 = bitcast ptr addrspace(4) %1016 to ptr addrspace(4)
  %1018 = load <128 x i32>, ptr addrspace(4) %1017, align 16
  %.esimd280 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd279, <128 x i32> %1018, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  br label %1019

1019:                                             ; preds = %1028, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit
  %1020 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %1029, %1028 ]
  %1021 = icmp ult i32 %1020, 2
  br i1 %1021, label %1022, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit

1022:                                             ; preds = %1019
  %1023 = shl nuw nsw i32 %1020, 7, !spirv.Decorations !20
  %1024 = zext i32 %1020 to i64
  br label %1025

1025:                                             ; preds = %1030, %1022
  %1026 = phi i32 [ %1043, %1030 ], [ 0, %1022 ]
  %1027 = icmp ult i32 %1026, 2
  br i1 %1027, label %1030, label %1028

1028:                                             ; preds = %1025
  %1029 = add nuw nsw i32 %1020, 1, !spirv.Decorations !20
  br label %1019, !llvm.loop !45

1030:                                             ; preds = %1025
  %1031 = shl nuw nsw i32 %1026, 6, !spirv.Decorations !20
  %1032 = or i32 %1023, %1031
  %1033 = trunc i32 %1032 to i16
  %1034 = shl nuw nsw i16 %1033, 2, !spirv.Decorations !20
  %.esimd281 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd280, i32 0, i32 64, i32 1, i16 %1034, i32 0)
  %1035 = zext i32 %1026 to i64
  %1036 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %1035
  %1037 = bitcast ptr addrspace(4) %1036 to ptr addrspace(4)
  %1038 = load <128 x i32>, ptr addrspace(4) %1037, align 512
  %1039 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %22, i64 0, i64 %1024
  %1040 = bitcast ptr addrspace(4) %1039 to ptr addrspace(4)
  %1041 = load <128 x i32>, ptr addrspace(4) %1040, align 512
  %.esimd282 = call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %1038, <128 x i32> %1041, <64 x i32> %.esimd281, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %1042 = bitcast ptr addrspace(4) %1036 to ptr addrspace(4)
  store <128 x i32> %.esimd282, ptr addrspace(4) %1042, align 512
  %1043 = add nuw nsw i32 %1026, 1, !spirv.Decorations !20
  br label %1025, !llvm.loop !46

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit: ; preds = %1019
  %1044 = getelementptr inbounds i32, ptr addrspace(4) %914, i64 256
  %1045 = add nsw i32 %916, 1, !spirv.Decorations !18
  %1046 = icmp eq i32 %1045, %8
  br i1 %1046, label %1047, label %1086

1047:                                             ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit
  %1048 = add nsw i32 %42, %915, !spirv.Decorations !18
  %1049 = sext i32 %44 to i64
  %1050 = shl nsw i64 %1049, 1, !spirv.Decorations !18
  %1051 = or i64 %1050, %46
  %1052 = sext i32 %12 to i64
  %1053 = mul i64 %1051, %1052
  %1054 = sext i32 %1048 to i64
  %1055 = add i64 %1053, %1054
  %1056 = shl i64 %1055, 4
  %1057 = sext i32 %13 to i64
  %1058 = mul i64 %1056, %1057
  %1059 = getelementptr inbounds i32, ptr addrspace(4) %39, i64 %1058
  %1060 = shl nsw i64 %71, 4, !spirv.Decorations !18
  %1061 = getelementptr inbounds i32, ptr addrspace(4) %1059, i64 %1060
  br label %1062

1062:                                             ; preds = %1071, %1047
  %1063 = phi i32 [ 0, %1047 ], [ %1072, %1071 ]
  %1064 = icmp ult i32 %1063, 2
  br i1 %1064, label %1065, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit

1065:                                             ; preds = %1062
  %1066 = zext i32 %1063 to i64
  %1067 = shl nuw nsw i32 %1063, 3, !spirv.Decorations !20
  br label %1068

1068:                                             ; preds = %1073, %1065
  %1069 = phi i32 [ %1084, %1073 ], [ 0, %1065 ]
  %1070 = icmp ult i32 %1069, 8
  br i1 %1070, label %1073, label %1071

1071:                                             ; preds = %1068
  %1072 = add nuw nsw i32 %1063, 1, !spirv.Decorations !20
  br label %1062, !llvm.loop !47

1073:                                             ; preds = %1068
  %1074 = trunc i32 %1069 to i16
  %1075 = shl nuw nsw i16 %1074, 6, !spirv.Decorations !20
  %1076 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %1066
  %1077 = bitcast ptr addrspace(4) %1076 to ptr addrspace(4)
  %1078 = load <128 x i32>, ptr addrspace(4) %1077, align 512
  %.esimd283 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %1078, i32 0, i32 16, i32 1, i16 %1075, i32 0)
  %1079 = or i32 %1067, %1069
  %1080 = sext i32 %1079 to i64
  %1081 = mul nsw i64 %1080, %1057, !spirv.Decorations !18
  %1082 = getelementptr inbounds i32, ptr addrspace(4) %1061, i64 %1081
  %1083 = bitcast ptr addrspace(4) %1082 to ptr addrspace(4)
  store <16 x i32> %.esimd283, ptr addrspace(4) %1083, align 16
  %1084 = add nuw nsw i32 %1069, 1, !spirv.Decorations !20
  br label %1068, !llvm.loop !48

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit: ; preds = %1062
  %1085 = add nsw i32 %915, 1, !spirv.Decorations !18
  br label %1086

1086:                                             ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10, %855, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11, %663, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12, %471, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13, %279
  %.21621 = phi i32 [ %.31622, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.31622, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.41623, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.41623, %855 ], [ %.51624, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.51624, %663 ], [ %.61625, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.61625, %471 ], [ %.71626, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.71626, %279 ]
  %.21612 = phi ptr addrspace(4) [ %.31613, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.31613, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.41614, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.41614, %855 ], [ %.51615, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.51615, %663 ], [ %.61616, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.61616, %471 ], [ %.71617, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.71617, %279 ]
  %.2 = phi i32 [ %.3, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.3, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.4, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.4, %855 ], [ %.5, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.5, %663 ], [ %.6, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.6, %471 ], [ %.7, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.7, %279 ]
  %.sroa.0449.1 = phi <24 x i32> [ %.sroa.0449.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0449.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.sroa.0449.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0449.0, %855 ], [ %.sroa.0449.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0449.0, %663 ], [ %.sroa.0449.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0449.0, %471 ], [ %.sroa.0449.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0449.0, %279 ]
  %.sroa.0454.1 = phi <24 x i32> [ %.sroa.0454.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0454.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.sroa.0454.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0454.2, %855 ], [ %.sroa.0454.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0454.0, %663 ], [ %.sroa.0454.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0454.0, %471 ], [ %.sroa.0454.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0454.0, %279 ]
  %.sroa.0460.1 = phi <24 x i32> [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0460.2, %855 ], [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0460.2, %663 ], [ %.sroa.0460.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0460.0, %471 ], [ %.sroa.0460.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0460.0, %279 ]
  %.sroa.0466.1 = phi <24 x i32> [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0466.2, %855 ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0466.2, %663 ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0466.2, %471 ], [ %.sroa.0466.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0466.0, %279 ]
  %.sroa.01403.1 = phi <256 x i32> [ %.esimd280, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd280, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.sroa.01403.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.01403.0, %855 ], [ %.sroa.01403.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.01403.0, %663 ], [ %.sroa.01403.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.01403.0, %471 ], [ %.sroa.01403.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01403.0, %279 ]
  %.sroa.01415.1 = phi <256 x i32> [ %.esimd228, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd228, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.esimd228, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd228, %855 ], [ %.sroa.01415.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.01415.0, %663 ], [ %.sroa.01415.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.01415.0, %471 ], [ %.sroa.01415.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01415.0, %279 ]
  %.sroa.01427.1 = phi <256 x i32> [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd176, %855 ], [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd176, %663 ], [ %.sroa.01427.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.01427.0, %471 ], [ %.sroa.01427.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01427.0, %279 ]
  %.sroa.01439.1 = phi <256 x i32> [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd124, %855 ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd124, %663 ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd124, %471 ], [ %.sroa.01439.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01439.0, %279 ]
  %1087 = phi ptr addrspace(4) [ %90, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %1044, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %90, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %852, %855 ], [ %90, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %660, %663 ], [ %90, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %468, %471 ], [ %90, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %276, %279 ]
  %1088 = phi i32 [ %1085, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %915, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %896, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %723, %855 ], [ %704, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %531, %663 ], [ %512, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %339, %471 ], [ %320, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %125, %279 ]
  %1089 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %1045, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %853, %855 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %661, %663 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %469, %471 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %277, %279 ]
  %1090 = add nuw nsw i32 %127, 5, !spirv.Decorations !20
  br label %123

1091:                                             ; preds = %123
  %1092 = bitcast ptr %20 to ptr
  call void @llvm.lifetime.end.p0(ptr %20)
  %1093 = bitcast ptr %19 to ptr
  call void @llvm.lifetime.end.p0(ptr %19)
  %1094 = bitcast ptr %18 to ptr
  call void @llvm.lifetime.end.p0(ptr %18)
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.start.p0(ptr captures(none)) #2

; Function Attrs: nocallback nofree nounwind willreturn memory(argmem: readwrite)
declare void @llvm.memcpy.p0.p0.i64(ptr noalias writeonly captures(none), ptr noalias readonly captures(none), i64, i1 immarg) #3

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(argmem: readwrite)
declare void @llvm.lifetime.end.p0(ptr captures(none)) #2

; Function Attrs: nounwind willreturn memory(none)
declare spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32) #0

attributes #0 = { nounwind willreturn memory(none) }
attributes #1 = { nounwind "CMGenxMain" "oclrt"="1" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }

!spirv.MemoryModel = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!spirv.Source = !{!1}
!opencl.spir.version = !{!2}
!opencl.used.extensions = !{!3}
!opencl.used.optional.core.features = !{!3}
!spirv.Generator = !{!4}
!genx.kernels = !{!5}

!0 = !{i32 2, i32 2}
!1 = !{i32 0, i32 100000}
!2 = !{i32 1, i32 2}
!3 = !{}
!4 = !{i16 6, i16 14}
!5 = !{ptr @_ZTSZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_EUlNS4_7nd_itemILi1EEEE_, !"_ZTSZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_EUlNS4_7nd_itemILi1EEEE_", !6, i32 0, i32 0, !6, !7, i32 0}
!6 = !{i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0, i32 0}
!7 = !{!"", !"", !"svmptr_t", !"svmptr_t", !"svmptr_t", !"svmptr_t", !"", !"", !"", !"", !"", !"", !"", !"", !"svmptr_t", !"", !""}
!8 = !{!9, !9, !11, !11, !11, !11, !9, !9, !9, !9, !9, !9, !9, !9, !11, !9, !9}
!9 = !{!10}
!10 = !{i32 5625, i32 0}
!11 = !{!12, !10}
!12 = !{i32 44, i32 4}
!13 = !{i32 1}
!14 = !{!15}
!15 = !{i32 44, i32 256}
!16 = !{!17}
!17 = !{i32 44, i32 512}
!18 = !{!19}
!19 = !{i32 4469}
!20 = !{!19, !21}
!21 = !{i32 4470}
!22 = distinct !{!22, !23}
!23 = !{!"llvm.loop.unroll.enable"}
!24 = distinct !{!24, !23}
!25 = distinct !{!25, !23}
!26 = distinct !{!26, !23}
!27 = distinct !{!27, !23}
!28 = distinct !{!28, !23}
!29 = distinct !{!29, !23}
!30 = distinct !{!30, !23}
!31 = distinct !{!31, !23}
!32 = distinct !{!32, !23}
!33 = distinct !{!33, !23}
!34 = distinct !{!34, !23}
!35 = distinct !{!35, !23}
!36 = distinct !{!36, !23}
!37 = distinct !{!37, !23}
!38 = distinct !{!38, !23}
!39 = distinct !{!39, !23}
!40 = distinct !{!40, !23}
!41 = distinct !{!41, !23}
!42 = distinct !{!42, !23}
!43 = distinct !{!43, !23}
!44 = distinct !{!44, !23}
!45 = distinct !{!45, !23}
!46 = distinct !{!46, !23}
!47 = distinct !{!47, !23}
!48 = distinct !{!48, !23}

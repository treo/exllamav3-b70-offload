; ------------------------------------------------
; VC_asm9cea78f553115c9f_after_spirv_reader.ll
; ------------------------------------------------
; ModuleID = 'Deserialized LLVM Module'
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-G1"
target triple = "spir64-unknown-unknown"

%"class.sycl::_V1::ext::intel::esimd::simd.213.1" = type { %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0" }
%"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0" = type { <40 x i32> }
%"class.sycl::_V1::ext::intel::esimd::simd.5.3" = type { %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.6.2" }
%"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.6.2" = type { <128 x i32> }

; Unknown intrinsic
declare <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32>, <8 x i32>, i32, i32, i32, i16, i32, <8 x i1>) #0

; Unknown intrinsic
declare <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32>, <16 x i32>, i32, i32, i32, i16, i32, <16 x i1>) #0

; Unknown intrinsic
declare <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32>, <8 x i32>, i32, i32, i32, i16, i32, <8 x i1>) #0

; Unknown intrinsic
declare <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32>, <24 x i32>, i32, i32, i32, i16, i32, <24 x i1>) #0

; Unknown intrinsic
declare <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32>, i32, i32, i32, i16, i32) #0

; Unknown intrinsic
declare <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32>, <7 x i32>, i32, i32, i32, i16, i32, <7 x i1>) #0

; Unknown intrinsic
declare <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32>, i32, i32, i32, i16, i32) #0

; Unknown intrinsic
declare <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32>, <1 x i32>, i32, i32, i32, i16, i32, <1 x i1>) #0

; Unknown intrinsic
declare <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32>, i32, i32, i32, i16, i32) #0

; Unknown intrinsic
declare <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16>, i32, i32, i32, i16, i32) #0

; Unknown intrinsic
declare <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32>, <16 x i32>, i32, i32, i32, i16, i32, <16 x i1>) #0

; Unknown intrinsic
declare <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32>, <128 x i32>, i32, i32, i32, i16, i32, <128 x i1>) #0

; Unknown intrinsic
declare <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32>, i32, i32, i32, i16, i32) #0

; Unknown intrinsic
declare <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32>, <128 x i32>, <64 x i32>, i32, i32, i32, i32, i32, i32) #0

; Unknown intrinsic
declare <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32>, i32, i32, i32, i16, i32) #0

; Function Attrs: nounwind
define spir_kernel void @_ZTSZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_EUlNS4_7nd_itemILi1EEEE_(i32 "VCArgumentIOKind"="0" %0, i32 "VCArgumentIOKind"="0" %1, ptr addrspace(1) align 4 "VCArgumentIOKind"="0" %2, ptr addrspace(1) align 4 "VCArgumentIOKind"="0" %3, ptr addrspace(1) align 4 "VCArgumentIOKind"="0" %4, ptr addrspace(1) align 4 "VCArgumentIOKind"="0" %5, i32 "VCArgumentIOKind"="0" %6, i32 "VCArgumentIOKind"="0" %7, i32 "VCArgumentIOKind"="0" %8, i32 "VCArgumentIOKind"="0" %9, i32 "VCArgumentIOKind"="0" %10, i32 "VCArgumentIOKind"="0" %11, i32 "VCArgumentIOKind"="0" %12, i32 "VCArgumentIOKind"="0" %13, ptr addrspace(1) align 4 "VCArgumentIOKind"="0" %14, i32 "VCArgumentIOKind"="0" %15, i32 "VCArgumentIOKind"="0" %16) #1 !spirv.ParameterDecorations !5 !intel_reqd_sub_group_size !10 {
  %18 = alloca [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], align 256, !spirv.Decorations !11
  %19 = alloca [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], align 512, !spirv.Decorations !13
  %20 = alloca [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], align 512, !spirv.Decorations !13
  %21 = alloca [1024 x i8], align 512, !spirv.Decorations !13
  store [1024 x i8] zeroinitializer, ptr %21, align 1
  %22 = addrspacecast ptr addrspace(1) %14 to ptr addrspace(4)
  %23 = addrspacecast ptr %19 to ptr addrspace(4)
  %24 = addrspacecast ptr %20 to ptr addrspace(4)
  %25 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 0) #4
  %26 = insertelement <3 x i64> poison, i64 %25, i32 0
  %27 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 1) #4
  %28 = insertelement <3 x i64> %26, i64 %27, i32 1
  %29 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 2) #4
  %30 = insertelement <3 x i64> %28, i64 %29, i32 2
  %31 = extractelement <3 x i64> %30, i32 0
  %32 = select i1 true, i64 %31, i64 0
  %33 = trunc i64 %32 to i32
  %34 = lshr i32 %33, 1
  %35 = sdiv i32 %34, %0
  %36 = mul i32 %35, %0
  %37 = sub i32 %34, %36
  %38 = icmp slt i32 %37, %1
  %.v = select i1 %38, ptr addrspace(1) %2, ptr addrspace(1) %3
  %39 = addrspacecast ptr addrspace(1) %.v to ptr addrspace(4)
  %.v1628 = select i1 %38, ptr addrspace(1) %4, ptr addrspace(1) %5
  %40 = addrspacecast ptr addrspace(1) %.v1628 to ptr addrspace(4)
  %41 = select i1 %38, i32 0, i32 %1
  %42 = sub nsw i32 %37, %41, !spirv.Decorations !15
  %43 = sdiv i32 %35, %6
  %44 = mul i32 %43, %6
  %45 = sub i32 %35, %44
  %46 = mul nsw i32 %45, %7, !spirv.Decorations !15
  %47 = and i64 %32, 1
  %.not = icmp eq i64 %47, 0
  %48 = select i1 %.not, i32 0, i32 %8
  %49 = add nsw i32 %46, %48, !spirv.Decorations !15
  %.esimd = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 19), <8 x i32> splat (i32 31), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %.esimd14 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 13), <8 x i32> splat (i32 1), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %50 = insertelement <16 x i32> undef, i32 %9, i32 0
  %51 = shufflevector <16 x i32> %50, <16 x i32> undef, <16 x i32> zeroinitializer
  %52 = add <16 x i32> %.esimd, %51
  %53 = add <16 x i32> %.esimd14, %51
  %.esimd15 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 11), <8 x i32> splat (i32 23), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %.esimd16 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 21), <8 x i32> splat (i32 9), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %54 = add <16 x i32> %.esimd15, %51
  %55 = add <16 x i32> %.esimd16, %51
  %.esimd17 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 3), <8 x i32> splat (i32 15), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %.esimd18 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 29), <8 x i32> splat (i32 17), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %56 = add <16 x i32> %.esimd17, %51
  %57 = add <16 x i32> %.esimd18, %51
  %.esimd19 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 27), <8 x i32> splat (i32 7), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %.esimd20 = call <16 x i32> @llvm.genx.wrregioni.v16i32.v8i32.i16.v8i1(<16 x i32> splat (i32 5), <8 x i32> splat (i32 25), i32 0, i32 8, i32 1, i16 32, i32 0, <8 x i1> splat (i1 true))
  %58 = add <16 x i32> %.esimd19, %51
  %59 = add <16 x i32> %.esimd20, %51
  %60 = bitcast ptr %18 to ptr
  call void @llvm.lifetime.start.p0(ptr %18)
  %61 = sext i32 %1 to i64
  %62 = mul nsw i64 %61, 24, !spirv.Decorations !15
  %63 = sext i32 %10 to i64
  %64 = mul nsw i64 %63, %61, !spirv.Decorations !15
  %65 = mul i64 %64, 24
  %66 = add nsw i32 %8, -1, !spirv.Decorations !15
  %67 = sext i32 %66 to i64
  %68 = mul i64 %62, %67
  %69 = sub i64 %65, %68
  %70 = sext i32 %49 to i64
  %71 = mul nsw i64 %70, %61, !spirv.Decorations !15
  %72 = sext i32 %42 to i64
  %73 = add nsw i64 %71, %72, !spirv.Decorations !15
  %74 = sext i32 %43 to i64
  %75 = mul nsw i64 %74, %63, !spirv.Decorations !15
  %76 = mul i64 %75, %61
  %77 = add i64 %76, %73
  %78 = mul i64 %77, 24
  %79 = getelementptr inbounds i32, ptr addrspace(4) %39, i64 %78
  br label %80

80:                                               ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5, %17
  %.01619 = phi i32 [ 0, %17 ], [ %.81627, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.01610 = phi ptr addrspace(4) [ %79, %17 ], [ %.81618, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.0 = phi i32 [ 0, %17 ], [ %.8, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %.sroa.0478.0 = phi <24 x i32> [ undef, %17 ], [ %.sroa.0478.1, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %81 = phi i32 [ 0, %17 ], [ %123, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5 ]
  %82 = icmp ult i32 %81, 4
  br i1 %82, label %102, label %83

83:                                               ; preds = %80
  %84 = bitcast ptr %19 to ptr
  call void @llvm.lifetime.start.p0(ptr %19)
  %85 = bitcast ptr %19 to ptr
  %86 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.6.2", ptr %85, i64 0, i32 0
  %87 = bitcast ptr %86 to ptr
  %88 = bitcast ptr %21 to ptr
  call void @llvm.memcpy.p0.p0.i64(ptr align 512 %87, ptr align 512 %88, i64 1024, i1 false)
  %89 = bitcast ptr %20 to ptr
  call void @llvm.lifetime.start.p0(ptr %20)
  %90 = shl nsw i64 %70, 8, !spirv.Decorations !15
  %91 = getelementptr inbounds i32, ptr addrspace(4) %22, i64 %90
  %92 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 4
  %93 = addrspacecast ptr %92 to ptr addrspace(4)
  %94 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 0
  %95 = addrspacecast ptr %94 to ptr addrspace(4)
  %96 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 1
  %97 = addrspacecast ptr %96 to ptr addrspace(4)
  %98 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 2
  %99 = addrspacecast ptr %98 to ptr addrspace(4)
  %100 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 3
  %101 = addrspacecast ptr %100 to ptr addrspace(4)
  br label %124

102:                                              ; preds = %80
  %103 = icmp sgt i32 %.0, 0
  br i1 %103, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5, label %104

104:                                              ; preds = %102
  %105 = zext i32 %81 to i64
  %106 = getelementptr inbounds [5 x %"class.sycl::_V1::ext::intel::esimd::simd.213.1"], ptr %18, i64 0, i64 %105
  %107 = addrspacecast ptr %106 to ptr addrspace(4)
  %108 = bitcast ptr addrspace(4) %.01610 to ptr addrspace(4)
  %109 = load <16 x i32>, ptr addrspace(4) %108, align 16
  %.esimd21 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0478.0, <16 x i32> %109, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %110 = getelementptr inbounds i32, ptr addrspace(4) %.01610, i64 16
  %111 = bitcast ptr addrspace(4) %110 to ptr addrspace(4)
  %112 = load <8 x i32>, ptr addrspace(4) %111, align 16
  %.esimd22 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd21, <8 x i32> %112, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %113 = bitcast ptr addrspace(4) %107 to ptr addrspace(4)
  %114 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %113, i64 0, i32 0
  %115 = load <40 x i32>, ptr addrspace(4) %114, align 256
  %.esimd23 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %115, <24 x i32> %.esimd22, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd23, ptr addrspace(4) %114, align 256
  %116 = add nsw i32 %.01619, 1, !spirv.Decorations !15
  %117 = icmp eq i32 %116, %8
  br i1 %117, label %118, label %121

118:                                              ; preds = %104
  %119 = add nsw i32 %.0, 1, !spirv.Decorations !15
  %120 = getelementptr inbounds i32, ptr addrspace(4) %.01610, i64 %69
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5

121:                                              ; preds = %104
  %122 = getelementptr inbounds i32, ptr addrspace(4) %.01610, i64 %62
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit5: ; preds = %121, %118, %102
  %.81627 = phi i32 [ %.01619, %102 ], [ 0, %118 ], [ %116, %121 ]
  %.81618 = phi ptr addrspace(4) [ %.01610, %102 ], [ %120, %118 ], [ %122, %121 ]
  %.8 = phi i32 [ %.0, %102 ], [ %119, %118 ], [ %.0, %121 ]
  %.sroa.0478.1 = phi <24 x i32> [ %.sroa.0478.0, %102 ], [ %.esimd22, %118 ], [ %.esimd22, %121 ]
  %123 = add nuw nsw i32 %81, 1, !spirv.Decorations !17
  br label %80, !llvm.loop !19

124:                                              ; preds = %1087, %83
  %.11620 = phi i32 [ %.01619, %83 ], [ %.21621, %1087 ]
  %.11611 = phi ptr addrspace(4) [ %.01610, %83 ], [ %.21612, %1087 ]
  %.1 = phi i32 [ %.0, %83 ], [ %.2, %1087 ]
  %.sroa.0449.0 = phi <24 x i32> [ undef, %83 ], [ %.sroa.0449.1, %1087 ]
  %.sroa.0454.0 = phi <24 x i32> [ undef, %83 ], [ %.sroa.0454.1, %1087 ]
  %.sroa.0460.0 = phi <24 x i32> [ undef, %83 ], [ %.sroa.0460.1, %1087 ]
  %.sroa.0466.0 = phi <24 x i32> [ undef, %83 ], [ %.sroa.0466.1, %1087 ]
  %.sroa.0472.0 = phi <24 x i32> [ undef, %83 ], [ %.sroa.0472.1, %1087 ]
  %.sroa.01403.0 = phi <256 x i32> [ undef, %83 ], [ %.sroa.01403.1, %1087 ]
  %.sroa.01415.0 = phi <256 x i32> [ undef, %83 ], [ %.sroa.01415.1, %1087 ]
  %.sroa.01427.0 = phi <256 x i32> [ undef, %83 ], [ %.sroa.01427.1, %1087 ]
  %.sroa.01439.0 = phi <256 x i32> [ undef, %83 ], [ %.sroa.01439.1, %1087 ]
  %.sroa.01451.0 = phi <256 x i32> [ undef, %83 ], [ %.esimd72, %1087 ]
  %125 = phi ptr addrspace(4) [ %91, %83 ], [ %1088, %1087 ]
  %126 = phi i32 [ 0, %83 ], [ %1089, %1087 ]
  %127 = phi i32 [ 0, %83 ], [ %1090, %1087 ]
  %128 = phi i32 [ 0, %83 ], [ %1091, %1087 ]
  %129 = icmp slt i32 %128, %8
  br i1 %129, label %130, label %1092

130:                                              ; preds = %124
  %131 = icmp eq i32 %127, 0
  br i1 %131, label %.preheader, label %141

.preheader:                                       ; preds = %130
  br label %132

132:                                              ; preds = %135, %.preheader
  %133 = phi i32 [ %140, %135 ], [ 0, %.preheader ]
  %134 = icmp ult i32 %133, 2
  br i1 %134, label %135, label %.loopexit4

135:                                              ; preds = %132
  %136 = zext i32 %133 to i64
  %137 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr %20, i64 0, i64 %136
  %138 = addrspacecast ptr %137 to ptr addrspace(4)
  %139 = bitcast ptr addrspace(4) %138 to ptr addrspace(4)
  store <128 x i32> zeroinitializer, ptr addrspace(4) %139, align 512
  %140 = add nuw nsw i32 %133, 1, !spirv.Decorations !17
  br label %132, !llvm.loop !21

.loopexit4:                                       ; preds = %132
  br label %141

141:                                              ; preds = %.loopexit4, %130
  %142 = icmp sgt i32 %.1, 0
  br i1 %142, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4, label %143

143:                                              ; preds = %141
  %144 = bitcast ptr addrspace(4) %.11611 to ptr addrspace(4)
  %145 = load <16 x i32>, ptr addrspace(4) %144, align 16
  %.esimd24 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0472.0, <16 x i32> %145, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %146 = getelementptr inbounds i32, ptr addrspace(4) %.11611, i64 16
  %147 = bitcast ptr addrspace(4) %146 to ptr addrspace(4)
  %148 = load <8 x i32>, ptr addrspace(4) %147, align 16
  %.esimd25 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd24, <8 x i32> %148, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %149 = bitcast ptr addrspace(4) %93 to ptr addrspace(4)
  %150 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %149, i64 0, i32 0
  %151 = load <40 x i32>, ptr addrspace(4) %150, align 256
  %.esimd26 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %151, <24 x i32> %.esimd25, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd26, ptr addrspace(4) %150, align 256
  %152 = add nsw i32 %.11620, 1, !spirv.Decorations !15
  %153 = icmp eq i32 %152, %8
  br i1 %153, label %154, label %157

154:                                              ; preds = %143
  %155 = add nsw i32 %.1, 1, !spirv.Decorations !15
  %156 = getelementptr inbounds i32, ptr addrspace(4) %.11611, i64 %69
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4

157:                                              ; preds = %143
  %158 = getelementptr inbounds i32, ptr addrspace(4) %.11611, i64 %62
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4: ; preds = %157, %154, %141
  %.71626 = phi i32 [ %.11620, %141 ], [ 0, %154 ], [ %152, %157 ]
  %.71617 = phi ptr addrspace(4) [ %.11611, %141 ], [ %156, %154 ], [ %158, %157 ]
  %.7 = phi i32 [ %.1, %141 ], [ %155, %154 ], [ %.1, %157 ]
  %.sroa.0472.1 = phi <24 x i32> [ %.sroa.0472.0, %141 ], [ %.esimd25, %154 ], [ %.esimd25, %157 ]
  %159 = bitcast ptr addrspace(4) %95 to ptr addrspace(4)
  %160 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %159, i64 0, i32 0
  %161 = load <40 x i32>, ptr addrspace(4) %160, align 256
  %.esimd27 = call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %161, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd28 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %161, <7 x i32> %.esimd27, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd29 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd28, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd30 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd28, <1 x i32> %.esimd29, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  store <40 x i32> %.esimd30, ptr addrspace(4) %160, align 256
  %.esimd31 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd32 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 64, i32 40)
  %162 = lshr <16 x i32> %.esimd32, %53
  %163 = shl <16 x i32> %.esimd31, %52
  %164 = or <16 x i32> %163, %162
  %165 = bitcast <16 x i32> %164 to <32 x i16>
  %.esimd33 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %165, i32 0, i32 16, i32 2, i16 2, i32 0)
  %166 = zext <16 x i16> %.esimd33 to <16 x i32>
  %167 = mul <16 x i32> %166, splat (i32 -2082680531)
  %168 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  %169 = load <128 x i32>, ptr addrspace(4) %168, align 512
  %.esimd34 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %169, <16 x i32> %167, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %170 = lshr <16 x i32> %164, splat (i32 13)
  %171 = bitcast <16 x i32> %170 to <32 x i16>
  %.esimd35 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %171, i32 0, i32 16, i32 2, i16 0, i32 0)
  %172 = zext <16 x i16> %.esimd35 to <16 x i32>
  %173 = mul <16 x i32> %172, splat (i32 -2082680531)
  %.esimd36 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd34, <16 x i32> %173, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %174 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd36, ptr addrspace(4) %174, align 512
  %175 = lshr <16 x i32> %164, splat (i32 10)
  %176 = bitcast <16 x i32> %175 to <32 x i16>
  %.esimd37 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %176, i32 0, i32 16, i32 2, i16 0, i32 0)
  %177 = zext <16 x i16> %.esimd37 to <16 x i32>
  %178 = mul <16 x i32> %177, splat (i32 -2082680531)
  %179 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 1
  %180 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  %181 = load <128 x i32>, ptr addrspace(4) %180, align 512
  %.esimd38 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %181, <16 x i32> %178, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %182 = lshr <16 x i32> %164, splat (i32 7)
  %183 = bitcast <16 x i32> %182 to <32 x i16>
  %.esimd39 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %183, i32 0, i32 16, i32 2, i16 0, i32 0)
  %184 = zext <16 x i16> %.esimd39 to <16 x i32>
  %185 = mul <16 x i32> %184, splat (i32 -2082680531)
  %.esimd40 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd38, <16 x i32> %185, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %186 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd40, ptr addrspace(4) %186, align 512
  %.esimd42 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 96, i32 40)
  %187 = lshr <16 x i32> %.esimd42, %55
  %188 = shl <16 x i32> %.esimd32, %54
  %189 = or <16 x i32> %188, %187
  %190 = bitcast <16 x i32> %189 to <32 x i16>
  %.esimd43 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %190, i32 0, i32 16, i32 2, i16 2, i32 0)
  %191 = zext <16 x i16> %.esimd43 to <16 x i32>
  %192 = mul <16 x i32> %191, splat (i32 -2082680531)
  %.esimd44 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd36, <16 x i32> %192, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %193 = lshr <16 x i32> %189, splat (i32 13)
  %194 = bitcast <16 x i32> %193 to <32 x i16>
  %.esimd45 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %194, i32 0, i32 16, i32 2, i16 0, i32 0)
  %195 = zext <16 x i16> %.esimd45 to <16 x i32>
  %196 = mul <16 x i32> %195, splat (i32 -2082680531)
  %.esimd46 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd44, <16 x i32> %196, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %197 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd46, ptr addrspace(4) %197, align 512
  %198 = lshr <16 x i32> %189, splat (i32 10)
  %199 = bitcast <16 x i32> %198 to <32 x i16>
  %.esimd47 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %199, i32 0, i32 16, i32 2, i16 0, i32 0)
  %200 = zext <16 x i16> %.esimd47 to <16 x i32>
  %201 = mul <16 x i32> %200, splat (i32 -2082680531)
  %.esimd48 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd40, <16 x i32> %201, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %202 = lshr <16 x i32> %189, splat (i32 7)
  %203 = bitcast <16 x i32> %202 to <32 x i16>
  %.esimd49 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %203, i32 0, i32 16, i32 2, i16 0, i32 0)
  %204 = zext <16 x i16> %.esimd49 to <16 x i32>
  %205 = mul <16 x i32> %204, splat (i32 -2082680531)
  %.esimd50 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd48, <16 x i32> %205, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %206 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd50, ptr addrspace(4) %206, align 512
  %.esimd52 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 0, i32 8, i32 1, i16 128, i32 40)
  %207 = lshr <16 x i32> %.esimd52, %57
  %208 = shl <16 x i32> %.esimd42, %56
  %209 = or <16 x i32> %208, %207
  %210 = bitcast <16 x i32> %209 to <32 x i16>
  %.esimd53 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %210, i32 0, i32 16, i32 2, i16 2, i32 0)
  %211 = zext <16 x i16> %.esimd53 to <16 x i32>
  %212 = mul <16 x i32> %211, splat (i32 -2082680531)
  %.esimd54 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd46, <16 x i32> %212, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %213 = lshr <16 x i32> %209, splat (i32 13)
  %214 = bitcast <16 x i32> %213 to <32 x i16>
  %.esimd55 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %214, i32 0, i32 16, i32 2, i16 0, i32 0)
  %215 = zext <16 x i16> %.esimd55 to <16 x i32>
  %216 = mul <16 x i32> %215, splat (i32 -2082680531)
  %.esimd56 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd54, <16 x i32> %216, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %217 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd56, ptr addrspace(4) %217, align 512
  %218 = lshr <16 x i32> %209, splat (i32 10)
  %219 = bitcast <16 x i32> %218 to <32 x i16>
  %.esimd57 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %219, i32 0, i32 16, i32 2, i16 0, i32 0)
  %220 = zext <16 x i16> %.esimd57 to <16 x i32>
  %221 = mul <16 x i32> %220, splat (i32 -2082680531)
  %.esimd58 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd50, <16 x i32> %221, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %222 = lshr <16 x i32> %209, splat (i32 7)
  %223 = bitcast <16 x i32> %222 to <32 x i16>
  %.esimd59 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %223, i32 0, i32 16, i32 2, i16 0, i32 0)
  %224 = zext <16 x i16> %.esimd59 to <16 x i32>
  %225 = mul <16 x i32> %224, splat (i32 -2082680531)
  %.esimd60 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd58, <16 x i32> %225, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %226 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd60, ptr addrspace(4) %226, align 512
  %.esimd61 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd30, i32 8, i32 8, i32 1, i16 96, i32 40)
  %227 = lshr <16 x i32> %.esimd52, %59
  %228 = shl <16 x i32> %.esimd61, %58
  %229 = or <16 x i32> %228, %227
  %230 = bitcast <16 x i32> %229 to <32 x i16>
  %.esimd63 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %230, i32 0, i32 16, i32 2, i16 2, i32 0)
  %231 = zext <16 x i16> %.esimd63 to <16 x i32>
  %232 = mul <16 x i32> %231, splat (i32 -2082680531)
  %.esimd64 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd56, <16 x i32> %232, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %233 = lshr <16 x i32> %229, splat (i32 13)
  %234 = bitcast <16 x i32> %233 to <32 x i16>
  %.esimd65 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %234, i32 0, i32 16, i32 2, i16 0, i32 0)
  %235 = zext <16 x i16> %.esimd65 to <16 x i32>
  %236 = mul <16 x i32> %235, splat (i32 -2082680531)
  %.esimd66 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd64, <16 x i32> %236, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %237 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd66, ptr addrspace(4) %237, align 512
  %238 = lshr <16 x i32> %229, splat (i32 10)
  %239 = bitcast <16 x i32> %238 to <32 x i16>
  %.esimd67 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %239, i32 0, i32 16, i32 2, i16 0, i32 0)
  %240 = zext <16 x i16> %.esimd67 to <16 x i32>
  %241 = mul <16 x i32> %240, splat (i32 -2082680531)
  %.esimd68 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd60, <16 x i32> %241, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %242 = lshr <16 x i32> %229, splat (i32 7)
  %243 = bitcast <16 x i32> %242 to <32 x i16>
  %.esimd69 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %243, i32 0, i32 16, i32 2, i16 0, i32 0)
  %244 = zext <16 x i16> %.esimd69 to <16 x i32>
  %245 = mul <16 x i32> %244, splat (i32 -2082680531)
  %.esimd70 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd68, <16 x i32> %245, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %246 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd70, ptr addrspace(4) %246, align 512
  %247 = bitcast ptr addrspace(4) %125 to ptr addrspace(4)
  %248 = load <128 x i32>, ptr addrspace(4) %247, align 16
  %.esimd71 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01451.0, <128 x i32> %248, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %249 = getelementptr inbounds i32, ptr addrspace(4) %125, i64 128
  %250 = bitcast ptr addrspace(4) %249 to ptr addrspace(4)
  %251 = load <128 x i32>, ptr addrspace(4) %250, align 16
  %.esimd72 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd71, <128 x i32> %251, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  br label %252

252:                                              ; preds = %261, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4
  %253 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit4 ], [ %262, %261 ]
  %254 = icmp ult i32 %253, 2
  br i1 %254, label %255, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit9

255:                                              ; preds = %252
  %256 = shl nuw nsw i32 %253, 7, !spirv.Decorations !17
  %257 = zext i32 %253 to i64
  br label %258

258:                                              ; preds = %263, %255
  %259 = phi i32 [ %276, %263 ], [ 0, %255 ]
  %260 = icmp ult i32 %259, 2
  br i1 %260, label %263, label %261

261:                                              ; preds = %258
  %262 = add nuw nsw i32 %253, 1, !spirv.Decorations !17
  br label %252, !llvm.loop !22

263:                                              ; preds = %258
  %264 = shl nuw nsw i32 %259, 6, !spirv.Decorations !17
  %265 = or i32 %256, %264
  %266 = trunc i32 %265 to i16
  %267 = shl nuw nsw i16 %266, 2, !spirv.Decorations !17
  %.esimd73 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd72, i32 0, i32 64, i32 1, i16 %267, i32 0)
  %268 = zext i32 %259 to i64
  %269 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %24, i64 0, i64 %268
  %270 = bitcast ptr addrspace(4) %269 to ptr addrspace(4)
  %271 = load <128 x i32>, ptr addrspace(4) %270, align 512
  %272 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %257
  %273 = bitcast ptr addrspace(4) %272 to ptr addrspace(4)
  %274 = load <128 x i32>, ptr addrspace(4) %273, align 512
  %.esimd74 = call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %271, <128 x i32> %274, <64 x i32> %.esimd73, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %275 = bitcast ptr addrspace(4) %269 to ptr addrspace(4)
  store <128 x i32> %.esimd74, ptr addrspace(4) %275, align 512
  %276 = add nuw nsw i32 %259, 1, !spirv.Decorations !17
  br label %258, !llvm.loop !23

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit9: ; preds = %252
  %277 = getelementptr inbounds i32, ptr addrspace(4) %125, i64 256
  %278 = add nsw i32 %127, 1, !spirv.Decorations !15
  %279 = icmp eq i32 %278, %8
  br i1 %279, label %283, label %280

280:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit9
  %281 = add nuw nsw i32 %128, 1, !spirv.Decorations !17
  %282 = icmp slt i32 %281, %8
  br i1 %282, label %324, label %1087

283:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit9
  %284 = add nsw i32 %43, %126, !spirv.Decorations !15
  %285 = sext i32 %45 to i64
  %286 = shl nsw i64 %285, 1, !spirv.Decorations !15
  %287 = or i64 %286, %47
  %288 = sext i32 %12 to i64
  %289 = mul i64 %287, %288
  %290 = sext i32 %284 to i64
  %291 = add i64 %289, %290
  %292 = shl i64 %291, 4
  %293 = sext i32 %13 to i64
  %294 = mul i64 %292, %293
  %295 = getelementptr inbounds i32, ptr addrspace(4) %40, i64 %294
  %296 = shl nsw i64 %72, 4, !spirv.Decorations !15
  %297 = getelementptr inbounds i32, ptr addrspace(4) %295, i64 %296
  br label %298

298:                                              ; preds = %307, %283
  %299 = phi i32 [ 0, %283 ], [ %308, %307 ]
  %300 = icmp ult i32 %299, 2
  br i1 %300, label %301, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13

301:                                              ; preds = %298
  %302 = zext i32 %299 to i64
  %303 = shl nuw nsw i32 %299, 3, !spirv.Decorations !17
  br label %304

304:                                              ; preds = %309, %301
  %305 = phi i32 [ %320, %309 ], [ 0, %301 ]
  %306 = icmp ult i32 %305, 8
  br i1 %306, label %309, label %307

307:                                              ; preds = %304
  %308 = add nuw nsw i32 %299, 1, !spirv.Decorations !17
  br label %298, !llvm.loop !24

309:                                              ; preds = %304
  %310 = trunc i32 %305 to i16
  %311 = shl nuw nsw i16 %310, 6, !spirv.Decorations !17
  %312 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %24, i64 0, i64 %302
  %313 = bitcast ptr addrspace(4) %312 to ptr addrspace(4)
  %314 = load <128 x i32>, ptr addrspace(4) %313, align 512
  %.esimd75 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %314, i32 0, i32 16, i32 1, i16 %311, i32 0)
  %315 = or i32 %303, %305
  %316 = sext i32 %315 to i64
  %317 = mul nsw i64 %316, %293, !spirv.Decorations !15
  %318 = getelementptr inbounds i32, ptr addrspace(4) %297, i64 %317
  %319 = bitcast ptr addrspace(4) %318 to ptr addrspace(4)
  store <16 x i32> %.esimd75, ptr addrspace(4) %319, align 16
  %320 = add nuw nsw i32 %305, 1, !spirv.Decorations !17
  br label %304, !llvm.loop !25

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13: ; preds = %298
  %321 = add nsw i32 %126, 1, !spirv.Decorations !15
  %322 = add nuw nsw i32 %128, 1, !spirv.Decorations !17
  %323 = icmp slt i32 %322, %8
  br i1 %323, label %326, label %1087

324:                                              ; preds = %280
  %325 = icmp eq i32 %278, 0
  br i1 %325, label %326, label %338

326:                                              ; preds = %324, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13
  %327 = phi ptr addrspace(4) [ %277, %324 ], [ %91, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ]
  %328 = phi i32 [ %126, %324 ], [ %321, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ]
  br label %329

329:                                              ; preds = %332, %326
  %330 = phi i32 [ %337, %332 ], [ 0, %326 ]
  %331 = icmp ult i32 %330, 2
  br i1 %331, label %332, label %.loopexit3

332:                                              ; preds = %329
  %333 = zext i32 %330 to i64
  %334 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr %20, i64 0, i64 %333
  %335 = addrspacecast ptr %334 to ptr addrspace(4)
  %336 = bitcast ptr addrspace(4) %335 to ptr addrspace(4)
  store <128 x i32> zeroinitializer, ptr addrspace(4) %336, align 512
  %337 = add nuw nsw i32 %330, 1, !spirv.Decorations !17
  br label %329, !llvm.loop !26

.loopexit3:                                       ; preds = %329
  br label %338

338:                                              ; preds = %.loopexit3, %324
  %339 = phi ptr addrspace(4) [ %277, %324 ], [ %327, %.loopexit3 ]
  %340 = phi i32 [ %126, %324 ], [ %328, %.loopexit3 ]
  %341 = phi i32 [ %278, %324 ], [ 0, %.loopexit3 ]
  %342 = icmp sgt i32 %.7, 0
  br i1 %342, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3, label %343

343:                                              ; preds = %338
  %344 = bitcast ptr addrspace(4) %.71617 to ptr addrspace(4)
  %345 = load <16 x i32>, ptr addrspace(4) %344, align 16
  %.esimd76 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0466.0, <16 x i32> %345, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %346 = getelementptr inbounds i32, ptr addrspace(4) %.71617, i64 16
  %347 = bitcast ptr addrspace(4) %346 to ptr addrspace(4)
  %348 = load <8 x i32>, ptr addrspace(4) %347, align 16
  %.esimd77 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd76, <8 x i32> %348, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd78 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd30, <24 x i32> %.esimd77, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd78, ptr addrspace(4) %160, align 256
  %349 = add nsw i32 %.71626, 1, !spirv.Decorations !15
  %350 = icmp eq i32 %349, %8
  br i1 %350, label %351, label %354

351:                                              ; preds = %343
  %352 = add nsw i32 %.7, 1, !spirv.Decorations !15
  %353 = getelementptr inbounds i32, ptr addrspace(4) %.71617, i64 %69
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3

354:                                              ; preds = %343
  %355 = getelementptr inbounds i32, ptr addrspace(4) %.71617, i64 %62
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3: ; preds = %354, %351, %338
  %.61625 = phi i32 [ %.71626, %338 ], [ 0, %351 ], [ %349, %354 ]
  %.61616 = phi ptr addrspace(4) [ %.71617, %338 ], [ %353, %351 ], [ %355, %354 ]
  %.6 = phi i32 [ %.7, %338 ], [ %352, %351 ], [ %.7, %354 ]
  %.sroa.0466.2 = phi <24 x i32> [ %.sroa.0466.0, %338 ], [ %.esimd77, %351 ], [ %.esimd77, %354 ]
  %356 = bitcast ptr addrspace(4) %97 to ptr addrspace(4)
  %357 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %356, i64 0, i32 0
  %358 = load <40 x i32>, ptr addrspace(4) %357, align 256
  %.esimd79 = call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %358, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd80 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %358, <7 x i32> %.esimd79, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd81 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd80, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd82 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd80, <1 x i32> %.esimd81, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  store <40 x i32> %.esimd82, ptr addrspace(4) %357, align 256
  %.esimd83 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd84 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 64, i32 40)
  %359 = lshr <16 x i32> %.esimd84, %53
  %360 = shl <16 x i32> %.esimd83, %52
  %361 = or <16 x i32> %360, %359
  %362 = bitcast <16 x i32> %361 to <32 x i16>
  %.esimd85 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %362, i32 0, i32 16, i32 2, i16 2, i32 0)
  %363 = zext <16 x i16> %.esimd85 to <16 x i32>
  %364 = mul <16 x i32> %363, splat (i32 -2082680531)
  %.esimd86 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd66, <16 x i32> %364, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %365 = lshr <16 x i32> %361, splat (i32 13)
  %366 = bitcast <16 x i32> %365 to <32 x i16>
  %.esimd87 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %366, i32 0, i32 16, i32 2, i16 0, i32 0)
  %367 = zext <16 x i16> %.esimd87 to <16 x i32>
  %368 = mul <16 x i32> %367, splat (i32 -2082680531)
  %.esimd88 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd86, <16 x i32> %368, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %369 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd88, ptr addrspace(4) %369, align 512
  %370 = lshr <16 x i32> %361, splat (i32 10)
  %371 = bitcast <16 x i32> %370 to <32 x i16>
  %.esimd89 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %371, i32 0, i32 16, i32 2, i16 0, i32 0)
  %372 = zext <16 x i16> %.esimd89 to <16 x i32>
  %373 = mul <16 x i32> %372, splat (i32 -2082680531)
  %.esimd90 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd70, <16 x i32> %373, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %374 = lshr <16 x i32> %361, splat (i32 7)
  %375 = bitcast <16 x i32> %374 to <32 x i16>
  %.esimd91 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %375, i32 0, i32 16, i32 2, i16 0, i32 0)
  %376 = zext <16 x i16> %.esimd91 to <16 x i32>
  %377 = mul <16 x i32> %376, splat (i32 -2082680531)
  %.esimd92 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd90, <16 x i32> %377, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %378 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd92, ptr addrspace(4) %378, align 512
  %.esimd94 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 96, i32 40)
  %379 = lshr <16 x i32> %.esimd94, %55
  %380 = shl <16 x i32> %.esimd84, %54
  %381 = or <16 x i32> %380, %379
  %382 = bitcast <16 x i32> %381 to <32 x i16>
  %.esimd95 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %382, i32 0, i32 16, i32 2, i16 2, i32 0)
  %383 = zext <16 x i16> %.esimd95 to <16 x i32>
  %384 = mul <16 x i32> %383, splat (i32 -2082680531)
  %.esimd96 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd88, <16 x i32> %384, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %385 = lshr <16 x i32> %381, splat (i32 13)
  %386 = bitcast <16 x i32> %385 to <32 x i16>
  %.esimd97 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %386, i32 0, i32 16, i32 2, i16 0, i32 0)
  %387 = zext <16 x i16> %.esimd97 to <16 x i32>
  %388 = mul <16 x i32> %387, splat (i32 -2082680531)
  %.esimd98 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd96, <16 x i32> %388, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %389 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd98, ptr addrspace(4) %389, align 512
  %390 = lshr <16 x i32> %381, splat (i32 10)
  %391 = bitcast <16 x i32> %390 to <32 x i16>
  %.esimd99 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %391, i32 0, i32 16, i32 2, i16 0, i32 0)
  %392 = zext <16 x i16> %.esimd99 to <16 x i32>
  %393 = mul <16 x i32> %392, splat (i32 -2082680531)
  %.esimd100 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd92, <16 x i32> %393, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %394 = lshr <16 x i32> %381, splat (i32 7)
  %395 = bitcast <16 x i32> %394 to <32 x i16>
  %.esimd101 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %395, i32 0, i32 16, i32 2, i16 0, i32 0)
  %396 = zext <16 x i16> %.esimd101 to <16 x i32>
  %397 = mul <16 x i32> %396, splat (i32 -2082680531)
  %.esimd102 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd100, <16 x i32> %397, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %398 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd102, ptr addrspace(4) %398, align 512
  %.esimd104 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 0, i32 8, i32 1, i16 128, i32 40)
  %399 = lshr <16 x i32> %.esimd104, %57
  %400 = shl <16 x i32> %.esimd94, %56
  %401 = or <16 x i32> %400, %399
  %402 = bitcast <16 x i32> %401 to <32 x i16>
  %.esimd105 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %402, i32 0, i32 16, i32 2, i16 2, i32 0)
  %403 = zext <16 x i16> %.esimd105 to <16 x i32>
  %404 = mul <16 x i32> %403, splat (i32 -2082680531)
  %.esimd106 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd98, <16 x i32> %404, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %405 = lshr <16 x i32> %401, splat (i32 13)
  %406 = bitcast <16 x i32> %405 to <32 x i16>
  %.esimd107 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %406, i32 0, i32 16, i32 2, i16 0, i32 0)
  %407 = zext <16 x i16> %.esimd107 to <16 x i32>
  %408 = mul <16 x i32> %407, splat (i32 -2082680531)
  %.esimd108 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd106, <16 x i32> %408, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %409 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd108, ptr addrspace(4) %409, align 512
  %410 = lshr <16 x i32> %401, splat (i32 10)
  %411 = bitcast <16 x i32> %410 to <32 x i16>
  %.esimd109 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %411, i32 0, i32 16, i32 2, i16 0, i32 0)
  %412 = zext <16 x i16> %.esimd109 to <16 x i32>
  %413 = mul <16 x i32> %412, splat (i32 -2082680531)
  %.esimd110 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd102, <16 x i32> %413, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %414 = lshr <16 x i32> %401, splat (i32 7)
  %415 = bitcast <16 x i32> %414 to <32 x i16>
  %.esimd111 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %415, i32 0, i32 16, i32 2, i16 0, i32 0)
  %416 = zext <16 x i16> %.esimd111 to <16 x i32>
  %417 = mul <16 x i32> %416, splat (i32 -2082680531)
  %.esimd112 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd110, <16 x i32> %417, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %418 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd112, ptr addrspace(4) %418, align 512
  %.esimd113 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd82, i32 8, i32 8, i32 1, i16 96, i32 40)
  %419 = lshr <16 x i32> %.esimd104, %59
  %420 = shl <16 x i32> %.esimd113, %58
  %421 = or <16 x i32> %420, %419
  %422 = bitcast <16 x i32> %421 to <32 x i16>
  %.esimd115 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %422, i32 0, i32 16, i32 2, i16 2, i32 0)
  %423 = zext <16 x i16> %.esimd115 to <16 x i32>
  %424 = mul <16 x i32> %423, splat (i32 -2082680531)
  %.esimd116 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd108, <16 x i32> %424, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %425 = lshr <16 x i32> %421, splat (i32 13)
  %426 = bitcast <16 x i32> %425 to <32 x i16>
  %.esimd117 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %426, i32 0, i32 16, i32 2, i16 0, i32 0)
  %427 = zext <16 x i16> %.esimd117 to <16 x i32>
  %428 = mul <16 x i32> %427, splat (i32 -2082680531)
  %.esimd118 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd116, <16 x i32> %428, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %429 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd118, ptr addrspace(4) %429, align 512
  %430 = lshr <16 x i32> %421, splat (i32 10)
  %431 = bitcast <16 x i32> %430 to <32 x i16>
  %.esimd119 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %431, i32 0, i32 16, i32 2, i16 0, i32 0)
  %432 = zext <16 x i16> %.esimd119 to <16 x i32>
  %433 = mul <16 x i32> %432, splat (i32 -2082680531)
  %.esimd120 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd112, <16 x i32> %433, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %434 = lshr <16 x i32> %421, splat (i32 7)
  %435 = bitcast <16 x i32> %434 to <32 x i16>
  %.esimd121 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %435, i32 0, i32 16, i32 2, i16 0, i32 0)
  %436 = zext <16 x i16> %.esimd121 to <16 x i32>
  %437 = mul <16 x i32> %436, splat (i32 -2082680531)
  %.esimd122 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd120, <16 x i32> %437, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %438 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd122, ptr addrspace(4) %438, align 512
  %439 = bitcast ptr addrspace(4) %339 to ptr addrspace(4)
  %440 = load <128 x i32>, ptr addrspace(4) %439, align 16
  %.esimd123 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01439.0, <128 x i32> %440, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %441 = getelementptr inbounds i32, ptr addrspace(4) %339, i64 128
  %442 = bitcast ptr addrspace(4) %441 to ptr addrspace(4)
  %443 = load <128 x i32>, ptr addrspace(4) %442, align 16
  %.esimd124 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd123, <128 x i32> %443, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  br label %444

444:                                              ; preds = %453, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3
  %445 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit3 ], [ %454, %453 ]
  %446 = icmp ult i32 %445, 2
  br i1 %446, label %447, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit8

447:                                              ; preds = %444
  %448 = shl nuw nsw i32 %445, 7, !spirv.Decorations !17
  %449 = zext i32 %445 to i64
  br label %450

450:                                              ; preds = %455, %447
  %451 = phi i32 [ %468, %455 ], [ 0, %447 ]
  %452 = icmp ult i32 %451, 2
  br i1 %452, label %455, label %453

453:                                              ; preds = %450
  %454 = add nuw nsw i32 %445, 1, !spirv.Decorations !17
  br label %444, !llvm.loop !27

455:                                              ; preds = %450
  %456 = shl nuw nsw i32 %451, 6, !spirv.Decorations !17
  %457 = or i32 %448, %456
  %458 = trunc i32 %457 to i16
  %459 = shl nuw nsw i16 %458, 2, !spirv.Decorations !17
  %.esimd125 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd124, i32 0, i32 64, i32 1, i16 %459, i32 0)
  %460 = zext i32 %451 to i64
  %461 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %24, i64 0, i64 %460
  %462 = bitcast ptr addrspace(4) %461 to ptr addrspace(4)
  %463 = load <128 x i32>, ptr addrspace(4) %462, align 512
  %464 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %449
  %465 = bitcast ptr addrspace(4) %464 to ptr addrspace(4)
  %466 = load <128 x i32>, ptr addrspace(4) %465, align 512
  %.esimd126 = call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %463, <128 x i32> %466, <64 x i32> %.esimd125, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %467 = bitcast ptr addrspace(4) %461 to ptr addrspace(4)
  store <128 x i32> %.esimd126, ptr addrspace(4) %467, align 512
  %468 = add nuw nsw i32 %451, 1, !spirv.Decorations !17
  br label %450, !llvm.loop !28

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit8: ; preds = %444
  %469 = getelementptr inbounds i32, ptr addrspace(4) %339, i64 256
  %470 = add nsw i32 %341, 1, !spirv.Decorations !15
  %471 = icmp eq i32 %470, %8
  br i1 %471, label %475, label %472

472:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit8
  %473 = add nuw nsw i32 %128, 2, !spirv.Decorations !17
  %474 = icmp slt i32 %473, %8
  br i1 %474, label %516, label %1087

475:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit8
  %476 = add nsw i32 %43, %340, !spirv.Decorations !15
  %477 = sext i32 %45 to i64
  %478 = shl nsw i64 %477, 1, !spirv.Decorations !15
  %479 = or i64 %478, %47
  %480 = sext i32 %12 to i64
  %481 = mul i64 %479, %480
  %482 = sext i32 %476 to i64
  %483 = add i64 %481, %482
  %484 = shl i64 %483, 4
  %485 = sext i32 %13 to i64
  %486 = mul i64 %484, %485
  %487 = getelementptr inbounds i32, ptr addrspace(4) %40, i64 %486
  %488 = shl nsw i64 %72, 4, !spirv.Decorations !15
  %489 = getelementptr inbounds i32, ptr addrspace(4) %487, i64 %488
  br label %490

490:                                              ; preds = %499, %475
  %491 = phi i32 [ 0, %475 ], [ %500, %499 ]
  %492 = icmp ult i32 %491, 2
  br i1 %492, label %493, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12

493:                                              ; preds = %490
  %494 = zext i32 %491 to i64
  %495 = shl nuw nsw i32 %491, 3, !spirv.Decorations !17
  br label %496

496:                                              ; preds = %501, %493
  %497 = phi i32 [ %512, %501 ], [ 0, %493 ]
  %498 = icmp ult i32 %497, 8
  br i1 %498, label %501, label %499

499:                                              ; preds = %496
  %500 = add nuw nsw i32 %491, 1, !spirv.Decorations !17
  br label %490, !llvm.loop !29

501:                                              ; preds = %496
  %502 = trunc i32 %497 to i16
  %503 = shl nuw nsw i16 %502, 6, !spirv.Decorations !17
  %504 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %24, i64 0, i64 %494
  %505 = bitcast ptr addrspace(4) %504 to ptr addrspace(4)
  %506 = load <128 x i32>, ptr addrspace(4) %505, align 512
  %.esimd127 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %506, i32 0, i32 16, i32 1, i16 %503, i32 0)
  %507 = or i32 %495, %497
  %508 = sext i32 %507 to i64
  %509 = mul nsw i64 %508, %485, !spirv.Decorations !15
  %510 = getelementptr inbounds i32, ptr addrspace(4) %489, i64 %509
  %511 = bitcast ptr addrspace(4) %510 to ptr addrspace(4)
  store <16 x i32> %.esimd127, ptr addrspace(4) %511, align 16
  %512 = add nuw nsw i32 %497, 1, !spirv.Decorations !17
  br label %496, !llvm.loop !30

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12: ; preds = %490
  %513 = add nsw i32 %340, 1, !spirv.Decorations !15
  %514 = add nuw nsw i32 %128, 2, !spirv.Decorations !17
  %515 = icmp slt i32 %514, %8
  br i1 %515, label %518, label %1087

516:                                              ; preds = %472
  %517 = icmp eq i32 %470, 0
  br i1 %517, label %518, label %530

518:                                              ; preds = %516, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12
  %519 = phi ptr addrspace(4) [ %469, %516 ], [ %91, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ]
  %520 = phi i32 [ %340, %516 ], [ %513, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ]
  br label %521

521:                                              ; preds = %524, %518
  %522 = phi i32 [ %529, %524 ], [ 0, %518 ]
  %523 = icmp ult i32 %522, 2
  br i1 %523, label %524, label %.loopexit2

524:                                              ; preds = %521
  %525 = zext i32 %522 to i64
  %526 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr %20, i64 0, i64 %525
  %527 = addrspacecast ptr %526 to ptr addrspace(4)
  %528 = bitcast ptr addrspace(4) %527 to ptr addrspace(4)
  store <128 x i32> zeroinitializer, ptr addrspace(4) %528, align 512
  %529 = add nuw nsw i32 %522, 1, !spirv.Decorations !17
  br label %521, !llvm.loop !31

.loopexit2:                                       ; preds = %521
  br label %530

530:                                              ; preds = %.loopexit2, %516
  %531 = phi ptr addrspace(4) [ %469, %516 ], [ %519, %.loopexit2 ]
  %532 = phi i32 [ %340, %516 ], [ %520, %.loopexit2 ]
  %533 = phi i32 [ %470, %516 ], [ 0, %.loopexit2 ]
  %534 = icmp sgt i32 %.6, 0
  br i1 %534, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2, label %535

535:                                              ; preds = %530
  %536 = bitcast ptr addrspace(4) %.61616 to ptr addrspace(4)
  %537 = load <16 x i32>, ptr addrspace(4) %536, align 16
  %.esimd128 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0460.0, <16 x i32> %537, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %538 = getelementptr inbounds i32, ptr addrspace(4) %.61616, i64 16
  %539 = bitcast ptr addrspace(4) %538 to ptr addrspace(4)
  %540 = load <8 x i32>, ptr addrspace(4) %539, align 16
  %.esimd129 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd128, <8 x i32> %540, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd130 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd82, <24 x i32> %.esimd129, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd130, ptr addrspace(4) %357, align 256
  %541 = add nsw i32 %.61625, 1, !spirv.Decorations !15
  %542 = icmp eq i32 %541, %8
  br i1 %542, label %543, label %546

543:                                              ; preds = %535
  %544 = add nsw i32 %.6, 1, !spirv.Decorations !15
  %545 = getelementptr inbounds i32, ptr addrspace(4) %.61616, i64 %69
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2

546:                                              ; preds = %535
  %547 = getelementptr inbounds i32, ptr addrspace(4) %.61616, i64 %62
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2: ; preds = %546, %543, %530
  %.51624 = phi i32 [ %.61625, %530 ], [ 0, %543 ], [ %541, %546 ]
  %.51615 = phi ptr addrspace(4) [ %.61616, %530 ], [ %545, %543 ], [ %547, %546 ]
  %.5 = phi i32 [ %.6, %530 ], [ %544, %543 ], [ %.6, %546 ]
  %.sroa.0460.2 = phi <24 x i32> [ %.sroa.0460.0, %530 ], [ %.esimd129, %543 ], [ %.esimd129, %546 ]
  %548 = bitcast ptr addrspace(4) %99 to ptr addrspace(4)
  %549 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %548, i64 0, i32 0
  %550 = load <40 x i32>, ptr addrspace(4) %549, align 256
  %.esimd131 = call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %550, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd132 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %550, <7 x i32> %.esimd131, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd133 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd132, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd134 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd132, <1 x i32> %.esimd133, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  store <40 x i32> %.esimd134, ptr addrspace(4) %549, align 256
  %.esimd135 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd136 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 64, i32 40)
  %551 = lshr <16 x i32> %.esimd136, %53
  %552 = shl <16 x i32> %.esimd135, %52
  %553 = or <16 x i32> %552, %551
  %554 = bitcast <16 x i32> %553 to <32 x i16>
  %.esimd137 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %554, i32 0, i32 16, i32 2, i16 2, i32 0)
  %555 = zext <16 x i16> %.esimd137 to <16 x i32>
  %556 = mul <16 x i32> %555, splat (i32 -2082680531)
  %.esimd138 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd118, <16 x i32> %556, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %557 = lshr <16 x i32> %553, splat (i32 13)
  %558 = bitcast <16 x i32> %557 to <32 x i16>
  %.esimd139 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %558, i32 0, i32 16, i32 2, i16 0, i32 0)
  %559 = zext <16 x i16> %.esimd139 to <16 x i32>
  %560 = mul <16 x i32> %559, splat (i32 -2082680531)
  %.esimd140 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd138, <16 x i32> %560, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %561 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd140, ptr addrspace(4) %561, align 512
  %562 = lshr <16 x i32> %553, splat (i32 10)
  %563 = bitcast <16 x i32> %562 to <32 x i16>
  %.esimd141 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %563, i32 0, i32 16, i32 2, i16 0, i32 0)
  %564 = zext <16 x i16> %.esimd141 to <16 x i32>
  %565 = mul <16 x i32> %564, splat (i32 -2082680531)
  %.esimd142 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd122, <16 x i32> %565, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %566 = lshr <16 x i32> %553, splat (i32 7)
  %567 = bitcast <16 x i32> %566 to <32 x i16>
  %.esimd143 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %567, i32 0, i32 16, i32 2, i16 0, i32 0)
  %568 = zext <16 x i16> %.esimd143 to <16 x i32>
  %569 = mul <16 x i32> %568, splat (i32 -2082680531)
  %.esimd144 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd142, <16 x i32> %569, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %570 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd144, ptr addrspace(4) %570, align 512
  %.esimd146 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 96, i32 40)
  %571 = lshr <16 x i32> %.esimd146, %55
  %572 = shl <16 x i32> %.esimd136, %54
  %573 = or <16 x i32> %572, %571
  %574 = bitcast <16 x i32> %573 to <32 x i16>
  %.esimd147 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %574, i32 0, i32 16, i32 2, i16 2, i32 0)
  %575 = zext <16 x i16> %.esimd147 to <16 x i32>
  %576 = mul <16 x i32> %575, splat (i32 -2082680531)
  %.esimd148 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd140, <16 x i32> %576, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %577 = lshr <16 x i32> %573, splat (i32 13)
  %578 = bitcast <16 x i32> %577 to <32 x i16>
  %.esimd149 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %578, i32 0, i32 16, i32 2, i16 0, i32 0)
  %579 = zext <16 x i16> %.esimd149 to <16 x i32>
  %580 = mul <16 x i32> %579, splat (i32 -2082680531)
  %.esimd150 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd148, <16 x i32> %580, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %581 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd150, ptr addrspace(4) %581, align 512
  %582 = lshr <16 x i32> %573, splat (i32 10)
  %583 = bitcast <16 x i32> %582 to <32 x i16>
  %.esimd151 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %583, i32 0, i32 16, i32 2, i16 0, i32 0)
  %584 = zext <16 x i16> %.esimd151 to <16 x i32>
  %585 = mul <16 x i32> %584, splat (i32 -2082680531)
  %.esimd152 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd144, <16 x i32> %585, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %586 = lshr <16 x i32> %573, splat (i32 7)
  %587 = bitcast <16 x i32> %586 to <32 x i16>
  %.esimd153 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %587, i32 0, i32 16, i32 2, i16 0, i32 0)
  %588 = zext <16 x i16> %.esimd153 to <16 x i32>
  %589 = mul <16 x i32> %588, splat (i32 -2082680531)
  %.esimd154 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd152, <16 x i32> %589, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %590 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd154, ptr addrspace(4) %590, align 512
  %.esimd156 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 0, i32 8, i32 1, i16 128, i32 40)
  %591 = lshr <16 x i32> %.esimd156, %57
  %592 = shl <16 x i32> %.esimd146, %56
  %593 = or <16 x i32> %592, %591
  %594 = bitcast <16 x i32> %593 to <32 x i16>
  %.esimd157 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %594, i32 0, i32 16, i32 2, i16 2, i32 0)
  %595 = zext <16 x i16> %.esimd157 to <16 x i32>
  %596 = mul <16 x i32> %595, splat (i32 -2082680531)
  %.esimd158 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd150, <16 x i32> %596, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %597 = lshr <16 x i32> %593, splat (i32 13)
  %598 = bitcast <16 x i32> %597 to <32 x i16>
  %.esimd159 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %598, i32 0, i32 16, i32 2, i16 0, i32 0)
  %599 = zext <16 x i16> %.esimd159 to <16 x i32>
  %600 = mul <16 x i32> %599, splat (i32 -2082680531)
  %.esimd160 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd158, <16 x i32> %600, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %601 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd160, ptr addrspace(4) %601, align 512
  %602 = lshr <16 x i32> %593, splat (i32 10)
  %603 = bitcast <16 x i32> %602 to <32 x i16>
  %.esimd161 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %603, i32 0, i32 16, i32 2, i16 0, i32 0)
  %604 = zext <16 x i16> %.esimd161 to <16 x i32>
  %605 = mul <16 x i32> %604, splat (i32 -2082680531)
  %.esimd162 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd154, <16 x i32> %605, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %606 = lshr <16 x i32> %593, splat (i32 7)
  %607 = bitcast <16 x i32> %606 to <32 x i16>
  %.esimd163 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %607, i32 0, i32 16, i32 2, i16 0, i32 0)
  %608 = zext <16 x i16> %.esimd163 to <16 x i32>
  %609 = mul <16 x i32> %608, splat (i32 -2082680531)
  %.esimd164 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd162, <16 x i32> %609, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %610 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd164, ptr addrspace(4) %610, align 512
  %.esimd165 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd134, i32 8, i32 8, i32 1, i16 96, i32 40)
  %611 = lshr <16 x i32> %.esimd156, %59
  %612 = shl <16 x i32> %.esimd165, %58
  %613 = or <16 x i32> %612, %611
  %614 = bitcast <16 x i32> %613 to <32 x i16>
  %.esimd167 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %614, i32 0, i32 16, i32 2, i16 2, i32 0)
  %615 = zext <16 x i16> %.esimd167 to <16 x i32>
  %616 = mul <16 x i32> %615, splat (i32 -2082680531)
  %.esimd168 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd160, <16 x i32> %616, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %617 = lshr <16 x i32> %613, splat (i32 13)
  %618 = bitcast <16 x i32> %617 to <32 x i16>
  %.esimd169 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %618, i32 0, i32 16, i32 2, i16 0, i32 0)
  %619 = zext <16 x i16> %.esimd169 to <16 x i32>
  %620 = mul <16 x i32> %619, splat (i32 -2082680531)
  %.esimd170 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd168, <16 x i32> %620, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %621 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd170, ptr addrspace(4) %621, align 512
  %622 = lshr <16 x i32> %613, splat (i32 10)
  %623 = bitcast <16 x i32> %622 to <32 x i16>
  %.esimd171 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %623, i32 0, i32 16, i32 2, i16 0, i32 0)
  %624 = zext <16 x i16> %.esimd171 to <16 x i32>
  %625 = mul <16 x i32> %624, splat (i32 -2082680531)
  %.esimd172 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd164, <16 x i32> %625, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %626 = lshr <16 x i32> %613, splat (i32 7)
  %627 = bitcast <16 x i32> %626 to <32 x i16>
  %.esimd173 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %627, i32 0, i32 16, i32 2, i16 0, i32 0)
  %628 = zext <16 x i16> %.esimd173 to <16 x i32>
  %629 = mul <16 x i32> %628, splat (i32 -2082680531)
  %.esimd174 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd172, <16 x i32> %629, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %630 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd174, ptr addrspace(4) %630, align 512
  %631 = bitcast ptr addrspace(4) %531 to ptr addrspace(4)
  %632 = load <128 x i32>, ptr addrspace(4) %631, align 16
  %.esimd175 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01427.0, <128 x i32> %632, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %633 = getelementptr inbounds i32, ptr addrspace(4) %531, i64 128
  %634 = bitcast ptr addrspace(4) %633 to ptr addrspace(4)
  %635 = load <128 x i32>, ptr addrspace(4) %634, align 16
  %.esimd176 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd175, <128 x i32> %635, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  br label %636

636:                                              ; preds = %645, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2
  %637 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit2 ], [ %646, %645 ]
  %638 = icmp ult i32 %637, 2
  br i1 %638, label %639, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit7

639:                                              ; preds = %636
  %640 = shl nuw nsw i32 %637, 7, !spirv.Decorations !17
  %641 = zext i32 %637 to i64
  br label %642

642:                                              ; preds = %647, %639
  %643 = phi i32 [ %660, %647 ], [ 0, %639 ]
  %644 = icmp ult i32 %643, 2
  br i1 %644, label %647, label %645

645:                                              ; preds = %642
  %646 = add nuw nsw i32 %637, 1, !spirv.Decorations !17
  br label %636, !llvm.loop !32

647:                                              ; preds = %642
  %648 = shl nuw nsw i32 %643, 6, !spirv.Decorations !17
  %649 = or i32 %640, %648
  %650 = trunc i32 %649 to i16
  %651 = shl nuw nsw i16 %650, 2, !spirv.Decorations !17
  %.esimd177 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd176, i32 0, i32 64, i32 1, i16 %651, i32 0)
  %652 = zext i32 %643 to i64
  %653 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %24, i64 0, i64 %652
  %654 = bitcast ptr addrspace(4) %653 to ptr addrspace(4)
  %655 = load <128 x i32>, ptr addrspace(4) %654, align 512
  %656 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %641
  %657 = bitcast ptr addrspace(4) %656 to ptr addrspace(4)
  %658 = load <128 x i32>, ptr addrspace(4) %657, align 512
  %.esimd178 = call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %655, <128 x i32> %658, <64 x i32> %.esimd177, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %659 = bitcast ptr addrspace(4) %653 to ptr addrspace(4)
  store <128 x i32> %.esimd178, ptr addrspace(4) %659, align 512
  %660 = add nuw nsw i32 %643, 1, !spirv.Decorations !17
  br label %642, !llvm.loop !33

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit7: ; preds = %636
  %661 = getelementptr inbounds i32, ptr addrspace(4) %531, i64 256
  %662 = add nsw i32 %533, 1, !spirv.Decorations !15
  %663 = icmp eq i32 %662, %8
  br i1 %663, label %667, label %664

664:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit7
  %665 = add nuw nsw i32 %128, 3, !spirv.Decorations !17
  %666 = icmp slt i32 %665, %8
  br i1 %666, label %708, label %1087

667:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit7
  %668 = add nsw i32 %43, %532, !spirv.Decorations !15
  %669 = sext i32 %45 to i64
  %670 = shl nsw i64 %669, 1, !spirv.Decorations !15
  %671 = or i64 %670, %47
  %672 = sext i32 %12 to i64
  %673 = mul i64 %671, %672
  %674 = sext i32 %668 to i64
  %675 = add i64 %673, %674
  %676 = shl i64 %675, 4
  %677 = sext i32 %13 to i64
  %678 = mul i64 %676, %677
  %679 = getelementptr inbounds i32, ptr addrspace(4) %40, i64 %678
  %680 = shl nsw i64 %72, 4, !spirv.Decorations !15
  %681 = getelementptr inbounds i32, ptr addrspace(4) %679, i64 %680
  br label %682

682:                                              ; preds = %691, %667
  %683 = phi i32 [ 0, %667 ], [ %692, %691 ]
  %684 = icmp ult i32 %683, 2
  br i1 %684, label %685, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11

685:                                              ; preds = %682
  %686 = zext i32 %683 to i64
  %687 = shl nuw nsw i32 %683, 3, !spirv.Decorations !17
  br label %688

688:                                              ; preds = %693, %685
  %689 = phi i32 [ %704, %693 ], [ 0, %685 ]
  %690 = icmp ult i32 %689, 8
  br i1 %690, label %693, label %691

691:                                              ; preds = %688
  %692 = add nuw nsw i32 %683, 1, !spirv.Decorations !17
  br label %682, !llvm.loop !34

693:                                              ; preds = %688
  %694 = trunc i32 %689 to i16
  %695 = shl nuw nsw i16 %694, 6, !spirv.Decorations !17
  %696 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %24, i64 0, i64 %686
  %697 = bitcast ptr addrspace(4) %696 to ptr addrspace(4)
  %698 = load <128 x i32>, ptr addrspace(4) %697, align 512
  %.esimd179 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %698, i32 0, i32 16, i32 1, i16 %695, i32 0)
  %699 = or i32 %687, %689
  %700 = sext i32 %699 to i64
  %701 = mul nsw i64 %700, %677, !spirv.Decorations !15
  %702 = getelementptr inbounds i32, ptr addrspace(4) %681, i64 %701
  %703 = bitcast ptr addrspace(4) %702 to ptr addrspace(4)
  store <16 x i32> %.esimd179, ptr addrspace(4) %703, align 16
  %704 = add nuw nsw i32 %689, 1, !spirv.Decorations !17
  br label %688, !llvm.loop !35

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11: ; preds = %682
  %705 = add nsw i32 %532, 1, !spirv.Decorations !15
  %706 = add nuw nsw i32 %128, 3, !spirv.Decorations !17
  %707 = icmp slt i32 %706, %8
  br i1 %707, label %710, label %1087

708:                                              ; preds = %664
  %709 = icmp eq i32 %662, 0
  br i1 %709, label %710, label %722

710:                                              ; preds = %708, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11
  %711 = phi ptr addrspace(4) [ %661, %708 ], [ %91, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ]
  %712 = phi i32 [ %532, %708 ], [ %705, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ]
  br label %713

713:                                              ; preds = %716, %710
  %714 = phi i32 [ %721, %716 ], [ 0, %710 ]
  %715 = icmp ult i32 %714, 2
  br i1 %715, label %716, label %.loopexit1

716:                                              ; preds = %713
  %717 = zext i32 %714 to i64
  %718 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr %20, i64 0, i64 %717
  %719 = addrspacecast ptr %718 to ptr addrspace(4)
  %720 = bitcast ptr addrspace(4) %719 to ptr addrspace(4)
  store <128 x i32> zeroinitializer, ptr addrspace(4) %720, align 512
  %721 = add nuw nsw i32 %714, 1, !spirv.Decorations !17
  br label %713, !llvm.loop !36

.loopexit1:                                       ; preds = %713
  br label %722

722:                                              ; preds = %.loopexit1, %708
  %723 = phi ptr addrspace(4) [ %661, %708 ], [ %711, %.loopexit1 ]
  %724 = phi i32 [ %532, %708 ], [ %712, %.loopexit1 ]
  %725 = phi i32 [ %662, %708 ], [ 0, %.loopexit1 ]
  %726 = icmp sgt i32 %.5, 0
  br i1 %726, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1, label %727

727:                                              ; preds = %722
  %728 = bitcast ptr addrspace(4) %.51615 to ptr addrspace(4)
  %729 = load <16 x i32>, ptr addrspace(4) %728, align 16
  %.esimd180 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0454.0, <16 x i32> %729, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %730 = getelementptr inbounds i32, ptr addrspace(4) %.51615, i64 16
  %731 = bitcast ptr addrspace(4) %730 to ptr addrspace(4)
  %732 = load <8 x i32>, ptr addrspace(4) %731, align 16
  %.esimd181 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd180, <8 x i32> %732, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd182 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd134, <24 x i32> %.esimd181, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd182, ptr addrspace(4) %549, align 256
  %733 = add nsw i32 %.51624, 1, !spirv.Decorations !15
  %734 = icmp eq i32 %733, %8
  br i1 %734, label %735, label %738

735:                                              ; preds = %727
  %736 = add nsw i32 %.5, 1, !spirv.Decorations !15
  %737 = getelementptr inbounds i32, ptr addrspace(4) %.51615, i64 %69
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1

738:                                              ; preds = %727
  %739 = getelementptr inbounds i32, ptr addrspace(4) %.51615, i64 %62
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1: ; preds = %738, %735, %722
  %.41623 = phi i32 [ %.51624, %722 ], [ 0, %735 ], [ %733, %738 ]
  %.41614 = phi ptr addrspace(4) [ %.51615, %722 ], [ %737, %735 ], [ %739, %738 ]
  %.4 = phi i32 [ %.5, %722 ], [ %736, %735 ], [ %.5, %738 ]
  %.sroa.0454.2 = phi <24 x i32> [ %.sroa.0454.0, %722 ], [ %.esimd181, %735 ], [ %.esimd181, %738 ]
  %740 = bitcast ptr addrspace(4) %101 to ptr addrspace(4)
  %741 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %740, i64 0, i32 0
  %742 = load <40 x i32>, ptr addrspace(4) %741, align 256
  %.esimd183 = call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %742, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd184 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %742, <7 x i32> %.esimd183, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd185 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd184, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd186 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd184, <1 x i32> %.esimd185, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  store <40 x i32> %.esimd186, ptr addrspace(4) %741, align 256
  %.esimd187 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd188 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 64, i32 40)
  %743 = lshr <16 x i32> %.esimd188, %53
  %744 = shl <16 x i32> %.esimd187, %52
  %745 = or <16 x i32> %744, %743
  %746 = bitcast <16 x i32> %745 to <32 x i16>
  %.esimd189 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %746, i32 0, i32 16, i32 2, i16 2, i32 0)
  %747 = zext <16 x i16> %.esimd189 to <16 x i32>
  %748 = mul <16 x i32> %747, splat (i32 -2082680531)
  %.esimd190 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd170, <16 x i32> %748, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %749 = lshr <16 x i32> %745, splat (i32 13)
  %750 = bitcast <16 x i32> %749 to <32 x i16>
  %.esimd191 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %750, i32 0, i32 16, i32 2, i16 0, i32 0)
  %751 = zext <16 x i16> %.esimd191 to <16 x i32>
  %752 = mul <16 x i32> %751, splat (i32 -2082680531)
  %.esimd192 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd190, <16 x i32> %752, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %753 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd192, ptr addrspace(4) %753, align 512
  %754 = lshr <16 x i32> %745, splat (i32 10)
  %755 = bitcast <16 x i32> %754 to <32 x i16>
  %.esimd193 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %755, i32 0, i32 16, i32 2, i16 0, i32 0)
  %756 = zext <16 x i16> %.esimd193 to <16 x i32>
  %757 = mul <16 x i32> %756, splat (i32 -2082680531)
  %.esimd194 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd174, <16 x i32> %757, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %758 = lshr <16 x i32> %745, splat (i32 7)
  %759 = bitcast <16 x i32> %758 to <32 x i16>
  %.esimd195 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %759, i32 0, i32 16, i32 2, i16 0, i32 0)
  %760 = zext <16 x i16> %.esimd195 to <16 x i32>
  %761 = mul <16 x i32> %760, splat (i32 -2082680531)
  %.esimd196 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd194, <16 x i32> %761, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %762 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd196, ptr addrspace(4) %762, align 512
  %.esimd198 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 96, i32 40)
  %763 = lshr <16 x i32> %.esimd198, %55
  %764 = shl <16 x i32> %.esimd188, %54
  %765 = or <16 x i32> %764, %763
  %766 = bitcast <16 x i32> %765 to <32 x i16>
  %.esimd199 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %766, i32 0, i32 16, i32 2, i16 2, i32 0)
  %767 = zext <16 x i16> %.esimd199 to <16 x i32>
  %768 = mul <16 x i32> %767, splat (i32 -2082680531)
  %.esimd200 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd192, <16 x i32> %768, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %769 = lshr <16 x i32> %765, splat (i32 13)
  %770 = bitcast <16 x i32> %769 to <32 x i16>
  %.esimd201 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %770, i32 0, i32 16, i32 2, i16 0, i32 0)
  %771 = zext <16 x i16> %.esimd201 to <16 x i32>
  %772 = mul <16 x i32> %771, splat (i32 -2082680531)
  %.esimd202 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd200, <16 x i32> %772, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %773 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd202, ptr addrspace(4) %773, align 512
  %774 = lshr <16 x i32> %765, splat (i32 10)
  %775 = bitcast <16 x i32> %774 to <32 x i16>
  %.esimd203 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %775, i32 0, i32 16, i32 2, i16 0, i32 0)
  %776 = zext <16 x i16> %.esimd203 to <16 x i32>
  %777 = mul <16 x i32> %776, splat (i32 -2082680531)
  %.esimd204 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd196, <16 x i32> %777, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %778 = lshr <16 x i32> %765, splat (i32 7)
  %779 = bitcast <16 x i32> %778 to <32 x i16>
  %.esimd205 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %779, i32 0, i32 16, i32 2, i16 0, i32 0)
  %780 = zext <16 x i16> %.esimd205 to <16 x i32>
  %781 = mul <16 x i32> %780, splat (i32 -2082680531)
  %.esimd206 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd204, <16 x i32> %781, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %782 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd206, ptr addrspace(4) %782, align 512
  %.esimd208 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 0, i32 8, i32 1, i16 128, i32 40)
  %783 = lshr <16 x i32> %.esimd208, %57
  %784 = shl <16 x i32> %.esimd198, %56
  %785 = or <16 x i32> %784, %783
  %786 = bitcast <16 x i32> %785 to <32 x i16>
  %.esimd209 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %786, i32 0, i32 16, i32 2, i16 2, i32 0)
  %787 = zext <16 x i16> %.esimd209 to <16 x i32>
  %788 = mul <16 x i32> %787, splat (i32 -2082680531)
  %.esimd210 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd202, <16 x i32> %788, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %789 = lshr <16 x i32> %785, splat (i32 13)
  %790 = bitcast <16 x i32> %789 to <32 x i16>
  %.esimd211 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %790, i32 0, i32 16, i32 2, i16 0, i32 0)
  %791 = zext <16 x i16> %.esimd211 to <16 x i32>
  %792 = mul <16 x i32> %791, splat (i32 -2082680531)
  %.esimd212 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd210, <16 x i32> %792, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %793 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd212, ptr addrspace(4) %793, align 512
  %794 = lshr <16 x i32> %785, splat (i32 10)
  %795 = bitcast <16 x i32> %794 to <32 x i16>
  %.esimd213 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %795, i32 0, i32 16, i32 2, i16 0, i32 0)
  %796 = zext <16 x i16> %.esimd213 to <16 x i32>
  %797 = mul <16 x i32> %796, splat (i32 -2082680531)
  %.esimd214 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd206, <16 x i32> %797, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %798 = lshr <16 x i32> %785, splat (i32 7)
  %799 = bitcast <16 x i32> %798 to <32 x i16>
  %.esimd215 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %799, i32 0, i32 16, i32 2, i16 0, i32 0)
  %800 = zext <16 x i16> %.esimd215 to <16 x i32>
  %801 = mul <16 x i32> %800, splat (i32 -2082680531)
  %.esimd216 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd214, <16 x i32> %801, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %802 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd216, ptr addrspace(4) %802, align 512
  %.esimd217 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd186, i32 8, i32 8, i32 1, i16 96, i32 40)
  %803 = lshr <16 x i32> %.esimd208, %59
  %804 = shl <16 x i32> %.esimd217, %58
  %805 = or <16 x i32> %804, %803
  %806 = bitcast <16 x i32> %805 to <32 x i16>
  %.esimd219 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %806, i32 0, i32 16, i32 2, i16 2, i32 0)
  %807 = zext <16 x i16> %.esimd219 to <16 x i32>
  %808 = mul <16 x i32> %807, splat (i32 -2082680531)
  %.esimd220 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd212, <16 x i32> %808, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %809 = lshr <16 x i32> %805, splat (i32 13)
  %810 = bitcast <16 x i32> %809 to <32 x i16>
  %.esimd221 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %810, i32 0, i32 16, i32 2, i16 0, i32 0)
  %811 = zext <16 x i16> %.esimd221 to <16 x i32>
  %812 = mul <16 x i32> %811, splat (i32 -2082680531)
  %.esimd222 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd220, <16 x i32> %812, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %813 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd222, ptr addrspace(4) %813, align 512
  %814 = lshr <16 x i32> %805, splat (i32 10)
  %815 = bitcast <16 x i32> %814 to <32 x i16>
  %.esimd223 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %815, i32 0, i32 16, i32 2, i16 0, i32 0)
  %816 = zext <16 x i16> %.esimd223 to <16 x i32>
  %817 = mul <16 x i32> %816, splat (i32 -2082680531)
  %.esimd224 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd216, <16 x i32> %817, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %818 = lshr <16 x i32> %805, splat (i32 7)
  %819 = bitcast <16 x i32> %818 to <32 x i16>
  %.esimd225 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %819, i32 0, i32 16, i32 2, i16 0, i32 0)
  %820 = zext <16 x i16> %.esimd225 to <16 x i32>
  %821 = mul <16 x i32> %820, splat (i32 -2082680531)
  %.esimd226 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd224, <16 x i32> %821, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %822 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd226, ptr addrspace(4) %822, align 512
  %823 = bitcast ptr addrspace(4) %723 to ptr addrspace(4)
  %824 = load <128 x i32>, ptr addrspace(4) %823, align 16
  %.esimd227 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01415.0, <128 x i32> %824, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %825 = getelementptr inbounds i32, ptr addrspace(4) %723, i64 128
  %826 = bitcast ptr addrspace(4) %825 to ptr addrspace(4)
  %827 = load <128 x i32>, ptr addrspace(4) %826, align 16
  %.esimd228 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd227, <128 x i32> %827, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  br label %828

828:                                              ; preds = %837, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1
  %829 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit1 ], [ %838, %837 ]
  %830 = icmp ult i32 %829, 2
  br i1 %830, label %831, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit6

831:                                              ; preds = %828
  %832 = shl nuw nsw i32 %829, 7, !spirv.Decorations !17
  %833 = zext i32 %829 to i64
  br label %834

834:                                              ; preds = %839, %831
  %835 = phi i32 [ %852, %839 ], [ 0, %831 ]
  %836 = icmp ult i32 %835, 2
  br i1 %836, label %839, label %837

837:                                              ; preds = %834
  %838 = add nuw nsw i32 %829, 1, !spirv.Decorations !17
  br label %828, !llvm.loop !37

839:                                              ; preds = %834
  %840 = shl nuw nsw i32 %835, 6, !spirv.Decorations !17
  %841 = or i32 %832, %840
  %842 = trunc i32 %841 to i16
  %843 = shl nuw nsw i16 %842, 2, !spirv.Decorations !17
  %.esimd229 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd228, i32 0, i32 64, i32 1, i16 %843, i32 0)
  %844 = zext i32 %835 to i64
  %845 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %24, i64 0, i64 %844
  %846 = bitcast ptr addrspace(4) %845 to ptr addrspace(4)
  %847 = load <128 x i32>, ptr addrspace(4) %846, align 512
  %848 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %833
  %849 = bitcast ptr addrspace(4) %848 to ptr addrspace(4)
  %850 = load <128 x i32>, ptr addrspace(4) %849, align 512
  %.esimd230 = call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %847, <128 x i32> %850, <64 x i32> %.esimd229, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %851 = bitcast ptr addrspace(4) %845 to ptr addrspace(4)
  store <128 x i32> %.esimd230, ptr addrspace(4) %851, align 512
  %852 = add nuw nsw i32 %835, 1, !spirv.Decorations !17
  br label %834, !llvm.loop !38

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit6: ; preds = %828
  %853 = getelementptr inbounds i32, ptr addrspace(4) %723, i64 256
  %854 = add nsw i32 %725, 1, !spirv.Decorations !15
  %855 = icmp eq i32 %854, %8
  br i1 %855, label %859, label %856

856:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit6
  %857 = add nuw nsw i32 %128, 4, !spirv.Decorations !17
  %858 = icmp slt i32 %857, %8
  br i1 %858, label %900, label %1087

859:                                              ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit6
  %860 = add nsw i32 %43, %724, !spirv.Decorations !15
  %861 = sext i32 %45 to i64
  %862 = shl nsw i64 %861, 1, !spirv.Decorations !15
  %863 = or i64 %862, %47
  %864 = sext i32 %12 to i64
  %865 = mul i64 %863, %864
  %866 = sext i32 %860 to i64
  %867 = add i64 %865, %866
  %868 = shl i64 %867, 4
  %869 = sext i32 %13 to i64
  %870 = mul i64 %868, %869
  %871 = getelementptr inbounds i32, ptr addrspace(4) %40, i64 %870
  %872 = shl nsw i64 %72, 4, !spirv.Decorations !15
  %873 = getelementptr inbounds i32, ptr addrspace(4) %871, i64 %872
  br label %874

874:                                              ; preds = %883, %859
  %875 = phi i32 [ 0, %859 ], [ %884, %883 ]
  %876 = icmp ult i32 %875, 2
  br i1 %876, label %877, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10

877:                                              ; preds = %874
  %878 = zext i32 %875 to i64
  %879 = shl nuw nsw i32 %875, 3, !spirv.Decorations !17
  br label %880

880:                                              ; preds = %885, %877
  %881 = phi i32 [ %896, %885 ], [ 0, %877 ]
  %882 = icmp ult i32 %881, 8
  br i1 %882, label %885, label %883

883:                                              ; preds = %880
  %884 = add nuw nsw i32 %875, 1, !spirv.Decorations !17
  br label %874, !llvm.loop !39

885:                                              ; preds = %880
  %886 = trunc i32 %881 to i16
  %887 = shl nuw nsw i16 %886, 6, !spirv.Decorations !17
  %888 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %24, i64 0, i64 %878
  %889 = bitcast ptr addrspace(4) %888 to ptr addrspace(4)
  %890 = load <128 x i32>, ptr addrspace(4) %889, align 512
  %.esimd231 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %890, i32 0, i32 16, i32 1, i16 %887, i32 0)
  %891 = or i32 %879, %881
  %892 = sext i32 %891 to i64
  %893 = mul nsw i64 %892, %869, !spirv.Decorations !15
  %894 = getelementptr inbounds i32, ptr addrspace(4) %873, i64 %893
  %895 = bitcast ptr addrspace(4) %894 to ptr addrspace(4)
  store <16 x i32> %.esimd231, ptr addrspace(4) %895, align 16
  %896 = add nuw nsw i32 %881, 1, !spirv.Decorations !17
  br label %880, !llvm.loop !40

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10: ; preds = %874
  %897 = add nsw i32 %724, 1, !spirv.Decorations !15
  %898 = add nuw nsw i32 %128, 4, !spirv.Decorations !17
  %899 = icmp slt i32 %898, %8
  br i1 %899, label %902, label %1087

900:                                              ; preds = %856
  %901 = icmp eq i32 %854, 0
  br i1 %901, label %902, label %914

902:                                              ; preds = %900, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10
  %903 = phi ptr addrspace(4) [ %853, %900 ], [ %91, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ]
  %904 = phi i32 [ %724, %900 ], [ %897, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ]
  br label %905

905:                                              ; preds = %908, %902
  %906 = phi i32 [ %913, %908 ], [ 0, %902 ]
  %907 = icmp ult i32 %906, 2
  br i1 %907, label %908, label %.loopexit

908:                                              ; preds = %905
  %909 = zext i32 %906 to i64
  %910 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr %20, i64 0, i64 %909
  %911 = addrspacecast ptr %910 to ptr addrspace(4)
  %912 = bitcast ptr addrspace(4) %911 to ptr addrspace(4)
  store <128 x i32> zeroinitializer, ptr addrspace(4) %912, align 512
  %913 = add nuw nsw i32 %906, 1, !spirv.Decorations !17
  br label %905, !llvm.loop !41

.loopexit:                                        ; preds = %905
  br label %914

914:                                              ; preds = %.loopexit, %900
  %915 = phi ptr addrspace(4) [ %853, %900 ], [ %903, %.loopexit ]
  %916 = phi i32 [ %724, %900 ], [ %904, %.loopexit ]
  %917 = phi i32 [ %854, %900 ], [ 0, %.loopexit ]
  %918 = icmp sgt i32 %.4, 0
  br i1 %918, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit, label %919

919:                                              ; preds = %914
  %920 = bitcast ptr addrspace(4) %.41614 to ptr addrspace(4)
  %921 = load <16 x i32>, ptr addrspace(4) %920, align 16
  %.esimd232 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v16i32.i16.v16i1(<24 x i32> %.sroa.0449.0, <16 x i32> %921, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %922 = getelementptr inbounds i32, ptr addrspace(4) %.41614, i64 16
  %923 = bitcast ptr addrspace(4) %922 to ptr addrspace(4)
  %924 = load <8 x i32>, ptr addrspace(4) %923, align 16
  %.esimd233 = call <24 x i32> @llvm.genx.wrregioni.v24i32.v8i32.i16.v8i1(<24 x i32> %.esimd232, <8 x i32> %924, i32 0, i32 8, i32 1, i16 64, i32 0, <8 x i1> splat (i1 true))
  %.esimd234 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v24i32.i16.v24i1(<40 x i32> %.esimd186, <24 x i32> %.esimd233, i32 0, i32 24, i32 1, i16 64, i32 0, <24 x i1> splat (i1 true))
  store <40 x i32> %.esimd234, ptr addrspace(4) %741, align 256
  %925 = add nsw i32 %.41623, 1, !spirv.Decorations !15
  %926 = icmp eq i32 %925, %8
  br i1 %926, label %927, label %930

927:                                              ; preds = %919
  %928 = add nsw i32 %.4, 1, !spirv.Decorations !15
  %929 = getelementptr inbounds i32, ptr addrspace(4) %.41614, i64 %69
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit

930:                                              ; preds = %919
  %931 = getelementptr inbounds i32, ptr addrspace(4) %.41614, i64 %62
  br label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit: ; preds = %930, %927, %914
  %.31622 = phi i32 [ %.41623, %914 ], [ 0, %927 ], [ %925, %930 ]
  %.31613 = phi ptr addrspace(4) [ %.41614, %914 ], [ %929, %927 ], [ %931, %930 ]
  %.3 = phi i32 [ %.4, %914 ], [ %928, %927 ], [ %.4, %930 ]
  %.sroa.0449.2 = phi <24 x i32> [ %.sroa.0449.0, %914 ], [ %.esimd233, %927 ], [ %.esimd233, %930 ]
  %932 = bitcast ptr addrspace(4) %93 to ptr addrspace(4)
  %933 = getelementptr inbounds %"class.sycl::_V1::ext::intel::esimd::detail::simd_obj_impl.214.0", ptr addrspace(4) %932, i64 0, i32 0
  %934 = load <40 x i32>, ptr addrspace(4) %933, align 256
  %.esimd235 = call <7 x i32> @llvm.genx.rdregioni.v7i32.v40i32.i16(<40 x i32> %934, i32 0, i32 7, i32 1, i16 128, i32 0)
  %.esimd236 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v7i32.i16.v7i1(<40 x i32> %934, <7 x i32> %.esimd235, i32 0, i32 7, i32 1, i16 36, i32 0, <7 x i1> splat (i1 true))
  %.esimd237 = call <1 x i32> @llvm.genx.rdregioni.v1i32.v40i32.i16(<40 x i32> %.esimd236, i32 0, i32 1, i32 1, i16 156, i32 0)
  %.esimd238 = call <40 x i32> @llvm.genx.wrregioni.v40i32.v1i32.i16.v1i1(<40 x i32> %.esimd236, <1 x i32> %.esimd237, i32 0, i32 1, i32 1, i16 32, i32 0, <1 x i1> splat (i1 true))
  store <40 x i32> %.esimd238, ptr addrspace(4) %933, align 256
  %.esimd239 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 32, i32 40)
  %.esimd240 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 64, i32 40)
  %935 = lshr <16 x i32> %.esimd240, %53
  %936 = shl <16 x i32> %.esimd239, %52
  %937 = or <16 x i32> %936, %935
  %938 = bitcast <16 x i32> %937 to <32 x i16>
  %.esimd241 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %938, i32 0, i32 16, i32 2, i16 2, i32 0)
  %939 = zext <16 x i16> %.esimd241 to <16 x i32>
  %940 = mul <16 x i32> %939, splat (i32 -2082680531)
  %.esimd242 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd222, <16 x i32> %940, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %941 = lshr <16 x i32> %937, splat (i32 13)
  %942 = bitcast <16 x i32> %941 to <32 x i16>
  %.esimd243 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %942, i32 0, i32 16, i32 2, i16 0, i32 0)
  %943 = zext <16 x i16> %.esimd243 to <16 x i32>
  %944 = mul <16 x i32> %943, splat (i32 -2082680531)
  %.esimd244 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd242, <16 x i32> %944, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %945 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd244, ptr addrspace(4) %945, align 512
  %946 = lshr <16 x i32> %937, splat (i32 10)
  %947 = bitcast <16 x i32> %946 to <32 x i16>
  %.esimd245 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %947, i32 0, i32 16, i32 2, i16 0, i32 0)
  %948 = zext <16 x i16> %.esimd245 to <16 x i32>
  %949 = mul <16 x i32> %948, splat (i32 -2082680531)
  %.esimd246 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd226, <16 x i32> %949, i32 0, i32 16, i32 1, i16 0, i32 0, <16 x i1> splat (i1 true))
  %950 = lshr <16 x i32> %937, splat (i32 7)
  %951 = bitcast <16 x i32> %950 to <32 x i16>
  %.esimd247 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %951, i32 0, i32 16, i32 2, i16 0, i32 0)
  %952 = zext <16 x i16> %.esimd247 to <16 x i32>
  %953 = mul <16 x i32> %952, splat (i32 -2082680531)
  %.esimd248 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd246, <16 x i32> %953, i32 0, i32 16, i32 1, i16 64, i32 0, <16 x i1> splat (i1 true))
  %954 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd248, ptr addrspace(4) %954, align 512
  %.esimd250 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 96, i32 40)
  %955 = lshr <16 x i32> %.esimd250, %55
  %956 = shl <16 x i32> %.esimd240, %54
  %957 = or <16 x i32> %956, %955
  %958 = bitcast <16 x i32> %957 to <32 x i16>
  %.esimd251 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %958, i32 0, i32 16, i32 2, i16 2, i32 0)
  %959 = zext <16 x i16> %.esimd251 to <16 x i32>
  %960 = mul <16 x i32> %959, splat (i32 -2082680531)
  %.esimd252 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd244, <16 x i32> %960, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %961 = lshr <16 x i32> %957, splat (i32 13)
  %962 = bitcast <16 x i32> %961 to <32 x i16>
  %.esimd253 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %962, i32 0, i32 16, i32 2, i16 0, i32 0)
  %963 = zext <16 x i16> %.esimd253 to <16 x i32>
  %964 = mul <16 x i32> %963, splat (i32 -2082680531)
  %.esimd254 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd252, <16 x i32> %964, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %965 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd254, ptr addrspace(4) %965, align 512
  %966 = lshr <16 x i32> %957, splat (i32 10)
  %967 = bitcast <16 x i32> %966 to <32 x i16>
  %.esimd255 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %967, i32 0, i32 16, i32 2, i16 0, i32 0)
  %968 = zext <16 x i16> %.esimd255 to <16 x i32>
  %969 = mul <16 x i32> %968, splat (i32 -2082680531)
  %.esimd256 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd248, <16 x i32> %969, i32 0, i32 16, i32 1, i16 128, i32 0, <16 x i1> splat (i1 true))
  %970 = lshr <16 x i32> %957, splat (i32 7)
  %971 = bitcast <16 x i32> %970 to <32 x i16>
  %.esimd257 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %971, i32 0, i32 16, i32 2, i16 0, i32 0)
  %972 = zext <16 x i16> %.esimd257 to <16 x i32>
  %973 = mul <16 x i32> %972, splat (i32 -2082680531)
  %.esimd258 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd256, <16 x i32> %973, i32 0, i32 16, i32 1, i16 192, i32 0, <16 x i1> splat (i1 true))
  %974 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd258, ptr addrspace(4) %974, align 512
  %.esimd260 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 0, i32 8, i32 1, i16 128, i32 40)
  %975 = lshr <16 x i32> %.esimd260, %57
  %976 = shl <16 x i32> %.esimd250, %56
  %977 = or <16 x i32> %976, %975
  %978 = bitcast <16 x i32> %977 to <32 x i16>
  %.esimd261 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %978, i32 0, i32 16, i32 2, i16 2, i32 0)
  %979 = zext <16 x i16> %.esimd261 to <16 x i32>
  %980 = mul <16 x i32> %979, splat (i32 -2082680531)
  %.esimd262 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd254, <16 x i32> %980, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %981 = lshr <16 x i32> %977, splat (i32 13)
  %982 = bitcast <16 x i32> %981 to <32 x i16>
  %.esimd263 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %982, i32 0, i32 16, i32 2, i16 0, i32 0)
  %983 = zext <16 x i16> %.esimd263 to <16 x i32>
  %984 = mul <16 x i32> %983, splat (i32 -2082680531)
  %.esimd264 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd262, <16 x i32> %984, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %985 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd264, ptr addrspace(4) %985, align 512
  %986 = lshr <16 x i32> %977, splat (i32 10)
  %987 = bitcast <16 x i32> %986 to <32 x i16>
  %.esimd265 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %987, i32 0, i32 16, i32 2, i16 0, i32 0)
  %988 = zext <16 x i16> %.esimd265 to <16 x i32>
  %989 = mul <16 x i32> %988, splat (i32 -2082680531)
  %.esimd266 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd258, <16 x i32> %989, i32 0, i32 16, i32 1, i16 256, i32 0, <16 x i1> splat (i1 true))
  %990 = lshr <16 x i32> %977, splat (i32 7)
  %991 = bitcast <16 x i32> %990 to <32 x i16>
  %.esimd267 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %991, i32 0, i32 16, i32 2, i16 0, i32 0)
  %992 = zext <16 x i16> %.esimd267 to <16 x i32>
  %993 = mul <16 x i32> %992, splat (i32 -2082680531)
  %.esimd268 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd266, <16 x i32> %993, i32 0, i32 16, i32 1, i16 320, i32 0, <16 x i1> splat (i1 true))
  %994 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd268, ptr addrspace(4) %994, align 512
  %.esimd269 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v40i32.i16(<40 x i32> %.esimd238, i32 8, i32 8, i32 1, i16 96, i32 40)
  %995 = lshr <16 x i32> %.esimd260, %59
  %996 = shl <16 x i32> %.esimd269, %58
  %997 = or <16 x i32> %996, %995
  %998 = bitcast <16 x i32> %997 to <32 x i16>
  %.esimd271 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %998, i32 0, i32 16, i32 2, i16 2, i32 0)
  %999 = zext <16 x i16> %.esimd271 to <16 x i32>
  %1000 = mul <16 x i32> %999, splat (i32 -2082680531)
  %.esimd272 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd264, <16 x i32> %1000, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %1001 = lshr <16 x i32> %997, splat (i32 13)
  %1002 = bitcast <16 x i32> %1001 to <32 x i16>
  %.esimd273 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %1002, i32 0, i32 16, i32 2, i16 0, i32 0)
  %1003 = zext <16 x i16> %.esimd273 to <16 x i32>
  %1004 = mul <16 x i32> %1003, splat (i32 -2082680531)
  %.esimd274 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd272, <16 x i32> %1004, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %1005 = bitcast ptr addrspace(4) %23 to ptr addrspace(4)
  store <128 x i32> %.esimd274, ptr addrspace(4) %1005, align 512
  %1006 = lshr <16 x i32> %997, splat (i32 10)
  %1007 = bitcast <16 x i32> %1006 to <32 x i16>
  %.esimd275 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %1007, i32 0, i32 16, i32 2, i16 0, i32 0)
  %1008 = zext <16 x i16> %.esimd275 to <16 x i32>
  %1009 = mul <16 x i32> %1008, splat (i32 -2082680531)
  %.esimd276 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd268, <16 x i32> %1009, i32 0, i32 16, i32 1, i16 384, i32 0, <16 x i1> splat (i1 true))
  %1010 = lshr <16 x i32> %997, splat (i32 7)
  %1011 = bitcast <16 x i32> %1010 to <32 x i16>
  %.esimd277 = call <16 x i16> @llvm.genx.rdregioni.v16i16.v32i16.i16(<32 x i16> %1011, i32 0, i32 16, i32 2, i16 0, i32 0)
  %1012 = zext <16 x i16> %.esimd277 to <16 x i32>
  %1013 = mul <16 x i32> %1012, splat (i32 -2082680531)
  %.esimd278 = call <128 x i32> @llvm.genx.wrregioni.v128i32.v16i32.i16.v16i1(<128 x i32> %.esimd276, <16 x i32> %1013, i32 0, i32 16, i32 1, i16 448, i32 0, <16 x i1> splat (i1 true))
  %1014 = bitcast ptr addrspace(4) %179 to ptr addrspace(4)
  store <128 x i32> %.esimd278, ptr addrspace(4) %1014, align 512
  %1015 = bitcast ptr addrspace(4) %915 to ptr addrspace(4)
  %1016 = load <128 x i32>, ptr addrspace(4) %1015, align 16
  %.esimd279 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.sroa.01403.0, <128 x i32> %1016, i32 0, i32 128, i32 1, i16 0, i32 0, <128 x i1> splat (i1 true))
  %1017 = getelementptr inbounds i32, ptr addrspace(4) %915, i64 128
  %1018 = bitcast ptr addrspace(4) %1017 to ptr addrspace(4)
  %1019 = load <128 x i32>, ptr addrspace(4) %1018, align 16
  %.esimd280 = call <256 x i32> @llvm.genx.wrregioni.v256i32.v128i32.i16.v128i1(<256 x i32> %.esimd279, <128 x i32> %1019, i32 0, i32 128, i32 1, i16 512, i32 0, <128 x i1> splat (i1 true))
  br label %1020

1020:                                             ; preds = %1029, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit
  %1021 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlRNS4_3ext5intel5esimd4simdIjLi40EEEE_clESG_.exit ], [ %1030, %1029 ]
  %1022 = icmp ult i32 %1021, 2
  br i1 %1022, label %1023, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit

1023:                                             ; preds = %1020
  %1024 = shl nuw nsw i32 %1021, 7, !spirv.Decorations !17
  %1025 = zext i32 %1021 to i64
  br label %1026

1026:                                             ; preds = %1031, %1023
  %1027 = phi i32 [ %1044, %1031 ], [ 0, %1023 ]
  %1028 = icmp ult i32 %1027, 2
  br i1 %1028, label %1031, label %1029

1029:                                             ; preds = %1026
  %1030 = add nuw nsw i32 %1021, 1, !spirv.Decorations !17
  br label %1020, !llvm.loop !42

1031:                                             ; preds = %1026
  %1032 = shl nuw nsw i32 %1027, 6, !spirv.Decorations !17
  %1033 = or i32 %1024, %1032
  %1034 = trunc i32 %1033 to i16
  %1035 = shl nuw nsw i16 %1034, 2, !spirv.Decorations !17
  %.esimd281 = call <64 x i32> @llvm.genx.rdregioni.v64i32.v256i32.i16(<256 x i32> %.esimd280, i32 0, i32 64, i32 1, i16 %1035, i32 0)
  %1036 = zext i32 %1027 to i64
  %1037 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %24, i64 0, i64 %1036
  %1038 = bitcast ptr addrspace(4) %1037 to ptr addrspace(4)
  %1039 = load <128 x i32>, ptr addrspace(4) %1038, align 512
  %1040 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %23, i64 0, i64 %1025
  %1041 = bitcast ptr addrspace(4) %1040 to ptr addrspace(4)
  %1042 = load <128 x i32>, ptr addrspace(4) %1041, align 512
  %.esimd282 = call <128 x i32> @llvm.genx.dpas2.v128i32.v128i32.v128i32.v64i32(<128 x i32> %1039, <128 x i32> %1042, <64 x i32> %.esimd281, i32 7, i32 8, i32 8, i32 8, i32 1, i32 1)
  %1043 = bitcast ptr addrspace(4) %1037 to ptr addrspace(4)
  store <128 x i32> %.esimd282, ptr addrspace(4) %1043, align 512
  %1044 = add nuw nsw i32 %1027, 1, !spirv.Decorations !17
  br label %1026, !llvm.loop !43

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit: ; preds = %1020
  %1045 = getelementptr inbounds i32, ptr addrspace(4) %915, i64 256
  %1046 = add nsw i32 %917, 1, !spirv.Decorations !15
  %1047 = icmp eq i32 %1046, %8
  br i1 %1047, label %1048, label %1087

1048:                                             ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit
  %1049 = add nsw i32 %43, %916, !spirv.Decorations !15
  %1050 = sext i32 %45 to i64
  %1051 = shl nsw i64 %1050, 1, !spirv.Decorations !15
  %1052 = or i64 %1051, %47
  %1053 = sext i32 %12 to i64
  %1054 = mul i64 %1052, %1053
  %1055 = sext i32 %1049 to i64
  %1056 = add i64 %1054, %1055
  %1057 = shl i64 %1056, 4
  %1058 = sext i32 %13 to i64
  %1059 = mul i64 %1057, %1058
  %1060 = getelementptr inbounds i32, ptr addrspace(4) %40, i64 %1059
  %1061 = shl nsw i64 %72, 4, !spirv.Decorations !15
  %1062 = getelementptr inbounds i32, ptr addrspace(4) %1060, i64 %1061
  br label %1063

1063:                                             ; preds = %1072, %1048
  %1064 = phi i32 [ 0, %1048 ], [ %1073, %1072 ]
  %1065 = icmp ult i32 %1064, 2
  br i1 %1065, label %1066, label %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit

1066:                                             ; preds = %1063
  %1067 = zext i32 %1064 to i64
  %1068 = shl nuw nsw i32 %1064, 3, !spirv.Decorations !17
  br label %1069

1069:                                             ; preds = %1074, %1066
  %1070 = phi i32 [ %1085, %1074 ], [ 0, %1066 ]
  %1071 = icmp ult i32 %1070, 8
  br i1 %1071, label %1074, label %1072

1072:                                             ; preds = %1069
  %1073 = add nuw nsw i32 %1064, 1, !spirv.Decorations !17
  br label %1063, !llvm.loop !44

1074:                                             ; preds = %1069
  %1075 = trunc i32 %1070 to i16
  %1076 = shl nuw nsw i16 %1075, 6, !spirv.Decorations !17
  %1077 = getelementptr inbounds [2 x %"class.sycl::_V1::ext::intel::esimd::simd.5.3"], ptr addrspace(4) %24, i64 0, i64 %1067
  %1078 = bitcast ptr addrspace(4) %1077 to ptr addrspace(4)
  %1079 = load <128 x i32>, ptr addrspace(4) %1078, align 512
  %.esimd283 = call <16 x i32> @llvm.genx.rdregioni.v16i32.v128i32.i16(<128 x i32> %1079, i32 0, i32 16, i32 1, i16 %1076, i32 0)
  %1080 = or i32 %1068, %1070
  %1081 = sext i32 %1080 to i64
  %1082 = mul nsw i64 %1081, %1058, !spirv.Decorations !15
  %1083 = getelementptr inbounds i32, ptr addrspace(4) %1062, i64 %1082
  %1084 = bitcast ptr addrspace(4) %1083 to ptr addrspace(4)
  store <16 x i32> %.esimd283, ptr addrspace(4) %1084, align 16
  %1085 = add nuw nsw i32 %1070, 1, !spirv.Decorations !17
  br label %1069, !llvm.loop !45

_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit: ; preds = %1063
  %1086 = add nsw i32 %916, 1, !spirv.Decorations !15
  br label %1087

1087:                                             ; preds = %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10, %856, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11, %664, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12, %472, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13, %280
  %.21621 = phi i32 [ %.31622, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.31622, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.41623, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.41623, %856 ], [ %.51624, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.51624, %664 ], [ %.61625, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.61625, %472 ], [ %.71626, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.71626, %280 ]
  %.21612 = phi ptr addrspace(4) [ %.31613, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.31613, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.41614, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.41614, %856 ], [ %.51615, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.51615, %664 ], [ %.61616, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.61616, %472 ], [ %.71617, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.71617, %280 ]
  %.2 = phi i32 [ %.3, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.3, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.4, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.4, %856 ], [ %.5, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.5, %664 ], [ %.6, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.6, %472 ], [ %.7, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.7, %280 ]
  %.sroa.0449.1 = phi <24 x i32> [ %.sroa.0449.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0449.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.sroa.0449.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0449.0, %856 ], [ %.sroa.0449.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0449.0, %664 ], [ %.sroa.0449.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0449.0, %472 ], [ %.sroa.0449.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0449.0, %280 ]
  %.sroa.0454.1 = phi <24 x i32> [ %.sroa.0454.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0454.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.sroa.0454.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0454.2, %856 ], [ %.sroa.0454.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0454.0, %664 ], [ %.sroa.0454.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0454.0, %472 ], [ %.sroa.0454.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0454.0, %280 ]
  %.sroa.0460.1 = phi <24 x i32> [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0460.2, %856 ], [ %.sroa.0460.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0460.2, %664 ], [ %.sroa.0460.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0460.0, %472 ], [ %.sroa.0460.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0460.0, %280 ]
  %.sroa.0466.1 = phi <24 x i32> [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.0466.2, %856 ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.0466.2, %664 ], [ %.sroa.0466.2, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.0466.2, %472 ], [ %.sroa.0466.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.0466.0, %280 ]
  %.sroa.01403.1 = phi <256 x i32> [ %.esimd280, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd280, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.sroa.01403.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.sroa.01403.0, %856 ], [ %.sroa.01403.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.01403.0, %664 ], [ %.sroa.01403.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.01403.0, %472 ], [ %.sroa.01403.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01403.0, %280 ]
  %.sroa.01415.1 = phi <256 x i32> [ %.esimd228, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd228, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.esimd228, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd228, %856 ], [ %.sroa.01415.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.sroa.01415.0, %664 ], [ %.sroa.01415.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.01415.0, %472 ], [ %.sroa.01415.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01415.0, %280 ]
  %.sroa.01427.1 = phi <256 x i32> [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd176, %856 ], [ %.esimd176, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd176, %664 ], [ %.sroa.01427.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.sroa.01427.0, %472 ], [ %.sroa.01427.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01427.0, %280 ]
  %.sroa.01439.1 = phi <256 x i32> [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %.esimd124, %856 ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %.esimd124, %664 ], [ %.esimd124, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %.esimd124, %472 ], [ %.sroa.01439.0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %.sroa.01439.0, %280 ]
  %1088 = phi ptr addrspace(4) [ %91, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %1045, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %91, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %853, %856 ], [ %91, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %661, %664 ], [ %91, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %469, %472 ], [ %91, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %277, %280 ]
  %1089 = phi i32 [ %1086, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %916, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ %897, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %724, %856 ], [ %705, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %532, %664 ], [ %513, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %340, %472 ], [ %321, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %126, %280 ]
  %1090 = phi i32 [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit ], [ %1046, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUlPKjE_clESC_.exit ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit10 ], [ %854, %856 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit11 ], [ %662, %664 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit12 ], [ %470, %472 ], [ 0, %_ZZZZL6submitILi3ELi8ELi2ELi0EEvRK6LaunchENKUlRN4sycl3_V17handlerEE_clES6_ENKUlNS4_7nd_itemILi1EEEE_clES9_ENKUliE_clEi.exit13 ], [ %278, %280 ]
  %1091 = add nuw nsw i32 %128, 5, !spirv.Decorations !17
  br label %124

1092:                                             ; preds = %124
  %1093 = bitcast ptr %20 to ptr
  call void @llvm.lifetime.end.p0(ptr %20)
  %1094 = bitcast ptr %19 to ptr
  call void @llvm.lifetime.end.p0(ptr %19)
  %1095 = bitcast ptr %18 to ptr
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
declare spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32) #4

attributes #0 = { "VCFunction" }
attributes #1 = { nounwind "VCFunction" "VCNamedBarrierCount"="0" "VCSLMSize"="0" }
attributes #2 = { nocallback nofree nosync nounwind willreturn memory(argmem: readwrite) }
attributes #3 = { nocallback nofree nounwind willreturn memory(argmem: readwrite) }
attributes #4 = { nounwind willreturn memory(none) }

!spirv.MemoryModel = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!spirv.Source = !{!1}
!opencl.spir.version = !{!2}
!opencl.used.extensions = !{!3}
!opencl.used.optional.core.features = !{!3}
!spirv.Generator = !{!4}

!0 = !{i32 2, i32 2}
!1 = !{i32 0, i32 100000}
!2 = !{i32 1, i32 2}
!3 = !{}
!4 = !{i16 6, i16 14}
!5 = !{!6, !6, !8, !8, !8, !8, !6, !6, !6, !6, !6, !6, !6, !6, !8, !6, !6}
!6 = !{!7}
!7 = !{i32 5625, i32 0}
!8 = !{!9, !7}
!9 = !{i32 44, i32 4}
!10 = !{i32 1}
!11 = !{!12}
!12 = !{i32 44, i32 256}
!13 = !{!14}
!14 = !{i32 44, i32 512}
!15 = !{!16}
!16 = !{i32 4469}
!17 = !{!16, !18}
!18 = !{i32 4470}
!19 = distinct !{!19, !20}
!20 = !{!"llvm.loop.unroll.enable"}
!21 = distinct !{!21, !20}
!22 = distinct !{!22, !20}
!23 = distinct !{!23, !20}
!24 = distinct !{!24, !20}
!25 = distinct !{!25, !20}
!26 = distinct !{!26, !20}
!27 = distinct !{!27, !20}
!28 = distinct !{!28, !20}
!29 = distinct !{!29, !20}
!30 = distinct !{!30, !20}
!31 = distinct !{!31, !20}
!32 = distinct !{!32, !20}
!33 = distinct !{!33, !20}
!34 = distinct !{!34, !20}
!35 = distinct !{!35, !20}
!36 = distinct !{!36, !20}
!37 = distinct !{!37, !20}
!38 = distinct !{!38, !20}
!39 = distinct !{!39, !20}
!40 = distinct !{!40, !20}
!41 = distinct !{!41, !20}
!42 = distinct !{!42, !20}
!43 = distinct !{!43, !20}
!44 = distinct !{!44, !20}
!45 = distinct !{!45, !20}

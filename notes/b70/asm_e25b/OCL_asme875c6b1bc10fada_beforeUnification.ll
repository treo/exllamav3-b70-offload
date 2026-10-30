; ------------------------------------------------
; OCL_asme875c6b1bc10fada_beforeUnification.ll
; ------------------------------------------------
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024"
target triple = "spir64-unknown-unknown"

%"class.sycl::_V1::range" = type { %"class.sycl::_V1::detail::array" }
%"class.sycl::_V1::detail::array" = type { [1 x i64] }
%class._ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_ = type { i32, ptr addrspace(4), ptr addrspace(4), ptr addrspace(4), ptr addrspace(4) }
%structtype = type { i32, i64, i64, i64, i64 }
%class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_ = type { i64, ptr addrspace(4), ptr addrspace(4), ptr addrspace(4), ptr addrspace(4), i32, ptr addrspace(4), ptr addrspace(4) }
%structtype.0 = type { i64, i64, i64, i64, i64, i32, i64, i64 }

; Function Attrs: nounwind
define spir_kernel void @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL5splitRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE(ptr byval(%"class.sycl::_V1::range") align 8 %0, ptr byval(%class._ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_) align 8 %1) #0 !kernel_arg_addr_space !294 !kernel_arg_access_qual !295 !kernel_arg_type !296 !kernel_arg_type_qual !297 !kernel_arg_base_type !296 !kernel_arg_name !297 !spirv.ParameterDecorations !298 {
  %3 = bitcast ptr %0 to ptr
  %4 = load i64, ptr %3, align 8
  %5 = bitcast ptr %1 to ptr
  %6 = getelementptr inbounds %structtype, ptr %5, i64 0, i32 0
  %7 = load i32, ptr %6, align 4
  %8 = bitcast ptr %1 to ptr
  %9 = getelementptr inbounds %structtype, ptr %8, i64 0, i32 1
  %10 = load i64, ptr %9, align 8
  %11 = inttoptr i64 %10 to ptr addrspace(4)
  %12 = bitcast ptr %1 to ptr
  %13 = getelementptr inbounds %structtype, ptr %12, i64 0, i32 2
  %14 = load i64, ptr %13, align 8
  %15 = inttoptr i64 %14 to ptr addrspace(4)
  %16 = bitcast ptr %1 to ptr
  %17 = getelementptr inbounds %structtype, ptr %16, i64 0, i32 3
  %18 = load i64, ptr %17, align 8
  %19 = inttoptr i64 %18 to ptr addrspace(4)
  %20 = bitcast ptr %1 to ptr
  %21 = getelementptr inbounds %structtype, ptr %20, i64 0, i32 4
  %22 = load i64, ptr %21, align 8
  %23 = inttoptr i64 %22 to ptr addrspace(4)
  %24 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 0) #2
  %25 = insertelement <3 x i64> poison, i64 %24, i32 0
  %26 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 1) #2
  %27 = insertelement <3 x i64> %25, i64 %26, i32 1
  %28 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 2) #2
  %29 = insertelement <3 x i64> %27, i64 %28, i32 2
  %30 = extractelement <3 x i64> %29, i32 0
  %31 = select i1 true, i64 %30, i64 0
  %32 = call spir_func i64 @_Z25__spirv_BuiltInGlobalSizei(i32 0) #2
  %33 = insertelement <3 x i64> poison, i64 %32, i32 0
  %34 = call spir_func i64 @_Z25__spirv_BuiltInGlobalSizei(i32 1) #2
  %35 = insertelement <3 x i64> %33, i64 %34, i32 1
  %36 = call spir_func i64 @_Z25__spirv_BuiltInGlobalSizei(i32 2) #2
  %37 = insertelement <3 x i64> %35, i64 %36, i32 2
  %38 = extractelement <3 x i64> %37, i32 0
  %39 = select i1 true, i64 %38, i64 1
  %40 = icmp ult i64 %31, %4
  %41 = sext i32 %7 to i64
  %42 = mul nsw i64 %41, 640, !spirv.Decorations !302
  br label %43

43:                                               ; preds = %72, %2
  %44 = phi i64 [ %31, %2 ], [ %86, %72 ]
  %45 = phi i1 [ %40, %2 ], [ %85, %72 ]
  br i1 %45, label %46, label %87

46:                                               ; preds = %43
  %47 = icmp ult i64 %44, 2147483648
  call void @llvm.assume(i1 %47)
  %48 = udiv i64 %44, %42
  %49 = trunc i64 %44 to i32
  %50 = udiv i32 %49, 640
  %51 = zext i32 %50 to i64
  %52 = urem i64 %51, %41
  %53 = mul i32 %50, 640
  %54 = sub i32 %49, %53
  %55 = zext i32 %54 to i64
  %56 = getelementptr i32, ptr addrspace(4) %11, i64 %55
  br label %57

57:                                               ; preds = %61, %46
  %58 = phi i32 [ 0, %46 ], [ %70, %61 ]
  %59 = phi i32 [ 0, %46 ], [ %71, %61 ]
  %60 = icmp ult i32 %59, 2
  br i1 %60, label %61, label %72

61:                                               ; preds = %57
  %62 = mul nuw nsw i32 %59, 10, !spirv.Decorations !304
  %63 = zext i32 %62 to i64
  %64 = add nuw nsw i64 %48, %63, !spirv.Decorations !304
  %65 = shl nuw nsw i64 %64, 4, !spirv.Decorations !304
  %66 = add nuw nsw i64 %65, %52, !spirv.Decorations !304
  %67 = mul nuw nsw i64 %66, 640, !spirv.Decorations !304
  %68 = getelementptr i32, ptr addrspace(4) %56, i64 %67
  %69 = load i32, ptr addrspace(4) %68, align 4
  %70 = add nsw i32 %58, %69, !spirv.Decorations !302
  %71 = add nuw nsw i32 %59, 1, !spirv.Decorations !304
  br label %57

72:                                               ; preds = %57
  %73 = getelementptr inbounds float, ptr addrspace(4) %19, i64 %52
  %74 = load float, ptr addrspace(4) %73, align 4
  %75 = fmul reassoc nsz arcp contract float %74, 0x3F7B717580000000, !spirv.Decorations !306
  %76 = sitofp i32 %58 to float
  %77 = getelementptr inbounds i32, ptr addrspace(4) %23, i64 %52
  %78 = load i32, ptr addrspace(4) %77, align 4
  %79 = sitofp i32 %78 to float
  %80 = fmul reassoc nnan nsz arcp contract float %79, 5.100000e+02, !spirv.Decorations !308
  %81 = fsub reassoc nnan nsz arcp contract float %76, %80, !spirv.Decorations !308
  %82 = fmul reassoc nsz arcp contract float %75, %81, !spirv.Decorations !306
  %83 = getelementptr inbounds float, ptr addrspace(4) %15, i64 %44
  store float %82, ptr addrspace(4) %83, align 4
  %84 = add i64 %44, %39
  %85 = icmp ult i64 %84, %4
  %86 = select i1 %85, i64 %84, i64 %31
  br label %43

87:                                               ; preds = %43
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #1

; Function Attrs: nounwind
define spir_kernel void @_ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_(i32 %0, ptr addrspace(1) align 4 %1, ptr addrspace(1) align 4 %2, ptr addrspace(1) align 4 %3, ptr addrspace(1) align 4 %4) #0 !kernel_arg_addr_space !310 !kernel_arg_access_qual !311 !kernel_arg_type !312 !kernel_arg_type_qual !313 !kernel_arg_base_type !312 !kernel_arg_name !313 !spirv.ParameterDecorations !314 {
  %6 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 0) #2
  %7 = insertelement <3 x i64> poison, i64 %6, i32 0
  %8 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 1) #2
  %9 = insertelement <3 x i64> %7, i64 %8, i32 1
  %10 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 2) #2
  %11 = insertelement <3 x i64> %9, i64 %10, i32 2
  %12 = extractelement <3 x i64> %11, i32 0
  %13 = select i1 true, i64 %12, i64 0
  %14 = icmp ult i64 %13, 2147483648
  call void @llvm.assume(i1 %14)
  %15 = sext i32 %0 to i64
  %16 = mul nsw i64 %15, 640, !spirv.Decorations !302
  %17 = udiv i64 %13, %16
  %18 = trunc i64 %13 to i32
  %19 = udiv i32 %18, 640
  %20 = zext i32 %19 to i64
  %21 = urem i64 %20, %15
  %22 = mul i32 %19, 640
  %23 = sub i32 %18, %22
  %24 = zext i32 %23 to i64
  %25 = getelementptr i32, ptr addrspace(1) %1, i64 %24
  br label %26

26:                                               ; preds = %30, %5
  %27 = phi i32 [ 0, %5 ], [ %39, %30 ]
  %28 = phi i32 [ 0, %5 ], [ %40, %30 ]
  %29 = icmp ult i32 %28, 2
  br i1 %29, label %30, label %41

30:                                               ; preds = %26
  %31 = mul nuw nsw i32 %28, 10, !spirv.Decorations !304
  %32 = zext i32 %31 to i64
  %33 = add nuw nsw i64 %17, %32, !spirv.Decorations !304
  %34 = shl nuw nsw i64 %33, 4, !spirv.Decorations !304
  %35 = add nuw nsw i64 %34, %21, !spirv.Decorations !304
  %36 = mul nuw nsw i64 %35, 640, !spirv.Decorations !304
  %37 = getelementptr i32, ptr addrspace(1) %25, i64 %36
  %38 = load i32, ptr addrspace(1) %37, align 4
  %39 = add nsw i32 %27, %38, !spirv.Decorations !302
  %40 = add nuw nsw i32 %28, 1, !spirv.Decorations !304
  br label %26

41:                                               ; preds = %26
  %42 = getelementptr inbounds float, ptr addrspace(1) %3, i64 %21
  %43 = load float, ptr addrspace(1) %42, align 4
  %44 = fmul reassoc nsz arcp contract float %43, 0x3F7B717580000000, !spirv.Decorations !306
  %45 = sitofp i32 %27 to float
  %46 = getelementptr inbounds i32, ptr addrspace(1) %4, i64 %21
  %47 = load i32, ptr addrspace(1) %46, align 4
  %48 = sitofp i32 %47 to float
  %49 = fmul reassoc nnan nsz arcp contract float %48, 5.100000e+02, !spirv.Decorations !308
  %50 = fsub reassoc nnan nsz arcp contract float %45, %49, !spirv.Decorations !308
  %51 = fmul reassoc nsz arcp contract float %44, %50, !spirv.Decorations !306
  %52 = getelementptr inbounds float, ptr addrspace(1) %2, i64 %13
  store float %51, ptr addrspace(1) %52, align 4
  ret void
}

; Function Attrs: nounwind
define spir_kernel void @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL4pairRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE(ptr byval(%"class.sycl::_V1::range") align 8 %0, ptr byval(%class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_) align 8 %1) #0 !kernel_arg_addr_space !294 !kernel_arg_access_qual !295 !kernel_arg_type !317 !kernel_arg_type_qual !297 !kernel_arg_base_type !317 !kernel_arg_name !297 !spirv.ParameterDecorations !298 {
  %3 = bitcast ptr %0 to ptr
  %4 = load i64, ptr %3, align 8
  %5 = bitcast ptr %1 to ptr
  %6 = getelementptr inbounds %structtype.0, ptr %5, i64 0, i32 0
  %7 = load i64, ptr %6, align 8
  %8 = bitcast ptr %1 to ptr
  %9 = getelementptr inbounds %structtype.0, ptr %8, i64 0, i32 1
  %10 = load i64, ptr %9, align 8
  %11 = bitcast ptr %1 to ptr
  %12 = getelementptr inbounds %structtype.0, ptr %11, i64 0, i32 2
  %13 = load i64, ptr %12, align 8
  %14 = bitcast ptr %1 to ptr
  %15 = getelementptr inbounds %structtype.0, ptr %14, i64 0, i32 3
  %16 = load i64, ptr %15, align 8
  %17 = bitcast ptr %1 to ptr
  %18 = getelementptr inbounds %structtype.0, ptr %17, i64 0, i32 4
  %19 = load i64, ptr %18, align 8
  %20 = bitcast ptr %1 to ptr
  %21 = getelementptr inbounds %structtype.0, ptr %20, i64 0, i32 5
  %22 = load i32, ptr %21, align 4
  %23 = bitcast ptr %1 to ptr
  %24 = getelementptr inbounds %structtype.0, ptr %23, i64 0, i32 6
  %25 = load i64, ptr %24, align 8
  %26 = inttoptr i64 %25 to ptr addrspace(4)
  %27 = bitcast ptr %1 to ptr
  %28 = getelementptr inbounds %structtype.0, ptr %27, i64 0, i32 7
  %29 = load i64, ptr %28, align 8
  %30 = inttoptr i64 %29 to ptr addrspace(4)
  %31 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 0) #2
  %32 = insertelement <3 x i64> poison, i64 %31, i32 0
  %33 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 1) #2
  %34 = insertelement <3 x i64> %32, i64 %33, i32 1
  %35 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 2) #2
  %36 = insertelement <3 x i64> %34, i64 %35, i32 2
  %37 = extractelement <3 x i64> %36, i32 0
  %38 = select i1 true, i64 %37, i64 0
  %39 = call spir_func i64 @_Z25__spirv_BuiltInGlobalSizei(i32 0) #2
  %40 = insertelement <3 x i64> poison, i64 %39, i32 0
  %41 = call spir_func i64 @_Z25__spirv_BuiltInGlobalSizei(i32 1) #2
  %42 = insertelement <3 x i64> %40, i64 %41, i32 1
  %43 = call spir_func i64 @_Z25__spirv_BuiltInGlobalSizei(i32 2) #2
  %44 = insertelement <3 x i64> %42, i64 %43, i32 2
  %45 = extractelement <3 x i64> %44, i32 0
  %46 = select i1 true, i64 %45, i64 1
  %47 = icmp ult i64 %38, %4
  %48 = sext i32 %22 to i64
  %49 = mul nsw i64 %48, 640, !spirv.Decorations !302
  br label %50

50:                                               ; preds = %87, %2
  %51 = phi i64 [ %38, %2 ], [ %101, %87 ]
  %52 = phi i1 [ %47, %2 ], [ %100, %87 ]
  br i1 %52, label %53, label %102

53:                                               ; preds = %50
  %54 = icmp ult i64 %51, 2147483648
  call void @llvm.assume(i1 %54)
  %55 = icmp ult i64 %51, %7
  %56 = select i1 %55, i64 %10, i64 %13
  %57 = inttoptr i64 %56 to ptr addrspace(4)
  %58 = select i1 %55, i64 %16, i64 %19
  %59 = inttoptr i64 %58 to ptr addrspace(4)
  %60 = select i1 %55, i64 0, i64 %7
  %61 = sub nsw i64 %51, %60, !spirv.Decorations !302
  %62 = udiv i64 %61, %49
  %63 = udiv i64 %61, 640
  %64 = urem i64 %63, %48
  %65 = mul i64 %63, 640
  %66 = sub i64 %61, %65
  %67 = shl i64 %62, 32
  %68 = ashr i64 %67, 32
  %69 = shl i64 %64, 32
  %70 = ashr i64 %69, 32
  %71 = getelementptr i32, ptr addrspace(4) %57, i64 %66
  br label %72

72:                                               ; preds = %76, %53
  %73 = phi i32 [ 0, %53 ], [ %85, %76 ]
  %74 = phi i32 [ 0, %53 ], [ %86, %76 ]
  %75 = icmp ult i32 %74, 2
  br i1 %75, label %76, label %87

76:                                               ; preds = %72
  %77 = mul nuw nsw i32 %74, 10, !spirv.Decorations !304
  %78 = zext i32 %77 to i64
  %79 = add nsw i64 %68, %78, !spirv.Decorations !302
  %80 = shl nsw i64 %79, 4, !spirv.Decorations !302
  %81 = add nsw i64 %80, %70, !spirv.Decorations !302
  %82 = mul nsw i64 %81, 640, !spirv.Decorations !302
  %83 = getelementptr i32, ptr addrspace(4) %71, i64 %82
  %84 = load i32, ptr addrspace(4) %83, align 4
  %85 = add nsw i32 %73, %84, !spirv.Decorations !302
  %86 = add nuw nsw i32 %74, 1, !spirv.Decorations !304
  br label %72

87:                                               ; preds = %72
  %88 = getelementptr inbounds float, ptr addrspace(4) %26, i64 %70
  %89 = load float, ptr addrspace(4) %88, align 4
  %90 = fmul reassoc nsz arcp contract float %89, 0x3F7B717580000000, !spirv.Decorations !306
  %91 = sitofp i32 %73 to float
  %92 = getelementptr inbounds i32, ptr addrspace(4) %30, i64 %70
  %93 = load i32, ptr addrspace(4) %92, align 4
  %94 = sitofp i32 %93 to float
  %95 = fmul reassoc nnan nsz arcp contract float %94, 5.100000e+02, !spirv.Decorations !308
  %96 = fsub reassoc nnan nsz arcp contract float %91, %95, !spirv.Decorations !308
  %97 = fmul reassoc nsz arcp contract float %90, %96, !spirv.Decorations !306
  %98 = getelementptr inbounds float, ptr addrspace(4) %59, i64 %61
  store float %97, ptr addrspace(4) %98, align 4
  %99 = add i64 %51, %46
  %100 = icmp ult i64 %99, %4
  %101 = select i1 %100, i64 %99, i64 %38
  br label %50

102:                                              ; preds = %50
  ret void
}

; Function Attrs: nounwind
define spir_kernel void @_ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_(i64 %0, ptr addrspace(1) align 4 %1, ptr addrspace(1) align 4 %2, ptr addrspace(1) align 4 %3, ptr addrspace(1) align 4 %4, i32 %5, ptr addrspace(1) align 4 %6, ptr addrspace(1) align 4 %7) #0 !kernel_arg_addr_space !318 !kernel_arg_access_qual !319 !kernel_arg_type !320 !kernel_arg_type_qual !321 !kernel_arg_base_type !320 !kernel_arg_name !321 !spirv.ParameterDecorations !322 {
  %9 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 0) #2
  %10 = insertelement <3 x i64> poison, i64 %9, i32 0
  %11 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 1) #2
  %12 = insertelement <3 x i64> %10, i64 %11, i32 1
  %13 = call spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32 2) #2
  %14 = insertelement <3 x i64> %12, i64 %13, i32 2
  %15 = extractelement <3 x i64> %14, i32 0
  %16 = select i1 true, i64 %15, i64 0
  %17 = icmp ult i64 %16, 2147483648
  call void @llvm.assume(i1 %17)
  %18 = icmp ult i64 %16, %0
  %19 = select i1 %18, ptr addrspace(1) %1, ptr addrspace(1) %2
  %20 = select i1 %18, i64 0, i64 %0
  %21 = sub nsw i64 %16, %20, !spirv.Decorations !302
  %22 = sext i32 %5 to i64
  %23 = mul nsw i64 %22, 640, !spirv.Decorations !302
  %24 = udiv i64 %21, %23
  %25 = udiv i64 %21, 640
  %26 = urem i64 %25, %22
  %27 = trunc i64 %26 to i32
  %28 = mul i64 %25, 640
  %29 = sub i64 %21, %28
  %30 = shl i64 %24, 32
  %31 = ashr i64 %30, 32
  %32 = sext i32 %27 to i64
  %33 = getelementptr i32, ptr addrspace(1) %19, i64 %29
  br label %34

34:                                               ; preds = %38, %8
  %35 = phi i32 [ 0, %8 ], [ %47, %38 ]
  %36 = phi i32 [ 0, %8 ], [ %48, %38 ]
  %37 = icmp ult i32 %36, 2
  br i1 %37, label %38, label %49

38:                                               ; preds = %34
  %39 = mul nuw nsw i32 %36, 10, !spirv.Decorations !304
  %40 = zext i32 %39 to i64
  %41 = add nsw i64 %31, %40, !spirv.Decorations !302
  %42 = shl nsw i64 %41, 4, !spirv.Decorations !302
  %43 = add nsw i64 %42, %32, !spirv.Decorations !302
  %44 = mul nsw i64 %43, 640, !spirv.Decorations !302
  %45 = getelementptr i32, ptr addrspace(1) %33, i64 %44
  %46 = load i32, ptr addrspace(1) %45, align 4
  %47 = add nsw i32 %35, %46, !spirv.Decorations !302
  %48 = add nuw nsw i32 %36, 1, !spirv.Decorations !304
  br label %34

49:                                               ; preds = %34
  %50 = select i1 %18, ptr addrspace(1) %3, ptr addrspace(1) %4
  %51 = getelementptr inbounds float, ptr addrspace(1) %6, i64 %32
  %52 = load float, ptr addrspace(1) %51, align 4
  %53 = fmul reassoc nsz arcp contract float %52, 0x3F7B717580000000, !spirv.Decorations !306
  %54 = sitofp i32 %35 to float
  %55 = getelementptr inbounds i32, ptr addrspace(1) %7, i64 %32
  %56 = load i32, ptr addrspace(1) %55, align 4
  %57 = sitofp i32 %56 to float
  %58 = fmul reassoc nnan nsz arcp contract float %57, 5.100000e+02, !spirv.Decorations !308
  %59 = fsub reassoc nnan nsz arcp contract float %54, %58, !spirv.Decorations !308
  %60 = fmul reassoc nsz arcp contract float %53, %59, !spirv.Decorations !306
  %61 = getelementptr inbounds float, ptr addrspace(1) %50, i64 %21
  store float %60, ptr addrspace(1) %61, align 4
  ret void
}

; Function Attrs: nounwind willreturn memory(none)
declare spir_func i64 @_Z33__spirv_BuiltInGlobalInvocationIdi(i32) #2

; Function Attrs: nounwind willreturn memory(none)
declare spir_func i64 @_Z25__spirv_BuiltInGlobalSizei(i32) #2

attributes #0 = { nounwind }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #2 = { nounwind willreturn memory(none) }

!spirv.MemoryModel = !{!0}
!opencl.enable.FP_CONTRACT = !{}
!spirv.Source = !{!1}
!opencl.spir.version = !{!2}
!opencl.used.extensions = !{!3}
!opencl.used.optional.core.features = !{!3}
!spirv.Generator = !{!4}
!opencl.compiler.options = !{!5}
!igc.spirv.extensions = !{!6}
!igc.functions = !{}
!IGCMetadata = !{!7}

!0 = !{i32 2, i32 2}
!1 = !{i32 4, i32 100000}
!2 = !{i32 1, i32 2}
!3 = !{}
!4 = !{i16 6, i16 14}
!5 = !{!"-ze-opt-level=O2"}
!6 = !{!"SPV_INTEL_fp_fast_math_mode", !"SPV_KHR_expect_assume"}
!7 = !{!"ModuleMD", !8, !9, !125, !126, !157, !174, !195, !205, !207, !208, !224, !225, !226, !227, !228, !232, !233, !240, !241, !242, !243, !244, !245, !246, !247, !248, !250, !254, !255, !256, !257, !258, !259, !260, !261, !262, !263, !264, !265, !266, !267, !268, !269, !270, !271, !272, !274, !276, !279, !280, !281, !283, !284, !285, !290, !291, !292, !293}
!8 = !{!"isPrecise", i1 false}
!9 = !{!"compOpt", !10, !11, !12, !13, !14, !15, !16, !17, !18, !19, !20, !21, !22, !23, !24, !25, !26, !27, !28, !29, !30, !31, !32, !33, !34, !35, !36, !37, !38, !39, !40, !41, !42, !43, !44, !45, !46, !47, !48, !49, !50, !51, !52, !53, !54, !55, !56, !57, !58, !59, !60, !61, !62, !63, !64, !65, !66, !67, !68, !69, !70, !71, !72, !73, !74, !75, !76, !77, !78, !79, !80, !81, !82, !83, !84, !85, !86, !87, !88, !89, !90, !91, !92, !93, !94, !95, !96, !97, !98, !99, !100, !101, !102, !103, !104, !105, !106, !107, !108, !109, !110, !111, !112, !113, !114, !115, !116, !117, !118, !119, !120, !121, !122, !123, !124}
!10 = !{!"DenormsAreZero", i1 false}
!11 = !{!"BFTFDenormsAreZero", i1 false}
!12 = !{!"CorrectlyRoundedDivSqrt", i1 false}
!13 = !{!"OptDisable", i1 false}
!14 = !{!"MadEnable", i1 false}
!15 = !{!"NoSignedZeros", i1 false}
!16 = !{!"NoNaNs", i1 false}
!17 = !{!"FloatDenormMode16", !"FLOAT_DENORM_RETAIN"}
!18 = !{!"FloatDenormMode32", !"FLOAT_DENORM_RETAIN"}
!19 = !{!"FloatDenormMode64", !"FLOAT_DENORM_RETAIN"}
!20 = !{!"FloatDenormModeBFTF", !"FLOAT_DENORM_RETAIN"}
!21 = !{!"FloatRoundingMode", i32 0}
!22 = !{!"FloatCvtIntRoundingMode", i32 3}
!23 = !{!"LoadCacheDefault", i32 -1}
!24 = !{!"StoreCacheDefault", i32 -1}
!25 = !{!"VISAPreSchedRPThreshold", i32 0}
!26 = !{!"VISAPreSchedCtrl", i32 0}
!27 = !{!"SetLoopUnrollThreshold", i32 0}
!28 = !{!"UnsafeMathOptimizations", i1 false}
!29 = !{!"disableCustomUnsafeOpts", i1 false}
!30 = !{!"disableReducePow", i1 false}
!31 = !{!"disableSqrtOpt", i1 false}
!32 = !{!"FiniteMathOnly", i1 false}
!33 = !{!"FastRelaxedMath", i1 false}
!34 = !{!"DashGSpecified", i1 false}
!35 = !{!"FastCompilation", i1 false}
!36 = !{!"UseScratchSpacePrivateMemory", i1 true}
!37 = !{!"RelaxedBuiltins", i1 false}
!38 = !{!"SubgroupIndependentForwardProgressRequired", i1 true}
!39 = !{!"GreaterThan2GBBufferRequired", i1 true}
!40 = !{!"GreaterThan4GBBufferRequired", i1 true}
!41 = !{!"DisableA64WA", i1 false}
!42 = !{!"ForceEnableA64WA", i1 false}
!43 = !{!"PushConstantsEnable", i1 true}
!44 = !{!"HasPositivePointerOffset", i1 false}
!45 = !{!"HasBufferOffsetArg", i1 false}
!46 = !{!"BufferOffsetArgOptional", i1 true}
!47 = !{!"replaceGlobalOffsetsByZero", i1 false}
!48 = !{!"forcePixelShaderSIMDMode", i32 0}
!49 = !{!"forceTotalGRFNum", i32 0}
!50 = !{!"ForceGeomFFShaderSIMDMode", i32 0}
!51 = !{!"pixelShaderDoNotAbortOnSpill", i1 false}
!52 = !{!"UniformWGS", i1 false}
!53 = !{!"disableVertexComponentPacking", i1 false}
!54 = !{!"disablePartialVertexComponentPacking", i1 false}
!55 = !{!"PreferBindlessImages", i1 false}
!56 = !{!"UseBindlessMode", i1 false}
!57 = !{!"UseLegacyBindlessMode", i1 true}
!58 = !{!"disableMathRefactoring", i1 false}
!59 = !{!"atomicBranch", i1 false}
!60 = !{!"spillCompression", i1 false}
!61 = !{!"AllowLICM", i1 true}
!62 = !{!"DisableEarlyOut", i1 false}
!63 = !{!"ForceInt32DivRemEmu", i1 false}
!64 = !{!"ForceInt32DivRemEmuSP", i1 false}
!65 = !{!"DisableIntDivRemIncrementReduction", i1 false}
!66 = !{!"DisableFastestSingleCSSIMD", i1 false}
!67 = !{!"DisableFastestLinearScan", i1 false}
!68 = !{!"UseStatelessforPrivateMemory", i1 false}
!69 = !{!"EnableTakeGlobalAddress", i1 false}
!70 = !{!"IsLibraryCompilation", i1 false}
!71 = !{!"LibraryCompileSIMDSize", i32 0}
!72 = !{!"FastVISACompile", i1 false}
!73 = !{!"MatchSinCosPi", i1 false}
!74 = !{!"ExcludeIRFromZEBinary", i1 false}
!75 = !{!"EmitZeBinVISASections", i1 false}
!76 = !{!"FP64GenEmulationEnabled", i1 false}
!77 = !{!"FP64GenConvEmulationEnabled", i1 false}
!78 = !{!"allowDisableRematforCS", i1 false}
!79 = !{!"DisableIncSpillCostAllAddrTaken", i1 false}
!80 = !{!"DisableCPSOmaskWA", i1 false}
!81 = !{!"DisableFastestGopt", i1 false}
!82 = !{!"WaForceHalfPromotionComputeShader", i1 false}
!83 = !{!"WaForceHalfPromotionPixelVertexShader", i1 false}
!84 = !{!"DisableConstantCoalescing", i1 false}
!85 = !{!"DisableBitcastedLoadNarrowing", i1 false}
!86 = !{!"EnableUndefAlphaOutputAsRed", i1 true}
!87 = !{!"WaEnableALTModeVisaWA", i1 false}
!88 = !{!"WaConvergentGradientsOnGenISA", i1 false}
!89 = !{!"WaDisableDualSIMD8", i1 false}
!90 = !{!"EnableLdStCombineforLoad", i1 false}
!91 = !{!"EnableLdStCombinewithDummyLoad", i1 false}
!92 = !{!"WaZeroInactiveLanesForWaveShuffle", i1 false}
!93 = !{!"ForceUniformBuffer", i1 false}
!94 = !{!"ForceUniformSurfaceSampler", i1 false}
!95 = !{!"EnableIndependentSharedMemoryFenceFunctionality", i1 false}
!96 = !{!"NewSpillCostFunction", i1 false}
!97 = !{!"EnableVRT", i1 true}
!98 = !{!"ForceLargeGRFNum4RQ", i1 false}
!99 = !{!"DisableEUFusion", i1 false}
!100 = !{!"DisableFDivToFMulInvOpt", i1 false}
!101 = !{!"initializePhiSampleSourceWA", i1 false}
!102 = !{!"WaDisableSubspanUseNoMaskForCB", i1 false}
!103 = !{!"DisableLoosenSimd32Occu", i1 false}
!104 = !{!"FastestS1Options", i32 0}
!105 = !{!"DisableFastestForWaveIntrinsicsCS", i1 false}
!106 = !{!"ForceLinearWalkOnLinearUAV", i1 false}
!107 = !{!"LscSamplerRouting", i32 0}
!108 = !{!"UseBarrierControlFlowOptimization", i1 false}
!109 = !{!"EnableDynamicRQManagement", i1 false}
!110 = !{!"WaDisablePayloadCoalescing", i1 false}
!111 = !{!"Quad8InputThreshold", i32 0}
!112 = !{!"UseResourceLoopUnrollNested", i1 false}
!113 = !{!"DisableLoopUnroll", i1 false}
!114 = !{!"ForcePushConstantMode", i32 0}
!115 = !{!"UseInstructionHoistingOptimization", i1 false}
!116 = !{!"DisableResourceLoopDestLifeTimeStart", i1 false}
!117 = !{!"ForceVRTGRFCeiling", i32 0}
!118 = !{!"EnableSamplerBackingByLSC", i32 0}
!119 = !{!"UseLinearScanRA", i1 false}
!120 = !{!"DisableConvertingAtomicIAddToIncDec", i1 false}
!121 = !{!"ZeroInitRegistersBeforeExecution", i1 false}
!122 = !{!"VISASpillAllowed", i32 0}
!123 = !{!"ConstantCoalescingMaxBBDepthDelta", i32 0}
!124 = !{!"ConstantCoalescingDepthCheckMinBytes", i32 0}
!125 = !{!"FuncMD"}
!126 = !{!"pushInfo", !127, !128, !129, !133, !134, !135, !136, !137, !138, !139, !140, !153, !154, !155, !156}
!127 = !{!"pushableAddresses"}
!128 = !{!"bindlessPushInfo"}
!129 = !{!"dynamicBufferInfo", !130, !131, !132}
!130 = !{!"firstIndex", i32 0}
!131 = !{!"numOffsets", i32 0}
!132 = !{!"forceDisabled", i1 false}
!133 = !{!"MaxNumberOfPushedBuffers", i32 0}
!134 = !{!"inlineConstantBufferSlot", i32 -1}
!135 = !{!"inlineConstantBufferOffset", i32 -1}
!136 = !{!"inlineConstantBufferGRFOffset", i32 -1}
!137 = !{!"constants"}
!138 = !{!"inputs"}
!139 = !{!"constantReg"}
!140 = !{!"simplePushInfoArr", !141, !150, !151, !152}
!141 = !{!"simplePushInfoArrVec[0]", !142, !143, !144, !145, !146, !147, !148, !149}
!142 = !{!"cbIdx", i32 0}
!143 = !{!"pushableAddressGrfOffset", i32 -1}
!144 = !{!"pushableOffsetGrfOffset", i32 -1}
!145 = !{!"offset", i32 0}
!146 = !{!"size", i32 0}
!147 = !{!"isStateless", i1 false}
!148 = !{!"isBindless", i1 false}
!149 = !{!"simplePushLoads"}
!150 = !{!"simplePushInfoArrVec[1]", !142, !143, !144, !145, !146, !147, !148, !149}
!151 = !{!"simplePushInfoArrVec[2]", !142, !143, !144, !145, !146, !147, !148, !149}
!152 = !{!"simplePushInfoArrVec[3]", !142, !143, !144, !145, !146, !147, !148, !149}
!153 = !{!"simplePushBufferUsed", i32 0}
!154 = !{!"pushAnalysisWIInfos"}
!155 = !{!"inlineRTGlobalPtrOffset", i32 0}
!156 = !{!"rtSyncSurfPtrOffset", i32 0}
!157 = !{!"psInfo", !158, !159, !160, !161, !162, !163, !164, !165, !166, !167, !168, !169, !170, !171, !172, !173}
!158 = !{!"BlendStateDisabledMask", i8 0}
!159 = !{!"SkipSrc0Alpha", i1 false}
!160 = !{!"DualSourceBlendingDisabled", i1 false}
!161 = !{!"ForceEnableSimd32", i1 false}
!162 = !{!"DisableSimd32WithDiscard", i1 false}
!163 = !{!"outputDepth", i1 false}
!164 = !{!"outputStencil", i1 false}
!165 = !{!"outputMask", i1 false}
!166 = !{!"blendToFillEnabled", i1 false}
!167 = !{!"forceEarlyZ", i1 false}
!168 = !{!"hasVersionedLoop", i1 false}
!169 = !{!"forceSingleSourceRTWAfterDualSourceRTW", i1 false}
!170 = !{!"blendOptimizationMode"}
!171 = !{!"colorOutputMask"}
!172 = !{!"isBlendEnabled"}
!173 = !{!"WaDisableVRS", i1 false}
!174 = !{!"csInfo", !175, !176, !177, !178, !49, !25, !26, !179, !27, !180, !181, !182, !183, !184, !185, !186, !187, !188, !189, !190, !60, !191, !192, !193, !194}
!175 = !{!"maxWorkGroupSize", i32 0}
!176 = !{!"waveSize", i32 0}
!177 = !{!"ComputeShaderSecondCompile"}
!178 = !{!"forcedSIMDSize", i8 0}
!179 = !{!"VISAPreSchedScheduleExtraGRF", i32 0}
!180 = !{!"forceSpillCompression", i1 false}
!181 = !{!"allowLowerSimd", i1 false}
!182 = !{!"disableSimd32Slicing", i1 false}
!183 = !{!"disableSplitOnSpill", i1 false}
!184 = !{!"enableNewSpillCostFunction", i1 false}
!185 = !{!"forceVISAPreSched", i1 false}
!186 = !{!"disableLocalIdOrderOptimizations", i1 false}
!187 = !{!"disableDispatchAlongY", i1 false}
!188 = !{!"neededThreadIdLayout", ptr null}
!189 = !{!"forceTileYWalk", i1 false}
!190 = !{!"atomicBranch", i32 0}
!191 = !{!"disableEarlyOut", i1 false}
!192 = !{!"walkOrderEnabled", i1 false}
!193 = !{!"walkOrderOverride", i32 0}
!194 = !{!"ResForHfPacking"}
!195 = !{!"msInfo", !196, !197, !198, !199, !200, !201, !202, !203, !204}
!196 = !{!"PrimitiveTopology", i32 3}
!197 = !{!"MaxNumOfPrimitives", i32 0}
!198 = !{!"MaxNumOfVertices", i32 0}
!199 = !{!"MaxNumOfPerPrimitiveOutputs", i32 0}
!200 = !{!"MaxNumOfPerVertexOutputs", i32 0}
!201 = !{!"WorkGroupSize", i32 0}
!202 = !{!"WorkGroupMemorySizeInBytes", i32 0}
!203 = !{!"IndexFormat", i32 6}
!204 = !{!"SubgroupSize", i32 0}
!205 = !{!"taskInfo", !206, !201, !202, !204}
!206 = !{!"MaxNumOfOutputs", i32 0}
!207 = !{!"NBarrierCnt", i32 0}
!208 = !{!"rtInfo", !209, !210, !211, !212, !213, !214, !215, !216, !217, !218, !219, !220, !221, !222, !223}
!209 = !{!"RayQueryAllocSizeInBytes", i32 0}
!210 = !{!"NumContinuations", i32 0}
!211 = !{!"RTAsyncStackAddrspace", i32 -1}
!212 = !{!"RTAsyncStackSurfaceStateOffset", ptr null}
!213 = !{!"SWHotZoneAddrspace", i32 -1}
!214 = !{!"SWHotZoneSurfaceStateOffset", ptr null}
!215 = !{!"SWStackAddrspace", i32 -1}
!216 = !{!"SWStackSurfaceStateOffset", ptr null}
!217 = !{!"RTSyncStackAddrspace", i32 -1}
!218 = !{!"RTSyncStackSurfaceStateOffset", ptr null}
!219 = !{!"doSyncDispatchRays", i1 false}
!220 = !{!"MemStyle", !"Xe"}
!221 = !{!"GlobalDataStyle", !"Xe"}
!222 = !{!"uberTileDimensions", ptr null}
!223 = !{!"numSyncRTStacks", i32 0}
!224 = !{!"hasSliceLayoutDependency", i1 false}
!225 = !{!"CurUniqueIndirectIdx", i32 0}
!226 = !{!"inlineDynTextures"}
!227 = !{!"inlineResInfoData"}
!228 = !{!"immConstant", !229, !230, !231}
!229 = !{!"data"}
!230 = !{!"sizes"}
!231 = !{!"zeroIdxs"}
!232 = !{!"stringConstants"}
!233 = !{!"inlineBuffers", !234, !238, !239}
!234 = !{!"inlineBuffersVec[0]", !235, !236, !237}
!235 = !{!"alignment", i32 0}
!236 = !{!"allocSize", i64 0}
!237 = !{!"Buffer"}
!238 = !{!"inlineBuffersVec[1]", !235, !236, !237}
!239 = !{!"inlineBuffersVec[2]", !235, !236, !237}
!240 = !{!"GlobalBufferAddressRelocInfo"}
!241 = !{!"ConstantBufferAddressRelocInfo"}
!242 = !{!"forceLscCacheList"}
!243 = !{!"SrvMap"}
!244 = !{!"RasterizerOrderedByteAddressBuffer"}
!245 = !{!"RasterizerOrderedViews"}
!246 = !{!"MinNOSPushConstantSize", i32 0}
!247 = !{!"inlineProgramScopeOffsets"}
!248 = !{!"shaderData", !249}
!249 = !{!"numReplicas", i32 0}
!250 = !{!"URBInfo", !251, !252, !253}
!251 = !{!"has64BVertexHeaderInput", i1 false}
!252 = !{!"has64BVertexHeaderOutput", i1 false}
!253 = !{!"hasVertexHeader", i1 true}
!254 = !{!"UseBindlessImage", i1 false}
!255 = !{!"HasBindlessImageRead", i1 false}
!256 = !{!"UseBindlessImageWithSamplerTracking", i1 false}
!257 = !{!"enableRangeReduce", i1 false}
!258 = !{!"allowMatchMadOptimizationforPosition", i1 false}
!259 = !{!"disableMatchMadOptimizationForCS", i1 false}
!260 = !{!"disableMemOptforNegativeOffsetLoads", i1 false}
!261 = !{!"enableThreeWayLoadSpiltOpt", i1 false}
!262 = !{!"statefulResourcesNotAliased", i1 false}
!263 = !{!"disableMixMode", i1 false}
!264 = !{!"genericAccessesResolved", i1 false}
!265 = !{!"disableSeparateSpillPvtScratchSpace", i1 false}
!266 = !{!"enableSeparateSpillPvtScratchSpace", i1 false}
!267 = !{!"disableSeparateScratchWA", i1 false}
!268 = !{!"enableRemoveUnusedTGMFence", i1 false}
!269 = !{!"privateMemoryPerWI", i32 0}
!270 = !{!"PrivateMemoryPerFG"}
!271 = !{!"m_OptsToDisable"}
!272 = !{!"capabilities", !273}
!273 = !{!"globalVariableDecorationsINTEL", i1 false}
!274 = !{!"extensions", !275}
!275 = !{!"spvINTELBindlessImages", i1 false}
!276 = !{!"m_ShaderResourceViewMcsMask", !277, !278}
!277 = !{!"m_ShaderResourceViewMcsMaskVec[0]", i64 0}
!278 = !{!"m_ShaderResourceViewMcsMaskVec[1]", i64 0}
!279 = !{!"computedDepthMode", i32 0}
!280 = !{!"isHDCFastClearShader", i1 false}
!281 = !{!"argRegisterReservations", !282}
!282 = !{!"argRegisterReservationsVec[0]", i32 0}
!283 = !{!"SIMD16_SpillThreshold", i8 0}
!284 = !{!"SIMD32_SpillThreshold", i8 0}
!285 = !{!"m_CacheControlOption", !286, !287, !288, !289}
!286 = !{!"LscLoadCacheControlOverride", i8 0}
!287 = !{!"LscStoreCacheControlOverride", i8 0}
!288 = !{!"TgmLoadCacheControlOverride", i8 0}
!289 = !{!"TgmStoreCacheControlOverride", i8 0}
!290 = !{!"ModuleUsesBindless", i1 false}
!291 = !{!"predicationMap"}
!292 = !{!"lifeTimeStartMap"}
!293 = !{!"HitGroups"}
!294 = !{i32 0, i32 0}
!295 = !{!"none", !"none"}
!296 = !{!"class.sycl::_V1::range", !"class._ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_"}
!297 = !{!"", !""}
!298 = !{!299, !299}
!299 = !{!300, !301}
!300 = !{i32 38, i32 2}
!301 = !{i32 44, i32 8}
!302 = !{!303}
!303 = !{i32 4469}
!304 = !{!303, !305}
!305 = !{i32 4470}
!306 = !{!307}
!307 = !{i32 40, i32 196620}
!308 = !{!309}
!309 = !{i32 40, i32 196621}
!310 = !{i32 0, i32 1, i32 1, i32 1, i32 1}
!311 = !{!"none", !"none", !"none", !"none", !"none"}
!312 = !{!"int", !"int*", !"float*", !"float*", !"int*"}
!313 = !{!"", !"", !"", !"", !""}
!314 = !{!3, !315, !315, !315, !315}
!315 = !{!316}
!316 = !{i32 44, i32 4}
!317 = !{!"class.sycl::_V1::range", !"class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_"}
!318 = !{i32 0, i32 1, i32 1, i32 1, i32 1, i32 0, i32 1, i32 1}
!319 = !{!"none", !"none", !"none", !"none", !"none", !"none", !"none", !"none"}
!320 = !{!"long", !"int*", !"int*", !"float*", !"float*", !"int", !"float*", !"int*"}
!321 = !{!"", !"", !"", !"", !"", !"", !"", !""}
!322 = !{!3, !315, !315, !315, !315, !3, !315, !315}

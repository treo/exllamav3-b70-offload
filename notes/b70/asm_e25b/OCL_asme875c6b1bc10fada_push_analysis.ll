; ------------------------------------------------
; OCL_asme875c6b1bc10fada_push_analysis.ll
; ------------------------------------------------
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "spir64-unknown-unknown"

%"class.sycl::_V1::range" = type { %"class.sycl::_V1::detail::array" }
%"class.sycl::_V1::detail::array" = type { [1 x i64] }
%class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_ = type { i64, ptr addrspace(4), ptr addrspace(4), ptr addrspace(4), ptr addrspace(4), i32, ptr addrspace(4), ptr addrspace(4) }
%class._ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_ = type { i32, ptr addrspace(4), ptr addrspace(4), ptr addrspace(4), ptr addrspace(4) }

; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_(i64 %0, ptr addrspace(1) align 4 %1, ptr addrspace(1) align 4 %2, ptr addrspace(1) align 4 %3, ptr addrspace(1) align 4 %4, i32 %5, ptr addrspace(1) align 4 %6, ptr addrspace(1) align 4 %7, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i32 %bufferOffset, i32 %bufferOffset1, i32 %bufferOffset2, i32 %bufferOffset3, i32 %bufferOffset4, i32 %bufferOffset5, i32 %bindlessOffset, i32 %bindlessOffset6, i32 %bindlessOffset7, i32 %bindlessOffset8, i32 %bindlessOffset9, i32 %bindlessOffset10) #0 {
  %9 = bitcast i64 %0 to <2 x i32>
  %10 = extractelement <2 x i32> %9, i32 0
  %11 = extractelement <2 x i32> %9, i32 1
  %12 = extractelement <3 x i32> %globalOffset, i32 0
  %13 = extractelement <3 x i32> %enqueuedLocalSize, i32 0
  %14 = extractelement <8 x i32> %r0, i32 1
  %15 = mul i32 %13, %14
  %16 = zext i16 %localIdX to i32
  %17 = add i32 %15, %16
  %18 = add i32 %17, %12
  %19 = zext nneg i32 %18 to i64
  %20 = icmp ugt i32 %10, %18
  %21 = icmp eq i32 %11, 0
  %22 = and i1 %21, %20
  %23 = icmp ugt i32 %11, 0
  %24 = or i1 %22, %23
  %25 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %1)
  %26 = extractvalue { i32, i32 } %25, 0
  %27 = extractvalue { i32, i32 } %25, 1
  %28 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %2)
  %29 = extractvalue { i32, i32 } %28, 0
  %30 = extractvalue { i32, i32 } %28, 1
  %31 = select i1 %24, i32 %26, i32 %29
  %32 = select i1 %24, i32 %27, i32 %30
  %33 = insertelement <2 x i32> undef, i32 %31, i32 0
  %34 = insertelement <2 x i32> %33, i32 %32, i32 1
  %35 = bitcast <2 x i32> %34 to i64
  %36 = select i1 %24, i32 0, i32 %10
  %37 = select i1 %24, i32 0, i32 %11
  %38 = insertelement <2 x i32> undef, i32 %36, i32 0
  %39 = insertelement <2 x i32> %38, i32 %37, i32 1
  %40 = bitcast <2 x i32> %39 to i64
  %41 = sub nsw i64 %19, %40, !spirv.Decorations !615
  %42 = bitcast i64 %41 to <2 x i32>
  %43 = extractelement <2 x i32> %42, i32 0
  %44 = extractelement <2 x i32> %42, i32 1
  %45 = sext i32 %5 to i64
  %46 = ashr i32 %5, 31
  %47 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %5, i32 %46, i32 640, i32 0)
  %48 = extractvalue { i32, i32 } %47, 0
  %49 = extractvalue { i32, i32 } %47, 1
  %50 = insertelement <2 x i32> undef, i32 %48, i32 0
  %51 = insertelement <2 x i32> %50, i32 %49, i32 1
  %52 = bitcast <2 x i32> %51 to i64
  %53 = or i32 %49, %44
  %54 = icmp ult i32 %53, 1
  br i1 %54, label %55, label %74

55:                                               ; preds = %8
  %56 = trunc nuw i64 %41 to i32
  %57 = trunc nuw i64 %52 to i32
  %tobool.i33 = icmp eq i32 %5, 0
  br i1 %tobool.i33, label %.precompiled_u32divrem_sp.exit55_crit_edge, label %if.end.i34

.precompiled_u32divrem_sp.exit55_crit_edge:       ; preds = %55
  br label %precompiled_u32divrem_sp.exit55

if.end.i34:                                       ; preds = %55
  %58 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %57)
  %conv.i35 = fptoui float %58 to i32
  %sub.i36 = sub i32 %57, %conv.i35
  %59 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i36)
  %60 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %56)
  %conv3.i37 = fptoui float %60 to i32
  %sub4.i38 = sub i32 %56, %conv3.i37
  %61 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i38)
  %div.i39 = fdiv float 1.000000e+00, %58, !fpmath !617
  %62 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i39, float 0xBE98000000000000, float %div.i39)
  %63 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %60, float %62)
  %conv8.i40 = fptoui float %63 to i32
  %64 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i40)
  %65 = fsub float 0.000000e+00, %58
  %66 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %65, float %64, float %60)
  %67 = fsub float 0.000000e+00, %59
  %68 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %67, float %64, float %61)
  %69 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %66, float %68)
  %70 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %62, float %69)
  %conv16.i43 = fptoui float %70 to i32
  %add.i44 = add i32 %conv16.i43, %conv8.i40
  %mul.i45 = mul i32 %add.i44, %57
  %sub17.i46 = sub i32 %56, %mul.i45
  %cmp.i47 = icmp uge i32 %sub17.i46, %57
  %71 = sext i1 %cmp.i47 to i32
  %72 = sub i32 0, %71
  %add19.i50 = add i32 %add.i44, %72
  br label %precompiled_u32divrem_sp.exit55

precompiled_u32divrem_sp.exit55:                  ; preds = %.precompiled_u32divrem_sp.exit55_crit_edge, %if.end.i34
  %retval.0.i54 = phi i32 [ %add19.i50, %if.end.i34 ], [ -1, %.precompiled_u32divrem_sp.exit55_crit_edge ]
  %73 = zext i32 %retval.0.i54 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit

74:                                               ; preds = %8
  %75 = trunc i64 %52 to i32
  %76 = uitofp i64 %52 to double
  %77 = fptrunc double %76 to float
  %78 = fdiv float 1.000000e+00, %77
  %79 = fpext float %78 to double
  %80 = fsub double 0.000000e+00, %76
  %81 = call double @llvm.fma.f64(double %80, double %79, double 1.000000e+00) #4
  %82 = fadd double %81, 0xBCF0000000000000
  %83 = call double @llvm.fma.f64(double %79, double %82, double %79) #4
  %84 = bitcast i64 %41 to <2 x i32>
  %85 = extractelement <2 x i32> %84, i32 1
  %86 = uitofp i32 %85 to double
  %87 = fmul double %83, %86
  %88 = fptoui double %87 to i32
  %89 = mul i32 %88, %75
  %90 = sub i32 %85, %89
  %91 = uitofp i32 %90 to double
  %92 = trunc i64 %41 to i32
  %93 = uitofp i32 %92 to double
  %94 = call double @llvm.fma.f64(double %91, double 0x41F0000000000000, double %93) #4
  %95 = fmul double %83, %94
  %96 = fptoui double %95 to i64
  %97 = bitcast i64 %96 to <2 x i32>
  %98 = extractelement <2 x i32> %97, i32 0
  %99 = trunc i64 %96 to i32
  %100 = lshr i64 %96, 32
  %101 = bitcast i64 %100 to <2 x i32>
  %102 = extractelement <2 x i32> %101, i32 0
  %103 = extractelement <2 x i32> %101, i32 1
  %104 = bitcast i64 %96 to <2 x i32>
  %105 = extractelement <2 x i32> %104, i32 1
  %106 = icmp eq i32 %102, 0
  %107 = icmp eq i32 %103, 0
  %108 = and i1 %107, %106
  %109 = mul i32 %99, %49
  %110 = select i1 %108, i32 0, i32 %75
  %111 = add i32 %109, %110
  %112 = sub i32 %90, %111
  %113 = insertelement <2 x i32> undef, i32 %43, i32 0
  %114 = insertelement <2 x i32> %113, i32 %112, i32 1
  %115 = bitcast <2 x i32> %114 to i64
  %116 = and i32 %48, -128
  %117 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %98, i32 0, i32 %116, i32 0)
  %118 = extractvalue { i32, i32 } %117, 0
  %119 = extractvalue { i32, i32 } %117, 1
  %120 = insertelement <2 x i32> undef, i32 %118, i32 0
  %121 = insertelement <2 x i32> %120, i32 %119, i32 1
  %122 = bitcast <2 x i32> %121 to i64
  %123 = sub i64 %115, %122
  %124 = bitcast i64 %123 to <2 x i32>
  %125 = extractelement <2 x i32> %124, i32 0
  %126 = extractelement <2 x i32> %124, i32 1
  %127 = add i32 %105, %88
  %128 = insertelement <2 x i32> undef, i32 %98, i32 0
  %129 = insertelement <2 x i32> %128, i32 %127, i32 1
  %130 = bitcast <2 x i32> %129 to i64
  %131 = icmp uge i32 %125, %48
  %132 = icmp eq i32 %126, %49
  %133 = and i1 %132, %131
  %134 = icmp ugt i32 %126, %49
  %135 = or i1 %133, %134
  %136 = sext i1 %135 to i64
  %137 = sub i64 0, %136
  %138 = add i64 %130, %137
  br label %__igcbuiltin_u64_udiv_dp.exit

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit55, %74
  %139 = phi i64 [ %73, %precompiled_u32divrem_sp.exit55 ], [ %138, %74 ]
  %140 = icmp ult i32 %44, 1
  br i1 %140, label %udiv_pow2_64b_as_32b, label %udiv_pow2_64b

udiv_pow2_64b_as_32b:                             ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %141 = trunc nuw i64 %41 to i32
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %141, i32 -858993459)
  %q_appx30 = lshr i32 %q_appx, 9
  %142 = zext nneg i32 %q_appx30 to i64
  br label %176

udiv_pow2_64b:                                    ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %u.hi32 = lshr i64 %41, 32
  %143 = bitcast i64 %u.hi32 to <2 x i32>
  %144 = extractelement <2 x i32> %143, i32 0
  %145 = extractelement <2 x i32> %143, i32 1
  %146 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %43, i32 0, i32 -858993459, i32 0)
  %147 = extractvalue { i32, i32 } %146, 0
  %148 = extractvalue { i32, i32 } %146, 1
  %149 = insertelement <2 x i32> undef, i32 %147, i32 0
  %150 = insertelement <2 x i32> %149, i32 %148, i32 1
  %151 = bitcast <2 x i32> %150 to i64
  %152 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %144, i32 %145, i32 -858993459, i32 0)
  %153 = extractvalue { i32, i32 } %152, 0
  %154 = extractvalue { i32, i32 } %152, 1
  %155 = insertelement <2 x i32> undef, i32 %153, i32 0
  %156 = insertelement <2 x i32> %155, i32 %154, i32 1
  %157 = bitcast <2 x i32> %156 to i64
  %w0.lo32 = lshr i64 %151, 32
  %t = add nuw i64 %157, %w0.lo32
  %158 = bitcast i64 %t to <2 x i32>
  %159 = extractelement <2 x i32> %158, i32 0
  %160 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %43, i32 0, i32 -858993460, i32 0)
  %161 = extractvalue { i32, i32 } %160, 0
  %162 = extractvalue { i32, i32 } %160, 1
  %163 = insertelement <2 x i32> undef, i32 %161, i32 0
  %164 = insertelement <2 x i32> %163, i32 %162, i32 1
  %165 = bitcast <2 x i32> %164 to i64
  %166 = insertelement <2 x i32> undef, i32 %159, i32 0
  %167 = insertelement <2 x i32> %166, i32 0, i32 1
  %168 = bitcast <2 x i32> %167 to i64
  %w1 = add nuw i64 %165, %168
  %169 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %144, i32 %145, i32 -858993460, i32 0)
  %170 = extractvalue { i32, i32 } %169, 0
  %171 = extractvalue { i32, i32 } %169, 1
  %172 = insertelement <2 x i32> undef, i32 %170, i32 0
  %173 = insertelement <2 x i32> %172, i32 %171, i32 1
  %174 = bitcast <2 x i32> %173 to i64
  %t.hi32 = lshr i64 %t, 32
  %175 = add nuw i64 %174, %t.hi32
  %w1.lo32 = lshr i64 %w1, 32
  %uv = add nuw i64 %175, %w1.lo32
  %q_appx31 = lshr i64 %uv, 9
  br label %176

176:                                              ; preds = %udiv_pow2_64b, %udiv_pow2_64b_as_32b
  %177 = phi i64 [ %142, %udiv_pow2_64b_as_32b ], [ %q_appx31, %udiv_pow2_64b ]
  %178 = bitcast i64 %177 to <2 x i32>
  %179 = extractelement <2 x i32> %178, i32 0
  %180 = extractelement <2 x i32> %178, i32 1
  %181 = or i32 %180, %46
  %182 = icmp ult i32 %181, 1
  br i1 %182, label %183, label %199

183:                                              ; preds = %176
  %184 = trunc nuw i64 %177 to i32
  %tobool.i = icmp eq i32 %5, 0
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %183
  br label %precompiled_u32divrem_sp.exit

if.end.i:                                         ; preds = %183
  %185 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %5)
  %conv.i = fptoui float %185 to i32
  %sub.i = sub i32 %5, %conv.i
  %186 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %187 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %184)
  %conv3.i = fptoui float %187 to i32
  %sub4.i = sub i32 %184, %conv3.i
  %188 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %div.i = fdiv float 1.000000e+00, %185, !fpmath !617
  %189 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %190 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %187, float %189)
  %conv8.i = fptoui float %190 to i32
  %191 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %192 = fsub float 0.000000e+00, %185
  %193 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %192, float %191, float %187)
  %194 = fsub float 0.000000e+00, %186
  %195 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %194, float %191, float %188)
  %196 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %193, float %195)
  %197 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %189, float %196)
  %conv16.i = fptoui float %197 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %5
  %sub17.i = sub i32 %184, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %5
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %5
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %198 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit

199:                                              ; preds = %176
  %200 = uitofp i64 %45 to double
  %201 = fptrunc double %200 to float
  %202 = fdiv float 1.000000e+00, %201
  %203 = fpext float %202 to double
  %204 = fsub double 0.000000e+00, %200
  %205 = call double @llvm.fma.f64(double %204, double %203, double 1.000000e+00) #4
  %206 = fadd double %205, 0xBCF0000000000000
  %207 = call double @llvm.fma.f64(double %203, double %206, double %203) #4
  %208 = bitcast i64 %177 to <2 x i32>
  %209 = extractelement <2 x i32> %208, i32 1
  %210 = uitofp nneg i32 %209 to double
  %211 = fmul double %207, %210
  %212 = fptoui double %211 to i32
  %213 = mul i32 %5, %212
  %214 = sub i32 %209, %213
  %215 = uitofp i32 %214 to double
  %216 = trunc i64 %177 to i32
  %217 = uitofp i32 %216 to double
  %218 = call double @llvm.fma.f64(double %215, double 0x41F0000000000000, double %217) #4
  %219 = fmul double %207, %218
  %220 = fptoui double %219 to i64
  %221 = bitcast i64 %220 to <2 x i32>
  %222 = extractelement <2 x i32> %221, i32 0
  %223 = extractelement <2 x i32> %221, i32 1
  %224 = trunc i64 %220 to i32
  %225 = icmp ult i32 %223, 1
  %isneg = icmp slt i32 %5, 0
  %.neg56 = select i1 %isneg, i32 %224, i32 0
  %226 = select i1 %225, i32 0, i32 %5
  %227 = sub i32 %214, %226
  %228 = add i32 %.neg56, %227
  %229 = insertelement <2 x i32> undef, i32 %179, i32 0
  %230 = insertelement <2 x i32> %229, i32 %228, i32 1
  %231 = bitcast <2 x i32> %230 to i64
  %232 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %222, i32 0, i32 %5, i32 0)
  %233 = extractvalue { i32, i32 } %232, 0
  %234 = extractvalue { i32, i32 } %232, 1
  %235 = insertelement <2 x i32> undef, i32 %233, i32 0
  %236 = insertelement <2 x i32> %235, i32 %234, i32 1
  %237 = bitcast <2 x i32> %236 to i64
  %238 = sub i64 %231, %237
  %239 = bitcast i64 %238 to <2 x i32>
  %240 = extractelement <2 x i32> %239, i32 0
  %241 = extractelement <2 x i32> %239, i32 1
  %242 = icmp ult i32 %240, %5
  %243 = icmp eq i32 %241, %46
  %244 = and i1 %243, %242
  %245 = icmp ult i32 %241, %46
  %246 = or i1 %244, %245
  %247 = select i1 %246, i32 0, i32 %5
  %248 = select i1 %246, i32 0, i32 %46
  %249 = insertelement <2 x i32> undef, i32 %247, i32 0
  %250 = insertelement <2 x i32> %249, i32 %248, i32 1
  %251 = bitcast <2 x i32> %250 to i64
  %252 = sub i64 %238, %251
  br label %__igcbuiltin_u64_urem_dp.exit

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %199
  %253 = phi i64 [ %198, %precompiled_u32divrem_sp.exit ], [ %252, %199 ]
  %254 = bitcast i64 %139 to <2 x i32>
  %255 = extractelement <2 x i32> %254, i32 0
  %256 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %255, i32 1
  %257 = bitcast <2 x i32> %256 to i64
  %258 = bitcast i64 %253 to <2 x i32>
  %259 = extractelement <2 x i32> %258, i32 0
  %260 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %259, i32 1
  %261 = bitcast <2 x i32> %260 to i64
  %262 = ashr exact i64 %261, 32
  %263 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %179, i32 %180, i32 -2560, i32 -1)
  %264 = extractvalue { i32, i32 } %263, 0
  %265 = extractvalue { i32, i32 } %263, 1
  %266 = insertelement <2 x i32> undef, i32 %264, i32 0
  %267 = insertelement <2 x i32> %266, i32 %265, i32 1
  %268 = bitcast <2 x i32> %267 to i64
  %269 = add i64 %268, %35
  %270 = shl i64 %41, 2
  %271 = add i64 %269, %270
  %272 = ashr exact i64 %257, 28
  %273 = add nsw i64 %272, %262, !spirv.Decorations !615
  %274 = bitcast i64 %273 to <2 x i32>
  %275 = extractelement <2 x i32> %274, i32 0
  %276 = extractelement <2 x i32> %274, i32 1
  %277 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %275, i32 %276, i32 2560, i32 0)
  %278 = extractvalue { i32, i32 } %277, 0
  %279 = extractvalue { i32, i32 } %277, 1
  %280 = insertelement <2 x i32> undef, i32 %278, i32 0
  %281 = insertelement <2 x i32> %280, i32 %279, i32 1
  %282 = bitcast <2 x i32> %281 to i64
  %283 = add i64 %271, %282
  %284 = inttoptr i64 %283 to ptr addrspace(1)
  %285 = load i32, ptr addrspace(1) %284, align 4
  %286 = add i64 %283, 409600
  %287 = inttoptr i64 %286 to ptr addrspace(1)
  %288 = load i32, ptr addrspace(1) %287, align 4
  %289 = add nsw i32 %285, %288, !spirv.Decorations !615
  %290 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %3)
  %291 = extractvalue { i32, i32 } %290, 0
  %292 = extractvalue { i32, i32 } %290, 1
  %293 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %4)
  %294 = extractvalue { i32, i32 } %293, 0
  %295 = extractvalue { i32, i32 } %293, 1
  %296 = select i1 %24, i32 %291, i32 %294
  %297 = select i1 %24, i32 %292, i32 %295
  %298 = insertelement <2 x i32> undef, i32 %296, i32 0
  %299 = insertelement <2 x i32> %298, i32 %297, i32 1
  %300 = bitcast <2 x i32> %299 to i64
  %301 = ptrtoint ptr addrspace(1) %6 to i64
  %302 = ashr exact i64 %261, 30
  %303 = add i64 %302, %301
  %304 = inttoptr i64 %303 to ptr addrspace(1)
  %305 = load float, ptr addrspace(1) %304, align 4
  %306 = fmul reassoc nsz arcp contract float %305, 0x3F7B717580000000, !spirv.Decorations !618
  %307 = sitofp i32 %289 to float
  %308 = ptrtoint ptr addrspace(1) %7 to i64
  %309 = add i64 %302, %308
  %310 = inttoptr i64 %309 to ptr addrspace(1)
  %311 = load i32, ptr addrspace(1) %310, align 4
  %312 = sitofp i32 %311 to float
  %313 = fmul reassoc nnan nsz arcp contract float %312, 5.100000e+02, !spirv.Decorations !620
  %314 = fsub reassoc nnan nsz arcp contract float %307, %313, !spirv.Decorations !620
  %315 = fmul reassoc nsz arcp contract float %306, %314, !spirv.Decorations !618
  %316 = add i64 %270, %300
  %317 = inttoptr i64 %316 to ptr addrspace(1)
  store float %315, ptr addrspace(1) %317, align 4
  ret void
}

; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL4pairRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE(ptr byval(%"class.sycl::_V1::range") align 8 %0, ptr byval(%class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_) align 8 %1, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %globalSize, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i64 %const_reg_qword, i64 %const_reg_qword1, i64 %const_reg_qword2, i64 %const_reg_qword3, i64 %const_reg_qword4, i64 %const_reg_qword5, i32 %const_reg_dword, i8 %const_reg_byte, i8 %const_reg_byte6, i8 %const_reg_byte7, i8 %const_reg_byte8, i64 %const_reg_qword9, i64 %const_reg_qword10) #0 {
  %3 = bitcast i64 %const_reg_qword to <2 x i32>
  %4 = extractelement <2 x i32> %3, i32 0
  %5 = extractelement <2 x i32> %3, i32 1
  %6 = bitcast i64 %const_reg_qword1 to <2 x i32>
  %7 = extractelement <2 x i32> %6, i32 0
  %8 = extractelement <2 x i32> %6, i32 1
  %9 = bitcast i64 %const_reg_qword2 to <2 x i32>
  %10 = extractelement <2 x i32> %9, i32 0
  %11 = extractelement <2 x i32> %9, i32 1
  %12 = bitcast i64 %const_reg_qword3 to <2 x i32>
  %13 = extractelement <2 x i32> %12, i32 0
  %14 = extractelement <2 x i32> %12, i32 1
  %15 = bitcast i64 %const_reg_qword4 to <2 x i32>
  %16 = extractelement <2 x i32> %15, i32 0
  %17 = extractelement <2 x i32> %15, i32 1
  %18 = bitcast i64 %const_reg_qword5 to <2 x i32>
  %19 = extractelement <2 x i32> %18, i32 0
  %20 = extractelement <2 x i32> %18, i32 1
  %21 = extractelement <3 x i32> %globalSize, i32 0
  %22 = extractelement <3 x i32> %globalOffset, i32 0
  %23 = extractelement <3 x i32> %enqueuedLocalSize, i32 0
  %24 = extractelement <8 x i32> %r0, i32 1
  %25 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %23, i32 0, i32 %24, i32 0)
  %26 = extractvalue { i32, i32 } %25, 0
  %27 = extractvalue { i32, i32 } %25, 1
  %28 = insertelement <2 x i32> undef, i32 %26, i32 0
  %29 = insertelement <2 x i32> %28, i32 %27, i32 1
  %30 = bitcast <2 x i32> %29 to i64
  %31 = zext i16 %localIdX to i64
  %32 = add nuw i64 %30, %31
  %33 = zext i32 %22 to i64
  %34 = add nuw i64 %32, %33
  %35 = bitcast i64 %34 to <2 x i32>
  %36 = extractelement <2 x i32> %35, i32 0
  %37 = extractelement <2 x i32> %35, i32 1
  %38 = zext i32 %21 to i64
  %39 = icmp ult i32 %36, %4
  %40 = icmp eq i32 %37, %5
  %41 = and i1 %40, %39
  %42 = icmp ult i32 %37, %5
  %43 = or i1 %41, %42
  %44 = sext i32 %const_reg_dword to i64
  %45 = ashr i32 %const_reg_dword, 31
  %46 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %const_reg_dword, i32 %45, i32 640, i32 0)
  %47 = extractvalue { i32, i32 } %46, 0
  %48 = extractvalue { i32, i32 } %46, 1
  %49 = insertelement <2 x i32> undef, i32 %47, i32 0
  %50 = insertelement <2 x i32> %49, i32 %48, i32 1
  %51 = bitcast <2 x i32> %50 to i64
  br i1 %43, label %.lr.ph.preheader, label %.._crit_edge_crit_edge

.._crit_edge_crit_edge:                           ; preds = %2
  br label %._crit_edge

.lr.ph.preheader:                                 ; preds = %2
  %52 = trunc i64 %51 to i32
  %53 = uitofp i64 %51 to double
  %54 = fptrunc double %53 to float
  %55 = fdiv float 1.000000e+00, %54
  %56 = fpext float %55 to double
  %57 = fsub double 0.000000e+00, %53
  %58 = call double @llvm.fma.f64(double %57, double %56, double 1.000000e+00) #4
  %59 = fadd double %58, 0xBCF0000000000000
  %60 = call double @llvm.fma.f64(double %56, double %59, double %56) #4
  %61 = and i32 %47, -128
  %tobool.i37 = icmp eq i32 %const_reg_dword, 0
  %62 = uitofp i64 %44 to double
  %63 = fptrunc double %62 to float
  %64 = fdiv float 1.000000e+00, %63
  %65 = fpext float %64 to double
  %66 = fsub double 0.000000e+00, %62
  %67 = call double @llvm.fma.f64(double %66, double %65, double 1.000000e+00) #4
  %68 = fadd double %67, 0xBCF0000000000000
  %69 = call double @llvm.fma.f64(double %65, double %68, double %65) #4
  %isneg = icmp slt i32 %const_reg_dword, 0
  br label %.lr.ph

.lr.ph:                                           ; preds = %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, %.lr.ph.preheader
  %70 = phi i64 [ %347, %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge ], [ %34, %.lr.ph.preheader ]
  %71 = bitcast i64 %70 to <2 x i32>
  %72 = extractelement <2 x i32> %71, i32 0
  %73 = extractelement <2 x i32> %71, i32 1
  %74 = icmp ult i32 %72, %7
  %75 = icmp eq i32 %73, %8
  %76 = and i1 %75, %74
  %77 = icmp ult i32 %73, %8
  %78 = or i1 %76, %77
  %79 = select i1 %78, i32 %10, i32 %13
  %80 = select i1 %78, i32 %11, i32 %14
  %81 = insertelement <2 x i32> undef, i32 %79, i32 0
  %82 = insertelement <2 x i32> %81, i32 %80, i32 1
  %83 = bitcast <2 x i32> %82 to i64
  %84 = select i1 %78, i32 0, i32 %7
  %85 = select i1 %78, i32 0, i32 %8
  %86 = insertelement <2 x i32> undef, i32 %84, i32 0
  %87 = insertelement <2 x i32> %86, i32 %85, i32 1
  %88 = bitcast <2 x i32> %87 to i64
  %89 = sub nsw i64 %70, %88, !spirv.Decorations !615
  %90 = bitcast i64 %89 to <2 x i32>
  %91 = extractelement <2 x i32> %90, i32 0
  %92 = extractelement <2 x i32> %90, i32 1
  %93 = or i32 %48, %92
  %94 = icmp ult i32 %93, 1
  br i1 %94, label %95, label %113

95:                                               ; preds = %.lr.ph
  %96 = trunc nuw i64 %89 to i32
  br i1 %tobool.i37, label %.precompiled_u32divrem_sp.exit59_crit_edge, label %if.end.i38

.precompiled_u32divrem_sp.exit59_crit_edge:       ; preds = %95
  br label %precompiled_u32divrem_sp.exit59

if.end.i38:                                       ; preds = %95
  %97 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %52)
  %conv.i39 = fptoui float %97 to i32
  %sub.i40 = sub i32 %52, %conv.i39
  %98 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i40)
  %99 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %96)
  %conv3.i41 = fptoui float %99 to i32
  %sub4.i42 = sub i32 %96, %conv3.i41
  %100 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i42)
  %div.i43 = fdiv float 1.000000e+00, %97, !fpmath !617
  %101 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i43, float 0xBE98000000000000, float %div.i43)
  %102 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %99, float %101)
  %conv8.i44 = fptoui float %102 to i32
  %103 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i44)
  %104 = fsub float 0.000000e+00, %97
  %105 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %104, float %103, float %99)
  %106 = fsub float 0.000000e+00, %98
  %107 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %106, float %103, float %100)
  %108 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %105, float %107)
  %109 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %101, float %108)
  %conv16.i47 = fptoui float %109 to i32
  %add.i48 = add i32 %conv16.i47, %conv8.i44
  %mul.i49 = mul i32 %add.i48, %52
  %sub17.i50 = sub i32 %96, %mul.i49
  %cmp.i51 = icmp uge i32 %sub17.i50, %52
  %110 = sext i1 %cmp.i51 to i32
  %111 = sub i32 0, %110
  %add19.i54 = add i32 %add.i48, %111
  br label %precompiled_u32divrem_sp.exit59

precompiled_u32divrem_sp.exit59:                  ; preds = %.precompiled_u32divrem_sp.exit59_crit_edge, %if.end.i38
  %retval.0.i58 = phi i32 [ %add19.i54, %if.end.i38 ], [ -1, %.precompiled_u32divrem_sp.exit59_crit_edge ]
  %112 = zext i32 %retval.0.i58 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit

113:                                              ; preds = %.lr.ph
  %114 = bitcast i64 %89 to <2 x i32>
  %115 = extractelement <2 x i32> %114, i32 1
  %116 = uitofp i32 %115 to double
  %117 = fmul double %60, %116
  %118 = fptoui double %117 to i32
  %119 = mul i32 %118, %52
  %120 = sub i32 %115, %119
  %121 = uitofp i32 %120 to double
  %122 = trunc i64 %89 to i32
  %123 = uitofp i32 %122 to double
  %124 = call double @llvm.fma.f64(double %121, double 0x41F0000000000000, double %123) #4
  %125 = fmul double %60, %124
  %126 = fptoui double %125 to i64
  %127 = bitcast i64 %126 to <2 x i32>
  %128 = extractelement <2 x i32> %127, i32 0
  %129 = trunc i64 %126 to i32
  %130 = lshr i64 %126, 32
  %131 = bitcast i64 %130 to <2 x i32>
  %132 = extractelement <2 x i32> %131, i32 0
  %133 = extractelement <2 x i32> %131, i32 1
  %134 = bitcast i64 %126 to <2 x i32>
  %135 = extractelement <2 x i32> %134, i32 1
  %136 = icmp eq i32 %132, 0
  %137 = icmp eq i32 %133, 0
  %138 = and i1 %137, %136
  %139 = mul i32 %129, %48
  %140 = select i1 %138, i32 0, i32 %52
  %141 = add i32 %139, %140
  %142 = sub i32 %120, %141
  %143 = insertelement <2 x i32> undef, i32 %91, i32 0
  %144 = insertelement <2 x i32> %143, i32 %142, i32 1
  %145 = bitcast <2 x i32> %144 to i64
  %146 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %128, i32 0, i32 %61, i32 0)
  %147 = extractvalue { i32, i32 } %146, 0
  %148 = extractvalue { i32, i32 } %146, 1
  %149 = insertelement <2 x i32> undef, i32 %147, i32 0
  %150 = insertelement <2 x i32> %149, i32 %148, i32 1
  %151 = bitcast <2 x i32> %150 to i64
  %152 = sub i64 %145, %151
  %153 = bitcast i64 %152 to <2 x i32>
  %154 = extractelement <2 x i32> %153, i32 0
  %155 = extractelement <2 x i32> %153, i32 1
  %156 = add i32 %135, %118
  %157 = insertelement <2 x i32> undef, i32 %128, i32 0
  %158 = insertelement <2 x i32> %157, i32 %156, i32 1
  %159 = bitcast <2 x i32> %158 to i64
  %160 = icmp uge i32 %154, %47
  %161 = icmp eq i32 %155, %48
  %162 = and i1 %161, %160
  %163 = icmp ugt i32 %155, %48
  %164 = or i1 %162, %163
  %165 = sext i1 %164 to i64
  %166 = sub i64 0, %165
  %167 = add i64 %159, %166
  br label %__igcbuiltin_u64_udiv_dp.exit

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit59, %113
  %168 = phi i64 [ %112, %precompiled_u32divrem_sp.exit59 ], [ %167, %113 ]
  %169 = icmp ult i32 %92, 1
  br i1 %169, label %udiv_pow2_64b_as_32b, label %udiv_pow2_64b

udiv_pow2_64b_as_32b:                             ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %170 = trunc nuw i64 %89 to i32
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %170, i32 -858993459)
  %q_appx34 = lshr i32 %q_appx, 9
  %171 = zext nneg i32 %q_appx34 to i64
  br label %205

udiv_pow2_64b:                                    ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %u.hi32 = lshr i64 %89, 32
  %172 = bitcast i64 %u.hi32 to <2 x i32>
  %173 = extractelement <2 x i32> %172, i32 0
  %174 = extractelement <2 x i32> %172, i32 1
  %175 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %91, i32 0, i32 -858993459, i32 0)
  %176 = extractvalue { i32, i32 } %175, 0
  %177 = extractvalue { i32, i32 } %175, 1
  %178 = insertelement <2 x i32> undef, i32 %176, i32 0
  %179 = insertelement <2 x i32> %178, i32 %177, i32 1
  %180 = bitcast <2 x i32> %179 to i64
  %181 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %173, i32 %174, i32 -858993459, i32 0)
  %182 = extractvalue { i32, i32 } %181, 0
  %183 = extractvalue { i32, i32 } %181, 1
  %184 = insertelement <2 x i32> undef, i32 %182, i32 0
  %185 = insertelement <2 x i32> %184, i32 %183, i32 1
  %186 = bitcast <2 x i32> %185 to i64
  %w0.lo32 = lshr i64 %180, 32
  %t = add nuw i64 %186, %w0.lo32
  %187 = bitcast i64 %t to <2 x i32>
  %188 = extractelement <2 x i32> %187, i32 0
  %189 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %91, i32 0, i32 -858993460, i32 0)
  %190 = extractvalue { i32, i32 } %189, 0
  %191 = extractvalue { i32, i32 } %189, 1
  %192 = insertelement <2 x i32> undef, i32 %190, i32 0
  %193 = insertelement <2 x i32> %192, i32 %191, i32 1
  %194 = bitcast <2 x i32> %193 to i64
  %195 = insertelement <2 x i32> undef, i32 %188, i32 0
  %196 = insertelement <2 x i32> %195, i32 0, i32 1
  %197 = bitcast <2 x i32> %196 to i64
  %w1 = add nuw i64 %194, %197
  %198 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %173, i32 %174, i32 -858993460, i32 0)
  %199 = extractvalue { i32, i32 } %198, 0
  %200 = extractvalue { i32, i32 } %198, 1
  %201 = insertelement <2 x i32> undef, i32 %199, i32 0
  %202 = insertelement <2 x i32> %201, i32 %200, i32 1
  %203 = bitcast <2 x i32> %202 to i64
  %t.hi32 = lshr i64 %t, 32
  %204 = add nuw i64 %203, %t.hi32
  %w1.lo32 = lshr i64 %w1, 32
  %uv = add nuw i64 %204, %w1.lo32
  %q_appx35 = lshr i64 %uv, 9
  br label %205

205:                                              ; preds = %udiv_pow2_64b, %udiv_pow2_64b_as_32b
  %206 = phi i64 [ %171, %udiv_pow2_64b_as_32b ], [ %q_appx35, %udiv_pow2_64b ]
  %207 = bitcast i64 %206 to <2 x i32>
  %208 = extractelement <2 x i32> %207, i32 0
  %209 = extractelement <2 x i32> %207, i32 1
  %210 = or i32 %209, %45
  %211 = icmp ult i32 %210, 1
  br i1 %211, label %212, label %228

212:                                              ; preds = %205
  %213 = trunc nuw i64 %206 to i32
  br i1 %tobool.i37, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %212
  br label %precompiled_u32divrem_sp.exit

if.end.i:                                         ; preds = %212
  %214 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword)
  %conv.i = fptoui float %214 to i32
  %sub.i = sub i32 %const_reg_dword, %conv.i
  %215 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %216 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %213)
  %conv3.i = fptoui float %216 to i32
  %sub4.i = sub i32 %213, %conv3.i
  %217 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %div.i = fdiv float 1.000000e+00, %214, !fpmath !617
  %218 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %219 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %216, float %218)
  %conv8.i = fptoui float %219 to i32
  %220 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %221 = fsub float 0.000000e+00, %214
  %222 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %221, float %220, float %216)
  %223 = fsub float 0.000000e+00, %215
  %224 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %223, float %220, float %217)
  %225 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %222, float %224)
  %226 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %218, float %225)
  %conv16.i = fptoui float %226 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %const_reg_dword
  %sub17.i = sub i32 %213, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %227 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit

228:                                              ; preds = %205
  %229 = bitcast i64 %206 to <2 x i32>
  %230 = extractelement <2 x i32> %229, i32 1
  %231 = uitofp nneg i32 %230 to double
  %232 = fmul double %69, %231
  %233 = fptoui double %232 to i32
  %234 = mul i32 %const_reg_dword, %233
  %235 = sub i32 %230, %234
  %236 = uitofp i32 %235 to double
  %237 = trunc i64 %206 to i32
  %238 = uitofp i32 %237 to double
  %239 = call double @llvm.fma.f64(double %236, double 0x41F0000000000000, double %238) #4
  %240 = fmul double %69, %239
  %241 = fptoui double %240 to i64
  %242 = bitcast i64 %241 to <2 x i32>
  %243 = extractelement <2 x i32> %242, i32 0
  %244 = extractelement <2 x i32> %242, i32 1
  %245 = trunc i64 %241 to i32
  %246 = icmp ult i32 %244, 1
  %.neg60 = select i1 %isneg, i32 %245, i32 0
  %247 = select i1 %246, i32 0, i32 %const_reg_dword
  %248 = sub i32 %235, %247
  %249 = add i32 %.neg60, %248
  %250 = insertelement <2 x i32> undef, i32 %208, i32 0
  %251 = insertelement <2 x i32> %250, i32 %249, i32 1
  %252 = bitcast <2 x i32> %251 to i64
  %253 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %243, i32 0, i32 %const_reg_dword, i32 0)
  %254 = extractvalue { i32, i32 } %253, 0
  %255 = extractvalue { i32, i32 } %253, 1
  %256 = insertelement <2 x i32> undef, i32 %254, i32 0
  %257 = insertelement <2 x i32> %256, i32 %255, i32 1
  %258 = bitcast <2 x i32> %257 to i64
  %259 = sub i64 %252, %258
  %260 = bitcast i64 %259 to <2 x i32>
  %261 = extractelement <2 x i32> %260, i32 0
  %262 = extractelement <2 x i32> %260, i32 1
  %263 = icmp ult i32 %261, %const_reg_dword
  %264 = icmp eq i32 %262, %45
  %265 = and i1 %264, %263
  %266 = icmp ult i32 %262, %45
  %267 = or i1 %265, %266
  %268 = select i1 %267, i32 0, i32 %const_reg_dword
  %269 = select i1 %267, i32 0, i32 %45
  %270 = insertelement <2 x i32> undef, i32 %268, i32 0
  %271 = insertelement <2 x i32> %270, i32 %269, i32 1
  %272 = bitcast <2 x i32> %271 to i64
  %273 = sub i64 %259, %272
  br label %__igcbuiltin_u64_urem_dp.exit

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %228
  %274 = phi i64 [ %227, %precompiled_u32divrem_sp.exit ], [ %273, %228 ]
  %275 = bitcast i64 %168 to <2 x i32>
  %276 = extractelement <2 x i32> %275, i32 0
  %277 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %276, i32 1
  %278 = bitcast <2 x i32> %277 to i64
  %279 = bitcast i64 %274 to <2 x i32>
  %280 = extractelement <2 x i32> %279, i32 0
  %281 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %280, i32 1
  %282 = bitcast <2 x i32> %281 to i64
  %283 = ashr exact i64 %282, 32
  %284 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %208, i32 %209, i32 -2560, i32 -1)
  %285 = extractvalue { i32, i32 } %284, 0
  %286 = extractvalue { i32, i32 } %284, 1
  %287 = insertelement <2 x i32> undef, i32 %285, i32 0
  %288 = insertelement <2 x i32> %287, i32 %286, i32 1
  %289 = bitcast <2 x i32> %288 to i64
  %290 = add i64 %83, %289
  %291 = shl i64 %89, 2
  %292 = add i64 %290, %291
  %293 = ashr exact i64 %278, 28
  %294 = add nsw i64 %293, %283, !spirv.Decorations !615
  %295 = bitcast i64 %294 to <2 x i32>
  %296 = extractelement <2 x i32> %295, i32 0
  %297 = extractelement <2 x i32> %295, i32 1
  %298 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %296, i32 %297, i32 2560, i32 0)
  %299 = extractvalue { i32, i32 } %298, 0
  %300 = extractvalue { i32, i32 } %298, 1
  %301 = insertelement <2 x i32> undef, i32 %299, i32 0
  %302 = insertelement <2 x i32> %301, i32 %300, i32 1
  %303 = bitcast <2 x i32> %302 to i64
  %304 = add i64 %292, %303
  %305 = inttoptr i64 %304 to ptr addrspace(4)
  %306 = addrspacecast ptr addrspace(4) %305 to ptr addrspace(1)
  %307 = load i32, ptr addrspace(1) %306, align 4
  %308 = add i64 %304, 409600
  %309 = inttoptr i64 %308 to ptr addrspace(4)
  %310 = addrspacecast ptr addrspace(4) %309 to ptr addrspace(1)
  %311 = load i32, ptr addrspace(1) %310, align 4
  %312 = add nsw i32 %307, %311, !spirv.Decorations !615
  %313 = select i1 %78, i32 %16, i32 %19
  %314 = select i1 %78, i32 %17, i32 %20
  %315 = insertelement <2 x i32> undef, i32 %313, i32 0
  %316 = insertelement <2 x i32> %315, i32 %314, i32 1
  %317 = bitcast <2 x i32> %316 to i64
  %318 = ashr exact i64 %282, 30
  %319 = add i64 %const_reg_qword9, %318
  %320 = inttoptr i64 %319 to ptr addrspace(1)
  %321 = load float, ptr addrspace(1) %320, align 4
  %322 = fmul reassoc nsz arcp contract float %321, 0x3F7B717580000000, !spirv.Decorations !618
  %323 = sitofp i32 %312 to float
  %324 = add i64 %const_reg_qword10, %318
  %325 = inttoptr i64 %324 to ptr addrspace(1)
  %326 = load i32, ptr addrspace(1) %325, align 4
  %327 = sitofp i32 %326 to float
  %328 = fmul reassoc nnan nsz arcp contract float %327, 5.100000e+02, !spirv.Decorations !620
  %329 = fsub reassoc nnan nsz arcp contract float %323, %328, !spirv.Decorations !620
  %330 = fmul reassoc nsz arcp contract float %322, %329, !spirv.Decorations !618
  %331 = add i64 %317, %291
  %332 = inttoptr i64 %331 to ptr addrspace(4)
  %333 = addrspacecast ptr addrspace(4) %332 to ptr addrspace(1)
  store float %330, ptr addrspace(1) %333, align 4
  %334 = add nuw nsw i64 %70, %38
  %335 = bitcast i64 %334 to <2 x i32>
  %336 = extractelement <2 x i32> %335, i32 0
  %337 = extractelement <2 x i32> %335, i32 1
  %338 = icmp ult i32 %336, %4
  %339 = icmp eq i32 %337, %5
  %340 = and i1 %339, %338
  %341 = icmp ult i32 %337, %5
  %342 = or i1 %340, %341
  %343 = select i1 %342, i32 %336, i32 %36
  %344 = select i1 %342, i32 %337, i32 %37
  %345 = insertelement <2 x i32> undef, i32 %343, i32 0
  %346 = insertelement <2 x i32> %345, i32 %344, i32 1
  %347 = bitcast <2 x i32> %346 to i64
  br i1 %342, label %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, label %._crit_edge.loopexit

__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge:   ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %.lr.ph

._crit_edge.loopexit:                             ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %._crit_edge

._crit_edge:                                      ; preds = %.._crit_edge_crit_edge, %._crit_edge.loopexit
  ret void
}

; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_(i32 %0, ptr addrspace(1) align 4 %1, ptr addrspace(1) align 4 %2, ptr addrspace(1) align 4 %3, ptr addrspace(1) align 4 %4, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i32 %bufferOffset, i32 %bufferOffset1, i32 %bufferOffset2, i32 %bufferOffset3, i32 %bindlessOffset, i32 %bindlessOffset4, i32 %bindlessOffset5, i32 %bindlessOffset6) #0 {
  %6 = extractelement <3 x i32> %globalOffset, i32 0
  %7 = extractelement <3 x i32> %enqueuedLocalSize, i32 0
  %8 = extractelement <8 x i32> %r0, i32 1
  %9 = mul i32 %7, %8
  %10 = zext i16 %localIdX to i32
  %11 = add i32 %9, %10
  %12 = add i32 %11, %6
  %13 = zext nneg i32 %12 to i64
  %14 = sext i32 %0 to i64
  %15 = ashr i32 %0, 31
  %16 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %0, i32 %15, i32 640, i32 0)
  %17 = extractvalue { i32, i32 } %16, 0
  %18 = extractvalue { i32, i32 } %16, 1
  %19 = insertelement <2 x i32> undef, i32 %17, i32 0
  %20 = insertelement <2 x i32> %19, i32 %18, i32 1
  %21 = bitcast <2 x i32> %20 to i64
  %22 = icmp ult i32 %18, 1
  br i1 %22, label %23, label %41

23:                                               ; preds = %5
  %24 = trunc nuw i64 %21 to i32
  %tobool.i27 = icmp eq i32 %0, 0
  br i1 %tobool.i27, label %.precompiled_u32divrem_sp.exit49_crit_edge, label %if.end.i28

.precompiled_u32divrem_sp.exit49_crit_edge:       ; preds = %23
  br label %precompiled_u32divrem_sp.exit49

if.end.i28:                                       ; preds = %23
  %25 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %24)
  %conv.i29 = fptoui float %25 to i32
  %sub.i30 = sub i32 %24, %conv.i29
  %26 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i30)
  %27 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %12)
  %conv3.i31 = fptoui float %27 to i32
  %sub4.i32 = sub i32 %12, %conv3.i31
  %28 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i32)
  %div.i33 = fdiv float 1.000000e+00, %25, !fpmath !617
  %29 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i33, float 0xBE98000000000000, float %div.i33)
  %30 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %27, float %29)
  %conv8.i34 = fptoui float %30 to i32
  %31 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i34)
  %32 = fsub float 0.000000e+00, %25
  %33 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %32, float %31, float %27)
  %34 = fsub float 0.000000e+00, %26
  %35 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %34, float %31, float %28)
  %36 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %33, float %35)
  %37 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %29, float %36)
  %conv16.i37 = fptoui float %37 to i32
  %add.i38 = add i32 %conv16.i37, %conv8.i34
  %mul.i39 = mul i32 %add.i38, %24
  %sub17.i40 = sub i32 %12, %mul.i39
  %cmp.i41 = icmp uge i32 %sub17.i40, %24
  %38 = sext i1 %cmp.i41 to i32
  %39 = sub i32 0, %38
  %add19.i44 = add i32 %add.i38, %39
  br label %precompiled_u32divrem_sp.exit49

precompiled_u32divrem_sp.exit49:                  ; preds = %.precompiled_u32divrem_sp.exit49_crit_edge, %if.end.i28
  %retval.0.i48 = phi i32 [ %add19.i44, %if.end.i28 ], [ -1, %.precompiled_u32divrem_sp.exit49_crit_edge ]
  %40 = zext i32 %retval.0.i48 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit

41:                                               ; preds = %5
  %42 = trunc i64 %21 to i32
  %43 = uitofp i64 %21 to double
  %44 = fptrunc double %43 to float
  %45 = fdiv float 1.000000e+00, %44
  %46 = fpext float %45 to double
  %47 = fsub double 0.000000e+00, %43
  %48 = call double @llvm.fma.f64(double %47, double %46, double 1.000000e+00) #4
  %49 = fadd double %48, 0xBCF0000000000000
  %50 = call double @llvm.fma.f64(double %46, double %49, double %46) #4
  %51 = uitofp nneg i32 %12 to double
  %52 = fmul double %50, %51
  %53 = fptoui double %52 to i64
  %54 = bitcast i64 %53 to <2 x i32>
  %55 = extractelement <2 x i32> %54, i32 0
  %56 = extractelement <2 x i32> %54, i32 1
  %57 = trunc i64 %53 to i32
  %58 = icmp ult i32 %56, 1
  %59 = mul i32 %57, %18
  %60 = select i1 %58, i32 0, i32 %42
  %61 = add i32 %59, %60
  %62 = sub i32 0, %61
  %63 = insertelement <2 x i32> undef, i32 %12, i32 0
  %64 = insertelement <2 x i32> %63, i32 %62, i32 1
  %65 = bitcast <2 x i32> %64 to i64
  %66 = and i32 %17, -128
  %67 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %55, i32 0, i32 %66, i32 0)
  %68 = extractvalue { i32, i32 } %67, 0
  %69 = extractvalue { i32, i32 } %67, 1
  %70 = insertelement <2 x i32> undef, i32 %68, i32 0
  %71 = insertelement <2 x i32> %70, i32 %69, i32 1
  %72 = bitcast <2 x i32> %71 to i64
  %73 = sub i64 %65, %72
  %74 = bitcast i64 %73 to <2 x i32>
  %75 = extractelement <2 x i32> %74, i32 0
  %76 = extractelement <2 x i32> %74, i32 1
  %77 = icmp uge i32 %75, %17
  %78 = icmp eq i32 %76, %18
  %79 = and i1 %78, %77
  %80 = icmp ugt i32 %76, %18
  %81 = or i1 %79, %80
  %82 = sext i1 %81 to i64
  %83 = sub i64 0, %82
  %84 = add i64 %53, %83
  br label %__igcbuiltin_u64_udiv_dp.exit

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit49, %41
  %85 = phi i64 [ %40, %precompiled_u32divrem_sp.exit49 ], [ %84, %41 ]
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %12, i32 -858993459)
  %q_appx25 = lshr i32 %q_appx, 9
  %86 = icmp sgt i32 %0, -1
  br i1 %86, label %87, label %102

87:                                               ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %tobool.i = icmp eq i32 %0, 0
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %87
  br label %precompiled_u32divrem_sp.exit

if.end.i:                                         ; preds = %87
  %88 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %0)
  %conv.i = fptoui float %88 to i32
  %sub.i = sub i32 %0, %conv.i
  %89 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %90 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %q_appx25)
  %conv3.i = fptoui float %90 to i32
  %sub4.i = sub i32 %q_appx25, %conv3.i
  %91 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %div.i = fdiv float 1.000000e+00, %88, !fpmath !617
  %92 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %93 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %90, float %92)
  %conv8.i = fptoui float %93 to i32
  %94 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %95 = fsub float 0.000000e+00, %88
  %96 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %95, float %94, float %90)
  %97 = fsub float 0.000000e+00, %89
  %98 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %97, float %94, float %91)
  %99 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %96, float %98)
  %100 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %92, float %99)
  %conv16.i = fptoui float %100 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %0
  %sub17.i = sub i32 %q_appx25, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %0
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %0
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %101 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit

102:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %103 = uitofp i64 %14 to double
  %104 = fptrunc double %103 to float
  %105 = fdiv float 1.000000e+00, %104
  %106 = fpext float %105 to double
  %107 = fsub double 0.000000e+00, %103
  %108 = call double @llvm.fma.f64(double %107, double %106, double 1.000000e+00) #4
  %109 = fadd double %108, 0xBCF0000000000000
  %110 = call double @llvm.fma.f64(double %106, double %109, double %106) #4
  %111 = uitofp nneg i32 %q_appx25 to double
  %112 = fmul double %110, %111
  %113 = fptoui double %112 to i64
  %114 = bitcast i64 %113 to <2 x i32>
  %115 = extractelement <2 x i32> %114, i32 0
  %116 = extractelement <2 x i32> %114, i32 1
  %117 = trunc i64 %113 to i32
  %118 = icmp ult i32 %116, 1
  %119 = select i1 %118, i32 0, i32 %0
  %120 = sub i32 %117, %119
  %121 = insertelement <2 x i32> undef, i32 %q_appx25, i32 0
  %122 = insertelement <2 x i32> %121, i32 %120, i32 1
  %123 = bitcast <2 x i32> %122 to i64
  %124 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %115, i32 0, i32 %0, i32 0)
  %125 = extractvalue { i32, i32 } %124, 0
  %126 = extractvalue { i32, i32 } %124, 1
  %127 = insertelement <2 x i32> undef, i32 %125, i32 0
  %128 = insertelement <2 x i32> %127, i32 %126, i32 1
  %129 = bitcast <2 x i32> %128 to i64
  %130 = sub i64 %123, %129
  %131 = bitcast i64 %130 to <2 x i32>
  %132 = extractelement <2 x i32> %131, i32 0
  %133 = extractelement <2 x i32> %131, i32 1
  %134 = icmp ult i32 %132, %0
  %135 = icmp eq i32 %133, %15
  %136 = and i1 %135, %134
  %137 = icmp ult i32 %133, %15
  %138 = or i1 %136, %137
  %139 = select i1 %138, i32 0, i32 %0
  %140 = select i1 %138, i32 0, i32 %15
  %141 = insertelement <2 x i32> undef, i32 %139, i32 0
  %142 = insertelement <2 x i32> %141, i32 %140, i32 1
  %143 = bitcast <2 x i32> %142 to i64
  %144 = sub i64 %130, %143
  br label %__igcbuiltin_u64_urem_dp.exit

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %102
  %145 = phi i64 [ %101, %precompiled_u32divrem_sp.exit ], [ %144, %102 ]
  %.neg = mul nsw i32 %q_appx25, -640
  %146 = add nsw i32 %.neg, %12
  %147 = zext i32 %146 to i64
  %148 = ptrtoint ptr addrspace(1) %1 to i64
  %149 = shl nuw nsw i64 %147, 2
  %150 = add i64 %149, %148
  %151 = shl nuw nsw i64 %85, 4, !spirv.Decorations !622
  %152 = add nuw nsw i64 %151, %145, !spirv.Decorations !622
  %153 = bitcast i64 %152 to <2 x i32>
  %154 = extractelement <2 x i32> %153, i32 0
  %155 = extractelement <2 x i32> %153, i32 1
  %156 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %154, i32 %155, i32 2560, i32 0)
  %157 = extractvalue { i32, i32 } %156, 0
  %158 = extractvalue { i32, i32 } %156, 1
  %159 = insertelement <2 x i32> undef, i32 %157, i32 0
  %160 = insertelement <2 x i32> %159, i32 %158, i32 1
  %161 = bitcast <2 x i32> %160 to i64
  %162 = add i64 %150, %161
  %163 = inttoptr i64 %162 to ptr addrspace(1)
  %164 = load i32, ptr addrspace(1) %163, align 4
  %165 = add i64 %162, 409600
  %166 = inttoptr i64 %165 to ptr addrspace(1)
  %167 = load i32, ptr addrspace(1) %166, align 4
  %168 = add nsw i32 %164, %167, !spirv.Decorations !615
  %169 = ptrtoint ptr addrspace(1) %3 to i64
  %170 = shl i64 %145, 2
  %171 = add i64 %170, %169
  %172 = inttoptr i64 %171 to ptr addrspace(1)
  %173 = load float, ptr addrspace(1) %172, align 4
  %174 = fmul reassoc nsz arcp contract float %173, 0x3F7B717580000000, !spirv.Decorations !618
  %175 = sitofp i32 %168 to float
  %176 = ptrtoint ptr addrspace(1) %4 to i64
  %177 = add i64 %170, %176
  %178 = inttoptr i64 %177 to ptr addrspace(1)
  %179 = load i32, ptr addrspace(1) %178, align 4
  %180 = sitofp i32 %179 to float
  %181 = fmul reassoc nnan nsz arcp contract float %180, 5.100000e+02, !spirv.Decorations !620
  %182 = fsub reassoc nnan nsz arcp contract float %175, %181, !spirv.Decorations !620
  %183 = fmul reassoc nsz arcp contract float %174, %182, !spirv.Decorations !618
  %184 = ptrtoint ptr addrspace(1) %2 to i64
  %185 = shl nuw nsw i64 %13, 2
  %186 = add i64 %185, %184
  %187 = inttoptr i64 %186 to ptr addrspace(1)
  store float %183, ptr addrspace(1) %187, align 4
  ret void
}

; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL5splitRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE(ptr byval(%"class.sycl::_V1::range") align 8 %0, ptr byval(%class._ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_) align 8 %1, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %globalSize, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i64 %const_reg_qword, i32 %const_reg_dword, i8 %const_reg_byte, i8 %const_reg_byte1, i8 %const_reg_byte2, i8 %const_reg_byte3, i64 %const_reg_qword4, i64 %const_reg_qword5, i64 %const_reg_qword6, i64 %const_reg_qword7) #0 {
  %3 = bitcast i64 %const_reg_qword to <2 x i32>
  %4 = extractelement <2 x i32> %3, i32 0
  %5 = extractelement <2 x i32> %3, i32 1
  %6 = extractelement <3 x i32> %globalSize, i32 0
  %7 = extractelement <3 x i32> %globalOffset, i32 0
  %8 = extractelement <3 x i32> %enqueuedLocalSize, i32 0
  %9 = extractelement <8 x i32> %r0, i32 1
  %10 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %8, i32 0, i32 %9, i32 0)
  %11 = extractvalue { i32, i32 } %10, 0
  %12 = extractvalue { i32, i32 } %10, 1
  %13 = insertelement <2 x i32> undef, i32 %11, i32 0
  %14 = insertelement <2 x i32> %13, i32 %12, i32 1
  %15 = bitcast <2 x i32> %14 to i64
  %16 = zext i16 %localIdX to i64
  %17 = add nuw i64 %15, %16
  %18 = zext i32 %7 to i64
  %19 = add nuw i64 %17, %18
  %20 = bitcast i64 %19 to <2 x i32>
  %21 = extractelement <2 x i32> %20, i32 0
  %22 = extractelement <2 x i32> %20, i32 1
  %23 = zext i32 %6 to i64
  %24 = icmp ult i32 %21, %4
  %25 = icmp eq i32 %22, %5
  %26 = and i1 %25, %24
  %27 = icmp ult i32 %22, %5
  %28 = or i1 %26, %27
  %29 = sext i32 %const_reg_dword to i64
  %30 = ashr i32 %const_reg_dword, 31
  %31 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %const_reg_dword, i32 %30, i32 640, i32 0)
  %32 = extractvalue { i32, i32 } %31, 0
  %33 = extractvalue { i32, i32 } %31, 1
  %34 = insertelement <2 x i32> undef, i32 %32, i32 0
  %35 = insertelement <2 x i32> %34, i32 %33, i32 1
  %36 = bitcast <2 x i32> %35 to i64
  br i1 %28, label %.lr.ph.preheader, label %.._crit_edge_crit_edge

.._crit_edge_crit_edge:                           ; preds = %2
  br label %._crit_edge

.lr.ph.preheader:                                 ; preds = %2
  %37 = trunc i64 %36 to i32
  %38 = uitofp i64 %36 to double
  %39 = fptrunc double %38 to float
  %40 = fdiv float 1.000000e+00, %39
  %41 = fpext float %40 to double
  %42 = fsub double 0.000000e+00, %38
  %43 = call double @llvm.fma.f64(double %42, double %41, double 1.000000e+00) #4
  %44 = fadd double %43, 0xBCF0000000000000
  %45 = call double @llvm.fma.f64(double %41, double %44, double %41) #4
  %46 = and i32 %32, -128
  %tobool.i32 = icmp eq i32 %const_reg_dword, 0
  %47 = icmp sgt i32 %const_reg_dword, -1
  %48 = uitofp i64 %29 to double
  %49 = fptrunc double %48 to float
  %50 = fdiv float 1.000000e+00, %49
  %51 = fpext float %50 to double
  %52 = fsub double 0.000000e+00, %48
  %53 = call double @llvm.fma.f64(double %52, double %51, double 1.000000e+00) #4
  %54 = fadd double %53, 0xBCF0000000000000
  %55 = call double @llvm.fma.f64(double %51, double %54, double %51) #4
  br label %.lr.ph

.lr.ph:                                           ; preds = %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, %.lr.ph.preheader
  %56 = phi i64 [ %239, %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge ], [ %19, %.lr.ph.preheader ]
  %57 = bitcast i64 %56 to <2 x i32>
  %58 = extractelement <2 x i32> %57, i32 0
  %59 = extractelement <2 x i32> %57, i32 1
  %60 = or i32 %33, %59
  %61 = icmp ult i32 %60, 1
  br i1 %61, label %62, label %80

62:                                               ; preds = %.lr.ph
  %63 = trunc nuw i64 %56 to i32
  br i1 %tobool.i32, label %.precompiled_u32divrem_sp.exit54_crit_edge, label %if.end.i33

.precompiled_u32divrem_sp.exit54_crit_edge:       ; preds = %62
  br label %precompiled_u32divrem_sp.exit54

if.end.i33:                                       ; preds = %62
  %64 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %37)
  %conv.i34 = fptoui float %64 to i32
  %sub.i35 = sub i32 %37, %conv.i34
  %65 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i35)
  %66 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %63)
  %conv3.i36 = fptoui float %66 to i32
  %sub4.i37 = sub i32 %63, %conv3.i36
  %67 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i37)
  %div.i38 = fdiv float 1.000000e+00, %64, !fpmath !617
  %68 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i38, float 0xBE98000000000000, float %div.i38)
  %69 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %66, float %68)
  %conv8.i39 = fptoui float %69 to i32
  %70 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i39)
  %71 = fsub float 0.000000e+00, %64
  %72 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %71, float %70, float %66)
  %73 = fsub float 0.000000e+00, %65
  %74 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %73, float %70, float %67)
  %75 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %72, float %74)
  %76 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %68, float %75)
  %conv16.i42 = fptoui float %76 to i32
  %add.i43 = add i32 %conv16.i42, %conv8.i39
  %mul.i44 = mul i32 %add.i43, %37
  %sub17.i45 = sub i32 %63, %mul.i44
  %cmp.i46 = icmp uge i32 %sub17.i45, %37
  %77 = sext i1 %cmp.i46 to i32
  %78 = sub i32 0, %77
  %add19.i49 = add i32 %add.i43, %78
  br label %precompiled_u32divrem_sp.exit54

precompiled_u32divrem_sp.exit54:                  ; preds = %.precompiled_u32divrem_sp.exit54_crit_edge, %if.end.i33
  %retval.0.i53 = phi i32 [ %add19.i49, %if.end.i33 ], [ -1, %.precompiled_u32divrem_sp.exit54_crit_edge ]
  %79 = zext i32 %retval.0.i53 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit

80:                                               ; preds = %.lr.ph
  %81 = bitcast i64 %56 to <2 x i32>
  %82 = extractelement <2 x i32> %81, i32 1
  %83 = uitofp i32 %82 to double
  %84 = fmul double %45, %83
  %85 = fptoui double %84 to i32
  %86 = mul i32 %85, %37
  %87 = sub i32 %82, %86
  %88 = uitofp i32 %87 to double
  %89 = trunc i64 %56 to i32
  %90 = uitofp i32 %89 to double
  %91 = call double @llvm.fma.f64(double %88, double 0x41F0000000000000, double %90) #4
  %92 = fmul double %45, %91
  %93 = fptoui double %92 to i64
  %94 = bitcast i64 %93 to <2 x i32>
  %95 = extractelement <2 x i32> %94, i32 0
  %96 = trunc i64 %93 to i32
  %97 = lshr i64 %93, 32
  %98 = bitcast i64 %97 to <2 x i32>
  %99 = extractelement <2 x i32> %98, i32 0
  %100 = extractelement <2 x i32> %98, i32 1
  %101 = bitcast i64 %93 to <2 x i32>
  %102 = extractelement <2 x i32> %101, i32 1
  %103 = icmp eq i32 %99, 0
  %104 = icmp eq i32 %100, 0
  %105 = and i1 %104, %103
  %106 = mul i32 %96, %33
  %107 = select i1 %105, i32 0, i32 %37
  %108 = add i32 %106, %107
  %109 = sub i32 %87, %108
  %110 = insertelement <2 x i32> undef, i32 %58, i32 0
  %111 = insertelement <2 x i32> %110, i32 %109, i32 1
  %112 = bitcast <2 x i32> %111 to i64
  %113 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %95, i32 0, i32 %46, i32 0)
  %114 = extractvalue { i32, i32 } %113, 0
  %115 = extractvalue { i32, i32 } %113, 1
  %116 = insertelement <2 x i32> undef, i32 %114, i32 0
  %117 = insertelement <2 x i32> %116, i32 %115, i32 1
  %118 = bitcast <2 x i32> %117 to i64
  %119 = sub i64 %112, %118
  %120 = bitcast i64 %119 to <2 x i32>
  %121 = extractelement <2 x i32> %120, i32 0
  %122 = extractelement <2 x i32> %120, i32 1
  %123 = add i32 %102, %85
  %124 = insertelement <2 x i32> undef, i32 %95, i32 0
  %125 = insertelement <2 x i32> %124, i32 %123, i32 1
  %126 = bitcast <2 x i32> %125 to i64
  %127 = icmp uge i32 %121, %32
  %128 = icmp eq i32 %122, %33
  %129 = and i1 %128, %127
  %130 = icmp ugt i32 %122, %33
  %131 = or i1 %129, %130
  %132 = sext i1 %131 to i64
  %133 = sub i64 0, %132
  %134 = add i64 %126, %133
  br label %__igcbuiltin_u64_udiv_dp.exit

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit54, %80
  %135 = phi i64 [ %79, %precompiled_u32divrem_sp.exit54 ], [ %134, %80 ]
  %136 = trunc nuw nsw i64 %56 to i32
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %136, i32 -858993459)
  %q_appx30 = lshr i32 %q_appx, 9
  br i1 %47, label %137, label %152

137:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  br i1 %tobool.i32, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %137
  br label %precompiled_u32divrem_sp.exit

if.end.i:                                         ; preds = %137
  %138 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword)
  %conv.i = fptoui float %138 to i32
  %sub.i = sub i32 %const_reg_dword, %conv.i
  %139 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %140 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %q_appx30)
  %conv3.i = fptoui float %140 to i32
  %sub4.i = sub i32 %q_appx30, %conv3.i
  %141 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %div.i = fdiv float 1.000000e+00, %138, !fpmath !617
  %142 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %143 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %140, float %142)
  %conv8.i = fptoui float %143 to i32
  %144 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %145 = fsub float 0.000000e+00, %138
  %146 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %145, float %144, float %140)
  %147 = fsub float 0.000000e+00, %139
  %148 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %147, float %144, float %141)
  %149 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %146, float %148)
  %150 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %142, float %149)
  %conv16.i = fptoui float %150 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %const_reg_dword
  %sub17.i = sub i32 %q_appx30, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %151 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit

152:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %153 = uitofp nneg i32 %q_appx30 to double
  %154 = fmul double %55, %153
  %155 = fptoui double %154 to i64
  %156 = bitcast i64 %155 to <2 x i32>
  %157 = extractelement <2 x i32> %156, i32 0
  %158 = extractelement <2 x i32> %156, i32 1
  %159 = trunc i64 %155 to i32
  %160 = icmp ult i32 %158, 1
  %161 = select i1 %160, i32 0, i32 %const_reg_dword
  %162 = sub i32 %159, %161
  %163 = insertelement <2 x i32> undef, i32 %q_appx30, i32 0
  %164 = insertelement <2 x i32> %163, i32 %162, i32 1
  %165 = bitcast <2 x i32> %164 to i64
  %166 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %157, i32 0, i32 %const_reg_dword, i32 0)
  %167 = extractvalue { i32, i32 } %166, 0
  %168 = extractvalue { i32, i32 } %166, 1
  %169 = insertelement <2 x i32> undef, i32 %167, i32 0
  %170 = insertelement <2 x i32> %169, i32 %168, i32 1
  %171 = bitcast <2 x i32> %170 to i64
  %172 = sub i64 %165, %171
  %173 = bitcast i64 %172 to <2 x i32>
  %174 = extractelement <2 x i32> %173, i32 0
  %175 = extractelement <2 x i32> %173, i32 1
  %176 = icmp ult i32 %174, %const_reg_dword
  %177 = icmp eq i32 %175, %30
  %178 = and i1 %177, %176
  %179 = icmp ult i32 %175, %30
  %180 = or i1 %178, %179
  %181 = select i1 %180, i32 0, i32 %const_reg_dword
  %182 = select i1 %180, i32 0, i32 %30
  %183 = insertelement <2 x i32> undef, i32 %181, i32 0
  %184 = insertelement <2 x i32> %183, i32 %182, i32 1
  %185 = bitcast <2 x i32> %184 to i64
  %186 = sub i64 %172, %185
  br label %__igcbuiltin_u64_urem_dp.exit

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %152
  %187 = phi i64 [ %151, %precompiled_u32divrem_sp.exit ], [ %186, %152 ]
  %.neg = mul nsw i32 %q_appx30, -640
  %188 = add nsw i32 %.neg, %136
  %189 = zext i32 %188 to i64
  %190 = shl nuw nsw i64 %189, 2
  %191 = add i64 %const_reg_qword4, %190
  %192 = shl nuw nsw i64 %135, 4, !spirv.Decorations !622
  %193 = add nuw nsw i64 %192, %187, !spirv.Decorations !622
  %194 = bitcast i64 %193 to <2 x i32>
  %195 = extractelement <2 x i32> %194, i32 0
  %196 = extractelement <2 x i32> %194, i32 1
  %197 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %195, i32 %196, i32 2560, i32 0)
  %198 = extractvalue { i32, i32 } %197, 0
  %199 = extractvalue { i32, i32 } %197, 1
  %200 = insertelement <2 x i32> undef, i32 %198, i32 0
  %201 = insertelement <2 x i32> %200, i32 %199, i32 1
  %202 = bitcast <2 x i32> %201 to i64
  %203 = add i64 %191, %202
  %204 = inttoptr i64 %203 to ptr addrspace(1)
  %205 = load i32, ptr addrspace(1) %204, align 4
  %206 = add i64 %203, 409600
  %207 = inttoptr i64 %206 to ptr addrspace(1)
  %208 = load i32, ptr addrspace(1) %207, align 4
  %209 = add nsw i32 %205, %208, !spirv.Decorations !615
  %210 = shl i64 %187, 2
  %211 = add i64 %const_reg_qword6, %210
  %212 = inttoptr i64 %211 to ptr addrspace(1)
  %213 = load float, ptr addrspace(1) %212, align 4
  %214 = fmul reassoc nsz arcp contract float %213, 0x3F7B717580000000, !spirv.Decorations !618
  %215 = sitofp i32 %209 to float
  %216 = add i64 %const_reg_qword7, %210
  %217 = inttoptr i64 %216 to ptr addrspace(1)
  %218 = load i32, ptr addrspace(1) %217, align 4
  %219 = sitofp i32 %218 to float
  %220 = fmul reassoc nnan nsz arcp contract float %219, 5.100000e+02, !spirv.Decorations !620
  %221 = fsub reassoc nnan nsz arcp contract float %215, %220, !spirv.Decorations !620
  %222 = fmul reassoc nsz arcp contract float %214, %221, !spirv.Decorations !618
  %223 = shl i64 %56, 2
  %224 = add i64 %const_reg_qword5, %223
  %225 = inttoptr i64 %224 to ptr addrspace(1)
  store float %222, ptr addrspace(1) %225, align 4
  %226 = add nuw nsw i64 %56, %23
  %227 = bitcast i64 %226 to <2 x i32>
  %228 = extractelement <2 x i32> %227, i32 0
  %229 = extractelement <2 x i32> %227, i32 1
  %230 = icmp ult i32 %228, %4
  %231 = icmp eq i32 %229, %5
  %232 = and i1 %231, %230
  %233 = icmp ult i32 %229, %5
  %234 = or i1 %232, %233
  %235 = select i1 %234, i32 %228, i32 %21
  %236 = select i1 %234, i32 %229, i32 %22
  %237 = insertelement <2 x i32> undef, i32 %235, i32 0
  %238 = insertelement <2 x i32> %237, i32 %236, i32 1
  %239 = bitcast <2 x i32> %238 to i64
  br i1 %234, label %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, label %._crit_edge.loopexit

__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge:   ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %.lr.ph

._crit_edge.loopexit:                             ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %._crit_edge

._crit_edge:                                      ; preds = %.._crit_edge_crit_edge, %._crit_edge.loopexit
  ret void
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #1

; Function Desc: 
; Output: 
; Arg 0: 
; Arg 1: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare i32 @llvm.genx.GenISA.umulH.i32(i32, i32) #2

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fma.f64(double, double, double) #3

; Function Desc: 
; Output: 
; Arg 0: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32) #2

; Function Desc: 
; Output: 
; Arg 0: 
; Arg 1: 
; Arg 2: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float, float, float) #2

; Function Desc: 
; Output: 
; Arg 0: 
; Arg 1: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float, float) #2

; Function Desc: 
; Output: 
; Arg 0: 
; Arg 1: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float, float) #2

; Function Desc: 
; Output: 
; Arg 0: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1)) #2

; Function Desc: 
; Output: 
; Arg 0: 
; Arg 1: 
; Arg 2: 
; Arg 3: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare { i32, i32 } @llvm.genx.GenISA.mul.pair(i32, i32, i32, i32) #2

attributes #0 = { convergent nounwind null_pointer_is_valid "less-precise-fpmad"="false" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #2 = { nounwind willreturn memory(none) }
attributes #3 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #4 = { nounwind }

!spirv.MemoryModel = !{!0}
!spirv.Source = !{!1}
!spirv.Generator = !{!2}
!igc.functions = !{!3, !6, !7, !8}
!IGCMetadata = !{!9}
!opencl.ocl.version = !{!606}
!opencl.spir.version = !{!606}
!llvm.ident = !{!607, !608, !609}
!llvm.errno.tbaa = !{!610}
!llvm.module.flags = !{!614}

!0 = !{i32 2, i32 2}
!1 = !{i32 4, i32 100000}
!2 = !{i16 6, i16 14}
!3 = !{ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL5splitRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE, !4}
!4 = !{!5}
!5 = !{!"function_type", i32 0}
!6 = !{ptr @_ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_, !4}
!7 = !{ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL4pairRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE, !4}
!8 = !{ptr @_ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_, !4}
!9 = !{!"ModuleMD", !10, !11, !127, !432, !463, !480, !501, !511, !513, !514, !529, !530, !531, !532, !533, !537, !538, !545, !546, !547, !548, !549, !550, !551, !552, !553, !555, !559, !560, !561, !562, !563, !564, !565, !566, !567, !568, !569, !570, !571, !572, !573, !254, !574, !583, !584, !586, !588, !591, !592, !593, !595, !596, !597, !602, !603, !604, !605}
!10 = !{!"isPrecise", i1 false}
!11 = !{!"compOpt", !12, !13, !14, !15, !16, !17, !18, !19, !20, !21, !22, !23, !24, !25, !26, !27, !28, !29, !30, !31, !32, !33, !34, !35, !36, !37, !38, !39, !40, !41, !42, !43, !44, !45, !46, !47, !48, !49, !50, !51, !52, !53, !54, !55, !56, !57, !58, !59, !60, !61, !62, !63, !64, !65, !66, !67, !68, !69, !70, !71, !72, !73, !74, !75, !76, !77, !78, !79, !80, !81, !82, !83, !84, !85, !86, !87, !88, !89, !90, !91, !92, !93, !94, !95, !96, !97, !98, !99, !100, !101, !102, !103, !104, !105, !106, !107, !108, !109, !110, !111, !112, !113, !114, !115, !116, !117, !118, !119, !120, !121, !122, !123, !124, !125, !126}
!12 = !{!"DenormsAreZero", i1 false}
!13 = !{!"BFTFDenormsAreZero", i1 false}
!14 = !{!"CorrectlyRoundedDivSqrt", i1 false}
!15 = !{!"OptDisable", i1 false}
!16 = !{!"MadEnable", i1 true}
!17 = !{!"NoSignedZeros", i1 false}
!18 = !{!"NoNaNs", i1 false}
!19 = !{!"FloatDenormMode16", !"FLOAT_DENORM_RETAIN"}
!20 = !{!"FloatDenormMode32", !"FLOAT_DENORM_RETAIN"}
!21 = !{!"FloatDenormMode64", !"FLOAT_DENORM_RETAIN"}
!22 = !{!"FloatDenormModeBFTF", !"FLOAT_DENORM_RETAIN"}
!23 = !{!"FloatRoundingMode", i32 0}
!24 = !{!"FloatCvtIntRoundingMode", i32 3}
!25 = !{!"LoadCacheDefault", i32 4}
!26 = !{!"StoreCacheDefault", i32 2}
!27 = !{!"VISAPreSchedRPThreshold", i32 0}
!28 = !{!"VISAPreSchedCtrl", i32 0}
!29 = !{!"SetLoopUnrollThreshold", i32 0}
!30 = !{!"UnsafeMathOptimizations", i1 false}
!31 = !{!"disableCustomUnsafeOpts", i1 false}
!32 = !{!"disableReducePow", i1 false}
!33 = !{!"disableSqrtOpt", i1 false}
!34 = !{!"FiniteMathOnly", i1 false}
!35 = !{!"FastRelaxedMath", i1 false}
!36 = !{!"DashGSpecified", i1 false}
!37 = !{!"FastCompilation", i1 false}
!38 = !{!"UseScratchSpacePrivateMemory", i1 true}
!39 = !{!"RelaxedBuiltins", i1 false}
!40 = !{!"SubgroupIndependentForwardProgressRequired", i1 true}
!41 = !{!"GreaterThan2GBBufferRequired", i1 true}
!42 = !{!"GreaterThan4GBBufferRequired", i1 true}
!43 = !{!"DisableA64WA", i1 false}
!44 = !{!"ForceEnableA64WA", i1 false}
!45 = !{!"PushConstantsEnable", i1 true}
!46 = !{!"HasPositivePointerOffset", i1 false}
!47 = !{!"HasBufferOffsetArg", i1 true}
!48 = !{!"BufferOffsetArgOptional", i1 true}
!49 = !{!"replaceGlobalOffsetsByZero", i1 false}
!50 = !{!"forcePixelShaderSIMDMode", i32 0}
!51 = !{!"forceTotalGRFNum", i32 0}
!52 = !{!"ForceGeomFFShaderSIMDMode", i32 0}
!53 = !{!"pixelShaderDoNotAbortOnSpill", i1 false}
!54 = !{!"UniformWGS", i1 false}
!55 = !{!"disableVertexComponentPacking", i1 false}
!56 = !{!"disablePartialVertexComponentPacking", i1 false}
!57 = !{!"PreferBindlessImages", i1 true}
!58 = !{!"UseBindlessMode", i1 true}
!59 = !{!"UseLegacyBindlessMode", i1 false}
!60 = !{!"disableMathRefactoring", i1 false}
!61 = !{!"atomicBranch", i1 false}
!62 = !{!"spillCompression", i1 false}
!63 = !{!"AllowLICM", i1 true}
!64 = !{!"DisableEarlyOut", i1 false}
!65 = !{!"ForceInt32DivRemEmu", i1 false}
!66 = !{!"ForceInt32DivRemEmuSP", i1 false}
!67 = !{!"DisableIntDivRemIncrementReduction", i1 false}
!68 = !{!"DisableFastestSingleCSSIMD", i1 false}
!69 = !{!"DisableFastestLinearScan", i1 false}
!70 = !{!"UseStatelessforPrivateMemory", i1 false}
!71 = !{!"EnableTakeGlobalAddress", i1 false}
!72 = !{!"IsLibraryCompilation", i1 false}
!73 = !{!"LibraryCompileSIMDSize", i32 0}
!74 = !{!"FastVISACompile", i1 false}
!75 = !{!"MatchSinCosPi", i1 false}
!76 = !{!"ExcludeIRFromZEBinary", i1 false}
!77 = !{!"EmitZeBinVISASections", i1 false}
!78 = !{!"FP64GenEmulationEnabled", i1 false}
!79 = !{!"FP64GenConvEmulationEnabled", i1 false}
!80 = !{!"allowDisableRematforCS", i1 false}
!81 = !{!"DisableIncSpillCostAllAddrTaken", i1 false}
!82 = !{!"DisableCPSOmaskWA", i1 false}
!83 = !{!"DisableFastestGopt", i1 false}
!84 = !{!"WaForceHalfPromotionComputeShader", i1 false}
!85 = !{!"WaForceHalfPromotionPixelVertexShader", i1 false}
!86 = !{!"DisableConstantCoalescing", i1 false}
!87 = !{!"DisableBitcastedLoadNarrowing", i1 false}
!88 = !{!"EnableUndefAlphaOutputAsRed", i1 true}
!89 = !{!"WaEnableALTModeVisaWA", i1 false}
!90 = !{!"WaConvergentGradientsOnGenISA", i1 false}
!91 = !{!"WaDisableDualSIMD8", i1 false}
!92 = !{!"EnableLdStCombineforLoad", i1 false}
!93 = !{!"EnableLdStCombinewithDummyLoad", i1 false}
!94 = !{!"WaZeroInactiveLanesForWaveShuffle", i1 false}
!95 = !{!"ForceUniformBuffer", i1 false}
!96 = !{!"ForceUniformSurfaceSampler", i1 false}
!97 = !{!"EnableIndependentSharedMemoryFenceFunctionality", i1 false}
!98 = !{!"NewSpillCostFunction", i1 false}
!99 = !{!"EnableVRT", i1 true}
!100 = !{!"ForceLargeGRFNum4RQ", i1 false}
!101 = !{!"DisableEUFusion", i1 false}
!102 = !{!"DisableFDivToFMulInvOpt", i1 false}
!103 = !{!"initializePhiSampleSourceWA", i1 false}
!104 = !{!"WaDisableSubspanUseNoMaskForCB", i1 false}
!105 = !{!"DisableLoosenSimd32Occu", i1 false}
!106 = !{!"FastestS1Options", i32 0}
!107 = !{!"DisableFastestForWaveIntrinsicsCS", i1 false}
!108 = !{!"ForceLinearWalkOnLinearUAV", i1 false}
!109 = !{!"LscSamplerRouting", i32 0}
!110 = !{!"UseBarrierControlFlowOptimization", i1 false}
!111 = !{!"EnableDynamicRQManagement", i1 false}
!112 = !{!"WaDisablePayloadCoalescing", i1 false}
!113 = !{!"Quad8InputThreshold", i32 0}
!114 = !{!"UseResourceLoopUnrollNested", i1 false}
!115 = !{!"DisableLoopUnroll", i1 false}
!116 = !{!"ForcePushConstantMode", i32 0}
!117 = !{!"UseInstructionHoistingOptimization", i1 false}
!118 = !{!"DisableResourceLoopDestLifeTimeStart", i1 false}
!119 = !{!"ForceVRTGRFCeiling", i32 0}
!120 = !{!"EnableSamplerBackingByLSC", i32 0}
!121 = !{!"UseLinearScanRA", i1 false}
!122 = !{!"DisableConvertingAtomicIAddToIncDec", i1 false}
!123 = !{!"ZeroInitRegistersBeforeExecution", i1 false}
!124 = !{!"VISASpillAllowed", i32 0}
!125 = !{!"ConstantCoalescingMaxBBDepthDelta", i32 0}
!126 = !{!"ConstantCoalescingDepthCheckMinBytes", i32 0}
!127 = !{!"FuncMD", !128, !129, !294, !295, !345, !346, !383, !384}
!128 = !{!"FuncMDMap[0]", ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL5splitRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE}
!129 = !{!"FuncMDValue[0]", !130, !131, !135, !138, !139, !140, !141, !142, !187, !188, !189, !212, !241, !242, !243, !244, !245, !246, !247, !248, !249, !250, !251, !252, !253, !254, !255, !256, !257, !258, !259, !260, !261, !262, !263, !264, !265, !266, !267, !270, !273, !276, !279, !282, !285, !290}
!130 = !{!"localOffsets"}
!131 = !{!"workGroupWalkOrder", !132, !133, !134}
!132 = !{!"dim0", i32 0}
!133 = !{!"dim1", i32 1}
!134 = !{!"dim2", i32 2}
!135 = !{!"threadGroupSize", !132, !136, !137}
!136 = !{!"dim1", i32 0}
!137 = !{!"dim2", i32 0}
!138 = !{!"threadGroupSizeHint", !132, !136, !137}
!139 = !{!"vecTypeHint", !""}
!140 = !{!"funcArgs"}
!141 = !{!"argInfoList"}
!142 = !{!"implicitArgInfoList", !143, !149, !151, !153, !155, !157, !159, !161, !163, !167, !170, !173, !175, !177, !179, !181, !183, !185}
!143 = !{!"implicitArgInfoListVec[0]", !144, !145, !146, !147, !148}
!144 = !{!"argId", i32 0}
!145 = !{!"explicitArgNum", i32 -1}
!146 = !{!"structArgOffset", i32 -1}
!147 = !{!"imgAccessFloatCoords", i32 -1}
!148 = !{!"imgAccessIntCoords", i32 -1}
!149 = !{!"implicitArgInfoListVec[1]", !150, !145, !146, !147, !148}
!150 = !{!"argId", i32 2}
!151 = !{!"implicitArgInfoListVec[2]", !152, !145, !146, !147, !148}
!152 = !{!"argId", i32 5}
!153 = !{!"implicitArgInfoListVec[3]", !154, !145, !146, !147, !148}
!154 = !{!"argId", i32 7}
!155 = !{!"implicitArgInfoListVec[4]", !156, !145, !146, !147, !148}
!156 = !{!"argId", i32 8}
!157 = !{!"implicitArgInfoListVec[5]", !158, !145, !146, !147, !148}
!158 = !{!"argId", i32 9}
!159 = !{!"implicitArgInfoListVec[6]", !160, !145, !146, !147, !148}
!160 = !{!"argId", i32 10}
!161 = !{!"implicitArgInfoListVec[7]", !162, !145, !146, !147, !148}
!162 = !{!"argId", i32 13}
!163 = !{!"implicitArgInfoListVec[8]", !164, !165, !166, !147, !148}
!164 = !{!"argId", i32 17}
!165 = !{!"explicitArgNum", i32 0}
!166 = !{!"structArgOffset", i32 0}
!167 = !{!"implicitArgInfoListVec[9]", !168, !169, !166, !147, !148}
!168 = !{!"argId", i32 18}
!169 = !{!"explicitArgNum", i32 1}
!170 = !{!"implicitArgInfoListVec[10]", !171, !169, !172, !147, !148}
!171 = !{!"argId", i32 20}
!172 = !{!"structArgOffset", i32 4}
!173 = !{!"implicitArgInfoListVec[11]", !171, !169, !174, !147, !148}
!174 = !{!"structArgOffset", i32 5}
!175 = !{!"implicitArgInfoListVec[12]", !171, !169, !176, !147, !148}
!176 = !{!"structArgOffset", i32 6}
!177 = !{!"implicitArgInfoListVec[13]", !171, !169, !178, !147, !148}
!178 = !{!"structArgOffset", i32 7}
!179 = !{!"implicitArgInfoListVec[14]", !164, !169, !180, !147, !148}
!180 = !{!"structArgOffset", i32 8}
!181 = !{!"implicitArgInfoListVec[15]", !164, !169, !182, !147, !148}
!182 = !{!"structArgOffset", i32 16}
!183 = !{!"implicitArgInfoListVec[16]", !164, !169, !184, !147, !148}
!184 = !{!"structArgOffset", i32 24}
!185 = !{!"implicitArgInfoListVec[17]", !164, !169, !186, !147, !148}
!186 = !{!"structArgOffset", i32 32}
!187 = !{!"functionType", !"KernelFunction"}
!188 = !{!"requiredSubGroupSize", i32 0}
!189 = !{!"rtInfo", !190, !191, !192, !193, !194, !195, !196, !197, !198, !199, !200, !201, !202, !203, !204, !205, !207, !208, !209, !210, !211}
!190 = !{!"callableShaderType", !"NumberOfCallableShaderTypes"}
!191 = !{!"isContinuation", i1 false}
!192 = !{!"hasTraceRayPayload", i1 false}
!193 = !{!"hasHitAttributes", i1 false}
!194 = !{!"hasCallableData", i1 false}
!195 = !{!"ShaderStackSize", i32 0}
!196 = !{!"ShaderHash", i64 0}
!197 = !{!"ShaderName", !""}
!198 = !{!"ParentName", !""}
!199 = !{!"SlotNum", ptr null}
!200 = !{!"NOSSize", i32 0}
!201 = !{!"globalRootSignatureSize", i32 0}
!202 = !{!"Entries"}
!203 = !{!"SpillUnions"}
!204 = !{!"CustomHitAttrSizeInBytes", i32 0}
!205 = !{!"Types", !206}
!206 = !{!"FullFrameTys"}
!207 = !{!"Aliases"}
!208 = !{!"numSyncRTStacks", i32 0}
!209 = !{!"NumCoherenceHintBits", i32 0}
!210 = !{!"useSyncHWStack", i1 false}
!211 = !{!"OriginatingShaderName", !""}
!212 = !{!"resAllocMD", !213, !214, !215, !216, !240}
!213 = !{!"uavsNumType", i32 0}
!214 = !{!"srvsNumType", i32 0}
!215 = !{!"samplersNumType", i32 0}
!216 = !{!"argAllocMDList", !217, !221, !222, !223, !224, !225, !226, !227, !228, !229, !230, !231, !232, !233, !234, !235, !236, !237, !238, !239}
!217 = !{!"argAllocMDListVec[0]", !218, !219, !220}
!218 = !{!"type", i32 0}
!219 = !{!"extensionType", i32 -1}
!220 = !{!"indexType", i32 -1}
!221 = !{!"argAllocMDListVec[1]", !218, !219, !220}
!222 = !{!"argAllocMDListVec[2]", !218, !219, !220}
!223 = !{!"argAllocMDListVec[3]", !218, !219, !220}
!224 = !{!"argAllocMDListVec[4]", !218, !219, !220}
!225 = !{!"argAllocMDListVec[5]", !218, !219, !220}
!226 = !{!"argAllocMDListVec[6]", !218, !219, !220}
!227 = !{!"argAllocMDListVec[7]", !218, !219, !220}
!228 = !{!"argAllocMDListVec[8]", !218, !219, !220}
!229 = !{!"argAllocMDListVec[9]", !218, !219, !220}
!230 = !{!"argAllocMDListVec[10]", !218, !219, !220}
!231 = !{!"argAllocMDListVec[11]", !218, !219, !220}
!232 = !{!"argAllocMDListVec[12]", !218, !219, !220}
!233 = !{!"argAllocMDListVec[13]", !218, !219, !220}
!234 = !{!"argAllocMDListVec[14]", !218, !219, !220}
!235 = !{!"argAllocMDListVec[15]", !218, !219, !220}
!236 = !{!"argAllocMDListVec[16]", !218, !219, !220}
!237 = !{!"argAllocMDListVec[17]", !218, !219, !220}
!238 = !{!"argAllocMDListVec[18]", !218, !219, !220}
!239 = !{!"argAllocMDListVec[19]", !218, !219, !220}
!240 = !{!"inlineSamplersMD"}
!241 = !{!"maxByteOffsets"}
!242 = !{!"IsInitializer", i1 false}
!243 = !{!"IsFinalizer", i1 false}
!244 = !{!"CompiledSubGroupsNumber", i32 0}
!245 = !{!"maxRegPressureSimd16", i32 0}
!246 = !{!"maxRegPressureSimd32", i32 0}
!247 = !{!"maxRegUniformPressure", i32 0}
!248 = !{!"maxRegNonUniformPressure", i32 0}
!249 = !{!"bestGuessSimd", i32 0}
!250 = !{!"hasInlineVmeSamplers", i1 false}
!251 = !{!"localSize", i32 0}
!252 = !{!"localIDPresent", i1 false}
!253 = !{!"groupIDPresent", i1 false}
!254 = !{!"privateMemoryPerWI", i32 0}
!255 = !{!"prevFPOffset", i32 0}
!256 = !{!"globalIDPresent", i1 false}
!257 = !{!"hasSyncRTCalls", i1 false}
!258 = !{!"hasPrintfCalls", i1 false}
!259 = !{!"hasDPAS", i1 false}
!260 = !{!"requireAssertBuffer", i1 false}
!261 = !{!"requireSyncBuffer", i1 false}
!262 = !{!"hasIndirectCalls", i1 false}
!263 = !{!"hasNonKernelArgLoad", i1 false}
!264 = !{!"hasNonKernelArgStore", i1 false}
!265 = !{!"hasNonKernelArgAtomic", i1 false}
!266 = !{!"UserAnnotations"}
!267 = !{!"m_OpenCLArgAddressSpaces", !268, !269}
!268 = !{!"m_OpenCLArgAddressSpacesVec[0]", i32 0}
!269 = !{!"m_OpenCLArgAddressSpacesVec[1]", i32 0}
!270 = !{!"m_OpenCLArgAccessQualifiers", !271, !272}
!271 = !{!"m_OpenCLArgAccessQualifiersVec[0]", !"none"}
!272 = !{!"m_OpenCLArgAccessQualifiersVec[1]", !"none"}
!273 = !{!"m_OpenCLArgTypes", !274, !275}
!274 = !{!"m_OpenCLArgTypesVec[0]", !"class.sycl::_V1::range"}
!275 = !{!"m_OpenCLArgTypesVec[1]", !"class._ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_"}
!276 = !{!"m_OpenCLArgBaseTypes", !277, !278}
!277 = !{!"m_OpenCLArgBaseTypesVec[0]", !"class.sycl::_V1::range"}
!278 = !{!"m_OpenCLArgBaseTypesVec[1]", !"class._ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_"}
!279 = !{!"m_OpenCLArgTypeQualifiers", !280, !281}
!280 = !{!"m_OpenCLArgTypeQualifiersVec[0]", !""}
!281 = !{!"m_OpenCLArgTypeQualifiersVec[1]", !""}
!282 = !{!"m_OpenCLArgNames", !283, !284}
!283 = !{!"m_OpenCLArgNamesVec[0]", !""}
!284 = !{!"m_OpenCLArgNamesVec[1]", !""}
!285 = !{!"m_OpenCLArgScalarAsPointers", !286, !287, !288, !289}
!286 = !{!"m_OpenCLArgScalarAsPointersSet[0]", i32 16}
!287 = !{!"m_OpenCLArgScalarAsPointersSet[1]", i32 17}
!288 = !{!"m_OpenCLArgScalarAsPointersSet[2]", i32 18}
!289 = !{!"m_OpenCLArgScalarAsPointersSet[3]", i32 19}
!290 = !{!"m_OptsToDisablePerFunc", !291, !292, !293}
!291 = !{!"m_OptsToDisablePerFuncSet[0]", !"IGC-AddressArithmeticSinking"}
!292 = !{!"m_OptsToDisablePerFuncSet[1]", !"IGC-AllowSimd32Slicing"}
!293 = !{!"m_OptsToDisablePerFuncSet[2]", !"IGC-SinkLoadOpt"}
!294 = !{!"FuncMDMap[1]", ptr @_ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_}
!295 = !{!"FuncMDValue[1]", !130, !131, !135, !138, !139, !140, !141, !296, !187, !188, !189, !212, !241, !242, !243, !244, !245, !246, !247, !248, !249, !250, !251, !252, !253, !254, !255, !256, !257, !258, !259, !260, !261, !262, !263, !264, !265, !266, !315, !320, !324, !330, !336, !340, !344, !290}
!296 = !{!"implicitArgInfoList", !143, !149, !297, !298, !299, !300, !301, !302, !304, !306, !308, !310, !312, !313, !314}
!297 = !{!"implicitArgInfoListVec[2]", !154, !145, !146, !147, !148}
!298 = !{!"implicitArgInfoListVec[3]", !156, !145, !146, !147, !148}
!299 = !{!"implicitArgInfoListVec[4]", !158, !145, !146, !147, !148}
!300 = !{!"implicitArgInfoListVec[5]", !160, !145, !146, !147, !148}
!301 = !{!"implicitArgInfoListVec[6]", !162, !145, !146, !147, !148}
!302 = !{!"implicitArgInfoListVec[7]", !303, !169, !146, !147, !148}
!303 = !{!"argId", i32 15}
!304 = !{!"implicitArgInfoListVec[8]", !303, !305, !146, !147, !148}
!305 = !{!"explicitArgNum", i32 2}
!306 = !{!"implicitArgInfoListVec[9]", !303, !307, !146, !147, !148}
!307 = !{!"explicitArgNum", i32 3}
!308 = !{!"implicitArgInfoListVec[10]", !303, !309, !146, !147, !148}
!309 = !{!"explicitArgNum", i32 4}
!310 = !{!"implicitArgInfoListVec[11]", !311, !169, !146, !147, !148}
!311 = !{!"argId", i32 54}
!312 = !{!"implicitArgInfoListVec[12]", !311, !305, !146, !147, !148}
!313 = !{!"implicitArgInfoListVec[13]", !311, !307, !146, !147, !148}
!314 = !{!"implicitArgInfoListVec[14]", !311, !309, !146, !147, !148}
!315 = !{!"m_OpenCLArgAddressSpaces", !268, !316, !317, !318, !319}
!316 = !{!"m_OpenCLArgAddressSpacesVec[1]", i32 1}
!317 = !{!"m_OpenCLArgAddressSpacesVec[2]", i32 1}
!318 = !{!"m_OpenCLArgAddressSpacesVec[3]", i32 1}
!319 = !{!"m_OpenCLArgAddressSpacesVec[4]", i32 1}
!320 = !{!"m_OpenCLArgAccessQualifiers", !271, !272, !321, !322, !323}
!321 = !{!"m_OpenCLArgAccessQualifiersVec[2]", !"none"}
!322 = !{!"m_OpenCLArgAccessQualifiersVec[3]", !"none"}
!323 = !{!"m_OpenCLArgAccessQualifiersVec[4]", !"none"}
!324 = !{!"m_OpenCLArgTypes", !325, !326, !327, !328, !329}
!325 = !{!"m_OpenCLArgTypesVec[0]", !"int"}
!326 = !{!"m_OpenCLArgTypesVec[1]", !"int*"}
!327 = !{!"m_OpenCLArgTypesVec[2]", !"float*"}
!328 = !{!"m_OpenCLArgTypesVec[3]", !"float*"}
!329 = !{!"m_OpenCLArgTypesVec[4]", !"int*"}
!330 = !{!"m_OpenCLArgBaseTypes", !331, !332, !333, !334, !335}
!331 = !{!"m_OpenCLArgBaseTypesVec[0]", !"int"}
!332 = !{!"m_OpenCLArgBaseTypesVec[1]", !"int*"}
!333 = !{!"m_OpenCLArgBaseTypesVec[2]", !"float*"}
!334 = !{!"m_OpenCLArgBaseTypesVec[3]", !"float*"}
!335 = !{!"m_OpenCLArgBaseTypesVec[4]", !"int*"}
!336 = !{!"m_OpenCLArgTypeQualifiers", !280, !281, !337, !338, !339}
!337 = !{!"m_OpenCLArgTypeQualifiersVec[2]", !""}
!338 = !{!"m_OpenCLArgTypeQualifiersVec[3]", !""}
!339 = !{!"m_OpenCLArgTypeQualifiersVec[4]", !""}
!340 = !{!"m_OpenCLArgNames", !283, !284, !341, !342, !343}
!341 = !{!"m_OpenCLArgNamesVec[2]", !""}
!342 = !{!"m_OpenCLArgNamesVec[3]", !""}
!343 = !{!"m_OpenCLArgNamesVec[4]", !""}
!344 = !{!"m_OpenCLArgScalarAsPointers"}
!345 = !{!"FuncMDMap[2]", ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL4pairRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE}
!346 = !{!"FuncMDValue[2]", !130, !131, !135, !138, !139, !140, !141, !347, !187, !188, !189, !367, !241, !242, !243, !244, !245, !246, !247, !248, !249, !250, !251, !252, !253, !254, !255, !256, !257, !258, !259, !260, !261, !262, !263, !264, !265, !266, !267, !270, !372, !374, !279, !282, !376, !290}
!347 = !{!"implicitArgInfoList", !143, !149, !151, !153, !155, !157, !159, !161, !163, !348, !349, !350, !351, !352, !353, !355, !357, !359, !361, !363, !365}
!348 = !{!"implicitArgInfoListVec[9]", !164, !169, !166, !147, !148}
!349 = !{!"implicitArgInfoListVec[10]", !164, !169, !180, !147, !148}
!350 = !{!"implicitArgInfoListVec[11]", !164, !169, !182, !147, !148}
!351 = !{!"implicitArgInfoListVec[12]", !164, !169, !184, !147, !148}
!352 = !{!"implicitArgInfoListVec[13]", !164, !169, !186, !147, !148}
!353 = !{!"implicitArgInfoListVec[14]", !168, !169, !354, !147, !148}
!354 = !{!"structArgOffset", i32 40}
!355 = !{!"implicitArgInfoListVec[15]", !171, !169, !356, !147, !148}
!356 = !{!"structArgOffset", i32 44}
!357 = !{!"implicitArgInfoListVec[16]", !171, !169, !358, !147, !148}
!358 = !{!"structArgOffset", i32 45}
!359 = !{!"implicitArgInfoListVec[17]", !171, !169, !360, !147, !148}
!360 = !{!"structArgOffset", i32 46}
!361 = !{!"implicitArgInfoListVec[18]", !171, !169, !362, !147, !148}
!362 = !{!"structArgOffset", i32 47}
!363 = !{!"implicitArgInfoListVec[19]", !164, !169, !364, !147, !148}
!364 = !{!"structArgOffset", i32 48}
!365 = !{!"implicitArgInfoListVec[20]", !164, !169, !366, !147, !148}
!366 = !{!"structArgOffset", i32 56}
!367 = !{!"resAllocMD", !213, !214, !215, !368, !240}
!368 = !{!"argAllocMDList", !217, !221, !222, !223, !224, !225, !226, !227, !228, !229, !230, !231, !232, !233, !234, !235, !236, !237, !238, !239, !369, !370, !371}
!369 = !{!"argAllocMDListVec[20]", !218, !219, !220}
!370 = !{!"argAllocMDListVec[21]", !218, !219, !220}
!371 = !{!"argAllocMDListVec[22]", !218, !219, !220}
!372 = !{!"m_OpenCLArgTypes", !274, !373}
!373 = !{!"m_OpenCLArgTypesVec[1]", !"class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_"}
!374 = !{!"m_OpenCLArgBaseTypes", !277, !375}
!375 = !{!"m_OpenCLArgBaseTypesVec[1]", !"class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_"}
!376 = !{!"m_OpenCLArgScalarAsPointers", !377, !378, !379, !380, !381, !382}
!377 = !{!"m_OpenCLArgScalarAsPointersSet[0]", i32 12}
!378 = !{!"m_OpenCLArgScalarAsPointersSet[1]", i32 13}
!379 = !{!"m_OpenCLArgScalarAsPointersSet[2]", i32 14}
!380 = !{!"m_OpenCLArgScalarAsPointersSet[3]", i32 15}
!381 = !{!"m_OpenCLArgScalarAsPointersSet[4]", i32 21}
!382 = !{!"m_OpenCLArgScalarAsPointersSet[5]", i32 22}
!383 = !{!"FuncMDMap[3]", ptr @_ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_}
!384 = !{!"FuncMDValue[3]", !130, !131, !135, !138, !139, !140, !141, !385, !187, !188, !189, !396, !241, !242, !243, !244, !245, !246, !247, !248, !249, !250, !251, !252, !253, !254, !255, !256, !257, !258, !259, !260, !261, !262, !263, !264, !265, !266, !402, !406, !410, !417, !424, !428, !344, !290}
!385 = !{!"implicitArgInfoList", !143, !149, !297, !298, !299, !300, !301, !302, !304, !306, !308, !386, !388, !390, !391, !392, !393, !394, !395}
!386 = !{!"implicitArgInfoListVec[11]", !303, !387, !146, !147, !148}
!387 = !{!"explicitArgNum", i32 6}
!388 = !{!"implicitArgInfoListVec[12]", !303, !389, !146, !147, !148}
!389 = !{!"explicitArgNum", i32 7}
!390 = !{!"implicitArgInfoListVec[13]", !311, !169, !146, !147, !148}
!391 = !{!"implicitArgInfoListVec[14]", !311, !305, !146, !147, !148}
!392 = !{!"implicitArgInfoListVec[15]", !311, !307, !146, !147, !148}
!393 = !{!"implicitArgInfoListVec[16]", !311, !309, !146, !147, !148}
!394 = !{!"implicitArgInfoListVec[17]", !311, !387, !146, !147, !148}
!395 = !{!"implicitArgInfoListVec[18]", !311, !389, !146, !147, !148}
!396 = !{!"resAllocMD", !213, !214, !215, !397, !240}
!397 = !{!"argAllocMDList", !217, !221, !222, !223, !224, !225, !226, !227, !228, !229, !230, !231, !232, !233, !234, !235, !236, !237, !238, !239, !369, !370, !371, !398, !399, !400, !401}
!398 = !{!"argAllocMDListVec[23]", !218, !219, !220}
!399 = !{!"argAllocMDListVec[24]", !218, !219, !220}
!400 = !{!"argAllocMDListVec[25]", !218, !219, !220}
!401 = !{!"argAllocMDListVec[26]", !218, !219, !220}
!402 = !{!"m_OpenCLArgAddressSpaces", !268, !316, !317, !318, !319, !403, !404, !405}
!403 = !{!"m_OpenCLArgAddressSpacesVec[5]", i32 0}
!404 = !{!"m_OpenCLArgAddressSpacesVec[6]", i32 1}
!405 = !{!"m_OpenCLArgAddressSpacesVec[7]", i32 1}
!406 = !{!"m_OpenCLArgAccessQualifiers", !271, !272, !321, !322, !323, !407, !408, !409}
!407 = !{!"m_OpenCLArgAccessQualifiersVec[5]", !"none"}
!408 = !{!"m_OpenCLArgAccessQualifiersVec[6]", !"none"}
!409 = !{!"m_OpenCLArgAccessQualifiersVec[7]", !"none"}
!410 = !{!"m_OpenCLArgTypes", !411, !326, !412, !328, !413, !414, !415, !416}
!411 = !{!"m_OpenCLArgTypesVec[0]", !"long"}
!412 = !{!"m_OpenCLArgTypesVec[2]", !"int*"}
!413 = !{!"m_OpenCLArgTypesVec[4]", !"float*"}
!414 = !{!"m_OpenCLArgTypesVec[5]", !"int"}
!415 = !{!"m_OpenCLArgTypesVec[6]", !"float*"}
!416 = !{!"m_OpenCLArgTypesVec[7]", !"int*"}
!417 = !{!"m_OpenCLArgBaseTypes", !418, !332, !419, !334, !420, !421, !422, !423}
!418 = !{!"m_OpenCLArgBaseTypesVec[0]", !"long"}
!419 = !{!"m_OpenCLArgBaseTypesVec[2]", !"int*"}
!420 = !{!"m_OpenCLArgBaseTypesVec[4]", !"float*"}
!421 = !{!"m_OpenCLArgBaseTypesVec[5]", !"int"}
!422 = !{!"m_OpenCLArgBaseTypesVec[6]", !"float*"}
!423 = !{!"m_OpenCLArgBaseTypesVec[7]", !"int*"}
!424 = !{!"m_OpenCLArgTypeQualifiers", !280, !281, !337, !338, !339, !425, !426, !427}
!425 = !{!"m_OpenCLArgTypeQualifiersVec[5]", !""}
!426 = !{!"m_OpenCLArgTypeQualifiersVec[6]", !""}
!427 = !{!"m_OpenCLArgTypeQualifiersVec[7]", !""}
!428 = !{!"m_OpenCLArgNames", !283, !284, !341, !342, !343, !429, !430, !431}
!429 = !{!"m_OpenCLArgNamesVec[5]", !""}
!430 = !{!"m_OpenCLArgNamesVec[6]", !""}
!431 = !{!"m_OpenCLArgNamesVec[7]", !""}
!432 = !{!"pushInfo", !433, !434, !435, !439, !440, !441, !442, !443, !444, !445, !446, !459, !460, !461, !462}
!433 = !{!"pushableAddresses"}
!434 = !{!"bindlessPushInfo"}
!435 = !{!"dynamicBufferInfo", !436, !437, !438}
!436 = !{!"firstIndex", i32 0}
!437 = !{!"numOffsets", i32 0}
!438 = !{!"forceDisabled", i1 false}
!439 = !{!"MaxNumberOfPushedBuffers", i32 0}
!440 = !{!"inlineConstantBufferSlot", i32 -1}
!441 = !{!"inlineConstantBufferOffset", i32 -1}
!442 = !{!"inlineConstantBufferGRFOffset", i32 -1}
!443 = !{!"constants"}
!444 = !{!"inputs"}
!445 = !{!"constantReg"}
!446 = !{!"simplePushInfoArr", !447, !456, !457, !458}
!447 = !{!"simplePushInfoArrVec[0]", !448, !449, !450, !451, !452, !453, !454, !455}
!448 = !{!"cbIdx", i32 0}
!449 = !{!"pushableAddressGrfOffset", i32 -1}
!450 = !{!"pushableOffsetGrfOffset", i32 -1}
!451 = !{!"offset", i32 0}
!452 = !{!"size", i32 0}
!453 = !{!"isStateless", i1 false}
!454 = !{!"isBindless", i1 false}
!455 = !{!"simplePushLoads"}
!456 = !{!"simplePushInfoArrVec[1]", !448, !449, !450, !451, !452, !453, !454, !455}
!457 = !{!"simplePushInfoArrVec[2]", !448, !449, !450, !451, !452, !453, !454, !455}
!458 = !{!"simplePushInfoArrVec[3]", !448, !449, !450, !451, !452, !453, !454, !455}
!459 = !{!"simplePushBufferUsed", i32 0}
!460 = !{!"pushAnalysisWIInfos"}
!461 = !{!"inlineRTGlobalPtrOffset", i32 0}
!462 = !{!"rtSyncSurfPtrOffset", i32 0}
!463 = !{!"psInfo", !464, !465, !466, !467, !468, !469, !470, !471, !472, !473, !474, !475, !476, !477, !478, !479}
!464 = !{!"BlendStateDisabledMask", i8 0}
!465 = !{!"SkipSrc0Alpha", i1 false}
!466 = !{!"DualSourceBlendingDisabled", i1 false}
!467 = !{!"ForceEnableSimd32", i1 false}
!468 = !{!"DisableSimd32WithDiscard", i1 false}
!469 = !{!"outputDepth", i1 false}
!470 = !{!"outputStencil", i1 false}
!471 = !{!"outputMask", i1 false}
!472 = !{!"blendToFillEnabled", i1 false}
!473 = !{!"forceEarlyZ", i1 false}
!474 = !{!"hasVersionedLoop", i1 false}
!475 = !{!"forceSingleSourceRTWAfterDualSourceRTW", i1 false}
!476 = !{!"blendOptimizationMode"}
!477 = !{!"colorOutputMask"}
!478 = !{!"isBlendEnabled"}
!479 = !{!"WaDisableVRS", i1 false}
!480 = !{!"csInfo", !481, !482, !483, !484, !51, !27, !28, !485, !29, !486, !487, !488, !489, !490, !491, !492, !493, !494, !495, !496, !62, !497, !498, !499, !500}
!481 = !{!"maxWorkGroupSize", i32 0}
!482 = !{!"waveSize", i32 0}
!483 = !{!"ComputeShaderSecondCompile"}
!484 = !{!"forcedSIMDSize", i8 0}
!485 = !{!"VISAPreSchedScheduleExtraGRF", i32 0}
!486 = !{!"forceSpillCompression", i1 false}
!487 = !{!"allowLowerSimd", i1 false}
!488 = !{!"disableSimd32Slicing", i1 false}
!489 = !{!"disableSplitOnSpill", i1 false}
!490 = !{!"enableNewSpillCostFunction", i1 false}
!491 = !{!"forceVISAPreSched", i1 false}
!492 = !{!"disableLocalIdOrderOptimizations", i1 false}
!493 = !{!"disableDispatchAlongY", i1 false}
!494 = !{!"neededThreadIdLayout", ptr null}
!495 = !{!"forceTileYWalk", i1 false}
!496 = !{!"atomicBranch", i32 0}
!497 = !{!"disableEarlyOut", i1 false}
!498 = !{!"walkOrderEnabled", i1 false}
!499 = !{!"walkOrderOverride", i32 0}
!500 = !{!"ResForHfPacking"}
!501 = !{!"msInfo", !502, !503, !504, !505, !506, !507, !508, !509, !510}
!502 = !{!"PrimitiveTopology", i32 3}
!503 = !{!"MaxNumOfPrimitives", i32 0}
!504 = !{!"MaxNumOfVertices", i32 0}
!505 = !{!"MaxNumOfPerPrimitiveOutputs", i32 0}
!506 = !{!"MaxNumOfPerVertexOutputs", i32 0}
!507 = !{!"WorkGroupSize", i32 0}
!508 = !{!"WorkGroupMemorySizeInBytes", i32 0}
!509 = !{!"IndexFormat", i32 6}
!510 = !{!"SubgroupSize", i32 0}
!511 = !{!"taskInfo", !512, !507, !508, !510}
!512 = !{!"MaxNumOfOutputs", i32 0}
!513 = !{!"NBarrierCnt", i32 0}
!514 = !{!"rtInfo", !515, !516, !517, !518, !519, !520, !521, !522, !523, !524, !525, !526, !527, !528, !208}
!515 = !{!"RayQueryAllocSizeInBytes", i32 0}
!516 = !{!"NumContinuations", i32 0}
!517 = !{!"RTAsyncStackAddrspace", i32 -1}
!518 = !{!"RTAsyncStackSurfaceStateOffset", ptr null}
!519 = !{!"SWHotZoneAddrspace", i32 -1}
!520 = !{!"SWHotZoneSurfaceStateOffset", ptr null}
!521 = !{!"SWStackAddrspace", i32 -1}
!522 = !{!"SWStackSurfaceStateOffset", ptr null}
!523 = !{!"RTSyncStackAddrspace", i32 -1}
!524 = !{!"RTSyncStackSurfaceStateOffset", ptr null}
!525 = !{!"doSyncDispatchRays", i1 false}
!526 = !{!"MemStyle", !"Xe"}
!527 = !{!"GlobalDataStyle", !"Xe"}
!528 = !{!"uberTileDimensions", ptr null}
!529 = !{!"hasSliceLayoutDependency", i1 false}
!530 = !{!"CurUniqueIndirectIdx", i32 0}
!531 = !{!"inlineDynTextures"}
!532 = !{!"inlineResInfoData"}
!533 = !{!"immConstant", !534, !535, !536}
!534 = !{!"data"}
!535 = !{!"sizes"}
!536 = !{!"zeroIdxs"}
!537 = !{!"stringConstants"}
!538 = !{!"inlineBuffers", !539, !543, !544}
!539 = !{!"inlineBuffersVec[0]", !540, !541, !542}
!540 = !{!"alignment", i32 0}
!541 = !{!"allocSize", i64 0}
!542 = !{!"Buffer"}
!543 = !{!"inlineBuffersVec[1]", !540, !541, !542}
!544 = !{!"inlineBuffersVec[2]", !540, !541, !542}
!545 = !{!"GlobalBufferAddressRelocInfo"}
!546 = !{!"ConstantBufferAddressRelocInfo"}
!547 = !{!"forceLscCacheList"}
!548 = !{!"SrvMap"}
!549 = !{!"RasterizerOrderedByteAddressBuffer"}
!550 = !{!"RasterizerOrderedViews"}
!551 = !{!"MinNOSPushConstantSize", i32 0}
!552 = !{!"inlineProgramScopeOffsets"}
!553 = !{!"shaderData", !554}
!554 = !{!"numReplicas", i32 0}
!555 = !{!"URBInfo", !556, !557, !558}
!556 = !{!"has64BVertexHeaderInput", i1 false}
!557 = !{!"has64BVertexHeaderOutput", i1 false}
!558 = !{!"hasVertexHeader", i1 true}
!559 = !{!"UseBindlessImage", i1 true}
!560 = !{!"HasBindlessImageRead", i1 false}
!561 = !{!"UseBindlessImageWithSamplerTracking", i1 false}
!562 = !{!"enableRangeReduce", i1 false}
!563 = !{!"allowMatchMadOptimizationforPosition", i1 false}
!564 = !{!"disableMatchMadOptimizationForCS", i1 false}
!565 = !{!"disableMemOptforNegativeOffsetLoads", i1 false}
!566 = !{!"enableThreeWayLoadSpiltOpt", i1 false}
!567 = !{!"statefulResourcesNotAliased", i1 false}
!568 = !{!"disableMixMode", i1 false}
!569 = !{!"genericAccessesResolved", i1 false}
!570 = !{!"disableSeparateSpillPvtScratchSpace", i1 false}
!571 = !{!"enableSeparateSpillPvtScratchSpace", i1 false}
!572 = !{!"disableSeparateScratchWA", i1 false}
!573 = !{!"enableRemoveUnusedTGMFence", i1 false}
!574 = !{!"PrivateMemoryPerFG", !575, !576, !577, !578, !579, !580, !581, !582}
!575 = !{!"PrivateMemoryPerFGMap[0]", ptr @_ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_}
!576 = !{!"PrivateMemoryPerFGValue[0]", i32 0}
!577 = !{!"PrivateMemoryPerFGMap[1]", ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL4pairRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE}
!578 = !{!"PrivateMemoryPerFGValue[1]", i32 0}
!579 = !{!"PrivateMemoryPerFGMap[2]", ptr @_ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_}
!580 = !{!"PrivateMemoryPerFGValue[2]", i32 0}
!581 = !{!"PrivateMemoryPerFGMap[3]", ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL5splitRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE}
!582 = !{!"PrivateMemoryPerFGValue[3]", i32 0}
!583 = !{!"m_OptsToDisable"}
!584 = !{!"capabilities", !585}
!585 = !{!"globalVariableDecorationsINTEL", i1 false}
!586 = !{!"extensions", !587}
!587 = !{!"spvINTELBindlessImages", i1 false}
!588 = !{!"m_ShaderResourceViewMcsMask", !589, !590}
!589 = !{!"m_ShaderResourceViewMcsMaskVec[0]", i64 0}
!590 = !{!"m_ShaderResourceViewMcsMaskVec[1]", i64 0}
!591 = !{!"computedDepthMode", i32 0}
!592 = !{!"isHDCFastClearShader", i1 false}
!593 = !{!"argRegisterReservations", !594}
!594 = !{!"argRegisterReservationsVec[0]", i32 0}
!595 = !{!"SIMD16_SpillThreshold", i8 0}
!596 = !{!"SIMD32_SpillThreshold", i8 0}
!597 = !{!"m_CacheControlOption", !598, !599, !600, !601}
!598 = !{!"LscLoadCacheControlOverride", i8 0}
!599 = !{!"LscStoreCacheControlOverride", i8 0}
!600 = !{!"TgmLoadCacheControlOverride", i8 0}
!601 = !{!"TgmStoreCacheControlOverride", i8 0}
!602 = !{!"ModuleUsesBindless", i1 false}
!603 = !{!"predicationMap"}
!604 = !{!"lifeTimeStartMap"}
!605 = !{!"HitGroups"}
!606 = !{i32 2, i32 0}
!607 = !{!"clang version 22.1.8 (Fedora 22.1.8-4.fc44)"}
!608 = !{!"clang version 9.0.0 (2dbee6917918354f14026a637370445d50bdaf6a)"}
!609 = !{!"clang version 9.0.0 (c68f557a081b1b2339a42d7cd6af3c2ab18c6061)"}
!610 = !{!611, !611, i64 0}
!611 = !{!"int", !612, i64 0}
!612 = !{!"omnipotent char", !613, i64 0}
!613 = !{!"Simple C/C++ TBAA"}
!614 = !{i32 1, !"wchar_size", i32 4}
!615 = !{!616}
!616 = !{i32 4469}
!617 = !{float 2.500000e+00}
!618 = !{!619}
!619 = !{i32 40, i32 196620}
!620 = !{!621}
!621 = !{i32 40, i32 196621}
!622 = !{!616, !623}
!623 = !{i32 4470}

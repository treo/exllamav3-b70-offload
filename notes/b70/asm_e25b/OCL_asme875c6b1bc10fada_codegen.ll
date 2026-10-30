; ------------------------------------------------
; OCL_asme875c6b1bc10fada_codegen.ll
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
  %19 = icmp eq i32 %11, 0
  %20 = icmp ugt i32 %10, %18
  %21 = and i1 %19, %20
  %22 = icmp ugt i32 %11, 0
  %23 = or i1 %21, %22
  %24 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %1)
  %25 = extractvalue { i32, i32 } %24, 0
  %26 = extractvalue { i32, i32 } %24, 1
  %27 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %2)
  %28 = extractvalue { i32, i32 } %27, 0
  %29 = extractvalue { i32, i32 } %27, 1
  %30 = select i1 %23, i32 %25, i32 %28
  %31 = select i1 %23, i32 %26, i32 %29
  %32 = insertelement <2 x i32> undef, i32 %30, i32 0
  %33 = insertelement <2 x i32> %32, i32 %31, i32 1
  %34 = bitcast <2 x i32> %33 to i64
  %35 = select i1 %23, i32 0, i32 %10
  %36 = select i1 %23, i32 0, i32 %11
  %37 = insertelement <2 x i32> undef, i32 %35, i32 0
  %38 = insertelement <2 x i32> %37, i32 %36, i32 1
  %39 = bitcast <2 x i32> %38 to i64
  %40 = zext nneg i32 %18 to i64
  %41 = sub nsw i64 %40, %39, !spirv.Decorations !626
  %42 = bitcast i64 %41 to <2 x i32>
  %43 = extractelement <2 x i32> %42, i32 0
  %44 = extractelement <2 x i32> %42, i32 1
  %45 = ashr i32 %5, 31
  %46 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %5, i32 %45, i32 640, i32 0)
  %47 = extractvalue { i32, i32 } %46, 0
  %48 = extractvalue { i32, i32 } %46, 1
  %49 = insertelement <2 x i32> undef, i32 %47, i32 0
  %50 = insertelement <2 x i32> %49, i32 %48, i32 1
  %51 = bitcast <2 x i32> %50 to i64
  %52 = or i32 %48, %44
  %53 = icmp ult i32 %52, 1
  br i1 %53, label %119, label %54, !stats.blockFrequency.digits !628, !stats.blockFrequency.scale !629

54:                                               ; preds = %8
  %55 = trunc i64 %51 to i32
  %56 = uitofp i64 %51 to double
  %57 = fptrunc double %56 to float
  %58 = fdiv float 1.000000e+00, %57
  %59 = fsub double 0.000000e+00, %56
  %60 = fpext float %58 to double
  %61 = call double @llvm.fma.f64(double %59, double %60, double 1.000000e+00) #4
  %62 = fadd double %61, 0xBCF0000000000000
  %63 = call double @llvm.fma.f64(double %60, double %62, double %60) #4
  %64 = bitcast i64 %41 to <2 x i32>
  %65 = extractelement <2 x i32> %64, i32 1
  %66 = uitofp i32 %65 to double
  %67 = fmul double %63, %66
  %68 = fptoui double %67 to i32
  %69 = mul i32 %68, %55
  %70 = sub i32 %65, %69
  %71 = trunc i64 %41 to i32
  %72 = uitofp i32 %70 to double
  %73 = uitofp i32 %71 to double
  %74 = call double @llvm.fma.f64(double %72, double 0x41F0000000000000, double %73) #4
  %75 = fmul double %63, %74
  %76 = fptoui double %75 to i64
  %77 = bitcast i64 %76 to <2 x i32>
  %78 = extractelement <2 x i32> %77, i32 0
  %79 = trunc i64 %76 to i32
  %80 = lshr i64 %76, 32
  %81 = bitcast i64 %80 to <2 x i32>
  %82 = extractelement <2 x i32> %81, i32 0
  %83 = extractelement <2 x i32> %81, i32 1
  %84 = bitcast i64 %76 to <2 x i32>
  %85 = extractelement <2 x i32> %84, i32 1
  %86 = icmp eq i32 %83, 0
  %87 = icmp eq i32 %82, 0
  %88 = and i1 %86, %87
  %89 = mul i32 %79, %48
  %90 = select i1 %88, i32 0, i32 %55
  %91 = add i32 %89, %90
  %92 = sub i32 %70, %91
  %93 = insertelement <2 x i32> undef, i32 %43, i32 0
  %94 = insertelement <2 x i32> %93, i32 %92, i32 1
  %95 = bitcast <2 x i32> %94 to i64
  %96 = and i32 %47, -128
  %97 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %78, i32 0, i32 %96, i32 0)
  %98 = extractvalue { i32, i32 } %97, 0
  %99 = extractvalue { i32, i32 } %97, 1
  %100 = insertelement <2 x i32> undef, i32 %98, i32 0
  %101 = insertelement <2 x i32> %100, i32 %99, i32 1
  %102 = bitcast <2 x i32> %101 to i64
  %103 = sub i64 %95, %102
  %104 = bitcast i64 %103 to <2 x i32>
  %105 = extractelement <2 x i32> %104, i32 0
  %106 = extractelement <2 x i32> %104, i32 1
  %107 = add i32 %85, %68
  %108 = insertelement <2 x i32> undef, i32 %78, i32 0
  %109 = insertelement <2 x i32> %108, i32 %107, i32 1
  %110 = bitcast <2 x i32> %109 to i64
  %111 = icmp eq i32 %106, %48
  %112 = icmp uge i32 %105, %47
  %113 = and i1 %111, %112
  %114 = icmp ugt i32 %106, %48
  %115 = or i1 %113, %114
  %116 = sext i1 %115 to i64
  %117 = sub i64 0, %116
  %118 = add i64 %110, %117
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

119:                                              ; preds = %8
  %tobool.i33 = icmp eq i32 %5, 0
  br i1 %tobool.i33, label %.precompiled_u32divrem_sp.exit55_crit_edge, label %if.end.i34, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

if.end.i34:                                       ; preds = %119
  %120 = trunc nuw i64 %41 to i32
  %121 = trunc nuw i64 %51 to i32
  %122 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %121)
  %conv.i35 = fptoui float %122 to i32
  %sub.i36 = sub i32 %121, %conv.i35
  %123 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %120)
  %div.i39 = fdiv float 1.000000e+00, %122, !fpmath !631
  %124 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i39, float 0xBE98000000000000, float %div.i39)
  %125 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %123, float %124)
  %conv3.i37 = fptoui float %123 to i32
  %sub4.i38 = sub i32 %120, %conv3.i37
  %conv8.i40 = fptoui float %125 to i32
  %126 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i36)
  %127 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i38)
  %128 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i40)
  %129 = fsub float 0.000000e+00, %122
  %130 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %129, float %128, float %123)
  %131 = fsub float 0.000000e+00, %126
  %132 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %131, float %128, float %127)
  %133 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %130, float %132)
  %134 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %124, float %133)
  %conv16.i43 = fptoui float %134 to i32
  %add.i44 = add i32 %conv16.i43, %conv8.i40
  %mul.i45 = mul i32 %add.i44, %121
  %sub17.i46 = sub i32 %120, %mul.i45
  %cmp.i47 = icmp uge i32 %sub17.i46, %121
  %135 = sext i1 %cmp.i47 to i32
  %136 = sub i32 0, %135
  %add19.i50 = add i32 %add.i44, %136
  br label %precompiled_u32divrem_sp.exit55, !stats.blockFrequency.digits !632, !stats.blockFrequency.scale !629

.precompiled_u32divrem_sp.exit55_crit_edge:       ; preds = %119
  br label %precompiled_u32divrem_sp.exit55, !stats.blockFrequency.digits !633, !stats.blockFrequency.scale !629

precompiled_u32divrem_sp.exit55:                  ; preds = %.precompiled_u32divrem_sp.exit55_crit_edge, %if.end.i34
  %retval.0.i54 = phi i32 [ %add19.i50, %if.end.i34 ], [ -1, %.precompiled_u32divrem_sp.exit55_crit_edge ]
  %137 = zext i32 %retval.0.i54 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit55, %54
  %138 = phi i64 [ %137, %precompiled_u32divrem_sp.exit55 ], [ %118, %54 ]
  %139 = icmp ult i32 %44, 1
  br i1 %139, label %udiv_pow2_64b_as_32b, label %udiv_pow2_64b, !stats.blockFrequency.digits !628, !stats.blockFrequency.scale !629

udiv_pow2_64b:                                    ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %u.hi32 = lshr i64 %41, 32
  %140 = bitcast i64 %u.hi32 to <2 x i32>
  %141 = extractelement <2 x i32> %140, i32 0
  %142 = extractelement <2 x i32> %140, i32 1
  %143 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %43, i32 0, i32 -858993459, i32 0)
  %144 = extractvalue { i32, i32 } %143, 0
  %145 = extractvalue { i32, i32 } %143, 1
  %146 = insertelement <2 x i32> undef, i32 %144, i32 0
  %147 = insertelement <2 x i32> %146, i32 %145, i32 1
  %148 = bitcast <2 x i32> %147 to i64
  %149 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %141, i32 %142, i32 -858993459, i32 0)
  %150 = extractvalue { i32, i32 } %149, 0
  %151 = extractvalue { i32, i32 } %149, 1
  %152 = insertelement <2 x i32> undef, i32 %150, i32 0
  %153 = insertelement <2 x i32> %152, i32 %151, i32 1
  %154 = bitcast <2 x i32> %153 to i64
  %w0.lo32 = lshr i64 %148, 32
  %t = add nuw i64 %154, %w0.lo32
  %155 = bitcast i64 %t to <2 x i32>
  %156 = extractelement <2 x i32> %155, i32 0
  %157 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %43, i32 0, i32 -858993460, i32 0)
  %158 = extractvalue { i32, i32 } %157, 0
  %159 = extractvalue { i32, i32 } %157, 1
  %160 = insertelement <2 x i32> undef, i32 %158, i32 0
  %161 = insertelement <2 x i32> %160, i32 %159, i32 1
  %162 = bitcast <2 x i32> %161 to i64
  %163 = insertelement <2 x i32> undef, i32 %156, i32 0
  %164 = insertelement <2 x i32> %163, i32 0, i32 1
  %165 = bitcast <2 x i32> %164 to i64
  %w1 = add nuw i64 %162, %165
  %166 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %141, i32 %142, i32 -858993460, i32 0)
  %167 = extractvalue { i32, i32 } %166, 0
  %168 = extractvalue { i32, i32 } %166, 1
  %169 = insertelement <2 x i32> undef, i32 %167, i32 0
  %170 = insertelement <2 x i32> %169, i32 %168, i32 1
  %171 = bitcast <2 x i32> %170 to i64
  %t.hi32 = lshr i64 %t, 32
  %172 = add nuw i64 %171, %t.hi32
  %w1.lo32 = lshr i64 %w1, 32
  %uv = add nuw i64 %172, %w1.lo32
  %q_appx31 = lshr i64 %uv, 9
  br label %175, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

udiv_pow2_64b_as_32b:                             ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %173 = trunc nuw i64 %41 to i32
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %173, i32 -858993459)
  %q_appx30 = lshr i32 %q_appx, 9
  %174 = zext nneg i32 %q_appx30 to i64
  br label %175, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

175:                                              ; preds = %udiv_pow2_64b, %udiv_pow2_64b_as_32b
  %176 = phi i64 [ %174, %udiv_pow2_64b_as_32b ], [ %q_appx31, %udiv_pow2_64b ]
  %177 = bitcast i64 %176 to <2 x i32>
  %178 = extractelement <2 x i32> %177, i32 0
  %179 = extractelement <2 x i32> %177, i32 1
  %180 = or i32 %179, %45
  %181 = icmp ult i32 %180, 1
  br i1 %181, label %237, label %182, !stats.blockFrequency.digits !628, !stats.blockFrequency.scale !629

182:                                              ; preds = %175
  %183 = sext i32 %5 to i64
  %184 = uitofp i64 %183 to double
  %185 = fptrunc double %184 to float
  %186 = fdiv float 1.000000e+00, %185
  %187 = fsub double 0.000000e+00, %184
  %188 = fpext float %186 to double
  %189 = call double @llvm.fma.f64(double %187, double %188, double 1.000000e+00) #4
  %190 = fadd double %189, 0xBCF0000000000000
  %191 = call double @llvm.fma.f64(double %188, double %190, double %188) #4
  %192 = bitcast i64 %176 to <2 x i32>
  %193 = extractelement <2 x i32> %192, i32 1
  %194 = uitofp nneg i32 %193 to double
  %195 = fmul double %191, %194
  %196 = fptoui double %195 to i32
  %197 = mul i32 %5, %196
  %198 = sub i32 %193, %197
  %199 = trunc i64 %176 to i32
  %200 = uitofp i32 %198 to double
  %201 = uitofp i32 %199 to double
  %202 = call double @llvm.fma.f64(double %200, double 0x41F0000000000000, double %201) #4
  %203 = fmul double %191, %202
  %204 = fptoui double %203 to i64
  %205 = bitcast i64 %204 to <2 x i32>
  %206 = extractelement <2 x i32> %205, i32 0
  %207 = extractelement <2 x i32> %205, i32 1
  %208 = trunc i64 %204 to i32
  %isneg = icmp slt i32 %5, 0
  %.neg56 = select i1 %isneg, i32 %208, i32 0
  %209 = icmp ult i32 %207, 1
  %210 = select i1 %209, i32 0, i32 %5
  %211 = sub i32 %198, %210
  %212 = add i32 %.neg56, %211
  %213 = insertelement <2 x i32> undef, i32 %178, i32 0
  %214 = insertelement <2 x i32> %213, i32 %212, i32 1
  %215 = bitcast <2 x i32> %214 to i64
  %216 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %206, i32 0, i32 %5, i32 0)
  %217 = extractvalue { i32, i32 } %216, 0
  %218 = extractvalue { i32, i32 } %216, 1
  %219 = insertelement <2 x i32> undef, i32 %217, i32 0
  %220 = insertelement <2 x i32> %219, i32 %218, i32 1
  %221 = bitcast <2 x i32> %220 to i64
  %222 = sub i64 %215, %221
  %223 = bitcast i64 %222 to <2 x i32>
  %224 = extractelement <2 x i32> %223, i32 0
  %225 = extractelement <2 x i32> %223, i32 1
  %226 = icmp eq i32 %225, %45
  %227 = icmp ult i32 %224, %5
  %228 = and i1 %226, %227
  %229 = icmp ult i32 %225, %45
  %230 = or i1 %228, %229
  %231 = select i1 %230, i32 0, i32 %5
  %232 = select i1 %230, i32 0, i32 %45
  %233 = insertelement <2 x i32> undef, i32 %231, i32 0
  %234 = insertelement <2 x i32> %233, i32 %232, i32 1
  %235 = bitcast <2 x i32> %234 to i64
  %236 = sub i64 %222, %235
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

237:                                              ; preds = %175
  %tobool.i = icmp eq i32 %5, 0
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

if.end.i:                                         ; preds = %237
  %238 = trunc nuw i64 %176 to i32
  %239 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %5)
  %conv.i = fptoui float %239 to i32
  %sub.i = sub i32 %5, %conv.i
  %240 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %238)
  %div.i = fdiv float 1.000000e+00, %239, !fpmath !631
  %241 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %242 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %240, float %241)
  %conv3.i = fptoui float %240 to i32
  %sub4.i = sub i32 %238, %conv3.i
  %conv8.i = fptoui float %242 to i32
  %243 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %244 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %245 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %246 = fsub float 0.000000e+00, %239
  %247 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %246, float %245, float %240)
  %248 = fsub float 0.000000e+00, %243
  %249 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %248, float %245, float %244)
  %250 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %247, float %249)
  %251 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %241, float %250)
  %conv16.i = fptoui float %251 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %5
  %sub17.i = sub i32 %238, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %5
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %5
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !632, !stats.blockFrequency.scale !629

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %237
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !633, !stats.blockFrequency.scale !629

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %252 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %182
  %253 = phi i64 [ %252, %precompiled_u32divrem_sp.exit ], [ %236, %182 ]
  %254 = bitcast i64 %138 to <2 x i32>
  %255 = extractelement <2 x i32> %254, i32 0
  %256 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %255, i32 1
  %257 = bitcast <2 x i32> %256 to i64
  %258 = bitcast i64 %253 to <2 x i32>
  %259 = extractelement <2 x i32> %258, i32 0
  %260 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %259, i32 1
  %261 = bitcast <2 x i32> %260 to i64
  %262 = ashr exact i64 %261, 32
  %263 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %178, i32 %179, i32 -2560, i32 -1)
  %264 = extractvalue { i32, i32 } %263, 0
  %265 = extractvalue { i32, i32 } %263, 1
  %266 = insertelement <2 x i32> undef, i32 %264, i32 0
  %267 = insertelement <2 x i32> %266, i32 %265, i32 1
  %268 = bitcast <2 x i32> %267 to i64
  %269 = add i64 %268, %34
  %270 = shl i64 %41, 2
  %271 = add i64 %269, %270
  %272 = ashr exact i64 %257, 28
  %273 = add nsw i64 %272, %262, !spirv.Decorations !626
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
  %289 = ashr exact i64 %261, 30
  %290 = ptrtoint ptr addrspace(1) %6 to i64
  %291 = add i64 %289, %290
  %292 = inttoptr i64 %291 to ptr addrspace(1)
  %293 = load float, ptr addrspace(1) %292, align 4
  %294 = ptrtoint ptr addrspace(1) %7 to i64
  %295 = add i64 %289, %294
  %296 = inttoptr i64 %295 to ptr addrspace(1)
  %297 = load i32, ptr addrspace(1) %296, align 4
  %298 = add nsw i32 %285, %288, !spirv.Decorations !626
  %299 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %3)
  %300 = extractvalue { i32, i32 } %299, 0
  %301 = extractvalue { i32, i32 } %299, 1
  %302 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %4)
  %303 = extractvalue { i32, i32 } %302, 0
  %304 = extractvalue { i32, i32 } %302, 1
  %305 = select i1 %23, i32 %300, i32 %303
  %306 = select i1 %23, i32 %301, i32 %304
  %307 = insertelement <2 x i32> undef, i32 %305, i32 0
  %308 = insertelement <2 x i32> %307, i32 %306, i32 1
  %309 = bitcast <2 x i32> %308 to i64
  %310 = fmul reassoc nsz arcp contract float %293, 0x3F7B717580000000, !spirv.Decorations !634
  %311 = sitofp i32 %298 to float
  %312 = sitofp i32 %297 to float
  %313 = fmul reassoc nnan nsz arcp contract float %312, 5.100000e+02, !spirv.Decorations !636
  %314 = fsub reassoc nnan nsz arcp contract float %311, %313, !spirv.Decorations !636
  %315 = fmul reassoc nsz arcp contract float %310, %314, !spirv.Decorations !634
  %316 = add i64 %270, %309
  %317 = inttoptr i64 %316 to ptr addrspace(1)
  store float %315, ptr addrspace(1) %317, align 4
  ret void, !stats.blockFrequency.digits !628, !stats.blockFrequency.scale !629
}

; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL4pairRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE(ptr byval(%"class.sycl::_V1::range") align 8 %0, ptr byval(%class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_) align 8 %1, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %globalSize, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i64 %const_reg_qword, i64 %const_reg_qword1, i64 %const_reg_qword2, i64 %const_reg_qword3, i64 %const_reg_qword4, i64 %const_reg_qword5, i32 %const_reg_dword, i8 %const_reg_byte, i8 %const_reg_byte6, i8 %const_reg_byte7, i8 %const_reg_byte8, i64 %const_reg_qword9, i64 %const_reg_qword10) #0 {
  %3 = bitcast i64 %const_reg_qword to <2 x i32>
  %4 = extractelement <2 x i32> %3, i32 0
  %5 = extractelement <2 x i32> %3, i32 1
  %6 = extractelement <3 x i32> %globalOffset, i32 0
  %7 = extractelement <3 x i32> %enqueuedLocalSize, i32 0
  %8 = extractelement <8 x i32> %r0, i32 1
  %9 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %7, i32 0, i32 %8, i32 0)
  %10 = extractvalue { i32, i32 } %9, 0
  %11 = extractvalue { i32, i32 } %9, 1
  %12 = insertelement <2 x i32> undef, i32 %10, i32 0
  %13 = insertelement <2 x i32> %12, i32 %11, i32 1
  %14 = bitcast <2 x i32> %13 to i64
  %15 = zext i16 %localIdX to i64
  %16 = add nuw i64 %14, %15
  %17 = zext i32 %6 to i64
  %18 = add nuw i64 %16, %17
  %19 = bitcast i64 %18 to <2 x i32>
  %20 = extractelement <2 x i32> %19, i32 0
  %21 = extractelement <2 x i32> %19, i32 1
  %22 = icmp eq i32 %21, %5
  %23 = icmp ult i32 %20, %4
  %24 = and i1 %22, %23
  %25 = icmp ult i32 %21, %5
  %26 = or i1 %24, %25
  %27 = ashr i32 %const_reg_dword, 31
  %28 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %const_reg_dword, i32 %27, i32 640, i32 0)
  %29 = extractvalue { i32, i32 } %28, 0
  %30 = extractvalue { i32, i32 } %28, 1
  br i1 %26, label %.lr.ph.preheader, label %.._crit_edge_crit_edge, !stats.blockFrequency.digits !638, !stats.blockFrequency.scale !639

.._crit_edge_crit_edge:                           ; preds = %2
  br label %._crit_edge, !stats.blockFrequency.digits !640, !stats.blockFrequency.scale !641

.lr.ph.preheader:                                 ; preds = %2
  %31 = bitcast i64 %const_reg_qword1 to <2 x i32>
  %32 = extractelement <2 x i32> %31, i32 0
  %33 = extractelement <2 x i32> %31, i32 1
  %34 = bitcast i64 %const_reg_qword2 to <2 x i32>
  %35 = extractelement <2 x i32> %34, i32 0
  %36 = extractelement <2 x i32> %34, i32 1
  %37 = bitcast i64 %const_reg_qword3 to <2 x i32>
  %38 = extractelement <2 x i32> %37, i32 0
  %39 = extractelement <2 x i32> %37, i32 1
  %40 = bitcast i64 %const_reg_qword4 to <2 x i32>
  %41 = extractelement <2 x i32> %40, i32 0
  %42 = extractelement <2 x i32> %40, i32 1
  %43 = bitcast i64 %const_reg_qword5 to <2 x i32>
  %44 = extractelement <2 x i32> %43, i32 0
  %45 = extractelement <2 x i32> %43, i32 1
  %46 = extractelement <3 x i32> %globalSize, i32 0
  %47 = insertelement <2 x i32> undef, i32 %29, i32 0
  %48 = insertelement <2 x i32> %47, i32 %30, i32 1
  %49 = bitcast <2 x i32> %48 to i64
  %50 = trunc i64 %49 to i32
  %51 = uitofp i64 %49 to double
  %52 = fptrunc double %51 to float
  %53 = fdiv float 1.000000e+00, %52
  %54 = fsub double 0.000000e+00, %51
  %55 = fpext float %53 to double
  %56 = call double @llvm.fma.f64(double %54, double %55, double 1.000000e+00) #4
  %57 = fadd double %56, 0xBCF0000000000000
  %58 = call double @llvm.fma.f64(double %55, double %57, double %55) #4
  %59 = and i32 %29, -128
  %tobool.i37 = icmp eq i32 %const_reg_dword, 0
  %60 = sext i32 %const_reg_dword to i64
  %61 = uitofp i64 %60 to double
  %62 = fptrunc double %61 to float
  %63 = fdiv float 1.000000e+00, %62
  %64 = fsub double 0.000000e+00, %61
  %65 = fpext float %63 to double
  %66 = call double @llvm.fma.f64(double %64, double %65, double 1.000000e+00) #4
  %67 = fadd double %66, 0xBCF0000000000000
  %68 = call double @llvm.fma.f64(double %65, double %67, double %65) #4
  %isneg = icmp slt i32 %const_reg_dword, 0
  %69 = zext i32 %46 to i64
  br label %.lr.ph, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !641

.lr.ph:                                           ; preds = %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, %.lr.ph.preheader
  %70 = phi i64 [ %347, %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge ], [ %18, %.lr.ph.preheader ]
  %71 = bitcast i64 %70 to <2 x i32>
  %72 = extractelement <2 x i32> %71, i32 0
  %73 = extractelement <2 x i32> %71, i32 1
  %74 = icmp eq i32 %73, %33
  %75 = icmp ult i32 %72, %32
  %76 = and i1 %74, %75
  %77 = icmp ult i32 %73, %33
  %78 = or i1 %76, %77
  %79 = select i1 %78, i32 %35, i32 %38
  %80 = select i1 %78, i32 %36, i32 %39
  %81 = insertelement <2 x i32> undef, i32 %79, i32 0
  %82 = insertelement <2 x i32> %81, i32 %80, i32 1
  %83 = bitcast <2 x i32> %82 to i64
  %84 = select i1 %78, i32 0, i32 %32
  %85 = select i1 %78, i32 0, i32 %33
  %86 = insertelement <2 x i32> undef, i32 %84, i32 0
  %87 = insertelement <2 x i32> %86, i32 %85, i32 1
  %88 = bitcast <2 x i32> %87 to i64
  %89 = sub nsw i64 %70, %88, !spirv.Decorations !626
  %90 = bitcast i64 %89 to <2 x i32>
  %91 = extractelement <2 x i32> %90, i32 0
  %92 = extractelement <2 x i32> %90, i32 1
  %93 = or i32 %30, %92
  %94 = icmp ult i32 %93, 1
  br i1 %94, label %95, label %113, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !643

95:                                               ; preds = %.lr.ph
  br i1 %tobool.i37, label %.precompiled_u32divrem_sp.exit59_crit_edge, label %if.end.i38, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

.precompiled_u32divrem_sp.exit59_crit_edge:       ; preds = %95
  br label %precompiled_u32divrem_sp.exit59, !stats.blockFrequency.digits !645, !stats.blockFrequency.scale !646

if.end.i38:                                       ; preds = %95
  %96 = trunc nuw i64 %89 to i32
  %97 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %50)
  %conv.i39 = fptoui float %97 to i32
  %sub.i40 = sub i32 %50, %conv.i39
  %98 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %96)
  %div.i43 = fdiv float 1.000000e+00, %97, !fpmath !631
  %99 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i43, float 0xBE98000000000000, float %div.i43)
  %100 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %98, float %99)
  %conv3.i41 = fptoui float %98 to i32
  %sub4.i42 = sub i32 %96, %conv3.i41
  %conv8.i44 = fptoui float %100 to i32
  %101 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i40)
  %102 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i42)
  %103 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i44)
  %104 = fsub float 0.000000e+00, %97
  %105 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %104, float %103, float %98)
  %106 = fsub float 0.000000e+00, %101
  %107 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %106, float %103, float %102)
  %108 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %105, float %107)
  %109 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %99, float %108)
  %conv16.i47 = fptoui float %109 to i32
  %add.i48 = add i32 %conv16.i47, %conv8.i44
  %mul.i49 = mul i32 %add.i48, %50
  %sub17.i50 = sub i32 %96, %mul.i49
  %cmp.i51 = icmp uge i32 %sub17.i50, %50
  %110 = sext i1 %cmp.i51 to i32
  %111 = sub i32 0, %110
  %add19.i54 = add i32 %add.i48, %111
  br label %precompiled_u32divrem_sp.exit59, !stats.blockFrequency.digits !647, !stats.blockFrequency.scale !648

precompiled_u32divrem_sp.exit59:                  ; preds = %.precompiled_u32divrem_sp.exit59_crit_edge, %if.end.i38
  %retval.0.i58 = phi i32 [ %add19.i54, %if.end.i38 ], [ -1, %.precompiled_u32divrem_sp.exit59_crit_edge ]
  %112 = zext i32 %retval.0.i58 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

113:                                              ; preds = %.lr.ph
  %114 = bitcast i64 %89 to <2 x i32>
  %115 = extractelement <2 x i32> %114, i32 1
  %116 = uitofp i32 %115 to double
  %117 = fmul double %58, %116
  %118 = fptoui double %117 to i32
  %119 = mul i32 %118, %50
  %120 = sub i32 %115, %119
  %121 = trunc i64 %89 to i32
  %122 = uitofp i32 %120 to double
  %123 = uitofp i32 %121 to double
  %124 = call double @llvm.fma.f64(double %122, double 0x41F0000000000000, double %123) #4
  %125 = fmul double %58, %124
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
  %136 = icmp eq i32 %133, 0
  %137 = icmp eq i32 %132, 0
  %138 = and i1 %136, %137
  %139 = mul i32 %129, %30
  %140 = select i1 %138, i32 0, i32 %50
  %141 = add i32 %139, %140
  %142 = sub i32 %120, %141
  %143 = insertelement <2 x i32> undef, i32 %91, i32 0
  %144 = insertelement <2 x i32> %143, i32 %142, i32 1
  %145 = bitcast <2 x i32> %144 to i64
  %146 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %128, i32 0, i32 %59, i32 0)
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
  %160 = icmp eq i32 %155, %30
  %161 = icmp uge i32 %154, %29
  %162 = and i1 %160, %161
  %163 = icmp ugt i32 %155, %30
  %164 = or i1 %162, %163
  %165 = sext i1 %164 to i64
  %166 = sub i64 0, %165
  %167 = add i64 %159, %166
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit59, %113
  %168 = phi i64 [ %112, %precompiled_u32divrem_sp.exit59 ], [ %167, %113 ]
  %169 = icmp ult i32 %92, 1
  br i1 %169, label %udiv_pow2_64b_as_32b, label %udiv_pow2_64b, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !643

udiv_pow2_64b:                                    ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %u.hi32 = lshr i64 %89, 32
  %170 = bitcast i64 %u.hi32 to <2 x i32>
  %171 = extractelement <2 x i32> %170, i32 0
  %172 = extractelement <2 x i32> %170, i32 1
  %173 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %91, i32 0, i32 -858993459, i32 0)
  %174 = extractvalue { i32, i32 } %173, 0
  %175 = extractvalue { i32, i32 } %173, 1
  %176 = insertelement <2 x i32> undef, i32 %174, i32 0
  %177 = insertelement <2 x i32> %176, i32 %175, i32 1
  %178 = bitcast <2 x i32> %177 to i64
  %179 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %171, i32 %172, i32 -858993459, i32 0)
  %180 = extractvalue { i32, i32 } %179, 0
  %181 = extractvalue { i32, i32 } %179, 1
  %182 = insertelement <2 x i32> undef, i32 %180, i32 0
  %183 = insertelement <2 x i32> %182, i32 %181, i32 1
  %184 = bitcast <2 x i32> %183 to i64
  %w0.lo32 = lshr i64 %178, 32
  %t = add nuw i64 %184, %w0.lo32
  %185 = bitcast i64 %t to <2 x i32>
  %186 = extractelement <2 x i32> %185, i32 0
  %187 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %91, i32 0, i32 -858993460, i32 0)
  %188 = extractvalue { i32, i32 } %187, 0
  %189 = extractvalue { i32, i32 } %187, 1
  %190 = insertelement <2 x i32> undef, i32 %188, i32 0
  %191 = insertelement <2 x i32> %190, i32 %189, i32 1
  %192 = bitcast <2 x i32> %191 to i64
  %193 = insertelement <2 x i32> undef, i32 %186, i32 0
  %194 = insertelement <2 x i32> %193, i32 0, i32 1
  %195 = bitcast <2 x i32> %194 to i64
  %w1 = add nuw i64 %192, %195
  %196 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %171, i32 %172, i32 -858993460, i32 0)
  %197 = extractvalue { i32, i32 } %196, 0
  %198 = extractvalue { i32, i32 } %196, 1
  %199 = insertelement <2 x i32> undef, i32 %197, i32 0
  %200 = insertelement <2 x i32> %199, i32 %198, i32 1
  %201 = bitcast <2 x i32> %200 to i64
  %t.hi32 = lshr i64 %t, 32
  %202 = add nuw i64 %201, %t.hi32
  %w1.lo32 = lshr i64 %w1, 32
  %uv = add nuw i64 %202, %w1.lo32
  %q_appx35 = lshr i64 %uv, 9
  br label %205, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

udiv_pow2_64b_as_32b:                             ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %203 = trunc nuw i64 %89 to i32
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %203, i32 -858993459)
  %q_appx34 = lshr i32 %q_appx, 9
  %204 = zext nneg i32 %q_appx34 to i64
  br label %205, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

205:                                              ; preds = %udiv_pow2_64b, %udiv_pow2_64b_as_32b
  %206 = phi i64 [ %204, %udiv_pow2_64b_as_32b ], [ %q_appx35, %udiv_pow2_64b ]
  %207 = bitcast i64 %206 to <2 x i32>
  %208 = extractelement <2 x i32> %207, i32 0
  %209 = extractelement <2 x i32> %207, i32 1
  %210 = or i32 %209, %27
  %211 = icmp ult i32 %210, 1
  br i1 %211, label %212, label %228, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !643

212:                                              ; preds = %205
  br i1 %tobool.i37, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %212
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !645, !stats.blockFrequency.scale !646

if.end.i:                                         ; preds = %212
  %213 = trunc nuw i64 %206 to i32
  %214 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword)
  %conv.i = fptoui float %214 to i32
  %sub.i = sub i32 %const_reg_dword, %conv.i
  %215 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %213)
  %div.i = fdiv float 1.000000e+00, %214, !fpmath !631
  %216 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %217 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %215, float %216)
  %conv3.i = fptoui float %215 to i32
  %sub4.i = sub i32 %213, %conv3.i
  %conv8.i = fptoui float %217 to i32
  %218 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %219 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %220 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %221 = fsub float 0.000000e+00, %214
  %222 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %221, float %220, float %215)
  %223 = fsub float 0.000000e+00, %218
  %224 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %223, float %220, float %219)
  %225 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %222, float %224)
  %226 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %216, float %225)
  %conv16.i = fptoui float %226 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %const_reg_dword
  %sub17.i = sub i32 %213, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !647, !stats.blockFrequency.scale !648

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %227 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

228:                                              ; preds = %205
  %229 = bitcast i64 %206 to <2 x i32>
  %230 = extractelement <2 x i32> %229, i32 1
  %231 = uitofp nneg i32 %230 to double
  %232 = fmul double %68, %231
  %233 = fptoui double %232 to i32
  %234 = mul i32 %const_reg_dword, %233
  %235 = sub i32 %230, %234
  %236 = trunc i64 %206 to i32
  %237 = uitofp i32 %235 to double
  %238 = uitofp i32 %236 to double
  %239 = call double @llvm.fma.f64(double %237, double 0x41F0000000000000, double %238) #4
  %240 = fmul double %68, %239
  %241 = fptoui double %240 to i64
  %242 = bitcast i64 %241 to <2 x i32>
  %243 = extractelement <2 x i32> %242, i32 0
  %244 = extractelement <2 x i32> %242, i32 1
  %245 = trunc i64 %241 to i32
  %.neg60 = select i1 %isneg, i32 %245, i32 0
  %246 = icmp ult i32 %244, 1
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
  %263 = icmp eq i32 %262, %27
  %264 = icmp ult i32 %261, %const_reg_dword
  %265 = and i1 %263, %264
  %266 = icmp ult i32 %262, %27
  %267 = or i1 %265, %266
  %268 = select i1 %267, i32 0, i32 %const_reg_dword
  %269 = select i1 %267, i32 0, i32 %27
  %270 = insertelement <2 x i32> undef, i32 %268, i32 0
  %271 = insertelement <2 x i32> %270, i32 %269, i32 1
  %272 = bitcast <2 x i32> %271 to i64
  %273 = sub i64 %259, %272
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

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
  %294 = add nsw i64 %293, %283, !spirv.Decorations !626
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
  %312 = ashr exact i64 %282, 30
  %313 = add i64 %const_reg_qword9, %312
  %314 = inttoptr i64 %313 to ptr addrspace(1)
  %315 = load float, ptr addrspace(1) %314, align 4
  %316 = add i64 %const_reg_qword10, %312
  %317 = inttoptr i64 %316 to ptr addrspace(1)
  %318 = load i32, ptr addrspace(1) %317, align 4
  %319 = add nsw i32 %307, %311, !spirv.Decorations !626
  %320 = select i1 %78, i32 %41, i32 %44
  %321 = select i1 %78, i32 %42, i32 %45
  %322 = insertelement <2 x i32> undef, i32 %320, i32 0
  %323 = insertelement <2 x i32> %322, i32 %321, i32 1
  %324 = bitcast <2 x i32> %323 to i64
  %325 = fmul reassoc nsz arcp contract float %315, 0x3F7B717580000000, !spirv.Decorations !634
  %326 = sitofp i32 %319 to float
  %327 = sitofp i32 %318 to float
  %328 = fmul reassoc nnan nsz arcp contract float %327, 5.100000e+02, !spirv.Decorations !636
  %329 = fsub reassoc nnan nsz arcp contract float %326, %328, !spirv.Decorations !636
  %330 = fmul reassoc nsz arcp contract float %325, %329, !spirv.Decorations !634
  %331 = add i64 %324, %291
  %332 = inttoptr i64 %331 to ptr addrspace(4)
  %333 = addrspacecast ptr addrspace(4) %332 to ptr addrspace(1)
  store float %330, ptr addrspace(1) %333, align 4
  %334 = add nuw nsw i64 %70, %69
  %335 = bitcast i64 %334 to <2 x i32>
  %336 = extractelement <2 x i32> %335, i32 0
  %337 = extractelement <2 x i32> %335, i32 1
  %338 = icmp eq i32 %337, %5
  %339 = icmp ult i32 %336, %4
  %340 = and i1 %338, %339
  %341 = icmp ult i32 %337, %5
  %342 = or i1 %340, %341
  br i1 %342, label %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, label %._crit_edge.loopexit, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !643

._crit_edge.loopexit:                             ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %._crit_edge, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !641

__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge:   ; preds = %__igcbuiltin_u64_urem_dp.exit
  %343 = select i1 %342, i32 %336, i32 %20
  %344 = select i1 %342, i32 %337, i32 %21
  %345 = insertelement <2 x i32> undef, i32 %343, i32 0
  %346 = insertelement <2 x i32> %345, i32 %344, i32 1
  %347 = bitcast <2 x i32> %346 to i64
  br label %.lr.ph, !stats.blockFrequency.digits !649, !stats.blockFrequency.scale !643

._crit_edge:                                      ; preds = %.._crit_edge_crit_edge, %._crit_edge.loopexit
  ret void, !stats.blockFrequency.digits !638, !stats.blockFrequency.scale !639
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
  %13 = ashr i32 %0, 31
  %14 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %0, i32 %13, i32 640, i32 0)
  %15 = extractvalue { i32, i32 } %14, 0
  %16 = extractvalue { i32, i32 } %14, 1
  %17 = insertelement <2 x i32> undef, i32 %15, i32 0
  %18 = insertelement <2 x i32> %17, i32 %16, i32 1
  %19 = bitcast <2 x i32> %18 to i64
  %20 = icmp ult i32 %16, 1
  br i1 %20, label %65, label %21, !stats.blockFrequency.digits !628, !stats.blockFrequency.scale !629

21:                                               ; preds = %5
  %22 = trunc i64 %19 to i32
  %23 = uitofp i64 %19 to double
  %24 = fptrunc double %23 to float
  %25 = fdiv float 1.000000e+00, %24
  %26 = fsub double 0.000000e+00, %23
  %27 = fpext float %25 to double
  %28 = call double @llvm.fma.f64(double %26, double %27, double 1.000000e+00) #4
  %29 = fadd double %28, 0xBCF0000000000000
  %30 = call double @llvm.fma.f64(double %27, double %29, double %27) #4
  %31 = uitofp nneg i32 %12 to double
  %32 = fmul double %30, %31
  %33 = fptoui double %32 to i64
  %34 = bitcast i64 %33 to <2 x i32>
  %35 = extractelement <2 x i32> %34, i32 0
  %36 = extractelement <2 x i32> %34, i32 1
  %37 = trunc i64 %33 to i32
  %38 = mul i32 %37, %16
  %39 = icmp ult i32 %36, 1
  %40 = select i1 %39, i32 0, i32 %22
  %41 = add i32 %38, %40
  %42 = sub i32 0, %41
  %43 = insertelement <2 x i32> undef, i32 %12, i32 0
  %44 = insertelement <2 x i32> %43, i32 %42, i32 1
  %45 = bitcast <2 x i32> %44 to i64
  %46 = and i32 %15, -128
  %47 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %35, i32 0, i32 %46, i32 0)
  %48 = extractvalue { i32, i32 } %47, 0
  %49 = extractvalue { i32, i32 } %47, 1
  %50 = insertelement <2 x i32> undef, i32 %48, i32 0
  %51 = insertelement <2 x i32> %50, i32 %49, i32 1
  %52 = bitcast <2 x i32> %51 to i64
  %53 = sub i64 %45, %52
  %54 = bitcast i64 %53 to <2 x i32>
  %55 = extractelement <2 x i32> %54, i32 0
  %56 = extractelement <2 x i32> %54, i32 1
  %57 = icmp eq i32 %56, %16
  %58 = icmp uge i32 %55, %15
  %59 = and i1 %57, %58
  %60 = icmp ugt i32 %56, %16
  %61 = or i1 %59, %60
  %62 = sext i1 %61 to i64
  %63 = sub i64 0, %62
  %64 = add i64 %33, %63
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

65:                                               ; preds = %5
  %tobool.i27 = icmp eq i32 %0, 0
  br i1 %tobool.i27, label %.precompiled_u32divrem_sp.exit49_crit_edge, label %if.end.i28, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

if.end.i28:                                       ; preds = %65
  %66 = trunc nuw i64 %19 to i32
  %67 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %66)
  %conv.i29 = fptoui float %67 to i32
  %sub.i30 = sub i32 %66, %conv.i29
  %68 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %12)
  %div.i33 = fdiv float 1.000000e+00, %67, !fpmath !631
  %69 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i33, float 0xBE98000000000000, float %div.i33)
  %70 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %68, float %69)
  %conv3.i31 = fptoui float %68 to i32
  %sub4.i32 = sub i32 %12, %conv3.i31
  %conv8.i34 = fptoui float %70 to i32
  %71 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i30)
  %72 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i32)
  %73 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i34)
  %74 = fsub float 0.000000e+00, %67
  %75 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %74, float %73, float %68)
  %76 = fsub float 0.000000e+00, %71
  %77 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %76, float %73, float %72)
  %78 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %75, float %77)
  %79 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %69, float %78)
  %conv16.i37 = fptoui float %79 to i32
  %add.i38 = add i32 %conv16.i37, %conv8.i34
  %mul.i39 = mul i32 %add.i38, %66
  %sub17.i40 = sub i32 %12, %mul.i39
  %cmp.i41 = icmp uge i32 %sub17.i40, %66
  %80 = sext i1 %cmp.i41 to i32
  %81 = sub i32 0, %80
  %add19.i44 = add i32 %add.i38, %81
  br label %precompiled_u32divrem_sp.exit49, !stats.blockFrequency.digits !632, !stats.blockFrequency.scale !629

.precompiled_u32divrem_sp.exit49_crit_edge:       ; preds = %65
  br label %precompiled_u32divrem_sp.exit49, !stats.blockFrequency.digits !633, !stats.blockFrequency.scale !629

precompiled_u32divrem_sp.exit49:                  ; preds = %.precompiled_u32divrem_sp.exit49_crit_edge, %if.end.i28
  %retval.0.i48 = phi i32 [ %add19.i44, %if.end.i28 ], [ -1, %.precompiled_u32divrem_sp.exit49_crit_edge ]
  %82 = zext i32 %retval.0.i48 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !630, !stats.blockFrequency.scale !629

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit49, %21
  %83 = phi i64 [ %82, %precompiled_u32divrem_sp.exit49 ], [ %64, %21 ]
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %12, i32 -858993459)
  %q_appx25 = lshr i32 %q_appx, 9
  %84 = icmp sgt i32 %0, -1
  br i1 %84, label %129, label %85, !stats.blockFrequency.digits !628, !stats.blockFrequency.scale !629

85:                                               ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %86 = sext i32 %0 to i64
  %87 = uitofp i64 %86 to double
  %88 = fptrunc double %87 to float
  %89 = fdiv float 1.000000e+00, %88
  %90 = fsub double 0.000000e+00, %87
  %91 = fpext float %89 to double
  %92 = call double @llvm.fma.f64(double %90, double %91, double 1.000000e+00) #4
  %93 = fadd double %92, 0xBCF0000000000000
  %94 = call double @llvm.fma.f64(double %91, double %93, double %91) #4
  %95 = uitofp nneg i32 %q_appx25 to double
  %96 = fmul double %94, %95
  %97 = fptoui double %96 to i64
  %98 = bitcast i64 %97 to <2 x i32>
  %99 = extractelement <2 x i32> %98, i32 0
  %100 = extractelement <2 x i32> %98, i32 1
  %101 = trunc i64 %97 to i32
  %102 = icmp ult i32 %100, 1
  %103 = select i1 %102, i32 0, i32 %0
  %104 = sub i32 %101, %103
  %105 = insertelement <2 x i32> undef, i32 %q_appx25, i32 0
  %106 = insertelement <2 x i32> %105, i32 %104, i32 1
  %107 = bitcast <2 x i32> %106 to i64
  %108 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %99, i32 0, i32 %0, i32 0)
  %109 = extractvalue { i32, i32 } %108, 0
  %110 = extractvalue { i32, i32 } %108, 1
  %111 = insertelement <2 x i32> undef, i32 %109, i32 0
  %112 = insertelement <2 x i32> %111, i32 %110, i32 1
  %113 = bitcast <2 x i32> %112 to i64
  %114 = sub i64 %107, %113
  %115 = bitcast i64 %114 to <2 x i32>
  %116 = extractelement <2 x i32> %115, i32 0
  %117 = extractelement <2 x i32> %115, i32 1
  %118 = icmp eq i32 %117, %13
  %119 = icmp ult i32 %116, %0
  %120 = and i1 %118, %119
  %121 = icmp ult i32 %117, %13
  %122 = or i1 %120, %121
  %123 = select i1 %122, i32 0, i32 %0
  %124 = select i1 %122, i32 0, i32 %13
  %125 = insertelement <2 x i32> undef, i32 %123, i32 0
  %126 = insertelement <2 x i32> %125, i32 %124, i32 1
  %127 = bitcast <2 x i32> %126 to i64
  %128 = sub i64 %114, %127
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !650, !stats.blockFrequency.scale !629

129:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %tobool.i = icmp eq i32 %0, 0
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !651, !stats.blockFrequency.scale !629

if.end.i:                                         ; preds = %129
  %130 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %0)
  %conv.i = fptoui float %130 to i32
  %sub.i = sub i32 %0, %conv.i
  %131 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %q_appx25)
  %div.i = fdiv float 1.000000e+00, %130, !fpmath !631
  %132 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %133 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %131, float %132)
  %conv3.i = fptoui float %131 to i32
  %sub4.i = sub i32 %q_appx25, %conv3.i
  %conv8.i = fptoui float %133 to i32
  %134 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %135 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %136 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %137 = fsub float 0.000000e+00, %130
  %138 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %137, float %136, float %131)
  %139 = fsub float 0.000000e+00, %134
  %140 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %139, float %136, float %135)
  %141 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %138, float %140)
  %142 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %132, float %141)
  %conv16.i = fptoui float %142 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %0
  %sub17.i = sub i32 %q_appx25, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %0
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %0
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !652, !stats.blockFrequency.scale !629

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %129
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !653, !stats.blockFrequency.scale !629

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %143 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !651, !stats.blockFrequency.scale !629

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %85
  %144 = phi i64 [ %143, %precompiled_u32divrem_sp.exit ], [ %128, %85 ]
  %.neg = mul nsw i32 %q_appx25, -640
  %145 = add nsw i32 %.neg, %12
  %146 = ptrtoint ptr addrspace(1) %1 to i64
  %147 = zext i32 %145 to i64
  %148 = shl nuw nsw i64 %147, 2
  %149 = add i64 %148, %146
  %150 = shl nuw nsw i64 %83, 4, !spirv.Decorations !654
  %151 = add nuw nsw i64 %150, %144, !spirv.Decorations !654
  %152 = bitcast i64 %151 to <2 x i32>
  %153 = extractelement <2 x i32> %152, i32 0
  %154 = extractelement <2 x i32> %152, i32 1
  %155 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %153, i32 %154, i32 2560, i32 0)
  %156 = extractvalue { i32, i32 } %155, 0
  %157 = extractvalue { i32, i32 } %155, 1
  %158 = insertelement <2 x i32> undef, i32 %156, i32 0
  %159 = insertelement <2 x i32> %158, i32 %157, i32 1
  %160 = bitcast <2 x i32> %159 to i64
  %161 = add i64 %149, %160
  %162 = inttoptr i64 %161 to ptr addrspace(1)
  %163 = load i32, ptr addrspace(1) %162, align 4
  %164 = add i64 %161, 409600
  %165 = inttoptr i64 %164 to ptr addrspace(1)
  %166 = load i32, ptr addrspace(1) %165, align 4
  %167 = shl i64 %144, 2
  %168 = ptrtoint ptr addrspace(1) %3 to i64
  %169 = add i64 %167, %168
  %170 = inttoptr i64 %169 to ptr addrspace(1)
  %171 = load float, ptr addrspace(1) %170, align 4
  %172 = ptrtoint ptr addrspace(1) %4 to i64
  %173 = add i64 %167, %172
  %174 = inttoptr i64 %173 to ptr addrspace(1)
  %175 = load i32, ptr addrspace(1) %174, align 4
  %176 = add nsw i32 %163, %166, !spirv.Decorations !626
  %177 = fmul reassoc nsz arcp contract float %171, 0x3F7B717580000000, !spirv.Decorations !634
  %178 = sitofp i32 %176 to float
  %179 = sitofp i32 %175 to float
  %180 = fmul reassoc nnan nsz arcp contract float %179, 5.100000e+02, !spirv.Decorations !636
  %181 = fsub reassoc nnan nsz arcp contract float %178, %180, !spirv.Decorations !636
  %182 = fmul reassoc nsz arcp contract float %177, %181, !spirv.Decorations !634
  %183 = ptrtoint ptr addrspace(1) %2 to i64
  %184 = zext nneg i32 %12 to i64
  %185 = shl nuw nsw i64 %184, 2
  %186 = add i64 %185, %183
  %187 = inttoptr i64 %186 to ptr addrspace(1)
  store float %182, ptr addrspace(1) %187, align 4
  ret void, !stats.blockFrequency.digits !628, !stats.blockFrequency.scale !629
}

; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL5splitRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE(ptr byval(%"class.sycl::_V1::range") align 8 %0, ptr byval(%class._ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_) align 8 %1, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %globalSize, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i64 %const_reg_qword, i32 %const_reg_dword, i8 %const_reg_byte, i8 %const_reg_byte1, i8 %const_reg_byte2, i8 %const_reg_byte3, i64 %const_reg_qword4, i64 %const_reg_qword5, i64 %const_reg_qword6, i64 %const_reg_qword7) #0 {
  %3 = bitcast i64 %const_reg_qword to <2 x i32>
  %4 = extractelement <2 x i32> %3, i32 0
  %5 = extractelement <2 x i32> %3, i32 1
  %6 = extractelement <3 x i32> %globalOffset, i32 0
  %7 = extractelement <3 x i32> %enqueuedLocalSize, i32 0
  %8 = extractelement <8 x i32> %r0, i32 1
  %9 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %7, i32 0, i32 %8, i32 0)
  %10 = extractvalue { i32, i32 } %9, 0
  %11 = extractvalue { i32, i32 } %9, 1
  %12 = insertelement <2 x i32> undef, i32 %10, i32 0
  %13 = insertelement <2 x i32> %12, i32 %11, i32 1
  %14 = bitcast <2 x i32> %13 to i64
  %15 = zext i16 %localIdX to i64
  %16 = add nuw i64 %14, %15
  %17 = zext i32 %6 to i64
  %18 = add nuw i64 %16, %17
  %19 = bitcast i64 %18 to <2 x i32>
  %20 = extractelement <2 x i32> %19, i32 0
  %21 = extractelement <2 x i32> %19, i32 1
  %22 = icmp eq i32 %21, %5
  %23 = icmp ult i32 %20, %4
  %24 = and i1 %22, %23
  %25 = icmp ult i32 %21, %5
  %26 = or i1 %24, %25
  %27 = ashr i32 %const_reg_dword, 31
  %28 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %const_reg_dword, i32 %27, i32 640, i32 0)
  %29 = extractvalue { i32, i32 } %28, 0
  %30 = extractvalue { i32, i32 } %28, 1
  br i1 %26, label %.lr.ph.preheader, label %.._crit_edge_crit_edge, !stats.blockFrequency.digits !638, !stats.blockFrequency.scale !639

.._crit_edge_crit_edge:                           ; preds = %2
  br label %._crit_edge, !stats.blockFrequency.digits !640, !stats.blockFrequency.scale !641

.lr.ph.preheader:                                 ; preds = %2
  %31 = extractelement <3 x i32> %globalSize, i32 0
  %32 = insertelement <2 x i32> undef, i32 %29, i32 0
  %33 = insertelement <2 x i32> %32, i32 %30, i32 1
  %34 = bitcast <2 x i32> %33 to i64
  %35 = trunc i64 %34 to i32
  %36 = uitofp i64 %34 to double
  %37 = fptrunc double %36 to float
  %38 = fdiv float 1.000000e+00, %37
  %39 = fsub double 0.000000e+00, %36
  %40 = fpext float %38 to double
  %41 = call double @llvm.fma.f64(double %39, double %40, double 1.000000e+00) #4
  %42 = fadd double %41, 0xBCF0000000000000
  %43 = call double @llvm.fma.f64(double %40, double %42, double %40) #4
  %44 = and i32 %29, -128
  %tobool.i32 = icmp eq i32 %const_reg_dword, 0
  %45 = icmp sgt i32 %const_reg_dword, -1
  %46 = sext i32 %const_reg_dword to i64
  %47 = uitofp i64 %46 to double
  %48 = fptrunc double %47 to float
  %49 = fdiv float 1.000000e+00, %48
  %50 = fsub double 0.000000e+00, %47
  %51 = fpext float %49 to double
  %52 = call double @llvm.fma.f64(double %50, double %51, double 1.000000e+00) #4
  %53 = fadd double %52, 0xBCF0000000000000
  %54 = call double @llvm.fma.f64(double %51, double %53, double %51) #4
  %55 = zext i32 %31 to i64
  br label %.lr.ph, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !641

.lr.ph:                                           ; preds = %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, %.lr.ph.preheader
  %56 = phi i64 [ %239, %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge ], [ %18, %.lr.ph.preheader ]
  %57 = bitcast i64 %56 to <2 x i32>
  %58 = extractelement <2 x i32> %57, i32 1
  %59 = or i32 %30, %58
  %60 = icmp ult i32 %59, 1
  br i1 %60, label %61, label %79, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !643

61:                                               ; preds = %.lr.ph
  br i1 %tobool.i32, label %.precompiled_u32divrem_sp.exit54_crit_edge, label %if.end.i33, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

.precompiled_u32divrem_sp.exit54_crit_edge:       ; preds = %61
  br label %precompiled_u32divrem_sp.exit54, !stats.blockFrequency.digits !645, !stats.blockFrequency.scale !646

if.end.i33:                                       ; preds = %61
  %62 = trunc nuw i64 %56 to i32
  %63 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %35)
  %conv.i34 = fptoui float %63 to i32
  %sub.i35 = sub i32 %35, %conv.i34
  %64 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %62)
  %div.i38 = fdiv float 1.000000e+00, %63, !fpmath !631
  %65 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i38, float 0xBE98000000000000, float %div.i38)
  %66 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %64, float %65)
  %conv3.i36 = fptoui float %64 to i32
  %sub4.i37 = sub i32 %62, %conv3.i36
  %conv8.i39 = fptoui float %66 to i32
  %67 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i35)
  %68 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i37)
  %69 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i39)
  %70 = fsub float 0.000000e+00, %63
  %71 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %70, float %69, float %64)
  %72 = fsub float 0.000000e+00, %67
  %73 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %72, float %69, float %68)
  %74 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %71, float %73)
  %75 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %65, float %74)
  %conv16.i42 = fptoui float %75 to i32
  %add.i43 = add i32 %conv16.i42, %conv8.i39
  %mul.i44 = mul i32 %add.i43, %35
  %sub17.i45 = sub i32 %62, %mul.i44
  %cmp.i46 = icmp uge i32 %sub17.i45, %35
  %76 = sext i1 %cmp.i46 to i32
  %77 = sub i32 0, %76
  %add19.i49 = add i32 %add.i43, %77
  br label %precompiled_u32divrem_sp.exit54, !stats.blockFrequency.digits !647, !stats.blockFrequency.scale !648

precompiled_u32divrem_sp.exit54:                  ; preds = %.precompiled_u32divrem_sp.exit54_crit_edge, %if.end.i33
  %retval.0.i53 = phi i32 [ %add19.i49, %if.end.i33 ], [ -1, %.precompiled_u32divrem_sp.exit54_crit_edge ]
  %78 = zext i32 %retval.0.i53 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

79:                                               ; preds = %.lr.ph
  %80 = extractelement <2 x i32> %57, i32 0
  %81 = bitcast i64 %56 to <2 x i32>
  %82 = extractelement <2 x i32> %81, i32 1
  %83 = uitofp i32 %82 to double
  %84 = fmul double %43, %83
  %85 = fptoui double %84 to i32
  %86 = mul i32 %85, %35
  %87 = sub i32 %82, %86
  %88 = trunc i64 %56 to i32
  %89 = uitofp i32 %87 to double
  %90 = uitofp i32 %88 to double
  %91 = call double @llvm.fma.f64(double %89, double 0x41F0000000000000, double %90) #4
  %92 = fmul double %43, %91
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
  %103 = icmp eq i32 %100, 0
  %104 = icmp eq i32 %99, 0
  %105 = and i1 %103, %104
  %106 = mul i32 %96, %30
  %107 = select i1 %105, i32 0, i32 %35
  %108 = add i32 %106, %107
  %109 = sub i32 %87, %108
  %110 = insertelement <2 x i32> undef, i32 %80, i32 0
  %111 = insertelement <2 x i32> %110, i32 %109, i32 1
  %112 = bitcast <2 x i32> %111 to i64
  %113 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %95, i32 0, i32 %44, i32 0)
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
  %127 = icmp eq i32 %122, %30
  %128 = icmp uge i32 %121, %29
  %129 = and i1 %127, %128
  %130 = icmp ugt i32 %122, %30
  %131 = or i1 %129, %130
  %132 = sext i1 %131 to i64
  %133 = sub i64 0, %132
  %134 = add i64 %126, %133
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !644

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit54, %79
  %135 = phi i64 [ %78, %precompiled_u32divrem_sp.exit54 ], [ %134, %79 ]
  %136 = trunc nuw nsw i64 %56 to i32
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %136, i32 -858993459)
  %q_appx30 = lshr i32 %q_appx, 9
  br i1 %45, label %137, label %152, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !643

137:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  br i1 %tobool.i32, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !647, !stats.blockFrequency.scale !644

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %137
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !656, !stats.blockFrequency.scale !648

if.end.i:                                         ; preds = %137
  %138 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword)
  %conv.i = fptoui float %138 to i32
  %sub.i = sub i32 %const_reg_dword, %conv.i
  %139 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %q_appx30)
  %div.i = fdiv float 1.000000e+00, %138, !fpmath !631
  %140 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %141 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %139, float %140)
  %conv3.i = fptoui float %139 to i32
  %sub4.i = sub i32 %q_appx30, %conv3.i
  %conv8.i = fptoui float %141 to i32
  %142 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %143 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %144 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %145 = fsub float 0.000000e+00, %138
  %146 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %145, float %144, float %139)
  %147 = fsub float 0.000000e+00, %142
  %148 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %147, float %144, float %143)
  %149 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %146, float %148)
  %150 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %140, float %149)
  %conv16.i = fptoui float %150 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %const_reg_dword
  %sub17.i = sub i32 %q_appx30, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !657, !stats.blockFrequency.scale !648

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %151 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !647, !stats.blockFrequency.scale !644

152:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %153 = uitofp nneg i32 %q_appx30 to double
  %154 = fmul double %54, %153
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
  %176 = icmp eq i32 %175, %27
  %177 = icmp ult i32 %174, %const_reg_dword
  %178 = and i1 %176, %177
  %179 = icmp ult i32 %175, %27
  %180 = or i1 %178, %179
  %181 = select i1 %180, i32 0, i32 %const_reg_dword
  %182 = select i1 %180, i32 0, i32 %27
  %183 = insertelement <2 x i32> undef, i32 %181, i32 0
  %184 = insertelement <2 x i32> %183, i32 %182, i32 1
  %185 = bitcast <2 x i32> %184 to i64
  %186 = sub i64 %172, %185
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !645, !stats.blockFrequency.scale !648

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %152
  %187 = phi i64 [ %151, %precompiled_u32divrem_sp.exit ], [ %186, %152 ]
  %.neg = mul nsw i32 %q_appx30, -640
  %188 = add nsw i32 %.neg, %136
  %189 = zext i32 %188 to i64
  %190 = shl nuw nsw i64 %189, 2
  %191 = add i64 %const_reg_qword4, %190
  %192 = shl nuw nsw i64 %135, 4, !spirv.Decorations !654
  %193 = add nuw nsw i64 %192, %187, !spirv.Decorations !654
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
  %209 = shl i64 %187, 2
  %210 = add i64 %const_reg_qword6, %209
  %211 = inttoptr i64 %210 to ptr addrspace(1)
  %212 = load float, ptr addrspace(1) %211, align 4
  %213 = add i64 %const_reg_qword7, %209
  %214 = inttoptr i64 %213 to ptr addrspace(1)
  %215 = load i32, ptr addrspace(1) %214, align 4
  %216 = add nsw i32 %205, %208, !spirv.Decorations !626
  %217 = fmul reassoc nsz arcp contract float %212, 0x3F7B717580000000, !spirv.Decorations !634
  %218 = sitofp i32 %216 to float
  %219 = sitofp i32 %215 to float
  %220 = fmul reassoc nnan nsz arcp contract float %219, 5.100000e+02, !spirv.Decorations !636
  %221 = fsub reassoc nnan nsz arcp contract float %218, %220, !spirv.Decorations !636
  %222 = fmul reassoc nsz arcp contract float %217, %221, !spirv.Decorations !634
  %223 = shl i64 %56, 2
  %224 = add i64 %const_reg_qword5, %223
  %225 = inttoptr i64 %224 to ptr addrspace(1)
  store float %222, ptr addrspace(1) %225, align 4
  %226 = add nuw nsw i64 %56, %55
  %227 = bitcast i64 %226 to <2 x i32>
  %228 = extractelement <2 x i32> %227, i32 0
  %229 = extractelement <2 x i32> %227, i32 1
  %230 = icmp eq i32 %229, %5
  %231 = icmp ult i32 %228, %4
  %232 = and i1 %230, %231
  %233 = icmp ult i32 %229, %5
  %234 = or i1 %232, %233
  br i1 %234, label %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, label %._crit_edge.loopexit, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !643

._crit_edge.loopexit:                             ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %._crit_edge, !stats.blockFrequency.digits !642, !stats.blockFrequency.scale !641

__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge:   ; preds = %__igcbuiltin_u64_urem_dp.exit
  %235 = select i1 %234, i32 %228, i32 %20
  %236 = select i1 %234, i32 %229, i32 %21
  %237 = insertelement <2 x i32> undef, i32 %235, i32 0
  %238 = insertelement <2 x i32> %237, i32 %236, i32 1
  %239 = bitcast <2 x i32> %238 to i64
  br label %.lr.ph, !stats.blockFrequency.digits !649, !stats.blockFrequency.scale !643

._crit_edge:                                      ; preds = %.._crit_edge_crit_edge, %._crit_edge.loopexit
  ret void, !stats.blockFrequency.digits !638, !stats.blockFrequency.scale !639
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
!opencl.ocl.version = !{!617}
!opencl.spir.version = !{!617}
!llvm.ident = !{!618, !619, !620}
!llvm.errno.tbaa = !{!621}
!llvm.module.flags = !{!625}

!0 = !{i32 2, i32 2}
!1 = !{i32 4, i32 100000}
!2 = !{i16 6, i16 14}
!3 = !{ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL5splitRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE, !4}
!4 = !{!5}
!5 = !{!"function_type", i32 0}
!6 = !{ptr @_ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_, !4}
!7 = !{ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL4pairRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE, !4}
!8 = !{ptr @_ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_, !4}
!9 = !{!"ModuleMD", !10, !11, !127, !443, !474, !491, !512, !522, !524, !525, !540, !541, !542, !543, !544, !548, !549, !556, !557, !558, !559, !560, !561, !562, !563, !564, !566, !570, !571, !572, !573, !574, !575, !576, !577, !578, !579, !580, !581, !582, !583, !584, !254, !585, !594, !595, !597, !599, !602, !603, !604, !606, !607, !608, !613, !614, !615, !616}
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
!127 = !{!"FuncMD", !128, !129, !294, !295, !349, !350, !390, !391}
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
!245 = !{!"maxRegPressureSimd16", i32 16}
!246 = !{!"maxRegPressureSimd32", i32 30}
!247 = !{!"maxRegUniformPressure", i32 1024}
!248 = !{!"maxRegNonUniformPressure", i32 0}
!249 = !{!"bestGuessSimd", i32 16}
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
!295 = !{!"FuncMDValue[1]", !130, !131, !135, !138, !139, !140, !141, !296, !187, !188, !189, !212, !241, !242, !243, !244, !315, !316, !317, !318, !249, !250, !251, !252, !253, !254, !255, !256, !257, !258, !259, !260, !261, !262, !263, !264, !265, !266, !319, !324, !328, !334, !340, !344, !348, !290}
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
!315 = !{!"maxRegPressureSimd16", i32 10}
!316 = !{!"maxRegPressureSimd32", i32 19}
!317 = !{!"maxRegUniformPressure", i32 40}
!318 = !{!"maxRegNonUniformPressure", i32 36}
!319 = !{!"m_OpenCLArgAddressSpaces", !268, !320, !321, !322, !323}
!320 = !{!"m_OpenCLArgAddressSpacesVec[1]", i32 1}
!321 = !{!"m_OpenCLArgAddressSpacesVec[2]", i32 1}
!322 = !{!"m_OpenCLArgAddressSpacesVec[3]", i32 1}
!323 = !{!"m_OpenCLArgAddressSpacesVec[4]", i32 1}
!324 = !{!"m_OpenCLArgAccessQualifiers", !271, !272, !325, !326, !327}
!325 = !{!"m_OpenCLArgAccessQualifiersVec[2]", !"none"}
!326 = !{!"m_OpenCLArgAccessQualifiersVec[3]", !"none"}
!327 = !{!"m_OpenCLArgAccessQualifiersVec[4]", !"none"}
!328 = !{!"m_OpenCLArgTypes", !329, !330, !331, !332, !333}
!329 = !{!"m_OpenCLArgTypesVec[0]", !"int"}
!330 = !{!"m_OpenCLArgTypesVec[1]", !"int*"}
!331 = !{!"m_OpenCLArgTypesVec[2]", !"float*"}
!332 = !{!"m_OpenCLArgTypesVec[3]", !"float*"}
!333 = !{!"m_OpenCLArgTypesVec[4]", !"int*"}
!334 = !{!"m_OpenCLArgBaseTypes", !335, !336, !337, !338, !339}
!335 = !{!"m_OpenCLArgBaseTypesVec[0]", !"int"}
!336 = !{!"m_OpenCLArgBaseTypesVec[1]", !"int*"}
!337 = !{!"m_OpenCLArgBaseTypesVec[2]", !"float*"}
!338 = !{!"m_OpenCLArgBaseTypesVec[3]", !"float*"}
!339 = !{!"m_OpenCLArgBaseTypesVec[4]", !"int*"}
!340 = !{!"m_OpenCLArgTypeQualifiers", !280, !281, !341, !342, !343}
!341 = !{!"m_OpenCLArgTypeQualifiersVec[2]", !""}
!342 = !{!"m_OpenCLArgTypeQualifiersVec[3]", !""}
!343 = !{!"m_OpenCLArgTypeQualifiersVec[4]", !""}
!344 = !{!"m_OpenCLArgNames", !283, !284, !345, !346, !347}
!345 = !{!"m_OpenCLArgNamesVec[2]", !""}
!346 = !{!"m_OpenCLArgNamesVec[3]", !""}
!347 = !{!"m_OpenCLArgNamesVec[4]", !""}
!348 = !{!"m_OpenCLArgScalarAsPointers"}
!349 = !{!"FuncMDMap[2]", ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL4pairRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE}
!350 = !{!"FuncMDValue[2]", !130, !131, !135, !138, !139, !140, !141, !351, !187, !188, !189, !371, !241, !242, !243, !244, !376, !377, !378, !248, !249, !250, !251, !252, !253, !254, !255, !256, !257, !258, !259, !260, !261, !262, !263, !264, !265, !266, !267, !270, !379, !381, !279, !282, !383, !290}
!351 = !{!"implicitArgInfoList", !143, !149, !151, !153, !155, !157, !159, !161, !163, !352, !353, !354, !355, !356, !357, !359, !361, !363, !365, !367, !369}
!352 = !{!"implicitArgInfoListVec[9]", !164, !169, !166, !147, !148}
!353 = !{!"implicitArgInfoListVec[10]", !164, !169, !180, !147, !148}
!354 = !{!"implicitArgInfoListVec[11]", !164, !169, !182, !147, !148}
!355 = !{!"implicitArgInfoListVec[12]", !164, !169, !184, !147, !148}
!356 = !{!"implicitArgInfoListVec[13]", !164, !169, !186, !147, !148}
!357 = !{!"implicitArgInfoListVec[14]", !168, !169, !358, !147, !148}
!358 = !{!"structArgOffset", i32 40}
!359 = !{!"implicitArgInfoListVec[15]", !171, !169, !360, !147, !148}
!360 = !{!"structArgOffset", i32 44}
!361 = !{!"implicitArgInfoListVec[16]", !171, !169, !362, !147, !148}
!362 = !{!"structArgOffset", i32 45}
!363 = !{!"implicitArgInfoListVec[17]", !171, !169, !364, !147, !148}
!364 = !{!"structArgOffset", i32 46}
!365 = !{!"implicitArgInfoListVec[18]", !171, !169, !366, !147, !148}
!366 = !{!"structArgOffset", i32 47}
!367 = !{!"implicitArgInfoListVec[19]", !164, !169, !368, !147, !148}
!368 = !{!"structArgOffset", i32 48}
!369 = !{!"implicitArgInfoListVec[20]", !164, !169, !370, !147, !148}
!370 = !{!"structArgOffset", i32 56}
!371 = !{!"resAllocMD", !213, !214, !215, !372, !240}
!372 = !{!"argAllocMDList", !217, !221, !222, !223, !224, !225, !226, !227, !228, !229, !230, !231, !232, !233, !234, !235, !236, !237, !238, !239, !373, !374, !375}
!373 = !{!"argAllocMDListVec[20]", !218, !219, !220}
!374 = !{!"argAllocMDListVec[21]", !218, !219, !220}
!375 = !{!"argAllocMDListVec[22]", !218, !219, !220}
!376 = !{!"maxRegPressureSimd16", i32 22}
!377 = !{!"maxRegPressureSimd32", i32 41}
!378 = !{!"maxRegUniformPressure", i32 1408}
!379 = !{!"m_OpenCLArgTypes", !274, !380}
!380 = !{!"m_OpenCLArgTypesVec[1]", !"class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_"}
!381 = !{!"m_OpenCLArgBaseTypes", !277, !382}
!382 = !{!"m_OpenCLArgBaseTypesVec[1]", !"class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_"}
!383 = !{!"m_OpenCLArgScalarAsPointers", !384, !385, !386, !387, !388, !389}
!384 = !{!"m_OpenCLArgScalarAsPointersSet[0]", i32 12}
!385 = !{!"m_OpenCLArgScalarAsPointersSet[1]", i32 13}
!386 = !{!"m_OpenCLArgScalarAsPointersSet[2]", i32 14}
!387 = !{!"m_OpenCLArgScalarAsPointersSet[3]", i32 15}
!388 = !{!"m_OpenCLArgScalarAsPointersSet[4]", i32 21}
!389 = !{!"m_OpenCLArgScalarAsPointersSet[5]", i32 22}
!390 = !{!"FuncMDMap[3]", ptr @_ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_}
!391 = !{!"FuncMDValue[3]", !130, !131, !135, !138, !139, !140, !141, !392, !187, !188, !189, !403, !241, !242, !243, !244, !409, !410, !411, !412, !249, !250, !251, !252, !253, !254, !255, !256, !257, !258, !259, !260, !261, !262, !263, !264, !265, !266, !413, !417, !421, !428, !435, !439, !348, !290}
!392 = !{!"implicitArgInfoList", !143, !149, !297, !298, !299, !300, !301, !302, !304, !306, !308, !393, !395, !397, !398, !399, !400, !401, !402}
!393 = !{!"implicitArgInfoListVec[11]", !303, !394, !146, !147, !148}
!394 = !{!"explicitArgNum", i32 6}
!395 = !{!"implicitArgInfoListVec[12]", !303, !396, !146, !147, !148}
!396 = !{!"explicitArgNum", i32 7}
!397 = !{!"implicitArgInfoListVec[13]", !311, !169, !146, !147, !148}
!398 = !{!"implicitArgInfoListVec[14]", !311, !305, !146, !147, !148}
!399 = !{!"implicitArgInfoListVec[15]", !311, !307, !146, !147, !148}
!400 = !{!"implicitArgInfoListVec[16]", !311, !309, !146, !147, !148}
!401 = !{!"implicitArgInfoListVec[17]", !311, !394, !146, !147, !148}
!402 = !{!"implicitArgInfoListVec[18]", !311, !396, !146, !147, !148}
!403 = !{!"resAllocMD", !213, !214, !215, !404, !240}
!404 = !{!"argAllocMDList", !217, !221, !222, !223, !224, !225, !226, !227, !228, !229, !230, !231, !232, !233, !234, !235, !236, !237, !238, !239, !373, !374, !375, !405, !406, !407, !408}
!405 = !{!"argAllocMDListVec[23]", !218, !219, !220}
!406 = !{!"argAllocMDListVec[24]", !218, !219, !220}
!407 = !{!"argAllocMDListVec[25]", !218, !219, !220}
!408 = !{!"argAllocMDListVec[26]", !218, !219, !220}
!409 = !{!"maxRegPressureSimd16", i32 17}
!410 = !{!"maxRegPressureSimd32", i32 32}
!411 = !{!"maxRegUniformPressure", i32 52}
!412 = !{!"maxRegNonUniformPressure", i32 61}
!413 = !{!"m_OpenCLArgAddressSpaces", !268, !320, !321, !322, !323, !414, !415, !416}
!414 = !{!"m_OpenCLArgAddressSpacesVec[5]", i32 0}
!415 = !{!"m_OpenCLArgAddressSpacesVec[6]", i32 1}
!416 = !{!"m_OpenCLArgAddressSpacesVec[7]", i32 1}
!417 = !{!"m_OpenCLArgAccessQualifiers", !271, !272, !325, !326, !327, !418, !419, !420}
!418 = !{!"m_OpenCLArgAccessQualifiersVec[5]", !"none"}
!419 = !{!"m_OpenCLArgAccessQualifiersVec[6]", !"none"}
!420 = !{!"m_OpenCLArgAccessQualifiersVec[7]", !"none"}
!421 = !{!"m_OpenCLArgTypes", !422, !330, !423, !332, !424, !425, !426, !427}
!422 = !{!"m_OpenCLArgTypesVec[0]", !"long"}
!423 = !{!"m_OpenCLArgTypesVec[2]", !"int*"}
!424 = !{!"m_OpenCLArgTypesVec[4]", !"float*"}
!425 = !{!"m_OpenCLArgTypesVec[5]", !"int"}
!426 = !{!"m_OpenCLArgTypesVec[6]", !"float*"}
!427 = !{!"m_OpenCLArgTypesVec[7]", !"int*"}
!428 = !{!"m_OpenCLArgBaseTypes", !429, !336, !430, !338, !431, !432, !433, !434}
!429 = !{!"m_OpenCLArgBaseTypesVec[0]", !"long"}
!430 = !{!"m_OpenCLArgBaseTypesVec[2]", !"int*"}
!431 = !{!"m_OpenCLArgBaseTypesVec[4]", !"float*"}
!432 = !{!"m_OpenCLArgBaseTypesVec[5]", !"int"}
!433 = !{!"m_OpenCLArgBaseTypesVec[6]", !"float*"}
!434 = !{!"m_OpenCLArgBaseTypesVec[7]", !"int*"}
!435 = !{!"m_OpenCLArgTypeQualifiers", !280, !281, !341, !342, !343, !436, !437, !438}
!436 = !{!"m_OpenCLArgTypeQualifiersVec[5]", !""}
!437 = !{!"m_OpenCLArgTypeQualifiersVec[6]", !""}
!438 = !{!"m_OpenCLArgTypeQualifiersVec[7]", !""}
!439 = !{!"m_OpenCLArgNames", !283, !284, !345, !346, !347, !440, !441, !442}
!440 = !{!"m_OpenCLArgNamesVec[5]", !""}
!441 = !{!"m_OpenCLArgNamesVec[6]", !""}
!442 = !{!"m_OpenCLArgNamesVec[7]", !""}
!443 = !{!"pushInfo", !444, !445, !446, !450, !451, !452, !453, !454, !455, !456, !457, !470, !471, !472, !473}
!444 = !{!"pushableAddresses"}
!445 = !{!"bindlessPushInfo"}
!446 = !{!"dynamicBufferInfo", !447, !448, !449}
!447 = !{!"firstIndex", i32 0}
!448 = !{!"numOffsets", i32 0}
!449 = !{!"forceDisabled", i1 false}
!450 = !{!"MaxNumberOfPushedBuffers", i32 0}
!451 = !{!"inlineConstantBufferSlot", i32 -1}
!452 = !{!"inlineConstantBufferOffset", i32 -1}
!453 = !{!"inlineConstantBufferGRFOffset", i32 -1}
!454 = !{!"constants"}
!455 = !{!"inputs"}
!456 = !{!"constantReg"}
!457 = !{!"simplePushInfoArr", !458, !467, !468, !469}
!458 = !{!"simplePushInfoArrVec[0]", !459, !460, !461, !462, !463, !464, !465, !466}
!459 = !{!"cbIdx", i32 0}
!460 = !{!"pushableAddressGrfOffset", i32 -1}
!461 = !{!"pushableOffsetGrfOffset", i32 -1}
!462 = !{!"offset", i32 0}
!463 = !{!"size", i32 0}
!464 = !{!"isStateless", i1 false}
!465 = !{!"isBindless", i1 false}
!466 = !{!"simplePushLoads"}
!467 = !{!"simplePushInfoArrVec[1]", !459, !460, !461, !462, !463, !464, !465, !466}
!468 = !{!"simplePushInfoArrVec[2]", !459, !460, !461, !462, !463, !464, !465, !466}
!469 = !{!"simplePushInfoArrVec[3]", !459, !460, !461, !462, !463, !464, !465, !466}
!470 = !{!"simplePushBufferUsed", i32 0}
!471 = !{!"pushAnalysisWIInfos"}
!472 = !{!"inlineRTGlobalPtrOffset", i32 0}
!473 = !{!"rtSyncSurfPtrOffset", i32 0}
!474 = !{!"psInfo", !475, !476, !477, !478, !479, !480, !481, !482, !483, !484, !485, !486, !487, !488, !489, !490}
!475 = !{!"BlendStateDisabledMask", i8 0}
!476 = !{!"SkipSrc0Alpha", i1 false}
!477 = !{!"DualSourceBlendingDisabled", i1 false}
!478 = !{!"ForceEnableSimd32", i1 false}
!479 = !{!"DisableSimd32WithDiscard", i1 false}
!480 = !{!"outputDepth", i1 false}
!481 = !{!"outputStencil", i1 false}
!482 = !{!"outputMask", i1 false}
!483 = !{!"blendToFillEnabled", i1 false}
!484 = !{!"forceEarlyZ", i1 false}
!485 = !{!"hasVersionedLoop", i1 false}
!486 = !{!"forceSingleSourceRTWAfterDualSourceRTW", i1 false}
!487 = !{!"blendOptimizationMode"}
!488 = !{!"colorOutputMask"}
!489 = !{!"isBlendEnabled"}
!490 = !{!"WaDisableVRS", i1 false}
!491 = !{!"csInfo", !492, !493, !494, !495, !51, !27, !28, !496, !29, !497, !498, !499, !500, !501, !502, !503, !504, !505, !506, !507, !62, !508, !509, !510, !511}
!492 = !{!"maxWorkGroupSize", i32 0}
!493 = !{!"waveSize", i32 0}
!494 = !{!"ComputeShaderSecondCompile"}
!495 = !{!"forcedSIMDSize", i8 0}
!496 = !{!"VISAPreSchedScheduleExtraGRF", i32 0}
!497 = !{!"forceSpillCompression", i1 false}
!498 = !{!"allowLowerSimd", i1 false}
!499 = !{!"disableSimd32Slicing", i1 false}
!500 = !{!"disableSplitOnSpill", i1 false}
!501 = !{!"enableNewSpillCostFunction", i1 false}
!502 = !{!"forceVISAPreSched", i1 false}
!503 = !{!"disableLocalIdOrderOptimizations", i1 false}
!504 = !{!"disableDispatchAlongY", i1 false}
!505 = !{!"neededThreadIdLayout", ptr null}
!506 = !{!"forceTileYWalk", i1 false}
!507 = !{!"atomicBranch", i32 0}
!508 = !{!"disableEarlyOut", i1 false}
!509 = !{!"walkOrderEnabled", i1 false}
!510 = !{!"walkOrderOverride", i32 0}
!511 = !{!"ResForHfPacking"}
!512 = !{!"msInfo", !513, !514, !515, !516, !517, !518, !519, !520, !521}
!513 = !{!"PrimitiveTopology", i32 3}
!514 = !{!"MaxNumOfPrimitives", i32 0}
!515 = !{!"MaxNumOfVertices", i32 0}
!516 = !{!"MaxNumOfPerPrimitiveOutputs", i32 0}
!517 = !{!"MaxNumOfPerVertexOutputs", i32 0}
!518 = !{!"WorkGroupSize", i32 0}
!519 = !{!"WorkGroupMemorySizeInBytes", i32 0}
!520 = !{!"IndexFormat", i32 6}
!521 = !{!"SubgroupSize", i32 0}
!522 = !{!"taskInfo", !523, !518, !519, !521}
!523 = !{!"MaxNumOfOutputs", i32 0}
!524 = !{!"NBarrierCnt", i32 0}
!525 = !{!"rtInfo", !526, !527, !528, !529, !530, !531, !532, !533, !534, !535, !536, !537, !538, !539, !208}
!526 = !{!"RayQueryAllocSizeInBytes", i32 0}
!527 = !{!"NumContinuations", i32 0}
!528 = !{!"RTAsyncStackAddrspace", i32 -1}
!529 = !{!"RTAsyncStackSurfaceStateOffset", ptr null}
!530 = !{!"SWHotZoneAddrspace", i32 -1}
!531 = !{!"SWHotZoneSurfaceStateOffset", ptr null}
!532 = !{!"SWStackAddrspace", i32 -1}
!533 = !{!"SWStackSurfaceStateOffset", ptr null}
!534 = !{!"RTSyncStackAddrspace", i32 -1}
!535 = !{!"RTSyncStackSurfaceStateOffset", ptr null}
!536 = !{!"doSyncDispatchRays", i1 false}
!537 = !{!"MemStyle", !"Xe"}
!538 = !{!"GlobalDataStyle", !"Xe"}
!539 = !{!"uberTileDimensions", ptr null}
!540 = !{!"hasSliceLayoutDependency", i1 false}
!541 = !{!"CurUniqueIndirectIdx", i32 0}
!542 = !{!"inlineDynTextures"}
!543 = !{!"inlineResInfoData"}
!544 = !{!"immConstant", !545, !546, !547}
!545 = !{!"data"}
!546 = !{!"sizes"}
!547 = !{!"zeroIdxs"}
!548 = !{!"stringConstants"}
!549 = !{!"inlineBuffers", !550, !554, !555}
!550 = !{!"inlineBuffersVec[0]", !551, !552, !553}
!551 = !{!"alignment", i32 0}
!552 = !{!"allocSize", i64 0}
!553 = !{!"Buffer"}
!554 = !{!"inlineBuffersVec[1]", !551, !552, !553}
!555 = !{!"inlineBuffersVec[2]", !551, !552, !553}
!556 = !{!"GlobalBufferAddressRelocInfo"}
!557 = !{!"ConstantBufferAddressRelocInfo"}
!558 = !{!"forceLscCacheList"}
!559 = !{!"SrvMap"}
!560 = !{!"RasterizerOrderedByteAddressBuffer"}
!561 = !{!"RasterizerOrderedViews"}
!562 = !{!"MinNOSPushConstantSize", i32 0}
!563 = !{!"inlineProgramScopeOffsets"}
!564 = !{!"shaderData", !565}
!565 = !{!"numReplicas", i32 0}
!566 = !{!"URBInfo", !567, !568, !569}
!567 = !{!"has64BVertexHeaderInput", i1 false}
!568 = !{!"has64BVertexHeaderOutput", i1 false}
!569 = !{!"hasVertexHeader", i1 true}
!570 = !{!"UseBindlessImage", i1 true}
!571 = !{!"HasBindlessImageRead", i1 false}
!572 = !{!"UseBindlessImageWithSamplerTracking", i1 false}
!573 = !{!"enableRangeReduce", i1 false}
!574 = !{!"allowMatchMadOptimizationforPosition", i1 false}
!575 = !{!"disableMatchMadOptimizationForCS", i1 false}
!576 = !{!"disableMemOptforNegativeOffsetLoads", i1 false}
!577 = !{!"enableThreeWayLoadSpiltOpt", i1 false}
!578 = !{!"statefulResourcesNotAliased", i1 false}
!579 = !{!"disableMixMode", i1 false}
!580 = !{!"genericAccessesResolved", i1 false}
!581 = !{!"disableSeparateSpillPvtScratchSpace", i1 false}
!582 = !{!"enableSeparateSpillPvtScratchSpace", i1 false}
!583 = !{!"disableSeparateScratchWA", i1 false}
!584 = !{!"enableRemoveUnusedTGMFence", i1 false}
!585 = !{!"PrivateMemoryPerFG", !586, !587, !588, !589, !590, !591, !592, !593}
!586 = !{!"PrivateMemoryPerFGMap[0]", ptr @_ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_}
!587 = !{!"PrivateMemoryPerFGValue[0]", i32 0}
!588 = !{!"PrivateMemoryPerFGMap[1]", ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL4pairRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE}
!589 = !{!"PrivateMemoryPerFGValue[1]", i32 0}
!590 = !{!"PrivateMemoryPerFGMap[2]", ptr @_ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_}
!591 = !{!"PrivateMemoryPerFGValue[2]", i32 0}
!592 = !{!"PrivateMemoryPerFGMap[3]", ptr @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL5splitRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE}
!593 = !{!"PrivateMemoryPerFGValue[3]", i32 0}
!594 = !{!"m_OptsToDisable"}
!595 = !{!"capabilities", !596}
!596 = !{!"globalVariableDecorationsINTEL", i1 false}
!597 = !{!"extensions", !598}
!598 = !{!"spvINTELBindlessImages", i1 false}
!599 = !{!"m_ShaderResourceViewMcsMask", !600, !601}
!600 = !{!"m_ShaderResourceViewMcsMaskVec[0]", i64 0}
!601 = !{!"m_ShaderResourceViewMcsMaskVec[1]", i64 0}
!602 = !{!"computedDepthMode", i32 0}
!603 = !{!"isHDCFastClearShader", i1 false}
!604 = !{!"argRegisterReservations", !605}
!605 = !{!"argRegisterReservationsVec[0]", i32 0}
!606 = !{!"SIMD16_SpillThreshold", i8 0}
!607 = !{!"SIMD32_SpillThreshold", i8 0}
!608 = !{!"m_CacheControlOption", !609, !610, !611, !612}
!609 = !{!"LscLoadCacheControlOverride", i8 0}
!610 = !{!"LscStoreCacheControlOverride", i8 0}
!611 = !{!"TgmLoadCacheControlOverride", i8 0}
!612 = !{!"TgmStoreCacheControlOverride", i8 0}
!613 = !{!"ModuleUsesBindless", i1 false}
!614 = !{!"predicationMap"}
!615 = !{!"lifeTimeStartMap"}
!616 = !{!"HitGroups"}
!617 = !{i32 2, i32 0}
!618 = !{!"clang version 22.1.8 (Fedora 22.1.8-4.fc44)"}
!619 = !{!"clang version 9.0.0 (2dbee6917918354f14026a637370445d50bdaf6a)"}
!620 = !{!"clang version 9.0.0 (c68f557a081b1b2339a42d7cd6af3c2ab18c6061)"}
!621 = !{!622, !622, i64 0}
!622 = !{!"int", !623, i64 0}
!623 = !{!"omnipotent char", !624, i64 0}
!624 = !{!"Simple C/C++ TBAA"}
!625 = !{i32 1, !"wchar_size", i32 4}
!626 = !{!627}
!627 = !{i32 4469}
!628 = !{!"180143985094819840"}
!629 = !{!"-54"}
!630 = !{!"90071992547409920"}
!631 = !{float 2.500000e+00}
!632 = !{!"56294995342131200"}
!633 = !{!"33776997205278720"}
!634 = !{!635}
!635 = !{i32 40, i32 196620}
!636 = !{!637}
!637 = !{i32 40, i32 196621}
!638 = !{!"163840"}
!639 = !{!"-14"}
!640 = !{!"11529215046068459520"}
!641 = !{!"-61"}
!642 = !{!"11529215046068480000"}
!643 = !{!"-56"}
!644 = !{!"-57"}
!645 = !{!"17293822569102720000"}
!646 = !{!"-59"}
!647 = !{!"14411518807585600000"}
!648 = !{!"-58"}
!649 = !{!"11168927075878840000"}
!650 = !{!"67553994410557440"}
!651 = !{!"112589990684262400"}
!652 = !{!"70368744177664000"}
!653 = !{!"42221246506598400"}
!654 = !{!627, !655}
!655 = !{i32 4470}
!656 = !{!"10808639105689200000"}
!657 = !{!"18014398509482000000"}

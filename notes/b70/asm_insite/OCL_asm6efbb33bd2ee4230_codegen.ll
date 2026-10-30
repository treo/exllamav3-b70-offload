; ------------------------------------------------
; OCL_asm6efbb33bd2ee4230_codegen.ll
; ------------------------------------------------
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "spir64-unknown-unknown"

%struct.Meta = type <{ i32, i32, i32, i32, i32, i32, double, float, [4 x i8] }>

; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSZL12combine_pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_RK4MetaiiEUlNS0_2idILi1EEEE_(i64 %0, ptr addrspace(1) align 4 %1, ptr addrspace(1) align 4 %2, ptr addrspace(1) align 4 %3, ptr addrspace(1) align 4 %4, ptr byval(%struct.Meta) align 8 %5, i32 %6, i32 %7, ptr addrspace(1) align 4 %8, ptr addrspace(1) align 4 %9, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i32 %const_reg_dword, i32 %const_reg_dword1, i32 %const_reg_dword2, i32 %const_reg_dword3, i32 %const_reg_dword4, i32 %const_reg_dword5, i64 %const_reg_qword, float %const_reg_fp32, i8 %const_reg_byte, i8 %const_reg_byte6, i8 %const_reg_byte7, i8 %const_reg_byte8, i32 %bufferOffset, i32 %bufferOffset9, i32 %bufferOffset10, i32 %bufferOffset11, i32 %bufferOffset12, i32 %bufferOffset13, i32 %bindlessOffset, i32 %bindlessOffset14, i32 %bindlessOffset15, i32 %bindlessOffset16, i32 %bindlessOffset17, i32 %bindlessOffset18) #0 {
  %11 = bitcast i64 %0 to <2 x i32>
  %12 = extractelement <2 x i32> %11, i32 0
  %13 = extractelement <2 x i32> %11, i32 1
  %14 = extractelement <3 x i32> %globalOffset, i32 0
  %15 = extractelement <3 x i32> %enqueuedLocalSize, i32 0
  %16 = extractelement <8 x i32> %r0, i32 1
  %17 = mul i32 %15, %16
  %18 = zext i16 %localIdX to i32
  %19 = add i32 %17, %18
  %20 = add i32 %19, %14
  %21 = icmp eq i32 %13, 0
  %22 = icmp ugt i32 %12, %20
  %23 = and i1 %21, %22
  %24 = icmp ugt i32 %13, 0
  %25 = or i1 %23, %24
  %26 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %1)
  %27 = extractvalue { i32, i32 } %26, 0
  %28 = extractvalue { i32, i32 } %26, 1
  %29 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %2)
  %30 = extractvalue { i32, i32 } %29, 0
  %31 = extractvalue { i32, i32 } %29, 1
  %32 = select i1 %25, i32 %27, i32 %30
  %33 = select i1 %25, i32 %28, i32 %31
  %34 = select i1 %25, i32 0, i32 %12
  %35 = select i1 %25, i32 0, i32 %13
  %36 = insertelement <2 x i32> undef, i32 %34, i32 0
  %37 = insertelement <2 x i32> %36, i32 %35, i32 1
  %38 = bitcast <2 x i32> %37 to i64
  %39 = zext nneg i32 %20 to i64
  %40 = sub nsw i64 %39, %38, !spirv.Decorations !556
  %41 = bitcast i64 %40 to <2 x i32>
  %42 = extractelement <2 x i32> %41, i32 0
  %43 = extractelement <2 x i32> %41, i32 1
  %44 = ashr i32 %const_reg_dword1, 31
  %45 = ashr i32 %const_reg_dword5, 31
  %46 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %const_reg_dword1, i32 %44, i32 %const_reg_dword5, i32 %45)
  %47 = extractvalue { i32, i32 } %46, 0
  %48 = extractvalue { i32, i32 } %46, 1
  %49 = insertelement <2 x i32> undef, i32 %47, i32 0
  %50 = insertelement <2 x i32> %49, i32 %48, i32 1
  %51 = bitcast <2 x i32> %50 to i64
  %52 = or i32 %48, %43
  %53 = icmp ult i32 %52, 1
  br i1 %53, label %118, label %54, !stats.blockFrequency.digits !558, !stats.blockFrequency.scale !559

54:                                               ; preds = %10
  %55 = trunc i64 %51 to i32
  %56 = uitofp i64 %51 to double
  %57 = fptrunc double %56 to float
  %58 = fdiv float 1.000000e+00, %57
  %59 = fsub double 0.000000e+00, %56
  %60 = fpext float %58 to double
  %61 = call double @llvm.fma.f64(double %59, double %60, double 1.000000e+00) #4
  %62 = fadd double %61, 0xBCF0000000000000
  %63 = call double @llvm.fma.f64(double %60, double %62, double %60) #4
  %64 = bitcast i64 %40 to <2 x i32>
  %65 = extractelement <2 x i32> %64, i32 1
  %66 = uitofp i32 %65 to double
  %67 = fmul double %63, %66
  %68 = fptoui double %67 to i32
  %69 = mul i32 %68, %55
  %70 = sub i32 %65, %69
  %71 = trunc i64 %40 to i32
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
  %93 = insertelement <2 x i32> undef, i32 %42, i32 0
  %94 = insertelement <2 x i32> %93, i32 %92, i32 1
  %95 = bitcast <2 x i32> %94 to i64
  %96 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %78, i32 0, i32 %47, i32 0)
  %97 = extractvalue { i32, i32 } %96, 0
  %98 = extractvalue { i32, i32 } %96, 1
  %99 = insertelement <2 x i32> undef, i32 %97, i32 0
  %100 = insertelement <2 x i32> %99, i32 %98, i32 1
  %101 = bitcast <2 x i32> %100 to i64
  %102 = sub i64 %95, %101
  %103 = bitcast i64 %102 to <2 x i32>
  %104 = extractelement <2 x i32> %103, i32 0
  %105 = extractelement <2 x i32> %103, i32 1
  %106 = add i32 %85, %68
  %107 = insertelement <2 x i32> undef, i32 %78, i32 0
  %108 = insertelement <2 x i32> %107, i32 %106, i32 1
  %109 = bitcast <2 x i32> %108 to i64
  %110 = icmp eq i32 %105, %48
  %111 = icmp uge i32 %104, %47
  %112 = and i1 %110, %111
  %113 = icmp ugt i32 %105, %48
  %114 = or i1 %112, %113
  %115 = sext i1 %114 to i64
  %116 = sub i64 0, %115
  %117 = add i64 %109, %116
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561

118:                                              ; preds = %10
  %119 = icmp eq i32 %48, 0
  %120 = icmp eq i32 %47, 0
  %121 = and i1 %119, %120
  br i1 %121, label %.precompiled_u32divrem_sp.exit88_crit_edge, label %if.end.i67, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561

.precompiled_u32divrem_sp.exit88_crit_edge:       ; preds = %118
  br label %precompiled_u32divrem_sp.exit88, !stats.blockFrequency.digits !562, !stats.blockFrequency.scale !563

if.end.i67:                                       ; preds = %118
  %122 = trunc nuw i64 %40 to i32
  %123 = trunc nuw i64 %51 to i32
  %124 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %123)
  %conv.i68 = fptoui float %124 to i32
  %sub.i69 = sub i32 %123, %conv.i68
  %125 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %122)
  %div.i72 = fdiv float 1.000000e+00, %124, !fpmath !564
  %126 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i72, float 0xBE98000000000000, float %div.i72)
  %127 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %125, float %126)
  %conv3.i70 = fptoui float %125 to i32
  %sub4.i71 = sub i32 %122, %conv3.i70
  %conv8.i73 = fptoui float %127 to i32
  %128 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i69)
  %129 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i71)
  %130 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i73)
  %131 = fsub float 0.000000e+00, %124
  %132 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %131, float %130, float %125)
  %133 = fsub float 0.000000e+00, %128
  %134 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %133, float %130, float %129)
  %135 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %132, float %134)
  %136 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %126, float %135)
  %conv16.i76 = fptoui float %136 to i32
  %add.i77 = add i32 %conv16.i76, %conv8.i73
  %mul.i78 = mul i32 %add.i77, %123
  %sub17.i79 = sub i32 %122, %mul.i78
  %cmp.i80 = icmp uge i32 %sub17.i79, %123
  %137 = sext i1 %cmp.i80 to i32
  %138 = sub i32 0, %137
  %add19.i83 = add i32 %add.i77, %138
  br label %precompiled_u32divrem_sp.exit88, !stats.blockFrequency.digits !562, !stats.blockFrequency.scale !563

precompiled_u32divrem_sp.exit88:                  ; preds = %.precompiled_u32divrem_sp.exit88_crit_edge, %if.end.i67
  %retval.0.i87 = phi i32 [ %add19.i83, %if.end.i67 ], [ -1, %.precompiled_u32divrem_sp.exit88_crit_edge ]
  %139 = zext i32 %retval.0.i87 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit88, %54
  %140 = phi i64 [ %139, %precompiled_u32divrem_sp.exit88 ], [ %117, %54 ]
  %141 = or i32 %43, %45
  %142 = icmp ult i32 %141, 1
  br i1 %142, label %206, label %143, !stats.blockFrequency.digits !558, !stats.blockFrequency.scale !559

143:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %144 = sext i32 %const_reg_dword5 to i64
  %145 = uitofp i64 %144 to double
  %146 = fptrunc double %145 to float
  %147 = fdiv float 1.000000e+00, %146
  %148 = fsub double 0.000000e+00, %145
  %149 = fpext float %147 to double
  %150 = call double @llvm.fma.f64(double %148, double %149, double 1.000000e+00) #4
  %151 = fadd double %150, 0xBCF0000000000000
  %152 = call double @llvm.fma.f64(double %149, double %151, double %149) #4
  %153 = bitcast i64 %40 to <2 x i32>
  %154 = extractelement <2 x i32> %153, i32 1
  %155 = uitofp i32 %154 to double
  %156 = fmul double %152, %155
  %157 = fptoui double %156 to i32
  %158 = mul i32 %const_reg_dword5, %157
  %159 = sub i32 %154, %158
  %160 = trunc i64 %40 to i32
  %161 = uitofp i32 %159 to double
  %162 = uitofp i32 %160 to double
  %163 = call double @llvm.fma.f64(double %161, double 0x41F0000000000000, double %162) #4
  %164 = fmul double %152, %163
  %165 = fptoui double %164 to i64
  %166 = bitcast i64 %165 to <2 x i32>
  %167 = extractelement <2 x i32> %166, i32 0
  %168 = trunc i64 %165 to i32
  %169 = lshr i64 %165, 32
  %170 = bitcast i64 %169 to <2 x i32>
  %171 = extractelement <2 x i32> %170, i32 0
  %172 = extractelement <2 x i32> %170, i32 1
  %173 = bitcast i64 %165 to <2 x i32>
  %174 = extractelement <2 x i32> %173, i32 1
  %175 = icmp eq i32 %172, 0
  %176 = icmp eq i32 %171, 0
  %177 = and i1 %175, %176
  %isneg = icmp slt i32 %const_reg_dword5, 0
  %.neg90 = select i1 %isneg, i32 %168, i32 0
  %178 = add i32 %.neg90, %159
  %179 = select i1 %177, i32 0, i32 %const_reg_dword5
  %180 = sub i32 %178, %179
  %181 = insertelement <2 x i32> undef, i32 %42, i32 0
  %182 = insertelement <2 x i32> %181, i32 %180, i32 1
  %183 = bitcast <2 x i32> %182 to i64
  %184 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %167, i32 0, i32 %const_reg_dword5, i32 0)
  %185 = extractvalue { i32, i32 } %184, 0
  %186 = extractvalue { i32, i32 } %184, 1
  %187 = insertelement <2 x i32> undef, i32 %185, i32 0
  %188 = insertelement <2 x i32> %187, i32 %186, i32 1
  %189 = bitcast <2 x i32> %188 to i64
  %190 = sub i64 %183, %189
  %191 = bitcast i64 %190 to <2 x i32>
  %192 = extractelement <2 x i32> %191, i32 0
  %193 = extractelement <2 x i32> %191, i32 1
  %194 = add i32 %174, %157
  %195 = insertelement <2 x i32> undef, i32 %167, i32 0
  %196 = insertelement <2 x i32> %195, i32 %194, i32 1
  %197 = bitcast <2 x i32> %196 to i64
  %198 = icmp eq i32 %193, %45
  %199 = icmp uge i32 %192, %const_reg_dword5
  %200 = and i1 %198, %199
  %201 = icmp ugt i32 %193, %45
  %202 = or i1 %200, %201
  %203 = sext i1 %202 to i64
  %204 = sub i64 0, %203
  %205 = add i64 %197, %204
  br label %__igcbuiltin_u64_udiv_dp.exit41, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561

206:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %tobool.i43 = icmp eq i32 %const_reg_dword5, 0
  br i1 %tobool.i43, label %.precompiled_u32divrem_sp.exit65_crit_edge, label %if.end.i44, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561

.precompiled_u32divrem_sp.exit65_crit_edge:       ; preds = %206
  br label %precompiled_u32divrem_sp.exit65, !stats.blockFrequency.digits !565, !stats.blockFrequency.scale !566

if.end.i44:                                       ; preds = %206
  %207 = trunc nuw i64 %40 to i32
  %208 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword5)
  %conv.i45 = fptoui float %208 to i32
  %sub.i46 = sub i32 %const_reg_dword5, %conv.i45
  %209 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %207)
  %div.i49 = fdiv float 1.000000e+00, %208, !fpmath !564
  %210 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i49, float 0xBE98000000000000, float %div.i49)
  %211 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %209, float %210)
  %conv3.i47 = fptoui float %209 to i32
  %sub4.i48 = sub i32 %207, %conv3.i47
  %conv8.i50 = fptoui float %211 to i32
  %212 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i46)
  %213 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i48)
  %214 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i50)
  %215 = fsub float 0.000000e+00, %208
  %216 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %215, float %214, float %209)
  %217 = fsub float 0.000000e+00, %212
  %218 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %217, float %214, float %213)
  %219 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %216, float %218)
  %220 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %210, float %219)
  %conv16.i53 = fptoui float %220 to i32
  %add.i54 = add i32 %conv16.i53, %conv8.i50
  %mul.i55 = mul i32 %add.i54, %const_reg_dword5
  %sub17.i56 = sub i32 %207, %mul.i55
  %cmp.i57 = icmp uge i32 %sub17.i56, %const_reg_dword5
  %221 = sext i1 %cmp.i57 to i32
  %222 = sub i32 0, %221
  %add19.i60 = add i32 %add.i54, %222
  br label %precompiled_u32divrem_sp.exit65, !stats.blockFrequency.digits !567, !stats.blockFrequency.scale !563

precompiled_u32divrem_sp.exit65:                  ; preds = %.precompiled_u32divrem_sp.exit65_crit_edge, %if.end.i44
  %retval.0.i64 = phi i32 [ %add19.i60, %if.end.i44 ], [ -1, %.precompiled_u32divrem_sp.exit65_crit_edge ]
  %223 = zext i32 %retval.0.i64 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit41, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561

__igcbuiltin_u64_udiv_dp.exit41:                  ; preds = %precompiled_u32divrem_sp.exit65, %143
  %224 = phi i64 [ %223, %precompiled_u32divrem_sp.exit65 ], [ %205, %143 ]
  %225 = bitcast i64 %224 to <2 x i32>
  %226 = extractelement <2 x i32> %225, i32 0
  %227 = extractelement <2 x i32> %225, i32 1
  %228 = or i32 %227, %44
  %229 = icmp ult i32 %228, 1
  br i1 %229, label %285, label %230, !stats.blockFrequency.digits !558, !stats.blockFrequency.scale !559

230:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit41
  %231 = sext i32 %const_reg_dword1 to i64
  %232 = uitofp i64 %231 to double
  %233 = fptrunc double %232 to float
  %234 = fdiv float 1.000000e+00, %233
  %235 = fsub double 0.000000e+00, %232
  %236 = fpext float %234 to double
  %237 = call double @llvm.fma.f64(double %235, double %236, double 1.000000e+00) #4
  %238 = fadd double %237, 0xBCF0000000000000
  %239 = call double @llvm.fma.f64(double %236, double %238, double %236) #4
  %240 = bitcast i64 %224 to <2 x i32>
  %241 = extractelement <2 x i32> %240, i32 1
  %242 = uitofp i32 %241 to double
  %243 = fmul double %239, %242
  %244 = fptoui double %243 to i32
  %245 = mul i32 %const_reg_dword1, %244
  %246 = sub i32 %241, %245
  %247 = trunc i64 %224 to i32
  %248 = uitofp i32 %246 to double
  %249 = uitofp i32 %247 to double
  %250 = call double @llvm.fma.f64(double %248, double 0x41F0000000000000, double %249) #4
  %251 = fmul double %239, %250
  %252 = fptoui double %251 to i64
  %253 = bitcast i64 %252 to <2 x i32>
  %254 = extractelement <2 x i32> %253, i32 0
  %255 = extractelement <2 x i32> %253, i32 1
  %256 = trunc i64 %252 to i32
  %isneg92 = icmp slt i32 %const_reg_dword1, 0
  %.neg91 = select i1 %isneg92, i32 %256, i32 0
  %257 = icmp ult i32 %255, 1
  %258 = select i1 %257, i32 0, i32 %const_reg_dword1
  %259 = sub i32 %246, %258
  %260 = add i32 %.neg91, %259
  %261 = insertelement <2 x i32> undef, i32 %226, i32 0
  %262 = insertelement <2 x i32> %261, i32 %260, i32 1
  %263 = bitcast <2 x i32> %262 to i64
  %264 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %254, i32 0, i32 %const_reg_dword1, i32 0)
  %265 = extractvalue { i32, i32 } %264, 0
  %266 = extractvalue { i32, i32 } %264, 1
  %267 = insertelement <2 x i32> undef, i32 %265, i32 0
  %268 = insertelement <2 x i32> %267, i32 %266, i32 1
  %269 = bitcast <2 x i32> %268 to i64
  %270 = sub i64 %263, %269
  %271 = bitcast i64 %270 to <2 x i32>
  %272 = extractelement <2 x i32> %271, i32 0
  %273 = extractelement <2 x i32> %271, i32 1
  %274 = icmp eq i32 %273, %44
  %275 = icmp ult i32 %272, %const_reg_dword1
  %276 = and i1 %274, %275
  %277 = icmp ult i32 %273, %44
  %278 = or i1 %276, %277
  %279 = select i1 %278, i32 0, i32 %const_reg_dword1
  %280 = select i1 %278, i32 0, i32 %44
  %281 = insertelement <2 x i32> undef, i32 %279, i32 0
  %282 = insertelement <2 x i32> %281, i32 %280, i32 1
  %283 = bitcast <2 x i32> %282 to i64
  %284 = sub i64 %270, %283
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561

285:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit41
  %tobool.i = icmp eq i32 %const_reg_dword1, 0
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %285
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !565, !stats.blockFrequency.scale !566

if.end.i:                                         ; preds = %285
  %286 = trunc nuw i64 %224 to i32
  %287 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword1)
  %conv.i = fptoui float %287 to i32
  %sub.i = sub i32 %const_reg_dword1, %conv.i
  %288 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %286)
  %div.i = fdiv float 1.000000e+00, %287, !fpmath !564
  %289 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %290 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %288, float %289)
  %conv3.i = fptoui float %288 to i32
  %sub4.i = sub i32 %286, %conv3.i
  %conv8.i = fptoui float %290 to i32
  %291 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %292 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %293 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %294 = fsub float 0.000000e+00, %287
  %295 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %294, float %293, float %288)
  %296 = fsub float 0.000000e+00, %291
  %297 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %296, float %293, float %292)
  %298 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %295, float %297)
  %299 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %289, float %298)
  %conv16.i = fptoui float %299 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %const_reg_dword1
  %sub17.i = sub i32 %286, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword1
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword1
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !567, !stats.blockFrequency.scale !563

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %300 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %230
  %301 = phi i64 [ %300, %precompiled_u32divrem_sp.exit ], [ %284, %230 ]
  %302 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %226, i32 %227, i32 %const_reg_dword5, i32 %45)
  %303 = extractvalue { i32, i32 } %302, 0
  %304 = extractvalue { i32, i32 } %302, 1
  %305 = bitcast i64 %301 to <2 x i32>
  %306 = extractelement <2 x i32> %305, i32 0
  %307 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %306, i32 1
  %308 = bitcast <2 x i32> %307 to i64
  %309 = icmp sgt i32 %6, 0
  br i1 %309, label %.lr.ph.preheader, label %__igcbuiltin_u64_urem_dp.exit._crit_edge, !stats.blockFrequency.digits !558, !stats.blockFrequency.scale !559

__igcbuiltin_u64_urem_dp.exit._crit_edge:         ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %368, !stats.blockFrequency.digits !568, !stats.blockFrequency.scale !563

.lr.ph.preheader:                                 ; preds = %__igcbuiltin_u64_urem_dp.exit
  %310 = insertelement <2 x i32> undef, i32 %32, i32 0
  %311 = insertelement <2 x i32> %310, i32 %33, i32 1
  %312 = bitcast <2 x i32> %311 to i64
  %313 = insertelement <2 x i32> undef, i32 %303, i32 0
  %314 = insertelement <2 x i32> %313, i32 %304, i32 1
  %315 = bitcast <2 x i32> %314 to i64
  %316 = sub i64 %40, %315
  %317 = shl nsw i32 %6, 1, !spirv.Decorations !556
  %318 = ashr i32 %const_reg_dword, 31
  %319 = bitcast i64 %140 to <2 x i32>
  %320 = extractelement <2 x i32> %319, i32 0
  %321 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %320, i32 1
  %322 = bitcast <2 x i32> %321 to i64
  %323 = ashr exact i64 %322, 32
  %324 = ashr i32 %7, 31
  %325 = ashr exact i64 %308, 32
  %326 = bitcast i64 %316 to <2 x i32>
  %327 = extractelement <2 x i32> %326, i32 0
  %328 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %327, i32 1
  %329 = bitcast <2 x i32> %328 to i64
  %330 = ashr exact i64 %329, 30
  %331 = add i64 %330, %312
  br label %.lr.ph, !stats.blockFrequency.digits !567, !stats.blockFrequency.scale !561

.lr.ph:                                           ; preds = %.lr.ph..lr.ph_crit_edge, %.lr.ph.preheader
  %332 = phi i32 [ %365, %.lr.ph..lr.ph_crit_edge ], [ 0, %.lr.ph.preheader ]
  %333 = phi i32 [ %364, %.lr.ph..lr.ph_crit_edge ], [ 0, %.lr.ph.preheader ]
  %334 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %332, i32 0, i32 %const_reg_dword, i32 %318)
  %335 = extractvalue { i32, i32 } %334, 0
  %336 = extractvalue { i32, i32 } %334, 1
  %337 = insertelement <2 x i32> undef, i32 %335, i32 0
  %338 = insertelement <2 x i32> %337, i32 %336, i32 1
  %339 = bitcast <2 x i32> %338 to i64
  %340 = add nsw i64 %339, %323, !spirv.Decorations !556
  %341 = bitcast i64 %340 to <2 x i32>
  %342 = extractelement <2 x i32> %341, i32 0
  %343 = extractelement <2 x i32> %341, i32 1
  %344 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %342, i32 %343, i32 %7, i32 %324)
  %345 = extractvalue { i32, i32 } %344, 0
  %346 = extractvalue { i32, i32 } %344, 1
  %347 = insertelement <2 x i32> undef, i32 %345, i32 0
  %348 = insertelement <2 x i32> %347, i32 %346, i32 1
  %349 = bitcast <2 x i32> %348 to i64
  %350 = add i64 %349, %325
  %351 = bitcast i64 %350 to <2 x i32>
  %352 = extractelement <2 x i32> %351, i32 0
  %353 = extractelement <2 x i32> %351, i32 1
  %354 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %352, i32 %353, i32 %const_reg_dword5, i32 %45)
  %355 = extractvalue { i32, i32 } %354, 0
  %356 = extractvalue { i32, i32 } %354, 1
  %357 = insertelement <2 x i32> undef, i32 %355, i32 0
  %358 = insertelement <2 x i32> %357, i32 %356, i32 1
  %359 = bitcast <2 x i32> %358 to i64
  %360 = shl i64 %359, 2
  %361 = add i64 %331, %360
  %362 = inttoptr i64 %361 to ptr addrspace(1)
  %363 = load i32, ptr addrspace(1) %362, align 4
  %364 = add nsw i32 %333, %363, !spirv.Decorations !556
  %365 = add nuw nsw i32 %332, 1, !spirv.Decorations !569
  %366 = icmp slt i32 %365, %317
  br i1 %366, label %.lr.ph..lr.ph_crit_edge, label %._crit_edge, !stats.blockFrequency.digits !567, !stats.blockFrequency.scale !571

._crit_edge:                                      ; preds = %.lr.ph
  %.lcssa94 = phi i32 [ %364, %.lr.ph ]
  %367 = sitofp i32 %.lcssa94 to float
  br label %368, !stats.blockFrequency.digits !567, !stats.blockFrequency.scale !561

.lr.ph..lr.ph_crit_edge:                          ; preds = %.lr.ph
  br label %.lr.ph, !stats.blockFrequency.digits !572, !stats.blockFrequency.scale !571

368:                                              ; preds = %__igcbuiltin_u64_urem_dp.exit._crit_edge, %._crit_edge
  %.lcssa = phi float [ %367, %._crit_edge ], [ 0.000000e+00, %__igcbuiltin_u64_urem_dp.exit._crit_edge ]
  %369 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %3)
  %370 = extractvalue { i32, i32 } %369, 0
  %371 = extractvalue { i32, i32 } %369, 1
  %372 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %4)
  %373 = extractvalue { i32, i32 } %372, 0
  %374 = extractvalue { i32, i32 } %372, 1
  %375 = select i1 %25, i32 %370, i32 %373
  %376 = select i1 %25, i32 %371, i32 %374
  %377 = insertelement <2 x i32> undef, i32 %375, i32 0
  %378 = insertelement <2 x i32> %377, i32 %376, i32 1
  %379 = bitcast <2 x i32> %378 to i64
  %380 = ptrtoint ptr addrspace(1) %8 to i64
  %381 = ashr exact i64 %308, 30
  %382 = add i64 %381, %380
  %383 = inttoptr i64 %382 to ptr addrspace(1)
  %384 = load float, ptr addrspace(1) %383, align 4
  %385 = ptrtoint ptr addrspace(1) %9 to i64
  %386 = add i64 %381, %385
  %387 = inttoptr i64 %386 to ptr addrspace(1)
  %388 = load i32, ptr addrspace(1) %387, align 4
  %389 = fmul reassoc nsz arcp contract float %const_reg_fp32, %384, !spirv.Decorations !573
  %390 = sitofp i32 %388 to float
  %391 = fmul reassoc nnan nsz arcp contract float %390, 5.100000e+02, !spirv.Decorations !575
  %392 = fsub reassoc nnan nsz arcp contract float %.lcssa, %391, !spirv.Decorations !575
  %393 = fmul reassoc nsz arcp contract float %389, %392, !spirv.Decorations !573
  %394 = shl i64 %40, 2
  %395 = add i64 %394, %379
  %396 = inttoptr i64 %395 to ptr addrspace(1)
  store float %393, ptr addrspace(1) %396, align 4
  ret void, !stats.blockFrequency.digits !558, !stats.blockFrequency.scale !559
}

; Function Attrs: nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write)
declare void @llvm.assume(i1 noundef) #1

; Function Attrs: nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none)
declare double @llvm.fma.f64(double, double, double) #2

; Function Desc: 
; Output: 
; Arg 0: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32) #3

; Function Desc: 
; Output: 
; Arg 0: 
; Arg 1: 
; Arg 2: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float, float, float) #3

; Function Desc: 
; Output: 
; Arg 0: 
; Arg 1: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float, float) #3

; Function Desc: 
; Output: 
; Arg 0: 
; Arg 1: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float, float) #3

; Function Desc: 
; Output: 
; Arg 0: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1)) #3

; Function Desc: 
; Output: 
; Arg 0: 
; Arg 1: 
; Arg 2: 
; Arg 3: 
; Function Attrs: nounwind willreturn memory(none)
; Unknown intrinsic
declare { i32, i32 } @llvm.genx.GenISA.mul.pair(i32, i32, i32, i32) #3

attributes #0 = { convergent nounwind null_pointer_is_valid "less-precise-fpmad"="false" }
attributes #1 = { nocallback nofree nosync nounwind willreturn memory(inaccessiblemem: write) }
attributes #2 = { nocallback nocreateundeforpoison nofree nosync nounwind speculatable willreturn memory(none) }
attributes #3 = { nounwind willreturn memory(none) }
attributes #4 = { nounwind }

!spirv.MemoryModel = !{!0}
!spirv.Source = !{!1}
!spirv.Generator = !{!2}
!igc.functions = !{!3}
!IGCMetadata = !{!6}
!opencl.ocl.version = !{!547}
!opencl.spir.version = !{!547}
!llvm.ident = !{!548, !549, !550}
!llvm.errno.tbaa = !{!551}
!llvm.module.flags = !{!555}

!0 = !{i32 2, i32 2}
!1 = !{i32 0, i32 100000}
!2 = !{i16 6, i16 14}
!3 = !{ptr @_ZTSZL12combine_pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_RK4MetaiiEUlNS0_2idILi1EEEE_, !4}
!4 = !{!5}
!5 = !{!"function_type", i32 0}
!6 = !{!"ModuleMD", !7, !8, !124, !379, !410, !427, !448, !458, !460, !461, !476, !477, !478, !479, !480, !484, !485, !492, !493, !494, !495, !496, !497, !498, !499, !500, !502, !506, !507, !508, !509, !510, !511, !512, !513, !514, !515, !516, !517, !518, !519, !520, !295, !521, !524, !525, !527, !529, !532, !533, !534, !536, !537, !538, !543, !544, !545, !546}
!7 = !{!"isPrecise", i1 false}
!8 = !{!"compOpt", !9, !10, !11, !12, !13, !14, !15, !16, !17, !18, !19, !20, !21, !22, !23, !24, !25, !26, !27, !28, !29, !30, !31, !32, !33, !34, !35, !36, !37, !38, !39, !40, !41, !42, !43, !44, !45, !46, !47, !48, !49, !50, !51, !52, !53, !54, !55, !56, !57, !58, !59, !60, !61, !62, !63, !64, !65, !66, !67, !68, !69, !70, !71, !72, !73, !74, !75, !76, !77, !78, !79, !80, !81, !82, !83, !84, !85, !86, !87, !88, !89, !90, !91, !92, !93, !94, !95, !96, !97, !98, !99, !100, !101, !102, !103, !104, !105, !106, !107, !108, !109, !110, !111, !112, !113, !114, !115, !116, !117, !118, !119, !120, !121, !122, !123}
!9 = !{!"DenormsAreZero", i1 false}
!10 = !{!"BFTFDenormsAreZero", i1 false}
!11 = !{!"CorrectlyRoundedDivSqrt", i1 false}
!12 = !{!"OptDisable", i1 false}
!13 = !{!"MadEnable", i1 true}
!14 = !{!"NoSignedZeros", i1 false}
!15 = !{!"NoNaNs", i1 false}
!16 = !{!"FloatDenormMode16", !"FLOAT_DENORM_RETAIN"}
!17 = !{!"FloatDenormMode32", !"FLOAT_DENORM_RETAIN"}
!18 = !{!"FloatDenormMode64", !"FLOAT_DENORM_RETAIN"}
!19 = !{!"FloatDenormModeBFTF", !"FLOAT_DENORM_RETAIN"}
!20 = !{!"FloatRoundingMode", i32 0}
!21 = !{!"FloatCvtIntRoundingMode", i32 3}
!22 = !{!"LoadCacheDefault", i32 4}
!23 = !{!"StoreCacheDefault", i32 2}
!24 = !{!"VISAPreSchedRPThreshold", i32 0}
!25 = !{!"VISAPreSchedCtrl", i32 0}
!26 = !{!"SetLoopUnrollThreshold", i32 0}
!27 = !{!"UnsafeMathOptimizations", i1 false}
!28 = !{!"disableCustomUnsafeOpts", i1 false}
!29 = !{!"disableReducePow", i1 false}
!30 = !{!"disableSqrtOpt", i1 false}
!31 = !{!"FiniteMathOnly", i1 false}
!32 = !{!"FastRelaxedMath", i1 false}
!33 = !{!"DashGSpecified", i1 false}
!34 = !{!"FastCompilation", i1 false}
!35 = !{!"UseScratchSpacePrivateMemory", i1 true}
!36 = !{!"RelaxedBuiltins", i1 false}
!37 = !{!"SubgroupIndependentForwardProgressRequired", i1 true}
!38 = !{!"GreaterThan2GBBufferRequired", i1 true}
!39 = !{!"GreaterThan4GBBufferRequired", i1 true}
!40 = !{!"DisableA64WA", i1 false}
!41 = !{!"ForceEnableA64WA", i1 false}
!42 = !{!"PushConstantsEnable", i1 true}
!43 = !{!"HasPositivePointerOffset", i1 false}
!44 = !{!"HasBufferOffsetArg", i1 true}
!45 = !{!"BufferOffsetArgOptional", i1 true}
!46 = !{!"replaceGlobalOffsetsByZero", i1 false}
!47 = !{!"forcePixelShaderSIMDMode", i32 0}
!48 = !{!"forceTotalGRFNum", i32 0}
!49 = !{!"ForceGeomFFShaderSIMDMode", i32 0}
!50 = !{!"pixelShaderDoNotAbortOnSpill", i1 false}
!51 = !{!"UniformWGS", i1 false}
!52 = !{!"disableVertexComponentPacking", i1 false}
!53 = !{!"disablePartialVertexComponentPacking", i1 false}
!54 = !{!"PreferBindlessImages", i1 true}
!55 = !{!"UseBindlessMode", i1 true}
!56 = !{!"UseLegacyBindlessMode", i1 false}
!57 = !{!"disableMathRefactoring", i1 false}
!58 = !{!"atomicBranch", i1 false}
!59 = !{!"spillCompression", i1 false}
!60 = !{!"AllowLICM", i1 true}
!61 = !{!"DisableEarlyOut", i1 false}
!62 = !{!"ForceInt32DivRemEmu", i1 false}
!63 = !{!"ForceInt32DivRemEmuSP", i1 false}
!64 = !{!"DisableIntDivRemIncrementReduction", i1 false}
!65 = !{!"DisableFastestSingleCSSIMD", i1 false}
!66 = !{!"DisableFastestLinearScan", i1 false}
!67 = !{!"UseStatelessforPrivateMemory", i1 false}
!68 = !{!"EnableTakeGlobalAddress", i1 false}
!69 = !{!"IsLibraryCompilation", i1 false}
!70 = !{!"LibraryCompileSIMDSize", i32 0}
!71 = !{!"FastVISACompile", i1 false}
!72 = !{!"MatchSinCosPi", i1 false}
!73 = !{!"ExcludeIRFromZEBinary", i1 false}
!74 = !{!"EmitZeBinVISASections", i1 false}
!75 = !{!"FP64GenEmulationEnabled", i1 false}
!76 = !{!"FP64GenConvEmulationEnabled", i1 false}
!77 = !{!"allowDisableRematforCS", i1 false}
!78 = !{!"DisableIncSpillCostAllAddrTaken", i1 false}
!79 = !{!"DisableCPSOmaskWA", i1 false}
!80 = !{!"DisableFastestGopt", i1 false}
!81 = !{!"WaForceHalfPromotionComputeShader", i1 false}
!82 = !{!"WaForceHalfPromotionPixelVertexShader", i1 false}
!83 = !{!"DisableConstantCoalescing", i1 false}
!84 = !{!"DisableBitcastedLoadNarrowing", i1 false}
!85 = !{!"EnableUndefAlphaOutputAsRed", i1 true}
!86 = !{!"WaEnableALTModeVisaWA", i1 false}
!87 = !{!"WaConvergentGradientsOnGenISA", i1 false}
!88 = !{!"WaDisableDualSIMD8", i1 false}
!89 = !{!"EnableLdStCombineforLoad", i1 false}
!90 = !{!"EnableLdStCombinewithDummyLoad", i1 false}
!91 = !{!"WaZeroInactiveLanesForWaveShuffle", i1 false}
!92 = !{!"ForceUniformBuffer", i1 false}
!93 = !{!"ForceUniformSurfaceSampler", i1 false}
!94 = !{!"EnableIndependentSharedMemoryFenceFunctionality", i1 false}
!95 = !{!"NewSpillCostFunction", i1 false}
!96 = !{!"EnableVRT", i1 true}
!97 = !{!"ForceLargeGRFNum4RQ", i1 false}
!98 = !{!"DisableEUFusion", i1 false}
!99 = !{!"DisableFDivToFMulInvOpt", i1 false}
!100 = !{!"initializePhiSampleSourceWA", i1 false}
!101 = !{!"WaDisableSubspanUseNoMaskForCB", i1 false}
!102 = !{!"DisableLoosenSimd32Occu", i1 false}
!103 = !{!"FastestS1Options", i32 0}
!104 = !{!"DisableFastestForWaveIntrinsicsCS", i1 false}
!105 = !{!"ForceLinearWalkOnLinearUAV", i1 false}
!106 = !{!"LscSamplerRouting", i32 0}
!107 = !{!"UseBarrierControlFlowOptimization", i1 false}
!108 = !{!"EnableDynamicRQManagement", i1 false}
!109 = !{!"WaDisablePayloadCoalescing", i1 false}
!110 = !{!"Quad8InputThreshold", i32 0}
!111 = !{!"UseResourceLoopUnrollNested", i1 false}
!112 = !{!"DisableLoopUnroll", i1 false}
!113 = !{!"ForcePushConstantMode", i32 0}
!114 = !{!"UseInstructionHoistingOptimization", i1 false}
!115 = !{!"DisableResourceLoopDestLifeTimeStart", i1 false}
!116 = !{!"ForceVRTGRFCeiling", i32 0}
!117 = !{!"EnableSamplerBackingByLSC", i32 0}
!118 = !{!"UseLinearScanRA", i1 false}
!119 = !{!"DisableConvertingAtomicIAddToIncDec", i1 false}
!120 = !{!"ZeroInitRegistersBeforeExecution", i1 false}
!121 = !{!"VISASpillAllowed", i32 0}
!122 = !{!"ConstantCoalescingMaxBBDepthDelta", i32 0}
!123 = !{!"ConstantCoalescingDepthCheckMinBytes", i32 0}
!124 = !{!"FuncMD", !125, !126}
!125 = !{!"FuncMDMap[0]", ptr @_ZTSZL12combine_pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_RK4MetaiiEUlNS0_2idILi1EEEE_}
!126 = !{!"FuncMDValue[0]", !127, !128, !132, !135, !136, !137, !138, !139, !207, !208, !209, !232, !282, !283, !284, !285, !286, !287, !288, !289, !290, !291, !292, !293, !294, !295, !296, !297, !298, !299, !300, !301, !302, !303, !304, !305, !306, !307, !308, !319, !330, !341, !352, !363, !374, !375}
!127 = !{!"localOffsets"}
!128 = !{!"workGroupWalkOrder", !129, !130, !131}
!129 = !{!"dim0", i32 0}
!130 = !{!"dim1", i32 1}
!131 = !{!"dim2", i32 2}
!132 = !{!"threadGroupSize", !129, !133, !134}
!133 = !{!"dim1", i32 0}
!134 = !{!"dim2", i32 0}
!135 = !{!"threadGroupSizeHint", !129, !133, !134}
!136 = !{!"vecTypeHint", !""}
!137 = !{!"funcArgs"}
!138 = !{!"argInfoList"}
!139 = !{!"implicitArgInfoList", !140, !146, !148, !150, !152, !154, !156, !158, !162, !164, !166, !168, !170, !172, !175, !178, !181, !183, !185, !187, !190, !192, !194, !196, !198, !200, !202, !203, !204, !205, !206}
!140 = !{!"implicitArgInfoListVec[0]", !141, !142, !143, !144, !145}
!141 = !{!"argId", i32 0}
!142 = !{!"explicitArgNum", i32 -1}
!143 = !{!"structArgOffset", i32 -1}
!144 = !{!"imgAccessFloatCoords", i32 -1}
!145 = !{!"imgAccessIntCoords", i32 -1}
!146 = !{!"implicitArgInfoListVec[1]", !147, !142, !143, !144, !145}
!147 = !{!"argId", i32 2}
!148 = !{!"implicitArgInfoListVec[2]", !149, !142, !143, !144, !145}
!149 = !{!"argId", i32 7}
!150 = !{!"implicitArgInfoListVec[3]", !151, !142, !143, !144, !145}
!151 = !{!"argId", i32 8}
!152 = !{!"implicitArgInfoListVec[4]", !153, !142, !143, !144, !145}
!153 = !{!"argId", i32 9}
!154 = !{!"implicitArgInfoListVec[5]", !155, !142, !143, !144, !145}
!155 = !{!"argId", i32 10}
!156 = !{!"implicitArgInfoListVec[6]", !157, !142, !143, !144, !145}
!157 = !{!"argId", i32 13}
!158 = !{!"implicitArgInfoListVec[7]", !159, !160, !161, !144, !145}
!159 = !{!"argId", i32 18}
!160 = !{!"explicitArgNum", i32 5}
!161 = !{!"structArgOffset", i32 0}
!162 = !{!"implicitArgInfoListVec[8]", !159, !160, !163, !144, !145}
!163 = !{!"structArgOffset", i32 4}
!164 = !{!"implicitArgInfoListVec[9]", !159, !160, !165, !144, !145}
!165 = !{!"structArgOffset", i32 8}
!166 = !{!"implicitArgInfoListVec[10]", !159, !160, !167, !144, !145}
!167 = !{!"structArgOffset", i32 12}
!168 = !{!"implicitArgInfoListVec[11]", !159, !160, !169, !144, !145}
!169 = !{!"structArgOffset", i32 16}
!170 = !{!"implicitArgInfoListVec[12]", !159, !160, !171, !144, !145}
!171 = !{!"structArgOffset", i32 20}
!172 = !{!"implicitArgInfoListVec[13]", !173, !160, !174, !144, !145}
!173 = !{!"argId", i32 17}
!174 = !{!"structArgOffset", i32 24}
!175 = !{!"implicitArgInfoListVec[14]", !176, !160, !177, !144, !145}
!176 = !{!"argId", i32 16}
!177 = !{!"structArgOffset", i32 32}
!178 = !{!"implicitArgInfoListVec[15]", !179, !160, !180, !144, !145}
!179 = !{!"argId", i32 20}
!180 = !{!"structArgOffset", i32 36}
!181 = !{!"implicitArgInfoListVec[16]", !179, !160, !182, !144, !145}
!182 = !{!"structArgOffset", i32 37}
!183 = !{!"implicitArgInfoListVec[17]", !179, !160, !184, !144, !145}
!184 = !{!"structArgOffset", i32 38}
!185 = !{!"implicitArgInfoListVec[18]", !179, !160, !186, !144, !145}
!186 = !{!"structArgOffset", i32 39}
!187 = !{!"implicitArgInfoListVec[19]", !188, !189, !143, !144, !145}
!188 = !{!"argId", i32 15}
!189 = !{!"explicitArgNum", i32 1}
!190 = !{!"implicitArgInfoListVec[20]", !188, !191, !143, !144, !145}
!191 = !{!"explicitArgNum", i32 2}
!192 = !{!"implicitArgInfoListVec[21]", !188, !193, !143, !144, !145}
!193 = !{!"explicitArgNum", i32 3}
!194 = !{!"implicitArgInfoListVec[22]", !188, !195, !143, !144, !145}
!195 = !{!"explicitArgNum", i32 4}
!196 = !{!"implicitArgInfoListVec[23]", !188, !197, !143, !144, !145}
!197 = !{!"explicitArgNum", i32 8}
!198 = !{!"implicitArgInfoListVec[24]", !188, !199, !143, !144, !145}
!199 = !{!"explicitArgNum", i32 9}
!200 = !{!"implicitArgInfoListVec[25]", !201, !189, !143, !144, !145}
!201 = !{!"argId", i32 54}
!202 = !{!"implicitArgInfoListVec[26]", !201, !191, !143, !144, !145}
!203 = !{!"implicitArgInfoListVec[27]", !201, !193, !143, !144, !145}
!204 = !{!"implicitArgInfoListVec[28]", !201, !195, !143, !144, !145}
!205 = !{!"implicitArgInfoListVec[29]", !201, !197, !143, !144, !145}
!206 = !{!"implicitArgInfoListVec[30]", !201, !199, !143, !144, !145}
!207 = !{!"functionType", !"KernelFunction"}
!208 = !{!"requiredSubGroupSize", i32 0}
!209 = !{!"rtInfo", !210, !211, !212, !213, !214, !215, !216, !217, !218, !219, !220, !221, !222, !223, !224, !225, !227, !228, !229, !230, !231}
!210 = !{!"callableShaderType", !"NumberOfCallableShaderTypes"}
!211 = !{!"isContinuation", i1 false}
!212 = !{!"hasTraceRayPayload", i1 false}
!213 = !{!"hasHitAttributes", i1 false}
!214 = !{!"hasCallableData", i1 false}
!215 = !{!"ShaderStackSize", i32 0}
!216 = !{!"ShaderHash", i64 0}
!217 = !{!"ShaderName", !""}
!218 = !{!"ParentName", !""}
!219 = !{!"SlotNum", ptr null}
!220 = !{!"NOSSize", i32 0}
!221 = !{!"globalRootSignatureSize", i32 0}
!222 = !{!"Entries"}
!223 = !{!"SpillUnions"}
!224 = !{!"CustomHitAttrSizeInBytes", i32 0}
!225 = !{!"Types", !226}
!226 = !{!"FullFrameTys"}
!227 = !{!"Aliases"}
!228 = !{!"numSyncRTStacks", i32 0}
!229 = !{!"NumCoherenceHintBits", i32 0}
!230 = !{!"useSyncHWStack", i1 false}
!231 = !{!"OriginatingShaderName", !""}
!232 = !{!"resAllocMD", !233, !234, !235, !236, !281}
!233 = !{!"uavsNumType", i32 0}
!234 = !{!"srvsNumType", i32 0}
!235 = !{!"samplersNumType", i32 0}
!236 = !{!"argAllocMDList", !237, !241, !242, !243, !244, !245, !246, !247, !248, !249, !250, !251, !252, !253, !254, !255, !256, !257, !258, !259, !260, !261, !262, !263, !264, !265, !266, !267, !268, !269, !270, !271, !272, !273, !274, !275, !276, !277, !278, !279, !280}
!237 = !{!"argAllocMDListVec[0]", !238, !239, !240}
!238 = !{!"type", i32 0}
!239 = !{!"extensionType", i32 -1}
!240 = !{!"indexType", i32 -1}
!241 = !{!"argAllocMDListVec[1]", !238, !239, !240}
!242 = !{!"argAllocMDListVec[2]", !238, !239, !240}
!243 = !{!"argAllocMDListVec[3]", !238, !239, !240}
!244 = !{!"argAllocMDListVec[4]", !238, !239, !240}
!245 = !{!"argAllocMDListVec[5]", !238, !239, !240}
!246 = !{!"argAllocMDListVec[6]", !238, !239, !240}
!247 = !{!"argAllocMDListVec[7]", !238, !239, !240}
!248 = !{!"argAllocMDListVec[8]", !238, !239, !240}
!249 = !{!"argAllocMDListVec[9]", !238, !239, !240}
!250 = !{!"argAllocMDListVec[10]", !238, !239, !240}
!251 = !{!"argAllocMDListVec[11]", !238, !239, !240}
!252 = !{!"argAllocMDListVec[12]", !238, !239, !240}
!253 = !{!"argAllocMDListVec[13]", !238, !239, !240}
!254 = !{!"argAllocMDListVec[14]", !238, !239, !240}
!255 = !{!"argAllocMDListVec[15]", !238, !239, !240}
!256 = !{!"argAllocMDListVec[16]", !238, !239, !240}
!257 = !{!"argAllocMDListVec[17]", !238, !239, !240}
!258 = !{!"argAllocMDListVec[18]", !238, !239, !240}
!259 = !{!"argAllocMDListVec[19]", !238, !239, !240}
!260 = !{!"argAllocMDListVec[20]", !238, !239, !240}
!261 = !{!"argAllocMDListVec[21]", !238, !239, !240}
!262 = !{!"argAllocMDListVec[22]", !238, !239, !240}
!263 = !{!"argAllocMDListVec[23]", !238, !239, !240}
!264 = !{!"argAllocMDListVec[24]", !238, !239, !240}
!265 = !{!"argAllocMDListVec[25]", !238, !239, !240}
!266 = !{!"argAllocMDListVec[26]", !238, !239, !240}
!267 = !{!"argAllocMDListVec[27]", !238, !239, !240}
!268 = !{!"argAllocMDListVec[28]", !238, !239, !240}
!269 = !{!"argAllocMDListVec[29]", !238, !239, !240}
!270 = !{!"argAllocMDListVec[30]", !238, !239, !240}
!271 = !{!"argAllocMDListVec[31]", !238, !239, !240}
!272 = !{!"argAllocMDListVec[32]", !238, !239, !240}
!273 = !{!"argAllocMDListVec[33]", !238, !239, !240}
!274 = !{!"argAllocMDListVec[34]", !238, !239, !240}
!275 = !{!"argAllocMDListVec[35]", !238, !239, !240}
!276 = !{!"argAllocMDListVec[36]", !238, !239, !240}
!277 = !{!"argAllocMDListVec[37]", !238, !239, !240}
!278 = !{!"argAllocMDListVec[38]", !238, !239, !240}
!279 = !{!"argAllocMDListVec[39]", !238, !239, !240}
!280 = !{!"argAllocMDListVec[40]", !238, !239, !240}
!281 = !{!"inlineSamplersMD"}
!282 = !{!"maxByteOffsets"}
!283 = !{!"IsInitializer", i1 false}
!284 = !{!"IsFinalizer", i1 false}
!285 = !{!"CompiledSubGroupsNumber", i32 0}
!286 = !{!"maxRegPressureSimd16", i32 18}
!287 = !{!"maxRegPressureSimd32", i32 34}
!288 = !{!"maxRegUniformPressure", i32 64}
!289 = !{!"maxRegNonUniformPressure", i32 65}
!290 = !{!"bestGuessSimd", i32 16}
!291 = !{!"hasInlineVmeSamplers", i1 false}
!292 = !{!"localSize", i32 0}
!293 = !{!"localIDPresent", i1 false}
!294 = !{!"groupIDPresent", i1 false}
!295 = !{!"privateMemoryPerWI", i32 0}
!296 = !{!"prevFPOffset", i32 0}
!297 = !{!"globalIDPresent", i1 false}
!298 = !{!"hasSyncRTCalls", i1 false}
!299 = !{!"hasPrintfCalls", i1 false}
!300 = !{!"hasDPAS", i1 false}
!301 = !{!"requireAssertBuffer", i1 false}
!302 = !{!"requireSyncBuffer", i1 false}
!303 = !{!"hasIndirectCalls", i1 false}
!304 = !{!"hasNonKernelArgLoad", i1 false}
!305 = !{!"hasNonKernelArgStore", i1 false}
!306 = !{!"hasNonKernelArgAtomic", i1 false}
!307 = !{!"UserAnnotations"}
!308 = !{!"m_OpenCLArgAddressSpaces", !309, !310, !311, !312, !313, !314, !315, !316, !317, !318}
!309 = !{!"m_OpenCLArgAddressSpacesVec[0]", i32 0}
!310 = !{!"m_OpenCLArgAddressSpacesVec[1]", i32 1}
!311 = !{!"m_OpenCLArgAddressSpacesVec[2]", i32 1}
!312 = !{!"m_OpenCLArgAddressSpacesVec[3]", i32 1}
!313 = !{!"m_OpenCLArgAddressSpacesVec[4]", i32 1}
!314 = !{!"m_OpenCLArgAddressSpacesVec[5]", i32 0}
!315 = !{!"m_OpenCLArgAddressSpacesVec[6]", i32 0}
!316 = !{!"m_OpenCLArgAddressSpacesVec[7]", i32 0}
!317 = !{!"m_OpenCLArgAddressSpacesVec[8]", i32 1}
!318 = !{!"m_OpenCLArgAddressSpacesVec[9]", i32 1}
!319 = !{!"m_OpenCLArgAccessQualifiers", !320, !321, !322, !323, !324, !325, !326, !327, !328, !329}
!320 = !{!"m_OpenCLArgAccessQualifiersVec[0]", !"none"}
!321 = !{!"m_OpenCLArgAccessQualifiersVec[1]", !"none"}
!322 = !{!"m_OpenCLArgAccessQualifiersVec[2]", !"none"}
!323 = !{!"m_OpenCLArgAccessQualifiersVec[3]", !"none"}
!324 = !{!"m_OpenCLArgAccessQualifiersVec[4]", !"none"}
!325 = !{!"m_OpenCLArgAccessQualifiersVec[5]", !"none"}
!326 = !{!"m_OpenCLArgAccessQualifiersVec[6]", !"none"}
!327 = !{!"m_OpenCLArgAccessQualifiersVec[7]", !"none"}
!328 = !{!"m_OpenCLArgAccessQualifiersVec[8]", !"none"}
!329 = !{!"m_OpenCLArgAccessQualifiersVec[9]", !"none"}
!330 = !{!"m_OpenCLArgTypes", !331, !332, !333, !334, !335, !336, !337, !338, !339, !340}
!331 = !{!"m_OpenCLArgTypesVec[0]", !"long"}
!332 = !{!"m_OpenCLArgTypesVec[1]", !"char*"}
!333 = !{!"m_OpenCLArgTypesVec[2]", !"char*"}
!334 = !{!"m_OpenCLArgTypesVec[3]", !"float*"}
!335 = !{!"m_OpenCLArgTypesVec[4]", !"float*"}
!336 = !{!"m_OpenCLArgTypesVec[5]", !"struct Meta"}
!337 = !{!"m_OpenCLArgTypesVec[6]", !"int"}
!338 = !{!"m_OpenCLArgTypesVec[7]", !"int"}
!339 = !{!"m_OpenCLArgTypesVec[8]", !"float*"}
!340 = !{!"m_OpenCLArgTypesVec[9]", !"int*"}
!341 = !{!"m_OpenCLArgBaseTypes", !342, !343, !344, !345, !346, !347, !348, !349, !350, !351}
!342 = !{!"m_OpenCLArgBaseTypesVec[0]", !"long"}
!343 = !{!"m_OpenCLArgBaseTypesVec[1]", !"char*"}
!344 = !{!"m_OpenCLArgBaseTypesVec[2]", !"char*"}
!345 = !{!"m_OpenCLArgBaseTypesVec[3]", !"float*"}
!346 = !{!"m_OpenCLArgBaseTypesVec[4]", !"float*"}
!347 = !{!"m_OpenCLArgBaseTypesVec[5]", !"struct Meta"}
!348 = !{!"m_OpenCLArgBaseTypesVec[6]", !"int"}
!349 = !{!"m_OpenCLArgBaseTypesVec[7]", !"int"}
!350 = !{!"m_OpenCLArgBaseTypesVec[8]", !"float*"}
!351 = !{!"m_OpenCLArgBaseTypesVec[9]", !"int*"}
!352 = !{!"m_OpenCLArgTypeQualifiers", !353, !354, !355, !356, !357, !358, !359, !360, !361, !362}
!353 = !{!"m_OpenCLArgTypeQualifiersVec[0]", !""}
!354 = !{!"m_OpenCLArgTypeQualifiersVec[1]", !""}
!355 = !{!"m_OpenCLArgTypeQualifiersVec[2]", !""}
!356 = !{!"m_OpenCLArgTypeQualifiersVec[3]", !""}
!357 = !{!"m_OpenCLArgTypeQualifiersVec[4]", !""}
!358 = !{!"m_OpenCLArgTypeQualifiersVec[5]", !""}
!359 = !{!"m_OpenCLArgTypeQualifiersVec[6]", !""}
!360 = !{!"m_OpenCLArgTypeQualifiersVec[7]", !""}
!361 = !{!"m_OpenCLArgTypeQualifiersVec[8]", !""}
!362 = !{!"m_OpenCLArgTypeQualifiersVec[9]", !""}
!363 = !{!"m_OpenCLArgNames", !364, !365, !366, !367, !368, !369, !370, !371, !372, !373}
!364 = !{!"m_OpenCLArgNamesVec[0]", !""}
!365 = !{!"m_OpenCLArgNamesVec[1]", !""}
!366 = !{!"m_OpenCLArgNamesVec[2]", !""}
!367 = !{!"m_OpenCLArgNamesVec[3]", !""}
!368 = !{!"m_OpenCLArgNamesVec[4]", !""}
!369 = !{!"m_OpenCLArgNamesVec[5]", !""}
!370 = !{!"m_OpenCLArgNamesVec[6]", !""}
!371 = !{!"m_OpenCLArgNamesVec[7]", !""}
!372 = !{!"m_OpenCLArgNamesVec[8]", !""}
!373 = !{!"m_OpenCLArgNamesVec[9]", !""}
!374 = !{!"m_OpenCLArgScalarAsPointers"}
!375 = !{!"m_OptsToDisablePerFunc", !376, !377, !378}
!376 = !{!"m_OptsToDisablePerFuncSet[0]", !"IGC-AddressArithmeticSinking"}
!377 = !{!"m_OptsToDisablePerFuncSet[1]", !"IGC-AllowSimd32Slicing"}
!378 = !{!"m_OptsToDisablePerFuncSet[2]", !"IGC-SinkLoadOpt"}
!379 = !{!"pushInfo", !380, !381, !382, !386, !387, !388, !389, !390, !391, !392, !393, !406, !407, !408, !409}
!380 = !{!"pushableAddresses"}
!381 = !{!"bindlessPushInfo"}
!382 = !{!"dynamicBufferInfo", !383, !384, !385}
!383 = !{!"firstIndex", i32 0}
!384 = !{!"numOffsets", i32 0}
!385 = !{!"forceDisabled", i1 false}
!386 = !{!"MaxNumberOfPushedBuffers", i32 0}
!387 = !{!"inlineConstantBufferSlot", i32 -1}
!388 = !{!"inlineConstantBufferOffset", i32 -1}
!389 = !{!"inlineConstantBufferGRFOffset", i32 -1}
!390 = !{!"constants"}
!391 = !{!"inputs"}
!392 = !{!"constantReg"}
!393 = !{!"simplePushInfoArr", !394, !403, !404, !405}
!394 = !{!"simplePushInfoArrVec[0]", !395, !396, !397, !398, !399, !400, !401, !402}
!395 = !{!"cbIdx", i32 0}
!396 = !{!"pushableAddressGrfOffset", i32 -1}
!397 = !{!"pushableOffsetGrfOffset", i32 -1}
!398 = !{!"offset", i32 0}
!399 = !{!"size", i32 0}
!400 = !{!"isStateless", i1 false}
!401 = !{!"isBindless", i1 false}
!402 = !{!"simplePushLoads"}
!403 = !{!"simplePushInfoArrVec[1]", !395, !396, !397, !398, !399, !400, !401, !402}
!404 = !{!"simplePushInfoArrVec[2]", !395, !396, !397, !398, !399, !400, !401, !402}
!405 = !{!"simplePushInfoArrVec[3]", !395, !396, !397, !398, !399, !400, !401, !402}
!406 = !{!"simplePushBufferUsed", i32 0}
!407 = !{!"pushAnalysisWIInfos"}
!408 = !{!"inlineRTGlobalPtrOffset", i32 0}
!409 = !{!"rtSyncSurfPtrOffset", i32 0}
!410 = !{!"psInfo", !411, !412, !413, !414, !415, !416, !417, !418, !419, !420, !421, !422, !423, !424, !425, !426}
!411 = !{!"BlendStateDisabledMask", i8 0}
!412 = !{!"SkipSrc0Alpha", i1 false}
!413 = !{!"DualSourceBlendingDisabled", i1 false}
!414 = !{!"ForceEnableSimd32", i1 false}
!415 = !{!"DisableSimd32WithDiscard", i1 false}
!416 = !{!"outputDepth", i1 false}
!417 = !{!"outputStencil", i1 false}
!418 = !{!"outputMask", i1 false}
!419 = !{!"blendToFillEnabled", i1 false}
!420 = !{!"forceEarlyZ", i1 false}
!421 = !{!"hasVersionedLoop", i1 false}
!422 = !{!"forceSingleSourceRTWAfterDualSourceRTW", i1 false}
!423 = !{!"blendOptimizationMode"}
!424 = !{!"colorOutputMask"}
!425 = !{!"isBlendEnabled"}
!426 = !{!"WaDisableVRS", i1 false}
!427 = !{!"csInfo", !428, !429, !430, !431, !48, !24, !25, !432, !26, !433, !434, !435, !436, !437, !438, !439, !440, !441, !442, !443, !59, !444, !445, !446, !447}
!428 = !{!"maxWorkGroupSize", i32 0}
!429 = !{!"waveSize", i32 0}
!430 = !{!"ComputeShaderSecondCompile"}
!431 = !{!"forcedSIMDSize", i8 0}
!432 = !{!"VISAPreSchedScheduleExtraGRF", i32 0}
!433 = !{!"forceSpillCompression", i1 false}
!434 = !{!"allowLowerSimd", i1 false}
!435 = !{!"disableSimd32Slicing", i1 false}
!436 = !{!"disableSplitOnSpill", i1 false}
!437 = !{!"enableNewSpillCostFunction", i1 false}
!438 = !{!"forceVISAPreSched", i1 false}
!439 = !{!"disableLocalIdOrderOptimizations", i1 false}
!440 = !{!"disableDispatchAlongY", i1 false}
!441 = !{!"neededThreadIdLayout", ptr null}
!442 = !{!"forceTileYWalk", i1 false}
!443 = !{!"atomicBranch", i32 0}
!444 = !{!"disableEarlyOut", i1 false}
!445 = !{!"walkOrderEnabled", i1 false}
!446 = !{!"walkOrderOverride", i32 0}
!447 = !{!"ResForHfPacking"}
!448 = !{!"msInfo", !449, !450, !451, !452, !453, !454, !455, !456, !457}
!449 = !{!"PrimitiveTopology", i32 3}
!450 = !{!"MaxNumOfPrimitives", i32 0}
!451 = !{!"MaxNumOfVertices", i32 0}
!452 = !{!"MaxNumOfPerPrimitiveOutputs", i32 0}
!453 = !{!"MaxNumOfPerVertexOutputs", i32 0}
!454 = !{!"WorkGroupSize", i32 0}
!455 = !{!"WorkGroupMemorySizeInBytes", i32 0}
!456 = !{!"IndexFormat", i32 6}
!457 = !{!"SubgroupSize", i32 0}
!458 = !{!"taskInfo", !459, !454, !455, !457}
!459 = !{!"MaxNumOfOutputs", i32 0}
!460 = !{!"NBarrierCnt", i32 0}
!461 = !{!"rtInfo", !462, !463, !464, !465, !466, !467, !468, !469, !470, !471, !472, !473, !474, !475, !228}
!462 = !{!"RayQueryAllocSizeInBytes", i32 0}
!463 = !{!"NumContinuations", i32 0}
!464 = !{!"RTAsyncStackAddrspace", i32 -1}
!465 = !{!"RTAsyncStackSurfaceStateOffset", ptr null}
!466 = !{!"SWHotZoneAddrspace", i32 -1}
!467 = !{!"SWHotZoneSurfaceStateOffset", ptr null}
!468 = !{!"SWStackAddrspace", i32 -1}
!469 = !{!"SWStackSurfaceStateOffset", ptr null}
!470 = !{!"RTSyncStackAddrspace", i32 -1}
!471 = !{!"RTSyncStackSurfaceStateOffset", ptr null}
!472 = !{!"doSyncDispatchRays", i1 false}
!473 = !{!"MemStyle", !"Xe"}
!474 = !{!"GlobalDataStyle", !"Xe"}
!475 = !{!"uberTileDimensions", ptr null}
!476 = !{!"hasSliceLayoutDependency", i1 false}
!477 = !{!"CurUniqueIndirectIdx", i32 0}
!478 = !{!"inlineDynTextures"}
!479 = !{!"inlineResInfoData"}
!480 = !{!"immConstant", !481, !482, !483}
!481 = !{!"data"}
!482 = !{!"sizes"}
!483 = !{!"zeroIdxs"}
!484 = !{!"stringConstants"}
!485 = !{!"inlineBuffers", !486, !490, !491}
!486 = !{!"inlineBuffersVec[0]", !487, !488, !489}
!487 = !{!"alignment", i32 0}
!488 = !{!"allocSize", i64 0}
!489 = !{!"Buffer"}
!490 = !{!"inlineBuffersVec[1]", !487, !488, !489}
!491 = !{!"inlineBuffersVec[2]", !487, !488, !489}
!492 = !{!"GlobalBufferAddressRelocInfo"}
!493 = !{!"ConstantBufferAddressRelocInfo"}
!494 = !{!"forceLscCacheList"}
!495 = !{!"SrvMap"}
!496 = !{!"RasterizerOrderedByteAddressBuffer"}
!497 = !{!"RasterizerOrderedViews"}
!498 = !{!"MinNOSPushConstantSize", i32 0}
!499 = !{!"inlineProgramScopeOffsets"}
!500 = !{!"shaderData", !501}
!501 = !{!"numReplicas", i32 0}
!502 = !{!"URBInfo", !503, !504, !505}
!503 = !{!"has64BVertexHeaderInput", i1 false}
!504 = !{!"has64BVertexHeaderOutput", i1 false}
!505 = !{!"hasVertexHeader", i1 true}
!506 = !{!"UseBindlessImage", i1 true}
!507 = !{!"HasBindlessImageRead", i1 false}
!508 = !{!"UseBindlessImageWithSamplerTracking", i1 false}
!509 = !{!"enableRangeReduce", i1 false}
!510 = !{!"allowMatchMadOptimizationforPosition", i1 false}
!511 = !{!"disableMatchMadOptimizationForCS", i1 false}
!512 = !{!"disableMemOptforNegativeOffsetLoads", i1 false}
!513 = !{!"enableThreeWayLoadSpiltOpt", i1 false}
!514 = !{!"statefulResourcesNotAliased", i1 false}
!515 = !{!"disableMixMode", i1 false}
!516 = !{!"genericAccessesResolved", i1 false}
!517 = !{!"disableSeparateSpillPvtScratchSpace", i1 false}
!518 = !{!"enableSeparateSpillPvtScratchSpace", i1 false}
!519 = !{!"disableSeparateScratchWA", i1 false}
!520 = !{!"enableRemoveUnusedTGMFence", i1 false}
!521 = !{!"PrivateMemoryPerFG", !522, !523}
!522 = !{!"PrivateMemoryPerFGMap[0]", ptr @_ZTSZL12combine_pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_RK4MetaiiEUlNS0_2idILi1EEEE_}
!523 = !{!"PrivateMemoryPerFGValue[0]", i32 0}
!524 = !{!"m_OptsToDisable"}
!525 = !{!"capabilities", !526}
!526 = !{!"globalVariableDecorationsINTEL", i1 false}
!527 = !{!"extensions", !528}
!528 = !{!"spvINTELBindlessImages", i1 false}
!529 = !{!"m_ShaderResourceViewMcsMask", !530, !531}
!530 = !{!"m_ShaderResourceViewMcsMaskVec[0]", i64 0}
!531 = !{!"m_ShaderResourceViewMcsMaskVec[1]", i64 0}
!532 = !{!"computedDepthMode", i32 0}
!533 = !{!"isHDCFastClearShader", i1 false}
!534 = !{!"argRegisterReservations", !535}
!535 = !{!"argRegisterReservationsVec[0]", i32 0}
!536 = !{!"SIMD16_SpillThreshold", i8 0}
!537 = !{!"SIMD32_SpillThreshold", i8 0}
!538 = !{!"m_CacheControlOption", !539, !540, !541, !542}
!539 = !{!"LscLoadCacheControlOverride", i8 0}
!540 = !{!"LscStoreCacheControlOverride", i8 0}
!541 = !{!"TgmLoadCacheControlOverride", i8 0}
!542 = !{!"TgmStoreCacheControlOverride", i8 0}
!543 = !{!"ModuleUsesBindless", i1 false}
!544 = !{!"predicationMap"}
!545 = !{!"lifeTimeStartMap"}
!546 = !{!"HitGroups"}
!547 = !{i32 2, i32 0}
!548 = !{!"clang version 22.1.8 (Fedora 22.1.8-4.fc44)"}
!549 = !{!"clang version 9.0.0 (2dbee6917918354f14026a637370445d50bdaf6a)"}
!550 = !{!"clang version 9.0.0 (c68f557a081b1b2339a42d7cd6af3c2ab18c6061)"}
!551 = !{!552, !552, i64 0}
!552 = !{!"int", !553, i64 0}
!553 = !{!"omnipotent char", !554, i64 0}
!554 = !{!"Simple C/C++ TBAA"}
!555 = !{i32 1, !"wchar_size", i32 4}
!556 = !{!557}
!557 = !{i32 4469}
!558 = !{!"163840"}
!559 = !{!"-14"}
!560 = !{!"11529215046068456960"}
!561 = !{!"-61"}
!562 = !{!"11529215046068431360"}
!563 = !{!"-62"}
!564 = !{float 2.500000e+00}
!565 = !{!"17293822569102647040"}
!566 = !{!"-63"}
!567 = !{!"14411518807585590400"}
!568 = !{!"17293822569102698240"}
!569 = !{!557, !570}
!570 = !{i32 4470}
!571 = !{!"-56"}
!572 = !{!"13961158844848540700"}
!573 = !{!574}
!574 = !{i32 40, i32 196620}
!575 = !{!576}
!576 = !{i32 40, i32 196621}

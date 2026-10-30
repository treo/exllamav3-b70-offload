; ------------------------------------------------
; OCL_asm10ec49003a6449c0_push_analysis.ll
; ------------------------------------------------
target datalayout = "e-p:64:64:64-i1:8:8-i8:8:8-i16:16:16-i32:32:32-i64:64:64-f32:32:32-f64:64:64-v16:16:16-v24:32:32-v32:32:32-v48:64:64-v64:64:64-v96:128:128-v128:128:128-v192:256:256-v256:256:256-v512:512:512-v1024:1024:1024-n8:16:32"
target triple = "spir64-unknown-unknown"

%struct.Meta = type <{ i32, i32, i32, i32, i32, i32, double, float, [4 x i8] }>

; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSZL7combineRN4sycl3_V15queueEPKiPKfS4_PfRK4MetaiiEUlNS0_2idILi1EEEE_(ptr byval(%struct.Meta) align 8 %0, i32 %1, ptr addrspace(1) align 4 %2, i32 %3, ptr addrspace(1) align 4 %4, ptr addrspace(1) align 4 %5, ptr addrspace(1) align 4 %6, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i32 %const_reg_dword, i32 %const_reg_dword1, i32 %const_reg_dword2, i32 %const_reg_dword3, i32 %const_reg_dword4, i32 %const_reg_dword5, i64 %const_reg_qword, float %const_reg_fp32, i8 %const_reg_byte, i8 %const_reg_byte6, i8 %const_reg_byte7, i8 %const_reg_byte8, i32 %bufferOffset, i32 %bufferOffset9, i32 %bufferOffset10, i32 %bufferOffset11, i32 %bindlessOffset, i32 %bindlessOffset12, i32 %bindlessOffset13, i32 %bindlessOffset14) #0 {
  %8 = extractelement <3 x i32> %globalOffset, i32 0
  %9 = extractelement <3 x i32> %enqueuedLocalSize, i32 0
  %10 = extractelement <8 x i32> %r0, i32 1
  %11 = mul i32 %9, %10
  %12 = zext i16 %localIdX to i32
  %13 = add i32 %11, %12
  %14 = add i32 %13, %8
  %15 = zext nneg i32 %14 to i64
  %16 = sext i32 %const_reg_dword1 to i64
  %17 = ashr i32 %const_reg_dword1, 31
  %18 = sext i32 %const_reg_dword5 to i64
  %19 = ashr i32 %const_reg_dword5, 31
  %20 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %const_reg_dword1, i32 %17, i32 %const_reg_dword5, i32 %19)
  %21 = extractvalue { i32, i32 } %20, 0
  %22 = extractvalue { i32, i32 } %20, 1
  %23 = insertelement <2 x i32> undef, i32 %21, i32 0
  %24 = insertelement <2 x i32> %23, i32 %22, i32 1
  %25 = bitcast <2 x i32> %24 to i64
  %26 = icmp ult i32 %22, 1
  br i1 %26, label %27, label %46

27:                                               ; preds = %7
  %28 = trunc nuw i64 %25 to i32
  %29 = icmp eq i32 %21, 0
  br i1 %29, label %.precompiled_u32divrem_sp.exit84_crit_edge, label %if.end.i63

.precompiled_u32divrem_sp.exit84_crit_edge:       ; preds = %27
  br label %precompiled_u32divrem_sp.exit84

if.end.i63:                                       ; preds = %27
  %30 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %28)
  %conv.i64 = fptoui float %30 to i32
  %sub.i65 = sub i32 %28, %conv.i64
  %31 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i65)
  %32 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %14)
  %conv3.i66 = fptoui float %32 to i32
  %sub4.i67 = sub i32 %14, %conv3.i66
  %33 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i67)
  %div.i68 = fdiv float 1.000000e+00, %30, !fpmath !525
  %34 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i68, float 0xBE98000000000000, float %div.i68)
  %35 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %32, float %34)
  %conv8.i69 = fptoui float %35 to i32
  %36 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i69)
  %37 = fsub float 0.000000e+00, %30
  %38 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %37, float %36, float %32)
  %39 = fsub float 0.000000e+00, %31
  %40 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %39, float %36, float %33)
  %41 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %38, float %40)
  %42 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %34, float %41)
  %conv16.i72 = fptoui float %42 to i32
  %add.i73 = add i32 %conv16.i72, %conv8.i69
  %mul.i74 = mul i32 %add.i73, %28
  %sub17.i75 = sub i32 %14, %mul.i74
  %cmp.i76 = icmp uge i32 %sub17.i75, %28
  %43 = sext i1 %cmp.i76 to i32
  %44 = sub i32 0, %43
  %add19.i79 = add i32 %add.i73, %44
  br label %precompiled_u32divrem_sp.exit84

precompiled_u32divrem_sp.exit84:                  ; preds = %.precompiled_u32divrem_sp.exit84_crit_edge, %if.end.i63
  %retval.0.i83 = phi i32 [ %add19.i79, %if.end.i63 ], [ -1, %.precompiled_u32divrem_sp.exit84_crit_edge ]
  %45 = zext i32 %retval.0.i83 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit

46:                                               ; preds = %7
  %47 = trunc i64 %25 to i32
  %48 = uitofp i64 %25 to double
  %49 = fptrunc double %48 to float
  %50 = fdiv float 1.000000e+00, %49
  %51 = fpext float %50 to double
  %52 = fsub double 0.000000e+00, %48
  %53 = call double @llvm.fma.f64(double %52, double %51, double 1.000000e+00) #4
  %54 = fadd double %53, 0xBCF0000000000000
  %55 = call double @llvm.fma.f64(double %51, double %54, double %51) #4
  %56 = uitofp nneg i32 %14 to double
  %57 = fmul double %55, %56
  %58 = fptoui double %57 to i64
  %59 = bitcast i64 %58 to <2 x i32>
  %60 = extractelement <2 x i32> %59, i32 0
  %61 = extractelement <2 x i32> %59, i32 1
  %62 = trunc i64 %58 to i32
  %63 = icmp ult i32 %61, 1
  %64 = mul i32 %62, %22
  %65 = select i1 %63, i32 0, i32 %47
  %66 = add i32 %64, %65
  %67 = sub i32 0, %66
  %68 = insertelement <2 x i32> undef, i32 %14, i32 0
  %69 = insertelement <2 x i32> %68, i32 %67, i32 1
  %70 = bitcast <2 x i32> %69 to i64
  %71 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %60, i32 0, i32 %21, i32 0)
  %72 = extractvalue { i32, i32 } %71, 0
  %73 = extractvalue { i32, i32 } %71, 1
  %74 = insertelement <2 x i32> undef, i32 %72, i32 0
  %75 = insertelement <2 x i32> %74, i32 %73, i32 1
  %76 = bitcast <2 x i32> %75 to i64
  %77 = sub i64 %70, %76
  %78 = bitcast i64 %77 to <2 x i32>
  %79 = extractelement <2 x i32> %78, i32 0
  %80 = extractelement <2 x i32> %78, i32 1
  %81 = icmp uge i32 %79, %21
  %82 = icmp eq i32 %80, %22
  %83 = and i1 %82, %81
  %84 = icmp ugt i32 %80, %22
  %85 = or i1 %83, %84
  %86 = sext i1 %85 to i64
  %87 = sub i64 0, %86
  %88 = add i64 %58, %87
  br label %__igcbuiltin_u64_udiv_dp.exit

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit84, %46
  %89 = phi i64 [ %45, %precompiled_u32divrem_sp.exit84 ], [ %88, %46 ]
  %90 = icmp sgt i32 %const_reg_dword5, -1
  br i1 %90, label %91, label %108

91:                                               ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %tobool.i39 = icmp eq i32 %const_reg_dword5, 0
  br i1 %tobool.i39, label %.precompiled_u32divrem_sp.exit61_crit_edge, label %if.end.i40

.precompiled_u32divrem_sp.exit61_crit_edge:       ; preds = %91
  br label %precompiled_u32divrem_sp.exit61

if.end.i40:                                       ; preds = %91
  %92 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword5)
  %conv.i41 = fptoui float %92 to i32
  %sub.i42 = sub i32 %const_reg_dword5, %conv.i41
  %93 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i42)
  %94 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %14)
  %conv3.i43 = fptoui float %94 to i32
  %sub4.i44 = sub i32 %14, %conv3.i43
  %95 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i44)
  %div.i45 = fdiv float 1.000000e+00, %92, !fpmath !525
  %96 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i45, float 0xBE98000000000000, float %div.i45)
  %97 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %94, float %96)
  %conv8.i46 = fptoui float %97 to i32
  %98 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i46)
  %99 = fsub float 0.000000e+00, %92
  %100 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %99, float %98, float %94)
  %101 = fsub float 0.000000e+00, %93
  %102 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %101, float %98, float %95)
  %103 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %100, float %102)
  %104 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %96, float %103)
  %conv16.i49 = fptoui float %104 to i32
  %add.i50 = add i32 %conv16.i49, %conv8.i46
  %mul.i51 = mul i32 %add.i50, %const_reg_dword5
  %sub17.i52 = sub i32 %14, %mul.i51
  %cmp.i53 = icmp uge i32 %sub17.i52, %const_reg_dword5
  %105 = sext i1 %cmp.i53 to i32
  %106 = sub i32 0, %105
  %add19.i56 = add i32 %add.i50, %106
  br label %precompiled_u32divrem_sp.exit61

precompiled_u32divrem_sp.exit61:                  ; preds = %.precompiled_u32divrem_sp.exit61_crit_edge, %if.end.i40
  %retval.0.i60 = phi i32 [ %add19.i56, %if.end.i40 ], [ -1, %.precompiled_u32divrem_sp.exit61_crit_edge ]
  %107 = zext i32 %retval.0.i60 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit37

108:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %109 = uitofp i64 %18 to double
  %110 = fptrunc double %109 to float
  %111 = fdiv float 1.000000e+00, %110
  %112 = fpext float %111 to double
  %113 = fsub double 0.000000e+00, %109
  %114 = call double @llvm.fma.f64(double %113, double %112, double 1.000000e+00) #4
  %115 = fadd double %114, 0xBCF0000000000000
  %116 = call double @llvm.fma.f64(double %112, double %115, double %112) #4
  %117 = uitofp nneg i32 %14 to double
  %118 = fmul double %116, %117
  %119 = fptoui double %118 to i64
  %120 = bitcast i64 %119 to <2 x i32>
  %121 = extractelement <2 x i32> %120, i32 0
  %122 = extractelement <2 x i32> %120, i32 1
  %123 = trunc i64 %119 to i32
  %124 = icmp ult i32 %122, 1
  %125 = select i1 %124, i32 0, i32 %const_reg_dword5
  %126 = sub i32 %123, %125
  %127 = insertelement <2 x i32> undef, i32 %14, i32 0
  %128 = insertelement <2 x i32> %127, i32 %126, i32 1
  %129 = bitcast <2 x i32> %128 to i64
  %130 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %121, i32 0, i32 %const_reg_dword5, i32 0)
  %131 = extractvalue { i32, i32 } %130, 0
  %132 = extractvalue { i32, i32 } %130, 1
  %133 = insertelement <2 x i32> undef, i32 %131, i32 0
  %134 = insertelement <2 x i32> %133, i32 %132, i32 1
  %135 = bitcast <2 x i32> %134 to i64
  %136 = sub i64 %129, %135
  %137 = bitcast i64 %136 to <2 x i32>
  %138 = extractelement <2 x i32> %137, i32 0
  %139 = extractelement <2 x i32> %137, i32 1
  %140 = icmp uge i32 %138, %const_reg_dword5
  %141 = icmp eq i32 %139, %19
  %142 = and i1 %141, %140
  %143 = icmp ugt i32 %139, %19
  %144 = or i1 %142, %143
  %145 = sext i1 %144 to i64
  %146 = sub i64 0, %145
  %147 = add i64 %119, %146
  br label %__igcbuiltin_u64_udiv_dp.exit37

__igcbuiltin_u64_udiv_dp.exit37:                  ; preds = %precompiled_u32divrem_sp.exit61, %108
  %148 = phi i64 [ %107, %precompiled_u32divrem_sp.exit61 ], [ %147, %108 ]
  %149 = bitcast i64 %148 to <2 x i32>
  %150 = extractelement <2 x i32> %149, i32 0
  %151 = extractelement <2 x i32> %149, i32 1
  %152 = or i32 %151, %17
  %153 = icmp ult i32 %152, 1
  br i1 %153, label %154, label %170

154:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit37
  %155 = trunc nuw i64 %148 to i32
  %tobool.i = icmp eq i32 %const_reg_dword1, 0
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %154
  br label %precompiled_u32divrem_sp.exit

if.end.i:                                         ; preds = %154
  %156 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword1)
  %conv.i = fptoui float %156 to i32
  %sub.i = sub i32 %const_reg_dword1, %conv.i
  %157 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %158 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %155)
  %conv3.i = fptoui float %158 to i32
  %sub4.i = sub i32 %155, %conv3.i
  %159 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %div.i = fdiv float 1.000000e+00, %156, !fpmath !525
  %160 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %161 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %158, float %160)
  %conv8.i = fptoui float %161 to i32
  %162 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %163 = fsub float 0.000000e+00, %156
  %164 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %163, float %162, float %158)
  %165 = fsub float 0.000000e+00, %157
  %166 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %165, float %162, float %159)
  %167 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %164, float %166)
  %168 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %160, float %167)
  %conv16.i = fptoui float %168 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %const_reg_dword1
  %sub17.i = sub i32 %155, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword1
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword1
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %169 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit

170:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit37
  %171 = uitofp i64 %16 to double
  %172 = fptrunc double %171 to float
  %173 = fdiv float 1.000000e+00, %172
  %174 = fpext float %173 to double
  %175 = fsub double 0.000000e+00, %171
  %176 = call double @llvm.fma.f64(double %175, double %174, double 1.000000e+00) #4
  %177 = fadd double %176, 0xBCF0000000000000
  %178 = call double @llvm.fma.f64(double %174, double %177, double %174) #4
  %179 = bitcast i64 %148 to <2 x i32>
  %180 = extractelement <2 x i32> %179, i32 1
  %181 = uitofp i32 %180 to double
  %182 = fmul double %178, %181
  %183 = fptoui double %182 to i32
  %184 = mul i32 %const_reg_dword1, %183
  %185 = sub i32 %180, %184
  %186 = uitofp i32 %185 to double
  %187 = trunc i64 %148 to i32
  %188 = uitofp i32 %187 to double
  %189 = call double @llvm.fma.f64(double %186, double 0x41F0000000000000, double %188) #4
  %190 = fmul double %178, %189
  %191 = fptoui double %190 to i64
  %192 = bitcast i64 %191 to <2 x i32>
  %193 = extractelement <2 x i32> %192, i32 0
  %194 = extractelement <2 x i32> %192, i32 1
  %195 = trunc i64 %191 to i32
  %196 = icmp ult i32 %194, 1
  %isneg = icmp slt i32 %const_reg_dword1, 0
  %.neg86 = select i1 %isneg, i32 %195, i32 0
  %197 = select i1 %196, i32 0, i32 %const_reg_dword1
  %198 = sub i32 %185, %197
  %199 = add i32 %.neg86, %198
  %200 = insertelement <2 x i32> undef, i32 %150, i32 0
  %201 = insertelement <2 x i32> %200, i32 %199, i32 1
  %202 = bitcast <2 x i32> %201 to i64
  %203 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %193, i32 0, i32 %const_reg_dword1, i32 0)
  %204 = extractvalue { i32, i32 } %203, 0
  %205 = extractvalue { i32, i32 } %203, 1
  %206 = insertelement <2 x i32> undef, i32 %204, i32 0
  %207 = insertelement <2 x i32> %206, i32 %205, i32 1
  %208 = bitcast <2 x i32> %207 to i64
  %209 = sub i64 %202, %208
  %210 = bitcast i64 %209 to <2 x i32>
  %211 = extractelement <2 x i32> %210, i32 0
  %212 = extractelement <2 x i32> %210, i32 1
  %213 = icmp ult i32 %211, %const_reg_dword1
  %214 = icmp eq i32 %212, %17
  %215 = and i1 %214, %213
  %216 = icmp ult i32 %212, %17
  %217 = or i1 %215, %216
  %218 = select i1 %217, i32 0, i32 %const_reg_dword1
  %219 = select i1 %217, i32 0, i32 %17
  %220 = insertelement <2 x i32> undef, i32 %218, i32 0
  %221 = insertelement <2 x i32> %220, i32 %219, i32 1
  %222 = bitcast <2 x i32> %221 to i64
  %223 = sub i64 %209, %222
  br label %__igcbuiltin_u64_urem_dp.exit

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %170
  %224 = phi i64 [ %169, %precompiled_u32divrem_sp.exit ], [ %223, %170 ]
  %225 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %150, i32 %151, i32 %const_reg_dword5, i32 %19)
  %226 = extractvalue { i32, i32 } %225, 0
  %227 = extractvalue { i32, i32 } %225, 1
  %228 = insertelement <2 x i32> undef, i32 %226, i32 0
  %229 = insertelement <2 x i32> %228, i32 %227, i32 1
  %230 = bitcast <2 x i32> %229 to i64
  %231 = sub nsw i64 %15, %230
  %232 = shl nsw i32 %1, 1, !spirv.Decorations !526
  %233 = ashr i32 %const_reg_dword, 31
  %234 = ashr i32 %3, 31
  %235 = ptrtoint ptr addrspace(1) %2 to i64
  %236 = icmp sgt i32 %1, 0
  br i1 %236, label %.lr.ph.preheader, label %__igcbuiltin_u64_urem_dp.exit._crit_edge

__igcbuiltin_u64_urem_dp.exit._crit_edge:         ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %274

.lr.ph.preheader:                                 ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %.lr.ph

.lr.ph:                                           ; preds = %.lr.ph..lr.ph_crit_edge, %.lr.ph.preheader
  %237 = phi i32 [ %271, %.lr.ph..lr.ph_crit_edge ], [ 0, %.lr.ph.preheader ]
  %238 = phi i32 [ %270, %.lr.ph..lr.ph_crit_edge ], [ 0, %.lr.ph.preheader ]
  %239 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %237, i32 0, i32 %const_reg_dword, i32 %233)
  %240 = extractvalue { i32, i32 } %239, 0
  %241 = extractvalue { i32, i32 } %239, 1
  %242 = insertelement <2 x i32> undef, i32 %240, i32 0
  %243 = insertelement <2 x i32> %242, i32 %241, i32 1
  %244 = bitcast <2 x i32> %243 to i64
  %245 = add nsw i64 %244, %89, !spirv.Decorations !526
  %246 = bitcast i64 %245 to <2 x i32>
  %247 = extractelement <2 x i32> %246, i32 0
  %248 = extractelement <2 x i32> %246, i32 1
  %249 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %247, i32 %248, i32 %3, i32 %234)
  %250 = extractvalue { i32, i32 } %249, 0
  %251 = extractvalue { i32, i32 } %249, 1
  %252 = insertelement <2 x i32> undef, i32 %250, i32 0
  %253 = insertelement <2 x i32> %252, i32 %251, i32 1
  %254 = bitcast <2 x i32> %253 to i64
  %255 = add i64 %254, %224
  %256 = bitcast i64 %255 to <2 x i32>
  %257 = extractelement <2 x i32> %256, i32 0
  %258 = extractelement <2 x i32> %256, i32 1
  %259 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %257, i32 %258, i32 %const_reg_dword5, i32 %19)
  %260 = extractvalue { i32, i32 } %259, 0
  %261 = extractvalue { i32, i32 } %259, 1
  %262 = insertelement <2 x i32> undef, i32 %260, i32 0
  %263 = insertelement <2 x i32> %262, i32 %261, i32 1
  %264 = bitcast <2 x i32> %263 to i64
  %265 = add i64 %231, %264
  %266 = shl i64 %265, 2
  %267 = add i64 %266, %235
  %268 = inttoptr i64 %267 to ptr addrspace(1)
  %269 = load i32, ptr addrspace(1) %268, align 4
  %270 = add nsw i32 %238, %269, !spirv.Decorations !526
  %271 = add nuw nsw i32 %237, 1, !spirv.Decorations !528
  %272 = icmp slt i32 %271, %232
  br i1 %272, label %.lr.ph..lr.ph_crit_edge, label %._crit_edge

.lr.ph..lr.ph_crit_edge:                          ; preds = %.lr.ph
  br label %.lr.ph

._crit_edge:                                      ; preds = %.lr.ph
  %273 = sitofp i32 %270 to float
  br label %274

274:                                              ; preds = %__igcbuiltin_u64_urem_dp.exit._crit_edge, %._crit_edge
  %.lcssa = phi float [ %273, %._crit_edge ], [ 0.000000e+00, %__igcbuiltin_u64_urem_dp.exit._crit_edge ]
  %275 = ptrtoint ptr addrspace(1) %5 to i64
  %276 = shl i64 %224, 2
  %277 = add i64 %276, %275
  %278 = inttoptr i64 %277 to ptr addrspace(1)
  %279 = load float, ptr addrspace(1) %278, align 4
  %280 = fmul reassoc nsz arcp contract float %const_reg_fp32, %279, !spirv.Decorations !530
  %281 = ptrtoint ptr addrspace(1) %6 to i64
  %282 = add i64 %276, %281
  %283 = inttoptr i64 %282 to ptr addrspace(1)
  %284 = load i32, ptr addrspace(1) %283, align 4
  %285 = sitofp i32 %284 to float
  %286 = fmul reassoc nnan nsz arcp contract float %285, 5.100000e+02, !spirv.Decorations !532
  %287 = fsub reassoc nnan nsz arcp contract float %.lcssa, %286, !spirv.Decorations !532
  %288 = fmul reassoc nsz arcp contract float %280, %287, !spirv.Decorations !530
  %289 = ptrtoint ptr addrspace(1) %4 to i64
  %290 = shl nuw nsw i64 %15, 2
  %291 = add i64 %290, %289
  %292 = inttoptr i64 %291 to ptr addrspace(1)
  store float %288, ptr addrspace(1) %292, align 4
  ret void
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
!opencl.ocl.version = !{!516}
!opencl.spir.version = !{!516}
!llvm.ident = !{!517, !518, !519}
!llvm.errno.tbaa = !{!520}
!llvm.module.flags = !{!524}

!0 = !{i32 2, i32 2}
!1 = !{i32 0, i32 100000}
!2 = !{i16 6, i16 14}
!3 = !{ptr @_ZTSZL7combineRN4sycl3_V15queueEPKiPKfS4_PfRK4MetaiiEUlNS0_2idILi1EEEE_, !4}
!4 = !{!5}
!5 = !{!"function_type", i32 0}
!6 = !{!"ModuleMD", !7, !8, !124, !348, !379, !396, !417, !427, !429, !430, !445, !446, !447, !448, !449, !453, !454, !461, !462, !463, !464, !465, !466, !467, !468, !469, !471, !475, !476, !477, !478, !479, !480, !481, !482, !483, !484, !485, !486, !487, !488, !489, !282, !490, !493, !494, !496, !498, !501, !502, !503, !505, !506, !507, !512, !513, !514, !515}
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
!125 = !{!"FuncMDMap[0]", ptr @_ZTSZL7combineRN4sycl3_V15queueEPKiPKfS4_PfRK4MetaiiEUlNS0_2idILi1EEEE_}
!126 = !{!"FuncMDValue[0]", !127, !128, !132, !135, !136, !137, !138, !139, !201, !202, !203, !226, !269, !270, !271, !272, !273, !274, !275, !276, !277, !278, !279, !280, !281, !282, !283, !284, !285, !286, !287, !288, !289, !290, !291, !292, !293, !294, !295, !303, !311, !319, !327, !335, !343, !344}
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
!139 = !{!"implicitArgInfoList", !140, !146, !148, !150, !152, !154, !156, !158, !162, !164, !166, !168, !170, !172, !175, !178, !181, !183, !185, !187, !190, !192, !194, !196, !198, !199, !200}
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
!160 = !{!"explicitArgNum", i32 0}
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
!189 = !{!"explicitArgNum", i32 2}
!190 = !{!"implicitArgInfoListVec[20]", !188, !191, !143, !144, !145}
!191 = !{!"explicitArgNum", i32 4}
!192 = !{!"implicitArgInfoListVec[21]", !188, !193, !143, !144, !145}
!193 = !{!"explicitArgNum", i32 5}
!194 = !{!"implicitArgInfoListVec[22]", !188, !195, !143, !144, !145}
!195 = !{!"explicitArgNum", i32 6}
!196 = !{!"implicitArgInfoListVec[23]", !197, !189, !143, !144, !145}
!197 = !{!"argId", i32 54}
!198 = !{!"implicitArgInfoListVec[24]", !197, !191, !143, !144, !145}
!199 = !{!"implicitArgInfoListVec[25]", !197, !193, !143, !144, !145}
!200 = !{!"implicitArgInfoListVec[26]", !197, !195, !143, !144, !145}
!201 = !{!"functionType", !"KernelFunction"}
!202 = !{!"requiredSubGroupSize", i32 0}
!203 = !{!"rtInfo", !204, !205, !206, !207, !208, !209, !210, !211, !212, !213, !214, !215, !216, !217, !218, !219, !221, !222, !223, !224, !225}
!204 = !{!"callableShaderType", !"NumberOfCallableShaderTypes"}
!205 = !{!"isContinuation", i1 false}
!206 = !{!"hasTraceRayPayload", i1 false}
!207 = !{!"hasHitAttributes", i1 false}
!208 = !{!"hasCallableData", i1 false}
!209 = !{!"ShaderStackSize", i32 0}
!210 = !{!"ShaderHash", i64 0}
!211 = !{!"ShaderName", !""}
!212 = !{!"ParentName", !""}
!213 = !{!"SlotNum", ptr null}
!214 = !{!"NOSSize", i32 0}
!215 = !{!"globalRootSignatureSize", i32 0}
!216 = !{!"Entries"}
!217 = !{!"SpillUnions"}
!218 = !{!"CustomHitAttrSizeInBytes", i32 0}
!219 = !{!"Types", !220}
!220 = !{!"FullFrameTys"}
!221 = !{!"Aliases"}
!222 = !{!"numSyncRTStacks", i32 0}
!223 = !{!"NumCoherenceHintBits", i32 0}
!224 = !{!"useSyncHWStack", i1 false}
!225 = !{!"OriginatingShaderName", !""}
!226 = !{!"resAllocMD", !227, !228, !229, !230, !268}
!227 = !{!"uavsNumType", i32 0}
!228 = !{!"srvsNumType", i32 0}
!229 = !{!"samplersNumType", i32 0}
!230 = !{!"argAllocMDList", !231, !235, !236, !237, !238, !239, !240, !241, !242, !243, !244, !245, !246, !247, !248, !249, !250, !251, !252, !253, !254, !255, !256, !257, !258, !259, !260, !261, !262, !263, !264, !265, !266, !267}
!231 = !{!"argAllocMDListVec[0]", !232, !233, !234}
!232 = !{!"type", i32 0}
!233 = !{!"extensionType", i32 -1}
!234 = !{!"indexType", i32 -1}
!235 = !{!"argAllocMDListVec[1]", !232, !233, !234}
!236 = !{!"argAllocMDListVec[2]", !232, !233, !234}
!237 = !{!"argAllocMDListVec[3]", !232, !233, !234}
!238 = !{!"argAllocMDListVec[4]", !232, !233, !234}
!239 = !{!"argAllocMDListVec[5]", !232, !233, !234}
!240 = !{!"argAllocMDListVec[6]", !232, !233, !234}
!241 = !{!"argAllocMDListVec[7]", !232, !233, !234}
!242 = !{!"argAllocMDListVec[8]", !232, !233, !234}
!243 = !{!"argAllocMDListVec[9]", !232, !233, !234}
!244 = !{!"argAllocMDListVec[10]", !232, !233, !234}
!245 = !{!"argAllocMDListVec[11]", !232, !233, !234}
!246 = !{!"argAllocMDListVec[12]", !232, !233, !234}
!247 = !{!"argAllocMDListVec[13]", !232, !233, !234}
!248 = !{!"argAllocMDListVec[14]", !232, !233, !234}
!249 = !{!"argAllocMDListVec[15]", !232, !233, !234}
!250 = !{!"argAllocMDListVec[16]", !232, !233, !234}
!251 = !{!"argAllocMDListVec[17]", !232, !233, !234}
!252 = !{!"argAllocMDListVec[18]", !232, !233, !234}
!253 = !{!"argAllocMDListVec[19]", !232, !233, !234}
!254 = !{!"argAllocMDListVec[20]", !232, !233, !234}
!255 = !{!"argAllocMDListVec[21]", !232, !233, !234}
!256 = !{!"argAllocMDListVec[22]", !232, !233, !234}
!257 = !{!"argAllocMDListVec[23]", !232, !233, !234}
!258 = !{!"argAllocMDListVec[24]", !232, !233, !234}
!259 = !{!"argAllocMDListVec[25]", !232, !233, !234}
!260 = !{!"argAllocMDListVec[26]", !232, !233, !234}
!261 = !{!"argAllocMDListVec[27]", !232, !233, !234}
!262 = !{!"argAllocMDListVec[28]", !232, !233, !234}
!263 = !{!"argAllocMDListVec[29]", !232, !233, !234}
!264 = !{!"argAllocMDListVec[30]", !232, !233, !234}
!265 = !{!"argAllocMDListVec[31]", !232, !233, !234}
!266 = !{!"argAllocMDListVec[32]", !232, !233, !234}
!267 = !{!"argAllocMDListVec[33]", !232, !233, !234}
!268 = !{!"inlineSamplersMD"}
!269 = !{!"maxByteOffsets"}
!270 = !{!"IsInitializer", i1 false}
!271 = !{!"IsFinalizer", i1 false}
!272 = !{!"CompiledSubGroupsNumber", i32 0}
!273 = !{!"maxRegPressureSimd16", i32 0}
!274 = !{!"maxRegPressureSimd32", i32 0}
!275 = !{!"maxRegUniformPressure", i32 0}
!276 = !{!"maxRegNonUniformPressure", i32 0}
!277 = !{!"bestGuessSimd", i32 0}
!278 = !{!"hasInlineVmeSamplers", i1 false}
!279 = !{!"localSize", i32 0}
!280 = !{!"localIDPresent", i1 false}
!281 = !{!"groupIDPresent", i1 false}
!282 = !{!"privateMemoryPerWI", i32 0}
!283 = !{!"prevFPOffset", i32 0}
!284 = !{!"globalIDPresent", i1 false}
!285 = !{!"hasSyncRTCalls", i1 false}
!286 = !{!"hasPrintfCalls", i1 false}
!287 = !{!"hasDPAS", i1 false}
!288 = !{!"requireAssertBuffer", i1 false}
!289 = !{!"requireSyncBuffer", i1 false}
!290 = !{!"hasIndirectCalls", i1 false}
!291 = !{!"hasNonKernelArgLoad", i1 false}
!292 = !{!"hasNonKernelArgStore", i1 false}
!293 = !{!"hasNonKernelArgAtomic", i1 false}
!294 = !{!"UserAnnotations"}
!295 = !{!"m_OpenCLArgAddressSpaces", !296, !297, !298, !299, !300, !301, !302}
!296 = !{!"m_OpenCLArgAddressSpacesVec[0]", i32 0}
!297 = !{!"m_OpenCLArgAddressSpacesVec[1]", i32 0}
!298 = !{!"m_OpenCLArgAddressSpacesVec[2]", i32 1}
!299 = !{!"m_OpenCLArgAddressSpacesVec[3]", i32 0}
!300 = !{!"m_OpenCLArgAddressSpacesVec[4]", i32 1}
!301 = !{!"m_OpenCLArgAddressSpacesVec[5]", i32 1}
!302 = !{!"m_OpenCLArgAddressSpacesVec[6]", i32 1}
!303 = !{!"m_OpenCLArgAccessQualifiers", !304, !305, !306, !307, !308, !309, !310}
!304 = !{!"m_OpenCLArgAccessQualifiersVec[0]", !"none"}
!305 = !{!"m_OpenCLArgAccessQualifiersVec[1]", !"none"}
!306 = !{!"m_OpenCLArgAccessQualifiersVec[2]", !"none"}
!307 = !{!"m_OpenCLArgAccessQualifiersVec[3]", !"none"}
!308 = !{!"m_OpenCLArgAccessQualifiersVec[4]", !"none"}
!309 = !{!"m_OpenCLArgAccessQualifiersVec[5]", !"none"}
!310 = !{!"m_OpenCLArgAccessQualifiersVec[6]", !"none"}
!311 = !{!"m_OpenCLArgTypes", !312, !313, !314, !315, !316, !317, !318}
!312 = !{!"m_OpenCLArgTypesVec[0]", !"struct Meta"}
!313 = !{!"m_OpenCLArgTypesVec[1]", !"int"}
!314 = !{!"m_OpenCLArgTypesVec[2]", !"int*"}
!315 = !{!"m_OpenCLArgTypesVec[3]", !"int"}
!316 = !{!"m_OpenCLArgTypesVec[4]", !"float*"}
!317 = !{!"m_OpenCLArgTypesVec[5]", !"float*"}
!318 = !{!"m_OpenCLArgTypesVec[6]", !"int*"}
!319 = !{!"m_OpenCLArgBaseTypes", !320, !321, !322, !323, !324, !325, !326}
!320 = !{!"m_OpenCLArgBaseTypesVec[0]", !"struct Meta"}
!321 = !{!"m_OpenCLArgBaseTypesVec[1]", !"int"}
!322 = !{!"m_OpenCLArgBaseTypesVec[2]", !"int*"}
!323 = !{!"m_OpenCLArgBaseTypesVec[3]", !"int"}
!324 = !{!"m_OpenCLArgBaseTypesVec[4]", !"float*"}
!325 = !{!"m_OpenCLArgBaseTypesVec[5]", !"float*"}
!326 = !{!"m_OpenCLArgBaseTypesVec[6]", !"int*"}
!327 = !{!"m_OpenCLArgTypeQualifiers", !328, !329, !330, !331, !332, !333, !334}
!328 = !{!"m_OpenCLArgTypeQualifiersVec[0]", !""}
!329 = !{!"m_OpenCLArgTypeQualifiersVec[1]", !""}
!330 = !{!"m_OpenCLArgTypeQualifiersVec[2]", !""}
!331 = !{!"m_OpenCLArgTypeQualifiersVec[3]", !""}
!332 = !{!"m_OpenCLArgTypeQualifiersVec[4]", !""}
!333 = !{!"m_OpenCLArgTypeQualifiersVec[5]", !""}
!334 = !{!"m_OpenCLArgTypeQualifiersVec[6]", !""}
!335 = !{!"m_OpenCLArgNames", !336, !337, !338, !339, !340, !341, !342}
!336 = !{!"m_OpenCLArgNamesVec[0]", !""}
!337 = !{!"m_OpenCLArgNamesVec[1]", !""}
!338 = !{!"m_OpenCLArgNamesVec[2]", !""}
!339 = !{!"m_OpenCLArgNamesVec[3]", !""}
!340 = !{!"m_OpenCLArgNamesVec[4]", !""}
!341 = !{!"m_OpenCLArgNamesVec[5]", !""}
!342 = !{!"m_OpenCLArgNamesVec[6]", !""}
!343 = !{!"m_OpenCLArgScalarAsPointers"}
!344 = !{!"m_OptsToDisablePerFunc", !345, !346, !347}
!345 = !{!"m_OptsToDisablePerFuncSet[0]", !"IGC-AddressArithmeticSinking"}
!346 = !{!"m_OptsToDisablePerFuncSet[1]", !"IGC-AllowSimd32Slicing"}
!347 = !{!"m_OptsToDisablePerFuncSet[2]", !"IGC-SinkLoadOpt"}
!348 = !{!"pushInfo", !349, !350, !351, !355, !356, !357, !358, !359, !360, !361, !362, !375, !376, !377, !378}
!349 = !{!"pushableAddresses"}
!350 = !{!"bindlessPushInfo"}
!351 = !{!"dynamicBufferInfo", !352, !353, !354}
!352 = !{!"firstIndex", i32 0}
!353 = !{!"numOffsets", i32 0}
!354 = !{!"forceDisabled", i1 false}
!355 = !{!"MaxNumberOfPushedBuffers", i32 0}
!356 = !{!"inlineConstantBufferSlot", i32 -1}
!357 = !{!"inlineConstantBufferOffset", i32 -1}
!358 = !{!"inlineConstantBufferGRFOffset", i32 -1}
!359 = !{!"constants"}
!360 = !{!"inputs"}
!361 = !{!"constantReg"}
!362 = !{!"simplePushInfoArr", !363, !372, !373, !374}
!363 = !{!"simplePushInfoArrVec[0]", !364, !365, !366, !367, !368, !369, !370, !371}
!364 = !{!"cbIdx", i32 0}
!365 = !{!"pushableAddressGrfOffset", i32 -1}
!366 = !{!"pushableOffsetGrfOffset", i32 -1}
!367 = !{!"offset", i32 0}
!368 = !{!"size", i32 0}
!369 = !{!"isStateless", i1 false}
!370 = !{!"isBindless", i1 false}
!371 = !{!"simplePushLoads"}
!372 = !{!"simplePushInfoArrVec[1]", !364, !365, !366, !367, !368, !369, !370, !371}
!373 = !{!"simplePushInfoArrVec[2]", !364, !365, !366, !367, !368, !369, !370, !371}
!374 = !{!"simplePushInfoArrVec[3]", !364, !365, !366, !367, !368, !369, !370, !371}
!375 = !{!"simplePushBufferUsed", i32 0}
!376 = !{!"pushAnalysisWIInfos"}
!377 = !{!"inlineRTGlobalPtrOffset", i32 0}
!378 = !{!"rtSyncSurfPtrOffset", i32 0}
!379 = !{!"psInfo", !380, !381, !382, !383, !384, !385, !386, !387, !388, !389, !390, !391, !392, !393, !394, !395}
!380 = !{!"BlendStateDisabledMask", i8 0}
!381 = !{!"SkipSrc0Alpha", i1 false}
!382 = !{!"DualSourceBlendingDisabled", i1 false}
!383 = !{!"ForceEnableSimd32", i1 false}
!384 = !{!"DisableSimd32WithDiscard", i1 false}
!385 = !{!"outputDepth", i1 false}
!386 = !{!"outputStencil", i1 false}
!387 = !{!"outputMask", i1 false}
!388 = !{!"blendToFillEnabled", i1 false}
!389 = !{!"forceEarlyZ", i1 false}
!390 = !{!"hasVersionedLoop", i1 false}
!391 = !{!"forceSingleSourceRTWAfterDualSourceRTW", i1 false}
!392 = !{!"blendOptimizationMode"}
!393 = !{!"colorOutputMask"}
!394 = !{!"isBlendEnabled"}
!395 = !{!"WaDisableVRS", i1 false}
!396 = !{!"csInfo", !397, !398, !399, !400, !48, !24, !25, !401, !26, !402, !403, !404, !405, !406, !407, !408, !409, !410, !411, !412, !59, !413, !414, !415, !416}
!397 = !{!"maxWorkGroupSize", i32 0}
!398 = !{!"waveSize", i32 0}
!399 = !{!"ComputeShaderSecondCompile"}
!400 = !{!"forcedSIMDSize", i8 0}
!401 = !{!"VISAPreSchedScheduleExtraGRF", i32 0}
!402 = !{!"forceSpillCompression", i1 false}
!403 = !{!"allowLowerSimd", i1 false}
!404 = !{!"disableSimd32Slicing", i1 false}
!405 = !{!"disableSplitOnSpill", i1 false}
!406 = !{!"enableNewSpillCostFunction", i1 false}
!407 = !{!"forceVISAPreSched", i1 false}
!408 = !{!"disableLocalIdOrderOptimizations", i1 false}
!409 = !{!"disableDispatchAlongY", i1 false}
!410 = !{!"neededThreadIdLayout", ptr null}
!411 = !{!"forceTileYWalk", i1 false}
!412 = !{!"atomicBranch", i32 0}
!413 = !{!"disableEarlyOut", i1 false}
!414 = !{!"walkOrderEnabled", i1 false}
!415 = !{!"walkOrderOverride", i32 0}
!416 = !{!"ResForHfPacking"}
!417 = !{!"msInfo", !418, !419, !420, !421, !422, !423, !424, !425, !426}
!418 = !{!"PrimitiveTopology", i32 3}
!419 = !{!"MaxNumOfPrimitives", i32 0}
!420 = !{!"MaxNumOfVertices", i32 0}
!421 = !{!"MaxNumOfPerPrimitiveOutputs", i32 0}
!422 = !{!"MaxNumOfPerVertexOutputs", i32 0}
!423 = !{!"WorkGroupSize", i32 0}
!424 = !{!"WorkGroupMemorySizeInBytes", i32 0}
!425 = !{!"IndexFormat", i32 6}
!426 = !{!"SubgroupSize", i32 0}
!427 = !{!"taskInfo", !428, !423, !424, !426}
!428 = !{!"MaxNumOfOutputs", i32 0}
!429 = !{!"NBarrierCnt", i32 0}
!430 = !{!"rtInfo", !431, !432, !433, !434, !435, !436, !437, !438, !439, !440, !441, !442, !443, !444, !222}
!431 = !{!"RayQueryAllocSizeInBytes", i32 0}
!432 = !{!"NumContinuations", i32 0}
!433 = !{!"RTAsyncStackAddrspace", i32 -1}
!434 = !{!"RTAsyncStackSurfaceStateOffset", ptr null}
!435 = !{!"SWHotZoneAddrspace", i32 -1}
!436 = !{!"SWHotZoneSurfaceStateOffset", ptr null}
!437 = !{!"SWStackAddrspace", i32 -1}
!438 = !{!"SWStackSurfaceStateOffset", ptr null}
!439 = !{!"RTSyncStackAddrspace", i32 -1}
!440 = !{!"RTSyncStackSurfaceStateOffset", ptr null}
!441 = !{!"doSyncDispatchRays", i1 false}
!442 = !{!"MemStyle", !"Xe"}
!443 = !{!"GlobalDataStyle", !"Xe"}
!444 = !{!"uberTileDimensions", ptr null}
!445 = !{!"hasSliceLayoutDependency", i1 false}
!446 = !{!"CurUniqueIndirectIdx", i32 0}
!447 = !{!"inlineDynTextures"}
!448 = !{!"inlineResInfoData"}
!449 = !{!"immConstant", !450, !451, !452}
!450 = !{!"data"}
!451 = !{!"sizes"}
!452 = !{!"zeroIdxs"}
!453 = !{!"stringConstants"}
!454 = !{!"inlineBuffers", !455, !459, !460}
!455 = !{!"inlineBuffersVec[0]", !456, !457, !458}
!456 = !{!"alignment", i32 0}
!457 = !{!"allocSize", i64 0}
!458 = !{!"Buffer"}
!459 = !{!"inlineBuffersVec[1]", !456, !457, !458}
!460 = !{!"inlineBuffersVec[2]", !456, !457, !458}
!461 = !{!"GlobalBufferAddressRelocInfo"}
!462 = !{!"ConstantBufferAddressRelocInfo"}
!463 = !{!"forceLscCacheList"}
!464 = !{!"SrvMap"}
!465 = !{!"RasterizerOrderedByteAddressBuffer"}
!466 = !{!"RasterizerOrderedViews"}
!467 = !{!"MinNOSPushConstantSize", i32 0}
!468 = !{!"inlineProgramScopeOffsets"}
!469 = !{!"shaderData", !470}
!470 = !{!"numReplicas", i32 0}
!471 = !{!"URBInfo", !472, !473, !474}
!472 = !{!"has64BVertexHeaderInput", i1 false}
!473 = !{!"has64BVertexHeaderOutput", i1 false}
!474 = !{!"hasVertexHeader", i1 true}
!475 = !{!"UseBindlessImage", i1 true}
!476 = !{!"HasBindlessImageRead", i1 false}
!477 = !{!"UseBindlessImageWithSamplerTracking", i1 false}
!478 = !{!"enableRangeReduce", i1 false}
!479 = !{!"allowMatchMadOptimizationforPosition", i1 false}
!480 = !{!"disableMatchMadOptimizationForCS", i1 false}
!481 = !{!"disableMemOptforNegativeOffsetLoads", i1 false}
!482 = !{!"enableThreeWayLoadSpiltOpt", i1 false}
!483 = !{!"statefulResourcesNotAliased", i1 false}
!484 = !{!"disableMixMode", i1 false}
!485 = !{!"genericAccessesResolved", i1 false}
!486 = !{!"disableSeparateSpillPvtScratchSpace", i1 false}
!487 = !{!"enableSeparateSpillPvtScratchSpace", i1 false}
!488 = !{!"disableSeparateScratchWA", i1 false}
!489 = !{!"enableRemoveUnusedTGMFence", i1 false}
!490 = !{!"PrivateMemoryPerFG", !491, !492}
!491 = !{!"PrivateMemoryPerFGMap[0]", ptr @_ZTSZL7combineRN4sycl3_V15queueEPKiPKfS4_PfRK4MetaiiEUlNS0_2idILi1EEEE_}
!492 = !{!"PrivateMemoryPerFGValue[0]", i32 0}
!493 = !{!"m_OptsToDisable"}
!494 = !{!"capabilities", !495}
!495 = !{!"globalVariableDecorationsINTEL", i1 false}
!496 = !{!"extensions", !497}
!497 = !{!"spvINTELBindlessImages", i1 false}
!498 = !{!"m_ShaderResourceViewMcsMask", !499, !500}
!499 = !{!"m_ShaderResourceViewMcsMaskVec[0]", i64 0}
!500 = !{!"m_ShaderResourceViewMcsMaskVec[1]", i64 0}
!501 = !{!"computedDepthMode", i32 0}
!502 = !{!"isHDCFastClearShader", i1 false}
!503 = !{!"argRegisterReservations", !504}
!504 = !{!"argRegisterReservationsVec[0]", i32 0}
!505 = !{!"SIMD16_SpillThreshold", i8 0}
!506 = !{!"SIMD32_SpillThreshold", i8 0}
!507 = !{!"m_CacheControlOption", !508, !509, !510, !511}
!508 = !{!"LscLoadCacheControlOverride", i8 0}
!509 = !{!"LscStoreCacheControlOverride", i8 0}
!510 = !{!"TgmLoadCacheControlOverride", i8 0}
!511 = !{!"TgmStoreCacheControlOverride", i8 0}
!512 = !{!"ModuleUsesBindless", i1 false}
!513 = !{!"predicationMap"}
!514 = !{!"lifeTimeStartMap"}
!515 = !{!"HitGroups"}
!516 = !{i32 2, i32 0}
!517 = !{!"clang version 22.1.8 (Fedora 22.1.8-4.fc44)"}
!518 = !{!"clang version 9.0.0 (2dbee6917918354f14026a637370445d50bdaf6a)"}
!519 = !{!"clang version 9.0.0 (c68f557a081b1b2339a42d7cd6af3c2ab18c6061)"}
!520 = !{!521, !521, i64 0}
!521 = !{!"int", !522, i64 0}
!522 = !{!"omnipotent char", !523, i64 0}
!523 = !{!"Simple C/C++ TBAA"}
!524 = !{i32 1, !"wchar_size", i32 4}
!525 = !{float 2.500000e+00}
!526 = !{!527}
!527 = !{i32 4469}
!528 = !{!527, !529}
!529 = !{i32 4470}
!530 = !{!531}
!531 = !{i32 40, i32 196620}
!532 = !{!533}
!533 = !{i32 40, i32 196621}

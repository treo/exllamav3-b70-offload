; ------------------------------------------------
; OCL_asm6efbb33bd2ee4230_push_analysis.ll
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
  %21 = zext nneg i32 %20 to i64
  %22 = icmp ugt i32 %12, %20
  %23 = icmp eq i32 %13, 0
  %24 = and i1 %23, %22
  %25 = icmp ugt i32 %13, 0
  %26 = or i1 %24, %25
  %27 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %1)
  %28 = extractvalue { i32, i32 } %27, 0
  %29 = extractvalue { i32, i32 } %27, 1
  %30 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %2)
  %31 = extractvalue { i32, i32 } %30, 0
  %32 = extractvalue { i32, i32 } %30, 1
  %33 = select i1 %26, i32 %28, i32 %31
  %34 = select i1 %26, i32 %29, i32 %32
  %35 = insertelement <2 x i32> undef, i32 %33, i32 0
  %36 = insertelement <2 x i32> %35, i32 %34, i32 1
  %37 = bitcast <2 x i32> %36 to i64
  %38 = select i1 %26, i32 0, i32 %12
  %39 = select i1 %26, i32 0, i32 %13
  %40 = insertelement <2 x i32> undef, i32 %38, i32 0
  %41 = insertelement <2 x i32> %40, i32 %39, i32 1
  %42 = bitcast <2 x i32> %41 to i64
  %43 = sub nsw i64 %21, %42, !spirv.Decorations !556
  %44 = bitcast i64 %43 to <2 x i32>
  %45 = extractelement <2 x i32> %44, i32 0
  %46 = extractelement <2 x i32> %44, i32 1
  %47 = sext i32 %const_reg_dword1 to i64
  %48 = ashr i32 %const_reg_dword1, 31
  %49 = sext i32 %const_reg_dword5 to i64
  %50 = ashr i32 %const_reg_dword5, 31
  %51 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %const_reg_dword1, i32 %48, i32 %const_reg_dword5, i32 %50)
  %52 = extractvalue { i32, i32 } %51, 0
  %53 = extractvalue { i32, i32 } %51, 1
  %54 = insertelement <2 x i32> undef, i32 %52, i32 0
  %55 = insertelement <2 x i32> %54, i32 %53, i32 1
  %56 = bitcast <2 x i32> %55 to i64
  %57 = or i32 %53, %46
  %58 = icmp ult i32 %57, 1
  br i1 %58, label %59, label %81

59:                                               ; preds = %10
  %60 = trunc nuw i64 %43 to i32
  %61 = trunc nuw i64 %56 to i32
  %62 = icmp eq i32 %52, 0
  %63 = icmp eq i32 %53, 0
  %64 = and i1 %63, %62
  br i1 %64, label %.precompiled_u32divrem_sp.exit88_crit_edge, label %if.end.i67

.precompiled_u32divrem_sp.exit88_crit_edge:       ; preds = %59
  br label %precompiled_u32divrem_sp.exit88

if.end.i67:                                       ; preds = %59
  %65 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %61)
  %conv.i68 = fptoui float %65 to i32
  %sub.i69 = sub i32 %61, %conv.i68
  %66 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i69)
  %67 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %60)
  %conv3.i70 = fptoui float %67 to i32
  %sub4.i71 = sub i32 %60, %conv3.i70
  %68 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i71)
  %div.i72 = fdiv float 1.000000e+00, %65, !fpmath !558
  %69 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i72, float 0xBE98000000000000, float %div.i72)
  %70 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %67, float %69)
  %conv8.i73 = fptoui float %70 to i32
  %71 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i73)
  %72 = fsub float 0.000000e+00, %65
  %73 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %72, float %71, float %67)
  %74 = fsub float 0.000000e+00, %66
  %75 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %74, float %71, float %68)
  %76 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %73, float %75)
  %77 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %69, float %76)
  %conv16.i76 = fptoui float %77 to i32
  %add.i77 = add i32 %conv16.i76, %conv8.i73
  %mul.i78 = mul i32 %add.i77, %61
  %sub17.i79 = sub i32 %60, %mul.i78
  %cmp.i80 = icmp uge i32 %sub17.i79, %61
  %78 = sext i1 %cmp.i80 to i32
  %79 = sub i32 0, %78
  %add19.i83 = add i32 %add.i77, %79
  br label %precompiled_u32divrem_sp.exit88

precompiled_u32divrem_sp.exit88:                  ; preds = %.precompiled_u32divrem_sp.exit88_crit_edge, %if.end.i67
  %retval.0.i87 = phi i32 [ %add19.i83, %if.end.i67 ], [ -1, %.precompiled_u32divrem_sp.exit88_crit_edge ]
  %80 = zext i32 %retval.0.i87 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit

81:                                               ; preds = %10
  %82 = trunc i64 %56 to i32
  %83 = uitofp i64 %56 to double
  %84 = fptrunc double %83 to float
  %85 = fdiv float 1.000000e+00, %84
  %86 = fpext float %85 to double
  %87 = fsub double 0.000000e+00, %83
  %88 = call double @llvm.fma.f64(double %87, double %86, double 1.000000e+00) #4
  %89 = fadd double %88, 0xBCF0000000000000
  %90 = call double @llvm.fma.f64(double %86, double %89, double %86) #4
  %91 = bitcast i64 %43 to <2 x i32>
  %92 = extractelement <2 x i32> %91, i32 1
  %93 = uitofp i32 %92 to double
  %94 = fmul double %90, %93
  %95 = fptoui double %94 to i32
  %96 = mul i32 %95, %82
  %97 = sub i32 %92, %96
  %98 = uitofp i32 %97 to double
  %99 = trunc i64 %43 to i32
  %100 = uitofp i32 %99 to double
  %101 = call double @llvm.fma.f64(double %98, double 0x41F0000000000000, double %100) #4
  %102 = fmul double %90, %101
  %103 = fptoui double %102 to i64
  %104 = bitcast i64 %103 to <2 x i32>
  %105 = extractelement <2 x i32> %104, i32 0
  %106 = trunc i64 %103 to i32
  %107 = lshr i64 %103, 32
  %108 = bitcast i64 %107 to <2 x i32>
  %109 = extractelement <2 x i32> %108, i32 0
  %110 = extractelement <2 x i32> %108, i32 1
  %111 = bitcast i64 %103 to <2 x i32>
  %112 = extractelement <2 x i32> %111, i32 1
  %113 = icmp eq i32 %109, 0
  %114 = icmp eq i32 %110, 0
  %115 = and i1 %114, %113
  %116 = mul i32 %106, %53
  %117 = select i1 %115, i32 0, i32 %82
  %118 = add i32 %116, %117
  %119 = sub i32 %97, %118
  %120 = insertelement <2 x i32> undef, i32 %45, i32 0
  %121 = insertelement <2 x i32> %120, i32 %119, i32 1
  %122 = bitcast <2 x i32> %121 to i64
  %123 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %105, i32 0, i32 %52, i32 0)
  %124 = extractvalue { i32, i32 } %123, 0
  %125 = extractvalue { i32, i32 } %123, 1
  %126 = insertelement <2 x i32> undef, i32 %124, i32 0
  %127 = insertelement <2 x i32> %126, i32 %125, i32 1
  %128 = bitcast <2 x i32> %127 to i64
  %129 = sub i64 %122, %128
  %130 = bitcast i64 %129 to <2 x i32>
  %131 = extractelement <2 x i32> %130, i32 0
  %132 = extractelement <2 x i32> %130, i32 1
  %133 = add i32 %112, %95
  %134 = insertelement <2 x i32> undef, i32 %105, i32 0
  %135 = insertelement <2 x i32> %134, i32 %133, i32 1
  %136 = bitcast <2 x i32> %135 to i64
  %137 = icmp uge i32 %131, %52
  %138 = icmp eq i32 %132, %53
  %139 = and i1 %138, %137
  %140 = icmp ugt i32 %132, %53
  %141 = or i1 %139, %140
  %142 = sext i1 %141 to i64
  %143 = sub i64 0, %142
  %144 = add i64 %136, %143
  br label %__igcbuiltin_u64_udiv_dp.exit

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit88, %81
  %145 = phi i64 [ %80, %precompiled_u32divrem_sp.exit88 ], [ %144, %81 ]
  %146 = or i32 %46, %50
  %147 = icmp ult i32 %146, 1
  br i1 %147, label %148, label %166

148:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %149 = trunc nuw i64 %43 to i32
  %tobool.i43 = icmp eq i32 %const_reg_dword5, 0
  br i1 %tobool.i43, label %.precompiled_u32divrem_sp.exit65_crit_edge, label %if.end.i44

.precompiled_u32divrem_sp.exit65_crit_edge:       ; preds = %148
  br label %precompiled_u32divrem_sp.exit65

if.end.i44:                                       ; preds = %148
  %150 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword5)
  %conv.i45 = fptoui float %150 to i32
  %sub.i46 = sub i32 %const_reg_dword5, %conv.i45
  %151 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i46)
  %152 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %149)
  %conv3.i47 = fptoui float %152 to i32
  %sub4.i48 = sub i32 %149, %conv3.i47
  %153 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i48)
  %div.i49 = fdiv float 1.000000e+00, %150, !fpmath !558
  %154 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i49, float 0xBE98000000000000, float %div.i49)
  %155 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %152, float %154)
  %conv8.i50 = fptoui float %155 to i32
  %156 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i50)
  %157 = fsub float 0.000000e+00, %150
  %158 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %157, float %156, float %152)
  %159 = fsub float 0.000000e+00, %151
  %160 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %159, float %156, float %153)
  %161 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %158, float %160)
  %162 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %154, float %161)
  %conv16.i53 = fptoui float %162 to i32
  %add.i54 = add i32 %conv16.i53, %conv8.i50
  %mul.i55 = mul i32 %add.i54, %const_reg_dword5
  %sub17.i56 = sub i32 %149, %mul.i55
  %cmp.i57 = icmp uge i32 %sub17.i56, %const_reg_dword5
  %163 = sext i1 %cmp.i57 to i32
  %164 = sub i32 0, %163
  %add19.i60 = add i32 %add.i54, %164
  br label %precompiled_u32divrem_sp.exit65

precompiled_u32divrem_sp.exit65:                  ; preds = %.precompiled_u32divrem_sp.exit65_crit_edge, %if.end.i44
  %retval.0.i64 = phi i32 [ %add19.i60, %if.end.i44 ], [ -1, %.precompiled_u32divrem_sp.exit65_crit_edge ]
  %165 = zext i32 %retval.0.i64 to i64
  br label %__igcbuiltin_u64_udiv_dp.exit41

166:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
  %167 = uitofp i64 %49 to double
  %168 = fptrunc double %167 to float
  %169 = fdiv float 1.000000e+00, %168
  %170 = fpext float %169 to double
  %171 = fsub double 0.000000e+00, %167
  %172 = call double @llvm.fma.f64(double %171, double %170, double 1.000000e+00) #4
  %173 = fadd double %172, 0xBCF0000000000000
  %174 = call double @llvm.fma.f64(double %170, double %173, double %170) #4
  %175 = bitcast i64 %43 to <2 x i32>
  %176 = extractelement <2 x i32> %175, i32 1
  %177 = uitofp i32 %176 to double
  %178 = fmul double %174, %177
  %179 = fptoui double %178 to i32
  %180 = mul i32 %const_reg_dword5, %179
  %181 = sub i32 %176, %180
  %182 = uitofp i32 %181 to double
  %183 = trunc i64 %43 to i32
  %184 = uitofp i32 %183 to double
  %185 = call double @llvm.fma.f64(double %182, double 0x41F0000000000000, double %184) #4
  %186 = fmul double %174, %185
  %187 = fptoui double %186 to i64
  %188 = bitcast i64 %187 to <2 x i32>
  %189 = extractelement <2 x i32> %188, i32 0
  %190 = trunc i64 %187 to i32
  %191 = lshr i64 %187, 32
  %192 = bitcast i64 %191 to <2 x i32>
  %193 = extractelement <2 x i32> %192, i32 0
  %194 = extractelement <2 x i32> %192, i32 1
  %195 = bitcast i64 %187 to <2 x i32>
  %196 = extractelement <2 x i32> %195, i32 1
  %197 = icmp eq i32 %193, 0
  %198 = icmp eq i32 %194, 0
  %199 = and i1 %198, %197
  %isneg = icmp slt i32 %const_reg_dword5, 0
  %.neg90 = select i1 %isneg, i32 %190, i32 0
  %200 = add i32 %.neg90, %181
  %201 = select i1 %199, i32 0, i32 %const_reg_dword5
  %202 = sub i32 %200, %201
  %203 = insertelement <2 x i32> undef, i32 %45, i32 0
  %204 = insertelement <2 x i32> %203, i32 %202, i32 1
  %205 = bitcast <2 x i32> %204 to i64
  %206 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %189, i32 0, i32 %const_reg_dword5, i32 0)
  %207 = extractvalue { i32, i32 } %206, 0
  %208 = extractvalue { i32, i32 } %206, 1
  %209 = insertelement <2 x i32> undef, i32 %207, i32 0
  %210 = insertelement <2 x i32> %209, i32 %208, i32 1
  %211 = bitcast <2 x i32> %210 to i64
  %212 = sub i64 %205, %211
  %213 = bitcast i64 %212 to <2 x i32>
  %214 = extractelement <2 x i32> %213, i32 0
  %215 = extractelement <2 x i32> %213, i32 1
  %216 = add i32 %196, %179
  %217 = insertelement <2 x i32> undef, i32 %189, i32 0
  %218 = insertelement <2 x i32> %217, i32 %216, i32 1
  %219 = bitcast <2 x i32> %218 to i64
  %220 = icmp uge i32 %214, %const_reg_dword5
  %221 = icmp eq i32 %215, %50
  %222 = and i1 %221, %220
  %223 = icmp ugt i32 %215, %50
  %224 = or i1 %222, %223
  %225 = sext i1 %224 to i64
  %226 = sub i64 0, %225
  %227 = add i64 %219, %226
  br label %__igcbuiltin_u64_udiv_dp.exit41

__igcbuiltin_u64_udiv_dp.exit41:                  ; preds = %precompiled_u32divrem_sp.exit65, %166
  %228 = phi i64 [ %165, %precompiled_u32divrem_sp.exit65 ], [ %227, %166 ]
  %229 = bitcast i64 %228 to <2 x i32>
  %230 = extractelement <2 x i32> %229, i32 0
  %231 = extractelement <2 x i32> %229, i32 1
  %232 = or i32 %231, %48
  %233 = icmp ult i32 %232, 1
  br i1 %233, label %234, label %250

234:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit41
  %235 = trunc nuw i64 %228 to i32
  %tobool.i = icmp eq i32 %const_reg_dword1, 0
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %234
  br label %precompiled_u32divrem_sp.exit

if.end.i:                                         ; preds = %234
  %236 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword1)
  %conv.i = fptoui float %236 to i32
  %sub.i = sub i32 %const_reg_dword1, %conv.i
  %237 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)
  %238 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %235)
  %conv3.i = fptoui float %238 to i32
  %sub4.i = sub i32 %235, %conv3.i
  %239 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)
  %div.i = fdiv float 1.000000e+00, %236, !fpmath !558
  %240 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)
  %241 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %238, float %240)
  %conv8.i = fptoui float %241 to i32
  %242 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)
  %243 = fsub float 0.000000e+00, %236
  %244 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %243, float %242, float %238)
  %245 = fsub float 0.000000e+00, %237
  %246 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %245, float %242, float %239)
  %247 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %244, float %246)
  %248 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %240, float %247)
  %conv16.i = fptoui float %248 to i32
  %add.i = add i32 %conv16.i, %conv8.i
  %mul.i = mul i32 %add.i, %const_reg_dword1
  %sub17.i = sub i32 %235, %mul.i
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword1
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword1
  %sub21.i = sub i32 %sub17.i, %and20.i
  br label %precompiled_u32divrem_sp.exit

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %249 = zext i32 %storemerge.i to i64
  br label %__igcbuiltin_u64_urem_dp.exit

250:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit41
  %251 = uitofp i64 %47 to double
  %252 = fptrunc double %251 to float
  %253 = fdiv float 1.000000e+00, %252
  %254 = fpext float %253 to double
  %255 = fsub double 0.000000e+00, %251
  %256 = call double @llvm.fma.f64(double %255, double %254, double 1.000000e+00) #4
  %257 = fadd double %256, 0xBCF0000000000000
  %258 = call double @llvm.fma.f64(double %254, double %257, double %254) #4
  %259 = bitcast i64 %228 to <2 x i32>
  %260 = extractelement <2 x i32> %259, i32 1
  %261 = uitofp i32 %260 to double
  %262 = fmul double %258, %261
  %263 = fptoui double %262 to i32
  %264 = mul i32 %const_reg_dword1, %263
  %265 = sub i32 %260, %264
  %266 = uitofp i32 %265 to double
  %267 = trunc i64 %228 to i32
  %268 = uitofp i32 %267 to double
  %269 = call double @llvm.fma.f64(double %266, double 0x41F0000000000000, double %268) #4
  %270 = fmul double %258, %269
  %271 = fptoui double %270 to i64
  %272 = bitcast i64 %271 to <2 x i32>
  %273 = extractelement <2 x i32> %272, i32 0
  %274 = extractelement <2 x i32> %272, i32 1
  %275 = trunc i64 %271 to i32
  %276 = icmp ult i32 %274, 1
  %isneg92 = icmp slt i32 %const_reg_dword1, 0
  %.neg91 = select i1 %isneg92, i32 %275, i32 0
  %277 = select i1 %276, i32 0, i32 %const_reg_dword1
  %278 = sub i32 %265, %277
  %279 = add i32 %.neg91, %278
  %280 = insertelement <2 x i32> undef, i32 %230, i32 0
  %281 = insertelement <2 x i32> %280, i32 %279, i32 1
  %282 = bitcast <2 x i32> %281 to i64
  %283 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %273, i32 0, i32 %const_reg_dword1, i32 0)
  %284 = extractvalue { i32, i32 } %283, 0
  %285 = extractvalue { i32, i32 } %283, 1
  %286 = insertelement <2 x i32> undef, i32 %284, i32 0
  %287 = insertelement <2 x i32> %286, i32 %285, i32 1
  %288 = bitcast <2 x i32> %287 to i64
  %289 = sub i64 %282, %288
  %290 = bitcast i64 %289 to <2 x i32>
  %291 = extractelement <2 x i32> %290, i32 0
  %292 = extractelement <2 x i32> %290, i32 1
  %293 = icmp ult i32 %291, %const_reg_dword1
  %294 = icmp eq i32 %292, %48
  %295 = and i1 %294, %293
  %296 = icmp ult i32 %292, %48
  %297 = or i1 %295, %296
  %298 = select i1 %297, i32 0, i32 %const_reg_dword1
  %299 = select i1 %297, i32 0, i32 %48
  %300 = insertelement <2 x i32> undef, i32 %298, i32 0
  %301 = insertelement <2 x i32> %300, i32 %299, i32 1
  %302 = bitcast <2 x i32> %301 to i64
  %303 = sub i64 %289, %302
  br label %__igcbuiltin_u64_urem_dp.exit

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %250
  %304 = phi i64 [ %249, %precompiled_u32divrem_sp.exit ], [ %303, %250 ]
  %305 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %230, i32 %231, i32 %const_reg_dword5, i32 %50)
  %306 = extractvalue { i32, i32 } %305, 0
  %307 = extractvalue { i32, i32 } %305, 1
  %308 = insertelement <2 x i32> undef, i32 %306, i32 0
  %309 = insertelement <2 x i32> %308, i32 %307, i32 1
  %310 = bitcast <2 x i32> %309 to i64
  %311 = sub i64 %43, %310
  %312 = shl nsw i32 %6, 1, !spirv.Decorations !556
  %313 = ashr i32 %const_reg_dword, 31
  %314 = bitcast i64 %145 to <2 x i32>
  %315 = extractelement <2 x i32> %314, i32 0
  %316 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %315, i32 1
  %317 = bitcast <2 x i32> %316 to i64
  %318 = ashr exact i64 %317, 32
  %319 = ashr i32 %7, 31
  %320 = bitcast i64 %304 to <2 x i32>
  %321 = extractelement <2 x i32> %320, i32 0
  %322 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %321, i32 1
  %323 = bitcast <2 x i32> %322 to i64
  %324 = ashr exact i64 %323, 32
  %325 = bitcast i64 %311 to <2 x i32>
  %326 = extractelement <2 x i32> %325, i32 0
  %327 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %326, i32 1
  %328 = bitcast <2 x i32> %327 to i64
  %329 = ashr exact i64 %328, 30
  %330 = add i64 %329, %37
  %331 = icmp sgt i32 %6, 0
  br i1 %331, label %.lr.ph.preheader, label %__igcbuiltin_u64_urem_dp.exit._crit_edge

__igcbuiltin_u64_urem_dp.exit._crit_edge:         ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %368

.lr.ph.preheader:                                 ; preds = %__igcbuiltin_u64_urem_dp.exit
  br label %.lr.ph

.lr.ph:                                           ; preds = %.lr.ph..lr.ph_crit_edge, %.lr.ph.preheader
  %332 = phi i32 [ %365, %.lr.ph..lr.ph_crit_edge ], [ 0, %.lr.ph.preheader ]
  %333 = phi i32 [ %364, %.lr.ph..lr.ph_crit_edge ], [ 0, %.lr.ph.preheader ]
  %334 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %332, i32 0, i32 %const_reg_dword, i32 %313)
  %335 = extractvalue { i32, i32 } %334, 0
  %336 = extractvalue { i32, i32 } %334, 1
  %337 = insertelement <2 x i32> undef, i32 %335, i32 0
  %338 = insertelement <2 x i32> %337, i32 %336, i32 1
  %339 = bitcast <2 x i32> %338 to i64
  %340 = add nsw i64 %339, %318, !spirv.Decorations !556
  %341 = bitcast i64 %340 to <2 x i32>
  %342 = extractelement <2 x i32> %341, i32 0
  %343 = extractelement <2 x i32> %341, i32 1
  %344 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %342, i32 %343, i32 %7, i32 %319)
  %345 = extractvalue { i32, i32 } %344, 0
  %346 = extractvalue { i32, i32 } %344, 1
  %347 = insertelement <2 x i32> undef, i32 %345, i32 0
  %348 = insertelement <2 x i32> %347, i32 %346, i32 1
  %349 = bitcast <2 x i32> %348 to i64
  %350 = add i64 %349, %324
  %351 = bitcast i64 %350 to <2 x i32>
  %352 = extractelement <2 x i32> %351, i32 0
  %353 = extractelement <2 x i32> %351, i32 1
  %354 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %352, i32 %353, i32 %const_reg_dword5, i32 %50)
  %355 = extractvalue { i32, i32 } %354, 0
  %356 = extractvalue { i32, i32 } %354, 1
  %357 = insertelement <2 x i32> undef, i32 %355, i32 0
  %358 = insertelement <2 x i32> %357, i32 %356, i32 1
  %359 = bitcast <2 x i32> %358 to i64
  %360 = shl i64 %359, 2
  %361 = add i64 %330, %360
  %362 = inttoptr i64 %361 to ptr addrspace(1)
  %363 = load i32, ptr addrspace(1) %362, align 4
  %364 = add nsw i32 %333, %363, !spirv.Decorations !556
  %365 = add nuw nsw i32 %332, 1, !spirv.Decorations !559
  %366 = icmp slt i32 %365, %312
  br i1 %366, label %.lr.ph..lr.ph_crit_edge, label %._crit_edge

.lr.ph..lr.ph_crit_edge:                          ; preds = %.lr.ph
  br label %.lr.ph

._crit_edge:                                      ; preds = %.lr.ph
  %367 = sitofp i32 %364 to float
  br label %368

368:                                              ; preds = %__igcbuiltin_u64_urem_dp.exit._crit_edge, %._crit_edge
  %.lcssa = phi float [ %367, %._crit_edge ], [ 0.000000e+00, %__igcbuiltin_u64_urem_dp.exit._crit_edge ]
  %369 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %3)
  %370 = extractvalue { i32, i32 } %369, 0
  %371 = extractvalue { i32, i32 } %369, 1
  %372 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %4)
  %373 = extractvalue { i32, i32 } %372, 0
  %374 = extractvalue { i32, i32 } %372, 1
  %375 = select i1 %26, i32 %370, i32 %373
  %376 = select i1 %26, i32 %371, i32 %374
  %377 = insertelement <2 x i32> undef, i32 %375, i32 0
  %378 = insertelement <2 x i32> %377, i32 %376, i32 1
  %379 = bitcast <2 x i32> %378 to i64
  %380 = ptrtoint ptr addrspace(1) %8 to i64
  %381 = ashr exact i64 %323, 30
  %382 = add i64 %381, %380
  %383 = inttoptr i64 %382 to ptr addrspace(1)
  %384 = load float, ptr addrspace(1) %383, align 4
  %385 = fmul reassoc nsz arcp contract float %const_reg_fp32, %384, !spirv.Decorations !561
  %386 = ptrtoint ptr addrspace(1) %9 to i64
  %387 = add i64 %381, %386
  %388 = inttoptr i64 %387 to ptr addrspace(1)
  %389 = load i32, ptr addrspace(1) %388, align 4
  %390 = sitofp i32 %389 to float
  %391 = fmul reassoc nnan nsz arcp contract float %390, 5.100000e+02, !spirv.Decorations !563
  %392 = fsub reassoc nnan nsz arcp contract float %.lcssa, %391, !spirv.Decorations !563
  %393 = fmul reassoc nsz arcp contract float %385, %392, !spirv.Decorations !561
  %394 = shl i64 %43, 2
  %395 = add i64 %394, %379
  %396 = inttoptr i64 %395 to ptr addrspace(1)
  store float %393, ptr addrspace(1) %396, align 4
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
!286 = !{!"maxRegPressureSimd16", i32 0}
!287 = !{!"maxRegPressureSimd32", i32 0}
!288 = !{!"maxRegUniformPressure", i32 0}
!289 = !{!"maxRegNonUniformPressure", i32 0}
!290 = !{!"bestGuessSimd", i32 0}
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
!558 = !{float 2.500000e+00}
!559 = !{!557, !560}
!560 = !{i32 4470}
!561 = !{!562}
!562 = !{i32 40, i32 196620}
!563 = !{!564}
!564 = !{i32 40, i32 196621}

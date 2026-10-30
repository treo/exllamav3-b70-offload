; ------------------------------------------------
; OCL_asme875c6b1bc10fada_simd32_entry_0001.visa.ll
; ------------------------------------------------
; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL5splitRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE(ptr byval(%"class.sycl::_V1::range") align 8 %0, ptr byval(%class._ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_) align 8 %1, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %globalSize, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i64 %const_reg_qword, i32 %const_reg_dword, i8 %const_reg_byte, i8 %const_reg_byte1, i8 %const_reg_byte2, i8 %const_reg_byte3, i64 %const_reg_qword4, i64 %const_reg_qword5, i64 %const_reg_qword6, i64 %const_reg_qword7) #0 {
; BB0 :
  %3 = bitcast i64 %const_reg_qword to <2 x i32>		; visa id: 2
  %4 = extractelement <2 x i32> %3, i32 0		; visa id: 3
  %5 = extractelement <2 x i32> %3, i32 1		; visa id: 3
  %6 = extractelement <3 x i32> %globalOffset, i32 0		; visa id: 3
  %7 = extractelement <3 x i32> %enqueuedLocalSize, i32 0		; visa id: 3
  %8 = extractelement <8 x i32> %r0, i32 1		; visa id: 3
  %9 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %7, i32 0, i32 %8, i32 0)
  %10 = extractvalue { i32, i32 } %9, 0		; visa id: 3
  %11 = extractvalue { i32, i32 } %9, 1		; visa id: 3
  %12 = insertelement <2 x i32> undef, i32 %10, i32 0		; visa id: 10
  %13 = insertelement <2 x i32> %12, i32 %11, i32 1		; visa id: 11
  %14 = bitcast <2 x i32> %13 to i64		; visa id: 12
  %15 = zext i16 %localIdX to i64		; visa id: 14
  %16 = add nuw i64 %14, %15		; visa id: 15
  %17 = zext i32 %6 to i64		; visa id: 16
  %18 = add nuw i64 %16, %17		; visa id: 17
  %19 = bitcast i64 %18 to <2 x i32>		; visa id: 18
  %20 = extractelement <2 x i32> %19, i32 0		; visa id: 22
  %21 = extractelement <2 x i32> %19, i32 1		; visa id: 22
  %22 = icmp eq i32 %21, %5
  %23 = icmp ult i32 %20, %4		; visa id: 22
  %24 = and i1 %22, %23		; visa id: 23
  %25 = icmp ult i32 %21, %5
  %26 = or i1 %24, %25		; visa id: 25
  %27 = ashr i32 %const_reg_dword, 31		; visa id: 27
  %28 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %const_reg_dword, i32 %27, i32 640, i32 0)
  %29 = extractvalue { i32, i32 } %28, 0		; visa id: 28
  %30 = extractvalue { i32, i32 } %28, 1		; visa id: 28
  br i1 %26, label %.lr.ph.preheader, label %.._crit_edge_crit_edge, !stats.blockFrequency.digits !615, !stats.blockFrequency.scale !616		; visa id: 35

.._crit_edge_crit_edge:                           ; preds = %2
; BB:
  br label %._crit_edge, !stats.blockFrequency.digits !617, !stats.blockFrequency.scale !618

.lr.ph.preheader:                                 ; preds = %2
; BB2 :
  %31 = extractelement <3 x i32> %globalSize, i32 0		; visa id: 37
  %32 = insertelement <2 x i32> undef, i32 %29, i32 0		; visa id: 37
  %33 = insertelement <2 x i32> %32, i32 %30, i32 1		; visa id: 38
  %34 = bitcast <2 x i32> %33 to i64		; visa id: 39
  %35 = trunc i64 %34 to i32		; visa id: 41
  %36 = uitofp i64 %34 to double		; visa id: 42
  %37 = fptrunc double %36 to float		; visa id: 43
  %38 = fdiv float 1.000000e+00, %37		; visa id: 44
  %39 = fsub double 0.000000e+00, %36
  %40 = fpext float %38 to double		; visa id: 45
  %41 = call double @llvm.fma.f64(double %39, double %40, double 1.000000e+00) #4		; visa id: 46
  %42 = fadd double %41, 0xBCF0000000000000		; visa id: 48
  %43 = call double @llvm.fma.f64(double %40, double %42, double %40) #4		; visa id: 50
  %44 = and i32 %29, -128		; visa id: 51
  %tobool.i32 = icmp eq i32 %const_reg_dword, 0		; visa id: 52
  %45 = icmp sgt i32 %const_reg_dword, -1		; visa id: 53
  %46 = sext i32 %const_reg_dword to i64		; visa id: 54
  %47 = uitofp i64 %46 to double		; visa id: 55
  %48 = fptrunc double %47 to float		; visa id: 56
  %49 = fdiv float 1.000000e+00, %48		; visa id: 57
  %50 = fsub double 0.000000e+00, %47
  %51 = fpext float %49 to double		; visa id: 58
  %52 = call double @llvm.fma.f64(double %50, double %51, double 1.000000e+00) #4		; visa id: 59
  %53 = fadd double %52, 0xBCF0000000000000		; visa id: 60
  %54 = call double @llvm.fma.f64(double %51, double %53, double %51) #4		; visa id: 61
  %55 = zext i32 %31 to i64		; visa id: 62
  br label %.lr.ph, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618		; visa id: 65

.lr.ph:                                           ; preds = %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, %.lr.ph.preheader
; BB3 :
  %56 = phi i64 [ %239, %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge ], [ %18, %.lr.ph.preheader ]
  %57 = bitcast i64 %56 to <2 x i32>		; visa id: 66
  %58 = extractelement <2 x i32> %57, i32 1
  %59 = or i32 %30, %58		; visa id: 70
  %60 = icmp ult i32 %59, 1		; visa id: 72
  br i1 %60, label %61, label %79, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !620		; visa id: 73

61:                                               ; preds = %.lr.ph
; BB4 :
  br i1 %tobool.i32, label %.precompiled_u32divrem_sp.exit54_crit_edge, label %if.end.i33, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !621		; visa id: 75

.precompiled_u32divrem_sp.exit54_crit_edge:       ; preds = %61
; BB5 :
  br label %precompiled_u32divrem_sp.exit54, !stats.blockFrequency.digits !622, !stats.blockFrequency.scale !623		; visa id: 78

if.end.i33:                                       ; preds = %61
; BB6 :
  %62 = trunc nuw i64 %56 to i32		; visa id: 80
  %63 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %35)		; visa id: 81
  %conv.i34 = fptoui float %63 to i32		; visa id: 83
  %sub.i35 = sub i32 %35, %conv.i34		; visa id: 84
  %64 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %62)		; visa id: 85
  %div.i38 = fdiv float 1.000000e+00, %63, !fpmath !624		; visa id: 86
  %65 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i38, float 0xBE98000000000000, float %div.i38)		; visa id: 87
  %66 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %64, float %65)		; visa id: 88
  %conv3.i36 = fptoui float %64 to i32		; visa id: 89
  %sub4.i37 = sub i32 %62, %conv3.i36		; visa id: 90
  %conv8.i39 = fptoui float %66 to i32		; visa id: 91
  %67 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i35)		; visa id: 92
  %68 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i37)		; visa id: 93
  %69 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i39)		; visa id: 94
  %70 = fsub float 0.000000e+00, %63		; visa id: 95
  %71 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %70, float %69, float %64)		; visa id: 96
  %72 = fsub float 0.000000e+00, %67		; visa id: 97
  %73 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %72, float %69, float %68)		; visa id: 98
  %74 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %71, float %73)		; visa id: 99
  %75 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %65, float %74)		; visa id: 100
  %conv16.i42 = fptoui float %75 to i32		; visa id: 102
  %add.i43 = add i32 %conv16.i42, %conv8.i39		; visa id: 103
  %mul.i44 = mul i32 %add.i43, %35		; visa id: 104
  %sub17.i45 = sub i32 %62, %mul.i44		; visa id: 105
  %cmp.i46 = icmp uge i32 %sub17.i45, %35
  %76 = sext i1 %cmp.i46 to i32		; visa id: 106
  %77 = sub i32 0, %76
  %add19.i49 = add i32 %add.i43, %77		; visa id: 107
  br label %precompiled_u32divrem_sp.exit54, !stats.blockFrequency.digits !625, !stats.blockFrequency.scale !626		; visa id: 108

precompiled_u32divrem_sp.exit54:                  ; preds = %.precompiled_u32divrem_sp.exit54_crit_edge, %if.end.i33
; BB7 :
  %retval.0.i53 = phi i32 [ %add19.i49, %if.end.i33 ], [ -1, %.precompiled_u32divrem_sp.exit54_crit_edge ]
  %78 = zext i32 %retval.0.i53 to i64		; visa id: 109
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !621		; visa id: 110

79:                                               ; preds = %.lr.ph
; BB8 :
  %80 = extractelement <2 x i32> %57, i32 0		; visa id: 112
  %81 = bitcast i64 %56 to <2 x i32>		; visa id: 112
  %82 = extractelement <2 x i32> %81, i32 1		; visa id: 114
  %83 = uitofp i32 %82 to double		; visa id: 114
  %84 = fmul double %43, %83		; visa id: 115
  %85 = fptoui double %84 to i32		; visa id: 116
  %86 = mul i32 %85, %35		; visa id: 117
  %87 = sub i32 %82, %86		; visa id: 118
  %88 = trunc i64 %56 to i32		; visa id: 119
  %89 = uitofp i32 %87 to double		; visa id: 120
  %90 = uitofp i32 %88 to double		; visa id: 121
  %91 = call double @llvm.fma.f64(double %89, double 0x41F0000000000000, double %90) #4		; visa id: 122
  %92 = fmul double %43, %91		; visa id: 123
  %93 = fptoui double %92 to i64		; visa id: 124
  %94 = bitcast i64 %93 to <2 x i32>		; visa id: 125
  %95 = extractelement <2 x i32> %94, i32 0		; visa id: 127
  %96 = trunc i64 %93 to i32		; visa id: 127
  %97 = lshr i64 %93, 32		; visa id: 128
  %98 = bitcast i64 %97 to <2 x i32>		; visa id: 129
  %99 = extractelement <2 x i32> %98, i32 0		; visa id: 133
  %100 = extractelement <2 x i32> %98, i32 1		; visa id: 133
  %101 = bitcast i64 %93 to <2 x i32>		; visa id: 133
  %102 = extractelement <2 x i32> %101, i32 1		; visa id: 135
  %103 = icmp eq i32 %100, 0
  %104 = icmp eq i32 %99, 0		; visa id: 135
  %105 = and i1 %103, %104		; visa id: 136
  %106 = mul i32 %96, %30		; visa id: 138
  %107 = select i1 %105, i32 0, i32 %35		; visa id: 139
  %108 = add i32 %106, %107		; visa id: 140
  %109 = sub i32 %87, %108		; visa id: 141
  %110 = insertelement <2 x i32> undef, i32 %80, i32 0		; visa id: 142
  %111 = insertelement <2 x i32> %110, i32 %109, i32 1		; visa id: 143
  %112 = bitcast <2 x i32> %111 to i64		; visa id: 144
  %113 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %95, i32 0, i32 %44, i32 0)
  %114 = extractvalue { i32, i32 } %113, 0
  %115 = extractvalue { i32, i32 } %113, 1
  %116 = insertelement <2 x i32> undef, i32 %114, i32 0
  %117 = insertelement <2 x i32> %116, i32 %115, i32 1
  %118 = bitcast <2 x i32> %117 to i64		; visa id: 148
  %119 = sub i64 %112, %118		; visa id: 156
  %120 = bitcast i64 %119 to <2 x i32>		; visa id: 157
  %121 = extractelement <2 x i32> %120, i32 0		; visa id: 161
  %122 = extractelement <2 x i32> %120, i32 1		; visa id: 161
  %123 = add i32 %102, %85		; visa id: 161
  %124 = insertelement <2 x i32> undef, i32 %95, i32 0		; visa id: 162
  %125 = insertelement <2 x i32> %124, i32 %123, i32 1		; visa id: 163
  %126 = bitcast <2 x i32> %125 to i64		; visa id: 164
  %127 = icmp eq i32 %122, %30
  %128 = icmp uge i32 %121, %29		; visa id: 168
  %129 = and i1 %127, %128		; visa id: 169
  %130 = icmp ugt i32 %122, %30
  %131 = or i1 %129, %130		; visa id: 171
  %132 = sext i1 %131 to i64		; visa id: 173
  %133 = sub i64 0, %132
  %134 = add i64 %126, %133		; visa id: 175
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !621		; visa id: 176

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit54, %79
; BB9 :
  %135 = phi i64 [ %78, %precompiled_u32divrem_sp.exit54 ], [ %134, %79 ]
  %136 = trunc nuw nsw i64 %56 to i32		; visa id: 177
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %136, i32 -858993459)		; visa id: 178
  %q_appx30 = lshr i32 %q_appx, 9		; visa id: 179
  br i1 %45, label %137, label %152, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !620		; visa id: 180

137:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB10 :
  br i1 %tobool.i32, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !625, !stats.blockFrequency.scale !621		; visa id: 182

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %137
; BB11 :
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !627, !stats.blockFrequency.scale !626		; visa id: 185

if.end.i:                                         ; preds = %137
; BB12 :
  %138 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword)		; visa id: 187
  %conv.i = fptoui float %138 to i32		; visa id: 189
  %sub.i = sub i32 %const_reg_dword, %conv.i		; visa id: 190
  %139 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %q_appx30)		; visa id: 191
  %div.i = fdiv float 1.000000e+00, %138, !fpmath !624		; visa id: 192
  %140 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)		; visa id: 193
  %141 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %139, float %140)		; visa id: 194
  %conv3.i = fptoui float %139 to i32		; visa id: 195
  %sub4.i = sub i32 %q_appx30, %conv3.i		; visa id: 196
  %conv8.i = fptoui float %141 to i32		; visa id: 197
  %142 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)		; visa id: 198
  %143 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)		; visa id: 199
  %144 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)		; visa id: 200
  %145 = fsub float 0.000000e+00, %138		; visa id: 201
  %146 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %145, float %144, float %139)		; visa id: 202
  %147 = fsub float 0.000000e+00, %142		; visa id: 203
  %148 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %147, float %144, float %143)		; visa id: 204
  %149 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %146, float %148)		; visa id: 205
  %150 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %140, float %149)		; visa id: 206
  %conv16.i = fptoui float %150 to i32		; visa id: 208
  %add.i = add i32 %conv16.i, %conv8.i		; visa id: 209
  %mul.i = mul i32 %add.i, %const_reg_dword		; visa id: 210
  %sub17.i = sub i32 %q_appx30, %mul.i		; visa id: 211
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword		; visa id: 212
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword		; visa id: 213
  %sub21.i = sub i32 %sub17.i, %and20.i		; visa id: 214
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !628, !stats.blockFrequency.scale !626		; visa id: 215

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
; BB13 :
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %151 = zext i32 %storemerge.i to i64		; visa id: 216
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !625, !stats.blockFrequency.scale !621		; visa id: 217

152:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB14 :
  %153 = uitofp nneg i32 %q_appx30 to double		; visa id: 219
  %154 = fmul double %54, %153		; visa id: 220
  %155 = fptoui double %154 to i64		; visa id: 221
  %156 = bitcast i64 %155 to <2 x i32>		; visa id: 222
  %157 = extractelement <2 x i32> %156, i32 0		; visa id: 226
  %158 = extractelement <2 x i32> %156, i32 1		; visa id: 226
  %159 = trunc i64 %155 to i32		; visa id: 226
  %160 = icmp ult i32 %158, 1		; visa id: 227
  %161 = select i1 %160, i32 0, i32 %const_reg_dword		; visa id: 228
  %162 = sub i32 %159, %161		; visa id: 229
  %163 = insertelement <2 x i32> undef, i32 %q_appx30, i32 0		; visa id: 230
  %164 = insertelement <2 x i32> %163, i32 %162, i32 1		; visa id: 231
  %165 = bitcast <2 x i32> %164 to i64		; visa id: 232
  %166 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %157, i32 0, i32 %const_reg_dword, i32 0)
  %167 = extractvalue { i32, i32 } %166, 0
  %168 = extractvalue { i32, i32 } %166, 1
  %169 = insertelement <2 x i32> undef, i32 %167, i32 0
  %170 = insertelement <2 x i32> %169, i32 %168, i32 1
  %171 = bitcast <2 x i32> %170 to i64		; visa id: 236
  %172 = sub i64 %165, %171		; visa id: 244
  %173 = bitcast i64 %172 to <2 x i32>		; visa id: 245
  %174 = extractelement <2 x i32> %173, i32 0		; visa id: 249
  %175 = extractelement <2 x i32> %173, i32 1		; visa id: 249
  %176 = icmp eq i32 %175, %27
  %177 = icmp ult i32 %174, %const_reg_dword		; visa id: 249
  %178 = and i1 %176, %177		; visa id: 250
  %179 = icmp ult i32 %175, %27
  %180 = or i1 %178, %179		; visa id: 252
  %181 = select i1 %180, i32 0, i32 %const_reg_dword		; visa id: 254
  %182 = select i1 %180, i32 0, i32 %27		; visa id: 255
  %183 = insertelement <2 x i32> undef, i32 %181, i32 0		; visa id: 256
  %184 = insertelement <2 x i32> %183, i32 %182, i32 1		; visa id: 257
  %185 = bitcast <2 x i32> %184 to i64		; visa id: 258
  %186 = sub i64 %172, %185		; visa id: 262
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !622, !stats.blockFrequency.scale !626		; visa id: 263

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %152
; BB15 :
  %187 = phi i64 [ %151, %precompiled_u32divrem_sp.exit ], [ %186, %152 ]
  %.neg = mul nsw i32 %q_appx30, -640
  %188 = add nsw i32 %.neg, %136		; visa id: 264
  %189 = zext i32 %188 to i64		; visa id: 265
  %190 = shl nuw nsw i64 %189, 2		; visa id: 266
  %191 = add i64 %const_reg_qword4, %190		; visa id: 267
  %192 = shl nuw nsw i64 %135, 4, !spirv.Decorations !629		; visa id: 268
  %193 = add nuw nsw i64 %192, %187, !spirv.Decorations !629		; visa id: 269
  %194 = bitcast i64 %193 to <2 x i32>		; visa id: 270
  %195 = extractelement <2 x i32> %194, i32 0		; visa id: 274
  %196 = extractelement <2 x i32> %194, i32 1		; visa id: 274
  %197 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %195, i32 %196, i32 2560, i32 0)
  %198 = extractvalue { i32, i32 } %197, 0
  %199 = extractvalue { i32, i32 } %197, 1
  %200 = insertelement <2 x i32> undef, i32 %198, i32 0
  %201 = insertelement <2 x i32> %200, i32 %199, i32 1
  %202 = bitcast <2 x i32> %201 to i64		; visa id: 274
  %203 = add i64 %191, %202		; visa id: 282
  %204 = inttoptr i64 %203 to ptr addrspace(1)		; visa id: 283
  %205 = load i32, ptr addrspace(1) %204, align 4		; visa id: 283
  %206 = add i64 %203, 409600
  %207 = inttoptr i64 %206 to ptr addrspace(1)
  %208 = load i32, ptr addrspace(1) %207, align 4		; visa id: 284
  %209 = shl i64 %187, 2		; visa id: 285
  %210 = add i64 %const_reg_qword6, %209		; visa id: 286
  %211 = inttoptr i64 %210 to ptr addrspace(1)		; visa id: 287
  %212 = load float, ptr addrspace(1) %211, align 4		; visa id: 287
  %213 = add i64 %const_reg_qword7, %209		; visa id: 288
  %214 = inttoptr i64 %213 to ptr addrspace(1)		; visa id: 289
  %215 = load i32, ptr addrspace(1) %214, align 4		; visa id: 289
  %216 = add nsw i32 %205, %208, !spirv.Decorations !632		; visa id: 290
  %217 = fmul reassoc nsz arcp contract float %212, 0x3F7B717580000000, !spirv.Decorations !633		; visa id: 291
  %218 = sitofp i32 %216 to float		; visa id: 292
  %219 = sitofp i32 %215 to float		; visa id: 293
  %220 = fmul reassoc nnan nsz arcp contract float %219, 5.100000e+02, !spirv.Decorations !635
  %221 = fsub reassoc nnan nsz arcp contract float %218, %220, !spirv.Decorations !635		; visa id: 294
  %222 = fmul reassoc nsz arcp contract float %217, %221, !spirv.Decorations !633		; visa id: 295
  %223 = shl i64 %56, 2		; visa id: 296
  %224 = add i64 %const_reg_qword5, %223		; visa id: 297
  %225 = inttoptr i64 %224 to ptr addrspace(1)		; visa id: 298
  store float %222, ptr addrspace(1) %225, align 4		; visa id: 298
  %226 = add nuw nsw i64 %56, %55		; visa id: 299
  %227 = bitcast i64 %226 to <2 x i32>		; visa id: 300
  %228 = extractelement <2 x i32> %227, i32 0		; visa id: 304
  %229 = extractelement <2 x i32> %227, i32 1		; visa id: 304
  %230 = icmp eq i32 %229, %5
  %231 = icmp ult i32 %228, %4		; visa id: 304
  %232 = and i1 %230, %231		; visa id: 305
  %233 = icmp ult i32 %229, %5
  %234 = or i1 %232, %233		; visa id: 307
  br i1 %234, label %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, label %._crit_edge.loopexit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !620		; visa id: 309

._crit_edge.loopexit:                             ; preds = %__igcbuiltin_u64_urem_dp.exit
; BB:
  br label %._crit_edge, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618

__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge:   ; preds = %__igcbuiltin_u64_urem_dp.exit
; BB17 :
  %235 = select i1 %234, i32 %228, i32 %20		; visa id: 311
  %236 = select i1 %234, i32 %229, i32 %21		; visa id: 312
  %237 = insertelement <2 x i32> undef, i32 %235, i32 0		; visa id: 313
  %238 = insertelement <2 x i32> %237, i32 %236, i32 1		; visa id: 314
  %239 = bitcast <2 x i32> %238 to i64		; visa id: 315
  br label %.lr.ph, !stats.blockFrequency.digits !637, !stats.blockFrequency.scale !620		; visa id: 319

._crit_edge:                                      ; preds = %.._crit_edge_crit_edge, %._crit_edge.loopexit
; BB18 :
  ret void, !stats.blockFrequency.digits !615, !stats.blockFrequency.scale !616		; visa id: 321
}

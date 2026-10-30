; ------------------------------------------------
; OCL_asme875c6b1bc10fada_simd32_entry_0003.visa.ll
; ------------------------------------------------
; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL4pairRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE(ptr byval(%"class.sycl::_V1::range") align 8 %0, ptr byval(%class._ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_) align 8 %1, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %globalSize, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i64 %const_reg_qword, i64 %const_reg_qword1, i64 %const_reg_qword2, i64 %const_reg_qword3, i64 %const_reg_qword4, i64 %const_reg_qword5, i32 %const_reg_dword, i8 %const_reg_byte, i8 %const_reg_byte6, i8 %const_reg_byte7, i8 %const_reg_byte8, i64 %const_reg_qword9, i64 %const_reg_qword10) #0 {
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
  %31 = bitcast i64 %const_reg_qword1 to <2 x i32>		; visa id: 37
  %32 = extractelement <2 x i32> %31, i32 0		; visa id: 38
  %33 = extractelement <2 x i32> %31, i32 1		; visa id: 38
  %34 = bitcast i64 %const_reg_qword2 to <2 x i32>		; visa id: 38
  %35 = extractelement <2 x i32> %34, i32 0		; visa id: 39
  %36 = extractelement <2 x i32> %34, i32 1		; visa id: 39
  %37 = bitcast i64 %const_reg_qword3 to <2 x i32>		; visa id: 39
  %38 = extractelement <2 x i32> %37, i32 0		; visa id: 40
  %39 = extractelement <2 x i32> %37, i32 1		; visa id: 40
  %40 = bitcast i64 %const_reg_qword4 to <2 x i32>		; visa id: 40
  %41 = extractelement <2 x i32> %40, i32 0		; visa id: 41
  %42 = extractelement <2 x i32> %40, i32 1		; visa id: 41
  %43 = bitcast i64 %const_reg_qword5 to <2 x i32>		; visa id: 41
  %44 = extractelement <2 x i32> %43, i32 0		; visa id: 42
  %45 = extractelement <2 x i32> %43, i32 1		; visa id: 42
  %46 = extractelement <3 x i32> %globalSize, i32 0		; visa id: 42
  %47 = insertelement <2 x i32> undef, i32 %29, i32 0		; visa id: 42
  %48 = insertelement <2 x i32> %47, i32 %30, i32 1		; visa id: 43
  %49 = bitcast <2 x i32> %48 to i64		; visa id: 44
  %50 = trunc i64 %49 to i32		; visa id: 46
  %51 = uitofp i64 %49 to double		; visa id: 47
  %52 = fptrunc double %51 to float		; visa id: 48
  %53 = fdiv float 1.000000e+00, %52		; visa id: 49
  %54 = fsub double 0.000000e+00, %51
  %55 = fpext float %53 to double		; visa id: 50
  %56 = call double @llvm.fma.f64(double %54, double %55, double 1.000000e+00) #4		; visa id: 51
  %57 = fadd double %56, 0xBCF0000000000000		; visa id: 53
  %58 = call double @llvm.fma.f64(double %55, double %57, double %55) #4		; visa id: 55
  %59 = and i32 %29, -128		; visa id: 56
  %tobool.i37 = icmp eq i32 %const_reg_dword, 0		; visa id: 57
  %60 = sext i32 %const_reg_dword to i64		; visa id: 58
  %61 = uitofp i64 %60 to double		; visa id: 59
  %62 = fptrunc double %61 to float		; visa id: 60
  %63 = fdiv float 1.000000e+00, %62		; visa id: 61
  %64 = fsub double 0.000000e+00, %61
  %65 = fpext float %63 to double		; visa id: 62
  %66 = call double @llvm.fma.f64(double %64, double %65, double 1.000000e+00) #4		; visa id: 63
  %67 = fadd double %66, 0xBCF0000000000000		; visa id: 64
  %68 = call double @llvm.fma.f64(double %65, double %67, double %65) #4		; visa id: 65
  %isneg = icmp slt i32 %const_reg_dword, 0		; visa id: 66
  %69 = zext i32 %46 to i64		; visa id: 67
  br label %.lr.ph, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618		; visa id: 70

.lr.ph:                                           ; preds = %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, %.lr.ph.preheader
; BB3 :
  %70 = phi i64 [ %347, %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge ], [ %18, %.lr.ph.preheader ]
  %71 = bitcast i64 %70 to <2 x i32>		; visa id: 71
  %72 = extractelement <2 x i32> %71, i32 0		; visa id: 75
  %73 = extractelement <2 x i32> %71, i32 1		; visa id: 75
  %74 = icmp eq i32 %73, %33
  %75 = icmp ult i32 %72, %32		; visa id: 75
  %76 = and i1 %74, %75		; visa id: 76
  %77 = icmp ult i32 %73, %33
  %78 = or i1 %76, %77		; visa id: 78
  %79 = select i1 %78, i32 %35, i32 %38		; visa id: 80
  %80 = select i1 %78, i32 %36, i32 %39		; visa id: 81
  %81 = insertelement <2 x i32> undef, i32 %79, i32 0		; visa id: 82
  %82 = insertelement <2 x i32> %81, i32 %80, i32 1		; visa id: 83
  %83 = bitcast <2 x i32> %82 to i64		; visa id: 84
  %84 = select i1 %78, i32 0, i32 %32		; visa id: 88
  %85 = select i1 %78, i32 0, i32 %33		; visa id: 89
  %86 = insertelement <2 x i32> undef, i32 %84, i32 0		; visa id: 90
  %87 = insertelement <2 x i32> %86, i32 %85, i32 1		; visa id: 91
  %88 = bitcast <2 x i32> %87 to i64		; visa id: 92
  %89 = sub nsw i64 %70, %88, !spirv.Decorations !620		; visa id: 96
  %90 = bitcast i64 %89 to <2 x i32>		; visa id: 97
  %91 = extractelement <2 x i32> %90, i32 0		; visa id: 101
  %92 = extractelement <2 x i32> %90, i32 1		; visa id: 101
  %93 = or i32 %30, %92		; visa id: 101
  %94 = icmp ult i32 %93, 1		; visa id: 103
  br i1 %94, label %95, label %113, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !622		; visa id: 104

95:                                               ; preds = %.lr.ph
; BB4 :
  br i1 %tobool.i37, label %.precompiled_u32divrem_sp.exit59_crit_edge, label %if.end.i38, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !623		; visa id: 106

.precompiled_u32divrem_sp.exit59_crit_edge:       ; preds = %95
; BB5 :
  br label %precompiled_u32divrem_sp.exit59, !stats.blockFrequency.digits !624, !stats.blockFrequency.scale !625		; visa id: 109

if.end.i38:                                       ; preds = %95
; BB6 :
  %96 = trunc nuw i64 %89 to i32		; visa id: 111
  %97 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %50)		; visa id: 112
  %conv.i39 = fptoui float %97 to i32		; visa id: 114
  %sub.i40 = sub i32 %50, %conv.i39		; visa id: 115
  %98 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %96)		; visa id: 116
  %div.i43 = fdiv float 1.000000e+00, %97, !fpmath !626		; visa id: 117
  %99 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i43, float 0xBE98000000000000, float %div.i43)		; visa id: 118
  %100 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %98, float %99)		; visa id: 119
  %conv3.i41 = fptoui float %98 to i32		; visa id: 120
  %sub4.i42 = sub i32 %96, %conv3.i41		; visa id: 121
  %conv8.i44 = fptoui float %100 to i32		; visa id: 122
  %101 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i40)		; visa id: 123
  %102 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i42)		; visa id: 124
  %103 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i44)		; visa id: 125
  %104 = fsub float 0.000000e+00, %97		; visa id: 126
  %105 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %104, float %103, float %98)		; visa id: 127
  %106 = fsub float 0.000000e+00, %101		; visa id: 128
  %107 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %106, float %103, float %102)		; visa id: 129
  %108 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %105, float %107)		; visa id: 130
  %109 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %99, float %108)		; visa id: 131
  %conv16.i47 = fptoui float %109 to i32		; visa id: 133
  %add.i48 = add i32 %conv16.i47, %conv8.i44		; visa id: 134
  %mul.i49 = mul i32 %add.i48, %50		; visa id: 135
  %sub17.i50 = sub i32 %96, %mul.i49		; visa id: 136
  %cmp.i51 = icmp uge i32 %sub17.i50, %50
  %110 = sext i1 %cmp.i51 to i32		; visa id: 137
  %111 = sub i32 0, %110
  %add19.i54 = add i32 %add.i48, %111		; visa id: 138
  br label %precompiled_u32divrem_sp.exit59, !stats.blockFrequency.digits !627, !stats.blockFrequency.scale !628		; visa id: 139

precompiled_u32divrem_sp.exit59:                  ; preds = %.precompiled_u32divrem_sp.exit59_crit_edge, %if.end.i38
; BB7 :
  %retval.0.i58 = phi i32 [ %add19.i54, %if.end.i38 ], [ -1, %.precompiled_u32divrem_sp.exit59_crit_edge ]
  %112 = zext i32 %retval.0.i58 to i64		; visa id: 140
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !623		; visa id: 141

113:                                              ; preds = %.lr.ph
; BB8 :
  %114 = bitcast i64 %89 to <2 x i32>		; visa id: 143
  %115 = extractelement <2 x i32> %114, i32 1		; visa id: 145
  %116 = uitofp i32 %115 to double		; visa id: 145
  %117 = fmul double %58, %116		; visa id: 146
  %118 = fptoui double %117 to i32		; visa id: 147
  %119 = mul i32 %118, %50		; visa id: 148
  %120 = sub i32 %115, %119		; visa id: 149
  %121 = trunc i64 %89 to i32		; visa id: 150
  %122 = uitofp i32 %120 to double		; visa id: 151
  %123 = uitofp i32 %121 to double		; visa id: 152
  %124 = call double @llvm.fma.f64(double %122, double 0x41F0000000000000, double %123) #4		; visa id: 153
  %125 = fmul double %58, %124		; visa id: 154
  %126 = fptoui double %125 to i64		; visa id: 155
  %127 = bitcast i64 %126 to <2 x i32>		; visa id: 156
  %128 = extractelement <2 x i32> %127, i32 0		; visa id: 158
  %129 = trunc i64 %126 to i32		; visa id: 158
  %130 = lshr i64 %126, 32		; visa id: 159
  %131 = bitcast i64 %130 to <2 x i32>		; visa id: 160
  %132 = extractelement <2 x i32> %131, i32 0		; visa id: 164
  %133 = extractelement <2 x i32> %131, i32 1		; visa id: 164
  %134 = bitcast i64 %126 to <2 x i32>		; visa id: 164
  %135 = extractelement <2 x i32> %134, i32 1		; visa id: 166
  %136 = icmp eq i32 %133, 0
  %137 = icmp eq i32 %132, 0		; visa id: 166
  %138 = and i1 %136, %137		; visa id: 167
  %139 = mul i32 %129, %30		; visa id: 169
  %140 = select i1 %138, i32 0, i32 %50		; visa id: 170
  %141 = add i32 %139, %140		; visa id: 171
  %142 = sub i32 %120, %141		; visa id: 172
  %143 = insertelement <2 x i32> undef, i32 %91, i32 0		; visa id: 173
  %144 = insertelement <2 x i32> %143, i32 %142, i32 1		; visa id: 174
  %145 = bitcast <2 x i32> %144 to i64		; visa id: 175
  %146 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %128, i32 0, i32 %59, i32 0)
  %147 = extractvalue { i32, i32 } %146, 0
  %148 = extractvalue { i32, i32 } %146, 1
  %149 = insertelement <2 x i32> undef, i32 %147, i32 0
  %150 = insertelement <2 x i32> %149, i32 %148, i32 1
  %151 = bitcast <2 x i32> %150 to i64		; visa id: 179
  %152 = sub i64 %145, %151		; visa id: 187
  %153 = bitcast i64 %152 to <2 x i32>		; visa id: 188
  %154 = extractelement <2 x i32> %153, i32 0		; visa id: 192
  %155 = extractelement <2 x i32> %153, i32 1		; visa id: 192
  %156 = add i32 %135, %118		; visa id: 192
  %157 = insertelement <2 x i32> undef, i32 %128, i32 0		; visa id: 193
  %158 = insertelement <2 x i32> %157, i32 %156, i32 1		; visa id: 194
  %159 = bitcast <2 x i32> %158 to i64		; visa id: 195
  %160 = icmp eq i32 %155, %30
  %161 = icmp uge i32 %154, %29		; visa id: 199
  %162 = and i1 %160, %161		; visa id: 200
  %163 = icmp ugt i32 %155, %30
  %164 = or i1 %162, %163		; visa id: 202
  %165 = sext i1 %164 to i64		; visa id: 204
  %166 = sub i64 0, %165
  %167 = add i64 %159, %166		; visa id: 206
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !623		; visa id: 207

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit59, %113
; BB9 :
  %168 = phi i64 [ %112, %precompiled_u32divrem_sp.exit59 ], [ %167, %113 ]
  %169 = icmp ult i32 %92, 1		; visa id: 208
  br i1 %169, label %udiv_pow2_64b_as_32b, label %udiv_pow2_64b, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !622		; visa id: 209

udiv_pow2_64b:                                    ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB10 :
  %u.hi32 = lshr i64 %89, 32		; visa id: 211
  %170 = bitcast i64 %u.hi32 to <2 x i32>		; visa id: 212
  %171 = extractelement <2 x i32> %170, i32 0		; visa id: 216
  %172 = extractelement <2 x i32> %170, i32 1		; visa id: 216
  %173 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %91, i32 0, i32 -858993459, i32 0)
  %174 = extractvalue { i32, i32 } %173, 0
  %175 = extractvalue { i32, i32 } %173, 1
  %176 = insertelement <2 x i32> undef, i32 %174, i32 0
  %177 = insertelement <2 x i32> %176, i32 %175, i32 1
  %178 = bitcast <2 x i32> %177 to i64		; visa id: 216
  %179 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %171, i32 %172, i32 -858993459, i32 0)
  %180 = extractvalue { i32, i32 } %179, 0
  %181 = extractvalue { i32, i32 } %179, 1
  %182 = insertelement <2 x i32> undef, i32 %180, i32 0
  %183 = insertelement <2 x i32> %182, i32 %181, i32 1
  %184 = bitcast <2 x i32> %183 to i64		; visa id: 224
  %w0.lo32 = lshr i64 %178, 32		; visa id: 232
  %t = add nuw i64 %184, %w0.lo32		; visa id: 233
  %185 = bitcast i64 %t to <2 x i32>		; visa id: 234
  %186 = extractelement <2 x i32> %185, i32 0		; visa id: 236
  %187 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %91, i32 0, i32 -858993460, i32 0)
  %188 = extractvalue { i32, i32 } %187, 0
  %189 = extractvalue { i32, i32 } %187, 1
  %190 = insertelement <2 x i32> undef, i32 %188, i32 0
  %191 = insertelement <2 x i32> %190, i32 %189, i32 1
  %192 = bitcast <2 x i32> %191 to i64		; visa id: 236
  %193 = insertelement <2 x i32> undef, i32 %186, i32 0		; visa id: 244
  %194 = insertelement <2 x i32> %193, i32 0, i32 1		; visa id: 245
  %195 = bitcast <2 x i32> %194 to i64		; visa id: 246
  %w1 = add nuw i64 %192, %195		; visa id: 250
  %196 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %171, i32 %172, i32 -858993460, i32 0)
  %197 = extractvalue { i32, i32 } %196, 0
  %198 = extractvalue { i32, i32 } %196, 1
  %199 = insertelement <2 x i32> undef, i32 %197, i32 0
  %200 = insertelement <2 x i32> %199, i32 %198, i32 1
  %201 = bitcast <2 x i32> %200 to i64		; visa id: 251
  %t.hi32 = lshr i64 %t, 32		; visa id: 259
  %202 = add nuw i64 %201, %t.hi32		; visa id: 260
  %w1.lo32 = lshr i64 %w1, 32		; visa id: 261
  %uv = add nuw i64 %202, %w1.lo32		; visa id: 262
  %q_appx35 = lshr i64 %uv, 9		; visa id: 263
  br label %205, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !623		; visa id: 264

udiv_pow2_64b_as_32b:                             ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB11 :
  %203 = trunc nuw i64 %89 to i32		; visa id: 266
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %203, i32 -858993459)		; visa id: 267
  %q_appx34 = lshr i32 %q_appx, 9		; visa id: 268
  %204 = zext nneg i32 %q_appx34 to i64		; visa id: 269
  br label %205, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !623		; visa id: 270

205:                                              ; preds = %udiv_pow2_64b, %udiv_pow2_64b_as_32b
; BB12 :
  %206 = phi i64 [ %204, %udiv_pow2_64b_as_32b ], [ %q_appx35, %udiv_pow2_64b ]
  %207 = bitcast i64 %206 to <2 x i32>		; visa id: 271
  %208 = extractelement <2 x i32> %207, i32 0		; visa id: 275
  %209 = extractelement <2 x i32> %207, i32 1		; visa id: 275
  %210 = or i32 %209, %27		; visa id: 275
  %211 = icmp ult i32 %210, 1		; visa id: 277
  br i1 %211, label %212, label %228, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !622		; visa id: 278

212:                                              ; preds = %205
; BB13 :
  br i1 %tobool.i37, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !623		; visa id: 280

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %212
; BB14 :
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !624, !stats.blockFrequency.scale !625		; visa id: 283

if.end.i:                                         ; preds = %212
; BB15 :
  %213 = trunc nuw i64 %206 to i32		; visa id: 285
  %214 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword)		; visa id: 286
  %conv.i = fptoui float %214 to i32		; visa id: 288
  %sub.i = sub i32 %const_reg_dword, %conv.i		; visa id: 289
  %215 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %213)		; visa id: 290
  %div.i = fdiv float 1.000000e+00, %214, !fpmath !626		; visa id: 291
  %216 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)		; visa id: 292
  %217 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %215, float %216)		; visa id: 293
  %conv3.i = fptoui float %215 to i32		; visa id: 294
  %sub4.i = sub i32 %213, %conv3.i		; visa id: 295
  %conv8.i = fptoui float %217 to i32		; visa id: 296
  %218 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)		; visa id: 297
  %219 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)		; visa id: 298
  %220 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)		; visa id: 299
  %221 = fsub float 0.000000e+00, %214		; visa id: 300
  %222 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %221, float %220, float %215)		; visa id: 301
  %223 = fsub float 0.000000e+00, %218		; visa id: 302
  %224 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %223, float %220, float %219)		; visa id: 303
  %225 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %222, float %224)		; visa id: 304
  %226 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %216, float %225)		; visa id: 305
  %conv16.i = fptoui float %226 to i32		; visa id: 307
  %add.i = add i32 %conv16.i, %conv8.i		; visa id: 308
  %mul.i = mul i32 %add.i, %const_reg_dword		; visa id: 309
  %sub17.i = sub i32 %213, %mul.i		; visa id: 310
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword		; visa id: 311
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword		; visa id: 312
  %sub21.i = sub i32 %sub17.i, %and20.i		; visa id: 313
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !627, !stats.blockFrequency.scale !628		; visa id: 314

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
; BB16 :
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %227 = zext i32 %storemerge.i to i64		; visa id: 315
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !623		; visa id: 316

228:                                              ; preds = %205
; BB17 :
  %229 = bitcast i64 %206 to <2 x i32>		; visa id: 318
  %230 = extractelement <2 x i32> %229, i32 1		; visa id: 320
  %231 = uitofp nneg i32 %230 to double		; visa id: 320
  %232 = fmul double %68, %231		; visa id: 321
  %233 = fptoui double %232 to i32		; visa id: 322
  %234 = mul i32 %const_reg_dword, %233		; visa id: 323
  %235 = sub i32 %230, %234		; visa id: 324
  %236 = trunc i64 %206 to i32		; visa id: 325
  %237 = uitofp i32 %235 to double		; visa id: 326
  %238 = uitofp i32 %236 to double		; visa id: 327
  %239 = call double @llvm.fma.f64(double %237, double 0x41F0000000000000, double %238) #4		; visa id: 328
  %240 = fmul double %68, %239		; visa id: 329
  %241 = fptoui double %240 to i64		; visa id: 330
  %242 = bitcast i64 %241 to <2 x i32>		; visa id: 331
  %243 = extractelement <2 x i32> %242, i32 0		; visa id: 335
  %244 = extractelement <2 x i32> %242, i32 1		; visa id: 335
  %245 = trunc i64 %241 to i32		; visa id: 335
  %.neg60 = select i1 %isneg, i32 %245, i32 0		; visa id: 336
  %246 = icmp ult i32 %244, 1		; visa id: 337
  %247 = select i1 %246, i32 0, i32 %const_reg_dword		; visa id: 338
  %248 = sub i32 %235, %247
  %249 = add i32 %.neg60, %248		; visa id: 339
  %250 = insertelement <2 x i32> undef, i32 %208, i32 0		; visa id: 340
  %251 = insertelement <2 x i32> %250, i32 %249, i32 1		; visa id: 341
  %252 = bitcast <2 x i32> %251 to i64		; visa id: 342
  %253 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %243, i32 0, i32 %const_reg_dword, i32 0)
  %254 = extractvalue { i32, i32 } %253, 0
  %255 = extractvalue { i32, i32 } %253, 1
  %256 = insertelement <2 x i32> undef, i32 %254, i32 0
  %257 = insertelement <2 x i32> %256, i32 %255, i32 1
  %258 = bitcast <2 x i32> %257 to i64		; visa id: 346
  %259 = sub i64 %252, %258		; visa id: 354
  %260 = bitcast i64 %259 to <2 x i32>		; visa id: 355
  %261 = extractelement <2 x i32> %260, i32 0		; visa id: 359
  %262 = extractelement <2 x i32> %260, i32 1		; visa id: 359
  %263 = icmp eq i32 %262, %27
  %264 = icmp ult i32 %261, %const_reg_dword		; visa id: 359
  %265 = and i1 %263, %264		; visa id: 360
  %266 = icmp ult i32 %262, %27
  %267 = or i1 %265, %266		; visa id: 362
  %268 = select i1 %267, i32 0, i32 %const_reg_dword		; visa id: 364
  %269 = select i1 %267, i32 0, i32 %27		; visa id: 365
  %270 = insertelement <2 x i32> undef, i32 %268, i32 0		; visa id: 366
  %271 = insertelement <2 x i32> %270, i32 %269, i32 1		; visa id: 367
  %272 = bitcast <2 x i32> %271 to i64		; visa id: 368
  %273 = sub i64 %259, %272		; visa id: 372
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !623		; visa id: 373

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %228
; BB18 :
  %274 = phi i64 [ %227, %precompiled_u32divrem_sp.exit ], [ %273, %228 ]
  %275 = bitcast i64 %168 to <2 x i32>		; visa id: 374
  %276 = extractelement <2 x i32> %275, i32 0		; visa id: 376
  %277 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %276, i32 1
  %278 = bitcast <2 x i32> %277 to i64		; visa id: 376
  %279 = bitcast i64 %274 to <2 x i32>		; visa id: 377
  %280 = extractelement <2 x i32> %279, i32 0		; visa id: 379
  %281 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %280, i32 1
  %282 = bitcast <2 x i32> %281 to i64		; visa id: 379
  %283 = ashr exact i64 %282, 32		; visa id: 380
  %284 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %208, i32 %209, i32 -2560, i32 -1)
  %285 = extractvalue { i32, i32 } %284, 0
  %286 = extractvalue { i32, i32 } %284, 1
  %287 = insertelement <2 x i32> undef, i32 %285, i32 0
  %288 = insertelement <2 x i32> %287, i32 %286, i32 1
  %289 = bitcast <2 x i32> %288 to i64		; visa id: 381
  %290 = add i64 %83, %289		; visa id: 389
  %291 = shl i64 %89, 2		; visa id: 390
  %292 = add i64 %290, %291		; visa id: 391
  %293 = ashr exact i64 %278, 28		; visa id: 392
  %294 = add nsw i64 %293, %283, !spirv.Decorations !620		; visa id: 393
  %295 = bitcast i64 %294 to <2 x i32>		; visa id: 394
  %296 = extractelement <2 x i32> %295, i32 0		; visa id: 398
  %297 = extractelement <2 x i32> %295, i32 1		; visa id: 398
  %298 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %296, i32 %297, i32 2560, i32 0)
  %299 = extractvalue { i32, i32 } %298, 0
  %300 = extractvalue { i32, i32 } %298, 1
  %301 = insertelement <2 x i32> undef, i32 %299, i32 0
  %302 = insertelement <2 x i32> %301, i32 %300, i32 1
  %303 = bitcast <2 x i32> %302 to i64		; visa id: 398
  %304 = add i64 %292, %303		; visa id: 406
  %305 = inttoptr i64 %304 to ptr addrspace(4)		; visa id: 407
  %306 = addrspacecast ptr addrspace(4) %305 to ptr addrspace(1)		; visa id: 407
  %307 = load i32, ptr addrspace(1) %306, align 4		; visa id: 408
  %308 = add i64 %304, 409600		; visa id: 409
  %309 = inttoptr i64 %308 to ptr addrspace(4)		; visa id: 410
  %310 = addrspacecast ptr addrspace(4) %309 to ptr addrspace(1)		; visa id: 410
  %311 = load i32, ptr addrspace(1) %310, align 4		; visa id: 411
  %312 = ashr exact i64 %282, 30		; visa id: 412
  %313 = add i64 %const_reg_qword9, %312		; visa id: 413
  %314 = inttoptr i64 %313 to ptr addrspace(1)		; visa id: 414
  %315 = load float, ptr addrspace(1) %314, align 4		; visa id: 414
  %316 = add i64 %const_reg_qword10, %312		; visa id: 415
  %317 = inttoptr i64 %316 to ptr addrspace(1)		; visa id: 416
  %318 = load i32, ptr addrspace(1) %317, align 4		; visa id: 416
  %319 = add nsw i32 %307, %311, !spirv.Decorations !620		; visa id: 417
  %320 = select i1 %78, i32 %41, i32 %44		; visa id: 418
  %321 = select i1 %78, i32 %42, i32 %45		; visa id: 419
  %322 = insertelement <2 x i32> undef, i32 %320, i32 0		; visa id: 420
  %323 = insertelement <2 x i32> %322, i32 %321, i32 1		; visa id: 421
  %324 = bitcast <2 x i32> %323 to i64		; visa id: 422
  %325 = fmul reassoc nsz arcp contract float %315, 0x3F7B717580000000, !spirv.Decorations !629		; visa id: 426
  %326 = sitofp i32 %319 to float		; visa id: 427
  %327 = sitofp i32 %318 to float		; visa id: 428
  %328 = fmul reassoc nnan nsz arcp contract float %327, 5.100000e+02, !spirv.Decorations !631
  %329 = fsub reassoc nnan nsz arcp contract float %326, %328, !spirv.Decorations !631		; visa id: 429
  %330 = fmul reassoc nsz arcp contract float %325, %329, !spirv.Decorations !629		; visa id: 430
  %331 = add i64 %324, %291		; visa id: 431
  %332 = inttoptr i64 %331 to ptr addrspace(4)		; visa id: 432
  %333 = addrspacecast ptr addrspace(4) %332 to ptr addrspace(1)		; visa id: 432
  store float %330, ptr addrspace(1) %333, align 4		; visa id: 433
  %334 = add nuw nsw i64 %70, %69		; visa id: 434
  %335 = bitcast i64 %334 to <2 x i32>		; visa id: 435
  %336 = extractelement <2 x i32> %335, i32 0		; visa id: 439
  %337 = extractelement <2 x i32> %335, i32 1		; visa id: 439
  %338 = icmp eq i32 %337, %5
  %339 = icmp ult i32 %336, %4		; visa id: 439
  %340 = and i1 %338, %339		; visa id: 440
  %341 = icmp ult i32 %337, %5
  %342 = or i1 %340, %341		; visa id: 442
  br i1 %342, label %__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge, label %._crit_edge.loopexit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !622		; visa id: 444

._crit_edge.loopexit:                             ; preds = %__igcbuiltin_u64_urem_dp.exit
; BB:
  br label %._crit_edge, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618

__igcbuiltin_u64_urem_dp.exit..lr.ph_crit_edge:   ; preds = %__igcbuiltin_u64_urem_dp.exit
; BB20 :
  %343 = select i1 %342, i32 %336, i32 %20		; visa id: 446
  %344 = select i1 %342, i32 %337, i32 %21		; visa id: 447
  %345 = insertelement <2 x i32> undef, i32 %343, i32 0		; visa id: 448
  %346 = insertelement <2 x i32> %345, i32 %344, i32 1		; visa id: 449
  %347 = bitcast <2 x i32> %346 to i64		; visa id: 450
  br label %.lr.ph, !stats.blockFrequency.digits !633, !stats.blockFrequency.scale !622		; visa id: 454

._crit_edge:                                      ; preds = %.._crit_edge_crit_edge, %._crit_edge.loopexit
; BB21 :
  ret void, !stats.blockFrequency.digits !615, !stats.blockFrequency.scale !616		; visa id: 456
}

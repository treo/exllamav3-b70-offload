; ------------------------------------------------
; OCL_asme875c6b1bc10fada_simd32_entry_0004.visa.ll
; ------------------------------------------------
; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_(i64 %0, ptr addrspace(1) align 4 %1, ptr addrspace(1) align 4 %2, ptr addrspace(1) align 4 %3, ptr addrspace(1) align 4 %4, i32 %5, ptr addrspace(1) align 4 %6, ptr addrspace(1) align 4 %7, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i32 %bufferOffset, i32 %bufferOffset1, i32 %bufferOffset2, i32 %bufferOffset3, i32 %bufferOffset4, i32 %bufferOffset5, i32 %bindlessOffset, i32 %bindlessOffset6, i32 %bindlessOffset7, i32 %bindlessOffset8, i32 %bindlessOffset9, i32 %bindlessOffset10) #0 {
; BB0 :
  %9 = bitcast i64 %0 to <2 x i32>		; visa id: 2
  %10 = extractelement <2 x i32> %9, i32 0		; visa id: 3
  %11 = extractelement <2 x i32> %9, i32 1		; visa id: 3
  %12 = extractelement <3 x i32> %globalOffset, i32 0		; visa id: 3
  %13 = extractelement <3 x i32> %enqueuedLocalSize, i32 0		; visa id: 3
  %14 = extractelement <8 x i32> %r0, i32 1		; visa id: 3
  %15 = mul i32 %13, %14		; visa id: 3
  %16 = zext i16 %localIdX to i32		; visa id: 4
  %17 = add i32 %15, %16
  %18 = add i32 %17, %12		; visa id: 5
  %19 = icmp eq i32 %11, 0
  %20 = icmp ugt i32 %10, %18		; visa id: 6
  %21 = and i1 %19, %20		; visa id: 7
  %22 = icmp ugt i32 %11, 0
  %23 = or i1 %21, %22		; visa id: 9
  %24 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %1)
  %25 = extractvalue { i32, i32 } %24, 0		; visa id: 11
  %26 = extractvalue { i32, i32 } %24, 1		; visa id: 11
  %27 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %2)
  %28 = extractvalue { i32, i32 } %27, 0		; visa id: 13
  %29 = extractvalue { i32, i32 } %27, 1		; visa id: 13
  %30 = select i1 %23, i32 %25, i32 %28		; visa id: 15
  %31 = select i1 %23, i32 %26, i32 %29		; visa id: 16
  %32 = insertelement <2 x i32> undef, i32 %30, i32 0		; visa id: 17
  %33 = insertelement <2 x i32> %32, i32 %31, i32 1		; visa id: 18
  %34 = bitcast <2 x i32> %33 to i64		; visa id: 19
  %35 = select i1 %23, i32 0, i32 %10		; visa id: 23
  %36 = select i1 %23, i32 0, i32 %11		; visa id: 24
  %37 = insertelement <2 x i32> undef, i32 %35, i32 0		; visa id: 25
  %38 = insertelement <2 x i32> %37, i32 %36, i32 1		; visa id: 26
  %39 = bitcast <2 x i32> %38 to i64		; visa id: 27
  %40 = zext nneg i32 %18 to i64		; visa id: 31
  %41 = sub nsw i64 %40, %39, !spirv.Decorations !615		; visa id: 32
  %42 = bitcast i64 %41 to <2 x i32>		; visa id: 33
  %43 = extractelement <2 x i32> %42, i32 0		; visa id: 37
  %44 = extractelement <2 x i32> %42, i32 1		; visa id: 37
  %45 = ashr i32 %5, 31		; visa id: 37
  %46 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %5, i32 %45, i32 640, i32 0)
  %47 = extractvalue { i32, i32 } %46, 0		; visa id: 38
  %48 = extractvalue { i32, i32 } %46, 1		; visa id: 38
  %49 = insertelement <2 x i32> undef, i32 %47, i32 0		; visa id: 45
  %50 = insertelement <2 x i32> %49, i32 %48, i32 1		; visa id: 46
  %51 = bitcast <2 x i32> %50 to i64		; visa id: 47
  %52 = or i32 %48, %44		; visa id: 49
  %53 = icmp ult i32 %52, 1		; visa id: 51
  br i1 %53, label %119, label %54, !stats.blockFrequency.digits !617, !stats.blockFrequency.scale !618		; visa id: 55

54:                                               ; preds = %8
; BB1 :
  %55 = trunc i64 %51 to i32		; visa id: 57
  %56 = uitofp i64 %51 to double		; visa id: 58
  %57 = fptrunc double %56 to float		; visa id: 59
  %58 = fdiv float 1.000000e+00, %57		; visa id: 60
  %59 = fsub double 0.000000e+00, %56
  %60 = fpext float %58 to double		; visa id: 61
  %61 = call double @llvm.fma.f64(double %59, double %60, double 1.000000e+00) #4		; visa id: 62
  %62 = fadd double %61, 0xBCF0000000000000		; visa id: 63
  %63 = call double @llvm.fma.f64(double %60, double %62, double %60) #4		; visa id: 64
  %64 = bitcast i64 %41 to <2 x i32>		; visa id: 65
  %65 = extractelement <2 x i32> %64, i32 1		; visa id: 67
  %66 = uitofp i32 %65 to double		; visa id: 67
  %67 = fmul double %63, %66		; visa id: 68
  %68 = fptoui double %67 to i32		; visa id: 69
  %69 = mul i32 %68, %55		; visa id: 70
  %70 = sub i32 %65, %69		; visa id: 71
  %71 = trunc i64 %41 to i32		; visa id: 72
  %72 = uitofp i32 %70 to double		; visa id: 73
  %73 = uitofp i32 %71 to double		; visa id: 74
  %74 = call double @llvm.fma.f64(double %72, double 0x41F0000000000000, double %73) #4		; visa id: 75
  %75 = fmul double %63, %74		; visa id: 76
  %76 = fptoui double %75 to i64		; visa id: 77
  %77 = bitcast i64 %76 to <2 x i32>		; visa id: 78
  %78 = extractelement <2 x i32> %77, i32 0		; visa id: 80
  %79 = trunc i64 %76 to i32		; visa id: 80
  %80 = lshr i64 %76, 32		; visa id: 81
  %81 = bitcast i64 %80 to <2 x i32>		; visa id: 82
  %82 = extractelement <2 x i32> %81, i32 0		; visa id: 86
  %83 = extractelement <2 x i32> %81, i32 1		; visa id: 86
  %84 = bitcast i64 %76 to <2 x i32>		; visa id: 86
  %85 = extractelement <2 x i32> %84, i32 1		; visa id: 88
  %86 = icmp eq i32 %83, 0
  %87 = icmp eq i32 %82, 0		; visa id: 88
  %88 = and i1 %86, %87		; visa id: 89
  %89 = mul i32 %79, %48		; visa id: 91
  %90 = select i1 %88, i32 0, i32 %55		; visa id: 92
  %91 = add i32 %89, %90		; visa id: 93
  %92 = sub i32 %70, %91		; visa id: 94
  %93 = insertelement <2 x i32> undef, i32 %43, i32 0		; visa id: 95
  %94 = insertelement <2 x i32> %93, i32 %92, i32 1		; visa id: 96
  %95 = bitcast <2 x i32> %94 to i64		; visa id: 97
  %96 = and i32 %47, -128		; visa id: 101
  %97 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %78, i32 0, i32 %96, i32 0)
  %98 = extractvalue { i32, i32 } %97, 0
  %99 = extractvalue { i32, i32 } %97, 1
  %100 = insertelement <2 x i32> undef, i32 %98, i32 0
  %101 = insertelement <2 x i32> %100, i32 %99, i32 1
  %102 = bitcast <2 x i32> %101 to i64		; visa id: 102
  %103 = sub i64 %95, %102		; visa id: 110
  %104 = bitcast i64 %103 to <2 x i32>		; visa id: 111
  %105 = extractelement <2 x i32> %104, i32 0		; visa id: 115
  %106 = extractelement <2 x i32> %104, i32 1		; visa id: 115
  %107 = add i32 %85, %68		; visa id: 115
  %108 = insertelement <2 x i32> undef, i32 %78, i32 0		; visa id: 116
  %109 = insertelement <2 x i32> %108, i32 %107, i32 1		; visa id: 117
  %110 = bitcast <2 x i32> %109 to i64		; visa id: 118
  %111 = icmp eq i32 %106, %48
  %112 = icmp uge i32 %105, %47		; visa id: 122
  %113 = and i1 %111, %112		; visa id: 123
  %114 = icmp ugt i32 %106, %48
  %115 = or i1 %113, %114		; visa id: 125
  %116 = sext i1 %115 to i64		; visa id: 127
  %117 = sub i64 0, %116
  %118 = add i64 %110, %117		; visa id: 129
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618		; visa id: 130

119:                                              ; preds = %8
; BB2 :
  %tobool.i33 = icmp eq i32 %5, 0		; visa id: 132
  br i1 %tobool.i33, label %.precompiled_u32divrem_sp.exit55_crit_edge, label %if.end.i34, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618		; visa id: 133

if.end.i34:                                       ; preds = %119
; BB3 :
  %120 = trunc nuw i64 %41 to i32		; visa id: 135
  %121 = trunc nuw i64 %51 to i32		; visa id: 136
  %122 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %121)		; visa id: 137
  %conv.i35 = fptoui float %122 to i32		; visa id: 139
  %sub.i36 = sub i32 %121, %conv.i35		; visa id: 140
  %123 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %120)		; visa id: 141
  %div.i39 = fdiv float 1.000000e+00, %122, !fpmath !620		; visa id: 142
  %124 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i39, float 0xBE98000000000000, float %div.i39)		; visa id: 143
  %125 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %123, float %124)		; visa id: 144
  %conv3.i37 = fptoui float %123 to i32		; visa id: 145
  %sub4.i38 = sub i32 %120, %conv3.i37		; visa id: 146
  %conv8.i40 = fptoui float %125 to i32		; visa id: 147
  %126 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i36)		; visa id: 148
  %127 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i38)		; visa id: 149
  %128 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i40)		; visa id: 150
  %129 = fsub float 0.000000e+00, %122		; visa id: 151
  %130 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %129, float %128, float %123)		; visa id: 152
  %131 = fsub float 0.000000e+00, %126		; visa id: 153
  %132 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %131, float %128, float %127)		; visa id: 154
  %133 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %130, float %132)		; visa id: 155
  %134 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %124, float %133)		; visa id: 156
  %conv16.i43 = fptoui float %134 to i32		; visa id: 158
  %add.i44 = add i32 %conv16.i43, %conv8.i40		; visa id: 159
  %mul.i45 = mul i32 %add.i44, %121		; visa id: 160
  %sub17.i46 = sub i32 %120, %mul.i45		; visa id: 161
  %cmp.i47 = icmp uge i32 %sub17.i46, %121
  %135 = sext i1 %cmp.i47 to i32		; visa id: 162
  %136 = sub i32 0, %135
  %add19.i50 = add i32 %add.i44, %136		; visa id: 163
  br label %precompiled_u32divrem_sp.exit55, !stats.blockFrequency.digits !621, !stats.blockFrequency.scale !618		; visa id: 164

.precompiled_u32divrem_sp.exit55_crit_edge:       ; preds = %119
; BB4 :
  br label %precompiled_u32divrem_sp.exit55, !stats.blockFrequency.digits !622, !stats.blockFrequency.scale !618		; visa id: 167

precompiled_u32divrem_sp.exit55:                  ; preds = %.precompiled_u32divrem_sp.exit55_crit_edge, %if.end.i34
; BB5 :
  %retval.0.i54 = phi i32 [ %add19.i50, %if.end.i34 ], [ -1, %.precompiled_u32divrem_sp.exit55_crit_edge ]
  %137 = zext i32 %retval.0.i54 to i64		; visa id: 168
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618		; visa id: 169

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit55, %54
; BB6 :
  %138 = phi i64 [ %137, %precompiled_u32divrem_sp.exit55 ], [ %118, %54 ]
  %139 = icmp ult i32 %44, 1		; visa id: 170
  br i1 %139, label %udiv_pow2_64b_as_32b, label %udiv_pow2_64b, !stats.blockFrequency.digits !617, !stats.blockFrequency.scale !618		; visa id: 171

udiv_pow2_64b:                                    ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB7 :
  %u.hi32 = lshr i64 %41, 32		; visa id: 173
  %140 = bitcast i64 %u.hi32 to <2 x i32>		; visa id: 174
  %141 = extractelement <2 x i32> %140, i32 0		; visa id: 178
  %142 = extractelement <2 x i32> %140, i32 1		; visa id: 178
  %143 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %43, i32 0, i32 -858993459, i32 0)
  %144 = extractvalue { i32, i32 } %143, 0
  %145 = extractvalue { i32, i32 } %143, 1
  %146 = insertelement <2 x i32> undef, i32 %144, i32 0
  %147 = insertelement <2 x i32> %146, i32 %145, i32 1
  %148 = bitcast <2 x i32> %147 to i64		; visa id: 178
  %149 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %141, i32 %142, i32 -858993459, i32 0)
  %150 = extractvalue { i32, i32 } %149, 0
  %151 = extractvalue { i32, i32 } %149, 1
  %152 = insertelement <2 x i32> undef, i32 %150, i32 0
  %153 = insertelement <2 x i32> %152, i32 %151, i32 1
  %154 = bitcast <2 x i32> %153 to i64		; visa id: 186
  %w0.lo32 = lshr i64 %148, 32		; visa id: 194
  %t = add nuw i64 %154, %w0.lo32		; visa id: 195
  %155 = bitcast i64 %t to <2 x i32>		; visa id: 196
  %156 = extractelement <2 x i32> %155, i32 0		; visa id: 198
  %157 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %43, i32 0, i32 -858993460, i32 0)
  %158 = extractvalue { i32, i32 } %157, 0
  %159 = extractvalue { i32, i32 } %157, 1
  %160 = insertelement <2 x i32> undef, i32 %158, i32 0
  %161 = insertelement <2 x i32> %160, i32 %159, i32 1
  %162 = bitcast <2 x i32> %161 to i64		; visa id: 198
  %163 = insertelement <2 x i32> undef, i32 %156, i32 0		; visa id: 206
  %164 = insertelement <2 x i32> %163, i32 0, i32 1		; visa id: 207
  %165 = bitcast <2 x i32> %164 to i64		; visa id: 208
  %w1 = add nuw i64 %162, %165		; visa id: 212
  %166 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %141, i32 %142, i32 -858993460, i32 0)
  %167 = extractvalue { i32, i32 } %166, 0
  %168 = extractvalue { i32, i32 } %166, 1
  %169 = insertelement <2 x i32> undef, i32 %167, i32 0
  %170 = insertelement <2 x i32> %169, i32 %168, i32 1
  %171 = bitcast <2 x i32> %170 to i64		; visa id: 213
  %t.hi32 = lshr i64 %t, 32		; visa id: 221
  %172 = add nuw i64 %171, %t.hi32		; visa id: 222
  %w1.lo32 = lshr i64 %w1, 32		; visa id: 223
  %uv = add nuw i64 %172, %w1.lo32		; visa id: 224
  %q_appx31 = lshr i64 %uv, 9		; visa id: 225
  br label %175, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618		; visa id: 226

udiv_pow2_64b_as_32b:                             ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB8 :
  %173 = trunc nuw i64 %41 to i32		; visa id: 228
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %173, i32 -858993459)		; visa id: 229
  %q_appx30 = lshr i32 %q_appx, 9		; visa id: 230
  %174 = zext nneg i32 %q_appx30 to i64		; visa id: 231
  br label %175, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618		; visa id: 232

175:                                              ; preds = %udiv_pow2_64b, %udiv_pow2_64b_as_32b
; BB9 :
  %176 = phi i64 [ %174, %udiv_pow2_64b_as_32b ], [ %q_appx31, %udiv_pow2_64b ]
  %177 = bitcast i64 %176 to <2 x i32>		; visa id: 233
  %178 = extractelement <2 x i32> %177, i32 0		; visa id: 237
  %179 = extractelement <2 x i32> %177, i32 1		; visa id: 237
  %180 = or i32 %179, %45		; visa id: 237
  %181 = icmp ult i32 %180, 1		; visa id: 239
  br i1 %181, label %237, label %182, !stats.blockFrequency.digits !617, !stats.blockFrequency.scale !618		; visa id: 240

182:                                              ; preds = %175
; BB10 :
  %183 = sext i32 %5 to i64		; visa id: 242
  %184 = uitofp i64 %183 to double		; visa id: 243
  %185 = fptrunc double %184 to float		; visa id: 244
  %186 = fdiv float 1.000000e+00, %185		; visa id: 245
  %187 = fsub double 0.000000e+00, %184
  %188 = fpext float %186 to double		; visa id: 246
  %189 = call double @llvm.fma.f64(double %187, double %188, double 1.000000e+00) #4		; visa id: 247
  %190 = fadd double %189, 0xBCF0000000000000		; visa id: 248
  %191 = call double @llvm.fma.f64(double %188, double %190, double %188) #4		; visa id: 249
  %192 = bitcast i64 %176 to <2 x i32>		; visa id: 250
  %193 = extractelement <2 x i32> %192, i32 1		; visa id: 252
  %194 = uitofp nneg i32 %193 to double		; visa id: 252
  %195 = fmul double %191, %194		; visa id: 253
  %196 = fptoui double %195 to i32		; visa id: 254
  %197 = mul i32 %5, %196		; visa id: 255
  %198 = sub i32 %193, %197		; visa id: 256
  %199 = trunc i64 %176 to i32		; visa id: 257
  %200 = uitofp i32 %198 to double		; visa id: 258
  %201 = uitofp i32 %199 to double		; visa id: 259
  %202 = call double @llvm.fma.f64(double %200, double 0x41F0000000000000, double %201) #4		; visa id: 260
  %203 = fmul double %191, %202		; visa id: 261
  %204 = fptoui double %203 to i64		; visa id: 262
  %205 = bitcast i64 %204 to <2 x i32>		; visa id: 263
  %206 = extractelement <2 x i32> %205, i32 0		; visa id: 267
  %207 = extractelement <2 x i32> %205, i32 1		; visa id: 267
  %208 = trunc i64 %204 to i32		; visa id: 267
  %isneg = icmp slt i32 %5, 0		; visa id: 268
  %.neg56 = select i1 %isneg, i32 %208, i32 0		; visa id: 269
  %209 = icmp ult i32 %207, 1		; visa id: 270
  %210 = select i1 %209, i32 0, i32 %5		; visa id: 271
  %211 = sub i32 %198, %210
  %212 = add i32 %.neg56, %211		; visa id: 272
  %213 = insertelement <2 x i32> undef, i32 %178, i32 0		; visa id: 273
  %214 = insertelement <2 x i32> %213, i32 %212, i32 1		; visa id: 274
  %215 = bitcast <2 x i32> %214 to i64		; visa id: 275
  %216 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %206, i32 0, i32 %5, i32 0)
  %217 = extractvalue { i32, i32 } %216, 0
  %218 = extractvalue { i32, i32 } %216, 1
  %219 = insertelement <2 x i32> undef, i32 %217, i32 0
  %220 = insertelement <2 x i32> %219, i32 %218, i32 1
  %221 = bitcast <2 x i32> %220 to i64		; visa id: 279
  %222 = sub i64 %215, %221		; visa id: 287
  %223 = bitcast i64 %222 to <2 x i32>		; visa id: 288
  %224 = extractelement <2 x i32> %223, i32 0		; visa id: 292
  %225 = extractelement <2 x i32> %223, i32 1		; visa id: 292
  %226 = icmp eq i32 %225, %45
  %227 = icmp ult i32 %224, %5		; visa id: 292
  %228 = and i1 %226, %227		; visa id: 293
  %229 = icmp ult i32 %225, %45
  %230 = or i1 %228, %229		; visa id: 295
  %231 = select i1 %230, i32 0, i32 %5		; visa id: 297
  %232 = select i1 %230, i32 0, i32 %45		; visa id: 298
  %233 = insertelement <2 x i32> undef, i32 %231, i32 0		; visa id: 299
  %234 = insertelement <2 x i32> %233, i32 %232, i32 1		; visa id: 300
  %235 = bitcast <2 x i32> %234 to i64		; visa id: 301
  %236 = sub i64 %222, %235		; visa id: 305
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618		; visa id: 306

237:                                              ; preds = %175
; BB11 :
  %tobool.i = icmp eq i32 %5, 0		; visa id: 308
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618		; visa id: 309

if.end.i:                                         ; preds = %237
; BB12 :
  %238 = trunc nuw i64 %176 to i32		; visa id: 311
  %239 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %5)		; visa id: 312
  %conv.i = fptoui float %239 to i32		; visa id: 314
  %sub.i = sub i32 %5, %conv.i		; visa id: 315
  %240 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %238)		; visa id: 316
  %div.i = fdiv float 1.000000e+00, %239, !fpmath !620		; visa id: 317
  %241 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)		; visa id: 318
  %242 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %240, float %241)		; visa id: 319
  %conv3.i = fptoui float %240 to i32		; visa id: 320
  %sub4.i = sub i32 %238, %conv3.i		; visa id: 321
  %conv8.i = fptoui float %242 to i32		; visa id: 322
  %243 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)		; visa id: 323
  %244 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)		; visa id: 324
  %245 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)		; visa id: 325
  %246 = fsub float 0.000000e+00, %239		; visa id: 326
  %247 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %246, float %245, float %240)		; visa id: 327
  %248 = fsub float 0.000000e+00, %243		; visa id: 328
  %249 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %248, float %245, float %244)		; visa id: 329
  %250 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %247, float %249)		; visa id: 330
  %251 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %241, float %250)		; visa id: 331
  %conv16.i = fptoui float %251 to i32		; visa id: 333
  %add.i = add i32 %conv16.i, %conv8.i		; visa id: 334
  %mul.i = mul i32 %add.i, %5		; visa id: 335
  %sub17.i = sub i32 %238, %mul.i		; visa id: 336
  %cmp.i.not = icmp ult i32 %sub17.i, %5		; visa id: 337
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %5		; visa id: 338
  %sub21.i = sub i32 %sub17.i, %and20.i		; visa id: 339
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !621, !stats.blockFrequency.scale !618		; visa id: 340

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %237
; BB13 :
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !622, !stats.blockFrequency.scale !618		; visa id: 343

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
; BB14 :
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %252 = zext i32 %storemerge.i to i64		; visa id: 344
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !618		; visa id: 345

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %182
; BB15 :
  %253 = phi i64 [ %252, %precompiled_u32divrem_sp.exit ], [ %236, %182 ]
  %254 = bitcast i64 %138 to <2 x i32>		; visa id: 346
  %255 = extractelement <2 x i32> %254, i32 0		; visa id: 348
  %256 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %255, i32 1
  %257 = bitcast <2 x i32> %256 to i64		; visa id: 348
  %258 = bitcast i64 %253 to <2 x i32>		; visa id: 349
  %259 = extractelement <2 x i32> %258, i32 0		; visa id: 351
  %260 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %259, i32 1
  %261 = bitcast <2 x i32> %260 to i64		; visa id: 351
  %262 = ashr exact i64 %261, 32		; visa id: 352
  %263 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %178, i32 %179, i32 -2560, i32 -1)
  %264 = extractvalue { i32, i32 } %263, 0
  %265 = extractvalue { i32, i32 } %263, 1
  %266 = insertelement <2 x i32> undef, i32 %264, i32 0
  %267 = insertelement <2 x i32> %266, i32 %265, i32 1
  %268 = bitcast <2 x i32> %267 to i64		; visa id: 353
  %269 = add i64 %268, %34		; visa id: 361
  %270 = shl i64 %41, 2		; visa id: 362
  %271 = add i64 %269, %270		; visa id: 363
  %272 = ashr exact i64 %257, 28		; visa id: 364
  %273 = add nsw i64 %272, %262, !spirv.Decorations !615		; visa id: 365
  %274 = bitcast i64 %273 to <2 x i32>		; visa id: 366
  %275 = extractelement <2 x i32> %274, i32 0		; visa id: 370
  %276 = extractelement <2 x i32> %274, i32 1		; visa id: 370
  %277 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %275, i32 %276, i32 2560, i32 0)
  %278 = extractvalue { i32, i32 } %277, 0
  %279 = extractvalue { i32, i32 } %277, 1
  %280 = insertelement <2 x i32> undef, i32 %278, i32 0
  %281 = insertelement <2 x i32> %280, i32 %279, i32 1
  %282 = bitcast <2 x i32> %281 to i64		; visa id: 370
  %283 = add i64 %271, %282		; visa id: 378
  %284 = inttoptr i64 %283 to ptr addrspace(1)		; visa id: 379
  %285 = load i32, ptr addrspace(1) %284, align 4		; visa id: 379
  %286 = add i64 %283, 409600
  %287 = inttoptr i64 %286 to ptr addrspace(1)
  %288 = load i32, ptr addrspace(1) %287, align 4		; visa id: 380
  %289 = ashr exact i64 %261, 30		; visa id: 381
  %290 = ptrtoint ptr addrspace(1) %6 to i64		; visa id: 382
  %291 = add i64 %289, %290		; visa id: 382
  %292 = inttoptr i64 %291 to ptr addrspace(1)		; visa id: 383
  %293 = load float, ptr addrspace(1) %292, align 4		; visa id: 383
  %294 = ptrtoint ptr addrspace(1) %7 to i64		; visa id: 384
  %295 = add i64 %289, %294		; visa id: 384
  %296 = inttoptr i64 %295 to ptr addrspace(1)		; visa id: 385
  %297 = load i32, ptr addrspace(1) %296, align 4		; visa id: 385
  %298 = add nsw i32 %285, %288, !spirv.Decorations !615		; visa id: 386
  %299 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %3)
  %300 = extractvalue { i32, i32 } %299, 0		; visa id: 387
  %301 = extractvalue { i32, i32 } %299, 1		; visa id: 387
  %302 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %4)
  %303 = extractvalue { i32, i32 } %302, 0		; visa id: 389
  %304 = extractvalue { i32, i32 } %302, 1		; visa id: 389
  %305 = select i1 %23, i32 %300, i32 %303		; visa id: 391
  %306 = select i1 %23, i32 %301, i32 %304		; visa id: 392
  %307 = insertelement <2 x i32> undef, i32 %305, i32 0		; visa id: 393
  %308 = insertelement <2 x i32> %307, i32 %306, i32 1		; visa id: 394
  %309 = bitcast <2 x i32> %308 to i64		; visa id: 395
  %310 = fmul reassoc nsz arcp contract float %293, 0x3F7B717580000000, !spirv.Decorations !623		; visa id: 399
  %311 = sitofp i32 %298 to float		; visa id: 400
  %312 = sitofp i32 %297 to float		; visa id: 401
  %313 = fmul reassoc nnan nsz arcp contract float %312, 5.100000e+02, !spirv.Decorations !625
  %314 = fsub reassoc nnan nsz arcp contract float %311, %313, !spirv.Decorations !625		; visa id: 402
  %315 = fmul reassoc nsz arcp contract float %310, %314, !spirv.Decorations !623		; visa id: 404
  %316 = add i64 %270, %309		; visa id: 405
  %317 = inttoptr i64 %316 to ptr addrspace(1)		; visa id: 406
  store float %315, ptr addrspace(1) %317, align 4		; visa id: 406
  ret void, !stats.blockFrequency.digits !617, !stats.blockFrequency.scale !618		; visa id: 407
}

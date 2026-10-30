; ------------------------------------------------
; OCL_asm6efbb33bd2ee4230_simd32_entry_0001.visa.ll
; ------------------------------------------------
; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSZL12combine_pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_RK4MetaiiEUlNS0_2idILi1EEEE_(i64 %0, ptr addrspace(1) align 4 %1, ptr addrspace(1) align 4 %2, ptr addrspace(1) align 4 %3, ptr addrspace(1) align 4 %4, ptr byval(%struct.Meta) align 8 %5, i32 %6, i32 %7, ptr addrspace(1) align 4 %8, ptr addrspace(1) align 4 %9, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i32 %const_reg_dword, i32 %const_reg_dword1, i32 %const_reg_dword2, i32 %const_reg_dword3, i32 %const_reg_dword4, i32 %const_reg_dword5, i64 %const_reg_qword, float %const_reg_fp32, i8 %const_reg_byte, i8 %const_reg_byte6, i8 %const_reg_byte7, i8 %const_reg_byte8, i32 %bufferOffset, i32 %bufferOffset9, i32 %bufferOffset10, i32 %bufferOffset11, i32 %bufferOffset12, i32 %bufferOffset13, i32 %bindlessOffset, i32 %bindlessOffset14, i32 %bindlessOffset15, i32 %bindlessOffset16, i32 %bindlessOffset17, i32 %bindlessOffset18) #0 {
; BB0 :
  %11 = bitcast i64 %0 to <2 x i32>		; visa id: 2
  %12 = extractelement <2 x i32> %11, i32 0		; visa id: 3
  %13 = extractelement <2 x i32> %11, i32 1		; visa id: 3
  %14 = extractelement <3 x i32> %globalOffset, i32 0		; visa id: 3
  %15 = extractelement <3 x i32> %enqueuedLocalSize, i32 0		; visa id: 3
  %16 = extractelement <8 x i32> %r0, i32 1		; visa id: 3
  %17 = mul i32 %15, %16		; visa id: 3
  %18 = zext i16 %localIdX to i32		; visa id: 4
  %19 = add i32 %17, %18
  %20 = add i32 %19, %14		; visa id: 5
  %21 = icmp eq i32 %13, 0
  %22 = icmp ugt i32 %12, %20		; visa id: 6
  %23 = and i1 %21, %22		; visa id: 7
  %24 = icmp ugt i32 %13, 0
  %25 = or i1 %23, %24		; visa id: 9
  %26 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %1)
  %27 = extractvalue { i32, i32 } %26, 0		; visa id: 11
  %28 = extractvalue { i32, i32 } %26, 1		; visa id: 11
  %29 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %2)
  %30 = extractvalue { i32, i32 } %29, 0		; visa id: 13
  %31 = extractvalue { i32, i32 } %29, 1		; visa id: 13
  %32 = select i1 %25, i32 %27, i32 %30		; visa id: 15
  %33 = select i1 %25, i32 %28, i32 %31		; visa id: 16
  %34 = select i1 %25, i32 0, i32 %12		; visa id: 17
  %35 = select i1 %25, i32 0, i32 %13		; visa id: 18
  %36 = insertelement <2 x i32> undef, i32 %34, i32 0		; visa id: 19
  %37 = insertelement <2 x i32> %36, i32 %35, i32 1		; visa id: 20
  %38 = bitcast <2 x i32> %37 to i64		; visa id: 21
  %39 = zext nneg i32 %20 to i64		; visa id: 25
  %40 = sub nsw i64 %39, %38, !spirv.Decorations !556		; visa id: 26
  %41 = bitcast i64 %40 to <2 x i32>		; visa id: 27
  %42 = extractelement <2 x i32> %41, i32 0		; visa id: 31
  %43 = extractelement <2 x i32> %41, i32 1		; visa id: 31
  %44 = ashr i32 %const_reg_dword1, 31		; visa id: 31
  %45 = ashr i32 %const_reg_dword5, 31		; visa id: 32
  %46 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %const_reg_dword1, i32 %44, i32 %const_reg_dword5, i32 %45)
  %47 = extractvalue { i32, i32 } %46, 0		; visa id: 33
  %48 = extractvalue { i32, i32 } %46, 1		; visa id: 33
  %49 = insertelement <2 x i32> undef, i32 %47, i32 0		; visa id: 40
  %50 = insertelement <2 x i32> %49, i32 %48, i32 1		; visa id: 41
  %51 = bitcast <2 x i32> %50 to i64		; visa id: 42
  %52 = or i32 %48, %43		; visa id: 44
  %53 = icmp ult i32 %52, 1		; visa id: 46
  br i1 %53, label %118, label %54, !stats.blockFrequency.digits !558, !stats.blockFrequency.scale !559		; visa id: 50

54:                                               ; preds = %10
; BB1 :
  %55 = trunc i64 %51 to i32		; visa id: 52
  %56 = uitofp i64 %51 to double		; visa id: 53
  %57 = fptrunc double %56 to float		; visa id: 54
  %58 = fdiv float 1.000000e+00, %57		; visa id: 55
  %59 = fsub double 0.000000e+00, %56
  %60 = fpext float %58 to double		; visa id: 56
  %61 = call double @llvm.fma.f64(double %59, double %60, double 1.000000e+00) #4		; visa id: 57
  %62 = fadd double %61, 0xBCF0000000000000		; visa id: 58
  %63 = call double @llvm.fma.f64(double %60, double %62, double %60) #4		; visa id: 59
  %64 = bitcast i64 %40 to <2 x i32>		; visa id: 60
  %65 = extractelement <2 x i32> %64, i32 1		; visa id: 62
  %66 = uitofp i32 %65 to double		; visa id: 62
  %67 = fmul double %63, %66		; visa id: 63
  %68 = fptoui double %67 to i32		; visa id: 64
  %69 = mul i32 %68, %55		; visa id: 65
  %70 = sub i32 %65, %69		; visa id: 66
  %71 = trunc i64 %40 to i32		; visa id: 67
  %72 = uitofp i32 %70 to double		; visa id: 68
  %73 = uitofp i32 %71 to double		; visa id: 69
  %74 = call double @llvm.fma.f64(double %72, double 0x41F0000000000000, double %73) #4		; visa id: 70
  %75 = fmul double %63, %74		; visa id: 71
  %76 = fptoui double %75 to i64		; visa id: 72
  %77 = bitcast i64 %76 to <2 x i32>		; visa id: 73
  %78 = extractelement <2 x i32> %77, i32 0		; visa id: 75
  %79 = trunc i64 %76 to i32		; visa id: 75
  %80 = lshr i64 %76, 32		; visa id: 76
  %81 = bitcast i64 %80 to <2 x i32>		; visa id: 77
  %82 = extractelement <2 x i32> %81, i32 0		; visa id: 81
  %83 = extractelement <2 x i32> %81, i32 1		; visa id: 81
  %84 = bitcast i64 %76 to <2 x i32>		; visa id: 81
  %85 = extractelement <2 x i32> %84, i32 1		; visa id: 83
  %86 = icmp eq i32 %83, 0
  %87 = icmp eq i32 %82, 0		; visa id: 83
  %88 = and i1 %86, %87		; visa id: 84
  %89 = mul i32 %79, %48		; visa id: 86
  %90 = select i1 %88, i32 0, i32 %55		; visa id: 87
  %91 = add i32 %89, %90		; visa id: 88
  %92 = sub i32 %70, %91		; visa id: 89
  %93 = insertelement <2 x i32> undef, i32 %42, i32 0		; visa id: 90
  %94 = insertelement <2 x i32> %93, i32 %92, i32 1		; visa id: 91
  %95 = bitcast <2 x i32> %94 to i64		; visa id: 92
  %96 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %78, i32 0, i32 %47, i32 0)
  %97 = extractvalue { i32, i32 } %96, 0
  %98 = extractvalue { i32, i32 } %96, 1
  %99 = insertelement <2 x i32> undef, i32 %97, i32 0
  %100 = insertelement <2 x i32> %99, i32 %98, i32 1
  %101 = bitcast <2 x i32> %100 to i64		; visa id: 96
  %102 = sub i64 %95, %101		; visa id: 104
  %103 = bitcast i64 %102 to <2 x i32>		; visa id: 105
  %104 = extractelement <2 x i32> %103, i32 0		; visa id: 109
  %105 = extractelement <2 x i32> %103, i32 1		; visa id: 109
  %106 = add i32 %85, %68		; visa id: 109
  %107 = insertelement <2 x i32> undef, i32 %78, i32 0		; visa id: 110
  %108 = insertelement <2 x i32> %107, i32 %106, i32 1		; visa id: 111
  %109 = bitcast <2 x i32> %108 to i64		; visa id: 112
  %110 = icmp eq i32 %105, %48
  %111 = icmp uge i32 %104, %47		; visa id: 116
  %112 = and i1 %110, %111		; visa id: 117
  %113 = icmp ugt i32 %105, %48
  %114 = or i1 %112, %113		; visa id: 119
  %115 = sext i1 %114 to i64		; visa id: 121
  %116 = sub i64 0, %115
  %117 = add i64 %109, %116		; visa id: 123
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561		; visa id: 124

118:                                              ; preds = %10
; BB2 :
  %119 = icmp eq i32 %48, 0
  %120 = icmp eq i32 %47, 0		; visa id: 126
  %121 = and i1 %119, %120		; visa id: 127
  br i1 %121, label %.precompiled_u32divrem_sp.exit88_crit_edge, label %if.end.i67, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561		; visa id: 129

.precompiled_u32divrem_sp.exit88_crit_edge:       ; preds = %118
; BB3 :
  br label %precompiled_u32divrem_sp.exit88, !stats.blockFrequency.digits !562, !stats.blockFrequency.scale !563		; visa id: 132

if.end.i67:                                       ; preds = %118
; BB4 :
  %122 = trunc nuw i64 %40 to i32		; visa id: 134
  %123 = trunc nuw i64 %51 to i32		; visa id: 135
  %124 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %123)		; visa id: 136
  %conv.i68 = fptoui float %124 to i32		; visa id: 138
  %sub.i69 = sub i32 %123, %conv.i68		; visa id: 139
  %125 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %122)		; visa id: 140
  %div.i72 = fdiv float 1.000000e+00, %124, !fpmath !564		; visa id: 141
  %126 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i72, float 0xBE98000000000000, float %div.i72)		; visa id: 142
  %127 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %125, float %126)		; visa id: 143
  %conv3.i70 = fptoui float %125 to i32		; visa id: 144
  %sub4.i71 = sub i32 %122, %conv3.i70		; visa id: 145
  %conv8.i73 = fptoui float %127 to i32		; visa id: 146
  %128 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i69)		; visa id: 147
  %129 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i71)		; visa id: 148
  %130 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i73)		; visa id: 149
  %131 = fsub float 0.000000e+00, %124		; visa id: 150
  %132 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %131, float %130, float %125)		; visa id: 151
  %133 = fsub float 0.000000e+00, %128		; visa id: 152
  %134 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %133, float %130, float %129)		; visa id: 153
  %135 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %132, float %134)		; visa id: 154
  %136 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %126, float %135)		; visa id: 155
  %conv16.i76 = fptoui float %136 to i32		; visa id: 157
  %add.i77 = add i32 %conv16.i76, %conv8.i73		; visa id: 158
  %mul.i78 = mul i32 %add.i77, %123		; visa id: 159
  %sub17.i79 = sub i32 %122, %mul.i78		; visa id: 160
  %cmp.i80 = icmp uge i32 %sub17.i79, %123
  %137 = sext i1 %cmp.i80 to i32		; visa id: 161
  %138 = sub i32 0, %137
  %add19.i83 = add i32 %add.i77, %138		; visa id: 162
  br label %precompiled_u32divrem_sp.exit88, !stats.blockFrequency.digits !562, !stats.blockFrequency.scale !563		; visa id: 163

precompiled_u32divrem_sp.exit88:                  ; preds = %.precompiled_u32divrem_sp.exit88_crit_edge, %if.end.i67
; BB5 :
  %retval.0.i87 = phi i32 [ %add19.i83, %if.end.i67 ], [ -1, %.precompiled_u32divrem_sp.exit88_crit_edge ]
  %139 = zext i32 %retval.0.i87 to i64		; visa id: 164
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561		; visa id: 165

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit88, %54
; BB6 :
  %140 = phi i64 [ %139, %precompiled_u32divrem_sp.exit88 ], [ %117, %54 ]
  %141 = or i32 %43, %45		; visa id: 166
  %142 = icmp ult i32 %141, 1		; visa id: 167
  br i1 %142, label %206, label %143, !stats.blockFrequency.digits !558, !stats.blockFrequency.scale !559		; visa id: 168

143:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB7 :
  %144 = sext i32 %const_reg_dword5 to i64		; visa id: 170
  %145 = uitofp i64 %144 to double		; visa id: 171
  %146 = fptrunc double %145 to float		; visa id: 172
  %147 = fdiv float 1.000000e+00, %146		; visa id: 173
  %148 = fsub double 0.000000e+00, %145
  %149 = fpext float %147 to double		; visa id: 174
  %150 = call double @llvm.fma.f64(double %148, double %149, double 1.000000e+00) #4		; visa id: 175
  %151 = fadd double %150, 0xBCF0000000000000		; visa id: 176
  %152 = call double @llvm.fma.f64(double %149, double %151, double %149) #4		; visa id: 177
  %153 = bitcast i64 %40 to <2 x i32>		; visa id: 178
  %154 = extractelement <2 x i32> %153, i32 1		; visa id: 180
  %155 = uitofp i32 %154 to double		; visa id: 180
  %156 = fmul double %152, %155		; visa id: 181
  %157 = fptoui double %156 to i32		; visa id: 182
  %158 = mul i32 %const_reg_dword5, %157		; visa id: 183
  %159 = sub i32 %154, %158		; visa id: 184
  %160 = trunc i64 %40 to i32		; visa id: 185
  %161 = uitofp i32 %159 to double		; visa id: 186
  %162 = uitofp i32 %160 to double		; visa id: 187
  %163 = call double @llvm.fma.f64(double %161, double 0x41F0000000000000, double %162) #4		; visa id: 188
  %164 = fmul double %152, %163		; visa id: 189
  %165 = fptoui double %164 to i64		; visa id: 190
  %166 = bitcast i64 %165 to <2 x i32>		; visa id: 191
  %167 = extractelement <2 x i32> %166, i32 0		; visa id: 193
  %168 = trunc i64 %165 to i32		; visa id: 193
  %169 = lshr i64 %165, 32		; visa id: 194
  %170 = bitcast i64 %169 to <2 x i32>		; visa id: 195
  %171 = extractelement <2 x i32> %170, i32 0		; visa id: 199
  %172 = extractelement <2 x i32> %170, i32 1		; visa id: 199
  %173 = bitcast i64 %165 to <2 x i32>		; visa id: 199
  %174 = extractelement <2 x i32> %173, i32 1		; visa id: 201
  %175 = icmp eq i32 %172, 0
  %176 = icmp eq i32 %171, 0		; visa id: 201
  %177 = and i1 %175, %176		; visa id: 202
  %isneg = icmp slt i32 %const_reg_dword5, 0		; visa id: 204
  %.neg90 = select i1 %isneg, i32 %168, i32 0		; visa id: 205
  %178 = add i32 %.neg90, %159
  %179 = select i1 %177, i32 0, i32 %const_reg_dword5		; visa id: 206
  %180 = sub i32 %178, %179		; visa id: 207
  %181 = insertelement <2 x i32> undef, i32 %42, i32 0		; visa id: 208
  %182 = insertelement <2 x i32> %181, i32 %180, i32 1		; visa id: 209
  %183 = bitcast <2 x i32> %182 to i64		; visa id: 210
  %184 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %167, i32 0, i32 %const_reg_dword5, i32 0)
  %185 = extractvalue { i32, i32 } %184, 0
  %186 = extractvalue { i32, i32 } %184, 1
  %187 = insertelement <2 x i32> undef, i32 %185, i32 0
  %188 = insertelement <2 x i32> %187, i32 %186, i32 1
  %189 = bitcast <2 x i32> %188 to i64		; visa id: 214
  %190 = sub i64 %183, %189		; visa id: 222
  %191 = bitcast i64 %190 to <2 x i32>		; visa id: 223
  %192 = extractelement <2 x i32> %191, i32 0		; visa id: 227
  %193 = extractelement <2 x i32> %191, i32 1		; visa id: 227
  %194 = add i32 %174, %157		; visa id: 227
  %195 = insertelement <2 x i32> undef, i32 %167, i32 0		; visa id: 228
  %196 = insertelement <2 x i32> %195, i32 %194, i32 1		; visa id: 229
  %197 = bitcast <2 x i32> %196 to i64		; visa id: 230
  %198 = icmp eq i32 %193, %45
  %199 = icmp uge i32 %192, %const_reg_dword5		; visa id: 234
  %200 = and i1 %198, %199		; visa id: 235
  %201 = icmp ugt i32 %193, %45
  %202 = or i1 %200, %201		; visa id: 237
  %203 = sext i1 %202 to i64		; visa id: 239
  %204 = sub i64 0, %203
  %205 = add i64 %197, %204		; visa id: 241
  br label %__igcbuiltin_u64_udiv_dp.exit41, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561		; visa id: 242

206:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB8 :
  %tobool.i43 = icmp eq i32 %const_reg_dword5, 0		; visa id: 244
  br i1 %tobool.i43, label %.precompiled_u32divrem_sp.exit65_crit_edge, label %if.end.i44, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561		; visa id: 245

.precompiled_u32divrem_sp.exit65_crit_edge:       ; preds = %206
; BB9 :
  br label %precompiled_u32divrem_sp.exit65, !stats.blockFrequency.digits !565, !stats.blockFrequency.scale !566		; visa id: 248

if.end.i44:                                       ; preds = %206
; BB10 :
  %207 = trunc nuw i64 %40 to i32		; visa id: 250
  %208 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword5)		; visa id: 251
  %conv.i45 = fptoui float %208 to i32		; visa id: 253
  %sub.i46 = sub i32 %const_reg_dword5, %conv.i45		; visa id: 254
  %209 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %207)		; visa id: 255
  %div.i49 = fdiv float 1.000000e+00, %208, !fpmath !564		; visa id: 256
  %210 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i49, float 0xBE98000000000000, float %div.i49)		; visa id: 257
  %211 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %209, float %210)		; visa id: 258
  %conv3.i47 = fptoui float %209 to i32		; visa id: 259
  %sub4.i48 = sub i32 %207, %conv3.i47		; visa id: 260
  %conv8.i50 = fptoui float %211 to i32		; visa id: 261
  %212 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i46)		; visa id: 262
  %213 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i48)		; visa id: 263
  %214 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i50)		; visa id: 264
  %215 = fsub float 0.000000e+00, %208		; visa id: 265
  %216 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %215, float %214, float %209)		; visa id: 266
  %217 = fsub float 0.000000e+00, %212		; visa id: 267
  %218 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %217, float %214, float %213)		; visa id: 268
  %219 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %216, float %218)		; visa id: 269
  %220 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %210, float %219)		; visa id: 270
  %conv16.i53 = fptoui float %220 to i32		; visa id: 272
  %add.i54 = add i32 %conv16.i53, %conv8.i50		; visa id: 273
  %mul.i55 = mul i32 %add.i54, %const_reg_dword5		; visa id: 274
  %sub17.i56 = sub i32 %207, %mul.i55		; visa id: 275
  %cmp.i57 = icmp uge i32 %sub17.i56, %const_reg_dword5
  %221 = sext i1 %cmp.i57 to i32		; visa id: 276
  %222 = sub i32 0, %221
  %add19.i60 = add i32 %add.i54, %222		; visa id: 277
  br label %precompiled_u32divrem_sp.exit65, !stats.blockFrequency.digits !567, !stats.blockFrequency.scale !563		; visa id: 278

precompiled_u32divrem_sp.exit65:                  ; preds = %.precompiled_u32divrem_sp.exit65_crit_edge, %if.end.i44
; BB11 :
  %retval.0.i64 = phi i32 [ %add19.i60, %if.end.i44 ], [ -1, %.precompiled_u32divrem_sp.exit65_crit_edge ]
  %223 = zext i32 %retval.0.i64 to i64		; visa id: 279
  br label %__igcbuiltin_u64_udiv_dp.exit41, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561		; visa id: 280

__igcbuiltin_u64_udiv_dp.exit41:                  ; preds = %precompiled_u32divrem_sp.exit65, %143
; BB12 :
  %224 = phi i64 [ %223, %precompiled_u32divrem_sp.exit65 ], [ %205, %143 ]
  %225 = bitcast i64 %224 to <2 x i32>		; visa id: 281
  %226 = extractelement <2 x i32> %225, i32 0		; visa id: 285
  %227 = extractelement <2 x i32> %225, i32 1		; visa id: 285
  %228 = or i32 %227, %44		; visa id: 285
  %229 = icmp ult i32 %228, 1		; visa id: 287
  br i1 %229, label %285, label %230, !stats.blockFrequency.digits !558, !stats.blockFrequency.scale !559		; visa id: 288

230:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit41
; BB13 :
  %231 = sext i32 %const_reg_dword1 to i64		; visa id: 290
  %232 = uitofp i64 %231 to double		; visa id: 291
  %233 = fptrunc double %232 to float		; visa id: 292
  %234 = fdiv float 1.000000e+00, %233		; visa id: 293
  %235 = fsub double 0.000000e+00, %232
  %236 = fpext float %234 to double		; visa id: 294
  %237 = call double @llvm.fma.f64(double %235, double %236, double 1.000000e+00) #4		; visa id: 295
  %238 = fadd double %237, 0xBCF0000000000000		; visa id: 296
  %239 = call double @llvm.fma.f64(double %236, double %238, double %236) #4		; visa id: 297
  %240 = bitcast i64 %224 to <2 x i32>		; visa id: 298
  %241 = extractelement <2 x i32> %240, i32 1		; visa id: 300
  %242 = uitofp i32 %241 to double		; visa id: 300
  %243 = fmul double %239, %242		; visa id: 301
  %244 = fptoui double %243 to i32		; visa id: 302
  %245 = mul i32 %const_reg_dword1, %244		; visa id: 303
  %246 = sub i32 %241, %245		; visa id: 304
  %247 = trunc i64 %224 to i32		; visa id: 305
  %248 = uitofp i32 %246 to double		; visa id: 306
  %249 = uitofp i32 %247 to double		; visa id: 307
  %250 = call double @llvm.fma.f64(double %248, double 0x41F0000000000000, double %249) #4		; visa id: 308
  %251 = fmul double %239, %250		; visa id: 309
  %252 = fptoui double %251 to i64		; visa id: 310
  %253 = bitcast i64 %252 to <2 x i32>		; visa id: 311
  %254 = extractelement <2 x i32> %253, i32 0		; visa id: 315
  %255 = extractelement <2 x i32> %253, i32 1		; visa id: 315
  %256 = trunc i64 %252 to i32		; visa id: 315
  %isneg92 = icmp slt i32 %const_reg_dword1, 0		; visa id: 316
  %.neg91 = select i1 %isneg92, i32 %256, i32 0		; visa id: 317
  %257 = icmp ult i32 %255, 1		; visa id: 318
  %258 = select i1 %257, i32 0, i32 %const_reg_dword1		; visa id: 319
  %259 = sub i32 %246, %258
  %260 = add i32 %.neg91, %259		; visa id: 320
  %261 = insertelement <2 x i32> undef, i32 %226, i32 0		; visa id: 321
  %262 = insertelement <2 x i32> %261, i32 %260, i32 1		; visa id: 322
  %263 = bitcast <2 x i32> %262 to i64		; visa id: 323
  %264 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %254, i32 0, i32 %const_reg_dword1, i32 0)
  %265 = extractvalue { i32, i32 } %264, 0
  %266 = extractvalue { i32, i32 } %264, 1
  %267 = insertelement <2 x i32> undef, i32 %265, i32 0
  %268 = insertelement <2 x i32> %267, i32 %266, i32 1
  %269 = bitcast <2 x i32> %268 to i64		; visa id: 327
  %270 = sub i64 %263, %269		; visa id: 335
  %271 = bitcast i64 %270 to <2 x i32>		; visa id: 336
  %272 = extractelement <2 x i32> %271, i32 0		; visa id: 340
  %273 = extractelement <2 x i32> %271, i32 1		; visa id: 340
  %274 = icmp eq i32 %273, %44
  %275 = icmp ult i32 %272, %const_reg_dword1		; visa id: 340
  %276 = and i1 %274, %275		; visa id: 341
  %277 = icmp ult i32 %273, %44
  %278 = or i1 %276, %277		; visa id: 343
  %279 = select i1 %278, i32 0, i32 %const_reg_dword1		; visa id: 345
  %280 = select i1 %278, i32 0, i32 %44		; visa id: 346
  %281 = insertelement <2 x i32> undef, i32 %279, i32 0		; visa id: 347
  %282 = insertelement <2 x i32> %281, i32 %280, i32 1		; visa id: 348
  %283 = bitcast <2 x i32> %282 to i64		; visa id: 349
  %284 = sub i64 %270, %283		; visa id: 353
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561		; visa id: 354

285:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit41
; BB14 :
  %tobool.i = icmp eq i32 %const_reg_dword1, 0		; visa id: 356
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561		; visa id: 357

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %285
; BB15 :
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !565, !stats.blockFrequency.scale !566		; visa id: 360

if.end.i:                                         ; preds = %285
; BB16 :
  %286 = trunc nuw i64 %224 to i32		; visa id: 362
  %287 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword1)		; visa id: 363
  %conv.i = fptoui float %287 to i32		; visa id: 365
  %sub.i = sub i32 %const_reg_dword1, %conv.i		; visa id: 366
  %288 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %286)		; visa id: 367
  %div.i = fdiv float 1.000000e+00, %287, !fpmath !564		; visa id: 368
  %289 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)		; visa id: 369
  %290 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %288, float %289)		; visa id: 370
  %conv3.i = fptoui float %288 to i32		; visa id: 371
  %sub4.i = sub i32 %286, %conv3.i		; visa id: 372
  %conv8.i = fptoui float %290 to i32		; visa id: 373
  %291 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)		; visa id: 374
  %292 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)		; visa id: 375
  %293 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)		; visa id: 376
  %294 = fsub float 0.000000e+00, %287		; visa id: 377
  %295 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %294, float %293, float %288)		; visa id: 378
  %296 = fsub float 0.000000e+00, %291		; visa id: 379
  %297 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %296, float %293, float %292)		; visa id: 380
  %298 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %295, float %297)		; visa id: 381
  %299 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %289, float %298)		; visa id: 382
  %conv16.i = fptoui float %299 to i32		; visa id: 384
  %add.i = add i32 %conv16.i, %conv8.i		; visa id: 385
  %mul.i = mul i32 %add.i, %const_reg_dword1		; visa id: 386
  %sub17.i = sub i32 %286, %mul.i		; visa id: 387
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword1		; visa id: 388
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword1		; visa id: 389
  %sub21.i = sub i32 %sub17.i, %and20.i		; visa id: 390
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !567, !stats.blockFrequency.scale !563		; visa id: 391

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
; BB17 :
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %300 = zext i32 %storemerge.i to i64		; visa id: 392
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !560, !stats.blockFrequency.scale !561		; visa id: 393

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %230
; BB18 :
  %301 = phi i64 [ %300, %precompiled_u32divrem_sp.exit ], [ %284, %230 ]
  %302 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %226, i32 %227, i32 %const_reg_dword5, i32 %45)
  %303 = extractvalue { i32, i32 } %302, 0		; visa id: 394
  %304 = extractvalue { i32, i32 } %302, 1		; visa id: 394
  %305 = bitcast i64 %301 to <2 x i32>		; visa id: 401
  %306 = extractelement <2 x i32> %305, i32 0		; visa id: 403
  %307 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %306, i32 1
  %308 = bitcast <2 x i32> %307 to i64		; visa id: 403
  %309 = icmp sgt i32 %6, 0		; visa id: 404
  br i1 %309, label %.lr.ph.preheader, label %__igcbuiltin_u64_urem_dp.exit._crit_edge, !stats.blockFrequency.digits !558, !stats.blockFrequency.scale !559		; visa id: 405

__igcbuiltin_u64_urem_dp.exit._crit_edge:         ; preds = %__igcbuiltin_u64_urem_dp.exit
; BB19 :
  br label %368, !stats.blockFrequency.digits !568, !stats.blockFrequency.scale !563		; visa id: 408

.lr.ph.preheader:                                 ; preds = %__igcbuiltin_u64_urem_dp.exit
; BB20 :
  %310 = insertelement <2 x i32> undef, i32 %32, i32 0		; visa id: 410
  %311 = insertelement <2 x i32> %310, i32 %33, i32 1		; visa id: 411
  %312 = bitcast <2 x i32> %311 to i64		; visa id: 412
  %313 = insertelement <2 x i32> undef, i32 %303, i32 0		; visa id: 416
  %314 = insertelement <2 x i32> %313, i32 %304, i32 1		; visa id: 417
  %315 = bitcast <2 x i32> %314 to i64		; visa id: 418
  %316 = sub i64 %40, %315		; visa id: 422
  %317 = shl nsw i32 %6, 1, !spirv.Decorations !556		; visa id: 423
  %318 = ashr i32 %const_reg_dword, 31		; visa id: 424
  %319 = bitcast i64 %140 to <2 x i32>		; visa id: 425
  %320 = extractelement <2 x i32> %319, i32 0		; visa id: 427
  %321 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %320, i32 1
  %322 = bitcast <2 x i32> %321 to i64		; visa id: 427
  %323 = ashr exact i64 %322, 32		; visa id: 428
  %324 = ashr i32 %7, 31		; visa id: 429
  %325 = ashr exact i64 %308, 32		; visa id: 430
  %326 = bitcast i64 %316 to <2 x i32>		; visa id: 431
  %327 = extractelement <2 x i32> %326, i32 0		; visa id: 433
  %328 = insertelement <2 x i32> <i32 0, i32 undef>, i32 %327, i32 1
  %329 = bitcast <2 x i32> %328 to i64		; visa id: 433
  %330 = ashr exact i64 %329, 30		; visa id: 434
  %331 = add i64 %330, %312		; visa id: 435
  br label %.lr.ph, !stats.blockFrequency.digits !567, !stats.blockFrequency.scale !561		; visa id: 438

.lr.ph:                                           ; preds = %.lr.ph..lr.ph_crit_edge, %.lr.ph.preheader
; BB21 :
  %332 = phi i32 [ %365, %.lr.ph..lr.ph_crit_edge ], [ 0, %.lr.ph.preheader ]
  %333 = phi i32 [ %364, %.lr.ph..lr.ph_crit_edge ], [ 0, %.lr.ph.preheader ]
  %334 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %332, i32 0, i32 %const_reg_dword, i32 %318)
  %335 = extractvalue { i32, i32 } %334, 0		; visa id: 439
  %336 = extractvalue { i32, i32 } %334, 1		; visa id: 439
  %337 = insertelement <2 x i32> undef, i32 %335, i32 0		; visa id: 446
  %338 = insertelement <2 x i32> %337, i32 %336, i32 1		; visa id: 447
  %339 = bitcast <2 x i32> %338 to i64		; visa id: 448
  %340 = add nsw i64 %339, %323, !spirv.Decorations !556		; visa id: 450
  %341 = bitcast i64 %340 to <2 x i32>		; visa id: 451
  %342 = extractelement <2 x i32> %341, i32 0		; visa id: 455
  %343 = extractelement <2 x i32> %341, i32 1		; visa id: 455
  %344 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %342, i32 %343, i32 %7, i32 %324)
  %345 = extractvalue { i32, i32 } %344, 0
  %346 = extractvalue { i32, i32 } %344, 1
  %347 = insertelement <2 x i32> undef, i32 %345, i32 0
  %348 = insertelement <2 x i32> %347, i32 %346, i32 1
  %349 = bitcast <2 x i32> %348 to i64		; visa id: 455
  %350 = add i64 %349, %325		; visa id: 463
  %351 = bitcast i64 %350 to <2 x i32>		; visa id: 464
  %352 = extractelement <2 x i32> %351, i32 0		; visa id: 468
  %353 = extractelement <2 x i32> %351, i32 1		; visa id: 468
  %354 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %352, i32 %353, i32 %const_reg_dword5, i32 %45)
  %355 = extractvalue { i32, i32 } %354, 0
  %356 = extractvalue { i32, i32 } %354, 1
  %357 = insertelement <2 x i32> undef, i32 %355, i32 0
  %358 = insertelement <2 x i32> %357, i32 %356, i32 1
  %359 = bitcast <2 x i32> %358 to i64		; visa id: 468
  %360 = shl i64 %359, 2		; visa id: 476
  %361 = add i64 %331, %360		; visa id: 477
  %362 = inttoptr i64 %361 to ptr addrspace(1)		; visa id: 478
  %363 = load i32, ptr addrspace(1) %362, align 4		; visa id: 478
  %364 = add nsw i32 %333, %363, !spirv.Decorations !556		; visa id: 479
  %365 = add nuw nsw i32 %332, 1, !spirv.Decorations !569		; visa id: 480
  %366 = icmp slt i32 %365, %317		; visa id: 481
  br i1 %366, label %.lr.ph..lr.ph_crit_edge, label %._crit_edge, !stats.blockFrequency.digits !567, !stats.blockFrequency.scale !571		; visa id: 482

._crit_edge:                                      ; preds = %.lr.ph
; BB22 :
  %.lcssa94 = phi i32 [ %364, %.lr.ph ]
  %367 = sitofp i32 %.lcssa94 to float		; visa id: 484
  br label %368, !stats.blockFrequency.digits !567, !stats.blockFrequency.scale !561		; visa id: 485

.lr.ph..lr.ph_crit_edge:                          ; preds = %.lr.ph
; BB:
  br label %.lr.ph, !stats.blockFrequency.digits !572, !stats.blockFrequency.scale !571

368:                                              ; preds = %__igcbuiltin_u64_urem_dp.exit._crit_edge, %._crit_edge
; BB24 :
  %.lcssa = phi float [ %367, %._crit_edge ], [ 0.000000e+00, %__igcbuiltin_u64_urem_dp.exit._crit_edge ]
  %369 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %3)
  %370 = extractvalue { i32, i32 } %369, 0		; visa id: 486
  %371 = extractvalue { i32, i32 } %369, 1		; visa id: 486
  %372 = call { i32, i32 } @llvm.genx.GenISA.ptr.to.pair.p1(ptr addrspace(1) %4)
  %373 = extractvalue { i32, i32 } %372, 0		; visa id: 488
  %374 = extractvalue { i32, i32 } %372, 1		; visa id: 488
  %375 = select i1 %25, i32 %370, i32 %373		; visa id: 490
  %376 = select i1 %25, i32 %371, i32 %374		; visa id: 491
  %377 = insertelement <2 x i32> undef, i32 %375, i32 0		; visa id: 492
  %378 = insertelement <2 x i32> %377, i32 %376, i32 1		; visa id: 493
  %379 = bitcast <2 x i32> %378 to i64		; visa id: 494
  %380 = ptrtoint ptr addrspace(1) %8 to i64		; visa id: 498
  %381 = ashr exact i64 %308, 30		; visa id: 498
  %382 = add i64 %381, %380		; visa id: 499
  %383 = inttoptr i64 %382 to ptr addrspace(1)		; visa id: 500
  %384 = load float, ptr addrspace(1) %383, align 4		; visa id: 500
  %385 = ptrtoint ptr addrspace(1) %9 to i64		; visa id: 501
  %386 = add i64 %381, %385		; visa id: 501
  %387 = inttoptr i64 %386 to ptr addrspace(1)		; visa id: 502
  %388 = load i32, ptr addrspace(1) %387, align 4		; visa id: 502
  %389 = fmul reassoc nsz arcp contract float %const_reg_fp32, %384, !spirv.Decorations !573		; visa id: 503
  %390 = sitofp i32 %388 to float		; visa id: 504
  %391 = fmul reassoc nnan nsz arcp contract float %390, 5.100000e+02, !spirv.Decorations !575
  %392 = fsub reassoc nnan nsz arcp contract float %.lcssa, %391, !spirv.Decorations !575		; visa id: 505
  %393 = fmul reassoc nsz arcp contract float %389, %392, !spirv.Decorations !573		; visa id: 507
  %394 = shl i64 %40, 2		; visa id: 508
  %395 = add i64 %394, %379		; visa id: 509
  %396 = inttoptr i64 %395 to ptr addrspace(1)		; visa id: 510
  store float %393, ptr addrspace(1) %396, align 4		; visa id: 510
  ret void, !stats.blockFrequency.digits !558, !stats.blockFrequency.scale !559		; visa id: 511
}

; ------------------------------------------------
; OCL_asm10ec49003a6449c0_simd32_entry_0001.visa.ll
; ------------------------------------------------
; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSZL7combineRN4sycl3_V15queueEPKiPKfS4_PfRK4MetaiiEUlNS0_2idILi1EEEE_(ptr byval(%struct.Meta) align 8 %0, i32 %1, ptr addrspace(1) align 4 %2, i32 %3, ptr addrspace(1) align 4 %4, ptr addrspace(1) align 4 %5, ptr addrspace(1) align 4 %6, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i32 %const_reg_dword, i32 %const_reg_dword1, i32 %const_reg_dword2, i32 %const_reg_dword3, i32 %const_reg_dword4, i32 %const_reg_dword5, i64 %const_reg_qword, float %const_reg_fp32, i8 %const_reg_byte, i8 %const_reg_byte6, i8 %const_reg_byte7, i8 %const_reg_byte8, i32 %bufferOffset, i32 %bufferOffset9, i32 %bufferOffset10, i32 %bufferOffset11, i32 %bindlessOffset, i32 %bindlessOffset12, i32 %bindlessOffset13, i32 %bindlessOffset14) #0 {
; BB0 :
  %8 = extractelement <3 x i32> %globalOffset, i32 0		; visa id: 2
  %9 = extractelement <3 x i32> %enqueuedLocalSize, i32 0		; visa id: 2
  %10 = extractelement <8 x i32> %r0, i32 1		; visa id: 2
  %11 = mul i32 %9, %10		; visa id: 2
  %12 = zext i16 %localIdX to i32		; visa id: 3
  %13 = add i32 %11, %12
  %14 = add i32 %13, %8		; visa id: 4
  %15 = ashr i32 %const_reg_dword1, 31		; visa id: 5
  %16 = ashr i32 %const_reg_dword5, 31		; visa id: 6
  %17 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %const_reg_dword1, i32 %15, i32 %const_reg_dword5, i32 %16)
  %18 = extractvalue { i32, i32 } %17, 0		; visa id: 7
  %19 = extractvalue { i32, i32 } %17, 1		; visa id: 7
  %20 = insertelement <2 x i32> undef, i32 %18, i32 0		; visa id: 14
  %21 = insertelement <2 x i32> %20, i32 %19, i32 1		; visa id: 15
  %22 = bitcast <2 x i32> %21 to i64		; visa id: 16
  %23 = icmp ult i32 %19, 1		; visa id: 18
  br i1 %23, label %67, label %24, !stats.blockFrequency.digits !525, !stats.blockFrequency.scale !526		; visa id: 21

24:                                               ; preds = %7
; BB1 :
  %25 = trunc i64 %22 to i32		; visa id: 23
  %26 = uitofp i64 %22 to double		; visa id: 24
  %27 = fptrunc double %26 to float		; visa id: 25
  %28 = fdiv float 1.000000e+00, %27		; visa id: 26
  %29 = fsub double 0.000000e+00, %26
  %30 = fpext float %28 to double		; visa id: 27
  %31 = call double @llvm.fma.f64(double %29, double %30, double 1.000000e+00) #4		; visa id: 28
  %32 = fadd double %31, 0xBCF0000000000000		; visa id: 29
  %33 = call double @llvm.fma.f64(double %30, double %32, double %30) #4		; visa id: 30
  %34 = uitofp nneg i32 %14 to double		; visa id: 31
  %35 = fmul double %33, %34		; visa id: 32
  %36 = fptoui double %35 to i64		; visa id: 33
  %37 = bitcast i64 %36 to <2 x i32>		; visa id: 34
  %38 = extractelement <2 x i32> %37, i32 0		; visa id: 38
  %39 = extractelement <2 x i32> %37, i32 1		; visa id: 38
  %40 = trunc i64 %36 to i32		; visa id: 38
  %41 = mul i32 %40, %19		; visa id: 39
  %42 = icmp ult i32 %39, 1		; visa id: 40
  %43 = select i1 %42, i32 0, i32 %25		; visa id: 41
  %44 = add i32 %41, %43
  %45 = sub i32 0, %44		; visa id: 42
  %46 = insertelement <2 x i32> undef, i32 %14, i32 0		; visa id: 43
  %47 = insertelement <2 x i32> %46, i32 %45, i32 1		; visa id: 44
  %48 = bitcast <2 x i32> %47 to i64		; visa id: 45
  %49 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %38, i32 0, i32 %18, i32 0)
  %50 = extractvalue { i32, i32 } %49, 0
  %51 = extractvalue { i32, i32 } %49, 1
  %52 = insertelement <2 x i32> undef, i32 %50, i32 0
  %53 = insertelement <2 x i32> %52, i32 %51, i32 1
  %54 = bitcast <2 x i32> %53 to i64		; visa id: 49
  %55 = sub i64 %48, %54		; visa id: 57
  %56 = bitcast i64 %55 to <2 x i32>		; visa id: 58
  %57 = extractelement <2 x i32> %56, i32 0		; visa id: 62
  %58 = extractelement <2 x i32> %56, i32 1		; visa id: 62
  %59 = icmp eq i32 %58, %19
  %60 = icmp uge i32 %57, %18		; visa id: 62
  %61 = and i1 %59, %60		; visa id: 63
  %62 = icmp ugt i32 %58, %19
  %63 = or i1 %61, %62		; visa id: 65
  %64 = sext i1 %63 to i64		; visa id: 67
  %65 = sub i64 0, %64
  %66 = add i64 %36, %65		; visa id: 69
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !527, !stats.blockFrequency.scale !528		; visa id: 70

67:                                               ; preds = %7
; BB2 :
  %68 = icmp eq i32 %18, 0		; visa id: 72
  br i1 %68, label %.precompiled_u32divrem_sp.exit84_crit_edge, label %if.end.i63, !stats.blockFrequency.digits !527, !stats.blockFrequency.scale !528		; visa id: 73

.precompiled_u32divrem_sp.exit84_crit_edge:       ; preds = %67
; BB3 :
  br label %precompiled_u32divrem_sp.exit84, !stats.blockFrequency.digits !529, !stats.blockFrequency.scale !530		; visa id: 76

if.end.i63:                                       ; preds = %67
; BB4 :
  %69 = trunc nuw i64 %22 to i32		; visa id: 78
  %70 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %69)		; visa id: 79
  %conv.i64 = fptoui float %70 to i32		; visa id: 81
  %sub.i65 = sub i32 %69, %conv.i64		; visa id: 82
  %71 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %14)		; visa id: 83
  %div.i68 = fdiv float 1.000000e+00, %70, !fpmath !531		; visa id: 84
  %72 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i68, float 0xBE98000000000000, float %div.i68)		; visa id: 85
  %73 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %71, float %72)		; visa id: 86
  %conv3.i66 = fptoui float %71 to i32		; visa id: 87
  %sub4.i67 = sub i32 %14, %conv3.i66		; visa id: 88
  %conv8.i69 = fptoui float %73 to i32		; visa id: 89
  %74 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i65)		; visa id: 90
  %75 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i67)		; visa id: 91
  %76 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i69)		; visa id: 92
  %77 = fsub float 0.000000e+00, %70		; visa id: 93
  %78 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %77, float %76, float %71)		; visa id: 94
  %79 = fsub float 0.000000e+00, %74		; visa id: 95
  %80 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %79, float %76, float %75)		; visa id: 96
  %81 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %78, float %80)		; visa id: 97
  %82 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %72, float %81)		; visa id: 98
  %conv16.i72 = fptoui float %82 to i32		; visa id: 100
  %add.i73 = add i32 %conv16.i72, %conv8.i69		; visa id: 101
  %mul.i74 = mul i32 %add.i73, %69		; visa id: 102
  %sub17.i75 = sub i32 %14, %mul.i74		; visa id: 103
  %cmp.i76 = icmp uge i32 %sub17.i75, %69
  %83 = sext i1 %cmp.i76 to i32		; visa id: 104
  %84 = sub i32 0, %83
  %add19.i79 = add i32 %add.i73, %84		; visa id: 105
  br label %precompiled_u32divrem_sp.exit84, !stats.blockFrequency.digits !532, !stats.blockFrequency.scale !533		; visa id: 106

precompiled_u32divrem_sp.exit84:                  ; preds = %.precompiled_u32divrem_sp.exit84_crit_edge, %if.end.i63
; BB5 :
  %retval.0.i83 = phi i32 [ %add19.i79, %if.end.i63 ], [ -1, %.precompiled_u32divrem_sp.exit84_crit_edge ]
  %85 = zext i32 %retval.0.i83 to i64		; visa id: 107
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !527, !stats.blockFrequency.scale !528		; visa id: 108

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit84, %24
; BB6 :
  %86 = phi i64 [ %85, %precompiled_u32divrem_sp.exit84 ], [ %66, %24 ]
  %87 = icmp sgt i32 %const_reg_dword5, -1		; visa id: 109
  br i1 %87, label %129, label %88, !stats.blockFrequency.digits !525, !stats.blockFrequency.scale !526		; visa id: 110

88:                                               ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB7 :
  %89 = sext i32 %const_reg_dword5 to i64		; visa id: 112
  %90 = uitofp i64 %89 to double		; visa id: 113
  %91 = fptrunc double %90 to float		; visa id: 114
  %92 = fdiv float 1.000000e+00, %91		; visa id: 115
  %93 = fsub double 0.000000e+00, %90
  %94 = fpext float %92 to double		; visa id: 116
  %95 = call double @llvm.fma.f64(double %93, double %94, double 1.000000e+00) #4		; visa id: 117
  %96 = fadd double %95, 0xBCF0000000000000		; visa id: 118
  %97 = call double @llvm.fma.f64(double %94, double %96, double %94) #4		; visa id: 119
  %98 = uitofp nneg i32 %14 to double		; visa id: 120
  %99 = fmul double %97, %98		; visa id: 121
  %100 = fptoui double %99 to i64		; visa id: 122
  %101 = bitcast i64 %100 to <2 x i32>		; visa id: 123
  %102 = extractelement <2 x i32> %101, i32 0		; visa id: 127
  %103 = extractelement <2 x i32> %101, i32 1		; visa id: 127
  %104 = trunc i64 %100 to i32		; visa id: 127
  %105 = icmp ult i32 %103, 1		; visa id: 128
  %106 = select i1 %105, i32 0, i32 %const_reg_dword5		; visa id: 129
  %107 = sub i32 %104, %106		; visa id: 130
  %108 = insertelement <2 x i32> undef, i32 %14, i32 0		; visa id: 131
  %109 = insertelement <2 x i32> %108, i32 %107, i32 1		; visa id: 132
  %110 = bitcast <2 x i32> %109 to i64		; visa id: 133
  %111 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %102, i32 0, i32 %const_reg_dword5, i32 0)
  %112 = extractvalue { i32, i32 } %111, 0
  %113 = extractvalue { i32, i32 } %111, 1
  %114 = insertelement <2 x i32> undef, i32 %112, i32 0
  %115 = insertelement <2 x i32> %114, i32 %113, i32 1
  %116 = bitcast <2 x i32> %115 to i64		; visa id: 137
  %117 = sub i64 %110, %116		; visa id: 145
  %118 = bitcast i64 %117 to <2 x i32>		; visa id: 146
  %119 = extractelement <2 x i32> %118, i32 0		; visa id: 150
  %120 = extractelement <2 x i32> %118, i32 1		; visa id: 150
  %121 = icmp eq i32 %120, %16
  %122 = icmp uge i32 %119, %const_reg_dword5		; visa id: 150
  %123 = and i1 %121, %122		; visa id: 151
  %124 = icmp ugt i32 %120, %16
  %125 = or i1 %123, %124		; visa id: 153
  %126 = sext i1 %125 to i64		; visa id: 155
  %127 = sub i64 0, %126
  %128 = add i64 %100, %127		; visa id: 157
  br label %__igcbuiltin_u64_udiv_dp.exit37, !stats.blockFrequency.digits !534, !stats.blockFrequency.scale !533		; visa id: 158

129:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB8 :
  %tobool.i39 = icmp eq i32 %const_reg_dword5, 0		; visa id: 160
  br i1 %tobool.i39, label %.precompiled_u32divrem_sp.exit61_crit_edge, label %if.end.i40, !stats.blockFrequency.digits !532, !stats.blockFrequency.scale !528		; visa id: 161

.precompiled_u32divrem_sp.exit61_crit_edge:       ; preds = %129
; BB9 :
  br label %precompiled_u32divrem_sp.exit61, !stats.blockFrequency.digits !535, !stats.blockFrequency.scale !533		; visa id: 164

if.end.i40:                                       ; preds = %129
; BB10 :
  %130 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword5)		; visa id: 166
  %conv.i41 = fptoui float %130 to i32		; visa id: 168
  %sub.i42 = sub i32 %const_reg_dword5, %conv.i41		; visa id: 169
  %131 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %14)		; visa id: 170
  %div.i45 = fdiv float 1.000000e+00, %130, !fpmath !531		; visa id: 171
  %132 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i45, float 0xBE98000000000000, float %div.i45)		; visa id: 172
  %133 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %131, float %132)		; visa id: 173
  %conv3.i43 = fptoui float %131 to i32		; visa id: 174
  %sub4.i44 = sub i32 %14, %conv3.i43		; visa id: 175
  %conv8.i46 = fptoui float %133 to i32		; visa id: 176
  %134 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i42)		; visa id: 177
  %135 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i44)		; visa id: 178
  %136 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i46)		; visa id: 179
  %137 = fsub float 0.000000e+00, %130		; visa id: 180
  %138 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %137, float %136, float %131)		; visa id: 181
  %139 = fsub float 0.000000e+00, %134		; visa id: 182
  %140 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %139, float %136, float %135)		; visa id: 183
  %141 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %138, float %140)		; visa id: 184
  %142 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %132, float %141)		; visa id: 185
  %conv16.i49 = fptoui float %142 to i32		; visa id: 187
  %add.i50 = add i32 %conv16.i49, %conv8.i46		; visa id: 188
  %mul.i51 = mul i32 %add.i50, %const_reg_dword5		; visa id: 189
  %sub17.i52 = sub i32 %14, %mul.i51		; visa id: 190
  %cmp.i53 = icmp uge i32 %sub17.i52, %const_reg_dword5
  %143 = sext i1 %cmp.i53 to i32		; visa id: 191
  %144 = sub i32 0, %143
  %add19.i56 = add i32 %add.i50, %144		; visa id: 192
  br label %precompiled_u32divrem_sp.exit61, !stats.blockFrequency.digits !536, !stats.blockFrequency.scale !533		; visa id: 193

precompiled_u32divrem_sp.exit61:                  ; preds = %.precompiled_u32divrem_sp.exit61_crit_edge, %if.end.i40
; BB11 :
  %retval.0.i60 = phi i32 [ %add19.i56, %if.end.i40 ], [ -1, %.precompiled_u32divrem_sp.exit61_crit_edge ]
  %145 = zext i32 %retval.0.i60 to i64		; visa id: 194
  br label %__igcbuiltin_u64_udiv_dp.exit37, !stats.blockFrequency.digits !532, !stats.blockFrequency.scale !528		; visa id: 195

__igcbuiltin_u64_udiv_dp.exit37:                  ; preds = %precompiled_u32divrem_sp.exit61, %88
; BB12 :
  %146 = phi i64 [ %145, %precompiled_u32divrem_sp.exit61 ], [ %128, %88 ]
  %147 = bitcast i64 %146 to <2 x i32>		; visa id: 196
  %148 = extractelement <2 x i32> %147, i32 0		; visa id: 200
  %149 = extractelement <2 x i32> %147, i32 1		; visa id: 200
  %150 = or i32 %149, %15		; visa id: 200
  %151 = icmp ult i32 %150, 1		; visa id: 202
  br i1 %151, label %207, label %152, !stats.blockFrequency.digits !525, !stats.blockFrequency.scale !526		; visa id: 203

152:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit37
; BB13 :
  %153 = sext i32 %const_reg_dword1 to i64		; visa id: 205
  %154 = uitofp i64 %153 to double		; visa id: 206
  %155 = fptrunc double %154 to float		; visa id: 207
  %156 = fdiv float 1.000000e+00, %155		; visa id: 208
  %157 = fsub double 0.000000e+00, %154
  %158 = fpext float %156 to double		; visa id: 209
  %159 = call double @llvm.fma.f64(double %157, double %158, double 1.000000e+00) #4		; visa id: 210
  %160 = fadd double %159, 0xBCF0000000000000		; visa id: 211
  %161 = call double @llvm.fma.f64(double %158, double %160, double %158) #4		; visa id: 212
  %162 = bitcast i64 %146 to <2 x i32>		; visa id: 213
  %163 = extractelement <2 x i32> %162, i32 1		; visa id: 215
  %164 = uitofp i32 %163 to double		; visa id: 215
  %165 = fmul double %161, %164		; visa id: 216
  %166 = fptoui double %165 to i32		; visa id: 217
  %167 = mul i32 %const_reg_dword1, %166		; visa id: 218
  %168 = sub i32 %163, %167		; visa id: 219
  %169 = trunc i64 %146 to i32		; visa id: 220
  %170 = uitofp i32 %168 to double		; visa id: 221
  %171 = uitofp i32 %169 to double		; visa id: 222
  %172 = call double @llvm.fma.f64(double %170, double 0x41F0000000000000, double %171) #4		; visa id: 223
  %173 = fmul double %161, %172		; visa id: 225
  %174 = fptoui double %173 to i64		; visa id: 226
  %175 = bitcast i64 %174 to <2 x i32>		; visa id: 227
  %176 = extractelement <2 x i32> %175, i32 0		; visa id: 231
  %177 = extractelement <2 x i32> %175, i32 1		; visa id: 231
  %178 = trunc i64 %174 to i32		; visa id: 231
  %isneg = icmp slt i32 %const_reg_dword1, 0		; visa id: 232
  %.neg86 = select i1 %isneg, i32 %178, i32 0		; visa id: 233
  %179 = icmp ult i32 %177, 1		; visa id: 234
  %180 = select i1 %179, i32 0, i32 %const_reg_dword1		; visa id: 235
  %181 = sub i32 %168, %180
  %182 = add i32 %.neg86, %181		; visa id: 236
  %183 = insertelement <2 x i32> undef, i32 %148, i32 0		; visa id: 237
  %184 = insertelement <2 x i32> %183, i32 %182, i32 1		; visa id: 238
  %185 = bitcast <2 x i32> %184 to i64		; visa id: 239
  %186 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %176, i32 0, i32 %const_reg_dword1, i32 0)
  %187 = extractvalue { i32, i32 } %186, 0
  %188 = extractvalue { i32, i32 } %186, 1
  %189 = insertelement <2 x i32> undef, i32 %187, i32 0
  %190 = insertelement <2 x i32> %189, i32 %188, i32 1
  %191 = bitcast <2 x i32> %190 to i64		; visa id: 243
  %192 = sub i64 %185, %191		; visa id: 251
  %193 = bitcast i64 %192 to <2 x i32>		; visa id: 252
  %194 = extractelement <2 x i32> %193, i32 0		; visa id: 256
  %195 = extractelement <2 x i32> %193, i32 1		; visa id: 256
  %196 = icmp eq i32 %195, %15
  %197 = icmp ult i32 %194, %const_reg_dword1		; visa id: 256
  %198 = and i1 %196, %197		; visa id: 257
  %199 = icmp ult i32 %195, %15
  %200 = or i1 %198, %199		; visa id: 259
  %201 = select i1 %200, i32 0, i32 %const_reg_dword1		; visa id: 261
  %202 = select i1 %200, i32 0, i32 %15		; visa id: 262
  %203 = insertelement <2 x i32> undef, i32 %201, i32 0		; visa id: 263
  %204 = insertelement <2 x i32> %203, i32 %202, i32 1		; visa id: 264
  %205 = bitcast <2 x i32> %204 to i64		; visa id: 265
  %206 = sub i64 %192, %205		; visa id: 269
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !527, !stats.blockFrequency.scale !528		; visa id: 270

207:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit37
; BB14 :
  %tobool.i = icmp eq i32 %const_reg_dword1, 0		; visa id: 272
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !527, !stats.blockFrequency.scale !528		; visa id: 273

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %207
; BB15 :
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !529, !stats.blockFrequency.scale !530		; visa id: 276

if.end.i:                                         ; preds = %207
; BB16 :
  %208 = trunc nuw i64 %146 to i32		; visa id: 278
  %209 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %const_reg_dword1)		; visa id: 279
  %conv.i = fptoui float %209 to i32		; visa id: 281
  %sub.i = sub i32 %const_reg_dword1, %conv.i		; visa id: 282
  %210 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %208)		; visa id: 283
  %div.i = fdiv float 1.000000e+00, %209, !fpmath !531		; visa id: 284
  %211 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)		; visa id: 285
  %212 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %210, float %211)		; visa id: 286
  %conv3.i = fptoui float %210 to i32		; visa id: 287
  %sub4.i = sub i32 %208, %conv3.i		; visa id: 288
  %conv8.i = fptoui float %212 to i32		; visa id: 289
  %213 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)		; visa id: 290
  %214 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)		; visa id: 291
  %215 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)		; visa id: 292
  %216 = fsub float 0.000000e+00, %209		; visa id: 293
  %217 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %216, float %215, float %210)		; visa id: 294
  %218 = fsub float 0.000000e+00, %213		; visa id: 295
  %219 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %218, float %215, float %214)		; visa id: 296
  %220 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %217, float %219)		; visa id: 297
  %221 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %211, float %220)		; visa id: 298
  %conv16.i = fptoui float %221 to i32		; visa id: 300
  %add.i = add i32 %conv16.i, %conv8.i		; visa id: 301
  %mul.i = mul i32 %add.i, %const_reg_dword1		; visa id: 302
  %sub17.i = sub i32 %208, %mul.i		; visa id: 303
  %cmp.i.not = icmp ult i32 %sub17.i, %const_reg_dword1		; visa id: 304
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %const_reg_dword1		; visa id: 305
  %sub21.i = sub i32 %sub17.i, %and20.i		; visa id: 306
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !532, !stats.blockFrequency.scale !533		; visa id: 307

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
; BB17 :
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %222 = zext i32 %storemerge.i to i64		; visa id: 308
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !527, !stats.blockFrequency.scale !528		; visa id: 309

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %152
; BB18 :
  %223 = phi i64 [ %222, %precompiled_u32divrem_sp.exit ], [ %206, %152 ]
  %224 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %148, i32 %149, i32 %const_reg_dword5, i32 %16)
  %225 = extractvalue { i32, i32 } %224, 0		; visa id: 310
  %226 = extractvalue { i32, i32 } %224, 1		; visa id: 310
  %227 = zext nneg i32 %14 to i64		; visa id: 317
  %228 = icmp sgt i32 %1, 0		; visa id: 318
  br i1 %228, label %.lr.ph.preheader, label %__igcbuiltin_u64_urem_dp.exit._crit_edge, !stats.blockFrequency.digits !525, !stats.blockFrequency.scale !526		; visa id: 319

__igcbuiltin_u64_urem_dp.exit._crit_edge:         ; preds = %__igcbuiltin_u64_urem_dp.exit
; BB19 :
  br label %274, !stats.blockFrequency.digits !534, !stats.blockFrequency.scale !533		; visa id: 322

.lr.ph.preheader:                                 ; preds = %__igcbuiltin_u64_urem_dp.exit
; BB20 :
  %229 = insertelement <2 x i32> undef, i32 %225, i32 0		; visa id: 324
  %230 = insertelement <2 x i32> %229, i32 %226, i32 1		; visa id: 325
  %231 = bitcast <2 x i32> %230 to i64		; visa id: 326
  %232 = sub nsw i64 %227, %231		; visa id: 330
  %233 = shl nsw i32 %1, 1, !spirv.Decorations !537		; visa id: 331
  %234 = ashr i32 %const_reg_dword, 31		; visa id: 332
  %235 = ashr i32 %3, 31		; visa id: 333
  %236 = ptrtoint ptr addrspace(1) %2 to i64		; visa id: 334
  br label %.lr.ph, !stats.blockFrequency.digits !532, !stats.blockFrequency.scale !528		; visa id: 336

.lr.ph:                                           ; preds = %.lr.ph..lr.ph_crit_edge, %.lr.ph.preheader
; BB21 :
  %237 = phi i32 [ %271, %.lr.ph..lr.ph_crit_edge ], [ 0, %.lr.ph.preheader ]
  %238 = phi i32 [ %270, %.lr.ph..lr.ph_crit_edge ], [ 0, %.lr.ph.preheader ]
  %239 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %237, i32 0, i32 %const_reg_dword, i32 %234)
  %240 = extractvalue { i32, i32 } %239, 0		; visa id: 337
  %241 = extractvalue { i32, i32 } %239, 1		; visa id: 337
  %242 = insertelement <2 x i32> undef, i32 %240, i32 0		; visa id: 344
  %243 = insertelement <2 x i32> %242, i32 %241, i32 1		; visa id: 345
  %244 = bitcast <2 x i32> %243 to i64		; visa id: 346
  %245 = add nsw i64 %244, %86, !spirv.Decorations !537		; visa id: 348
  %246 = bitcast i64 %245 to <2 x i32>		; visa id: 349
  %247 = extractelement <2 x i32> %246, i32 0		; visa id: 353
  %248 = extractelement <2 x i32> %246, i32 1		; visa id: 353
  %249 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %247, i32 %248, i32 %3, i32 %235)
  %250 = extractvalue { i32, i32 } %249, 0
  %251 = extractvalue { i32, i32 } %249, 1
  %252 = insertelement <2 x i32> undef, i32 %250, i32 0
  %253 = insertelement <2 x i32> %252, i32 %251, i32 1
  %254 = bitcast <2 x i32> %253 to i64		; visa id: 353
  %255 = add i64 %254, %223		; visa id: 361
  %256 = bitcast i64 %255 to <2 x i32>		; visa id: 362
  %257 = extractelement <2 x i32> %256, i32 0		; visa id: 366
  %258 = extractelement <2 x i32> %256, i32 1		; visa id: 366
  %259 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %257, i32 %258, i32 %const_reg_dword5, i32 %16)
  %260 = extractvalue { i32, i32 } %259, 0
  %261 = extractvalue { i32, i32 } %259, 1
  %262 = insertelement <2 x i32> undef, i32 %260, i32 0
  %263 = insertelement <2 x i32> %262, i32 %261, i32 1
  %264 = bitcast <2 x i32> %263 to i64		; visa id: 366
  %265 = add i64 %232, %264		; visa id: 374
  %266 = shl i64 %265, 2		; visa id: 375
  %267 = add i64 %266, %236		; visa id: 376
  %268 = inttoptr i64 %267 to ptr addrspace(1)		; visa id: 377
  %269 = load i32, ptr addrspace(1) %268, align 4		; visa id: 377
  %270 = add nsw i32 %238, %269, !spirv.Decorations !537		; visa id: 378
  %271 = add nuw nsw i32 %237, 1, !spirv.Decorations !539		; visa id: 379
  %272 = icmp slt i32 %271, %233		; visa id: 380
  br i1 %272, label %.lr.ph..lr.ph_crit_edge, label %._crit_edge, !stats.blockFrequency.digits !532, !stats.blockFrequency.scale !541		; visa id: 381

._crit_edge:                                      ; preds = %.lr.ph
; BB22 :
  %.lcssa88 = phi i32 [ %270, %.lr.ph ]
  %273 = sitofp i32 %.lcssa88 to float		; visa id: 383
  br label %274, !stats.blockFrequency.digits !532, !stats.blockFrequency.scale !528		; visa id: 384

.lr.ph..lr.ph_crit_edge:                          ; preds = %.lr.ph
; BB:
  br label %.lr.ph, !stats.blockFrequency.digits !542, !stats.blockFrequency.scale !541

274:                                              ; preds = %__igcbuiltin_u64_urem_dp.exit._crit_edge, %._crit_edge
; BB24 :
  %.lcssa = phi float [ %273, %._crit_edge ], [ 0.000000e+00, %__igcbuiltin_u64_urem_dp.exit._crit_edge ]
  %275 = ptrtoint ptr addrspace(1) %5 to i64		; visa id: 385
  %276 = shl i64 %223, 2		; visa id: 385
  %277 = add i64 %276, %275		; visa id: 386
  %278 = inttoptr i64 %277 to ptr addrspace(1)		; visa id: 387
  %279 = load float, ptr addrspace(1) %278, align 4		; visa id: 387
  %280 = ptrtoint ptr addrspace(1) %6 to i64		; visa id: 388
  %281 = add i64 %276, %280		; visa id: 388
  %282 = inttoptr i64 %281 to ptr addrspace(1)		; visa id: 389
  %283 = load i32, ptr addrspace(1) %282, align 4		; visa id: 389
  %284 = fmul reassoc nsz arcp contract float %const_reg_fp32, %279, !spirv.Decorations !543		; visa id: 390
  %285 = sitofp i32 %283 to float		; visa id: 391
  %286 = fmul reassoc nnan nsz arcp contract float %285, 5.100000e+02, !spirv.Decorations !545
  %287 = fsub reassoc nnan nsz arcp contract float %.lcssa, %286, !spirv.Decorations !545		; visa id: 392
  %288 = fmul reassoc nsz arcp contract float %284, %287, !spirv.Decorations !543		; visa id: 394
  %289 = ptrtoint ptr addrspace(1) %4 to i64		; visa id: 395
  %290 = shl nuw nsw i64 %227, 2		; visa id: 395
  %291 = add i64 %290, %289		; visa id: 396
  %292 = inttoptr i64 %291 to ptr addrspace(1)		; visa id: 397
  store float %288, ptr addrspace(1) %292, align 4		; visa id: 397
  ret void, !stats.blockFrequency.digits !525, !stats.blockFrequency.scale !526		; visa id: 398
}

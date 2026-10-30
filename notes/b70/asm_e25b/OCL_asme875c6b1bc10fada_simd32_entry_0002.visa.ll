; ------------------------------------------------
; OCL_asme875c6b1bc10fada_simd32_entry_0002.visa.ll
; ------------------------------------------------
; Function Attrs: convergent nounwind null_pointer_is_valid
define spir_kernel void @_ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_(i32 %0, ptr addrspace(1) align 4 %1, ptr addrspace(1) align 4 %2, ptr addrspace(1) align 4 %3, ptr addrspace(1) align 4 %4, <8 x i32> %r0, <3 x i32> %globalOffset, <3 x i32> %enqueuedLocalSize, i16 %localIdX, i16 %localIdY, i16 %localIdZ, ptr %privateBase, i32 %bufferOffset, i32 %bufferOffset1, i32 %bufferOffset2, i32 %bufferOffset3, i32 %bindlessOffset, i32 %bindlessOffset4, i32 %bindlessOffset5, i32 %bindlessOffset6) #0 {
; BB0 :
  %6 = extractelement <3 x i32> %globalOffset, i32 0		; visa id: 2
  %7 = extractelement <3 x i32> %enqueuedLocalSize, i32 0		; visa id: 2
  %8 = extractelement <8 x i32> %r0, i32 1		; visa id: 2
  %9 = mul i32 %7, %8		; visa id: 2
  %10 = zext i16 %localIdX to i32		; visa id: 3
  %11 = add i32 %9, %10
  %12 = add i32 %11, %6		; visa id: 4
  %13 = ashr i32 %0, 31		; visa id: 5
  %14 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %0, i32 %13, i32 640, i32 0)
  %15 = extractvalue { i32, i32 } %14, 0		; visa id: 6
  %16 = extractvalue { i32, i32 } %14, 1		; visa id: 6
  %17 = insertelement <2 x i32> undef, i32 %15, i32 0		; visa id: 13
  %18 = insertelement <2 x i32> %17, i32 %16, i32 1		; visa id: 14
  %19 = bitcast <2 x i32> %18 to i64		; visa id: 15
  %20 = icmp ult i32 %16, 1		; visa id: 17
  br i1 %20, label %65, label %21, !stats.blockFrequency.digits !615, !stats.blockFrequency.scale !616		; visa id: 20

21:                                               ; preds = %5
; BB1 :
  %22 = trunc i64 %19 to i32		; visa id: 22
  %23 = uitofp i64 %19 to double		; visa id: 23
  %24 = fptrunc double %23 to float		; visa id: 24
  %25 = fdiv float 1.000000e+00, %24		; visa id: 25
  %26 = fsub double 0.000000e+00, %23
  %27 = fpext float %25 to double		; visa id: 26
  %28 = call double @llvm.fma.f64(double %26, double %27, double 1.000000e+00) #4		; visa id: 27
  %29 = fadd double %28, 0xBCF0000000000000		; visa id: 28
  %30 = call double @llvm.fma.f64(double %27, double %29, double %27) #4		; visa id: 29
  %31 = uitofp nneg i32 %12 to double		; visa id: 30
  %32 = fmul double %30, %31		; visa id: 31
  %33 = fptoui double %32 to i64		; visa id: 32
  %34 = bitcast i64 %33 to <2 x i32>		; visa id: 33
  %35 = extractelement <2 x i32> %34, i32 0		; visa id: 37
  %36 = extractelement <2 x i32> %34, i32 1		; visa id: 37
  %37 = trunc i64 %33 to i32		; visa id: 37
  %38 = mul i32 %37, %16		; visa id: 38
  %39 = icmp ult i32 %36, 1		; visa id: 39
  %40 = select i1 %39, i32 0, i32 %22		; visa id: 40
  %41 = add i32 %38, %40
  %42 = sub i32 0, %41		; visa id: 41
  %43 = insertelement <2 x i32> undef, i32 %12, i32 0		; visa id: 42
  %44 = insertelement <2 x i32> %43, i32 %42, i32 1		; visa id: 43
  %45 = bitcast <2 x i32> %44 to i64		; visa id: 44
  %46 = and i32 %15, -128		; visa id: 48
  %47 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %35, i32 0, i32 %46, i32 0)
  %48 = extractvalue { i32, i32 } %47, 0
  %49 = extractvalue { i32, i32 } %47, 1
  %50 = insertelement <2 x i32> undef, i32 %48, i32 0
  %51 = insertelement <2 x i32> %50, i32 %49, i32 1
  %52 = bitcast <2 x i32> %51 to i64		; visa id: 49
  %53 = sub i64 %45, %52		; visa id: 57
  %54 = bitcast i64 %53 to <2 x i32>		; visa id: 58
  %55 = extractelement <2 x i32> %54, i32 0		; visa id: 62
  %56 = extractelement <2 x i32> %54, i32 1		; visa id: 62
  %57 = icmp eq i32 %56, %16
  %58 = icmp uge i32 %55, %15		; visa id: 62
  %59 = and i1 %57, %58		; visa id: 63
  %60 = icmp ugt i32 %56, %16
  %61 = or i1 %59, %60		; visa id: 65
  %62 = sext i1 %61 to i64		; visa id: 67
  %63 = sub i64 0, %62
  %64 = add i64 %33, %63		; visa id: 69
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !617, !stats.blockFrequency.scale !616		; visa id: 70

65:                                               ; preds = %5
; BB2 :
  %tobool.i27 = icmp eq i32 %0, 0		; visa id: 72
  br i1 %tobool.i27, label %.precompiled_u32divrem_sp.exit49_crit_edge, label %if.end.i28, !stats.blockFrequency.digits !617, !stats.blockFrequency.scale !616		; visa id: 73

if.end.i28:                                       ; preds = %65
; BB3 :
  %66 = trunc nuw i64 %19 to i32		; visa id: 75
  %67 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %66)		; visa id: 76
  %conv.i29 = fptoui float %67 to i32		; visa id: 78
  %sub.i30 = sub i32 %66, %conv.i29		; visa id: 79
  %68 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %12)		; visa id: 80
  %div.i33 = fdiv float 1.000000e+00, %67, !fpmath !618		; visa id: 81
  %69 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i33, float 0xBE98000000000000, float %div.i33)		; visa id: 82
  %70 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %68, float %69)		; visa id: 83
  %conv3.i31 = fptoui float %68 to i32		; visa id: 84
  %sub4.i32 = sub i32 %12, %conv3.i31		; visa id: 85
  %conv8.i34 = fptoui float %70 to i32		; visa id: 86
  %71 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i30)		; visa id: 87
  %72 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i32)		; visa id: 88
  %73 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i34)		; visa id: 89
  %74 = fsub float 0.000000e+00, %67		; visa id: 90
  %75 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %74, float %73, float %68)		; visa id: 91
  %76 = fsub float 0.000000e+00, %71		; visa id: 92
  %77 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %76, float %73, float %72)		; visa id: 93
  %78 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %75, float %77)		; visa id: 94
  %79 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %69, float %78)		; visa id: 95
  %conv16.i37 = fptoui float %79 to i32		; visa id: 97
  %add.i38 = add i32 %conv16.i37, %conv8.i34		; visa id: 98
  %mul.i39 = mul i32 %add.i38, %66		; visa id: 99
  %sub17.i40 = sub i32 %12, %mul.i39		; visa id: 100
  %cmp.i41 = icmp uge i32 %sub17.i40, %66
  %80 = sext i1 %cmp.i41 to i32		; visa id: 101
  %81 = sub i32 0, %80
  %add19.i44 = add i32 %add.i38, %81		; visa id: 102
  br label %precompiled_u32divrem_sp.exit49, !stats.blockFrequency.digits !619, !stats.blockFrequency.scale !616		; visa id: 103

.precompiled_u32divrem_sp.exit49_crit_edge:       ; preds = %65
; BB4 :
  br label %precompiled_u32divrem_sp.exit49, !stats.blockFrequency.digits !620, !stats.blockFrequency.scale !616		; visa id: 106

precompiled_u32divrem_sp.exit49:                  ; preds = %.precompiled_u32divrem_sp.exit49_crit_edge, %if.end.i28
; BB5 :
  %retval.0.i48 = phi i32 [ %add19.i44, %if.end.i28 ], [ -1, %.precompiled_u32divrem_sp.exit49_crit_edge ]
  %82 = zext i32 %retval.0.i48 to i64		; visa id: 107
  br label %__igcbuiltin_u64_udiv_dp.exit, !stats.blockFrequency.digits !617, !stats.blockFrequency.scale !616		; visa id: 108

__igcbuiltin_u64_udiv_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit49, %21
; BB6 :
  %83 = phi i64 [ %82, %precompiled_u32divrem_sp.exit49 ], [ %64, %21 ]
  %q_appx = call i32 @llvm.genx.GenISA.umulH.i32(i32 %12, i32 -858993459)		; visa id: 109
  %q_appx25 = lshr i32 %q_appx, 9		; visa id: 110
  %84 = icmp sgt i32 %0, -1		; visa id: 111
  br i1 %84, label %129, label %85, !stats.blockFrequency.digits !615, !stats.blockFrequency.scale !616		; visa id: 112

85:                                               ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB7 :
  %86 = sext i32 %0 to i64		; visa id: 114
  %87 = uitofp i64 %86 to double		; visa id: 115
  %88 = fptrunc double %87 to float		; visa id: 116
  %89 = fdiv float 1.000000e+00, %88		; visa id: 117
  %90 = fsub double 0.000000e+00, %87
  %91 = fpext float %89 to double		; visa id: 118
  %92 = call double @llvm.fma.f64(double %90, double %91, double 1.000000e+00) #4		; visa id: 119
  %93 = fadd double %92, 0xBCF0000000000000		; visa id: 120
  %94 = call double @llvm.fma.f64(double %91, double %93, double %91) #4		; visa id: 121
  %95 = uitofp nneg i32 %q_appx25 to double		; visa id: 122
  %96 = fmul double %94, %95		; visa id: 123
  %97 = fptoui double %96 to i64		; visa id: 124
  %98 = bitcast i64 %97 to <2 x i32>		; visa id: 125
  %99 = extractelement <2 x i32> %98, i32 0		; visa id: 129
  %100 = extractelement <2 x i32> %98, i32 1		; visa id: 129
  %101 = trunc i64 %97 to i32		; visa id: 129
  %102 = icmp ult i32 %100, 1		; visa id: 130
  %103 = select i1 %102, i32 0, i32 %0		; visa id: 131
  %104 = sub i32 %101, %103		; visa id: 132
  %105 = insertelement <2 x i32> undef, i32 %q_appx25, i32 0		; visa id: 133
  %106 = insertelement <2 x i32> %105, i32 %104, i32 1		; visa id: 134
  %107 = bitcast <2 x i32> %106 to i64		; visa id: 135
  %108 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %99, i32 0, i32 %0, i32 0)
  %109 = extractvalue { i32, i32 } %108, 0
  %110 = extractvalue { i32, i32 } %108, 1
  %111 = insertelement <2 x i32> undef, i32 %109, i32 0
  %112 = insertelement <2 x i32> %111, i32 %110, i32 1
  %113 = bitcast <2 x i32> %112 to i64		; visa id: 139
  %114 = sub i64 %107, %113		; visa id: 147
  %115 = bitcast i64 %114 to <2 x i32>		; visa id: 148
  %116 = extractelement <2 x i32> %115, i32 0		; visa id: 152
  %117 = extractelement <2 x i32> %115, i32 1		; visa id: 152
  %118 = icmp eq i32 %117, %13
  %119 = icmp ult i32 %116, %0		; visa id: 152
  %120 = and i1 %118, %119		; visa id: 153
  %121 = icmp ult i32 %117, %13
  %122 = or i1 %120, %121		; visa id: 155
  %123 = select i1 %122, i32 0, i32 %0		; visa id: 157
  %124 = select i1 %122, i32 0, i32 %13		; visa id: 158
  %125 = insertelement <2 x i32> undef, i32 %123, i32 0		; visa id: 159
  %126 = insertelement <2 x i32> %125, i32 %124, i32 1		; visa id: 160
  %127 = bitcast <2 x i32> %126 to i64		; visa id: 161
  %128 = sub i64 %114, %127		; visa id: 165
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !621, !stats.blockFrequency.scale !616		; visa id: 166

129:                                              ; preds = %__igcbuiltin_u64_udiv_dp.exit
; BB8 :
  %tobool.i = icmp eq i32 %0, 0		; visa id: 168
  br i1 %tobool.i, label %.precompiled_u32divrem_sp.exit_crit_edge, label %if.end.i, !stats.blockFrequency.digits !622, !stats.blockFrequency.scale !616		; visa id: 169

if.end.i:                                         ; preds = %129
; BB9 :
  %130 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %0)		; visa id: 171
  %conv.i = fptoui float %130 to i32		; visa id: 173
  %sub.i = sub i32 %0, %conv.i		; visa id: 174
  %131 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %q_appx25)		; visa id: 175
  %div.i = fdiv float 1.000000e+00, %130, !fpmath !618		; visa id: 176
  %132 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %div.i, float 0xBE98000000000000, float %div.i)		; visa id: 177
  %133 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %131, float %132)		; visa id: 178
  %conv3.i = fptoui float %131 to i32		; visa id: 179
  %sub4.i = sub i32 %q_appx25, %conv3.i		; visa id: 180
  %conv8.i = fptoui float %133 to i32		; visa id: 181
  %134 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub.i)		; visa id: 182
  %135 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %sub4.i)		; visa id: 183
  %136 = call float @llvm.genx.GenISA.uitof.rtz.f32.i32(i32 %conv8.i)		; visa id: 184
  %137 = fsub float 0.000000e+00, %130		; visa id: 185
  %138 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %137, float %136, float %131)		; visa id: 186
  %139 = fsub float 0.000000e+00, %134		; visa id: 187
  %140 = call float @llvm.genx.GenISA.fma.rtz.f32.f32.f32.f32(float %139, float %136, float %135)		; visa id: 188
  %141 = call float @llvm.genx.GenISA.add.rtz.f32.f32.f32(float %138, float %140)		; visa id: 189
  %142 = call float @llvm.genx.GenISA.mul.rtz.f32.f32.f32(float %132, float %141)		; visa id: 190
  %conv16.i = fptoui float %142 to i32		; visa id: 192
  %add.i = add i32 %conv16.i, %conv8.i		; visa id: 193
  %mul.i = mul i32 %add.i, %0		; visa id: 194
  %sub17.i = sub i32 %q_appx25, %mul.i		; visa id: 195
  %cmp.i.not = icmp ult i32 %sub17.i, %0		; visa id: 196
  %and20.i = select i1 %cmp.i.not, i32 0, i32 %0		; visa id: 197
  %sub21.i = sub i32 %sub17.i, %and20.i		; visa id: 198
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !623, !stats.blockFrequency.scale !616		; visa id: 199

.precompiled_u32divrem_sp.exit_crit_edge:         ; preds = %129
; BB10 :
  br label %precompiled_u32divrem_sp.exit, !stats.blockFrequency.digits !624, !stats.blockFrequency.scale !616		; visa id: 202

precompiled_u32divrem_sp.exit:                    ; preds = %.precompiled_u32divrem_sp.exit_crit_edge, %if.end.i
; BB11 :
  %storemerge.i = phi i32 [ %sub21.i, %if.end.i ], [ -1, %.precompiled_u32divrem_sp.exit_crit_edge ]
  %143 = zext i32 %storemerge.i to i64		; visa id: 203
  br label %__igcbuiltin_u64_urem_dp.exit, !stats.blockFrequency.digits !622, !stats.blockFrequency.scale !616		; visa id: 204

__igcbuiltin_u64_urem_dp.exit:                    ; preds = %precompiled_u32divrem_sp.exit, %85
; BB12 :
  %144 = phi i64 [ %143, %precompiled_u32divrem_sp.exit ], [ %128, %85 ]
  %.neg = mul nsw i32 %q_appx25, -640
  %145 = add nsw i32 %.neg, %12		; visa id: 205
  %146 = ptrtoint ptr addrspace(1) %1 to i64		; visa id: 206
  %147 = zext i32 %145 to i64		; visa id: 206
  %148 = shl nuw nsw i64 %147, 2		; visa id: 207
  %149 = add i64 %148, %146		; visa id: 208
  %150 = shl nuw nsw i64 %83, 4, !spirv.Decorations !625		; visa id: 209
  %151 = add nuw nsw i64 %150, %144, !spirv.Decorations !625		; visa id: 210
  %152 = bitcast i64 %151 to <2 x i32>		; visa id: 211
  %153 = extractelement <2 x i32> %152, i32 0		; visa id: 215
  %154 = extractelement <2 x i32> %152, i32 1		; visa id: 215
  %155 = call { i32, i32 } @llvm.genx.GenISA.mul.pair(i32 %153, i32 %154, i32 2560, i32 0)
  %156 = extractvalue { i32, i32 } %155, 0
  %157 = extractvalue { i32, i32 } %155, 1
  %158 = insertelement <2 x i32> undef, i32 %156, i32 0
  %159 = insertelement <2 x i32> %158, i32 %157, i32 1
  %160 = bitcast <2 x i32> %159 to i64		; visa id: 215
  %161 = add i64 %149, %160		; visa id: 223
  %162 = inttoptr i64 %161 to ptr addrspace(1)		; visa id: 224
  %163 = load i32, ptr addrspace(1) %162, align 4		; visa id: 224
  %164 = add i64 %161, 409600
  %165 = inttoptr i64 %164 to ptr addrspace(1)
  %166 = load i32, ptr addrspace(1) %165, align 4		; visa id: 225
  %167 = shl i64 %144, 2		; visa id: 226
  %168 = ptrtoint ptr addrspace(1) %3 to i64		; visa id: 227
  %169 = add i64 %167, %168		; visa id: 227
  %170 = inttoptr i64 %169 to ptr addrspace(1)		; visa id: 228
  %171 = load float, ptr addrspace(1) %170, align 4		; visa id: 228
  %172 = ptrtoint ptr addrspace(1) %4 to i64		; visa id: 229
  %173 = add i64 %167, %172		; visa id: 229
  %174 = inttoptr i64 %173 to ptr addrspace(1)		; visa id: 230
  %175 = load i32, ptr addrspace(1) %174, align 4		; visa id: 230
  %176 = add nsw i32 %163, %166, !spirv.Decorations !628		; visa id: 231
  %177 = fmul reassoc nsz arcp contract float %171, 0x3F7B717580000000, !spirv.Decorations !629		; visa id: 232
  %178 = sitofp i32 %176 to float		; visa id: 233
  %179 = sitofp i32 %175 to float		; visa id: 234
  %180 = fmul reassoc nnan nsz arcp contract float %179, 5.100000e+02, !spirv.Decorations !631
  %181 = fsub reassoc nnan nsz arcp contract float %178, %180, !spirv.Decorations !631		; visa id: 235
  %182 = fmul reassoc nsz arcp contract float %177, %181, !spirv.Decorations !629		; visa id: 237
  %183 = ptrtoint ptr addrspace(1) %2 to i64		; visa id: 238
  %184 = zext nneg i32 %12 to i64		; visa id: 238
  %185 = shl nuw nsw i64 %184, 2		; visa id: 239
  %186 = add i64 %185, %183		; visa id: 240
  %187 = inttoptr i64 %186 to ptr addrspace(1)		; visa id: 241
  store float %182, ptr addrspace(1) %187, align 4		; visa id: 241
  ret void, !stats.blockFrequency.digits !615, !stats.blockFrequency.scale !616		; visa id: 242
}

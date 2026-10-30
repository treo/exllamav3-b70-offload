//.kernel _ZTSZL7combineRN4sycl3_V15queueEPKiPKfS4_PfRK4MetaiiEUlNS0_2idILi1EEEE_
//.platform XE2
//.thread_config numGRF=128, numAcc=4, numSWSB=16
//.options_string "-emitCrossThreadOffR0Reloc -hashmovs 283920640 979651008 -hashmovs1 0 1 "
//.full_options "-emitLocation -wideMulMadOpsEn -enableCoalesceScalarMoves -supportLSCImmScale 0 -samplerHeaderWA -enablePreemptionR0Only -hasRNEandDenorm -noStitchExternFunc -useInlineData -emitCrossThreadOffR0Reloc -abortonspill -abortOnSpill 4 -enableBCR -enableBundleCR 3 -freqBasedSpillCost 8 -freqBasedSpillCostFunc 1 -boundsChecking -presched-ctrl 6 -presched-rp 100 -nodpsendreorder -SBIDDepLoc -PVCSendWARWA -output -binary -dumpcommonisa -dumpcombinedcisa -dumpvisa -printHexFloatInAsm -noverifyCISA -enableHalfLSC -partialInt64 -activeThreadsOnlyBarrier -hashmovs 283920640 979651008 -hashmovs1 0 1 -GRFBumpUpNumber 2 "
//.instCount 511
//.RA type	LOCAL_FIRST_FIT_BC_RA
//.git-hash f523d3ae2278a1765cdbdedb3770d11afa642fa5

//.declare BuiltInR0 (0)  rf=r size=64 type=ud align=32 words (r0.0) IsBuiltin
//.declare  (1)  rf=r size=64 type=ud align=32 words (r40.0) IsBuiltin
//.declare BuiltinA0 (2)  rf=a size=4 type=ud align=1 words (a0.0) IsBuiltin
//.declare BuiltinA0Dot2 (3)  rf=a size=4 type=ud align=1 words (a0.2) IsBuiltin
//.declare BuiltinSR0Dot1 (5)  rf=r size=4 type=ud align=2 words IsBuiltin
//.declare %null (10)  rf=r size=4 type=ud align=32 words
//.declare %local_id_x (13)  rf=r size=4 type=ud align=2 words (r0.9)
//.declare %local_id_y (14)  rf=r size=4 type=ud align=2 words (r0.10)
//.declare %local_size_x (15)  rf=r size=4 type=ud align=2 words (r0.5)
//.declare %local_size_y (16)  rf=r size=4 type=ud align=2 words (r0.6)
//.declare %group_id_x (17)  rf=r size=4 type=ud align=2 words (r0.1)
//.declare %group_id_y (18)  rf=r size=4 type=ud align=2 words (r0.6)
//.declare %group_id_z (19)  rf=r size=4 type=ud align=2 words (r0.7)
//.declare %group_count_x (20)  rf=r size=4 type=ud align=2 words (r0.7)
//.declare %group_count_y (21)  rf=r size=4 type=ud align=2 words (r0.8)
//.declare %tsc (22)  rf=r size=20 type=ud align=2 words
//.declare %arg (23)  rf=r size=0 type=ud align=32 words (r26.0)
//.declare %retval (24)  rf=r size=0 type=ud align=32 words (r26.0) Output
//.declare %sp (25)  rf=r size=8 type=uq align=32 words (r127.3)
//.declare %fp (26)  rf=r size=8 type=uq align=32 words (r127.2)
//.declare %sr0 (27)  rf=r size=16 type=ud align=2 words
//.declare %cr0 (28)  rf=r size=12 type=ud align=2 words
//.declare %ce0 (29)  rf=r size=4 type=ud align=2 words
//.declare %dbg0 (30)  rf=r size=8 type=ud align=2 words
//.declare implBufPtr (32)  rf=r size=8 type=uq align=32 words (r126.0)
//.declare localIdBufPtr (33)  rf=r size=8 type=uq align=32 words (r126.3)
//.declare %msg0 (34)  rf=r size=12 type=ud align=2 words
//.declare %scratchloc (35)  rf=r size=8 type=uq align=4 words (s0.7)
//.declare V0033 (43)  rf=r size=64 type=d alias=+0 align=32 words (r40.0)
//.declare V0034 (44)  rf=r size=4 type=d align=2 words (r3.6)
//.declare V0035 (45)  rf=r size=8 type=uq align=4 words (r2.3)
//.declare V0036 (46)  rf=r size=4 type=d align=2 words (r3.7)
//.declare V0037 (47)  rf=r size=8 type=uq align=4 words (r3.0)
//.declare V0038 (48)  rf=r size=8 type=uq align=4 words (r3.1)
//.declare V0039 (49)  rf=r size=8 type=uq align=4 words (r3.2)
//.declare V0041 (51)  rf=r size=32 type=d alias=+0 align=32 words (r40.0)
//.declare V0042 (52)  rf=r size=12 type=d align=2 words (r2.0)
//.declare V0043 (53)  rf=r size=12 type=d align=2 words (r2.3)
//.declare V0044 (54)  rf=r size=64 type=w align=32 words (r1.0)
//.declare V0048 (58)  rf=r size=4 type=d align=2 words (r3.8)
//.declare V0049 (59)  rf=r size=4 type=d align=2 words (r3.9)
//.declare V0050 (60)  rf=r size=4 type=d align=2 words (r3.10)
//.declare V0051 (61)  rf=r size=4 type=d align=2 words (r3.11)
//.declare V0052 (62)  rf=r size=4 type=d align=2 words (r3.12)
//.declare V0053 (63)  rf=r size=4 type=d align=2 words (r3.13)
//.declare V0054 (64)  rf=r size=8 type=q align=4 words (r3.7)
//.declare V0055 (65)  rf=r size=4 type=f align=2 words (r4.0)
//.declare V0056 (66)  rf=r size=1 type=b align=2 words (r4.4)
//.declare V0057 (67)  rf=r size=1 type=b align=2 words (r4.8)
//.declare V0058 (68)  rf=r size=1 type=b align=2 words (r4.12)
//.declare V0059 (69)  rf=r size=1 type=b align=2 words (r4.16)
//.declare V0068 (78)  rf=r size=4 type=d align=32 words (r5.0)
//.declare V0070 (80)  rf=r size=64 type=uw alias=V0044+0 align=32 words (r1.0)
//.declare V0071 (81)  rf=r size=128 type=d align=32 words (r42.0)
//.declare V0072 (82)  rf=r size=4 type=d align=2 words (r41.0)
//.declare V0073 (83)  rf=r size=4 type=d align=2 words (r41.1)
//.declare V0074 (84)  rf=r size=4 type=d align=32 words (r44.0)
//.declare V0075 (85)  rf=r size=4 type=d align=2 words (r41.2)
//.declare V0076 (86)  rf=r size=4 type=ud alias=V0074+0 align=2 words (r44.0)
//.declare V0077 (87)  rf=r size=4 type=ud alias=V0049+0 align=32 words (r3.9)
//.declare V0078 (88)  rf=r size=4 type=ud alias=V0053+0 align=32 words (r3.13)
//.declare V0079 (89)  rf=r size=4 type=d align=32 words (r6.0)
//.declare V0081 (91)  rf=r size=4 type=d align=32 words (r7.0)
//.declare V0083 (93)  rf=r size=8 type=q align=4 words (r41.2)
//.declare V0084 (94)  rf=r size=8 type=d alias=V0083+0 align=4 words (r41.4)
//.declare P01 (95)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0085 (96)  rf=r size=4 type=ud alias=V0075+0 align=2 words (r41.2)
//.declare V0086 (97)  rf=r size=8 type=df align=4 words (r41.3)
//.declare V0087 (98)  rf=r size=8 type=df align=4 words (r41.4)
//.declare V0089 (100)  rf=r size=8 type=df align=4 words (r3.5)
//.declare V0090 (101)  rf=r size=8 type=uq alias=V0083+0 align=4 words (r41.2)
//.declare V0091 (102)  rf=r size=4 type=f align=4 words (r2.8)
//.declare V0092 (103)  rf=r size=4 type=f align=2 words (r3.12)
//.declare V0093 (104)  rf=r size=8 type=df align=4 words (r4.1)
//.declare V0094 (105)  rf=r size=8 type=df align=4 words (r4.2)
//.declare V0095 (106)  rf=r size=8 type=df align=4 words (r5.0)
//.declare V0096 (107)  rf=r size=8 type=df align=4 words (r6.0)
//.declare V0098 (109)  rf=r size=128 type=ud alias=V0071+0 align=32 words (r42.0)
//.declare V0104 (115)  rf=r size=128 type=d align=32 words (r24.0)
//.declare V0105 (116)  rf=r size=128 type=d align=32 words (r26.0)
//.declare V0106 (117)  rf=r size=128 type=d align=32 words (r28.0)
//.declare V0107 (118)  rf=r size=128 type=d align=32 words (r8.0)
//.declare P02 (119)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0108 (120)  rf=r size=128 type=ud alias=V0105+0 align=32 words (r26.0)
//.declare V0109 (121)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0115 (127)  rf=r size=128 type=ud alias=V0104+0 align=32 words (r24.0)
//.declare V0118 (130)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0119 (131)  rf=r size=128 type=d align=32 words (r8.0)
//.declare V0123 (135)  rf=r size=128 type=d align=32 words (r18.0)
//.declare V0124 (136)  rf=r size=128 type=d align=32 words (r32.0)
//.declare P03 (137)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0125 (138)  rf=r size=128 type=ud alias=V0123+0 align=32 words (r18.0)
//.declare P04 (139)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare P05 (140)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0126 (141)  rf=r size=128 type=ud alias=V0124+0 align=32 words (r32.0)
//.declare P06 (146)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0131 (147)  rf=r size=128 type=d align=32 words (r46.0)
//.declare V0132 (148)  rf=r size=4 type=d align=4 words (r2.8)
//.declare V0133 (149)  rf=r size=4 type=f align=2 words (r2.9)
//.declare V0134 (150)  rf=r size=4 type=ud alias=V0132+0 align=2 words (r2.8)
//.declare V0135 (151)  rf=r size=4 type=d align=2 words (r2.10)
//.declare V0136 (152)  rf=r size=4 type=ud alias=V0135+0 align=2 words (r2.10)
//.declare V0137 (153)  rf=r size=4 type=d align=2 words (r3.10)
//.declare V0138 (154)  rf=r size=128 type=f align=32 words (r6.0)
//.declare V0139 (155)  rf=r size=4 type=f align=2 words (r4.1)
//.declare V0140 (156)  rf=r size=4 type=f align=2 words (r5.0)
//.declare V0141 (157)  rf=r size=128 type=f align=32 words (r8.0)
//.declare V0142 (158)  rf=r size=128 type=d align=32 words (r10.0)
//.declare V0143 (159)  rf=r size=128 type=ud alias=V0142+0 align=32 words (r10.0)
//.declare V0144 (160)  rf=r size=128 type=d align=32 words (r12.0)
//.declare V0145 (161)  rf=r size=128 type=d align=32 words (r14.0)
//.declare V0146 (162)  rf=r size=128 type=ud alias=V0145+0 align=32 words (r14.0)
//.declare V0147 (163)  rf=r size=4 type=f align=2 words (r16.0)
//.declare V0148 (164)  rf=r size=4 type=ud alias=V0137+0 align=2 words (r3.10)
//.declare V0149 (165)  rf=r size=128 type=f align=32 words (r18.0)
//.declare V0150 (166)  rf=r size=128 type=ud alias=V0144+0 align=32 words (r12.0)
//.declare V0151 (167)  rf=r size=128 type=f align=32 words (r20.0)
//.declare V0157 (173)  rf=r size=128 type=f align=32 words (r22.0)
//.declare V0158 (174)  rf=r size=128 type=d align=32 words (r24.0)
//.declare V0159 (175)  rf=r size=128 type=ud alias=V0158+0 align=32 words (r24.0)
//.declare V0160 (176)  rf=r size=128 type=d align=32 words (r26.0)
//.declare V0161 (177)  rf=r size=128 type=d align=32 words (r8.0)
//.declare V0162 (178)  rf=r size=128 type=d align=32 words (r10.0)
//.declare V0163 (179)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0164 (180)  rf=r size=128 type=ud alias=V0162+0 align=32 words (r10.0)
//.declare V0165 (181)  rf=r size=128 type=ud alias=V0163+0 align=32 words (r6.0)
//.declare  (182)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0166 (183)  rf=r size=128 type=ud alias=V0131+0 align=32 words (r46.0)
//.declare P07 (184)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0167 (185)  rf=r size=8 type=q align=4 words (r2.4)
//.declare V0168 (186)  rf=r size=8 type=df align=4 words (r3.5)
//.declare V0169 (187)  rf=r size=8 type=uq alias=V0167+0 align=4 words (r2.4)
//.declare V0170 (188)  rf=r size=4 type=f align=4 words (r3.12)
//.declare V0171 (189)  rf=r size=4 type=f align=2 words (r4.1)
//.declare V0172 (190)  rf=r size=8 type=df align=4 words (r6.0)
//.declare V0173 (191)  rf=r size=8 type=df align=4 words (r5.0)
//.declare V0174 (192)  rf=r size=8 type=df align=4 words (r7.0)
//.declare V0175 (193)  rf=r size=8 type=df align=4 words (r8.0)
//.declare V0182 (200)  rf=r size=128 type=d align=32 words (r26.0)
//.declare V0183 (201)  rf=r size=128 type=d align=32 words (r28.0)
//.declare V0184 (202)  rf=r size=128 type=d align=32 words (r6.0)
//.declare P08 (203)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0185 (204)  rf=r size=128 type=ud alias=V0183+0 align=32 words (r28.0)
//.declare V0186 (205)  rf=r size=128 type=d align=32 words (r10.0)
//.declare V0192 (211)  rf=r size=128 type=ud alias=V0182+0 align=32 words (r26.0)
//.declare V0195 (214)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0196 (215)  rf=r size=128 type=d align=32 words (r10.0)
//.declare V0200 (219)  rf=r size=128 type=d align=32 words (r32.0)
//.declare V0201 (220)  rf=r size=128 type=d align=32 words (r34.0)
//.declare P09 (221)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0202 (222)  rf=r size=128 type=ud alias=V0200+0 align=32 words (r32.0)
//.declare P10 (223)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare P11 (224)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0203 (225)  rf=r size=128 type=ud alias=V0201+0 align=32 words (r34.0)
//.declare V0204 (226)  rf=r size=4 type=ud alias=V0073+0 align=2 words (r41.1)
//.declare P12 (231)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0209 (232)  rf=r size=128 type=d align=32 words (r48.0)
//.declare V0210 (233)  rf=r size=4 type=f align=2 words (r2.8)
//.declare V0211 (234)  rf=r size=4 type=d align=2 words (r2.9)
//.declare V0212 (235)  rf=r size=4 type=ud alias=V0211+0 align=2 words (r2.9)
//.declare V0213 (236)  rf=r size=4 type=d align=2 words (r3.10)
//.declare V0214 (237)  rf=r size=128 type=f align=32 words (r6.0)
//.declare V0215 (238)  rf=r size=4 type=f align=2 words (r4.1)
//.declare V0216 (239)  rf=r size=4 type=f align=2 words (r5.0)
//.declare V0217 (240)  rf=r size=128 type=f align=32 words (r8.0)
//.declare V0218 (241)  rf=r size=128 type=d align=32 words (r10.0)
//.declare V0219 (242)  rf=r size=128 type=ud alias=V0218+0 align=32 words (r10.0)
//.declare V0220 (243)  rf=r size=128 type=d align=32 words (r12.0)
//.declare V0221 (244)  rf=r size=128 type=d align=32 words (r14.0)
//.declare V0222 (245)  rf=r size=128 type=ud alias=V0221+0 align=32 words (r14.0)
//.declare V0223 (246)  rf=r size=4 type=f align=2 words (r16.0)
//.declare V0224 (247)  rf=r size=4 type=ud alias=V0213+0 align=2 words (r3.10)
//.declare V0225 (248)  rf=r size=128 type=f align=32 words (r18.0)
//.declare V0226 (249)  rf=r size=128 type=ud alias=V0220+0 align=32 words (r12.0)
//.declare V0227 (250)  rf=r size=128 type=f align=32 words (r20.0)
//.declare V0233 (256)  rf=r size=128 type=f align=32 words (r22.0)
//.declare V0234 (257)  rf=r size=128 type=d align=32 words (r24.0)
//.declare V0235 (258)  rf=r size=128 type=ud alias=V0234+0 align=32 words (r24.0)
//.declare V0236 (259)  rf=r size=128 type=d align=32 words (r26.0)
//.declare V0237 (260)  rf=r size=128 type=d align=32 words (r8.0)
//.declare V0238 (261)  rf=r size=128 type=d align=32 words (r10.0)
//.declare V0239 (262)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0240 (263)  rf=r size=128 type=ud alias=V0238+0 align=32 words (r10.0)
//.declare V0241 (264)  rf=r size=128 type=ud alias=V0239+0 align=32 words (r6.0)
//.declare  (265)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0242 (266)  rf=r size=128 type=ud alias=V0209+0 align=32 words (r48.0)
//.declare V0245 (269)  rf=r size=128 type=d align=32 words (r50.0)
//.declare V0246 (270)  rf=r size=128 type=d align=32 words (r52.0)
//.declare V0247 (271)  rf=r size=128 type=d align=32 words (r6.0)
//.declare P13 (272)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0248 (273)  rf=r size=128 type=ud alias=V0247+0 align=32 words (r6.0)
//.declare V0249 (274)  rf=r size=8 type=q align=4 words (r2.4)
//.declare V0250 (275)  rf=r size=8 type=df align=4 words (r3.5)
//.declare V0251 (276)  rf=r size=8 type=uq alias=V0249+0 align=4 words (r2.4)
//.declare V0252 (277)  rf=r size=4 type=f align=4 words (r3.12)
//.declare V0253 (278)  rf=r size=4 type=f align=2 words (r4.1)
//.declare V0254 (279)  rf=r size=8 type=df align=4 words (r6.0)
//.declare V0255 (280)  rf=r size=8 type=df align=4 words (r5.0)
//.declare V0256 (281)  rf=r size=8 type=df align=4 words (r7.0)
//.declare V0257 (282)  rf=r size=8 type=df align=4 words (r8.0)
//.declare V0259 (284)  rf=r size=128 type=d align=32 words (r10.0)
//.declare V0261 (286)  rf=r size=128 type=ud alias=V0259+0 align=32 words (r10.0)
//.declare V0263 (288)  rf=r size=128 type=d align=32 words (r26.0)
//.declare V0264 (289)  rf=r size=128 type=ud alias=V0263+0 align=32 words (r26.0)
//.declare V0265 (290)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0266 (291)  rf=r size=128 type=d align=32 words (r12.0)
//.declare V0269 (294)  rf=r size=128 type=ud alias=V0266+0 align=32 words (r12.0)
//.declare V0273 (298)  rf=r size=8 type=df align=4 words (r2.4)
//.declare V0279 (304)  rf=r size=128 type=d align=32 words (r38.0)
//.declare V0280 (305)  rf=r size=128 type=d align=32 words (r30.0)
//.declare V0281 (306)  rf=r size=128 type=d align=32 words (r14.0)
//.declare P14 (307)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0282 (308)  rf=r size=128 type=d align=32 words (r20.0)
//.declare P15 (309)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0283 (310)  rf=r size=128 type=ud alias=V0280+0 align=32 words (r30.0)
//.declare V0284 (311)  rf=r size=128 type=d align=32 words (r16.0)
//.declare V0290 (317)  rf=r size=128 type=ud alias=V0279+0 align=32 words (r38.0)
//.declare V0293 (320)  rf=r size=128 type=d align=32 words (r12.0)
//.declare V0294 (321)  rf=r size=128 type=d align=32 words (r16.0)
//.declare V0298 (325)  rf=r size=128 type=d align=32 words (r20.0)
//.declare V0299 (326)  rf=r size=128 type=d align=32 words (r14.0)
//.declare P16 (327)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0300 (328)  rf=r size=128 type=ud alias=V0298+0 align=32 words (r20.0)
//.declare P17 (329)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare P18 (330)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0301 (331)  rf=r size=128 type=ud alias=V0299+0 align=32 words (r14.0)
//.declare V0302 (332)  rf=r size=4 type=ud alias=V0072+0 align=2 words (r41.0)
//.declare P19 (339)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0309 (340)  rf=r size=128 type=d align=32 words (r54.0)
//.declare V0310 (341)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0311 (342)  rf=r size=4 type=f align=2 words (r2.8)
//.declare V0312 (343)  rf=r size=4 type=d align=2 words (r2.9)
//.declare V0313 (344)  rf=r size=4 type=ud alias=V0312+0 align=2 words (r2.9)
//.declare V0314 (345)  rf=r size=4 type=d align=2 words (r3.10)
//.declare V0315 (346)  rf=r size=128 type=f align=32 words (r8.0)
//.declare V0316 (347)  rf=r size=128 type=ud alias=V0310+0 align=32 words (r6.0)
//.declare V0317 (348)  rf=r size=4 type=f align=2 words (r4.1)
//.declare V0318 (349)  rf=r size=4 type=f align=2 words (r5.0)
//.declare V0319 (350)  rf=r size=128 type=f align=32 words (r10.0)
//.declare V0320 (351)  rf=r size=128 type=d align=32 words (r12.0)
//.declare V0321 (352)  rf=r size=128 type=ud alias=V0320+0 align=32 words (r12.0)
//.declare V0322 (353)  rf=r size=128 type=d align=32 words (r14.0)
//.declare V0323 (354)  rf=r size=128 type=d align=32 words (r16.0)
//.declare V0324 (355)  rf=r size=128 type=ud alias=V0323+0 align=32 words (r16.0)
//.declare V0325 (356)  rf=r size=4 type=f align=2 words (r18.0)
//.declare V0326 (357)  rf=r size=4 type=ud alias=V0314+0 align=2 words (r3.10)
//.declare V0327 (358)  rf=r size=128 type=f align=32 words (r20.0)
//.declare V0328 (359)  rf=r size=128 type=ud alias=V0322+0 align=32 words (r14.0)
//.declare V0329 (360)  rf=r size=128 type=f align=32 words (r22.0)
//.declare V0335 (366)  rf=r size=128 type=f align=32 words (r24.0)
//.declare V0336 (367)  rf=r size=128 type=d align=32 words (r26.0)
//.declare V0337 (368)  rf=r size=128 type=ud alias=V0336+0 align=32 words (r26.0)
//.declare V0338 (369)  rf=r size=128 type=d align=32 words (r28.0)
//.declare V0339 (370)  rf=r size=128 type=d align=32 words (r10.0)
//.declare V0340 (371)  rf=r size=128 type=d align=32 words (r12.0)
//.declare P20 (372)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0341 (373)  rf=r size=128 type=ud alias=V0340+0 align=32 words (r12.0)
//.declare V0342 (374)  rf=r size=128 type=d align=32 words (r8.0)
//.declare V0343 (375)  rf=r size=128 type=ud alias=V0309+0 align=32 words (r54.0)
//.declare V0344 (376)  rf=r size=128 type=d align=32 words (r56.0)
//.declare V0345 (377)  rf=r size=128 type=d align=32 words (r58.0)
//.declare V0346 (378)  rf=r size=128 type=ud alias=V0344+0 align=32 words (r56.0)
//.declare V0347 (379)  rf=r size=128 type=ud alias=V0245+0 align=32 words (r50.0)
//.declare V0348 (380)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0350 (382)  rf=r size=128 type=d align=32 words (r8.0)
//.declare P21 (384)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0352 (385)  rf=r size=128 type=f align=32 words (r60.0)
//.declare V0357 (390)  rf=r size=4 type=d align=2 words (r41.3)
//.declare V0358 (391)  rf=r size=4 type=d align=2 words (r41.10)
//.declare V0359 (392)  rf=r size=4 type=d align=2 words (r41.11)
//.declare V0360 (393)  rf=r size=8 type=q alias=V0035+0 align=32 words (r2.3)
//.declare V0361 (394)  rf=r size=4 type=d align=2 words (r41.12)
//.declare V0362 (395)  rf=r size=128 type=d align=32 words (r62.0)
//.declare V0366 (399)  rf=r size=4 type=ud alias=V0361+0 align=2 words (r41.12)
//.declare V0367 (400)  rf=r size=4 type=ud alias=V0048+0 align=32 words (r3.8)
//.declare V0368 (401)  rf=r size=4 type=d align=32 words (r6.0)
//.declare V0370 (403)  rf=r size=4 type=d align=32 words (r7.0)
//.declare V0372 (405)  rf=r size=8 type=q align=32 words (r5.0)
//.declare V0373 (406)  rf=r size=8 type=d alias=V0372+0 align=4 words (r5.0)
//.declare V0377 (410)  rf=r size=128 type=d align=32 words (r12.0)
//.declare V0378 (411)  rf=r size=128 type=d align=32 words (r14.0)
//.declare V0380 (413)  rf=r size=128 type=ud alias=V0377+0 align=32 words (r12.0)
//.declare V0381 (414)  rf=r size=4 type=ud alias=V0036+0 align=32 words (r3.7)
//.declare V0384 (417)  rf=r size=128 type=d align=32 words (r22.0)
//.declare V0385 (418)  rf=r size=128 type=d align=32 words (r8.0)
//.declare V0389 (422)  rf=r size=128 type=d align=32 words (r24.0)
//.declare V0390 (423)  rf=r size=128 type=d align=32 words (r12.0)
//.declare V0392 (425)  rf=r size=128 type=ud alias=V0389+0 align=32 words (r24.0)
//.declare V0395 (428)  rf=r size=128 type=d align=32 words (r8.0)
//.declare V0396 (429)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0399 (432)  rf=r size=256 type=q align=32 words (r20.0)
//.declare V0400 (433)  rf=r size=256 type=uq alias=V0399+0 align=32 words (r20.0)
//.declare V0401 (434)  rf=r size=128 type=d align=32 words (r24.0)
//.declare P22 (435)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0402 (436)  rf=r size=8 type=q alias=V0038+0 align=32 words (r3.1)
//.declare V0404 (438)  rf=r size=256 type=q align=32 words (r17.0)
//.declare V0405 (439)  rf=r size=256 type=uq alias=V0404+0 align=32 words (r17.0)
//.declare V0406 (440)  rf=r size=128 type=f align=32 words (r28.0)
//.declare V0407 (441)  rf=r size=8 type=q alias=V0039+0 align=32 words (r3.2)
//.declare V0408 (442)  rf=r size=256 type=q align=32 words (r13.0)
//.declare V0409 (443)  rf=r size=256 type=uq alias=V0408+0 align=32 words (r13.0)
//.declare V0410 (444)  rf=r size=128 type=d align=32 words (r26.0)
//.declare V0412 (446)  rf=r size=128 type=f align=32 words (r30.0)
//.declare V0413 (447)  rf=r size=128 type=f align=32 words (r32.0)
//.declare V0414 (448)  rf=r size=4 type=f align=2 words (r2.8)
//.declare V0415 (449)  rf=r size=128 type=f align=32 words (r34.0)
//.declare V0416 (450)  rf=r size=8 type=q alias=V0037+0 align=32 words (r3.0)
//.declare V0418 (452)  rf=r size=256 type=q align=32 words (r21.0)
//.declare V0419 (453)  rf=r size=256 type=uq alias=V0418+0 align=32 words (r21.0)
//.declare  (454)  rf=r size=64 type=ud align=32 words (r127.0)
//.declare  (455)  rf=r size=4 type=d alias=V0083+0 align=2 words (r41.4)
//.declare  (460)  rf=r size=2 type=w align=1 words (r2.16)
//.declare  (461)  rf=r size=64 type=ud align=32 words (r18.0)
//.declare  (462)  rf=r size=64 type=ud align=32 words (r26.0)
//.declare  (463)  rf=r size=128 type=ud align=32 words (r8.0)
//.declare  (464)  rf=r size=128 type=ud align=32 words (r12.0)
//.declare  (465)  rf=r size=128 type=ud align=32 words (r34.0)
//.declare  (466)  rf=r size=128 type=ud align=32 words (r8.0)
//.declare  (467)  rf=r size=4 type=f align=2 words (r3.11)
//.declare  (468)  rf=r size=128 type=ud align=32 words (r6.0)
//.declare  (469)  rf=r size=128 type=ud align=32 words (r8.0)
//.declare  (472)  rf=r size=2 type=w align=1 words (r2.16)
//.declare  (473)  rf=r size=64 type=ud align=32 words (r18.0)
//.declare  (474)  rf=r size=64 type=ud align=32 words (r28.0)
//.declare  (475)  rf=r size=128 type=ud align=32 words (r10.0)
//.declare  (476)  rf=r size=128 type=ud align=32 words (r14.0)
//.declare  (477)  rf=r size=128 type=ud align=32 words (r36.0)
//.declare  (478)  rf=r size=128 type=ud align=32 words (r8.0)
//.declare  (479)  rf=r size=4 type=f align=2 words (r3.11)
//.declare  (480)  rf=r size=128 type=ud align=32 words (r6.0)
//.declare  (481)  rf=r size=128 type=ud align=32 words (r8.0)
//.declare  (482)  rf=r size=128 type=ud align=32 words (r24.0)
//.declare  (483)  rf=r size=128 type=ud align=32 words (r28.0)
//.declare  (486)  rf=r size=64 type=ud align=32 words (r6.0)
//.declare  (487)  rf=r size=64 type=ud align=32 words (r14.0)
//.declare  (488)  rf=r size=128 type=ud align=32 words (r12.0)
//.declare  (489)  rf=r size=128 type=ud align=32 words (r16.0)
//.declare  (490)  rf=r size=128 type=ud align=32 words (r30.0)
//.declare  (491)  rf=r size=128 type=ud align=32 words (r14.0)
//.declare  (492)  rf=r size=4 type=f align=2 words (r3.11)
//.declare  (495)  rf=r size=128 type=ud align=32 words (r6.0)
//.declare  (496)  rf=r size=128 type=ud align=32 words (r8.0)
//.declare  (497)  rf=r size=128 type=ud align=32 words (r10.0)
//.declare  (498)  rf=r size=128 type=ud align=32 words (r12.0)
//.declare  (499)  rf=r size=64 type=ud align=32 words (r16.0)
//.declare  (500)  rf=r size=64 type=ud align=32 words (r20.0)
//.declare  (501)  rf=r size=64 type=ud align=32 words (r16.0)
//.declare  (502)  rf=r size=64 type=ud align=32 words (r14.0)
//.declare  (503)  rf=r size=128 type=df align=32 words (r10.0)
//.declare  (504)  rf=r size=128 type=df align=32 words (r14.0)
//.declare  (505)  rf=r size=128 type=df align=32 words (r16.0)
//.declare  (506)  rf=r size=128 type=df align=32 words (r18.0)
//.declare  (507)  rf=r size=128 type=q align=32 words (r20.0)
//.declare  (508)  rf=r size=128 type=q align=32 words (r22.0)
//.declare  (511)  rf=r size=128 type=d align=32 words (r12.0)
//.declare  (512)  rf=r size=128 type=d align=32 words (r10.0)
//.declare  (513)  rf=r size=128 type=q align=32 words (r14.0)
//.declare  (514)  rf=r size=128 type=q align=32 words (r16.0)
//.declare  (515)  rf=r size=128 type=q align=32 words (r30.0)
//.declare  (516)  rf=r size=128 type=q align=32 words (r27.0)
//.declare  (517)  rf=r size=128 type=q align=32 words (r10.0)
//.declare  (518)  rf=r size=128 type=q align=32 words (r12.0)
//.declare  (521)  rf=r size=128 type=q align=32 words (r5.0)
//.declare  (522)  rf=r size=128 type=q align=32 words (r14.0)
//.declare  (523)  rf=r size=128 type=q align=32 words (r24.0)
//.declare  (525)  rf=r size=128 type=q align=32 words (r64.0)
//.declare  (526)  rf=r size=128 type=q align=32 words (r66.0)
//.declare  (527)  rf=r size=128 type=df align=32 words (r12.0)
//.declare  (528)  rf=r size=128 type=df align=32 words (r16.0)
//.declare  (529)  rf=r size=128 type=df align=32 words (r18.0)
//.declare  (530)  rf=r size=128 type=df align=32 words (r20.0)
//.declare  (531)  rf=r size=128 type=q align=32 words (r22.0)
//.declare  (532)  rf=r size=128 type=q align=32 words (r24.0)
//.declare  (535)  rf=r size=128 type=d align=32 words (r12.0)
//.declare  (536)  rf=r size=128 type=d align=32 words (r14.0)
//.declare  (537)  rf=r size=128 type=q align=32 words (r8.0)
//.declare  (538)  rf=r size=128 type=q align=32 words (r16.0)
//.declare  (539)  rf=r size=128 type=q align=32 words (r19.0)
//.declare  (540)  rf=r size=128 type=q align=32 words (r29.0)
//.declare  (541)  rf=r size=128 type=q align=32 words (r12.0)
//.declare  (542)  rf=r size=128 type=q align=32 words (r14.0)
//.declare  (545)  rf=r size=128 type=q align=32 words (r5.0)
//.declare  (546)  rf=r size=128 type=q align=32 words (r10.0)
//.declare  (547)  rf=r size=128 type=q align=32 words (r26.0)
//.declare  (549)  rf=r size=128 type=q align=32 words (r68.0)
//.declare  (550)  rf=r size=128 type=q align=32 words (r70.0)
//.declare  (553)  rf=r size=128 type=df align=32 words (r14.0)
//.declare  (554)  rf=r size=128 type=df align=32 words (r18.0)
//.declare  (555)  rf=r size=128 type=df align=32 words (r20.0)
//.declare  (556)  rf=r size=128 type=df align=32 words (r22.0)
//.declare  (557)  rf=r size=128 type=df align=32 words (r33.0)
//.declare  (558)  rf=r size=128 type=df align=32 words (r17.0)
//.declare  (559)  rf=r size=128 type=df align=32 words (r20.0)
//.declare  (560)  rf=r size=128 type=df align=32 words (r24.0)
//.declare  (561)  rf=r size=128 type=df align=32 words (r22.0)
//.declare  (562)  rf=r size=128 type=df align=32 words (r28.0)
//.declare  (563)  rf=r size=128 type=df align=32 words (r35.0)
//.declare  (564)  rf=r size=128 type=df align=32 words (r26.0)
//.declare  (565)  rf=r size=128 type=q align=32 words (r5.0)
//.declare  (566)  rf=r size=128 type=q align=32 words (r9.0)
//.declare  (569)  rf=r size=128 type=d align=32 words (r22.0)
//.declare  (570)  rf=r size=128 type=d align=32 words (r18.0)
//.declare  (571)  rf=r size=128 type=q align=32 words (r7.0)
//.declare  (572)  rf=r size=128 type=q align=32 words (r24.0)
//.declare  (573)  rf=r size=128 type=q align=32 words (r9.0)
//.declare  (574)  rf=r size=128 type=q align=32 words (r26.0)
//.declare  (575)  rf=r size=128 type=q align=32 words (r18.0)
//.declare  (576)  rf=r size=128 type=q align=32 words (r5.0)
//.declare  (579)  rf=r size=128 type=d align=32 words (r22.0)
//.declare  (580)  rf=r size=128 type=d align=32 words (r28.0)
//.declare  (581)  rf=r size=128 type=q align=32 words (r30.0)
//.declare  (582)  rf=r size=128 type=q align=32 words (r11.0)
//.declare  (583)  rf=r size=128 type=q align=32 words (r72.0)
//.declare  (584)  rf=r size=128 type=q align=32 words (r74.0)
//.declare  (585)  rf=r size=128 type=q align=32 words (r76.0)
//.declare  (586)  rf=r size=128 type=q align=32 words (r78.0)
//.declare  (587)  rf=r size=128 type=d align=32 words (r6.0)
//.declare  (588)  rf=r size=128 type=d align=32 words (r8.0)
//.declare  (589)  rf=r size=128 type=q align=32 words (r10.0)
//.declare  (590)  rf=r size=128 type=q align=32 words (r12.0)
//.declare  (591)  rf=r size=128 type=q align=32 words (r80.0)
//.declare  (592)  rf=r size=128 type=q align=32 words (r82.0)
//.declare  (593)  rf=r size=128 type=q align=32 words (r8.0)
//.declare  (594)  rf=r size=128 type=q align=32 words (r10.0)
//.declare  (597)  rf=r size=128 type=q align=32 words (r17.0)
//.declare  (598)  rf=r size=128 type=q align=32 words (r6.0)
//.declare  (599)  rf=r size=128 type=q align=32 words (r10.0)
//.declare  (600)  rf=r size=128 type=q align=32 words (r19.0)
//.declare  (603)  rf=r size=128 type=q align=32 words (r26.0)
//.declare  (604)  rf=r size=128 type=q align=32 words (r28.0)
//.declare  (605)  rf=r size=128 type=q align=32 words (r10.0)
//.declare  (606)  rf=r size=128 type=q align=32 words (r14.0)
//.declare  (607)  rf=r size=128 type=q align=32 words (r16.0)
//.declare  (608)  rf=r size=128 type=q align=32 words (r18.0)
//.declare  (609)  rf=r size=128 type=q align=32 words (r5.0)
//.declare  (610)  rf=r size=128 type=q align=32 words (r7.0)
//.declare  (611)  rf=r size=128 type=q align=32 words (r9.0)
//.declare  (612)  rf=r size=128 type=q align=32 words (r11.0)
//.declare  (613)  rf=r size=128 type=uq alias=+0 align=32 words (r20.0)
//.declare  (614)  rf=r size=128 type=uq alias=+0 align=32 words (r22.0)
//.declare  (615)  rf=r size=128 type=d alias=+0 align=32 words (r20.0)
//.declare  (616)  rf=r size=128 type=d alias=+0 align=32 words (r22.0)
//.declare  (617)  rf=r size=128 type=d alias=+0 align=32 words (r14.0)
//.declare  (618)  rf=r size=128 type=d alias=+0 align=32 words (r16.0)
//.declare  (619)  rf=r size=128 type=ud alias=+0 align=32 words (r30.0)
//.declare  (620)  rf=r size=128 type=ud alias=+0 align=32 words (r27.0)
//.declare  (621)  rf=r size=128 type=d alias=+0 align=32 words (r30.0)
//.declare  (622)  rf=r size=128 type=d alias=+0 align=32 words (r27.0)
//.declare  (623)  rf=r size=128 type=d alias=+0 align=32 words (r10.0)
//.declare  (624)  rf=r size=128 type=d alias=+0 align=32 words (r12.0)
//.declare  (625)  rf=r size=128 type=d alias=+0 align=32 words (r24.0)
//.declare  (626)  rf=r size=128 type=ud alias=+0 align=32 words (r24.0)
//.declare  (627)  rf=r size=128 type=uq alias=+0 align=32 words (r22.0)
//.declare  (628)  rf=r size=128 type=uq alias=+0 align=32 words (r24.0)
//.declare  (629)  rf=r size=128 type=d alias=+0 align=32 words (r22.0)
//.declare  (630)  rf=r size=128 type=d alias=+0 align=32 words (r24.0)
//.declare  (631)  rf=r size=128 type=d alias=+0 align=32 words (r8.0)
//.declare  (632)  rf=r size=128 type=d alias=+0 align=32 words (r16.0)
//.declare  (633)  rf=r size=128 type=ud alias=+0 align=32 words (r19.0)
//.declare  (634)  rf=r size=128 type=ud alias=+0 align=32 words (r29.0)
//.declare  (635)  rf=r size=128 type=d alias=+0 align=32 words (r19.0)
//.declare  (636)  rf=r size=128 type=d alias=+0 align=32 words (r29.0)
//.declare  (637)  rf=r size=128 type=d alias=+0 align=32 words (r12.0)
//.declare  (638)  rf=r size=128 type=d alias=+0 align=32 words (r14.0)
//.declare  (639)  rf=r size=128 type=d alias=+0 align=32 words (r26.0)
//.declare  (640)  rf=r size=128 type=ud alias=+0 align=32 words (r26.0)
//.declare  (641)  rf=r size=128 type=d alias=+0 align=32 words (r68.0)
//.declare  (642)  rf=r size=128 type=d alias=+0 align=32 words (r70.0)
//.declare  (643)  rf=r size=128 type=ud alias=+0 align=32 words (r68.0)
//.declare  (644)  rf=r size=128 type=ud alias=+0 align=32 words (r70.0)
//.declare  (645)  rf=r size=128 type=uq alias=+0 align=32 words (r5.0)
//.declare  (646)  rf=r size=128 type=uq alias=+0 align=32 words (r9.0)
//.declare  (647)  rf=r size=128 type=d alias=+0 align=32 words (r5.0)
//.declare  (648)  rf=r size=128 type=d alias=+0 align=32 words (r9.0)
//.declare  (649)  rf=r size=128 type=d alias=+0 align=32 words (r7.0)
//.declare  (650)  rf=r size=128 type=d alias=+0 align=32 words (r24.0)
//.declare  (651)  rf=r size=128 type=ud alias=+0 align=32 words (r9.0)
//.declare  (652)  rf=r size=128 type=ud alias=+0 align=32 words (r26.0)
//.declare  (653)  rf=r size=128 type=d alias=+0 align=32 words (r9.0)
//.declare  (654)  rf=r size=128 type=d alias=+0 align=32 words (r26.0)
//.declare  (655)  rf=r size=128 type=d alias=+0 align=32 words (r18.0)
//.declare  (656)  rf=r size=128 type=d alias=+0 align=32 words (r5.0)
//.declare  (657)  rf=r size=128 type=d alias=+0 align=32 words (r30.0)
//.declare  (658)  rf=r size=128 type=d alias=+0 align=32 words (r11.0)
//.declare  (659)  rf=r size=128 type=d alias=+0 align=32 words (r10.0)
//.declare  (660)  rf=r size=128 type=d alias=+0 align=32 words (r12.0)
//.declare  (661)  rf=r size=128 type=d alias=+0 align=32 words (r8.0)
//.declare  (662)  rf=r size=128 type=d alias=+0 align=32 words (r10.0)
//.declare  (663)  rf=r size=128 type=ud alias=+0 align=32 words (r17.0)
//.declare  (664)  rf=r size=128 type=ud alias=+0 align=32 words (r6.0)
//.declare  (665)  rf=r size=128 type=d alias=+0 align=32 words (r17.0)
//.declare  (666)  rf=r size=128 type=d alias=+0 align=32 words (r6.0)
//.declare  (667)  rf=r size=128 type=d alias=+0 align=32 words (r10.0)
//.declare  (668)  rf=r size=128 type=d alias=+0 align=32 words (r19.0)
//.declare  (669)  rf=r size=128 type=ud alias=+0 align=32 words (r26.0)
//.declare  (670)  rf=r size=128 type=ud alias=+0 align=32 words (r28.0)
//.declare  (671)  rf=r size=128 type=d alias=+0 align=32 words (r26.0)
//.declare  (672)  rf=r size=128 type=d alias=+0 align=32 words (r28.0)
//.declare r0 (673)  rf=r size=64 type=ud align=32 words (r0.0)
//.declare rtmp (674)  rf=r size=64 type=ud align=32 words (r127.0)
//.declare inlineRegFromTDL (675)  rf=r size=32 type=ud align=2 words (r1.0)
//.declare inlineRegExpectedLocation (676)  rf=r size=32 type=ud align=2 words (r2.0)
//.declare  (677)  rf=r size=64 type=ud align=32 words (r1.0)
//.declare  (678)  rf=r size=64 type=ud align=32 words (r3.0)
//.declare  (679)  rf=r size=32 type=ud align=2 words (r4.0)

// .inputs
// +----------+----------+--------+----------+------------------+
// | id       | type     |  bytes | at       | from             |
// +----------+----------+--------+----------+------------------+
// | V0044    | :w x 32  |   0x40 | r1       | pti[tid]+0x0     |
// | V0042    | :d x 3   |    0xC | r2       | inline+0x0       |
// | V0043    | :d x 3   |    0xC | r2+0xC   | inline+0xC       |
// | V0035    | :uq      |    0x8 | r2+0x18  | inline+0x18      |
// | V0037    | :uq      |    0x8 | r3       | cti+0x20         |
// | V0038    | :uq      |    0x8 | r3+0x8   | cti+0x28         |
// | V0039    | :uq      |    0x8 | r3+0x10  | cti+0x30         |
// | V0034    | :d       |    0x4 | r3+0x18  | cti+0x38         |
// | V0036    | :d       |    0x4 | r3+0x1C  | cti+0x3C         |
// | V0048    | :d       |    0x4 | r3+0x20  | cti+0x40         |
// | V0049    | :d       |    0x4 | r3+0x24  | cti+0x44         |
// | V0050    | :d       |    0x4 | r3+0x28  | cti+0x48         |
// | V0051    | :d       |    0x4 | r3+0x2C  | cti+0x4C         |
// | V0052    | :d       |    0x4 | r3+0x30  | cti+0x50         |
// | V0053    | :d       |    0x4 | r3+0x34  | cti+0x54         |
// | V0054    | :q       |    0x8 | r3+0x38  | cti+0x58         |
// | V0055    | :f       |    0x4 | r4       | cti+0x60         |
// | V0056    | :b       |    0x1 | r4+0x4   | cti+0x64         |
// | V0057    | :b       |    0x1 | r4+0x8   | cti+0x68         |
// | V0058    | :b       |    0x1 | r4+0xC   | cti+0x6C         |
// | V0059    | :b       |    0x1 | r4+0x10  | cti+0x70         |
// +----------+----------+--------+----------+------------------+


// B000: Preds:{},  Succs:{B001}
per_thread_prolog:
(W)     mov (16|M0)              r127.0<1>:ud  0x0:ud                                                //  ALU pipe: int; 
(W)     and (1|M0)               r127.2<1>:ud  r0.0<0;1,0>:ud    0xFFFFFFC0:ud                       //  ALU pipe: int; 
(W)     and (1|M0)               r127.0<1>:uw  r0.4<0;1,0>:uw    0xFF:uw                             //  ALU pipe: int; 
(W)     add (1|M0)               r127.2<1>:ud  r127.2<0;1,0>:ud  0x60:ud              {I@2}          //  ALU pipe: int; 
(W)     add (1|M0)               r127.2<1>:ud  r127.2<0;1,0>:ud  0x0:ud              {I@1}           //  R_SYM_ADDR_32: __INTEL_PATCH_CROSS_THREAD_OFFSET_OFF_R0; ALU pipe: int; 
(W)     mad (1|M0)               r127.0<1>:ud  r127.2<0;0>:ud    r127.0<0;0>:uw    0x40:uw              {I@1} //  ALU pipe: int; 
(W)     mov (8|M0)               r2.0<1>:ud    r1.0<1;1,0>:ud                                        //  ALU pipe: int; 
(W)     load.ugm.d32x16t.a32.ca.cc (1|M0)  r1:1 bti[255][r127:1]   {A@1,$0} // ex_desc:0xFF000000; desc:0x6219D500 // 
// B001: Preds:{B000},  Succs:{B002}
// cross_thread_prolog:
(W)     and (1|M0)               r127.0<1>:ud  r0.0<0;1,0>:ud    0xFFFFFFC0:ud              {$0.src} //  ALU pipe: int; 
(W)     add (1|M0)               r127.0<1>:ud  r127.0<0;1,0>:ud  0x0:ud              {I@1}           //  R_SYM_ADDR_32: __INTEL_PATCH_CROSS_THREAD_OFFSET_OFF_R0; ALU pipe: int; 
(W)     load.ugm.d32x16t.a32.ca.cc (1|M0)  r3:1 bti[255][r127:1]   {I@1,$1} // ex_desc:0xFF000000; desc:0x6219D500 // 
(W)     load.ugm.d32x8t.a32.ca.cc (1|M0)  r4:1  bti[255][r127:1+0x40]  {$2} // ex_desc:0xFF040000; desc:0x6219C500 // 
// B002: Preds:{B001},  Succs:{B003, B004}
// _main:
(W)     mov (16|M0)              r40.0<1>:ud   r0.0<1;1,0>:ud                   {Compacted}          //  ALU pipe: int; $1
(W)     or (1|M0)                cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x400004C0:ud              {A@1}    // $1
(W)     mul (1|M0)               acc0.0<1>:d   r2.3<0;1,0>:d     r40.2<0;1,0>:uw  {A@1}              //  ALU pipe: int; $2
(W)     asr (1|M0)               r41.1<1>:d    r3.13<0;1,0>:d    31:w               {$1.dst}         //  ALU pipe: int; $6
(W)     macl (1|M0)              r5.0<1>:d     r2.3<0;1,0>:d     r40.1<0;1,0>:d   {Compacted}        //  ALU pipe: int; $4
(W)     mul (1|M0)               acc0.0<1>:ud  r3.9<0;1,0>:ud    r3.26<0;1,0>:uw                     //  ALU pipe: int; $7
(W)     macl (1|M0)              r44.0<1>:ud   r3.9<0;1,0>:ud    r3.13<0;1,0>:ud                     //  ALU pipe: int; $8
(W)     mul (1|M0)               acc0.0<1>:ud  r3.9<0;1,0>:ud    r3.26<0;1,0>:uw                     //  ALU pipe: int; $8
(W)     asr (1|M0)               r41.0<1>:d    r3.9<0;1,0>:d     31:w                                //  ALU pipe: int; $5
(W)     mach (1|M0)              r6.0<1>:d     r3.9<0;1,0>:ud    r3.13<0;1,0>:ud                     //  ALU pipe: int; 
(W)     mul (1|M0)               acc0.0<1>:d   r3.9<0;1,0>:ud    r41.2<0;1,0>:uw  {I@7}              //  ALU pipe: int; $9
(W)     macl (1|M0)              r7.0<1>:d     r3.9<0;1,0>:ud    r41.1<0;1,0>:d                      //  ALU pipe: int; $10
(W)     mul (1|M0)               acc0.0<1>:d   r3.13<0;1,0>:ud   r41.0<0;1,0>:uw  {I@4}              //  ALU pipe: int; $11
(W)     add (1|M0)               r6.0<1>:d     r6.0<0;1,0>:d     r7.0<0;1,0>:d    {Compacted,I@2}    //  ALU pipe: int; $10
(W)     macl (1|M0)              r7.0<1>:d     r3.13<0;1,0>:ud   r41.0<0;1,0>:d                      //  ALU pipe: int; $13
        add3 (32|M0)             r42.0<1>:d    r5.0<0;0>:d       r1.0<1;0>:uw      r2.0<0>:d        {$0.dst} //  ALU pipe: int; $4
(W)     add (1|M0)               r41.2<1>:d    r6.0<0;1,0>:d     r7.0<0;1,0>:d    {Compacted,I@2}    //  ALU pipe: int; $13
(W)     mov (1|M0)               r41.3<1>:df   0xBCF0000000000000:df                                 //  ALU pipe: long; $19
(W)     cmp (32|M0)   (lt)f3.0   null<1>:ud    r41.2<0;1,0>:ud   0x1:uw              {I@1}           //  ALU pipe: int; $18
(W)     mov (1|M0)               r41.4<1>:df   0x3FF0000000000000:df                                 //  ALU pipe: long; $20
(W)     mov (1|M0)               r41.4<1>:d    r44.0<0;1,0>:d                                        //  ALU pipe: int; $14
(W)     mov (1|M0)               r41.5<1>:d    r41.2<0;1,0>:d                                        //  ALU pipe: int; $15
(W&f3.0) jmpi                                _0_025                                                  //  ALU pipe: int; $21
// B003: Preds:{B002},  Succs:{B008}
_0_026:
(W)     mov (1|M0)               r3.5<1>:df    r41.2<0;1,0>:uq                  {I@2}                //  ALU pipe: long; $24
        mov (16|M0)              r8.0<2>:ud    r42.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $31
(W)     mov (1|M0)               r2.8<2>:f     r3.5<0;1,0>:df                   {L@1}                //  ALU pipe: float; $25
        mov (16|M16)             r12.0<2>:ud   r43.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $31
(W)     math.inv (1|M0)          r3.12<1>:f    r2.8<0;1,0>:f                    {F@1}                //  ALU pipe: math; $26
        sync.nop                             null                             {M@1}                  // $27
(W)     mov (1|M0)               r4.1<1>:df    r3.12<0;1,0>:f                   {$2.dst}             //  ALU pipe: long; $27
        mov (16|M0)              r10.0<1>:df   r8.0<2;1,0>:ud                   {I@2}                //  ALU pipe: long; $31
(W)     mad (1|M0)               r4.2<1>:df    r41.4<0;0>:df     r4.1<0;0>:df      -r3.5<0>:df      {L@2} //  ALU pipe: long; $28
        mov (16|M16)             r14.0<1>:df   r12.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $31
(W)     add (1|M0)               r5.0<1>:df    r4.2<0;1,0>:df    r41.3<0;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $29
        mov (32|M0)              r12.0<1>:f    r42.0<1;1,0>:f                   {Compacted,L@2}      //  ALU pipe: float; $43
(W)     mad (1|M0)               r6.0<1>:df    r4.1<0;0>:df      r5.0<0;0>:df      r4.1<0>:df       {L@1} //  ALU pipe: long; $30
(W)     mov (1|M0)               r2.16<1>:hf   0xFFFF:hf                                             //  ALU pipe: float; $67
        mul (16|M0)              r16.0<1>:df   r6.0<0;1,0>:df    r10.0<1;1,0>:df  {Compacted,L@1}    //  ALU pipe: long; $32
        mul (16|M16)             r18.0<1>:df   r6.0<0;1,0>:df    r14.0<1;1,0>:df  {Compacted}        //  ALU pipe: long; $32
        mov (16|M0)              r20.0<1>:uq   r16.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $33
        mov (16|M16)             r22.0<1>:uq   r18.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $33
        mov (16|M0)              r26.0<1>:d    r20.1<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $36
        mov (16|M16)             r27.0<1>:d    r22.1<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $37
        mov (16|M0)              r28.0<1>:d    r20.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $38
        cmp (32|M0)   (lt)f3.0   null<1>:ud    r26.0<1;1,0>:ud   0x1:uw              {I@2}           //  ALU pipe: int; $40
        mov (16|M16)             r29.0<1>:d    r22.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $38
        mov (16|M0)              r24.0<1>:d    r20.0<2;1,0>:d                                        //  ALU pipe: int; $34
(W)     mul (16|M0)              acc0.0<1>:d   r28.0<1;1,0>:d    r41.4<0;1,0>:uw  {I@4}              //  ALU pipe: int; $39
        mov (16|M16)             r25.0<1>:d    r22.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $35
        macl (16|M0)             r8.0<1>:d     r28.0<1;1,0>:d    r41.2<0;1,0>:d   {Compacted}        //  ALU pipe: int; $39
(W)     mul (16|M16)             acc0.0<1>:d   r29.0<1;1,0>:d    r41.4<0;1,0>:uw  {I@5}              //  ALU pipe: int; $39
(~f3.0) sel (32|M0)              r6.0<1>:d     r41.4<0;1,0>:d    0:w                                 //  ALU pipe: int; $41
        macl (16|M16)            r9.0<1>:d     r29.0<1;1,0>:d    r41.2<0;1,0>:d   {Compacted}        //  ALU pipe: int; $40
(W)     mul (16|M0)              acc0.0<1>:ud  r24.0<1;1,0>:ud   r44.0<0;1,0>:uw  {I@7}              //  ALU pipe: int; $49
        macl (16|M0)             r18.0<1>:ud   r24.0<1;1,0>:ud   r44.0<0;1,0>:ud  {Compacted}        //  ALU pipe: int; $50
(W)     mul (16|M16)             acc0.0<1>:ud  r25.0<1;1,0>:ud   r44.0<0;1,0>:uw  {I@7}              //  ALU pipe: int; $50
        add3 (32|M0)             r10.0<1>:d    0:w                -r8.0<1;0>:d      -r6.0<1>:d       {I@4} //  ALU pipe: int; $42
        macl (16|M16)            r26.0<1>:ud   r25.0<1;1,0>:ud   r44.0<0;1,0>:ud                     //  ALU pipe: int; $51
(W)     mul (16|M0)              acc0.0<1>:ud  r24.0<1;1,0>:ud   r44.0<0;1,0>:uw                     //  ALU pipe: int; $51
        mach (16|M0)             r6.0<1>:d     r24.0<1;1,0>:ud   r44.0<0;1,0>:ud                     //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r25.0<1;1,0>:ud   r44.0<0;1,0>:uw                     //  ALU pipe: int; $51
        mach (16|M16)            r7.0<1>:d     r25.0<1;1,0>:ud   r44.0<0;1,0>:ud                     //  ALU pipe: int; $53
        mov (32|M0)              r8.0<1>:d     0:w                               {Compacted}         //  ALU pipe: int; $54
        mov (16|M0)              r14.0<2>:d    r12.0<1;1,0>:d                   {F@2}                //  ALU pipe: int; $45
        mov (16|M16)             r16.0<2>:d    r13.0<1;1,0>:d                                        //  ALU pipe: int; $46
        mov (16|M0)              r30.0<2>:ud   r18.0<1;1,0>:ud                  {Compacted,I@7}      //  ALU pipe: int; $50
        mov (16|M16)             r27.0<2>:ud   r26.0<1;1,0>:ud                  {I@7}                //  ALU pipe: int; $51
        mov (16|M0)              r14.1<2>:d    r10.0<1;1,0>:d                                        //  ALU pipe: int; $47
        mov (16|M16)             r16.1<2>:d    r11.0<1;1,0>:d                                        //  ALU pipe: int; $48
        add (16|M0)              r30.1<2>:d    r6.0<1;1,0>:d     r8.0<1;1,0>:d    {I@7}              //  ALU pipe: int; $55
        add (16|M16)             r27.1<2>:d    r7.0<1;1,0>:d     r9.0<1;1,0>:d                       //  ALU pipe: int; $56
        add (16|M0)              r10.0<1>:q    r14.0<1;1,0>:q    -r30.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $57 R{} IR{}{E:7,E:7,},  R{} IR{}{O:7,O:15,},  {BC=1}
        add (16|M16)             r12.0<1>:q    r16.0<1;1,0>:q    -r27.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $57
        mov (16|M0)              r18.0<1>:d    r10.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $58
        mov (16|M16)             r19.0<1>:d    r12.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $59
        cmp (32|M0)   (ge)f2.0   null<1>:ud    r18.0<1;1,0>:ud   r44.0<0;1,0>:ud  {I@1}              //  ALU pipe: int; $62
        mov (16|M0)              r32.0<1>:d    r10.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $60
        mov (16|M16)             r33.0<1>:d    r12.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $61
(f2.0)  cmp (32|M0)   (eq)f2.0   null<1>:d     r32.0<1;1,0>:d    r41.2<0;1,0>:d   {I@1}              //  ALU pipe: int; $63
(~f2.0) cmp (32|M0)   (gt)f2.0   null<1>:ud    r32.0<1;1,0>:ud   r41.2<0;1,0>:ud                     //  ALU pipe: int; $65
(f2.0)  sel (32|M0)              r24.0<1>:d    r2.16<0;1,0>:w    0:w               {F@1}             //  ALU pipe: int; $67
        mov (16|M0)              r34.0<2>:ud   r24.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $68
        mov (16|M16)             r8.0<2>:ud    r25.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $68
        mov (16|M0)              r5.0<1>:q     r34.0<2;1,0>:d                   {I@2}                //  ALU pipe: int; $68
        mov (16|M16)             r14.0<1>:q    r8.0<2;1,0>:d                    {I@2}                //  ALU pipe: int; $68
        add (16|M0)              r64.0<1>:q    r20.0<1;1,0>:q    -r5.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $69
        add (16|M16)             r66.0<1>:q    r22.0<1;1,0>:q    -r14.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $69
(W)     jmpi                                 _0_027                                                  // $70
// B004: Preds:{B002},  Succs:{B005, B006}
_0_025:
(W)     cmp (32|M0)   (eq)f2.0   null<1>:d     r44.0<0;1,0>:d    0:w                                 //  ALU pipe: int; $72
(W&~f2.0) jmpi                               _0_028                                                  //  ALU pipe: int; $73
// B005: Preds:{B004},  Succs:{B007}
_0_029:
        mov (32|M0)              r46.0<1>:d    -1:w                                                  //  ALU pipe: int; $75
(W)     jmpi                                 _0_030                                                  // $76
// B006: Preds:{B004},  Succs:{B007}
_0_028:
(W)     mov (1|M0)               r2.8<2>:d     r41.2<0;1,0>:q                                        //  ALU pipe: int; $78
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $79
(W)     mov (1|M0)               r2.9<1>:f     r2.8<0;1,0>:ud                   {A@1}                //  ALU pipe: float; $80
(W)     mov (1|M0)               r3.11<1>:f    0xB4C00000:f                                          //  ALU pipe: float; $85
(W)     math.inv (1|M0)          r4.1<1>:f     r2.9<0;1,0>:f                    {@2,$2.dst}          //  ALU pipe: math; $84
        mov (32|M0)              r6.0<1>:f     r42.0<1;1,0>:ud                                       //  ALU pipe: float; $83
(W)     mad (1|M0)               r5.0<1>:f     r4.1<0;0>:f       r3.11<0;0>:f      r4.1<0>:f        {A@1} //  ALU pipe: float; $85
        mov (32|M0)              r10.0<1>:ud   r6.0<1;1,0>:f                    {F@2}                //  ALU pipe: int; $87
        mul (32|M0)              r8.0<1>:f     r6.0<1;1,0>:f     r5.0<0;1,0>:f    {Compacted,F@1}    //  ALU pipe: float; $86
(W)     mov (1|M0)               r2.10<1>:ud   r2.9<0;1,0>:f                                         //  ALU pipe: int; $81
        add (32|M0)              r12.0<1>:d    r42.0<1;1,0>:d    -r10.0<1;1,0>:d  {Compacted,I@2}    //  ALU pipe: int; $88 R{} IR{}{E:5,E:5,},  R{} IR{}{O:5,O:5,},  {BC=2}
        mov (32|M0)              r14.0<1>:ud   r8.0<1;1,0>:f                    {F@1}                //  ALU pipe: int; $89
(W)     add (1|M0)               r3.10<1>:d    r2.8<0;1,0>:d     -r2.10<0;1,0>:d  {I@3}              //  ALU pipe: int; $82
        mov (32|M0)              r20.0<1>:f    r14.0<1;1,0>:ud                  {I@2}                //  ALU pipe: float; $92
        mov (32|M0)              r18.0<1>:f    r12.0<1;1,0>:ud                                       //  ALU pipe: float; $91
(W)     mov (1|M0)               r16.0<1>:f    r3.10<0;1,0>:ud                  {I@1}                //  ALU pipe: float; $90
        mad (32|M0)              acc0.0<1>:f   r6.0<1;0>:f       r20.0<1;0>:f      -r2.9<0>:f       {F@3} //  ALU pipe: float; $94 R{} IR{}{E:3,E:2,E:1,},  R{r2,} IR{}{O:3,O:10,},  {BC=1}
        mad (32|M0)              acc2.0<1>:f   r18.0<1;0>:f      r20.0<1;0>:f      -r16.0<0>:f      {F@2} //  ALU pipe: float; $96 R{} IR{}{E:1,E:2,E:0,},  R{r16,} IR{}{O:9,O:10,},  {BC=1}
        add (32|M0)              acc0.0<1>:f   acc0.0<1;1,0>:f   acc2.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $97
        mul (32|M0)              r22.0<1>:f    r5.0<0;1,0>:f     acc0.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $98
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $99
        mov (32|M0)              r24.0<1>:ud   r22.0<1;1,0>:f                   {A@1}                //  ALU pipe: int; $100
        add (32|M0)              r26.0<1>:d    r24.0<1;1,0>:d    r14.0<1;1,0>:d   {Compacted,I@1}    //  ALU pipe: int; $101
(W)     mul (16|M0)              acc0.0<1>:d   r26.0<1;1,0>:d    r2.16<0;1,0>:uw  {I@1}              //  ALU pipe: int; $102
        macl (16|M0)             r8.0<1>:d     r26.0<1;1,0>:d    r2.8<0;1,0>:d    {Compacted}        //  ALU pipe: int; $102
(W)     mul (16|M16)             acc0.0<1>:d   r27.0<1;1,0>:d    r2.16<0;1,0>:uw                     //  ALU pipe: int; $102
        macl (16|M16)            r9.0<1>:d     r27.0<1;1,0>:d    r2.8<0;1,0>:d    {Compacted}        //  ALU pipe: int; $103
        add (32|M0)              r10.0<1>:d    r42.0<1;1,0>:d    -r8.0<1;1,0>:d   {Compacted,I@1}    //  ALU pipe: int; $103
        cmp (32|M0)   (ge)f1.0   r6.0<1>:ud    r10.0<1;1,0>:ud   r2.8<0;1,0>:ud   {I@1}              //  ALU pipe: int; $104
        add3 (32|M0)             r46.0<1>:d    r24.0<1;0>:d      r14.0<1;0>:d      -r6.0<1>:d       {Compacted,I@1} //  ALU pipe: int; $105 R{} IR{}{E:4,E:7,E:3,},  R{} IR{}{O:12,O:7,O:3,},  {BC=2}
// B007: Preds:{B006, B005},  Succs:{B008}
_0_030:
        mov (16|M0)              r6.0<2>:ud    r46.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $107
        mov (16|M16)             r8.0<2>:ud    r47.0<1;1,0>:ud                                       //  ALU pipe: int; $107
        mov (16|M0)              r64.0<1>:q    r6.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $107
        mov (16|M16)             r66.0<1>:q    r8.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $107
// B008: Preds:{B007, B003},  Succs:{B009, B010}
_0_027:
(W)     cmp (32|M0)   (gt)f1.0   null<1>:d     r3.13<0;1,0>:d    -1:w                                //  ALU pipe: int; $109
(W&f1.0) jmpi                                _0_031                                                  //  ALU pipe: int; $110
// B009: Preds:{B008},  Succs:{B014}
_0_032:
(W)     mov (1|M0)               r2.4<1>:q     r3.13<0;1,0>:d                                        //  ALU pipe: int; $112
        mov (16|M0)              r10.0<2>:ud   r42.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $120
(W)     mov (1|M0)               r3.5<1>:df    r2.4<0;1,0>:uq                   {I@2}                //  ALU pipe: long; $113
        mov (16|M16)             r14.0<2>:ud   r43.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $120
(W)     mov (1|M0)               r3.12<2>:f    r3.5<0;1,0>:df                   {L@1}                //  ALU pipe: float; $114
        mov (16|M0)              r12.0<1>:df   r10.0<2;1,0>:ud                  {I@2}                //  ALU pipe: long; $120
(W)     math.inv (1|M0)          r4.1<1>:f     r3.12<0;1,0>:f                   {@1,$2.dst}          //  ALU pipe: math; $115
(W)     mov (1|M0)               r6.0<1>:df    r4.1<0;1,0>:f                    {M@1}                //  ALU pipe: long; $116
        mov (16|M16)             r16.0<1>:df   r14.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $120
(W)     mad (1|M0)               r5.0<1>:df    r41.4<0;0>:df     r6.0<0;0>:df      -r3.5<0>:df      {L@2} //  ALU pipe: long; $117
(W)     mov (1|M0)               r2.16<1>:hf   0xFFFF:hf                                             //  ALU pipe: float; $155
(W)     add (1|M0)               r7.0<1>:df    r5.0<0;1,0>:df    r41.3<0;1,0>:df  {Compacted,L@1}    //  ALU pipe: long; $118
(W)     mad (1|M0)               r8.0<1>:df    r6.0<0;0>:df      r7.0<0;0>:df      r6.0<0>:df       {L@1} //  ALU pipe: long; $119
        mul (16|M0)              r18.0<1>:df   r8.0<0;1,0>:df    r12.0<1;1,0>:df  {Compacted,L@1}    //  ALU pipe: long; $121
        mul (16|M16)             r20.0<1>:df   r8.0<0;1,0>:df    r16.0<1;1,0>:df  {Compacted}        //  ALU pipe: long; $121
        mov (16|M0)              r22.0<1>:uq   r18.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $122
        mov (16|M16)             r24.0<1>:uq   r20.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $122
        mov (16|M0)              r28.0<1>:d    r22.1<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $125
        mov (16|M16)             r29.0<1>:d    r24.1<2;1,0>:d                   {I@2}                //  ALU pipe: int; $126
        cmp (32|M0)   (lt)f0.0   null<1>:ud    r28.0<1;1,0>:ud   0x1:uw              {I@1}           //  ALU pipe: int; $128
        mov (16|M0)              r26.0<1>:d    r22.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $123
        mov (16|M16)             r27.0<1>:d    r24.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $124
        mov (16|M0)              r6.0<1>:d     r22.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $127
        mov (16|M16)             r7.0<1>:d     r24.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $127
(~f0.0) sel (32|M0)              r10.0<1>:d    r3.13<0;1,0>:d    0:w                                 //  ALU pipe: int; $129
(W)     mul (16|M0)              acc0.0<1>:ud  r26.0<1;1,0>:ud   r3.26<0;1,0>:uw  {I@5}              //  ALU pipe: int; $137
        macl (16|M0)             r18.0<1>:ud   r26.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; $138
(W)     mul (16|M16)             acc0.0<1>:ud  r27.0<1;1,0>:ud   r3.26<0;1,0>:uw  {I@6}              //  ALU pipe: int; $138
        add (32|M0)              r14.0<1>:d    r6.0<1;1,0>:d     -r10.0<1;1,0>:d  {I@4}              //  ALU pipe: int; $130
        macl (16|M16)            r28.0<1>:ud   r27.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; $139
(W)     mul (16|M0)              acc0.0<1>:ud  r26.0<1;1,0>:ud   r3.26<0;1,0>:uw                     //  ALU pipe: int; $139
        mach (16|M0)             r6.0<1>:d     r26.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r27.0<1;1,0>:ud   r3.26<0;1,0>:uw                     //  ALU pipe: int; $139
        mach (16|M16)            r7.0<1>:d     r27.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; $141
        mov (32|M0)              r12.0<1>:f    r42.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $131
        mov (32|M0)              r10.0<1>:d    0:w                               {Compacted}         //  ALU pipe: int; $142
        mov (16|M0)              r19.0<2>:ud   r18.0<1;1,0>:ud                  {Compacted,I@7}      //  ALU pipe: int; $138
        mov (16|M16)             r29.0<2>:ud   r28.0<1;1,0>:ud                  {Compacted,I@7}      //  ALU pipe: int; $139
        mov (16|M0)              r8.0<2>:d     r12.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $133
        mov (16|M16)             r16.0<2>:d    r13.0<1;1,0>:d                                        //  ALU pipe: int; $134
        add (16|M0)              r19.1<2>:d    r6.0<1;1,0>:d     r10.0<1;1,0>:d   {I@5}              //  ALU pipe: int; $143
        add (16|M16)             r29.1<2>:d    r7.0<1;1,0>:d     r11.0<1;1,0>:d                      //  ALU pipe: int; $144
        mov (16|M0)              r8.1<2>:d     r14.0<1;1,0>:d                                        //  ALU pipe: int; $135
        mov (16|M16)             r16.1<2>:d    r15.0<1;1,0>:d                                        //  ALU pipe: int; $136
        add (16|M0)              r12.0<1>:q    r8.0<1;1,0>:q     -r19.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $145
        add (16|M16)             r14.0<1>:q    r16.0<1;1,0>:q    -r29.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $145
        mov (16|M0)              r32.0<1>:d    r12.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $146
        mov (16|M16)             r33.0<1>:d    r14.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $147
        cmp (32|M0)   (ge)f1.0   null<1>:ud    r32.0<1;1,0>:ud   r3.13<0;1,0>:ud  {I@1}              //  ALU pipe: int; $150
        mov (16|M0)              r34.0<1>:d    r12.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $148
        mov (16|M16)             r35.0<1>:d    r14.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $149
(f1.0)  cmp (32|M0)   (eq)f1.0   null<1>:d     r34.0<1;1,0>:d    r41.1<0;1,0>:d   {I@1}              //  ALU pipe: int; $151
(~f1.0) cmp (32|M0)   (gt)f1.0   null<1>:ud    r34.0<1;1,0>:ud   r41.1<0;1,0>:ud                     //  ALU pipe: int; $153
(f1.0)  sel (32|M0)              r26.0<1>:d    r2.16<0;1,0>:w    0:w                                 //  ALU pipe: int; $155
        mov (16|M0)              r36.0<2>:ud   r26.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $156
        mov (16|M16)             r8.0<2>:ud    r27.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $156
        mov (16|M0)              r5.0<1>:q     r36.0<2;1,0>:d                   {I@2}                //  ALU pipe: int; $156
        mov (16|M16)             r10.0<1>:q    r8.0<2;1,0>:d                    {I@2}                //  ALU pipe: int; $156
        add (16|M0)              r68.0<1>:q    r22.0<1;1,0>:q    -r5.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $157
        add (16|M16)             r70.0<1>:q    r24.0<1;1,0>:q    -r10.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $157
(W)     jmpi                                 _0_033                                                  // $158
// B010: Preds:{B008},  Succs:{B011, B012}
_0_031:
(W)     cmp (32|M0)   (eq)f3.0   null<1>:d     r3.13<0;1,0>:d    0:w                                 //  ALU pipe: int; $160
(W&~f3.0) jmpi                               _0_034                                                  //  ALU pipe: int; $161
// B011: Preds:{B010},  Succs:{B013}
_0_035:
        mov (32|M0)              r48.0<1>:d    -1:w                                                  //  ALU pipe: int; $163
(W)     jmpi                                 _0_036                                                  // $164
// B012: Preds:{B010},  Succs:{B013}
_0_034:
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $166
(W)     mov (1|M0)               r2.8<1>:f     r3.13<0;1,0>:ud                  {A@1}                //  ALU pipe: float; $167
(W)     mov (1|M0)               r3.11<1>:f    0xB4C00000:f                                          //  ALU pipe: float; $172
(W)     math.inv (1|M0)          r4.1<1>:f     r2.8<0;1,0>:f                    {@2,$2.dst}          //  ALU pipe: math; $171
        mov (32|M0)              r6.0<1>:f     r42.0<1;1,0>:ud                  {I@7}                //  ALU pipe: float; $170
(W)     mad (1|M0)               r5.0<1>:f     r4.1<0;0>:f       r3.11<0;0>:f      r4.1<0>:f        {A@1} //  ALU pipe: float; $172
        mov (32|M0)              r10.0<1>:ud   r6.0<1;1,0>:f                    {F@2}                //  ALU pipe: int; $174
        mul (32|M0)              r8.0<1>:f     r6.0<1;1,0>:f     r5.0<0;1,0>:f    {Compacted,F@1}    //  ALU pipe: float; $173
(W)     mov (1|M0)               r2.9<1>:ud    r2.8<0;1,0>:f                                         //  ALU pipe: int; $168
        add (32|M0)              r12.0<1>:d    r42.0<1;1,0>:d    -r10.0<1;1,0>:d  {Compacted,I@2}    //  ALU pipe: int; $175 R{} IR{}{E:5,E:5,},  R{} IR{}{O:5,O:5,},  {BC=2}
        mov (32|M0)              r14.0<1>:ud   r8.0<1;1,0>:f                    {F@1}                //  ALU pipe: int; $176
(W)     add (1|M0)               r3.10<1>:d    r3.13<0;1,0>:d    -r2.9<0;1,0>:d   {I@3}              //  ALU pipe: int; $169
        mov (32|M0)              r20.0<1>:f    r14.0<1;1,0>:ud                  {I@2}                //  ALU pipe: float; $179
        mov (32|M0)              r18.0<1>:f    r12.0<1;1,0>:ud                                       //  ALU pipe: float; $178
(W)     mov (1|M0)               r16.0<1>:f    r3.10<0;1,0>:ud                  {I@1}                //  ALU pipe: float; $177
        mad (32|M0)              acc0.0<1>:f   r6.0<1;0>:f       r20.0<1;0>:f      -r2.8<0>:f       {F@3} //  ALU pipe: float; $181 R{} IR{}{E:3,E:2,E:1,},  R{r2,} IR{}{O:3,O:10,},  {BC=1}
        mad (32|M0)              acc2.0<1>:f   r18.0<1;0>:f      r20.0<1;0>:f      -r16.0<0>:f      {F@2} //  ALU pipe: float; $183 R{} IR{}{E:1,E:2,E:0,},  R{r16,} IR{}{O:9,O:10,},  {BC=1}
        add (32|M0)              acc0.0<1>:f   acc0.0<1;1,0>:f   acc2.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $184
        mul (32|M0)              r22.0<1>:f    r5.0<0;1,0>:f     acc0.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $185
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $186
        mov (32|M0)              r24.0<1>:ud   r22.0<1;1,0>:f                   {A@1}                //  ALU pipe: int; $187
        add (32|M0)              r26.0<1>:d    r24.0<1;1,0>:d    r14.0<1;1,0>:d   {I@1}              //  ALU pipe: int; $188
(W)     mul (16|M0)              acc0.0<1>:d   r26.0<1;1,0>:d    r3.26<0;1,0>:uw  {I@1}              //  ALU pipe: int; $189
        macl (16|M0)             r8.0<1>:d     r26.0<1;1,0>:d    r3.13<0;1,0>:d                      //  ALU pipe: int; $189
(W)     mul (16|M16)             acc0.0<1>:d   r27.0<1;1,0>:d    r3.26<0;1,0>:uw                     //  ALU pipe: int; $189
        macl (16|M16)            r9.0<1>:d     r27.0<1;1,0>:d    r3.13<0;1,0>:d                      //  ALU pipe: int; $190
        add (32|M0)              r10.0<1>:d    r42.0<1;1,0>:d    -r8.0<1;1,0>:d   {Compacted,I@1}    //  ALU pipe: int; $190
        cmp (32|M0)   (ge)f0.0   r6.0<1>:ud    r10.0<1;1,0>:ud   r3.13<0;1,0>:ud  {I@1}              //  ALU pipe: int; $191
        add3 (32|M0)             r48.0<1>:d    r24.0<1;0>:d      r14.0<1;0>:d      -r6.0<1>:d       {Compacted,I@1} //  ALU pipe: int; $192 R{} IR{}{E:4,E:7,E:3,},  R{} IR{}{O:12,O:7,O:3,},  {BC=2}
// B013: Preds:{B012, B011},  Succs:{B014}
_0_036:
        mov (16|M0)              r6.0<2>:ud    r48.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $194
        mov (16|M16)             r8.0<2>:ud    r49.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $194
        mov (16|M0)              r68.0<1>:q    r6.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $194
        mov (16|M16)             r70.0<1>:q    r8.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $194
// B014: Preds:{B013, B009},  Succs:{B015, B016}
_0_033:
        or (16|M0)               r6.0<1>:d     r68.1<2;1,0>:d    r41.0<0;1,0>:d   {Compacted,I@2}    //  ALU pipe: int; $200
        or (16|M16)              r7.0<1>:d     r70.1<2;1,0>:d    r41.0<0;1,0>:d   {Compacted,I@2}    //  ALU pipe: int; $201
        cmp (32|M0)   (lt)f2.0   null<1>:ud    r6.0<1;1,0>:ud    0x1:uw              {I@1}           //  ALU pipe: int; $202
        mov (16|M0)              r50.0<1>:d    r68.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $196
        mov (16|M16)             r51.0<1>:d    r70.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $197
        mov (16|M0)              r52.0<1>:d    r68.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $198
        mov (16|M16)             r53.0<1>:d    r70.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $199
(f2.0)  goto (32|M0)                         _0_037            _0_037                                //  ALU pipe: int; $203
// B015: [inDivergent],  Preds:{B014},  Succs:{B020}
_0_038:
(W)     mov (1|M0)               r2.4<1>:q     r3.9<0;1,0>:d                                         //  ALU pipe: int; $205
        mov (16|M0)              r10.0<1>:d    r68.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $213
(W)     mov (1|M0)               r3.5<1>:df    r2.4<0;1,0>:uq                   {I@2}                //  ALU pipe: long; $206
        mov (16|M16)             r11.0<1>:d    r70.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $214
(W)     mov (1|M0)               r3.12<2>:f    r3.5<0;1,0>:df                   {L@1}                //  ALU pipe: float; $207
        mov (16|M0)              r12.0<2>:ud   r10.0<1;1,0>:ud                  {I@2}                //  ALU pipe: int; $215
(W)     math.inv (1|M0)          r4.1<1>:f     r3.12<0;1,0>:f                   {@1,$2.dst}          //  ALU pipe: math; $208
(W)     mov (1|M0)               r6.0<1>:df    r4.1<0;1,0>:f                    {M@1}                //  ALU pipe: long; $209
        mov (16|M16)             r16.0<2>:ud   r11.0<1;1,0>:ud                  {I@2}                //  ALU pipe: int; $215
(W)     mad (1|M0)               r5.0<1>:df    r41.4<0;0>:df     r6.0<0;0>:df      -r3.5<0>:df      {L@1} //  ALU pipe: long; $210
        mov (16|M0)              r14.0<1>:df   r12.0<2;1,0>:ud                  {I@2}                //  ALU pipe: long; $215
(W)     add (1|M0)               r7.0<1>:df    r5.0<0;1,0>:df    r41.3<0;1,0>:df  {L@2}              //  ALU pipe: long; $211
        mov (16|M16)             r18.0<1>:df   r16.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $215
(W)     mad (1|M0)               r8.0<1>:df    r6.0<0;0>:df      r7.0<0;0>:df      r6.0<0>:df       {L@2} //  ALU pipe: long; $212
(W)     mov (1|M0)               r2.4<1>:df    0x41F0000000000000:df                                 //  ALU pipe: long; $223
        mul (16|M0)              r20.0<1>:df   r8.0<0;1,0>:df    r14.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $216
        mul (16|M16)             r22.0<1>:df   r8.0<0;1,0>:df    r18.0<1;1,0>:df  {Compacted}        //  ALU pipe: long; $216
        mov (16|M0)              r24.0<2>:ud   r20.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $217
        mov (16|M16)             r28.0<2>:ud   r22.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $217
        mov (16|M0)              r26.0<1>:ud   r24.0<2;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $217
        mov (16|M16)             r27.0<1>:ud   r28.0<2;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $217
(W)     mul (16|M0)              acc0.0<1>:d   r3.9<0;1,0>:d     r26.0<2;1,0>:uw  {I@2}              //  ALU pipe: int; $218
        macl (16|M0)             r6.0<1>:d     r3.9<0;1,0>:d     r26.0<1;1,0>:d   {Compacted}        //  ALU pipe: int; $218
(W)     mul (16|M16)             acc0.0<1>:d   r3.9<0;1,0>:d     r27.0<2;1,0>:uw  {I@3}              //  ALU pipe: int; $218
        macl (16|M16)            r7.0<1>:d     r3.9<0;1,0>:d     r27.0<1;1,0>:d   {Compacted}        //  ALU pipe: int; $219
        add (32|M0)              r12.0<1>:d    r10.0<1;1,0>:d    -r6.0<1;1,0>:d   {Compacted,I@1}    //  ALU pipe: int; $219
        mov (16|M0)              r30.0<2>:ud   r12.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $221
        mov (16|M16)             r14.0<2>:ud   r13.0<1;1,0>:ud                                       //  ALU pipe: int; $221
        mov (16|M0)              r20.0<1>:df   r68.0<2;1,0>:ud                                       //  ALU pipe: long; $222
        mov (16|M16)             r24.0<1>:df   r70.0<2;1,0>:ud                                       //  ALU pipe: long; $222
        mov (16|M0)              r33.0<1>:df   r30.0<2;1,0>:ud                  {I@2}                //  ALU pipe: long; $221
        mov (16|M16)             r17.0<1>:df   r14.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $221
        mad (16|M0)              r22.0<1>:df   r20.0<1;0>:df     r33.0<1;0>:df     r2.4<0>:df       {Compacted,L@2} //  ALU pipe: long; $224
        mad (16|M16)             r28.0<1>:df   r24.0<1;0>:df     r17.0<1;0>:df     r2.4<0>:df       {Compacted,L@2} //  ALU pipe: long; $224
        mul (16|M0)              r35.0<1>:df   r8.0<0;1,0>:df    r22.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $225
        mul (16|M16)             r26.0<1>:df   r8.0<0;1,0>:df    r28.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $225
        mov (16|M0)              r5.0<1>:uq    r35.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $226
        mov (16|M16)             r9.0<1>:uq    r26.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $226
        mov (16|M0)              r30.0<1>:d    r5.1<2;1,0>:d                    {Compacted,I@2}      //  ALU pipe: int; $229
        mov (16|M16)             r31.0<1>:d    r9.1<2;1,0>:d                    {Compacted,I@2}      //  ALU pipe: int; $230
(W)     cmp (32|M0)   (lt)f1.0   null<1>:d     r3.9<0;1,0>:d     0:w                                 //  ALU pipe: int; $232
        cmp (32|M0)   (lt)f0.0   null<1>:ud    r30.0<1;1,0>:ud   0x1:uw              {I@2}           //  ALU pipe: int; $234
        mov (16|M0)              r38.0<1>:d    r5.0<2;1,0>:d                    {Compacted}          //  ALU pipe: int; $227
        mov (16|M0)              r14.0<1>:d    r5.0<2;1,0>:d                    {Compacted}          //  ALU pipe: int; $231
        mov (16|M16)             r15.0<1>:d    r9.0<2;1,0>:d                    {Compacted}          //  ALU pipe: int; $231
        mov (16|M16)             r39.0<1>:d    r9.0<2;1,0>:d                    {Compacted}          //  ALU pipe: int; $228
(~f0.0) sel (32|M0)              r16.0<1>:d    r3.9<0;1,0>:d     0:w                                 //  ALU pipe: int; $235
(W)     mul (16|M0)              acc0.0<1>:ud  r38.0<1;1,0>:ud   r3.18<0;1,0>:uw  {I@5}              //  ALU pipe: int; $243
(f1.0)  sel (32|M0)              r20.0<1>:d    r14.0<1;1,0>:d    0:w               {I@4}             //  ALU pipe: int; $233
        macl (16|M0)             r6.0<1>:ud    r38.0<1;1,0>:ud   r3.9<0;1,0>:ud   {Compacted}        //  ALU pipe: int; $244
(W)     mul (16|M16)             acc0.0<1>:ud  r39.0<1;1,0>:ud   r3.18<0;1,0>:uw  {I@5}              //  ALU pipe: int; $244
        add3 (32|M0)             r18.0<1>:d    r20.0<1;0>:d      r12.0<1;0>:d      -r16.0<1>:d      {Compacted,I@3} //  ALU pipe: int; $236 R{} IR{}{E:2,E:6,E:0,},  R{} IR{}{O:10,O:6,O:8,},  {BC=2}
        macl (16|M16)            r14.0<1>:ud   r39.0<1;1,0>:ud   r3.9<0;1,0>:ud                      //  ALU pipe: int; $245
(W)     mul (16|M0)              acc0.0<1>:ud  r38.0<1;1,0>:ud   r3.18<0;1,0>:uw                     //  ALU pipe: int; $245
        mach (16|M0)             r12.0<1>:d    r38.0<1;1,0>:ud   r3.9<0;1,0>:ud                      //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r39.0<1;1,0>:ud   r3.18<0;1,0>:uw                     //  ALU pipe: int; $245
        mach (16|M16)            r13.0<1>:d    r39.0<1;1,0>:ud   r3.9<0;1,0>:ud                      //  ALU pipe: int; $247
        mov (32|M0)              r22.0<1>:f    r50.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $237
        mov (32|M0)              r16.0<1>:d    0:w                               {Compacted}         //  ALU pipe: int; $248
        mov (16|M0)              r9.0<2>:ud    r6.0<1;1,0>:ud                   {Compacted,I@7}      //  ALU pipe: int; $244
        mov (16|M16)             r26.0<2>:ud   r14.0<1;1,0>:ud                  {Compacted,I@7}      //  ALU pipe: int; $245
        mov (16|M0)              r7.0<2>:d     r22.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $239
        mov (16|M16)             r24.0<2>:d    r23.0<1;1,0>:d                                        //  ALU pipe: int; $240
        add (16|M0)              r9.1<2>:d     r12.0<1;1,0>:d    r16.0<1;1,0>:d   {I@5}              //  ALU pipe: int; $249
        add (16|M16)             r26.1<2>:d    r13.0<1;1,0>:d    r17.0<1;1,0>:d                      //  ALU pipe: int; $250
        mov (16|M0)              r7.1<2>:d     r18.0<1;1,0>:d                                        //  ALU pipe: int; $241
        mov (16|M16)             r24.1<2>:d    r19.0<1;1,0>:d                                        //  ALU pipe: int; $242
        add (16|M0)              r18.0<1>:q    r7.0<1;1,0>:q     -r9.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $251
        add (16|M16)             r5.0<1>:q     r24.0<1;1,0>:q    -r26.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $251
        mov (16|M0)              r20.0<1>:d    r18.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $252
        mov (16|M16)             r21.0<1>:d    r5.0<2;1,0>:d                    {Compacted,I@2}      //  ALU pipe: int; $253
        cmp (32|M0)   (lt)f0.0   null<1>:ud    r20.0<1;1,0>:ud   r3.9<0;1,0>:ud   {I@1}              //  ALU pipe: int; $256
        mov (16|M0)              r14.0<1>:d    r18.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $254
        mov (16|M16)             r15.0<1>:d    r5.1<2;1,0>:d                    {Compacted}          //  ALU pipe: int; $255
(f0.0)  cmp (32|M0)   (eq)f0.0   null<1>:d     r14.0<1;1,0>:d    r41.0<0;1,0>:d   {I@1}              //  ALU pipe: int; $257
(~f0.0) cmp (32|M0)   (lt)f0.0   null<1>:ud    r14.0<1;1,0>:ud   r41.0<0;1,0>:ud                     //  ALU pipe: int; $259
(~f0.0) sel (32|M0)              r22.0<1>:d    r3.9<0;1,0>:d     0:w                                 //  ALU pipe: int; $261
(~f0.0) sel (32|M0)              r28.0<1>:d    r41.0<0;1,0>:d    0:w                                 //  ALU pipe: int; $262
        mov (16|M0)              r30.0<2>:d    r22.0<1;1,0>:d                   {I@2}                //  ALU pipe: int; $265
        mov (16|M16)             r11.0<2>:d    r23.0<1;1,0>:d                                        //  ALU pipe: int; $266
        mov (16|M0)              r30.1<2>:d    r28.0<1;1,0>:d                   {I@3}                //  ALU pipe: int; $267
        mov (16|M16)             r11.1<2>:d    r29.0<1;1,0>:d                                        //  ALU pipe: int; $268
        add (16|M0)              r72.0<1>:q    r18.0<1;1,0>:q    -r30.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $269
        add (16|M16)             r74.0<1>:q    r5.0<1;1,0>:q     -r11.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $269
        goto (32|M0)                         _0_037            _0_039                                // $270
// B016: [inDivergent],  Preds:{B014},  Succs:{B017, B018}
_0_037:
        join (32|M0)                         _0_039                                                  // 
L4416:
(W)     cmp (32|M0)   (eq)f3.0   null<1>:d     r3.9<0;1,0>:d     0:w                                 //  ALU pipe: int; $272
(W&~f3.0) jmpi                               _0_040                                                  //  ALU pipe: int; $273
// B017: [inDivergent],  Preds:{B016},  Succs:{B019}
_0_041:
        mov (32|M0)              r54.0<1>:d    -1:w                               {Compacted}        //  ALU pipe: int; $275
(W)     jmpi                                 _0_042                                                  // $276
// B018: [inDivergent],  Preds:{B016},  Succs:{B019}
_0_040:
        mov (16|M0)              r6.0<1>:d     r68.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $278
        mov (16|M16)             r7.0<1>:d     r70.0<2;1,0>:d                                        //  ALU pipe: int; $278
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $279
(W)     mov (1|M0)               r2.8<1>:f     r3.9<0;1,0>:ud                   {A@1}                //  ALU pipe: float; $280
(W)     mov (1|M0)               r3.11<1>:f    0xB4C00000:f                                          //  ALU pipe: float; $285
(W)     math.inv (1|M0)          r4.1<1>:f     r2.8<0;1,0>:f                    {@2,$2.dst}          //  ALU pipe: math; $284
        mov (32|M0)              r8.0<1>:f     r6.0<1;1,0>:ud                   {I@2}                //  ALU pipe: float; $283
(W)     mad (1|M0)               r5.0<1>:f     r4.1<0;0>:f       r3.11<0;0>:f      r4.1<0>:f        {A@1} //  ALU pipe: float; $285
        mov (32|M0)              r12.0<1>:ud   r8.0<1;1,0>:f                    {F@2}                //  ALU pipe: int; $287
        mul (32|M0)              r10.0<1>:f    r8.0<1;1,0>:f     r5.0<0;1,0>:f    {Compacted,F@1}    //  ALU pipe: float; $286
(W)     mov (1|M0)               r2.9<1>:ud    r2.8<0;1,0>:f                                         //  ALU pipe: int; $281
        add (32|M0)              r14.0<1>:d    r6.0<1;1,0>:d     -r12.0<1;1,0>:d  {Compacted,I@2}    //  ALU pipe: int; $288
        mov (32|M0)              r16.0<1>:ud   r10.0<1;1,0>:f                   {F@1}                //  ALU pipe: int; $289
(W)     add (1|M0)               r3.10<1>:d    r3.9<0;1,0>:d     -r2.9<0;1,0>:d   {I@3}              //  ALU pipe: int; $282
        mov (32|M0)              r22.0<1>:f    r16.0<1;1,0>:ud                  {I@2}                //  ALU pipe: float; $292
        mov (32|M0)              r20.0<1>:f    r14.0<1;1,0>:ud                                       //  ALU pipe: float; $291
(W)     mov (1|M0)               r18.0<1>:f    r3.10<0;1,0>:ud                  {I@1}                //  ALU pipe: float; $290
        mad (32|M0)              acc0.0<1>:f   r8.0<1;0>:f       r22.0<1;0>:f      -r2.8<0>:f       {F@3} //  ALU pipe: float; $294 R{} IR{}{E:4,E:3,E:1,},  R{r2,} IR{}{O:4,O:11,},  {BC=1}
        mad (32|M0)              acc2.0<1>:f   r20.0<1;0>:f      r22.0<1;0>:f      -r18.0<0>:f      {F@2} //  ALU pipe: float; $296 R{} IR{}{E:2,E:3,E:1,},  R{r18,} IR{}{O:10,O:11,},  {BC=1}
        add (32|M0)              acc0.0<1>:f   acc0.0<1;1,0>:f   acc2.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $297
        mul (32|M0)              r24.0<1>:f    r5.0<0;1,0>:f     acc0.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $298
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $299
        mov (32|M0)              r26.0<1>:ud   r24.0<1;1,0>:f                   {A@1}                //  ALU pipe: int; $300
        add (32|M0)              r28.0<1>:d    r26.0<1;1,0>:d    r16.0<1;1,0>:d   {Compacted,I@1}    //  ALU pipe: int; $301
(W)     mul (16|M0)              acc0.0<1>:d   r28.0<1;1,0>:d    r3.18<0;1,0>:uw  {I@1}              //  ALU pipe: int; $302
        macl (16|M0)             r10.0<1>:d    r28.0<1;1,0>:d    r3.9<0;1,0>:d    {Compacted}        //  ALU pipe: int; $302
(W)     mul (16|M16)             acc0.0<1>:d   r29.0<1;1,0>:d    r3.18<0;1,0>:uw                     //  ALU pipe: int; $302
        macl (16|M16)            r11.0<1>:d    r29.0<1;1,0>:d    r3.9<0;1,0>:d    {Compacted}        //  ALU pipe: int; $303
        add (32|M0)              r12.0<1>:d    r6.0<1;1,0>:d     -r10.0<1;1,0>:d  {Compacted,I@1}    //  ALU pipe: int; $303
        cmp (32|M0)   (lt)f2.0   null<1>:ud    r12.0<1;1,0>:ud   r3.9<0;1,0>:ud   {I@1}              //  ALU pipe: int; $304
(~f2.0) sel (32|M0)              r8.0<1>:d     r3.9<0;1,0>:d     0:w                                 //  ALU pipe: int; $305
        add3 (32|M0)             r54.0<1>:d    r6.0<1;0>:d       -r10.0<1;0>:d     -r8.0<1>:d       {I@1} //  ALU pipe: int; $306 R{} IR{}{E:3,E:5,E:4,},  R{} IR{}{O:3,O:5,O:4,},  {BC=2}
// B019: [inDivergent],  Preds:{B018, B017},  Succs:{B020}
_0_042:
        mov (16|M0)              r6.0<2>:ud    r54.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $308
        mov (16|M16)             r8.0<2>:ud    r55.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $308
        mov (16|M0)              r72.0<1>:q    r6.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $308
        mov (16|M16)             r74.0<1>:q    r8.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $308
// B020: Preds:{B019, B015},  Succs:{B021, B022}
_0_039:
        join (32|M0)                         L4976                                                   // 
L4976:
(W)     mul (16|M0)              acc0.0<1>:ud  r50.0<1;1,0>:ud   r3.26<0;1,0>:uw                     //  ALU pipe: int; $310
        macl (16|M0)             r56.0<1>:ud   r50.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; $310
(W)     mul (16|M16)             acc0.0<1>:ud  r51.0<1;1,0>:ud   r3.26<0;1,0>:uw                     //  ALU pipe: int; $310
        macl (16|M16)            r57.0<1>:ud   r51.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; $311
(W)     mul (16|M0)              acc0.0<1>:ud  r50.0<1;1,0>:ud   r3.26<0;1,0>:uw                     //  ALU pipe: int; $311
        mach (16|M0)             r6.0<1>:d     r50.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r51.0<1;1,0>:ud   r3.26<0;1,0>:uw                     //  ALU pipe: int; $311
        mach (16|M16)            r7.0<1>:d     r51.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; $312
(W)     mul (16|M0)              acc0.0<1>:d   r50.0<1;1,0>:ud   r41.2<0;1,0>:uw                     //  ALU pipe: int; $312
        macl (16|M0)             r8.0<1>:d     r50.0<1;1,0>:ud   r41.1<0;1,0>:d                      //  ALU pipe: int; $312
(W)     mul (16|M16)             acc0.0<1>:d   r51.0<1;1,0>:ud   r41.2<0;1,0>:uw                     //  ALU pipe: int; $312
        macl (16|M16)            r9.0<1>:d     r51.0<1;1,0>:ud   r41.1<0;1,0>:d                      //  ALU pipe: int; $313
        add (32|M0)              r6.0<1>:d     r6.0<1;1,0>:d     r8.0<1;1,0>:d    {I@1}              //  ALU pipe: int; $313
(W)     mul (16|M0)              acc0.0<1>:d   r3.13<0;1,0>:ud   r52.0<2;1,0>:uw                     //  ALU pipe: int; $314
        macl (16|M0)             r8.0<1>:d     r3.13<0;1,0>:ud   r52.0<1;1,0>:d                      //  ALU pipe: int; $314
(W)     mul (16|M16)             acc0.0<1>:d   r3.13<0;1,0>:ud   r53.0<2;1,0>:uw                     //  ALU pipe: int; $314
        macl (16|M16)            r9.0<1>:d     r3.13<0;1,0>:ud   r53.0<1;1,0>:d                      //  ALU pipe: int; $316
(W)     cmp (32|M0)   (gt)f1.0   null<1>:d     r3.6<0;1,0>:d     0:w                                 //  ALU pipe: int; $318
        mov (16|M0)              r10.0<2>:ud   r42.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $317
        mov (16|M16)             r12.0<2>:ud   r43.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $317
        add (32|M0)              r58.0<1>:d    r6.0<1;1,0>:d     r8.0<1;1,0>:d    {I@4}              //  ALU pipe: int; $316
        mov (16|M0)              r76.0<1>:q    r10.0<2;1,0>:ud                  {I@3}                //  ALU pipe: int; $317
        mov (16|M16)             r78.0<1>:q    r12.0<2;1,0>:ud                  {I@3}                //  ALU pipe: int; $317
(W&f1.0) jmpi                                _0_043                                                  //  ALU pipe: int; $319
// B021: Preds:{B020},  Succs:{B025}
_0_044:
        mov (32|M0)              r60.0<1>:ud   0x0:ud                              {Compacted}       //  ALU pipe: int; $321
(W)     jmpi                                 _0_045                                                  // $322
// B022: Preds:{B020},  Succs:{B023}
_0_043:
        mov (32|M0)              r6.0<1>:f     r56.0<1;1,0>:f                   {Compacted,I@6}      //  ALU pipe: float; $324
        mov (32|M0)              r8.0<1>:f     r58.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $325
        mov (32|M0)              r62.0<1>:d    0:w                               {Compacted}         //  ALU pipe: int; $335
        mov (16|M0)              r10.0<2>:d    r6.0<1;1,0>:d                    {F@2}                //  ALU pipe: int; $326
        mov (16|M16)             r12.0<2>:d    r7.0<1;1,0>:d                                         //  ALU pipe: int; $327
        mov (16|M0)              r10.1<2>:d    r8.0<1;1,0>:d                    {F@1}                //  ALU pipe: int; $328
        mov (16|M16)             r12.1<2>:d    r9.0<1;1,0>:d                                         //  ALU pipe: int; $329
        add (16|M0)              r80.0<1>:q    r76.0<1;1,0>:q    -r10.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $330
        add (16|M16)             r82.0<1>:q    r78.0<1;1,0>:q    -r12.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $330
(W)     shl (1|M0)               r41.3<1>:d    r3.6<0;1,0>:d     1:w                                 //  ALU pipe: int; $331
(W)     asr (1|M0)               r41.10<1>:d   r3.8<0;1,0>:d     31:w                                //  ALU pipe: int; $332
(W)     asr (1|M0)               r41.11<1>:d   r3.7<0;1,0>:d     31:w                                //  ALU pipe: int; $333
(W)     mov (1|M0)               r41.12<1>:d   0:w                                                   //  ALU pipe: int; $334
// B023: Preds:{B023, B022},  Succs:{B024, B023}
_0_046:
(W)     mul (1|M0)               acc0.0<1>:ud  r41.12<0;1,0>:ud  r3.16<0;1,0>:uw  {I@1}              //  ALU pipe: int; $337
(W)     macl (1|M0)              r5.0<1>:ud    r41.12<0;1,0>:ud  r3.8<0;1,0>:ud                      //  ALU pipe: int; $338
(W)     mul (1|M0)               acc0.0<1>:ud  r41.12<0;1,0>:ud  r3.16<0;1,0>:uw                     //  ALU pipe: int; $338
(W)     mach (1|M0)              r6.0<1>:d     r41.12<0;1,0>:ud  r3.8<0;1,0>:ud                      //  ALU pipe: int; 
(W)     mul (1|M0)               acc0.0<1>:d   r41.12<0;1,0>:ud  r41.20<0;1,0>:uw                    //  ALU pipe: int; $339
(W)     macl (1|M0)              r7.0<1>:d     r41.12<0;1,0>:ud  r41.10<0;1,0>:d                     //  ALU pipe: int; $340
(W)     add (1|M0)               r41.12<1>:d   r41.12<0;1,0>:d   1:w                                 //  ALU pipe: int; $379
(W)     add (1|M0)               r6.0<1>:d     r6.0<0;1,0>:d     r7.0<0;1,0>:d    {Compacted,I@2}    //  ALU pipe: int; $340
(W)     cmp (32|M0)   (lt)f0.0   null<1>:d     r41.12<0;1,0>:d   r41.3<0;1,0>:d   {I@2}              //  ALU pipe: int; $380
(W)     mov (1|M0)               r5.1<1>:d     r6.0<0;1,0>:d                    {Compacted,I@2}      //  ALU pipe: int; $343
        add (16|M0)              r8.0<1>:q     r5.0<0;1,0>:q     r64.0<1;1,0>:q   {Compacted,I@1}    //  ALU pipe: int; $348
        add (16|M16)             r10.0<1>:q    r5.0<0;1,0>:q     r66.0<1;1,0>:q   {Compacted}        //  ALU pipe: int; $348
        mov (16|M0)              r12.0<1>:d    r8.0<2;1,0>:d                    {Compacted,I@2}      //  ALU pipe: int; $349
        mov (16|M16)             r13.0<1>:d    r10.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $350
(W)     mul (16|M0)              acc0.0<1>:ud  r12.0<1;1,0>:ud   r3.14<0;1,0>:uw  {I@2}              //  ALU pipe: int; $353
        macl (16|M0)             r16.0<1>:ud   r12.0<1;1,0>:ud   r3.7<0;1,0>:ud   {Compacted}        //  ALU pipe: int; $354
(W)     mul (16|M16)             acc0.0<1>:ud  r13.0<1;1,0>:ud   r3.14<0;1,0>:uw  {I@3}              //  ALU pipe: int; $354
        macl (16|M16)            r20.0<1>:ud   r13.0<1;1,0>:ud   r3.7<0;1,0>:ud   {Compacted}        //  ALU pipe: int; $355
(W)     mul (16|M0)              acc0.0<1>:ud  r12.0<1;1,0>:ud   r3.14<0;1,0>:uw                     //  ALU pipe: int; $355
        mach (16|M0)             r22.0<1>:d    r12.0<1;1,0>:ud   r3.7<0;1,0>:ud                      //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r13.0<1;1,0>:ud   r3.14<0;1,0>:uw                     //  ALU pipe: int; $355
        mach (16|M16)            r23.0<1>:d    r13.0<1;1,0>:ud   r3.7<0;1,0>:ud                      //  ALU pipe: int; $356
(W)     mul (16|M0)              acc0.0<1>:d   r12.0<1;1,0>:ud   r41.22<0;1,0>:uw                    //  ALU pipe: int; $356
        mov (16|M0)              r14.0<1>:d    r8.1<2;1,0>:d                                         //  ALU pipe: int; $351
        macl (16|M0)             r8.0<1>:d     r12.0<1;1,0>:ud   r41.11<0;1,0>:d                     //  ALU pipe: int; $356
(W)     mul (16|M16)             acc0.0<1>:d   r13.0<1;1,0>:ud   r41.22<0;1,0>:uw                    //  ALU pipe: int; $356
        macl (16|M16)            r9.0<1>:d     r13.0<1;1,0>:ud   r41.11<0;1,0>:d                     //  ALU pipe: int; $357
        mov (16|M16)             r15.0<1>:d    r10.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $352
        add (32|M0)              r22.0<1>:d    r22.0<1;1,0>:d    r8.0<1;1,0>:d    {Compacted,I@2}    //  ALU pipe: int; $357
(W)     mul (16|M0)              acc0.0<1>:d   r3.7<0;1,0>:ud    r14.0<2;1,0>:uw                     //  ALU pipe: int; $358
        macl (16|M0)             r8.0<1>:d     r3.7<0;1,0>:ud    r14.0<1;1,0>:d                      //  ALU pipe: int; $358
(W)     mul (16|M16)             acc0.0<1>:d   r3.7<0;1,0>:ud    r15.0<2;1,0>:uw  {I@4}              //  ALU pipe: int; $358
        macl (16|M16)            r9.0<1>:d     r3.7<0;1,0>:ud    r15.0<1;1,0>:d                      //  ALU pipe: int; $359
        mov (16|M0)              r17.0<2>:ud   r16.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $354
        add (16|M0)              r17.1<2>:d    r22.0<1;1,0>:d    r8.0<1;1,0>:d    {I@4}              //  ALU pipe: int; $359
        mov (16|M16)             r6.0<2>:ud    r20.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $355
        add (16|M16)             r6.1<2>:d     r23.0<1;1,0>:d    r9.0<1;1,0>:d    {I@4}              //  ALU pipe: int; $360
        add (16|M0)              r10.0<1>:q    r17.0<1;1,0>:q    r72.0<1;1,0>:q   {Compacted,I@3}    //  ALU pipe: int; $361
        add (16|M16)             r19.0<1>:q    r6.0<1;1,0>:q     r74.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $361
        mov (16|M0)              r24.0<1>:d    r10.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $362
        mov (16|M16)             r25.0<1>:d    r19.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $363
(W)     mul (16|M0)              acc0.0<1>:ud  r24.0<1;1,0>:ud   r3.26<0;1,0>:uw  {I@2}              //  ALU pipe: int; $366
        macl (16|M0)             r16.0<1>:ud   r24.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; $367
(W)     mul (16|M16)             acc0.0<1>:ud  r25.0<1;1,0>:ud   r3.26<0;1,0>:uw  {I@3}              //  ALU pipe: int; $367
        macl (16|M16)            r14.0<1>:ud   r25.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; $368
(W)     mul (16|M0)              acc0.0<1>:ud  r24.0<1;1,0>:ud   r3.26<0;1,0>:uw                     //  ALU pipe: int; $368
        mach (16|M0)             r8.0<1>:d     r24.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r25.0<1;1,0>:ud   r3.26<0;1,0>:uw                     //  ALU pipe: int; $368
        mach (16|M16)            r9.0<1>:d     r25.0<1;1,0>:ud   r3.13<0;1,0>:ud                     //  ALU pipe: int; $369
(W)     mul (16|M0)              acc0.0<1>:d   r24.0<1;1,0>:ud   r41.2<0;1,0>:uw                     //  ALU pipe: int; $369
        macl (16|M0)             r6.0<1>:d     r24.0<1;1,0>:ud   r41.1<0;1,0>:d                      //  ALU pipe: int; $369
(W)     mul (16|M16)             acc0.0<1>:d   r25.0<1;1,0>:ud   r41.2<0;1,0>:uw                     //  ALU pipe: int; $369
        mov (16|M0)              r12.0<1>:d    r10.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $364
        macl (16|M16)            r7.0<1>:d     r25.0<1;1,0>:ud   r41.1<0;1,0>:d                      //  ALU pipe: int; $370 R{} IR{}{O:4,O:4,},  {BC=1}
        mov (16|M16)             r13.0<1>:d    r19.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $365
        add (32|M0)              r8.0<1>:d     r8.0<1;1,0>:d     r6.0<1;1,0>:d    {I@2}              //  ALU pipe: int; $370
(W)     mul (16|M0)              acc0.0<1>:d   r3.13<0;1,0>:ud   r12.0<2;1,0>:uw                     //  ALU pipe: int; $371
        macl (16|M0)             r6.0<1>:d     r3.13<0;1,0>:ud   r12.0<1;1,0>:d                      //  ALU pipe: int; $371
(W)     mul (16|M16)             acc0.0<1>:d   r3.13<0;1,0>:ud   r13.0<2;1,0>:uw  {I@4}              //  ALU pipe: int; $371
        macl (16|M16)            r7.0<1>:d     r3.13<0;1,0>:ud   r13.0<1;1,0>:d                      //  ALU pipe: int; $372
        mov (16|M0)              r26.0<2>:ud   r16.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $367
        mov (16|M16)             r28.0<2>:ud   r14.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $368
        add (16|M0)              r26.1<2>:d    r8.0<1;1,0>:d     r6.0<1;1,0>:d    {I@5}              //  ALU pipe: int; $372
        add (16|M16)             r28.1<2>:d    r9.0<1;1,0>:d     r7.0<1;1,0>:d    {I@4}              //  ALU pipe: int; $373
        add (16|M0)              r10.0<1>:q    r80.0<1;1,0>:q    r26.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $374
        add (16|M16)             r14.0<1>:q    r82.0<1;1,0>:q    r28.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $374
        shl (16|M0)              r16.0<1>:q    r10.0<1;1,0>:q    2:w               {Compacted,I@2}   //  ALU pipe: int; $375
        shl (16|M16)             r18.0<1>:q    r14.0<1;1,0>:q    2:w               {Compacted,I@2}   //  ALU pipe: int; $375
        add (16|M0)              r20.0<1>:q    r16.0<1;1,0>:q    r2.3<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $376
        add (16|M16)             r22.0<1>:q    r18.0<1;1,0>:q    r2.3<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $376
        load.ugm.d32.a64 (32|M0)  r24:2         [r20:4]            {I@1,$3} // ex_desc:0x0; desc:0x8200580 // $377
        add (32|M0)              r62.0<1>:d    r62.0<1;1,0>:d    r24.0<1;1,0>:d   {Compacted,$3.dst} //  ALU pipe: int; $378
(W&f0.0) jmpi                                _0_046                                                  //  ALU pipe: int; $381
// B024: Preds:{B023},  Succs:{B025}
_0_047:
        mov (32|M0)              r60.0<1>:f    r62.0<1;1,0>:d                   {I@2}                //  ALU pipe: float; $383
// B025: Preds:{B024, B021},  Succs:{}
_0_045:
        shl (16|M0)              r5.0<1>:q     r72.0<1;1,0>:q    2:w               {Compacted}       //  ALU pipe: int; $385
        shl (16|M16)             r7.0<1>:q     r74.0<1;1,0>:q    2:w               {Compacted}       //  ALU pipe: int; $385
        add (16|M0)              r13.0<1>:q    r5.0<1;1,0>:q     r3.2<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $388
        add (16|M16)             r15.0<1>:q    r7.0<1;1,0>:q     r3.2<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $388
        load.ugm.d32.a64 (32|M0)  r26:2         [r13:4]            {I@1,$4} // ex_desc:0x0; desc:0x8200580 // $389
        add (16|M0)              r17.0<1>:q    r5.0<1;1,0>:q     r3.1<0;1,0>:q    {Compacted}        //  ALU pipe: int; $386
        add (16|M16)             r19.0<1>:q    r7.0<1;1,0>:q     r3.1<0;1,0>:q                       //  ALU pipe: int; $386
        load.ugm.d32.a64 (32|M0)  r28:2         [r17:4]            {I@1,$5} // ex_desc:0x0; desc:0x8200580 // $387
(W)     mov (1|M0)               r2.8<1>:ud    0x43FF0000:ud                                         //  ALU pipe: int; $392
        shl (16|M0)              r9.0<1>:q     r76.0<1;1,0>:q    2:w               {Compacted}       //  ALU pipe: int; $395
        shl (16|M16)             r11.0<1>:q    r78.0<1;1,0>:q    2:w               {Compacted}       //  ALU pipe: int; $395
        add (16|M0)              r21.0<1>:q    r9.0<1;1,0>:q     r3.0<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $396
        add (16|M16)             r23.0<1>:q    r11.0<1;1,0>:q    r3.0<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $396
(W)     mov (16|M0)              r127.0<1>:ud  r40.0<1;1,0>:ud                  {$2.src}             //  ALU pipe: int; $398
        mov (32|M0)              r30.0<1>:f    r26.0<1;1,0>:d                   {$4.dst}             //  ALU pipe: float; $391
        mad (32|M0)              r32.0<1>:f    r60.0<1;0>:f      -r30.0<1;0>:f     r2.8<0>:f        {Compacted,F@1} //  ALU pipe: float; $393 R{} IR{}{E:6,E:7,E:1,},  R{r2,} IR{}{O:14,O:15,},  {BC=1}
        sync.nop                             null                             {Compacted,$5.dst}     // $390
        mul (32|M0)              acc0.0<1>:f   r4.0<0;1,0>:f     r28.0<1;1,0>:f   {Compacted,$2.dst} //  ALU pipe: float; $390
        mul (32|M0)              r34.0<1>:f    acc0.0<1;1,0>:f   r32.0<1;1,0>:f   {Compacted,F@2}    //  ALU pipe: float; $394
        store.ugm.d32.a64 (32|M0)  [r21:4]      r34:2              {A@1,$6} // ex_desc:0x0; desc:0x8000584 // $397
(W)     send.gtwy (1|M0)         null     r127  null:0  0x0            0x02000010           {EOT,I@1,$7} // wr:1+0, rd:0; end of thread // $398
L6736:
(W)     mov (16|M0)              null<1>:ud    0x10EC4900:ud                                         // 
(W)     mov (16|M0)              null<1>:ud    0x3A6449C0:ud                                         // 
(W)     mov (16|M0)              null<1>:ud    0x0:ud                                                // 
(W)     mov (16|M0)              null<1>:ud    0x1:ud                                                // 


//.BankConflicts: 21
//.ByteRMWs: 0
//


//.numALUInst: 486
//.accSubDef: 10
//.accSubUse: 10
//.accSubCandidateDef: 11
//.accSubCandidateUse: 11
//
//
//.singlePipeAtOneDistNum: 79
//.allAtOneDistNum: 19
//.syncInstCount: 2
//.tokenReuseCount: 0
//.AfterWriteTokenDepCount: 12
//.AfterReadTokenDepCount: 2

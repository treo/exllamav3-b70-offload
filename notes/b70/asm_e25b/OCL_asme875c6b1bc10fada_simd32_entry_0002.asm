//.kernel _ZTSZL5splitRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_
//.platform XE2
//.thread_config numGRF=128, numAcc=4, numSWSB=16
//.options_string "-emitCrossThreadOffR0Reloc -hashmovs 3900032689 3155229402 -hashmovs1 0 2 "
//.full_options "-emitLocation -wideMulMadOpsEn -enableCoalesceScalarMoves -supportLSCImmScale 0 -samplerHeaderWA -enablePreemptionR0Only -hasRNEandDenorm -noStitchExternFunc -useInlineData -emitCrossThreadOffR0Reloc -abortonspill -abortOnSpill 4 -enableBCR -enableBundleCR 3 -freqBasedSpillCost 8 -freqBasedSpillCostFunc 1 -boundsChecking -presched-ctrl 6 -presched-rp 100 -nodpsendreorder -SBIDDepLoc -PVCSendWARWA -output -binary -dumpcommonisa -dumpcombinedcisa -dumpvisa -printHexFloatInAsm -noverifyCISA -enableHalfLSC -partialInt64 -activeThreadsOnlyBarrier -hashmovs 3900032689 3155229402 -hashmovs1 0 2 -GRFBumpUpNumber 2 "
//.instCount 294
//.RA type	LOCAL_ROUND_ROBIN_BC_RA
//.git-hash f523d3ae2278a1765cdbdedb3770d11afa642fa5

//.declare BuiltInR0 (0)  rf=r size=64 type=ud align=32 words (r0.0) IsBuiltin
//.declare  (1)  rf=r size=64 type=ud align=32 words (r85.0) IsBuiltin
//.declare BuiltinA0 (2)  rf=a size=4 type=ud align=1 words (a0.0) IsBuiltin
//.declare BuiltinA0Dot2 (3)  rf=a size=4 type=ud align=1 words (a0.2) IsBuiltin
//.declare BuiltinSR0Dot1 (5)  rf=r size=4 type=ud align=2 words IsBuiltin
//.declare %null (10)  rf=r size=4 type=ud align=2 words
//.declare %local_id_x (13)  rf=r size=4 type=ud align=2 words (r3.11)
//.declare %local_id_y (14)  rf=r size=4 type=ud align=2 words (r3.12)
//.declare %local_size_x (15)  rf=r size=4 type=ud align=2 words (r3.7)
//.declare %local_size_y (16)  rf=r size=4 type=ud align=2 words (r3.8)
//.declare %group_id_x (17)  rf=r size=4 type=ud align=2 words (r0.1)
//.declare %group_id_y (18)  rf=r size=4 type=ud align=2 words (r0.6)
//.declare %group_id_z (19)  rf=r size=4 type=ud align=2 words (r0.7)
//.declare %group_count_x (20)  rf=r size=4 type=ud align=2 words (r3.9)
//.declare %group_count_y (21)  rf=r size=4 type=ud align=2 words (r3.10)
//.declare %tsc (22)  rf=r size=20 type=ud align=2 words
//.declare %arg (23)  rf=r size=0 type=ud align=32 words (r26.0)
//.declare %retval (24)  rf=r size=0 type=ud align=32 words (r26.0) Output
//.declare %sp (25)  rf=r size=8 type=uq align=4 words (r127.3)
//.declare %fp (26)  rf=r size=8 type=uq align=4 words (r127.2)
//.declare %sr0 (27)  rf=r size=16 type=ud align=2 words
//.declare %cr0 (28)  rf=r size=12 type=ud align=2 words
//.declare %ce0 (29)  rf=r size=4 type=ud align=2 words
//.declare %dbg0 (30)  rf=r size=8 type=ud align=2 words
//.declare implBufPtr (32)  rf=r size=8 type=uq align=4 words (r126.0)
//.declare localIdBufPtr (33)  rf=r size=8 type=uq align=4 words (r126.3)
//.declare %msg0 (34)  rf=r size=12 type=ud align=2 words
//.declare %scratchloc (35)  rf=r size=8 type=uq align=4 words (s0.7)
//.declare V0033 (43)  rf=r size=64 type=d alias=+0 align=32 words (r85.0)
//.declare V0034 (44)  rf=r size=4 type=d align=2 words (r3.6)
//.declare V0035 (45)  rf=r size=8 type=uq align=4 words (r2.3)
//.declare V0036 (46)  rf=r size=8 type=uq align=4 words (r3.0)
//.declare V0037 (47)  rf=r size=8 type=uq align=4 words (r3.1)
//.declare V0038 (48)  rf=r size=8 type=uq align=4 words (r3.2)
//.declare V0040 (50)  rf=r size=32 type=d alias=+0 align=32 words (r85.0)
//.declare V0041 (51)  rf=r size=12 type=d align=2 words (r2.0)
//.declare V0042 (52)  rf=r size=12 type=d align=2 words (r2.3)
//.declare V0043 (53)  rf=r size=64 type=w align=32 words (r1.0)
//.declare V0055 (65)  rf=r size=4 type=d align=32 words (r4.0)
//.declare V0057 (67)  rf=r size=64 type=uw alias=V0043+0 align=32 words (r1.0)
//.declare V0058 (68)  rf=r size=128 type=d align=32 words (r87.0)
//.declare V0059 (69)  rf=r size=4 type=d align=2 words (r86.0)
//.declare V0060 (70)  rf=r size=4 type=d align=2 words (r86.1)
//.declare V0061 (71)  rf=r size=4 type=d align=2 words (r86.2)
//.declare V0062 (72)  rf=r size=4 type=ud alias=V0060+0 align=2 words (r86.1)
//.declare V0063 (73)  rf=r size=4 type=ud alias=V0034+0 align=2 words (r3.6)
//.declare V0064 (74)  rf=r size=4 type=d align=32 words (r5.0)
//.declare V0066 (76)  rf=r size=4 type=d align=2 words (r6.0)
//.declare V0068 (78)  rf=r size=8 type=q align=4 words (r86.2)
//.declare V0069 (79)  rf=r size=8 type=d alias=V0068+0 align=4 words (r86.4)
//.declare P01 (80)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0070 (81)  rf=r size=4 type=ud alias=V0061+0 align=2 words (r86.2)
//.declare V0071 (82)  rf=r size=8 type=df align=4 words (r86.3)
//.declare V0072 (83)  rf=r size=8 type=df align=4 words (r86.4)
//.declare V0074 (85)  rf=r size=8 type=df align=4 words (r1.0)
//.declare V0075 (86)  rf=r size=8 type=uq alias=V0068+0 align=4 words (r86.2)
//.declare V0076 (87)  rf=r size=4 type=f align=4 words (r2.0)
//.declare V0077 (88)  rf=r size=4 type=f align=2 words (r3.7)
//.declare V0078 (89)  rf=r size=8 type=df align=4 words (r4.0)
//.declare V0079 (90)  rf=r size=8 type=df align=4 words (r5.0)
//.declare V0080 (91)  rf=r size=8 type=df align=4 words (r7.0)
//.declare V0081 (92)  rf=r size=8 type=df align=4 words (r8.0)
//.declare V0083 (94)  rf=r size=128 type=ud alias=V0058+0 align=32 words (r87.0)
//.declare V0089 (100)  rf=r size=128 type=d align=32 words (r25.0)
//.declare V0090 (101)  rf=r size=128 type=d align=32 words (r27.0)
//.declare V0091 (102)  rf=r size=128 type=d align=32 words (r29.0)
//.declare V0092 (103)  rf=r size=128 type=d align=32 words (r31.0)
//.declare P02 (104)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0093 (105)  rf=r size=128 type=ud alias=V0090+0 align=32 words (r27.0)
//.declare V0094 (106)  rf=r size=128 type=d align=32 words (r34.0)
//.declare V0099 (111)  rf=r size=4 type=d align=2 words (r44.0)
//.declare V0101 (113)  rf=r size=128 type=ud alias=V0089+0 align=32 words (r25.0)
//.declare V0102 (114)  rf=r size=4 type=ud alias=V0099+0 align=2 words (r44.0)
//.declare V0105 (117)  rf=r size=128 type=d align=32 words (r51.0)
//.declare V0106 (118)  rf=r size=128 type=d align=32 words (r53.0)
//.declare V0110 (122)  rf=r size=128 type=d align=32 words (r59.0)
//.declare V0111 (123)  rf=r size=128 type=d align=32 words (r61.0)
//.declare P03 (124)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0112 (125)  rf=r size=128 type=ud alias=V0110+0 align=32 words (r59.0)
//.declare P04 (126)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare P05 (127)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0113 (128)  rf=r size=128 type=ud alias=V0111+0 align=32 words (r61.0)
//.declare P06 (133)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0118 (134)  rf=r size=4 type=d align=4 words (r1.0)
//.declare V0119 (135)  rf=r size=4 type=f align=2 words (r2.0)
//.declare V0120 (136)  rf=r size=4 type=ud alias=V0118+0 align=2 words (r1.0)
//.declare V0121 (137)  rf=r size=4 type=d align=2 words (r3.7)
//.declare V0122 (138)  rf=r size=4 type=ud alias=V0121+0 align=2 words (r3.7)
//.declare V0123 (139)  rf=r size=4 type=d align=2 words (r4.0)
//.declare V0124 (140)  rf=r size=128 type=f align=32 words (r5.0)
//.declare V0125 (141)  rf=r size=4 type=f align=2 words (r8.0)
//.declare V0126 (142)  rf=r size=4 type=f align=2 words (r10.0)
//.declare V0127 (143)  rf=r size=128 type=f align=32 words (r11.0)
//.declare V0128 (144)  rf=r size=128 type=d align=32 words (r13.0)
//.declare V0129 (145)  rf=r size=128 type=ud alias=V0128+0 align=32 words (r13.0)
//.declare V0130 (146)  rf=r size=128 type=d align=32 words (r15.0)
//.declare V0131 (147)  rf=r size=128 type=d align=32 words (r17.0)
//.declare V0132 (148)  rf=r size=128 type=ud alias=V0131+0 align=32 words (r17.0)
//.declare V0133 (149)  rf=r size=4 type=f align=2 words (r20.0)
//.declare V0134 (150)  rf=r size=4 type=ud alias=V0123+0 align=2 words (r4.0)
//.declare V0135 (151)  rf=r size=128 type=f align=32 words (r21.0)
//.declare V0136 (152)  rf=r size=128 type=ud alias=V0130+0 align=32 words (r15.0)
//.declare V0137 (153)  rf=r size=128 type=f align=32 words (r25.0)
//.declare V0143 (159)  rf=r size=128 type=f align=32 words (r27.0)
//.declare V0144 (160)  rf=r size=128 type=d align=32 words (r29.0)
//.declare V0145 (161)  rf=r size=128 type=ud alias=V0144+0 align=32 words (r29.0)
//.declare V0146 (162)  rf=r size=128 type=d align=32 words (r31.0)
//.declare V0147 (163)  rf=r size=128 type=d align=32 words (r33.0)
//.declare V0148 (164)  rf=r size=128 type=d align=32 words (r35.0)
//.declare V0149 (165)  rf=r size=128 type=d align=32 words (r38.0)
//.declare V0150 (166)  rf=r size=128 type=ud alias=V0148+0 align=32 words (r35.0)
//.declare V0151 (167)  rf=r size=128 type=ud alias=V0149+0 align=32 words (r38.0)
//.declare  (168)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0152 (169)  rf=r size=128 type=d align=32 words (r89.0)
//.declare V0153 (170)  rf=r size=128 type=ud alias=V0152+0 align=32 words (r89.0)
//.declare V0154 (171)  rf=r size=128 type=d align=32 words (r4.0)
//.declare V0155 (172)  rf=r size=128 type=ud alias=V0154+0 align=32 words (r4.0)
//.declare V0156 (173)  rf=r size=128 type=d align=32 words (r92.0)
//.declare V0157 (174)  rf=r size=128 type=ud alias=V0156+0 align=32 words (r92.0)
//.declare P07 (175)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0158 (176)  rf=r size=8 type=q align=4 words (r1.0)
//.declare V0159 (177)  rf=r size=8 type=df align=4 words (r3.4)
//.declare V0160 (178)  rf=r size=8 type=uq alias=V0158+0 align=4 words (r1.0)
//.declare V0161 (179)  rf=r size=4 type=f align=4 words (r4.0)
//.declare V0162 (180)  rf=r size=4 type=f align=2 words (r5.0)
//.declare V0163 (181)  rf=r size=8 type=df align=4 words (r6.0)
//.declare V0164 (182)  rf=r size=8 type=df align=4 words (r7.0)
//.declare V0165 (183)  rf=r size=8 type=df align=4 words (r9.0)
//.declare V0166 (184)  rf=r size=8 type=df align=4 words (r10.0)
//.declare V0173 (191)  rf=r size=128 type=d align=32 words (r27.0)
//.declare V0174 (192)  rf=r size=128 type=d align=32 words (r29.0)
//.declare V0175 (193)  rf=r size=128 type=d align=32 words (r31.0)
//.declare P08 (194)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0176 (195)  rf=r size=128 type=ud alias=V0174+0 align=32 words (r29.0)
//.declare V0177 (196)  rf=r size=128 type=d align=32 words (r33.0)
//.declare V0183 (202)  rf=r size=128 type=ud alias=V0173+0 align=32 words (r27.0)
//.declare V0186 (205)  rf=r size=128 type=d align=32 words (r49.0)
//.declare V0187 (206)  rf=r size=128 type=d align=32 words (r51.0)
//.declare V0191 (210)  rf=r size=128 type=d align=32 words (r57.0)
//.declare V0192 (211)  rf=r size=128 type=d align=32 words (r59.0)
//.declare P09 (212)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0193 (213)  rf=r size=128 type=ud alias=V0191+0 align=32 words (r57.0)
//.declare P10 (214)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare P11 (215)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0194 (216)  rf=r size=128 type=ud alias=V0192+0 align=32 words (r59.0)
//.declare V0195 (217)  rf=r size=4 type=ud alias=V0059+0 align=2 words (r86.0)
//.declare P12 (224)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0202 (225)  rf=r size=4 type=f align=2 words (r2.0)
//.declare V0203 (226)  rf=r size=4 type=d align=2 words (r3.7)
//.declare V0204 (227)  rf=r size=4 type=ud alias=V0203+0 align=2 words (r3.7)
//.declare V0205 (228)  rf=r size=4 type=d align=2 words (r4.0)
//.declare V0206 (229)  rf=r size=128 type=f align=32 words (r5.0)
//.declare V0207 (230)  rf=r size=4 type=f align=2 words (r8.0)
//.declare V0208 (231)  rf=r size=4 type=f align=2 words (r10.0)
//.declare V0209 (232)  rf=r size=128 type=f align=32 words (r11.0)
//.declare V0210 (233)  rf=r size=128 type=d align=32 words (r13.0)
//.declare V0211 (234)  rf=r size=128 type=ud alias=V0210+0 align=32 words (r13.0)
//.declare V0212 (235)  rf=r size=128 type=d align=32 words (r15.0)
//.declare V0213 (236)  rf=r size=128 type=d align=32 words (r17.0)
//.declare V0214 (237)  rf=r size=128 type=ud alias=V0213+0 align=32 words (r17.0)
//.declare V0215 (238)  rf=r size=4 type=f align=2 words (r20.0)
//.declare V0216 (239)  rf=r size=4 type=ud alias=V0205+0 align=2 words (r4.0)
//.declare V0217 (240)  rf=r size=128 type=f align=32 words (r21.0)
//.declare V0218 (241)  rf=r size=128 type=ud alias=V0212+0 align=32 words (r15.0)
//.declare V0219 (242)  rf=r size=128 type=f align=32 words (r25.0)
//.declare V0225 (248)  rf=r size=128 type=f align=32 words (r27.0)
//.declare V0226 (249)  rf=r size=128 type=d align=32 words (r29.0)
//.declare V0227 (250)  rf=r size=128 type=ud alias=V0226+0 align=32 words (r29.0)
//.declare V0228 (251)  rf=r size=128 type=d align=32 words (r31.0)
//.declare V0229 (252)  rf=r size=128 type=d align=32 words (r33.0)
//.declare V0230 (253)  rf=r size=128 type=d align=32 words (r35.0)
//.declare P13 (254)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0231 (255)  rf=r size=128 type=ud alias=V0230+0 align=32 words (r35.0)
//.declare V0232 (256)  rf=r size=128 type=d align=32 words (r37.0)
//.declare V0233 (257)  rf=r size=128 type=d align=32 words (r94.0)
//.declare V0234 (258)  rf=r size=128 type=ud alias=V0233+0 align=32 words (r94.0)
//.declare V0235 (259)  rf=r size=128 type=d align=32 words (r8.0)
//.declare V0236 (260)  rf=r size=8 type=q alias=V0035+0 align=4 words (r2.3)
//.declare V0238 (262)  rf=r size=128 type=ud alias=V0235+0 align=32 words (r8.0)
//.declare V0245 (269)  rf=r size=128 type=d align=32 words (r26.0)
//.declare V0246 (270)  rf=r size=128 type=d align=32 words (r28.0)
//.declare V0248 (272)  rf=r size=128 type=ud alias=V0245+0 align=32 words (r26.0)
//.declare V0251 (275)  rf=r size=128 type=d align=32 words (r38.0)
//.declare V0252 (276)  rf=r size=128 type=d align=32 words (r36.0)
//.declare V0253 (277)  rf=r size=256 type=q align=32 words (r67.0)
//.declare V0254 (278)  rf=r size=256 type=uq alias=V0253+0 align=32 words (r67.0)
//.declare V0255 (279)  rf=r size=128 type=d align=32 words (r71.0)
//.declare V0256 (280)  rf=r size=128 type=d align=32 words (r73.0)
//.declare V0258 (282)  rf=r size=8 type=q alias=V0037+0 align=4 words (r3.1)
//.declare V0259 (283)  rf=r size=256 type=q align=32 words (r46.0)
//.declare V0260 (284)  rf=r size=256 type=uq alias=V0259+0 align=32 words (r46.0)
//.declare V0261 (285)  rf=r size=128 type=f align=32 words (r53.0)
//.declare V0262 (286)  rf=r size=8 type=q alias=V0038+0 align=4 words (r3.2)
//.declare V0263 (287)  rf=r size=256 type=q align=32 words (r22.0)
//.declare V0264 (288)  rf=r size=256 type=uq alias=V0263+0 align=32 words (r22.0)
//.declare V0265 (289)  rf=r size=128 type=d align=32 words (r50.0)
//.declare V0266 (290)  rf=r size=128 type=d align=32 words (r79.0)
//.declare V0267 (291)  rf=r size=128 type=f align=32 words (r77.0)
//.declare V0268 (292)  rf=r size=128 type=f align=32 words (r81.0)
//.declare V0269 (293)  rf=r size=128 type=f align=32 words (r75.0)
//.declare V0271 (295)  rf=r size=4 type=f align=2 words (r52.0)
//.declare V0272 (296)  rf=r size=128 type=f align=32 words (r83.0)
//.declare V0273 (297)  rf=r size=8 type=q alias=V0036+0 align=4 words (r3.0)
//.declare V0276 (300)  rf=r size=256 type=q align=32 words (r63.0)
//.declare V0277 (301)  rf=r size=256 type=uq alias=V0276+0 align=32 words (r63.0)
//.declare  (302)  rf=r size=64 type=ud align=32 words (r127.0)
//.declare  (303)  rf=r size=4 type=d alias=V0068+0 align=2 words (r86.4)
//.declare  (306)  rf=r size=2 type=w align=1 words (r63.0)
//.declare  (307)  rf=r size=64 type=ud align=32 words (r45.0)
//.declare  (308)  rf=r size=64 type=ud align=32 words (r48.0)
//.declare  (309)  rf=r size=128 type=ud align=32 words (r9.0)
//.declare  (310)  rf=r size=128 type=ud align=32 words (r13.0)
//.declare  (311)  rf=r size=128 type=ud align=32 words (r66.0)
//.declare  (312)  rf=r size=128 type=ud align=32 words (r70.0)
//.declare  (313)  rf=r size=4 type=f align=2 words (r9.0)
//.declare  (314)  rf=r size=128 type=ud align=32 words (r4.0)
//.declare  (315)  rf=r size=128 type=ud align=32 words (r6.0)
//.declare  (318)  rf=r size=64 type=ud align=32 words (r43.0)
//.declare  (319)  rf=r size=64 type=ud align=32 words (r46.0)
//.declare  (320)  rf=r size=128 type=ud align=32 words (r11.0)
//.declare  (321)  rf=r size=128 type=ud align=32 words (r15.0)
//.declare  (322)  rf=r size=4 type=f align=2 words (r9.0)
//.declare  (323)  rf=r size=128 type=ud align=32 words (r4.0)
//.declare  (324)  rf=r size=128 type=ud align=32 words (r6.0)
//.declare  (325)  rf=r size=128 type=ud align=32 words (r18.0)
//.declare  (326)  rf=r size=128 type=ud align=32 words (r20.0)
//.declare  (327)  rf=r size=128 type=ud align=32 words (r55.0)
//.declare  (328)  rf=r size=128 type=ud align=32 words (r57.0)
//.declare  (329)  rf=r size=128 type=df align=32 words (r11.0)
//.declare  (330)  rf=r size=128 type=df align=32 words (r15.0)
//.declare  (331)  rf=r size=128 type=df align=32 words (r17.0)
//.declare  (332)  rf=r size=128 type=df align=32 words (r19.0)
//.declare  (333)  rf=r size=128 type=q align=32 words (r21.0)
//.declare  (334)  rf=r size=128 type=q align=32 words (r23.0)
//.declare  (337)  rf=r size=128 type=d align=32 words (r38.0)
//.declare  (338)  rf=r size=128 type=d align=32 words (r36.0)
//.declare  (339)  rf=r size=128 type=q align=32 words (r40.0)
//.declare  (340)  rf=r size=128 type=q align=32 words (r42.0)
//.declare  (341)  rf=r size=128 type=q align=32 words (r46.0)
//.declare  (342)  rf=r size=128 type=q align=32 words (r49.0)
//.declare  (343)  rf=r size=128 type=q align=32 words (r55.0)
//.declare  (344)  rf=r size=128 type=q align=32 words (r57.0)
//.declare  (347)  rf=r size=128 type=q align=32 words (r68.0)
//.declare  (348)  rf=r size=128 type=q align=32 words (r72.0)
//.declare  (349)  rf=r size=128 type=q align=32 words (r64.0)
//.declare  (351)  rf=r size=128 type=q align=32 words (r96.0)
//.declare  (352)  rf=r size=128 type=q align=32 words (r98.0)
//.declare  (353)  rf=r size=128 type=df align=32 words (r13.0)
//.declare  (354)  rf=r size=128 type=df align=32 words (r17.0)
//.declare  (355)  rf=r size=128 type=df align=32 words (r19.0)
//.declare  (356)  rf=r size=128 type=df align=32 words (r21.0)
//.declare  (357)  rf=r size=128 type=q align=32 words (r23.0)
//.declare  (358)  rf=r size=128 type=q align=32 words (r25.0)
//.declare  (361)  rf=r size=128 type=d align=32 words (r37.0)
//.declare  (362)  rf=r size=128 type=d align=32 words (r35.0)
//.declare  (363)  rf=r size=128 type=q align=32 words (r39.0)
//.declare  (364)  rf=r size=128 type=q align=32 words (r41.0)
//.declare  (365)  rf=r size=128 type=q align=32 words (r44.0)
//.declare  (366)  rf=r size=128 type=q align=32 words (r47.0)
//.declare  (367)  rf=r size=128 type=q align=32 words (r53.0)
//.declare  (368)  rf=r size=128 type=q align=32 words (r55.0)
//.declare  (371)  rf=r size=128 type=d align=32 words (r61.0)
//.declare  (372)  rf=r size=128 type=d align=32 words (r63.0)
//.declare  (373)  rf=r size=128 type=q align=32 words (r65.0)
//.declare  (374)  rf=r size=128 type=q align=32 words (r67.0)
//.declare  (375)  rf=r size=128 type=q align=32 words (r100.0)
//.declare  (376)  rf=r size=128 type=q align=32 words (r102.0)
//.declare  (379)  rf=r size=128 type=q align=32 words (r30.0)
//.declare  (380)  rf=r size=128 type=q align=32 words (r32.0)
//.declare  (381)  rf=r size=128 type=q align=32 words (r40.0)
//.declare  (382)  rf=r size=128 type=q align=32 words (r42.0)
//.declare  (383)  rf=r size=128 type=q align=32 words (r4.0)
//.declare  (384)  rf=r size=128 type=q align=32 words (r6.0)
//.declare  (385)  rf=r size=128 type=q align=32 words (r14.0)
//.declare  (386)  rf=r size=128 type=q align=32 words (r16.0)
//.declare  (389)  rf=r size=128 type=q align=32 words (r34.0)
//.declare  (390)  rf=r size=128 type=q align=32 words (r44.0)
//.declare  (391)  rf=r size=128 type=q align=32 words (r10.0)
//.declare  (392)  rf=r size=128 type=q align=32 words (r12.0)
//.declare  (395)  rf=r size=128 type=q align=32 words (r59.0)
//.declare  (396)  rf=r size=128 type=q align=32 words (r61.0)
//.declare  (397)  rf=r size=128 type=uq alias=+0 align=32 words (r21.0)
//.declare  (398)  rf=r size=128 type=uq alias=+0 align=32 words (r23.0)
//.declare  (399)  rf=r size=128 type=d alias=+0 align=32 words (r21.0)
//.declare  (400)  rf=r size=128 type=d alias=+0 align=32 words (r23.0)
//.declare  (401)  rf=r size=128 type=d alias=+0 align=32 words (r40.0)
//.declare  (402)  rf=r size=128 type=d alias=+0 align=32 words (r42.0)
//.declare  (403)  rf=r size=128 type=ud alias=+0 align=32 words (r46.0)
//.declare  (404)  rf=r size=128 type=ud alias=+0 align=32 words (r49.0)
//.declare  (405)  rf=r size=128 type=d alias=+0 align=32 words (r46.0)
//.declare  (406)  rf=r size=128 type=d alias=+0 align=32 words (r49.0)
//.declare  (407)  rf=r size=128 type=d alias=+0 align=32 words (r55.0)
//.declare  (408)  rf=r size=128 type=d alias=+0 align=32 words (r57.0)
//.declare  (409)  rf=r size=128 type=d alias=+0 align=32 words (r64.0)
//.declare  (410)  rf=r size=128 type=ud alias=+0 align=32 words (r64.0)
//.declare  (411)  rf=r size=128 type=uq alias=+0 align=32 words (r23.0)
//.declare  (412)  rf=r size=128 type=uq alias=+0 align=32 words (r25.0)
//.declare  (413)  rf=r size=128 type=d alias=+0 align=32 words (r23.0)
//.declare  (414)  rf=r size=128 type=d alias=+0 align=32 words (r25.0)
//.declare  (415)  rf=r size=128 type=d alias=+0 align=32 words (r39.0)
//.declare  (416)  rf=r size=128 type=d alias=+0 align=32 words (r41.0)
//.declare  (417)  rf=r size=128 type=ud alias=+0 align=32 words (r44.0)
//.declare  (418)  rf=r size=128 type=ud alias=+0 align=32 words (r47.0)
//.declare  (419)  rf=r size=128 type=d alias=+0 align=32 words (r44.0)
//.declare  (420)  rf=r size=128 type=d alias=+0 align=32 words (r47.0)
//.declare  (421)  rf=r size=128 type=d alias=+0 align=32 words (r53.0)
//.declare  (422)  rf=r size=128 type=d alias=+0 align=32 words (r55.0)
//.declare  (423)  rf=r size=128 type=d alias=+0 align=32 words (r65.0)
//.declare  (424)  rf=r size=128 type=d alias=+0 align=32 words (r67.0)
//.declare  (425)  rf=r size=128 type=d alias=+0 align=32 words (r14.0)
//.declare  (426)  rf=r size=128 type=d alias=+0 align=32 words (r16.0)
//.declare  (427)  rf=r size=128 type=ud alias=+0 align=32 words (r34.0)
//.declare  (428)  rf=r size=128 type=ud alias=+0 align=32 words (r44.0)
//.declare  (429)  rf=r size=128 type=d alias=+0 align=32 words (r34.0)
//.declare  (430)  rf=r size=128 type=d alias=+0 align=32 words (r44.0)
//.declare r0 (431)  rf=r size=64 type=ud align=32 words (r0.0)
//.declare rtmp (432)  rf=r size=64 type=ud align=32 words (r127.0)
//.declare inlineRegFromTDL (433)  rf=r size=32 type=ud align=2 words (r1.0)
//.declare inlineRegExpectedLocation (434)  rf=r size=32 type=ud align=2 words (r2.0)
//.declare  (435)  rf=r size=64 type=ud align=32 words (r1.0)
//.declare  (436)  rf=r size=32 type=ud align=2 words (r3.0)

// .inputs
// +----------+----------+--------+----------+------------------+
// | id       | type     |  bytes | at       | from             |
// +----------+----------+--------+----------+------------------+
// | V0043    | :w x 32  |   0x40 | r1       | pti[tid]+0x0     |
// | V0041    | :d x 3   |    0xC | r2       | inline+0x0       |
// | V0042    | :d x 3   |    0xC | r2+0xC   | inline+0xC       |
// | V0035    | :uq      |    0x8 | r2+0x18  | inline+0x18      |
// | V0036    | :uq      |    0x8 | r3       | cti+0x20         |
// | V0037    | :uq      |    0x8 | r3+0x8   | cti+0x28         |
// | V0038    | :uq      |    0x8 | r3+0x10  | cti+0x30         |
// | V0034    | :d       |    0x4 | r3+0x18  | cti+0x38         |
// +----------+----------+--------+----------+------------------+


// B000: Preds:{},  Succs:{B001}
per_thread_prolog:
(W)     mov (16|M0)              r127.0<1>:ud  0x0:ud                                                //  ALU pipe: int; 
(W)     and (1|M0)               r127.2<1>:ud  r0.0<0;1,0>:ud    0xFFFFFFC0:ud                       //  ALU pipe: int; 
(W)     and (1|M0)               r127.0<1>:uw  r0.4<0;1,0>:uw    0xFF:uw                             //  ALU pipe: int; 
(W)     add (1|M0)               r127.2<1>:ud  r127.2<0;1,0>:ud  0x20:ud              {I@2}          //  ALU pipe: int; 
(W)     add (1|M0)               r127.2<1>:ud  r127.2<0;1,0>:ud  0x0:ud              {I@1}           //  R_SYM_ADDR_32: __INTEL_PATCH_CROSS_THREAD_OFFSET_OFF_R0; ALU pipe: int; 
(W)     mad (1|M0)               r127.0<1>:ud  r127.2<0;0>:ud    r127.0<0;0>:uw    0x40:uw              {I@1} //  ALU pipe: int; 
(W)     mov (8|M0)               r2.0<1>:ud    r1.0<1;1,0>:ud                                        //  ALU pipe: int; 
(W)     load.ugm.d32x16t.a32.ca.cc (1|M0)  r1:1 bti[255][r127:1]   {A@1,$0} // ex_desc:0xFF000000; desc:0x6219D500 // 
// B001: Preds:{B000},  Succs:{B002}
// cross_thread_prolog:
(W)     and (1|M0)               r127.0<1>:ud  r0.0<0;1,0>:ud    0xFFFFFFC0:ud              {$0.src} //  ALU pipe: int; 
(W)     add (1|M0)               r127.0<1>:ud  r127.0<0;1,0>:ud  0x0:ud              {I@1}           //  R_SYM_ADDR_32: __INTEL_PATCH_CROSS_THREAD_OFFSET_OFF_R0; ALU pipe: int; 
(W)     load.ugm.d32x8t.a32.ca.cc (1|M0)  r3:1  bti[255][r127:1]   {I@1,$1} // ex_desc:0xFF000000; desc:0x6219C500 // 
// B002: Preds:{B001},  Succs:{B003, B004}
// _main:
(W)     mov (16|M0)              r85.0<1>:ud   r0.0<1;1,0>:ud                                        //  ALU pipe: int; $1
(W)     or (1|M0)                cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x400004C0:ud              {A@1}    // $1
(W)     mul (1|M0)               acc0.0<1>:d   r2.3<0;1,0>:d     r85.2<0;1,0>:uw  {A@1}              //  ALU pipe: int; $2
(W)     asr (1|M0)               r86.0<1>:d    r3.6<0;1,0>:d     31:w               {Compacted,$1.dst} //  ALU pipe: int; $5
(W)     macl (1|M0)              r4.0<1>:d     r2.3<0;1,0>:d     r85.1<0;1,0>:d   {Compacted}        //  ALU pipe: int; $4
(W)     mul (1|M0)               acc0.0<1>:ud  r3.6<0;1,0>:ud    0x280:uw                            //  ALU pipe: int; $7
(W)     mul (1|M0)               r6.0<1>:d     r86.0<0;1,0>:d    0x280:uw              {I@3}         //  ALU pipe: int; $10
(W)     mach (1|M0)              r5.0<1>:d     r3.6<0;1,0>:ud    0x280:ud                            //  ALU pipe: int; 
        add3 (32|M0)             r87.0<1>:d    r4.0<0;0>:d       r1.0<1;0>:uw      r2.0<0>:d        {@4,$0.dst} //  ALU pipe: int; $4
(W)     add (1|M0)               r86.2<1>:d    r5.0<0;1,0>:d     r6.0<0;1,0>:d    {I@2}              //  ALU pipe: int; $12
(W)     mul (1|M0)               r86.1<1>:ud   r3.6<0;1,0>:ud    0x280:uw                            //  ALU pipe: int; $6
(W)     cmp (32|M0)   (lt)f0.0   null<1>:ud    r86.2<0;1,0>:ud   0x1:uw              {I@2}           //  ALU pipe: int; $17
(W)     mov (1|M0)               r86.3<1>:df   0xBCF0000000000000:df                                 //  ALU pipe: long; $18
(W)     mov (1|M0)               r86.4<1>:df   0x3FF0000000000000:df                                 //  ALU pipe: long; $19
(W)     mov (1|M0)               r86.5<1>:d    r86.2<0;1,0>:d                                        //  ALU pipe: int; $14
(W)     mov (1|M0)               r86.4<1>:d    r86.1<0;1,0>:d                   {I@3}                //  ALU pipe: int; $13
(W&f0.0) jmpi                                _0_013                                                  //  ALU pipe: int; $20
// B003: Preds:{B002},  Succs:{B008}
_0_014:
(W)     mov (1|M0)               r1.0<1>:df    r86.2<0;1,0>:uq                  {I@2}                //  ALU pipe: long; $23
        mov (16|M0)              r9.0<2>:ud    r87.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $30
(W)     mov (1|M0)               r2.0<2>:f     r1.0<0;1,0>:df                   {L@1}                //  ALU pipe: float; $24
        mov (16|M16)             r13.0<2>:ud   r88.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $30
(W)     math.inv (1|M0)          r3.7<1>:f     r2.0<0;1,0>:f                    {F@1}                //  ALU pipe: math; $25
(W)     mov (1|M0)               r4.0<1>:df    r3.7<0;1,0>:f                    {M@1}                //  ALU pipe: long; $26
        mov (16|M0)              r11.0<1>:df   r9.0<2;1,0>:ud                   {I@2}                //  ALU pipe: long; $30
(W)     mad (1|M0)               r5.0<1>:df    r86.4<0;0>:df     r4.0<0;0>:df      -r1.0<0>:df      {L@2} //  ALU pipe: long; $27
        mov (16|M16)             r15.0<1>:df   r13.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $30
(W)     add (1|M0)               r7.0<1>:df    r5.0<0;1,0>:df    r86.3<0;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $28
(W)     and (1|M0)               r44.0<1>:d    r86.1<0;1,0>:d    -128:w               {Compacted}    //  ALU pipe: int; $48
(W)     mad (1|M0)               r8.0<1>:df    r4.0<0;0>:df      r7.0<0;0>:df      r4.0<0>:df       {L@1} //  ALU pipe: long; $29
        mov (32|M0)              r38.0<1>:f    r87.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $42
        mul (16|M0)              r17.0<1>:df   r8.0<0;1,0>:df    r11.0<1;1,0>:df  {Compacted,L@1}    //  ALU pipe: long; $31
        mul (16|M16)             r19.0<1>:df   r8.0<0;1,0>:df    r15.0<1;1,0>:df                     //  ALU pipe: long; $31
        mov (16|M0)              r21.0<1>:uq   r17.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $32
        mov (16|M16)             r23.0<1>:uq   r19.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $32
        mov (16|M0)              r29.0<1>:d    r21.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $37
        mov (16|M0)              r27.0<1>:d    r21.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $35
        mov (16|M16)             r28.0<1>:d    r23.1<2;1,0>:d                   {Compacted,I@3}      //  ALU pipe: int; $36
        mov (16|M16)             r30.0<1>:d    r23.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $37
        mov (16|M0)              r25.0<1>:d    r21.0<2;1,0>:d                                        //  ALU pipe: int; $33
(W)     mul (16|M0)              acc0.0<1>:d   r29.0<1;1,0>:d    r86.4<0;1,0>:uw  {I@5}              //  ALU pipe: int; $38
        mov (16|M16)             r26.0<1>:d    r23.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $34
        cmp (32|M0)   (lt)f1.0   null<1>:ud    r27.0<1;1,0>:ud   0x1:uw              {I@5}           //  ALU pipe: int; $39
        macl (16|M0)             r31.0<1>:d    r29.0<1;1,0>:d    r86.2<0;1,0>:d   {Compacted}        //  ALU pipe: int; $38
(W)     mul (16|M16)             acc0.0<1>:d   r30.0<1;1,0>:d    r86.4<0;1,0>:uw  {I@6}              //  ALU pipe: int; $38
        macl (16|M16)            r32.0<1>:d    r30.0<1;1,0>:d    r86.2<0;1,0>:d   {Compacted}        //  ALU pipe: int; $39
(W)     mul (16|M0)              acc0.0<1>:ud  r25.0<1;1,0>:ud   r44.0<0;1,0>:uw  {I@7}              //  ALU pipe: int; $49
        macl (16|M0)             r45.0<1>:ud   r25.0<1;1,0>:ud   r44.0<0;1,0>:ud  {Compacted}        //  ALU pipe: int; $50
(W)     mul (16|M16)             acc0.0<1>:ud  r26.0<1;1,0>:ud   r44.0<0;1,0>:uw  {I@7}              //  ALU pipe: int; $50
        macl (16|M16)            r48.0<1>:ud   r26.0<1;1,0>:ud   r44.0<0;1,0>:ud                     //  ALU pipe: int; $51
(W)     mul (16|M0)              acc0.0<1>:ud  r25.0<1;1,0>:ud   r44.0<0;1,0>:uw                     //  ALU pipe: int; $51
(~f1.0) sel (32|M0)              r34.0<1>:d    r86.4<0;1,0>:d    0:w                                 //  ALU pipe: int; $40
        mach (16|M0)             r51.0<1>:d    r25.0<1;1,0>:ud   r44.0<0;1,0>:ud                     //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r26.0<1;1,0>:ud   r44.0<0;1,0>:uw                     //  ALU pipe: int; $51
        mach (16|M16)            r52.0<1>:d    r26.0<1;1,0>:ud   r44.0<0;1,0>:ud                     //  ALU pipe: int; $53
        add3 (32|M0)             r36.0<1>:d    0:w                -r31.0<1;0>:d     -r34.0<1>:d      {I@4} //  ALU pipe: int; $41
        mov (32|M0)              r53.0<1>:d    0:w                                                   //  ALU pipe: int; $54
        mov (16|M0)              r40.0<2>:d    r38.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $44
        mov (16|M16)             r42.0<2>:d    r39.0<1;1,0>:d                                        //  ALU pipe: int; $45
        mov (16|M0)              r46.0<2>:ud   r45.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $50
        mov (16|M16)             r49.0<2>:ud   r48.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $51
        mov (16|M0)              r40.1<2>:d    r36.0<1;1,0>:d                   {I@6}                //  ALU pipe: int; $46
        mov (16|M16)             r42.1<2>:d    r37.0<1;1,0>:d                                        //  ALU pipe: int; $47
        add (16|M0)              r46.1<2>:d    r51.0<1;1,0>:d    r53.0<1;1,0>:d   {I@7}              //  ALU pipe: int; $55
        add (16|M16)             r49.1<2>:d    r52.0<1;1,0>:d    r54.0<1;1,0>:d                      //  ALU pipe: int; $56
        add (16|M0)              r55.0<1>:q    r40.0<1;1,0>:q    -r46.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $57
        add (16|M16)             r57.0<1>:q    r42.0<1;1,0>:q    -r49.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $57
        mov (16|M0)              r59.0<1>:d    r55.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $58
        mov (16|M16)             r60.0<1>:d    r57.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $59
        cmp (32|M0)   (ge)f3.0   null<1>:ud    r59.0<1;1,0>:ud   r86.1<0;1,0>:ud  {I@1}              //  ALU pipe: int; $62
        mov (16|M0)              r61.0<1>:d    r55.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $60
        mov (16|M16)             r62.0<1>:d    r57.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $61
(f3.0)  cmp (32|M0)   (eq)f3.0   null<1>:d     r61.0<1;1,0>:d    r86.2<0;1,0>:d   {I@1}              //  ALU pipe: int; $63
(~f3.0) cmp (32|M0)   (gt)f3.0   null<1>:ud    r61.0<1;1,0>:ud   r86.2<0;1,0>:ud                     //  ALU pipe: int; $65
(W)     mov (1|M0)               r63.0<1>:hf   0xFFFF:hf                                             //  ALU pipe: float; $67
(f3.0)  sel (32|M0)              r64.0<1>:d    r63.0<0;1,0>:w    0:w               {F@1}             //  ALU pipe: int; $67
        mov (16|M0)              r66.0<2>:ud   r64.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $68
        mov (16|M16)             r70.0<2>:ud   r65.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $68
        mov (16|M0)              r68.0<1>:q    r66.0<2;1,0>:d                   {I@2}                //  ALU pipe: int; $68
        mov (16|M16)             r72.0<1>:q    r70.0<2;1,0>:d                   {I@2}                //  ALU pipe: int; $68
        add (16|M0)              r96.0<1>:q    r21.0<1;1,0>:q    -r68.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $69
        add (16|M16)             r98.0<1>:q    r23.0<1;1,0>:q    -r72.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $69
(W)     jmpi                                 _0_015                                                  // $70
// B004: Preds:{B002},  Succs:{B005, B006}
_0_013:
(W)     cmp (32|M0)   (eq)f0.0   null<1>:d     r3.6<0;1,0>:d     0:w                                 //  ALU pipe: int; $72
(W&f0.0) jmpi                                _0_016                                                  //  ALU pipe: int; $73
// B005: Preds:{B004},  Succs:{B007}
_0_017:
(W)     mov (1|M0)               r1.0<2>:d     r86.2<0;1,0>:q                                        //  ALU pipe: int; $75
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $76
(W)     mov (1|M0)               r2.0<1>:f     r1.0<0;1,0>:ud                   {A@1}                //  ALU pipe: float; $77
(W)     mov (1|M0)               r9.0<1>:f     0xB4C00000:f                               {Compacted} //  ALU pipe: float; $82
(W)     math.inv (1|M0)          r8.0<1>:f     r2.0<0;1,0>:f                    {F@2}                //  ALU pipe: math; $81
        mov (32|M0)              r5.0<1>:f     r87.0<1;1,0>:ud                                       //  ALU pipe: float; $80
(W)     mad (1|M0)               r10.0<1>:f    r8.0<0;0>:f       r9.0<0;0>:f       r8.0<0>:f        {Compacted,A@1} //  ALU pipe: float; $82
        mov (32|M0)              r13.0<1>:ud   r5.0<1;1,0>:f                    {F@2}                //  ALU pipe: int; $84
        mul (32|M0)              r11.0<1>:f    r5.0<1;1,0>:f     r10.0<0;1,0>:f   {Compacted,F@1}    //  ALU pipe: float; $83
(W)     mov (1|M0)               r3.7<1>:ud    r2.0<0;1,0>:f                                         //  ALU pipe: int; $78
        add (32|M0)              r15.0<1>:d    r87.0<1;1,0>:d    -r13.0<1;1,0>:d  {Compacted,I@2}    //  ALU pipe: int; $85
        mov (32|M0)              r17.0<1>:ud   r11.0<1;1,0>:f                   {F@1}                //  ALU pipe: int; $86
(W)     add (1|M0)               r4.0<1>:d     r1.0<0;1,0>:d     -r3.7<0;1,0>:d   {I@3}              //  ALU pipe: int; $79
        mov (32|M0)              r25.0<1>:f    r17.0<1;1,0>:ud                  {I@2}                //  ALU pipe: float; $89
        mov (32|M0)              r21.0<1>:f    r15.0<1;1,0>:ud                                       //  ALU pipe: float; $88
(W)     mov (1|M0)               r20.0<1>:f    r4.0<0;1,0>:ud                   {I@1}                //  ALU pipe: float; $87
        mad (32|M0)              acc0.0<1>:f   r5.0<1;0>:f       r25.0<1;0>:f      -r2.0<0>:f       {F@3} //  ALU pipe: float; $91
        mad (32|M0)              acc2.0<1>:f   r21.0<1;0>:f      r25.0<1;0>:f      -r20.0<0>:f      {F@2} //  ALU pipe: float; $93
        add (32|M0)              acc0.0<1>:f   acc0.0<1;1,0>:f   acc2.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $94
        mul (32|M0)              r27.0<1>:f    r10.0<0;1,0>:f    acc0.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $95
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $96
        mov (32|M0)              r29.0<1>:ud   r27.0<1;1,0>:f                   {A@1}                //  ALU pipe: int; $97
        add (32|M0)              r31.0<1>:d    r29.0<1;1,0>:d    r17.0<1;1,0>:d   {Compacted,I@1}    //  ALU pipe: int; $98
(W)     mul (16|M0)              acc0.0<1>:d   r31.0<1;1,0>:d    r1.0<0;1,0>:uw   {I@1}              //  ALU pipe: int; $99
        macl (16|M0)             r33.0<1>:d    r31.0<1;1,0>:d    r1.0<0;1,0>:d    {Compacted}        //  ALU pipe: int; $99
(W)     mul (16|M16)             acc0.0<1>:d   r32.0<1;1,0>:d    r1.0<0;1,0>:uw                      //  ALU pipe: int; $99
        macl (16|M16)            r34.0<1>:d    r32.0<1;1,0>:d    r1.0<0;1,0>:d    {Compacted}        //  ALU pipe: int; $100
        add (32|M0)              r35.0<1>:d    r87.0<1;1,0>:d    -r33.0<1;1,0>:d  {Compacted,I@1}    //  ALU pipe: int; $100
        cmp (32|M0)   (ge)f1.0   r38.0<1>:ud   r35.0<1;1,0>:ud   r1.0<0;1,0>:ud   {I@1}              //  ALU pipe: int; $101
        add3 (32|M0)             r89.0<1>:d    r29.0<1;0>:d      r17.0<1;0>:d      -r38.0<1>:d      {Compacted,I@1} //  ALU pipe: int; $102
(W)     jmpi                                 _0_018                                                  // $103
// B006: Preds:{B004},  Succs:{B007}
_0_016:
        mov (32|M0)              r89.0<1>:d    -1:w                               {Compacted}        //  ALU pipe: int; $105
// B007: Preds:{B006, B005},  Succs:{B008}
_0_018:
        mov (16|M0)              r4.0<2>:ud    r89.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $107
        mov (16|M16)             r6.0<2>:ud    r90.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $107
        mov (16|M0)              r96.0<1>:q    r4.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $107
        mov (16|M16)             r98.0<1>:q    r6.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $107
// B008: Preds:{B007, B003},  Succs:{B009, B010}
_0_015:
(W)     mul (16|M0)              acc0.0<1>:ud  r87.0<1;1,0>:ud   0xCCCD:uw                           //  ALU pipe: int; $109
        mach (16|M0)             r4.0<1>:ud    r87.0<1;1,0>:ud   0xCCCCCCCD:ud                       //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r88.0<1;1,0>:ud   0xCCCD:uw                           //  ALU pipe: int; $109
        mach (16|M16)            r5.0<1>:ud    r88.0<1;1,0>:ud   0xCCCCCCCD:ud                       //  ALU pipe: int; $110
(W)     cmp (32|M0)   (gt)f3.0   null<1>:d     r3.6<0;1,0>:d     -1:w                                //  ALU pipe: int; $111
        shr (32|M0)              r92.0<1>:ud   r4.0<1;1,0>:ud    9:w               {I@2}             //  ALU pipe: int; $110
(W&f3.0) jmpi                                _0_019                                                  //  ALU pipe: int; $112
// B009: Preds:{B008},  Succs:{B014}
_0_020:
(W)     mov (1|M0)               r1.0<1>:q     r3.6<0;1,0>:d                                         //  ALU pipe: int; $114
        mov (16|M0)              r11.0<2>:ud   r92.0<1;1,0>:ud                  {Compacted,I@3}      //  ALU pipe: int; $122
(W)     mov (1|M0)               r3.4<1>:df    r1.0<0;1,0>:uq                   {I@2}                //  ALU pipe: long; $115
        mov (16|M16)             r15.0<2>:ud   r93.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $122
(W)     mov (1|M0)               r4.0<2>:f     r3.4<0;1,0>:df                   {L@1}                //  ALU pipe: float; $116
        mov (16|M0)              r13.0<1>:df   r11.0<2;1,0>:ud                  {I@2}                //  ALU pipe: long; $122
(W)     math.inv (1|M0)          r5.0<1>:f     r4.0<0;1,0>:f                    {F@1}                //  ALU pipe: math; $117
(W)     mov (1|M0)               r6.0<1>:df    r5.0<0;1,0>:f                    {M@1}                //  ALU pipe: long; $118
        mov (16|M16)             r17.0<1>:df   r15.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $122
(W)     mad (1|M0)               r7.0<1>:df    r86.4<0;0>:df     r6.0<0;0>:df      -r3.4<0>:df      {L@2} //  ALU pipe: long; $119 R{} IR{}{E:3,E:3,O:1,},  {BC=1}
        mov (32|M0)              r37.0<1>:f    r92.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $133
(W)     add (1|M0)               r9.0<1>:df    r7.0<0;1,0>:df    r86.3<0;1,0>:df  {Compacted,L@1}    //  ALU pipe: long; $120
        mov (32|M0)              r51.0<1>:d    0:w                                                   //  ALU pipe: int; $144
(W)     mad (1|M0)               r10.0<1>:df   r6.0<0;0>:df      r9.0<0;0>:df      r6.0<0>:df       {L@1} //  ALU pipe: long; $121
        mov (16|M0)              r39.0<2>:d    r37.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $135
        mul (16|M0)              r19.0<1>:df   r10.0<0;1,0>:df   r13.0<1;1,0>:df  {Compacted,L@1}    //  ALU pipe: long; $123
        mul (16|M16)             r21.0<1>:df   r10.0<0;1,0>:df   r17.0<1;1,0>:df  {Compacted}        //  ALU pipe: long; $123
        mov (16|M0)              r23.0<1>:uq   r19.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $124
        mov (16|M16)             r25.0<1>:uq   r21.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $124
        mov (16|M0)              r29.0<1>:d    r23.1<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $127
        mov (16|M16)             r30.0<1>:d    r25.1<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $128
        mov (16|M0)              r27.0<1>:d    r23.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $125
        mov (16|M16)             r28.0<1>:d    r25.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $126
        cmp (32|M0)   (lt)f2.0   null<1>:ud    r29.0<1;1,0>:ud   0x1:uw              {I@3}           //  ALU pipe: int; $130
(W)     mul (16|M0)              acc0.0<1>:ud  r27.0<1;1,0>:ud   r3.12<0;1,0>:uw  {I@3}              //  ALU pipe: int; $139
        macl (16|M0)             r43.0<1>:ud   r27.0<1;1,0>:ud   r3.6<0;1,0>:ud   {Compacted}        //  ALU pipe: int; $140
(W)     mul (16|M16)             acc0.0<1>:ud  r28.0<1;1,0>:ud   r3.12<0;1,0>:uw  {I@4}              //  ALU pipe: int; $140
        macl (16|M16)            r46.0<1>:ud   r28.0<1;1,0>:ud   r3.6<0;1,0>:ud   {Compacted}        //  ALU pipe: int; $141
(W)     mul (16|M0)              acc0.0<1>:ud  r27.0<1;1,0>:ud   r3.12<0;1,0>:uw                     //  ALU pipe: int; $141
        mov (16|M0)              r31.0<1>:d    r23.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $129
        mov (16|M16)             r32.0<1>:d    r25.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $129
(~f2.0) sel (32|M0)              r33.0<1>:d    r3.6<0;1,0>:d     0:w                                 //  ALU pipe: int; $131
        mach (16|M0)             r49.0<1>:d    r27.0<1;1,0>:ud   r3.6<0;1,0>:ud                      //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r28.0<1;1,0>:ud   r3.12<0;1,0>:uw                     //  ALU pipe: int; $141
        mach (16|M16)            r50.0<1>:d    r28.0<1;1,0>:ud   r3.6<0;1,0>:ud                      //  ALU pipe: int; $143
        add (32|M0)              r35.0<1>:d    r31.0<1;1,0>:d    -r33.0<1;1,0>:d  {Compacted,I@4}    //  ALU pipe: int; $132
        mov (16|M16)             r41.0<2>:d    r38.0<1;1,0>:d                                        //  ALU pipe: int; $136
        mov (16|M0)              r44.0<2>:ud   r43.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $140
        mov (16|M16)             r47.0<2>:ud   r46.0<1;1,0>:ud                                       //  ALU pipe: int; $141
        mov (16|M0)              r39.1<2>:d    r35.0<1;1,0>:d                   {I@4}                //  ALU pipe: int; $137
        mov (16|M16)             r41.1<2>:d    r36.0<1;1,0>:d                                        //  ALU pipe: int; $138
        add (16|M0)              r44.1<2>:d    r49.0<1;1,0>:d    r51.0<1;1,0>:d                      //  ALU pipe: int; $145
        add (16|M16)             r47.1<2>:d    r50.0<1;1,0>:d    r52.0<1;1,0>:d                      //  ALU pipe: int; $146
        add (16|M0)              r53.0<1>:q    r39.0<1;1,0>:q    -r44.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $147
        add (16|M16)             r55.0<1>:q    r41.0<1;1,0>:q    -r47.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $147
        mov (16|M0)              r57.0<1>:d    r53.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $148
        mov (16|M16)             r58.0<1>:d    r55.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $149
        cmp (32|M0)   (lt)f2.0   null<1>:ud    r57.0<1;1,0>:ud   r3.6<0;1,0>:ud   {I@1}              //  ALU pipe: int; $152
        mov (16|M0)              r59.0<1>:d    r53.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $150
        mov (16|M16)             r60.0<1>:d    r55.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $151
(f2.0)  cmp (32|M0)   (eq)f2.0   null<1>:d     r59.0<1;1,0>:d    r86.0<0;1,0>:d   {I@1}              //  ALU pipe: int; $153
(~f2.0) cmp (32|M0)   (lt)f2.0   null<1>:ud    r59.0<1;1,0>:ud   r86.0<0;1,0>:ud                     //  ALU pipe: int; $155
(~f2.0) sel (32|M0)              r61.0<1>:d    r3.6<0;1,0>:d     0:w                                 //  ALU pipe: int; $157
(~f2.0) sel (32|M0)              r63.0<1>:d    r86.0<0;1,0>:d    0:w                                 //  ALU pipe: int; $158
        mov (16|M0)              r65.0<2>:d    r61.0<1;1,0>:d                   {I@2}                //  ALU pipe: int; $161
        mov (16|M16)             r67.0<2>:d    r62.0<1;1,0>:d                                        //  ALU pipe: int; $162
        mov (16|M0)              r65.1<2>:d    r63.0<1;1,0>:d                   {I@3}                //  ALU pipe: int; $163
        mov (16|M16)             r67.1<2>:d    r64.0<1;1,0>:d                                        //  ALU pipe: int; $164
        add (16|M0)              r100.0<1>:q   r53.0<1;1,0>:q    -r65.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $165
        add (16|M16)             r102.0<1>:q   r55.0<1;1,0>:q    -r67.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $165
(W)     jmpi                                 _0_021                                                  // $166
// B010: Preds:{B008},  Succs:{B011, B012}
_0_019:
(W)     cmp (32|M0)   (eq)f1.0   null<1>:d     r3.6<0;1,0>:d     0:w                                 //  ALU pipe: int; $168
(W&f1.0) jmpi                                _0_022                                                  //  ALU pipe: int; $169
// B011: Preds:{B010},  Succs:{B013}
_0_023:
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $171
(W)     mov (1|M0)               r2.0<1>:f     r3.6<0;1,0>:ud                   {A@1}                //  ALU pipe: float; $172
(W)     mov (1|M0)               r9.0<1>:f     0xB4C00000:f                                          //  ALU pipe: float; $177
(W)     math.inv (1|M0)          r8.0<1>:f     r2.0<0;1,0>:f                    {F@2}                //  ALU pipe: math; $176
        mov (32|M0)              r5.0<1>:f     r92.0<1;1,0>:ud                                       //  ALU pipe: float; $175
(W)     mad (1|M0)               r10.0<1>:f    r8.0<0;0>:f       r9.0<0;0>:f       r8.0<0>:f        {Compacted,A@1} //  ALU pipe: float; $177
        mov (32|M0)              r13.0<1>:ud   r5.0<1;1,0>:f                    {F@2}                //  ALU pipe: int; $179
        mul (32|M0)              r11.0<1>:f    r5.0<1;1,0>:f     r10.0<0;1,0>:f   {Compacted,F@1}    //  ALU pipe: float; $178
(W)     mov (1|M0)               r3.7<1>:ud    r2.0<0;1,0>:f                                         //  ALU pipe: int; $173
        add (32|M0)              r15.0<1>:d    r92.0<1;1,0>:d    -r13.0<1;1,0>:d  {I@2}              //  ALU pipe: int; $180
        mov (32|M0)              r17.0<1>:ud   r11.0<1;1,0>:f                   {F@1}                //  ALU pipe: int; $181
(W)     add (1|M0)               r4.0<1>:d     r3.6<0;1,0>:d     -r3.7<0;1,0>:d   {I@3}              //  ALU pipe: int; $174
        mov (32|M0)              r25.0<1>:f    r17.0<1;1,0>:ud                  {I@2}                //  ALU pipe: float; $184
        mov (32|M0)              r21.0<1>:f    r15.0<1;1,0>:ud                                       //  ALU pipe: float; $183
(W)     mov (1|M0)               r20.0<1>:f    r4.0<0;1,0>:ud                   {I@1}                //  ALU pipe: float; $182
        mad (32|M0)              acc0.0<1>:f   r5.0<1;0>:f       r25.0<1;0>:f      -r2.0<0>:f       {F@3} //  ALU pipe: float; $186
        mad (32|M0)              acc2.0<1>:f   r21.0<1;0>:f      r25.0<1;0>:f      -r20.0<0>:f      {F@2} //  ALU pipe: float; $188
        add (32|M0)              acc0.0<1>:f   acc0.0<1;1,0>:f   acc2.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $189
        mul (32|M0)              r27.0<1>:f    r10.0<0;1,0>:f    acc0.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $190
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $191
        mov (32|M0)              r29.0<1>:ud   r27.0<1;1,0>:f                   {A@1}                //  ALU pipe: int; $192
        add (32|M0)              r31.0<1>:d    r29.0<1;1,0>:d    r17.0<1;1,0>:d   {I@1}              //  ALU pipe: int; $193
(W)     mul (16|M0)              acc0.0<1>:d   r31.0<1;1,0>:d    r3.12<0;1,0>:uw  {I@1}              //  ALU pipe: int; $194
        macl (16|M0)             r33.0<1>:d    r31.0<1;1,0>:d    r3.6<0;1,0>:d    {Compacted}        //  ALU pipe: int; $194
(W)     mul (16|M16)             acc0.0<1>:d   r32.0<1;1,0>:d    r3.12<0;1,0>:uw                     //  ALU pipe: int; $194
        macl (16|M16)            r34.0<1>:d    r32.0<1;1,0>:d    r3.6<0;1,0>:d    {Compacted}        //  ALU pipe: int; $195
        add (32|M0)              r35.0<1>:d    r92.0<1;1,0>:d    -r33.0<1;1,0>:d  {I@1}              //  ALU pipe: int; $195
        cmp (32|M0)   (lt)f0.0   null<1>:ud    r35.0<1;1,0>:ud   r3.6<0;1,0>:ud   {I@1}              //  ALU pipe: int; $196 R{} IR{}{O:1,O:1,},  R{r3,} IR{} {BC=1}
(~f0.0) sel (32|M0)              r37.0<1>:d    r3.6<0;1,0>:d     0:w                                 //  ALU pipe: int; $197
        add3 (32|M0)             r94.0<1>:d    r92.0<1;0>:d      -r33.0<1;0>:d     -r37.0<1>:d      {I@1} //  ALU pipe: int; $198
(W)     jmpi                                 _0_024                                                  // $199
// B012: Preds:{B010},  Succs:{B013}
_0_022:
        mov (32|M0)              r94.0<1>:d    -1:w                               {Compacted}        //  ALU pipe: int; $201
// B013: Preds:{B012, B011},  Succs:{B014}
_0_024:
        mov (16|M0)              r4.0<2>:ud    r94.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $203
        mov (16|M16)             r6.0<2>:ud    r95.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $203
        mov (16|M0)              r100.0<1>:q   r4.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $203
        mov (16|M16)             r102.0<1>:q   r6.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $203
// B014: Preds:{B013, B009},  Succs:{}
_0_021:
        shl (16|M0)              r4.0<1>:q     r96.0<1;1,0>:q    4:w               {Compacted}       //  ALU pipe: int; $209
        shl (16|M16)             r6.0<1>:q     r98.0<1;1,0>:q    4:w               {Compacted}       //  ALU pipe: int; $209
        add (16|M0)              r14.0<1>:q    r4.0<1;1,0>:q     r100.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $210 R{} IR{}{E:2,E:2,},  R{} IR{}{O:2,O:2,},  {BC=2}
        add (16|M16)             r16.0<1>:q    r6.0<1;1,0>:q     r102.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $210 R{} IR{}{E:3,E:3,},  R{} IR{}{O:3,O:3,},  {BC=2}
        mov (16|M0)              r26.0<1>:d    r14.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $211
        mov (16|M16)             r27.0<1>:d    r16.0<2;1,0>:d                   {I@2}                //  ALU pipe: int; $212
        mad (32|M0)              r8.0<1>:d     r87.0<1;0>:d      r92.0<1;0>:d      -640:w               //  ALU pipe: int; $205
(W)     mul (16|M0)              acc0.0<1>:ud  r26.0<1;1,0>:ud   0xA00:uw              {I@3}         //  ALU pipe: int; $217
        mov (16|M0)              r28.0<1>:d    r14.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $213
        mov (16|M16)             r29.0<1>:d    r16.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $214
        mach (16|M0)             r38.0<1>:d    r26.0<1;1,0>:ud   0xA00:ud                            //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r27.0<1;1,0>:ud   0xA00:uw              {I@6}         //  ALU pipe: int; $217
        mov (16|M0)              r18.0<2>:ud   r8.0<1;1,0>:ud                   {Compacted,I@6}      //  ALU pipe: int; $207
        mov (16|M16)             r20.0<2>:ud   r9.0<1;1,0>:ud                   {Compacted}          //  ALU pipe: int; $207
        mach (16|M16)            r39.0<1>:d    r27.0<1;1,0>:ud   0xA00:ud                            //  ALU pipe: int; $219
        mul (32|M0)              r36.0<1>:d    r28.0<1;1,0>:d    0xA00:uw              {I@6}         //  ALU pipe: int; $220
        shl (16|M0)              r30.0<1>:q    r18.0<2;1,0>:ud   2:w               {I@4}             //  ALU pipe: int; $207
        shl (16|M16)             r32.0<1>:q    r20.0<2;1,0>:ud   2:w               {I@4}             //  ALU pipe: int; $207
        mul (16|M0)              r34.0<2>:ud   r26.0<1;1,0>:ud   0xA00:uw                            //  ALU pipe: int; $215
        mul (16|M16)             r44.0<2>:ud   r27.0<1;1,0>:ud   0xA00:uw                            //  ALU pipe: int; $216
        add (16|M0)              r40.0<1>:q    r30.0<1;1,0>:q    r2.3<0;1,0>:q    {Compacted,I@4}    //  ALU pipe: int; $208
        add (16|M16)             r42.0<1>:q    r32.0<1;1,0>:q    r2.3<0;1,0>:q    {Compacted,I@4}    //  ALU pipe: int; $208
        add (16|M0)              r34.1<2>:d    r38.0<1;1,0>:d    r36.0<1;1,0>:d                      //  ALU pipe: int; $221
        add (16|M16)             r44.1<2>:d    r39.0<1;1,0>:d    r37.0<1;1,0>:d                      //  ALU pipe: int; $222
        add (16|M0)              r67.0<1>:q    r40.0<1;1,0>:q    r34.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $223
        add (16|M16)             r69.0<1>:q    r42.0<1;1,0>:q    r44.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $223
        shl (16|M0)              r10.0<1>:q    r100.0<1;1,0>:q   2:w               {Compacted}       //  ALU pipe: int; $226
        shl (16|M16)             r12.0<1>:q    r102.0<1;1,0>:q   2:w               {Compacted}       //  ALU pipe: int; $226
        load.ugm.d32.a64 (32|M0)  r71:2         [r67:4]            {I@3,$2} // ex_desc:0x0; desc:0x8200580 // $224
        load.ugm.d32.a64 (32|M0)  r73:2         [r67:4+0x64000]    {$3} // ex_desc:0x64000000; desc:0x8200580 // $225
        add (16|M0)              r22.0<1>:q    r10.0<1;1,0>:q    r3.2<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $229
        add (16|M16)             r24.0<1>:q    r12.0<1;1,0>:q    r3.2<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $229
        add (16|M0)              r46.0<1>:q    r10.0<1;1,0>:q    r3.1<0;1,0>:q    {Compacted}        //  ALU pipe: int; $227
        add (16|M16)             r48.0<1>:q    r12.0<1;1,0>:q    r3.1<0;1,0>:q    {Compacted}        //  ALU pipe: int; $227
        load.ugm.d32.a64 (32|M0)  r50:2         [r22:4]            {I@3,$4} // ex_desc:0x0; desc:0x8200580 // $230
        load.ugm.d32.a64 (32|M0)  r53:2         [r46:4]            {I@1,$5} // ex_desc:0x0; desc:0x8200580 // $228
(W)     mov (1|M0)               r52.0<1>:ud   0x43FF0000:ud                                         //  ALU pipe: int; $235
        mov (16|M0)              r55.0<2>:ud   r87.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $239
        mov (16|M16)             r57.0<2>:ud   r88.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $239
        shl (16|M0)              r59.0<1>:q    r55.0<2;1,0>:ud   2:w               {I@2}             //  ALU pipe: int; $239
        shl (16|M16)             r61.0<1>:q    r57.0<2;1,0>:ud   2:w               {I@2}             //  ALU pipe: int; $239
        add (16|M0)              r63.0<1>:q    r59.0<1;1,0>:q    r3.0<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $240
        add (16|M16)             r65.0<1>:q    r61.0<1;1,0>:q    r3.0<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $240
(W)     mov (16|M0)              r127.0<1>:ud  r85.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $242
        sync.nop                             null                             {Compacted,$3.dst}     // $231
        add (32|M0)              r79.0<1>:d    r71.0<1;1,0>:d    r73.0<1;1,0>:d   {Compacted,$2.dst} //  ALU pipe: int; $231
        mov (32|M0)              r81.0<1>:f    r79.0<1;1,0>:d                   {I@1}                //  ALU pipe: float; $233
        mov (32|M0)              r75.0<1>:f    r50.0<1;1,0>:d                   {$4.dst}             //  ALU pipe: float; $234
        mul (32|M0)              r77.0<1>:f    r53.0<1;1,0>:f    0x3BDB8BAC:f               {$5.dst} //  ALU pipe: float; $232
        mad (32|M0)              acc2.0<1>:f   r81.0<1;0>:f      -r75.0<1;0>:f     r52.0<0>:f       {Compacted,F@2} //  ALU pipe: float; $236
        mul (32|M0)              r83.0<1>:f    r77.0<1;1,0>:f    acc2.0<1;1,0>:f  {F@2}              //  ALU pipe: float; $237
        store.ugm.d32.a64 (32|M0)  [r63:4]      r83:2              {F@1,$6} // ex_desc:0x0; desc:0x8000584 // $241
(W)     send.gtwy (1|M0)         null     r127  null:0  0x0            0x02000010           {EOT,$7} // wr:1+0, rd:0; end of thread // $242
L3824:
(W)     mov (16|M0)              null<1>:ud    0xE875C6B1:ud                                         // 
(W)     mov (16|M0)              null<1>:ud    0xBC10FADA:ud                                         // 
(W)     mov (16|M0)              null<1>:ud    0x0:ud                                                // 
(W)     mov (16|M0)              null<1>:ud    0x2:ud                                                // 


//.BankConflicts: 6
//.ByteRMWs: 0
//


//.numALUInst: 278
//.accSubDef: 7
//.accSubUse: 7
//.accSubCandidateDef: 8
//.accSubCandidateUse: 8
//
//
//.singlePipeAtOneDistNum: 48
//.allAtOneDistNum: 13
//.syncInstCount: 1
//.tokenReuseCount: 0
//.AfterWriteTokenDepCount: 6
//.AfterReadTokenDepCount: 1

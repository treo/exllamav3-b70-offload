//.kernel _ZTSZL4pairRN4sycl3_V15queueEPKiS4_PKfS4_PfS7_iEUlNS0_2idILi1EEEE_
//.platform XE2
//.thread_config numGRF=128, numAcc=4, numSWSB=16
//.options_string "-emitCrossThreadOffR0Reloc -hashmovs 3900032689 3155229402 -hashmovs1 0 4 "
//.full_options "-emitLocation -wideMulMadOpsEn -enableCoalesceScalarMoves -supportLSCImmScale 0 -samplerHeaderWA -enablePreemptionR0Only -hasRNEandDenorm -noStitchExternFunc -useInlineData -emitCrossThreadOffR0Reloc -abortonspill -abortOnSpill 4 -enableBCR -enableBundleCR 3 -freqBasedSpillCost 8 -freqBasedSpillCostFunc 1 -boundsChecking -presched-ctrl 6 -presched-rp 100 -nodpsendreorder -SBIDDepLoc -PVCSendWARWA -output -binary -dumpcommonisa -dumpcombinedcisa -dumpvisa -printHexFloatInAsm -noverifyCISA -enableHalfLSC -partialInt64 -activeThreadsOnlyBarrier -hashmovs 3900032689 3155229402 -hashmovs1 0 4 -GRFBumpUpNumber 2 "
//.instCount 516
//.RA type	LOCAL_ROUND_ROBIN_BC_RA
//.git-hash f523d3ae2278a1765cdbdedb3770d11afa642fa5

//.declare BuiltInR0 (0)  rf=r size=64 type=ud align=32 words (r0.0) IsBuiltin
//.declare  (1)  rf=r size=64 type=ud align=32 words (r86.0) IsBuiltin
//.declare BuiltinA0 (2)  rf=a size=4 type=ud align=1 words (a0.0) IsBuiltin
//.declare BuiltinA0Dot2 (3)  rf=a size=4 type=ud align=1 words (a0.2) IsBuiltin
//.declare BuiltinSR0Dot1 (5)  rf=r size=4 type=ud align=2 words IsBuiltin
//.declare %null (10)  rf=r size=4 type=ud align=2 words
//.declare %local_id_x (13)  rf=r size=4 type=ud align=2 words (r4.1)
//.declare %local_id_y (14)  rf=r size=4 type=ud align=2 words (r4.2)
//.declare %local_size_x (15)  rf=r size=4 type=ud align=2 words (r3.13)
//.declare %local_size_y (16)  rf=r size=4 type=ud align=2 words (r3.14)
//.declare %group_id_x (17)  rf=r size=4 type=ud align=2 words (r0.1)
//.declare %group_id_y (18)  rf=r size=4 type=ud align=2 words (r0.6)
//.declare %group_id_z (19)  rf=r size=4 type=ud align=2 words (r0.7)
//.declare %group_count_x (20)  rf=r size=4 type=ud align=2 words (r3.15)
//.declare %group_count_y (21)  rf=r size=4 type=ud align=2 words (r4.0)
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
//.declare V0033 (43)  rf=r size=64 type=d alias=+0 align=32 words (r86.0)
//.declare V0034 (44)  rf=r size=8 type=q align=4 words (r3.5)
//.declare V0035 (45)  rf=r size=8 type=uq align=4 words (r2.3)
//.declare V0036 (46)  rf=r size=8 type=uq align=4 words (r3.0)
//.declare V0037 (47)  rf=r size=8 type=uq align=4 words (r3.1)
//.declare V0038 (48)  rf=r size=8 type=uq align=4 words (r3.2)
//.declare V0039 (49)  rf=r size=4 type=d align=2 words (r3.12)
//.declare V0040 (50)  rf=r size=8 type=uq align=4 words (r3.3)
//.declare V0041 (51)  rf=r size=8 type=uq align=4 words (r3.4)
//.declare V0043 (53)  rf=r size=32 type=d alias=+0 align=32 words (r86.0)
//.declare V0044 (54)  rf=r size=12 type=d align=2 words (r2.0)
//.declare V0045 (55)  rf=r size=12 type=d align=2 words (r2.3)
//.declare V0046 (56)  rf=r size=64 type=w align=32 words (r1.0)
//.declare V0062 (72)  rf=r size=8 type=d align=2 words (r2.8)
//.declare V0063 (73)  rf=r size=8 type=d alias=V0034+0 align=4 words (r3.10)
//.declare V0064 (74)  rf=r size=4 type=d align=32 words (r4.0)
//.declare V0066 (76)  rf=r size=64 type=uw alias=V0046+0 align=32 words (r1.0)
//.declare V0067 (77)  rf=r size=128 type=d align=32 words (r5.0)
//.declare P01 (78)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0068 (79)  rf=r size=8 type=ud alias=V0062+0 align=2 words (r2.8)
//.declare V0069 (80)  rf=r size=128 type=ud alias=V0067+0 align=32 words (r5.0)
//.declare P02 (81)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare P03 (82)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0072 (85)  rf=r size=8 type=d alias=V0035+0 align=4 words (r2.6)
//.declare V0075 (88)  rf=r size=8 type=d alias=V0036+0 align=4 words (r3.0)
//.declare V0090 (103)  rf=r size=128 type=d align=32 words (r87.0)
//.declare V0091 (104)  rf=r size=128 type=d align=32 words (r89.0)
//.declare V0092 (105)  rf=r size=4 type=d align=2 words (r91.0)
//.declare V0093 (106)  rf=r size=4 type=d align=2 words (r91.1)
//.declare V0094 (107)  rf=r size=4 type=d align=2 words (r91.2)
//.declare V0095 (108)  rf=r size=4 type=ud alias=V0093+0 align=2 words (r91.1)
//.declare V0096 (109)  rf=r size=4 type=ud alias=V0039+0 align=2 words (r3.12)
//.declare V0097 (110)  rf=r size=4 type=d align=32 words (r23.0)
//.declare V0099 (112)  rf=r size=4 type=d align=2 words (r24.0)
//.declare V0101 (114)  rf=r size=8 type=q align=4 words (r91.2)
//.declare V0102 (115)  rf=r size=8 type=d alias=V0101+0 align=4 words (r91.4)
//.declare V0103 (116)  rf=r size=128 type=d align=32 words (r25.0)
//.declare P04 (117)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0104 (118)  rf=r size=128 type=ud alias=V0103+0 align=32 words (r25.0)
//.declare V0105 (119)  rf=r size=8 type=df align=4 words (r91.3)
//.declare V0106 (120)  rf=r size=8 type=df align=4 words (r91.4)
//.declare V0107 (121)  rf=r size=8 type=df align=4 words (r91.5)
//.declare V0109 (123)  rf=r size=8 type=df align=4 words (r1.0)
//.declare V0110 (124)  rf=r size=8 type=uq alias=V0101+0 align=4 words (r91.2)
//.declare V0111 (125)  rf=r size=4 type=f align=4 words (r2.0)
//.declare V0112 (126)  rf=r size=4 type=f align=2 words (r3.0)
//.declare V0113 (127)  rf=r size=8 type=df align=4 words (r4.0)
//.declare V0114 (128)  rf=r size=8 type=df align=4 words (r5.0)
//.declare V0115 (129)  rf=r size=8 type=df align=4 words (r7.0)
//.declare V0116 (130)  rf=r size=8 type=df align=4 words (r8.0)
//.declare V0118 (132)  rf=r size=128 type=d align=32 words (r9.0)
//.declare V0120 (134)  rf=r size=128 type=ud alias=V0118+0 align=32 words (r9.0)
//.declare V0122 (136)  rf=r size=128 type=d align=32 words (r25.0)
//.declare V0123 (137)  rf=r size=128 type=ud alias=V0122+0 align=32 words (r25.0)
//.declare V0124 (138)  rf=r size=128 type=d align=32 words (r29.0)
//.declare V0125 (139)  rf=r size=128 type=d align=32 words (r31.0)
//.declare V0128 (142)  rf=r size=128 type=ud alias=V0125+0 align=32 words (r31.0)
//.declare V0137 (151)  rf=r size=128 type=d align=32 words (r59.0)
//.declare V0138 (152)  rf=r size=128 type=d align=32 words (r61.0)
//.declare V0143 (157)  rf=r size=128 type=d align=32 words (r67.0)
//.declare V0144 (158)  rf=r size=128 type=d align=32 words (r69.0)
//.declare V0146 (160)  rf=r size=128 type=d align=32 words (r71.0)
//.declare P05 (161)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare P06 (162)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0147 (163)  rf=r size=128 type=d align=32 words (r73.0)
//.declare V0148 (164)  rf=r size=128 type=d align=32 words (r75.0)
//.declare V0149 (165)  rf=r size=128 type=d align=32 words (r80.0)
//.declare V0154 (170)  rf=r size=4 type=d align=2 words (r6.0)
//.declare V0156 (172)  rf=r size=128 type=ud alias=V0137+0 align=32 words (r59.0)
//.declare V0157 (173)  rf=r size=4 type=ud alias=V0154+0 align=2 words (r6.0)
//.declare V0160 (176)  rf=r size=128 type=d align=32 words (r13.0)
//.declare V0161 (177)  rf=r size=128 type=d align=32 words (r15.0)
//.declare V0165 (181)  rf=r size=128 type=d align=32 words (r21.0)
//.declare V0166 (182)  rf=r size=128 type=d align=32 words (r23.0)
//.declare P07 (187)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0171 (188)  rf=r size=128 type=ud alias=V0165+0 align=32 words (r21.0)
//.declare P08 (189)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare P09 (190)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0172 (191)  rf=r size=128 type=ud alias=V0166+0 align=32 words (r23.0)
//.declare V0173 (192)  rf=r size=4 type=ud alias=V0094+0 align=2 words (r91.2)
//.declare P10 (197)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0178 (198)  rf=r size=128 type=d align=32 words (r1.0)
//.declare V0179 (199)  rf=r size=4 type=d align=4 words (r3.0)
//.declare V0180 (200)  rf=r size=4 type=f align=2 words (r4.0)
//.declare V0181 (201)  rf=r size=4 type=ud alias=V0179+0 align=2 words (r3.0)
//.declare V0182 (202)  rf=r size=4 type=d align=2 words (r5.0)
//.declare V0183 (203)  rf=r size=4 type=ud alias=V0182+0 align=2 words (r5.0)
//.declare V0184 (204)  rf=r size=4 type=d align=2 words (r6.0)
//.declare V0185 (205)  rf=r size=128 type=f align=32 words (r7.0)
//.declare V0186 (206)  rf=r size=128 type=ud alias=V0178+0 align=32 words (r1.0)
//.declare V0187 (207)  rf=r size=4 type=f align=2 words (r10.0)
//.declare V0188 (208)  rf=r size=4 type=f align=2 words (r12.0)
//.declare V0189 (209)  rf=r size=128 type=f align=32 words (r13.0)
//.declare V0190 (210)  rf=r size=128 type=d align=32 words (r15.0)
//.declare V0191 (211)  rf=r size=128 type=ud alias=V0190+0 align=32 words (r15.0)
//.declare V0192 (212)  rf=r size=128 type=d align=32 words (r17.0)
//.declare V0193 (213)  rf=r size=128 type=d align=32 words (r19.0)
//.declare V0194 (214)  rf=r size=128 type=ud alias=V0193+0 align=32 words (r19.0)
//.declare V0195 (215)  rf=r size=4 type=f align=2 words (r22.0)
//.declare V0196 (216)  rf=r size=4 type=ud alias=V0184+0 align=2 words (r6.0)
//.declare V0197 (217)  rf=r size=128 type=f align=32 words (r23.0)
//.declare V0198 (218)  rf=r size=128 type=ud alias=V0192+0 align=32 words (r17.0)
//.declare V0199 (219)  rf=r size=128 type=f align=32 words (r27.0)
//.declare V0205 (225)  rf=r size=128 type=f align=32 words (r29.0)
//.declare V0206 (226)  rf=r size=128 type=d align=32 words (r31.0)
//.declare V0207 (227)  rf=r size=128 type=ud alias=V0206+0 align=32 words (r31.0)
//.declare V0208 (228)  rf=r size=128 type=d align=32 words (r33.0)
//.declare V0209 (229)  rf=r size=128 type=d align=32 words (r35.0)
//.declare V0210 (230)  rf=r size=128 type=d align=32 words (r37.0)
//.declare V0211 (231)  rf=r size=128 type=d align=32 words (r40.0)
//.declare V0212 (232)  rf=r size=128 type=ud alias=V0210+0 align=32 words (r37.0)
//.declare V0213 (233)  rf=r size=128 type=ud alias=V0211+0 align=32 words (r40.0)
//.declare  (234)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0214 (235)  rf=r size=128 type=d align=32 words (r92.0)
//.declare V0215 (236)  rf=r size=128 type=ud alias=V0214+0 align=32 words (r92.0)
//.declare P11 (237)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0216 (238)  rf=r size=128 type=ud alias=V0091+0 align=32 words (r89.0)
//.declare V0222 (244)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0223 (245)  rf=r size=128 type=d align=32 words (r8.0)
//.declare V0225 (247)  rf=r size=128 type=ud alias=V0090+0 align=32 words (r87.0)
//.declare V0228 (250)  rf=r size=128 type=d align=32 words (r16.0)
//.declare V0229 (251)  rf=r size=128 type=d align=32 words (r18.0)
//.declare V0231 (253)  rf=r size=128 type=ud alias=V0222+0 align=32 words (r6.0)
//.declare V0234 (256)  rf=r size=128 type=d align=32 words (r26.0)
//.declare V0235 (257)  rf=r size=128 type=d align=32 words (r28.0)
//.declare V0242 (264)  rf=r size=128 type=d align=32 words (r38.0)
//.declare V0246 (268)  rf=r size=128 type=d align=32 words (r46.0)
//.declare V0255 (277)  rf=r size=128 type=d align=32 words (r66.0)
//.declare V0256 (278)  rf=r size=128 type=d align=32 words (r68.0)
//.declare V0268 (290)  rf=r size=128 type=d align=32 words (r1.0)
//.declare V0269 (291)  rf=r size=128 type=d align=32 words (r4.0)
//.declare V0270 (292)  rf=r size=128 type=ud alias=V0268+0 align=32 words (r1.0)
//.declare V0271 (293)  rf=r size=128 type=ud alias=V0269+0 align=32 words (r4.0)
//.declare V0272 (294)  rf=r size=128 type=d align=32 words (r6.0)
//.declare V0273 (295)  rf=r size=128 type=ud alias=V0272+0 align=32 words (r6.0)
//.declare V0276 (298)  rf=r size=128 type=d align=32 words (r94.0)
//.declare V0277 (299)  rf=r size=128 type=d align=32 words (r96.0)
//.declare V0278 (300)  rf=r size=128 type=d align=32 words (r1.0)
//.declare P12 (301)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0279 (302)  rf=r size=128 type=ud alias=V0278+0 align=32 words (r1.0)
//.declare V0280 (303)  rf=r size=8 type=q align=4 words (r1.0)
//.declare V0281 (304)  rf=r size=8 type=df align=4 words (r3.0)
//.declare V0282 (305)  rf=r size=8 type=uq alias=V0280+0 align=4 words (r1.0)
//.declare V0283 (306)  rf=r size=4 type=f align=4 words (r4.0)
//.declare V0284 (307)  rf=r size=4 type=f align=2 words (r5.0)
//.declare V0285 (308)  rf=r size=8 type=df align=4 words (r6.0)
//.declare V0286 (309)  rf=r size=8 type=df align=4 words (r7.0)
//.declare V0287 (310)  rf=r size=8 type=df align=4 words (r9.0)
//.declare V0288 (311)  rf=r size=8 type=df align=4 words (r10.0)
//.declare V0290 (313)  rf=r size=128 type=d align=32 words (r11.0)
//.declare V0292 (315)  rf=r size=128 type=ud alias=V0290+0 align=32 words (r11.0)
//.declare V0294 (317)  rf=r size=128 type=d align=32 words (r27.0)
//.declare V0295 (318)  rf=r size=128 type=ud alias=V0294+0 align=32 words (r27.0)
//.declare V0296 (319)  rf=r size=128 type=d align=32 words (r31.0)
//.declare V0297 (320)  rf=r size=128 type=d align=32 words (r33.0)
//.declare V0300 (323)  rf=r size=128 type=ud alias=V0297+0 align=32 words (r33.0)
//.declare V0309 (332)  rf=r size=128 type=d align=32 words (r61.0)
//.declare V0310 (333)  rf=r size=128 type=d align=32 words (r63.0)
//.declare V0311 (334)  rf=r size=128 type=d align=32 words (r65.0)
//.declare P13 (335)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0312 (336)  rf=r size=128 type=d align=32 words (r68.0)
//.declare P14 (337)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0313 (338)  rf=r size=128 type=ud alias=V0310+0 align=32 words (r63.0)
//.declare V0314 (339)  rf=r size=128 type=d align=32 words (r70.0)
//.declare V0320 (345)  rf=r size=128 type=ud alias=V0309+0 align=32 words (r61.0)
//.declare V0323 (348)  rf=r size=128 type=d align=32 words (r1.0)
//.declare V0324 (349)  rf=r size=128 type=d align=32 words (r4.0)
//.declare V0328 (353)  rf=r size=128 type=d align=32 words (r10.0)
//.declare V0329 (354)  rf=r size=128 type=d align=32 words (r12.0)
//.declare P15 (355)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0330 (356)  rf=r size=128 type=ud alias=V0328+0 align=32 words (r10.0)
//.declare P16 (357)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare P17 (358)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0331 (359)  rf=r size=128 type=ud alias=V0329+0 align=32 words (r12.0)
//.declare V0332 (360)  rf=r size=4 type=ud alias=V0092+0 align=2 words (r91.0)
//.declare P18 (367)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0339 (368)  rf=r size=128 type=d align=32 words (r1.0)
//.declare V0340 (369)  rf=r size=4 type=f align=2 words (r4.0)
//.declare V0341 (370)  rf=r size=4 type=d align=2 words (r5.0)
//.declare V0342 (371)  rf=r size=4 type=ud alias=V0341+0 align=2 words (r5.0)
//.declare V0343 (372)  rf=r size=4 type=d align=2 words (r6.0)
//.declare V0344 (373)  rf=r size=128 type=f align=32 words (r7.0)
//.declare V0345 (374)  rf=r size=128 type=ud alias=V0339+0 align=32 words (r1.0)
//.declare V0346 (375)  rf=r size=4 type=f align=2 words (r10.0)
//.declare V0347 (376)  rf=r size=4 type=f align=2 words (r12.0)
//.declare V0348 (377)  rf=r size=128 type=f align=32 words (r13.0)
//.declare V0349 (378)  rf=r size=128 type=d align=32 words (r15.0)
//.declare V0350 (379)  rf=r size=128 type=ud alias=V0349+0 align=32 words (r15.0)
//.declare V0351 (380)  rf=r size=128 type=d align=32 words (r17.0)
//.declare V0352 (381)  rf=r size=128 type=d align=32 words (r19.0)
//.declare V0353 (382)  rf=r size=128 type=ud alias=V0352+0 align=32 words (r19.0)
//.declare V0354 (383)  rf=r size=4 type=f align=2 words (r22.0)
//.declare V0355 (384)  rf=r size=4 type=ud alias=V0343+0 align=2 words (r6.0)
//.declare V0356 (385)  rf=r size=128 type=f align=32 words (r23.0)
//.declare V0357 (386)  rf=r size=128 type=ud alias=V0351+0 align=32 words (r17.0)
//.declare V0358 (387)  rf=r size=128 type=f align=32 words (r27.0)
//.declare V0364 (393)  rf=r size=128 type=f align=32 words (r29.0)
//.declare V0365 (394)  rf=r size=128 type=d align=32 words (r31.0)
//.declare V0366 (395)  rf=r size=128 type=ud alias=V0365+0 align=32 words (r31.0)
//.declare V0367 (396)  rf=r size=128 type=d align=32 words (r33.0)
//.declare V0368 (397)  rf=r size=128 type=d align=32 words (r37.0)
//.declare V0369 (398)  rf=r size=128 type=d align=32 words (r39.0)
//.declare P19 (399)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare V0370 (400)  rf=r size=128 type=ud alias=V0369+0 align=32 words (r39.0)
//.declare V0371 (401)  rf=r size=128 type=d align=32 words (r42.0)
//.declare V0372 (402)  rf=r size=128 type=d align=32 words (r98.0)
//.declare V0373 (403)  rf=r size=128 type=ud alias=V0372+0 align=32 words (r98.0)
//.declare V0384 (414)  rf=r size=128 type=ud alias=V0276+0 align=32 words (r94.0)
//.declare V0387 (417)  rf=r size=128 type=d align=32 words (r20.0)
//.declare V0388 (418)  rf=r size=128 type=d align=32 words (r16.0)
//.declare V0396 (426)  rf=r size=128 type=d align=32 words (r32.0)
//.declare V0397 (427)  rf=r size=128 type=d align=32 words (r36.0)
//.declare V0399 (429)  rf=r size=128 type=ud alias=V0396+0 align=32 words (r32.0)
//.declare V0402 (432)  rf=r size=128 type=d align=32 words (r54.0)
//.declare V0403 (433)  rf=r size=128 type=d align=32 words (r44.0)
//.declare V0404 (434)  rf=r size=256 type=q align=32 words (r81.0)
//.declare V0405 (435)  rf=r size=256 type=uq alias=V0404+0 align=32 words (r81.0)
//.declare V0406 (436)  rf=r size=128 type=d align=32 words (r5.0)
//.declare V0407 (437)  rf=r size=128 type=d align=32 words (r7.0)
//.declare V0409 (439)  rf=r size=8 type=q alias=V0040+0 align=4 words (r3.3)
//.declare V0410 (440)  rf=r size=256 type=q align=32 words (r56.0)
//.declare V0411 (441)  rf=r size=256 type=uq alias=V0410+0 align=32 words (r56.0)
//.declare V0412 (442)  rf=r size=128 type=f align=32 words (r71.0)
//.declare V0413 (443)  rf=r size=8 type=q alias=V0041+0 align=4 words (r3.4)
//.declare V0414 (444)  rf=r size=256 type=q align=32 words (r50.0)
//.declare V0415 (445)  rf=r size=256 type=uq alias=V0414+0 align=32 words (r50.0)
//.declare V0416 (446)  rf=r size=128 type=d align=32 words (r67.0)
//.declare V0417 (447)  rf=r size=128 type=d align=32 words (r13.0)
//.declare V0420 (450)  rf=r size=8 type=d alias=V0037+0 align=4 words (r3.2)
//.declare V0423 (453)  rf=r size=8 type=d alias=V0038+0 align=4 words (r3.4)
//.declare V0429 (459)  rf=r size=128 type=f align=32 words (r11.0)
//.declare V0430 (460)  rf=r size=128 type=f align=32 words (r15.0)
//.declare V0431 (461)  rf=r size=128 type=f align=32 words (r9.0)
//.declare V0433 (463)  rf=r size=4 type=f align=2 words (r64.0)
//.declare V0434 (464)  rf=r size=128 type=f align=32 words (r17.0)
//.declare V0435 (465)  rf=r size=256 type=q align=32 words (r1.0)
//.declare V0436 (466)  rf=r size=256 type=uq alias=V0435+0 align=32 words (r1.0)
//.declare  (467)  rf=r size=64 type=ud align=32 words (r127.0)
//.declare  (468)  rf=r size=4 type=d alias=V0101+0 align=2 words (r91.4)
//.declare  (469)  rf=r size=4 type=d alias=V0101+0 align=2 words (r91.4)
//.declare  (474)  rf=r size=128 type=ud align=32 words (r19.0)
//.declare  (475)  rf=r size=128 type=ud align=32 words (r21.0)
//.declare  (476)  rf=r size=128 type=ud align=32 words (r23.0)
//.declare  (477)  rf=r size=128 type=ud align=32 words (r27.0)
//.declare  (480)  rf=r size=2 type=w align=1 words (r35.0)
//.declare  (481)  rf=r size=64 type=ud align=32 words (r7.0)
//.declare  (482)  rf=r size=64 type=ud align=32 words (r10.0)
//.declare  (483)  rf=r size=128 type=ud align=32 words (r11.0)
//.declare  (484)  rf=r size=128 type=ud align=32 words (r15.0)
//.declare  (485)  rf=r size=128 type=ud align=32 words (r33.0)
//.declare  (486)  rf=r size=128 type=ud align=32 words (r38.0)
//.declare  (487)  rf=r size=128 type=ud align=32 words (r38.0)
//.declare  (488)  rf=r size=128 type=ud align=32 words (r42.0)
//.declare  (489)  rf=r size=4 type=f align=2 words (r11.0)
//.declare  (492)  rf=r size=128 type=ud align=32 words (r1.0)
//.declare  (493)  rf=r size=128 type=ud align=32 words (r4.0)
//.declare  (494)  rf=r size=64 type=ud align=32 words (r10.0)
//.declare  (495)  rf=r size=64 type=ud align=32 words (r13.0)
//.declare  (496)  rf=r size=64 type=ud align=32 words (r20.0)
//.declare  (497)  rf=r size=64 type=ud align=32 words (r23.0)
//.declare  (498)  rf=r size=64 type=ud align=32 words (r40.0)
//.declare  (499)  rf=r size=64 type=ud align=32 words (r43.0)
//.declare  (500)  rf=r size=64 type=ud align=32 words (r60.0)
//.declare  (501)  rf=r size=64 type=ud align=32 words (r63.0)
//.declare  (504)  rf=r size=128 type=ud align=32 words (r8.0)
//.declare  (505)  rf=r size=128 type=ud align=32 words (r10.0)
//.declare  (506)  rf=r size=128 type=ud align=32 words (r25.0)
//.declare  (507)  rf=r size=128 type=ud align=32 words (r29.0)
//.declare  (510)  rf=r size=64 type=ud align=32 words (r80.0)
//.declare  (511)  rf=r size=64 type=ud align=32 words (r83.0)
//.declare  (512)  rf=r size=128 type=ud align=32 words (r13.0)
//.declare  (513)  rf=r size=128 type=ud align=32 words (r17.0)
//.declare  (514)  rf=r size=128 type=ud align=32 words (r35.0)
//.declare  (515)  rf=r size=128 type=ud align=32 words (r40.0)
//.declare  (516)  rf=r size=4 type=f align=2 words (r11.0)
//.declare  (519)  rf=r size=128 type=ud align=32 words (r1.0)
//.declare  (520)  rf=r size=128 type=ud align=32 words (r4.0)
//.declare  (521)  rf=r size=64 type=ud align=32 words (r8.0)
//.declare  (522)  rf=r size=64 type=ud align=32 words (r15.0)
//.declare  (523)  rf=r size=128 type=d align=32 words (r7.0)
//.declare  (524)  rf=r size=128 type=d align=32 words (r9.0)
//.declare  (525)  rf=r size=128 type=q align=32 words (r100.0)
//.declare  (526)  rf=r size=128 type=q align=32 words (r102.0)
//.declare  (527)  rf=r size=128 type=d align=32 words (r11.0)
//.declare  (528)  rf=r size=128 type=d align=32 words (r13.0)
//.declare  (529)  rf=r size=128 type=q align=32 words (r15.0)
//.declare  (530)  rf=r size=128 type=q align=32 words (r17.0)
//.declare  (533)  rf=r size=128 type=q align=32 words (r104.0)
//.declare  (534)  rf=r size=128 type=q align=32 words (r106.0)
//.declare  (537)  rf=r size=128 type=df align=32 words (r13.0)
//.declare  (538)  rf=r size=128 type=df align=32 words (r17.0)
//.declare  (539)  rf=r size=128 type=df align=32 words (r19.0)
//.declare  (540)  rf=r size=128 type=df align=32 words (r21.0)
//.declare  (541)  rf=r size=128 type=df align=32 words (r36.0)
//.declare  (542)  rf=r size=128 type=df align=32 words (r40.0)
//.declare  (543)  rf=r size=128 type=df align=32 words (r43.0)
//.declare  (544)  rf=r size=128 type=df align=32 words (r45.0)
//.declare  (545)  rf=r size=128 type=df align=32 words (r47.0)
//.declare  (546)  rf=r size=128 type=df align=32 words (r49.0)
//.declare  (547)  rf=r size=128 type=df align=32 words (r51.0)
//.declare  (548)  rf=r size=128 type=df align=32 words (r53.0)
//.declare  (549)  rf=r size=128 type=q align=32 words (r55.0)
//.declare  (550)  rf=r size=128 type=q align=32 words (r57.0)
//.declare  (551)  rf=r size=128 type=q align=32 words (r63.0)
//.declare  (552)  rf=r size=128 type=q align=32 words (r65.0)
//.declare  (555)  rf=r size=128 type=d align=32 words (r84.0)
//.declare  (556)  rf=r size=128 type=d align=32 words (r82.0)
//.declare  (557)  rf=r size=128 type=q align=32 words (r1.0)
//.declare  (558)  rf=r size=128 type=q align=32 words (r4.0)
//.declare  (559)  rf=r size=128 type=q align=32 words (r8.0)
//.declare  (560)  rf=r size=128 type=q align=32 words (r11.0)
//.declare  (561)  rf=r size=128 type=q align=32 words (r17.0)
//.declare  (562)  rf=r size=128 type=q align=32 words (r19.0)
//.declare  (565)  rf=r size=128 type=d align=32 words (r29.0)
//.declare  (566)  rf=r size=128 type=d align=32 words (r27.0)
//.declare  (567)  rf=r size=128 type=q align=32 words (r31.0)
//.declare  (568)  rf=r size=128 type=q align=32 words (r33.0)
//.declare  (569)  rf=r size=128 type=q align=32 words (r40.0)
//.declare  (570)  rf=r size=128 type=q align=32 words (r44.0)
//.declare  (571)  rf=r size=128 type=q align=32 words (r36.0)
//.declare  (573)  rf=r size=128 type=q align=32 words (r108.0)
//.declare  (574)  rf=r size=128 type=q align=32 words (r110.0)
//.declare  (575)  rf=r size=128 type=q align=32 words (r1.0)
//.declare  (576)  rf=r size=128 type=q align=32 words (r4.0)
//.declare  (579)  rf=r size=128 type=q align=32 words (r11.0)
//.declare  (580)  rf=r size=128 type=q align=32 words (r14.0)
//.declare  (581)  rf=r size=128 type=q align=32 words (r21.0)
//.declare  (582)  rf=r size=128 type=q align=32 words (r24.0)
//.declare  (583)  rf=r size=128 type=q align=32 words (r30.0)
//.declare  (584)  rf=r size=128 type=q align=32 words (r32.0)
//.declare  (585)  rf=r size=128 type=q align=32 words (r34.0)
//.declare  (586)  rf=r size=128 type=q align=32 words (r36.0)
//.declare  (587)  rf=r size=128 type=q align=32 words (r41.0)
//.declare  (588)  rf=r size=128 type=q align=32 words (r44.0)
//.declare  (589)  rf=r size=128 type=d align=32 words (r48.0)
//.declare  (590)  rf=r size=128 type=d align=32 words (r50.0)
//.declare  (591)  rf=r size=128 type=q align=32 words (r52.0)
//.declare  (592)  rf=r size=128 type=q align=32 words (r54.0)
//.declare  (593)  rf=r size=128 type=q align=32 words (r56.0)
//.declare  (594)  rf=r size=128 type=q align=32 words (r58.0)
//.declare  (595)  rf=r size=128 type=q align=32 words (r61.0)
//.declare  (596)  rf=r size=128 type=q align=32 words (r64.0)
//.declare  (597)  rf=r size=128 type=q align=32 words (r70.0)
//.declare  (598)  rf=r size=128 type=q align=32 words (r72.0)
//.declare  (599)  rf=r size=128 type=q align=32 words (r74.0)
//.declare  (600)  rf=r size=128 type=q align=32 words (r76.0)
//.declare  (601)  rf=r size=128 type=q align=32 words (r78.0)
//.declare  (602)  rf=r size=128 type=q align=32 words (r80.0)
//.declare  (603)  rf=r size=128 type=q align=32 words (r82.0)
//.declare  (604)  rf=r size=128 type=q align=32 words (r84.0)
//.declare  (605)  rf=r size=128 type=q align=32 words (r112.0)
//.declare  (606)  rf=r size=128 type=q align=32 words (r114.0)
//.declare  (609)  rf=r size=128 type=df align=32 words (r15.0)
//.declare  (610)  rf=r size=128 type=df align=32 words (r19.0)
//.declare  (611)  rf=r size=128 type=df align=32 words (r21.0)
//.declare  (612)  rf=r size=128 type=df align=32 words (r23.0)
//.declare  (613)  rf=r size=128 type=df align=32 words (r38.0)
//.declare  (614)  rf=r size=128 type=df align=32 words (r42.0)
//.declare  (615)  rf=r size=128 type=df align=32 words (r45.0)
//.declare  (616)  rf=r size=128 type=df align=32 words (r47.0)
//.declare  (617)  rf=r size=128 type=df align=32 words (r49.0)
//.declare  (618)  rf=r size=128 type=df align=32 words (r51.0)
//.declare  (619)  rf=r size=128 type=df align=32 words (r53.0)
//.declare  (620)  rf=r size=128 type=df align=32 words (r55.0)
//.declare  (621)  rf=r size=128 type=q align=32 words (r57.0)
//.declare  (622)  rf=r size=128 type=q align=32 words (r59.0)
//.declare  (625)  rf=r size=128 type=d align=32 words (r74.0)
//.declare  (626)  rf=r size=128 type=d align=32 words (r72.0)
//.declare  (627)  rf=r size=128 type=q align=32 words (r76.0)
//.declare  (628)  rf=r size=128 type=q align=32 words (r78.0)
//.declare  (629)  rf=r size=128 type=q align=32 words (r81.0)
//.declare  (630)  rf=r size=128 type=q align=32 words (r84.0)
//.declare  (631)  rf=r size=128 type=q align=32 words (r6.0)
//.declare  (632)  rf=r size=128 type=q align=32 words (r8.0)
//.declare  (635)  rf=r size=128 type=d align=32 words (r14.0)
//.declare  (636)  rf=r size=128 type=d align=32 words (r16.0)
//.declare  (637)  rf=r size=128 type=q align=32 words (r18.0)
//.declare  (638)  rf=r size=128 type=q align=32 words (r20.0)
//.declare  (639)  rf=r size=128 type=q align=32 words (r116.0)
//.declare  (640)  rf=r size=128 type=q align=32 words (r118.0)
//.declare  (641)  rf=r size=128 type=q align=32 words (r1.0)
//.declare  (642)  rf=r size=128 type=q align=32 words (r6.0)
//.declare  (643)  rf=r size=128 type=q align=32 words (r4.0)
//.declare  (644)  rf=r size=128 type=q align=32 words (r9.0)
//.declare  (645)  rf=r size=128 type=q align=32 words (r13.0)
//.declare  (646)  rf=r size=128 type=q align=32 words (r18.0)
//.declare  (647)  rf=r size=128 type=q align=32 words (r26.0)
//.declare  (648)  rf=r size=128 type=q align=32 words (r28.0)
//.declare  (649)  rf=r size=128 type=q align=32 words (r60.0)
//.declare  (650)  rf=r size=128 type=q align=32 words (r62.0)
//.declare  (651)  rf=r size=128 type=q align=32 words (r30.0)
//.declare  (652)  rf=r size=128 type=q align=32 words (r38.0)
//.declare  (653)  rf=r size=128 type=q align=32 words (r65.0)
//.declare  (654)  rf=r size=128 type=q align=32 words (r69.0)
//.declare  (655)  rf=r size=128 type=q align=32 words (r11.0)
//.declare  (656)  rf=r size=128 type=q align=32 words (r24.0)
//.declare  (657)  rf=r size=128 type=q align=32 words (r22.0)
//.declare  (658)  rf=r size=128 type=q align=32 words (r34.0)
//.declare  (661)  rf=r size=128 type=q align=32 words (r40.0)
//.declare  (662)  rf=r size=128 type=q align=32 words (r46.0)
//.declare  (663)  rf=r size=128 type=q align=32 words (r42.0)
//.declare  (664)  rf=r size=128 type=q align=32 words (r48.0)
//.declare  (665)  rf=r size=128 type=d align=32 words (r73.0)
//.declare  (666)  rf=r size=128 type=d align=32 words (r75.0)
//.declare  (667)  rf=r size=128 type=q align=32 words (r77.0)
//.declare  (668)  rf=r size=128 type=q align=32 words (r79.0)
//.declare  (669)  rf=r size=128 type=d alias=+0 align=32 words (r100.0)
//.declare  (670)  rf=r size=128 type=d alias=+0 align=32 words (r102.0)
//.declare  (671)  rf=r size=128 type=d alias=+0 align=32 words (r15.0)
//.declare  (672)  rf=r size=128 type=d alias=+0 align=32 words (r17.0)
//.declare  (673)  rf=r size=128 type=d alias=+0 align=32 words (r104.0)
//.declare  (674)  rf=r size=128 type=d alias=+0 align=32 words (r106.0)
//.declare  (675)  rf=r size=128 type=ud alias=+0 align=32 words (r104.0)
//.declare  (676)  rf=r size=128 type=ud alias=+0 align=32 words (r106.0)
//.declare  (677)  rf=r size=128 type=uq alias=+0 align=32 words (r55.0)
//.declare  (678)  rf=r size=128 type=uq alias=+0 align=32 words (r57.0)
//.declare  (679)  rf=r size=128 type=d alias=+0 align=32 words (r55.0)
//.declare  (680)  rf=r size=128 type=d alias=+0 align=32 words (r57.0)
//.declare  (681)  rf=r size=128 type=uq alias=+0 align=32 words (r63.0)
//.declare  (682)  rf=r size=128 type=uq alias=+0 align=32 words (r65.0)
//.declare  (683)  rf=r size=128 type=d alias=+0 align=32 words (r63.0)
//.declare  (684)  rf=r size=128 type=d alias=+0 align=32 words (r65.0)
//.declare  (685)  rf=r size=128 type=d alias=+0 align=32 words (r1.0)
//.declare  (686)  rf=r size=128 type=d alias=+0 align=32 words (r4.0)
//.declare  (687)  rf=r size=128 type=ud alias=+0 align=32 words (r8.0)
//.declare  (688)  rf=r size=128 type=ud alias=+0 align=32 words (r11.0)
//.declare  (689)  rf=r size=128 type=d alias=+0 align=32 words (r8.0)
//.declare  (690)  rf=r size=128 type=d alias=+0 align=32 words (r11.0)
//.declare  (691)  rf=r size=128 type=d alias=+0 align=32 words (r17.0)
//.declare  (692)  rf=r size=128 type=d alias=+0 align=32 words (r19.0)
//.declare  (693)  rf=r size=128 type=d alias=+0 align=32 words (r31.0)
//.declare  (694)  rf=r size=128 type=d alias=+0 align=32 words (r33.0)
//.declare  (695)  rf=r size=128 type=d alias=+0 align=32 words (r36.0)
//.declare  (696)  rf=r size=128 type=ud alias=+0 align=32 words (r36.0)
//.declare  (697)  rf=r size=128 type=uq alias=+0 align=32 words (r1.0)
//.declare  (698)  rf=r size=128 type=uq alias=+0 align=32 words (r104.0)
//.declare  (699)  rf=r size=128 type=uq alias=+0 align=32 words (r4.0)
//.declare  (700)  rf=r size=128 type=uq alias=+0 align=32 words (r106.0)
//.declare  (701)  rf=r size=128 type=d alias=+0 align=32 words (r1.0)
//.declare  (702)  rf=r size=128 type=d alias=+0 align=32 words (r4.0)
//.declare  (703)  rf=r size=128 type=ud alias=+0 align=32 words (r11.0)
//.declare  (704)  rf=r size=128 type=ud alias=+0 align=32 words (r14.0)
//.declare  (705)  rf=r size=128 type=d alias=+0 align=32 words (r11.0)
//.declare  (706)  rf=r size=128 type=d alias=+0 align=32 words (r14.0)
//.declare  (707)  rf=r size=128 type=ud alias=+0 align=32 words (r21.0)
//.declare  (708)  rf=r size=128 type=ud alias=+0 align=32 words (r24.0)
//.declare  (709)  rf=r size=128 type=d alias=+0 align=32 words (r21.0)
//.declare  (710)  rf=r size=128 type=d alias=+0 align=32 words (r24.0)
//.declare  (711)  rf=r size=128 type=uq alias=+0 align=32 words (r30.0)
//.declare  (712)  rf=r size=128 type=uq alias=+0 align=32 words (r11.0)
//.declare  (713)  rf=r size=128 type=uq alias=+0 align=32 words (r32.0)
//.declare  (714)  rf=r size=128 type=uq alias=+0 align=32 words (r14.0)
//.declare  (715)  rf=r size=128 type=d alias=+0 align=32 words (r34.0)
//.declare  (716)  rf=r size=128 type=d alias=+0 align=32 words (r36.0)
//.declare  (717)  rf=r size=128 type=ud alias=+0 align=32 words (r41.0)
//.declare  (718)  rf=r size=128 type=ud alias=+0 align=32 words (r44.0)
//.declare  (719)  rf=r size=128 type=d alias=+0 align=32 words (r41.0)
//.declare  (720)  rf=r size=128 type=d alias=+0 align=32 words (r44.0)
//.declare  (721)  rf=r size=128 type=d alias=+0 align=32 words (r52.0)
//.declare  (722)  rf=r size=128 type=d alias=+0 align=32 words (r54.0)
//.declare  (723)  rf=r size=128 type=ud alias=+0 align=32 words (r61.0)
//.declare  (724)  rf=r size=128 type=ud alias=+0 align=32 words (r64.0)
//.declare  (725)  rf=r size=128 type=d alias=+0 align=32 words (r61.0)
//.declare  (726)  rf=r size=128 type=d alias=+0 align=32 words (r64.0)
//.declare  (727)  rf=r size=128 type=uq alias=+0 align=32 words (r70.0)
//.declare  (728)  rf=r size=128 type=uq alias=+0 align=32 words (r34.0)
//.declare  (729)  rf=r size=128 type=uq alias=+0 align=32 words (r72.0)
//.declare  (730)  rf=r size=128 type=uq alias=+0 align=32 words (r36.0)
//.declare  (731)  rf=r size=128 type=uq alias=+0 align=32 words (r78.0)
//.declare  (732)  rf=r size=128 type=uq alias=+0 align=32 words (r56.0)
//.declare  (733)  rf=r size=128 type=uq alias=+0 align=32 words (r80.0)
//.declare  (734)  rf=r size=128 type=uq alias=+0 align=32 words (r58.0)
//.declare  (735)  rf=r size=128 type=uq alias=+0 align=32 words (r112.0)
//.declare  (736)  rf=r size=128 type=uq alias=+0 align=32 words (r82.0)
//.declare  (737)  rf=r size=128 type=uq alias=+0 align=32 words (r114.0)
//.declare  (738)  rf=r size=128 type=uq alias=+0 align=32 words (r84.0)
//.declare  (739)  rf=r size=128 type=d alias=+0 align=32 words (r112.0)
//.declare  (740)  rf=r size=128 type=d alias=+0 align=32 words (r114.0)
//.declare  (741)  rf=r size=128 type=ud alias=+0 align=32 words (r112.0)
//.declare  (742)  rf=r size=128 type=ud alias=+0 align=32 words (r114.0)
//.declare  (743)  rf=r size=128 type=uq alias=+0 align=32 words (r57.0)
//.declare  (744)  rf=r size=128 type=uq alias=+0 align=32 words (r59.0)
//.declare  (745)  rf=r size=128 type=d alias=+0 align=32 words (r57.0)
//.declare  (746)  rf=r size=128 type=d alias=+0 align=32 words (r59.0)
//.declare  (747)  rf=r size=128 type=d alias=+0 align=32 words (r76.0)
//.declare  (748)  rf=r size=128 type=d alias=+0 align=32 words (r78.0)
//.declare  (749)  rf=r size=128 type=ud alias=+0 align=32 words (r81.0)
//.declare  (750)  rf=r size=128 type=ud alias=+0 align=32 words (r84.0)
//.declare  (751)  rf=r size=128 type=d alias=+0 align=32 words (r81.0)
//.declare  (752)  rf=r size=128 type=d alias=+0 align=32 words (r84.0)
//.declare  (753)  rf=r size=128 type=d alias=+0 align=32 words (r6.0)
//.declare  (754)  rf=r size=128 type=d alias=+0 align=32 words (r8.0)
//.declare  (755)  rf=r size=128 type=d alias=+0 align=32 words (r18.0)
//.declare  (756)  rf=r size=128 type=d alias=+0 align=32 words (r20.0)
//.declare  (757)  rf=r size=128 type=d alias=+0 align=32 words (r108.0)
//.declare  (758)  rf=r size=128 type=d alias=+0 align=32 words (r110.0)
//.declare  (759)  rf=r size=128 type=d alias=+0 align=32 words (r116.0)
//.declare  (760)  rf=r size=128 type=d alias=+0 align=32 words (r118.0)
//.declare  (761)  rf=r size=128 type=ud alias=+0 align=32 words (r26.0)
//.declare  (762)  rf=r size=128 type=ud alias=+0 align=32 words (r28.0)
//.declare  (763)  rf=r size=128 type=d alias=+0 align=32 words (r26.0)
//.declare  (764)  rf=r size=128 type=d alias=+0 align=32 words (r28.0)
//.declare  (765)  rf=r size=128 type=d alias=+0 align=32 words (r22.0)
//.declare  (766)  rf=r size=128 type=d alias=+0 align=32 words (r34.0)
//.declare  (767)  rf=r size=128 type=ud alias=+0 align=32 words (r40.0)
//.declare  (768)  rf=r size=128 type=ud alias=+0 align=32 words (r46.0)
//.declare  (769)  rf=r size=128 type=d alias=+0 align=32 words (r40.0)
//.declare  (770)  rf=r size=128 type=d alias=+0 align=32 words (r46.0)
//.declare  (771)  rf=r size=128 type=d alias=+0 align=32 words (r77.0)
//.declare  (772)  rf=r size=128 type=d alias=+0 align=32 words (r79.0)
//.declare r0 (773)  rf=r size=64 type=ud align=32 words (r0.0)
//.declare rtmp (774)  rf=r size=64 type=ud align=32 words (r127.0)
//.declare inlineRegFromTDL (775)  rf=r size=32 type=ud align=2 words (r1.0)
//.declare inlineRegExpectedLocation (776)  rf=r size=32 type=ud align=2 words (r2.0)
//.declare  (777)  rf=r size=64 type=ud align=32 words (r1.0)
//.declare  (778)  rf=r size=64 type=ud align=32 words (r3.0)

// .inputs
// +----------+----------+--------+----------+------------------+
// | id       | type     |  bytes | at       | from             |
// +----------+----------+--------+----------+------------------+
// | V0046    | :w x 32  |   0x40 | r1       | pti[tid]+0x0     |
// | V0044    | :d x 3   |    0xC | r2       | inline+0x0       |
// | V0045    | :d x 3   |    0xC | r2+0xC   | inline+0xC       |
// | V0035    | :uq      |    0x8 | r2+0x18  | inline+0x18      |
// | V0036    | :uq      |    0x8 | r3       | cti+0x20         |
// | V0037    | :uq      |    0x8 | r3+0x8   | cti+0x28         |
// | V0038    | :uq      |    0x8 | r3+0x10  | cti+0x30         |
// | V0040    | :uq      |    0x8 | r3+0x18  | cti+0x38         |
// | V0041    | :uq      |    0x8 | r3+0x20  | cti+0x40         |
// | V0034    | :q       |    0x8 | r3+0x28  | cti+0x48         |
// | V0039    | :d       |    0x4 | r3+0x30  | cti+0x50         |
// +----------+----------+--------+----------+------------------+


// B000: Preds:{},  Succs:{B001}
per_thread_prolog:
(W)     mov (16|M0)              r127.0<1>:ud  0x0:ud                                                //  ALU pipe: int; 
(W)     and (1|M0)               r127.2<1>:ud  r0.0<0;1,0>:ud    0xFFFFFFC0:ud                       //  ALU pipe: int; 
(W)     and (1|M0)               r127.0<1>:uw  r0.4<0;1,0>:uw    0xFF:uw                             //  ALU pipe: int; 
(W)     add (1|M0)               r127.2<1>:ud  r127.2<0;1,0>:ud  0x40:ud              {I@2}          //  ALU pipe: int; 
(W)     add (1|M0)               r127.2<1>:ud  r127.2<0;1,0>:ud  0x0:ud              {I@1}           //  R_SYM_ADDR_32: __INTEL_PATCH_CROSS_THREAD_OFFSET_OFF_R0; ALU pipe: int; 
(W)     mad (1|M0)               r127.0<1>:ud  r127.2<0;0>:ud    r127.0<0;0>:uw    0x40:uw              {I@1} //  ALU pipe: int; 
(W)     mov (8|M0)               r2.0<1>:ud    r1.0<1;1,0>:ud                                        //  ALU pipe: int; 
(W)     load.ugm.d32x16t.a32.ca.cc (1|M0)  r1:1 bti[255][r127:1]   {A@1,$0} // ex_desc:0xFF000000; desc:0x6219D500 // 
// B001: Preds:{B000},  Succs:{B002}
// cross_thread_prolog:
(W)     and (1|M0)               r127.0<1>:ud  r0.0<0;1,0>:ud    0xFFFFFFC0:ud              {$0.src} //  ALU pipe: int; 
(W)     add (1|M0)               r127.0<1>:ud  r127.0<0;1,0>:ud  0x0:ud              {I@1}           //  R_SYM_ADDR_32: __INTEL_PATCH_CROSS_THREAD_OFFSET_OFF_R0; ALU pipe: int; 
(W)     load.ugm.d32x16t.a32.ca.cc (1|M0)  r3:1 bti[255][r127:1]   {I@1,$1} // ex_desc:0xFF000000; desc:0x6219D500 // 
// B002: Preds:{B001},  Succs:{B003, B004}
// _main:
(W)     mov (16|M0)              r86.0<1>:ud   r0.0<1;1,0>:ud                                        //  ALU pipe: int; $1
(W)     or (1|M0)                cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x400004C0:ud              {A@1}    // $1
(W)     mul (1|M0)               acc0.0<1>:d   r2.3<0;1,0>:d     r86.2<0;1,0>:uw  {A@1}              //  ALU pipe: int; $3
(W)     macl (1|M0)              r4.0<1>:d     r2.3<0;1,0>:d     r86.1<0;1,0>:d                      //  ALU pipe: int; $5
(W)     mov (2|M0)               r2.8<1>:d     r3.10<1;1,0>:d                   {$1.dst}             //  ALU pipe: int; $2
        add3 (32|M0)             r5.0<1>:d     r4.0<0;0>:d       r1.0<1;0>:uw      r2.0<0>:d        {@2,$0.dst} //  ALU pipe: int; $5
        cmp (32|M0)   (gt)f0.0   null<1>:ud    r2.8<0;1,0>:ud    r5.0<1;1,0>:ud   {I@1}              //  ALU pipe: int; $6
(f0.0)  cmp (32|M0)   (eq)f0.0   null<1>:d     r2.9<0;1,0>:d     0:w                                 //  ALU pipe: int; $7
(~f0.0) cmp (32|M0)   (gt)f0.0   null<1>:ud    r2.9<0;1,0>:ud    0x0:uw                              //  ALU pipe: int; $9
(W)     asr (1|M0)               r91.0<1>:d    r3.12<0;1,0>:d    31:w               {Compacted}      //  ALU pipe: int; $37
(~f0.0) sel (32|M0)              r11.0<1>:d    r2.8<0;1,0>:d     0:w                                 //  ALU pipe: int; $23
(~f0.0) sel (32|M0)              r13.0<1>:d    r2.9<0;1,0>:d     0:w                                 //  ALU pipe: int; $24
(W)     mul (1|M0)               acc0.0<1>:ud  r3.12<0;1,0>:ud   0x280:uw                            //  ALU pipe: int; $39
        mov (16|M0)              r19.0<2>:ud   r5.0<1;1,0>:ud                   {Compacted}          //  ALU pipe: int; $32
        mov (16|M16)             r21.0<2>:ud   r6.0<1;1,0>:ud                                        //  ALU pipe: int; $32
(W)     mul (1|M0)               r24.0<1>:d    r91.0<0;1,0>:d    0x280:uw              {I@6}         //  ALU pipe: int; $42
        mov (16|M0)              r15.0<2>:d    r11.0<1;1,0>:d                   {I@6}                //  ALU pipe: int; $27
        mov (16|M16)             r17.0<2>:d    r12.0<1;1,0>:d                                        //  ALU pipe: int; $28
(W)     mach (1|M0)              r23.0<1>:d    r3.12<0;1,0>:ud   0x280:ud                            //  ALU pipe: int; 
        mov (16|M0)              r15.1<2>:d    r13.0<1;1,0>:d                   {I@7}                //  ALU pipe: int; $29
        mov (16|M16)             r17.1<2>:d    r14.0<1;1,0>:d                                        //  ALU pipe: int; $30
(W)     add (1|M0)               r91.2<1>:d    r23.0<0;1,0>:d    r24.0<0;1,0>:d   {I@3}              //  ALU pipe: int; $44
        add (16|M0)              r104.0<1>:q   r19.0<2;1,0>:ud   -r15.0<1;1,0>:q  {I@3}              //  ALU pipe: int; $32
        add (16|M16)             r106.0<1>:q   r21.0<2;1,0>:ud   -r17.0<1;1,0>:q  {I@3}              //  ALU pipe: int; $32
        or (16|M0)               r25.0<1>:d    r91.2<0;1,0>:d    r104.1<2;1,0>:d  {I@2}              //  ALU pipe: int; $49
        or (16|M16)              r26.0<1>:d    r91.2<0;1,0>:d    r106.1<2;1,0>:d  {I@2}              //  ALU pipe: int; $50
        cmp (32|M0)   (lt)f2.0   null<1>:ud    r25.0<1;1,0>:ud   0x1:uw              {I@1}           //  ALU pipe: int; $51
(W)     mul (1|M0)               r91.1<1>:ud   r3.12<0;1,0>:ud   0x280:uw                            //  ALU pipe: int; $38
(f0.0)  sel (32|M0)              r7.0<1>:d     r2.6<0;1,0>:d     r3.0<0;1,0>:d                       //  ALU pipe: int; $15
(f0.0)  sel (32|M0)              r9.0<1>:d     r2.7<0;1,0>:d     r3.1<0;1,0>:d                       //  ALU pipe: int; $16
(W)     mov (1|M0)               r91.3<1>:df   0x41F0000000000000:df                                 //  ALU pipe: long; $52
(W)     mov (1|M0)               r91.4<1>:df   0xBCF0000000000000:df                                 //  ALU pipe: long; $53
(W)     mov (1|M0)               r91.5<1>:df   0x3FF0000000000000:df                                 //  ALU pipe: long; $54
(W)     mov (1|M0)               r91.5<1>:d    r91.2<0;1,0>:d                                        //  ALU pipe: int; $46
        mov (16|M0)              r87.0<1>:d    r104.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $33
        mov (16|M0)              r89.0<1>:d    r104.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $35
        mov (16|M16)             r88.0<1>:d    r106.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $34
        mov (16|M16)             r90.0<1>:d    r106.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $36
(W)     mov (1|M0)               r91.4<1>:d    r91.1<0;1,0>:d                   {I@7}                //  ALU pipe: int; $45
        mov (16|M0)              r100.0<2>:d   r7.0<1;1,0>:d                    {I@7}                //  ALU pipe: int; $19
        mov (16|M16)             r102.0<2>:d   r8.0<1;1,0>:d                                         //  ALU pipe: int; $20
        mov (16|M0)              r100.1<2>:d   r9.0<1;1,0>:d                    {I@7}                //  ALU pipe: int; $21
        mov (16|M16)             r102.1<2>:d   r10.0<1;1,0>:d                                        //  ALU pipe: int; $22
(f2.0)  goto (32|M0)                         _0_016            _0_016                                //  ALU pipe: int; $55
// B003: [inDivergent],  Preds:{B002},  Succs:{B008}
_0_017:
(W)     mov (1|M0)               r1.0<1>:df    r91.2<0;1,0>:uq                  {I@6}                //  ALU pipe: long; $58
        mov (16|M0)              r9.0<1>:d     r104.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $65
(W)     mov (1|M0)               r2.0<2>:f     r1.0<0;1,0>:df                   {L@1}                //  ALU pipe: float; $59
        mov (16|M16)             r10.0<1>:d    r106.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $66
(W)     math.inv (1|M0)          r3.0<1>:f     r2.0<0;1,0>:f                    {F@1}                //  ALU pipe: math; $60
(W)     mov (1|M0)               r4.0<1>:df    r3.0<0;1,0>:f                    {M@1}                //  ALU pipe: long; $61
        mov (16|M0)              r11.0<2>:ud   r9.0<1;1,0>:ud                   {Compacted,I@2}      //  ALU pipe: int; $67
(W)     mad (1|M0)               r5.0<1>:df    r91.5<0;0>:df     r4.0<0;0>:df      -r1.0<0>:df      {L@1} //  ALU pipe: long; $62
        mov (16|M16)             r15.0<2>:ud   r10.0<1;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $67
(W)     add (1|M0)               r7.0<1>:df    r5.0<0;1,0>:df    r91.4<0;1,0>:df  {L@1}              //  ALU pipe: long; $63
        mov (16|M0)              r13.0<1>:df   r11.0<2;1,0>:ud                  {I@2}                //  ALU pipe: long; $67
(W)     mad (1|M0)               r8.0<1>:df    r4.0<0;0>:df      r7.0<0;0>:df      r4.0<0>:df       {L@2} //  ALU pipe: long; $64
        mov (16|M16)             r17.0<1>:df   r15.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $67
        mul (16|M0)              r19.0<1>:df   r8.0<0;1,0>:df    r13.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $68
        mul (16|M16)             r21.0<1>:df   r8.0<0;1,0>:df    r17.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $68
        mov (16|M0)              r23.0<2>:ud   r19.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $69
        mov (16|M16)             r27.0<2>:ud   r21.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $69
        mov (16|M0)              r25.0<1>:ud   r23.0<2;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $69
        mov (16|M16)             r26.0<1>:ud   r27.0<2;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $69
(W)     mul (16|M0)              acc0.0<1>:d   r25.0<1;1,0>:d    r91.8<0;1,0>:uw  {I@2}              //  ALU pipe: int; $70
        macl (16|M0)             r29.0<1>:d    r25.0<1;1,0>:d    r91.4<0;1,0>:d   {Compacted}        //  ALU pipe: int; $70
(W)     mul (16|M16)             acc0.0<1>:d   r26.0<1;1,0>:d    r91.8<0;1,0>:uw  {I@3}              //  ALU pipe: int; $70
        macl (16|M16)            r30.0<1>:d    r26.0<1;1,0>:d    r91.4<0;1,0>:d   {Compacted}        //  ALU pipe: int; $71
        add (32|M0)              r31.0<1>:d    r9.0<1;1,0>:d     -r29.0<1;1,0>:d  {Compacted,I@1}    //  ALU pipe: int; $71
        mov (16|M0)              r33.0<2>:ud   r31.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $73
        mov (16|M16)             r38.0<2>:ud   r32.0<1;1,0>:ud                                       //  ALU pipe: int; $73
        mov (16|M0)              r43.0<1>:df   r104.0<2;1,0>:ud                                      //  ALU pipe: long; $74
        mov (16|M16)             r45.0<1>:df   r106.0<2;1,0>:ud                                      //  ALU pipe: long; $74
        mov (16|M0)              r36.0<1>:df   r33.0<2;1,0>:ud                  {I@2}                //  ALU pipe: long; $73
        mov (16|M16)             r40.0<1>:df   r38.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $73
        mad (16|M0)              r47.0<1>:df   r43.0<1;0>:df     r36.0<1;0>:df     r91.3<0>:df      {Compacted,L@2} //  ALU pipe: long; $75 R{} IR{}{O:5,E:2,O:5,},  R{r91,} IR{}{E:6,O:2,},  {BC=1}
        mad (16|M16)             r49.0<1>:df   r45.0<1;0>:df     r40.0<1;0>:df     r91.3<0>:df      {Compacted,L@2} //  ALU pipe: long; $75
        mul (16|M0)              r51.0<1>:df   r8.0<0;1,0>:df    r47.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $76
        mul (16|M16)             r53.0<1>:df   r8.0<0;1,0>:df    r49.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $76
        mov (16|M0)              r55.0<1>:uq   r51.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $77
        mov (16|M16)             r57.0<1>:uq   r53.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $77
        shr (16|M0)              r63.0<1>:uq   r55.0<1;1,0>:uq   32:w               {I@2}            //  ALU pipe: int; $81
        shr (16|M16)             r65.0<1>:uq   r57.0<1;1,0>:uq   32:w               {I@2}            //  ALU pipe: int; $81
        mov (16|M0)              r67.0<1>:d    r63.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $82
        mov (16|M16)             r68.0<1>:d    r65.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $83
        cmp (32|M0)   (eq)f1.0   null<1>:d     r67.0<1;1,0>:d    0:w               {I@1}             //  ALU pipe: int; $88
        mov (16|M0)              r69.0<1>:d    r63.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $84
        mov (16|M16)             r70.0<1>:d    r65.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $85
        mov (16|M0)              r61.0<1>:d    r55.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $80
(f1.0)  cmp (32|M0)   (eq)f1.0   null<1>:d     r69.0<1;1,0>:d    0:w               {I@2}             //  ALU pipe: int; $89
        mov (16|M16)             r62.0<1>:d    r57.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $80
(W)     mul (16|M0)              acc0.0<1>:d   r61.0<1;1,0>:d    r91.4<0;1,0>:uw  {I@3}              //  ALU pipe: int; $91
        macl (16|M0)             r73.0<1>:d    r61.0<1;1,0>:d    r91.2<0;1,0>:d   {Compacted}        //  ALU pipe: int; $91
(W)     mul (16|M16)             acc0.0<1>:d   r62.0<1;1,0>:d    r91.4<0;1,0>:uw  {I@3}              //  ALU pipe: int; $91
(~f1.0) sel (32|M0)              r75.0<1>:d    r91.4<0;1,0>:d    0:w                                 //  ALU pipe: int; $92
        macl (16|M16)            r74.0<1>:d    r62.0<1;1,0>:d    r91.2<0;1,0>:d   {Compacted}        //  ALU pipe: int; $92
(W)     and (1|M0)               r6.0<1>:d     r91.1<0;1,0>:d    -128:w               {Compacted}    //  ALU pipe: int; $101
        mov (16|M0)              r59.0<1>:d    r55.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $78
        add (32|M0)              r80.0<1>:d    r73.0<1;1,0>:d    r75.0<1;1,0>:d   {Compacted,I@3}    //  ALU pipe: int; $93
        mov (16|M16)             r60.0<1>:d    r57.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $79
(W)     mul (16|M0)              acc0.0<1>:ud  r59.0<1;1,0>:ud   r6.0<0;1,0>:uw   {I@3}              //  ALU pipe: int; $102
        add3 (32|M0)             r82.0<1>:d    r9.0<1;0>:d       -r29.0<1;0>:d     -r80.0<1>:d      {I@3} //  ALU pipe: int; $94
        macl (16|M0)             r7.0<1>:ud    r59.0<1;1,0>:ud   r6.0<0;1,0>:ud                      //  ALU pipe: int; $103
(W)     mul (16|M16)             acc0.0<1>:ud  r60.0<1;1,0>:ud   r6.0<0;1,0>:uw   {I@4}              //  ALU pipe: int; $103
        macl (16|M16)            r10.0<1>:ud   r60.0<1;1,0>:ud   r6.0<0;1,0>:ud                      //  ALU pipe: int; $104
(W)     mul (16|M0)              acc0.0<1>:ud  r59.0<1;1,0>:ud   r6.0<0;1,0>:uw                      //  ALU pipe: int; $104
        mach (16|M0)             r13.0<1>:d    r59.0<1;1,0>:ud   r6.0<0;1,0>:ud                      //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r60.0<1;1,0>:ud   r6.0<0;1,0>:uw                      //  ALU pipe: int; $104
        mach (16|M16)            r14.0<1>:d    r60.0<1;1,0>:ud   r6.0<0;1,0>:ud                      //  ALU pipe: int; $106
        mov (32|M0)              r84.0<1>:f    r87.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $95
        mov (32|M0)              r15.0<1>:d    0:w                               {Compacted}         //  ALU pipe: int; $107
        mov (16|M0)              r8.0<2>:ud    r7.0<1;1,0>:ud                   {Compacted,I@7}      //  ALU pipe: int; $103
        mov (16|M16)             r11.0<2>:ud   r10.0<1;1,0>:ud                  {Compacted,I@7}      //  ALU pipe: int; $104
        mov (16|M0)              r1.0<2>:d     r84.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $97
        mov (16|M16)             r4.0<2>:d     r85.0<1;1,0>:d                                        //  ALU pipe: int; $98
        add (16|M0)              r8.1<2>:d     r13.0<1;1,0>:d    r15.0<1;1,0>:d   {I@5}              //  ALU pipe: int; $108
        add (16|M16)             r11.1<2>:d    r14.0<1;1,0>:d    r16.0<1;1,0>:d                      //  ALU pipe: int; $109
        mov (16|M0)              r1.1<2>:d     r82.0<1;1,0>:d                                        //  ALU pipe: int; $99
        mov (16|M16)             r4.1<2>:d     r83.0<1;1,0>:d                                        //  ALU pipe: int; $100
        add (16|M0)              r17.0<1>:q    r1.0<1;1,0>:q     -r8.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $110
        add (16|M16)             r19.0<1>:q    r4.0<1;1,0>:q     -r11.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $110
        mov (16|M0)              r21.0<1>:d    r17.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $111
        mov (16|M16)             r22.0<1>:d    r19.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $112
        cmp (32|M0)   (ge)f3.0   null<1>:ud    r21.0<1;1,0>:ud   r91.1<0;1,0>:ud  {I@1}              //  ALU pipe: int; $122
        mov (16|M0)              r23.0<1>:d    r17.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $113
        mov (16|M16)             r24.0<1>:d    r19.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $114
(f3.0)  cmp (32|M0)   (eq)f3.0   null<1>:d     r23.0<1;1,0>:d    r91.2<0;1,0>:d   {I@1}              //  ALU pipe: int; $123
(~f3.0) cmp (32|M0)   (gt)f3.0   null<1>:ud    r23.0<1;1,0>:ud   r91.2<0;1,0>:ud                     //  ALU pipe: int; $125
(W)     mov (1|M0)               r35.0<1>:hf   0xFFFF:hf                                             //  ALU pipe: float; $127
        mov (16|M0)              r71.0<1>:d    r55.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $86
        mov (16|M16)             r72.0<1>:d    r57.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $87
(f3.0)  sel (32|M0)              r36.0<1>:d    r35.0<0;1,0>:w    0:w               {F@1}             //  ALU pipe: int; $127
        add (32|M0)              r27.0<1>:d    r71.0<1;1,0>:d    r25.0<1;1,0>:d   {Compacted,I@2}    //  ALU pipe: int; $115
        mov (32|M0)              r29.0<1>:f    r59.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $116
        mov (16|M0)              r38.0<2>:ud   r36.0<1;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $128
        mov (16|M16)             r42.0<2>:ud   r37.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $128
        mov (16|M0)              r31.0<2>:d    r29.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $118
        mov (16|M16)             r33.0<2>:d    r30.0<1;1,0>:d                                        //  ALU pipe: int; $119
        mov (16|M0)              r40.0<1>:q    r38.0<2;1,0>:d                   {I@4}                //  ALU pipe: int; $128
        mov (16|M16)             r44.0<1>:q    r42.0<2;1,0>:d                   {I@4}                //  ALU pipe: int; $128
        mov (16|M0)              r31.1<2>:d    r27.0<1;1,0>:d                                        //  ALU pipe: int; $120
        mov (16|M16)             r33.1<2>:d    r28.0<1;1,0>:d                                        //  ALU pipe: int; $121
        add (16|M0)              r108.0<1>:q   r31.0<1;1,0>:q    -r40.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $129
        add (16|M16)             r110.0<1>:q   r33.0<1;1,0>:q    -r44.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $129
        goto (32|M0)                         _0_016            _0_018                                // $130
// B004: [inDivergent],  Preds:{B002},  Succs:{B005, B006}
_0_016:
        join (32|M0)                         _0_018                                                  // 
L2080:
(W)     cmp (32|M0)   (eq)f1.0   null<1>:d     r3.12<0;1,0>:d    0:w                                 //  ALU pipe: int; $132
(W&f1.0) jmpi                                _0_019                                                  //  ALU pipe: int; $133
// B005: [inDivergent],  Preds:{B004},  Succs:{B007}
_0_020:
        mov (16|M0)              r1.0<1>:d     r104.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $135
        mov (16|M16)             r2.0<1>:d     r106.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $135
(W)     mov (1|M0)               r3.0<2>:d     r91.2<0;1,0>:q                                        //  ALU pipe: int; $136
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $137
(W)     mov (1|M0)               r4.0<1>:f     r3.0<0;1,0>:ud                   {A@1}                //  ALU pipe: float; $138
(W)     mov (1|M0)               r11.0<1>:f    0xB4C00000:f                               {Compacted} //  ALU pipe: float; $143
(W)     math.inv (1|M0)          r10.0<1>:f    r4.0<0;1,0>:f                    {F@2}                //  ALU pipe: math; $142
        mov (32|M0)              r7.0<1>:f     r1.0<1;1,0>:ud                                        //  ALU pipe: float; $141
(W)     mad (1|M0)               r12.0<1>:f    r10.0<0;0>:f      r11.0<0;0>:f      r10.0<0>:f       {Compacted,A@1} //  ALU pipe: float; $143
        mov (32|M0)              r15.0<1>:ud   r7.0<1;1,0>:f                    {F@2}                //  ALU pipe: int; $145
        mul (32|M0)              r13.0<1>:f    r7.0<1;1,0>:f     r12.0<0;1,0>:f   {Compacted,F@1}    //  ALU pipe: float; $144
(W)     mov (1|M0)               r5.0<1>:ud    r4.0<0;1,0>:f                                         //  ALU pipe: int; $139
        add (32|M0)              r17.0<1>:d    r1.0<1;1,0>:d     -r15.0<1;1,0>:d  {Compacted,I@2}    //  ALU pipe: int; $146
        mov (32|M0)              r19.0<1>:ud   r13.0<1;1,0>:f                   {F@1}                //  ALU pipe: int; $147
(W)     add (1|M0)               r6.0<1>:d     r3.0<0;1,0>:d     -r5.0<0;1,0>:d   {I@3}              //  ALU pipe: int; $140
        mov (32|M0)              r27.0<1>:f    r19.0<1;1,0>:ud                  {I@2}                //  ALU pipe: float; $150
        mov (32|M0)              r23.0<1>:f    r17.0<1;1,0>:ud                                       //  ALU pipe: float; $149
(W)     mov (1|M0)               r22.0<1>:f    r6.0<0;1,0>:ud                   {I@1}                //  ALU pipe: float; $148
        mad (32|M0)              acc0.0<1>:f   r7.0<1;0>:f       r27.0<1;0>:f      -r4.0<0>:f       {F@3} //  ALU pipe: float; $152
        mad (32|M0)              acc2.0<1>:f   r23.0<1;0>:f      r27.0<1;0>:f      -r22.0<0>:f      {F@2} //  ALU pipe: float; $154
        add (32|M0)              acc0.0<1>:f   acc0.0<1;1,0>:f   acc2.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $155
        mul (32|M0)              r29.0<1>:f    r12.0<0;1,0>:f    acc0.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $156
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $157
        mov (32|M0)              r31.0<1>:ud   r29.0<1;1,0>:f                   {A@1}                //  ALU pipe: int; $158
        add (32|M0)              r33.0<1>:d    r31.0<1;1,0>:d    r19.0<1;1,0>:d   {Compacted,I@1}    //  ALU pipe: int; $159
(W)     mul (16|M0)              acc0.0<1>:d   r33.0<1;1,0>:d    r3.0<0;1,0>:uw   {I@1}              //  ALU pipe: int; $160
        macl (16|M0)             r35.0<1>:d    r33.0<1;1,0>:d    r3.0<0;1,0>:d    {Compacted}        //  ALU pipe: int; $160
(W)     mul (16|M16)             acc0.0<1>:d   r34.0<1;1,0>:d    r3.0<0;1,0>:uw                      //  ALU pipe: int; $160
        macl (16|M16)            r36.0<1>:d    r34.0<1;1,0>:d    r3.0<0;1,0>:d    {Compacted}        //  ALU pipe: int; $161
        add (32|M0)              r37.0<1>:d    r1.0<1;1,0>:d     -r35.0<1;1,0>:d  {Compacted,I@1}    //  ALU pipe: int; $161
        cmp (32|M0)   (ge)f3.0   r40.0<1>:ud   r37.0<1;1,0>:ud   r3.0<0;1,0>:ud   {I@1}              //  ALU pipe: int; $162
        add3 (32|M0)             r92.0<1>:d    r31.0<1;0>:d      r19.0<1;0>:d      -r40.0<1>:d      {Compacted,I@1} //  ALU pipe: int; $163
(W)     jmpi                                 _0_021                                                  // $164
// B006: [inDivergent],  Preds:{B004},  Succs:{B007}
_0_019:
        mov (32|M0)              r92.0<1>:d    -1:w                               {Compacted}        //  ALU pipe: int; $166
// B007: [inDivergent],  Preds:{B006, B005},  Succs:{B008}
_0_021:
        mov (16|M0)              r1.0<2>:ud    r92.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $168
        mov (16|M16)             r4.0<2>:ud    r93.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $168
        mov (16|M0)              r108.0<1>:q   r1.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $168
        mov (16|M16)             r110.0<1>:q   r4.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $168
// B008: Preds:{B007, B003},  Succs:{B009, B010}
_0_018:
        join (32|M0)                         L2608                                                   // 
L2608:
        cmp (32|M0)   (lt)f3.0   null<1>:ud    r89.0<1;1,0>:ud   0x1:uw                              //  ALU pipe: int; $170
(f3.0)  goto (32|M0)                         _0_022            _0_022                                //  ALU pipe: int; $171
// B009: [inDivergent],  Preds:{B008},  Succs:{B011}
_0_023:
        shr (16|M0)              r1.0<1>:uq    r104.0<1;1,0>:uq  32:w                                //  ALU pipe: int; $173
(W)     mul (16|M0)              acc0.0<1>:ud  r87.0<1;1,0>:ud   0xCCCD:uw                           //  ALU pipe: int; $178
        shr (16|M16)             r4.0<1>:uq    r106.0<1;1,0>:uq  32:w                                //  ALU pipe: int; $173
        macl (16|M0)             r10.0<1>:ud   r87.0<1;1,0>:ud   0xCCCCCCCD:ud                       //  ALU pipe: int; $179
(W)     mul (16|M16)             acc0.0<1>:ud  r88.0<1;1,0>:ud   0xCCCD:uw                           //  ALU pipe: int; $179
        mov (16|M0)              r6.0<1>:d     r1.0<2;1,0>:d                    {I@5}                //  ALU pipe: int; $174
        macl (16|M16)            r13.0<1>:ud   r88.0<1;1,0>:ud   0xCCCCCCCD:ud                       //  ALU pipe: int; $180
(W)     mul (16|M0)              acc0.0<1>:ud  r87.0<1;1,0>:ud   0xCCCD:uw                           //  ALU pipe: int; $180
        mov (16|M16)             r7.0<1>:d     r4.0<2;1,0>:d                    {I@6}                //  ALU pipe: int; $175
        mach (16|M0)             r16.0<1>:d    r87.0<1;1,0>:ud   0xCCCCCCCD:ud                       //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r88.0<1;1,0>:ud   0xCCCD:uw                           //  ALU pipe: int; $180
        mach (16|M16)            r17.0<1>:d    r88.0<1;1,0>:ud   0xCCCCCCCD:ud                       //  ALU pipe: int; $182
(W)     mul (16|M0)              acc0.0<1>:ud  r6.0<1;1,0>:ud    0xCCCD:uw              {I@7}        //  ALU pipe: int; $186
        macl (16|M0)             r20.0<1>:ud   r6.0<1;1,0>:ud    0xCCCCCCCD:ud                       //  ALU pipe: int; $187
(W)     mul (16|M16)             acc0.0<1>:ud  r7.0<1;1,0>:ud    0xCCCD:uw              {I@6}        //  ALU pipe: int; $187
        mov (16|M0)              r8.0<1>:d     r1.1<2;1,0>:d                    {Compacted}          //  ALU pipe: int; $176
        macl (16|M16)            r23.0<1>:ud   r7.0<1;1,0>:ud    0xCCCCCCCD:ud                       //  ALU pipe: int; $188
(W)     mul (16|M0)              acc0.0<1>:ud  r6.0<1;1,0>:ud    0xCCCD:uw                           //  ALU pipe: int; $188
        mov (16|M16)             r9.0<1>:d     r4.1<2;1,0>:d                    {Compacted}          //  ALU pipe: int; $177
        mach (16|M0)             r26.0<1>:d    r6.0<1;1,0>:ud    0xCCCCCCCD:ud                       //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r7.0<1;1,0>:ud    0xCCCD:uw                           //  ALU pipe: int; $188
        mov (32|M0)              r18.0<1>:d    0x0:uw                                                //  ALU pipe: int; $183
        mach (16|M16)            r27.0<1>:d    r7.0<1;1,0>:ud    0xCCCCCCCD:ud                       //  ALU pipe: int; $190
(W)     mul (16|M0)              acc0.0<1>:d   r8.0<1;1,0>:d     0xCCCD:uw              {I@7}        //  ALU pipe: int; $191
        macl (16|M0)             r28.0<1>:d    r8.0<1;1,0>:d     0xCCCCCCCD:ud                       //  ALU pipe: int; $191
(W)     mul (16|M16)             acc0.0<1>:d   r9.0<1;1,0>:d     0xCCCD:uw              {I@7}        //  ALU pipe: int; $191
        mov (16|M0)              r11.0<2>:ud   r10.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $179
        mov (16|M16)             r14.0<2>:ud   r13.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $180
        macl (16|M16)            r29.0<1>:d    r9.0<1;1,0>:d     0xCCCCCCCD:ud                       //  ALU pipe: int; $192
        add (16|M0)              r11.1<2>:d    r16.0<1;1,0>:d    r18.0<1;1,0>:d   {I@7}              //  ALU pipe: int; $184
        add (16|M16)             r14.1<2>:d    r17.0<1;1,0>:d    r19.0<1;1,0>:d                      //  ALU pipe: int; $185
(W)     mul (16|M0)              acc0.0<1>:ud  r87.0<1;1,0>:ud   0xCCCC:uw                           //  ALU pipe: int; $198
        macl (16|M0)             r40.0<1>:ud   r87.0<1;1,0>:ud   0xCCCCCCCC:ud                       //  ALU pipe: int; $199
(W)     mul (16|M16)             acc0.0<1>:ud  r88.0<1;1,0>:ud   0xCCCC:uw                           //  ALU pipe: int; $199
        mov (16|M0)              r21.0<2>:ud   r20.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $187
        mov (16|M16)             r24.0<2>:ud   r23.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $188
        shr (16|M0)              r30.0<1>:uq   r11.0<1;1,0>:uq   32:w               {I@7}            //  ALU pipe: int; $194
        shr (16|M16)             r32.0<1>:uq   r14.0<1;1,0>:uq   32:w               {I@7}            //  ALU pipe: int; $194
        macl (16|M16)            r43.0<1>:ud   r88.0<1;1,0>:ud   0xCCCCCCCC:ud                       //  ALU pipe: int; $200
        add (16|M0)              r21.1<2>:d    r26.0<1;1,0>:d    r28.0<1;1,0>:d                      //  ALU pipe: int; $192
        add (16|M16)             r24.1<2>:d    r27.0<1;1,0>:d    r29.0<1;1,0>:d                      //  ALU pipe: int; $193
(W)     mul (16|M0)              acc0.0<1>:ud  r87.0<1;1,0>:ud   0xCCCC:uw                           //  ALU pipe: int; $200
        mach (16|M0)             r46.0<1>:d    r87.0<1;1,0>:ud   0xCCCCCCCC:ud                       //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r88.0<1;1,0>:ud   0xCCCC:uw                           //  ALU pipe: int; $200
        add (16|M0)              r34.0<1>:q    r21.0<1;1,0>:q    r30.0<1;1,0>:q   {Compacted,I@5}    //  ALU pipe: int; $195
        add (16|M16)             r36.0<1>:q    r24.0<1;1,0>:q    r32.0<1;1,0>:q   {Compacted,I@5}    //  ALU pipe: int; $195
        mach (16|M16)            r47.0<1>:d    r88.0<1;1,0>:ud   0xCCCCCCCC:ud                       //  ALU pipe: int; $202
(W)     mul (16|M0)              acc0.0<1>:ud  r6.0<1;1,0>:ud    0xCCCC:uw                           //  ALU pipe: int; $213
        macl (16|M0)             r60.0<1>:ud   r6.0<1;1,0>:ud    0xCCCCCCCC:ud                       //  ALU pipe: int; $214
(W)     mul (16|M16)             acc0.0<1>:ud  r7.0<1;1,0>:ud    0xCCCC:uw                           //  ALU pipe: int; $214
        mov (16|M0)              r38.0<1>:d    r34.0<2;1,0>:d                   {Compacted,I@6}      //  ALU pipe: int; $196
        mov (16|M16)             r39.0<1>:d    r36.0<2;1,0>:d                   {Compacted,I@6}      //  ALU pipe: int; $197
        macl (16|M16)            r63.0<1>:ud   r7.0<1;1,0>:ud    0xCCCCCCCC:ud                       //  ALU pipe: int; $215
(W)     mul (16|M0)              acc0.0<1>:ud  r6.0<1;1,0>:ud    0xCCCC:uw                           //  ALU pipe: int; $215
        mach (16|M0)             r66.0<1>:d    r6.0<1;1,0>:ud    0xCCCCCCCC:ud                       //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r7.0<1;1,0>:ud    0xCCCC:uw                           //  ALU pipe: int; $215
        mov (32|M0)              r50.0<1>:d    0:w                               {Compacted}         //  ALU pipe: int; $207
        mov (32|M0)              r48.0<1>:f    r38.0<1;1,0>:f                   {Compacted,I@6}      //  ALU pipe: float; $206
        mach (16|M16)            r67.0<1>:d    r7.0<1;1,0>:ud    0xCCCCCCCC:ud                       //  ALU pipe: int; $217
(W)     mul (16|M0)              acc0.0<1>:d   r8.0<1;1,0>:d     0xCCCC:uw                           //  ALU pipe: int; $218
        macl (16|M0)             r68.0<1>:d    r8.0<1;1,0>:d     0xCCCCCCCC:ud                       //  ALU pipe: int; $218
(W)     mul (16|M16)             acc0.0<1>:d   r9.0<1;1,0>:d     0xCCCC:uw                           //  ALU pipe: int; $218
        mov (16|M0)              r41.0<2>:ud   r40.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $199
        mov (16|M16)             r44.0<2>:ud   r43.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $200
        mov (16|M0)              r52.0<2>:d    r48.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $208
        mov (16|M16)             r54.0<2>:d    r49.0<1;1,0>:d                                        //  ALU pipe: int; $209
        macl (16|M16)            r69.0<1>:d    r9.0<1;1,0>:d     0xCCCCCCCC:ud                       //  ALU pipe: int; $219
        add (16|M0)              r41.1<2>:d    r46.0<1;1,0>:d    r18.0<1;1,0>:d                      //  ALU pipe: int; $204
        add (16|M16)             r44.1<2>:d    r47.0<1;1,0>:d    r19.0<1;1,0>:d                      //  ALU pipe: int; $205
        mov (16|M0)              r52.1<2>:d    r50.0<1;1,0>:d                                        //  ALU pipe: int; $210
        mov (16|M16)             r54.1<2>:d    r51.0<1;1,0>:d                                        //  ALU pipe: int; $211
        shr (16|M0)              r70.0<1>:uq   r34.0<1;1,0>:uq   32:w                                //  ALU pipe: int; $221
        shr (16|M16)             r72.0<1>:uq   r36.0<1;1,0>:uq   32:w                                //  ALU pipe: int; $221
        mov (16|M0)              r61.0<2>:ud   r60.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $214
        mov (16|M16)             r64.0<2>:ud   r63.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $215
        add (16|M0)              r56.0<1>:q    r41.0<1;1,0>:q    r52.0<1;1,0>:q   {Compacted,I@6}    //  ALU pipe: int; $212
        add (16|M16)             r58.0<1>:q    r44.0<1;1,0>:q    r54.0<1;1,0>:q   {Compacted,I@6}    //  ALU pipe: int; $212
        add (16|M0)              r61.1<2>:d    r66.0<1;1,0>:d    r68.0<1;1,0>:d                      //  ALU pipe: int; $219
        add (16|M16)             r64.1<2>:d    r67.0<1;1,0>:d    r69.0<1;1,0>:d                      //  ALU pipe: int; $220
        shr (16|M0)              r78.0<1>:uq   r56.0<1;1,0>:uq   32:w               {I@4}            //  ALU pipe: int; $223
        shr (16|M16)             r80.0<1>:uq   r58.0<1;1,0>:uq   32:w               {I@4}            //  ALU pipe: int; $223
        add (16|M0)              r74.0<1>:q    r61.0<1;1,0>:q    r70.0<1;1,0>:q   {Compacted,I@4}    //  ALU pipe: int; $222
        add (16|M16)             r76.0<1>:q    r64.0<1;1,0>:q    r72.0<1;1,0>:q   {Compacted,I@4}    //  ALU pipe: int; $222
        add (16|M0)              r82.0<1>:q    r74.0<1;1,0>:q    r78.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $224
        add (16|M16)             r84.0<1>:q    r76.0<1;1,0>:q    r80.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $224
        shr (16|M0)              r112.0<1>:uq  r82.0<1;1,0>:uq   9:w               {I@2}             //  ALU pipe: int; $225
        shr (16|M16)             r114.0<1>:uq  r84.0<1;1,0>:uq   9:w               {I@2}             //  ALU pipe: int; $225
        goto (32|M0)                         _0_022            _0_024                                // $226
// B010: [inDivergent],  Preds:{B008},  Succs:{B011}
_0_022:
        join (32|M0)                         _0_024                                                  // 
L3888:
        mov (16|M0)              r1.0<1>:d     r104.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $228
        mov (16|M16)             r2.0<1>:d     r106.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $228
(W)     mul (16|M0)              acc0.0<1>:ud  r1.0<1;1,0>:ud    0xCCCD:uw              {I@2}        //  ALU pipe: int; $229
        mach (16|M0)             r4.0<1>:ud    r1.0<1;1,0>:ud    0xCCCCCCCD:ud                       //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r2.0<1;1,0>:ud    0xCCCD:uw              {I@3}        //  ALU pipe: int; $229
        mach (16|M16)            r5.0<1>:ud    r2.0<1;1,0>:ud    0xCCCCCCCD:ud                       //  ALU pipe: int; $230
        shr (32|M0)              r6.0<1>:ud    r4.0<1;1,0>:ud    9:w               {I@1}             //  ALU pipe: int; $230
        mov (16|M0)              r8.0<2>:ud    r6.0<1;1,0>:ud                   {Compacted,I@1}      //  ALU pipe: int; $231
        mov (16|M16)             r10.0<2>:ud   r7.0<1;1,0>:ud                   {Compacted}          //  ALU pipe: int; $231
        mov (16|M0)              r112.0<1>:q   r8.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $231
        mov (16|M16)             r114.0<1>:q   r10.0<2;1,0>:ud                  {I@2}                //  ALU pipe: int; $231
// B011: Preds:{B010, B009},  Succs:{B012, B013}
_0_024:
        join (32|M0)                         L4048                                                   // 
L4048:
        or (16|M0)               r1.0<1>:d     r112.1<2;1,0>:d   r91.0<0;1,0>:d   {Compacted,I@3}    //  ALU pipe: int; $237
        or (16|M16)              r2.0<1>:d     r114.1<2;1,0>:d   r91.0<0;1,0>:d   {Compacted,I@3}    //  ALU pipe: int; $238
        cmp (32|M0)   (lt)f2.0   null<1>:ud    r1.0<1;1,0>:ud    0x1:uw              {I@1}           //  ALU pipe: int; $239
        mov (16|M0)              r94.0<1>:d    r112.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $233
        mov (16|M16)             r95.0<1>:d    r114.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $234
        mov (16|M0)              r96.0<1>:d    r112.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $235
        mov (16|M16)             r97.0<1>:d    r114.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $236
(f2.0)  goto (32|M0)                         _0_025            _0_025                                //  ALU pipe: int; $240
// B012: [inDivergent],  Preds:{B011},  Succs:{B017}
_0_026:
(W)     mov (1|M0)               r1.0<1>:q     r3.12<0;1,0>:d                                        //  ALU pipe: int; $242
        mov (16|M0)              r11.0<1>:d    r112.1<2;1,0>:d                                       //  ALU pipe: int; $250
(W)     mov (1|M0)               r3.0<1>:df    r1.0<0;1,0>:uq                   {I@2}                //  ALU pipe: long; $243
        mov (16|M16)             r12.0<1>:d    r114.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $251
(W)     mov (1|M0)               r4.0<2>:f     r3.0<0;1,0>:df                   {L@1}                //  ALU pipe: float; $244
        mov (16|M0)              r13.0<2>:ud   r11.0<1;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $252
(W)     math.inv (1|M0)          r5.0<1>:f     r4.0<0;1,0>:f                    {F@1}                //  ALU pipe: math; $245
(W)     mov (1|M0)               r6.0<1>:df    r5.0<0;1,0>:f                    {M@1}                //  ALU pipe: long; $246
        mov (16|M16)             r17.0<2>:ud   r12.0<1;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $252
(W)     mad (1|M0)               r7.0<1>:df    r91.5<0;0>:df     r6.0<0;0>:df      -r3.0<0>:df      {L@1} //  ALU pipe: long; $247
        mov (16|M0)              r15.0<1>:df   r13.0<2;1,0>:ud                  {I@2}                //  ALU pipe: long; $252
(W)     add (1|M0)               r9.0<1>:df    r7.0<0;1,0>:df    r91.4<0;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $248
        mov (16|M16)             r19.0<1>:df   r17.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $252
(W)     mad (1|M0)               r10.0<1>:df   r6.0<0;0>:df      r9.0<0;0>:df      r6.0<0>:df       {L@2} //  ALU pipe: long; $249
        mov (16|M0)              r45.0<1>:df   r112.0<2;1,0>:ud                                      //  ALU pipe: long; $259
        mul (16|M0)              r21.0<1>:df   r10.0<0;1,0>:df   r15.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $253
        mul (16|M16)             r23.0<1>:df   r10.0<0;1,0>:df   r19.0<1;1,0>:df  {Compacted}        //  ALU pipe: long; $253
        mov (16|M0)              r25.0<2>:ud   r21.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $254
        mov (16|M16)             r29.0<2>:ud   r23.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $254
        mov (16|M0)              r27.0<1>:ud   r25.0<2;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $254
        mov (16|M16)             r28.0<1>:ud   r29.0<2;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $254
(W)     mul (16|M0)              acc0.0<1>:d   r3.12<0;1,0>:d    r27.0<2;1,0>:uw  {I@2}              //  ALU pipe: int; $255
        macl (16|M0)             r31.0<1>:d    r3.12<0;1,0>:d    r27.0<1;1,0>:d   {Compacted}        //  ALU pipe: int; $255
(W)     mul (16|M16)             acc0.0<1>:d   r3.12<0;1,0>:d    r28.0<2;1,0>:uw  {I@3}              //  ALU pipe: int; $255
        macl (16|M16)            r32.0<1>:d    r3.12<0;1,0>:d    r28.0<1;1,0>:d   {Compacted}        //  ALU pipe: int; $256
        add (32|M0)              r33.0<1>:d    r11.0<1;1,0>:d    -r31.0<1;1,0>:d  {Compacted,I@1}    //  ALU pipe: int; $256
        mov (16|M0)              r35.0<2>:ud   r33.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $258
        mov (16|M16)             r40.0<2>:ud   r34.0<1;1,0>:ud                                       //  ALU pipe: int; $258
        mov (16|M16)             r47.0<1>:df   r114.0<2;1,0>:ud                                      //  ALU pipe: long; $259
        mov (16|M0)              r38.0<1>:df   r35.0<2;1,0>:ud                  {I@2}                //  ALU pipe: long; $258
        mov (16|M16)             r42.0<1>:df   r40.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $258
        mad (16|M0)              r49.0<1>:df   r45.0<1;0>:df     r38.0<1;0>:df     r91.3<0>:df      {Compacted,L@2} //  ALU pipe: long; $260
        mad (16|M16)             r51.0<1>:df   r47.0<1;0>:df     r42.0<1;0>:df     r91.3<0>:df      {Compacted,L@2} //  ALU pipe: long; $260
        mul (16|M0)              r53.0<1>:df   r10.0<0;1,0>:df   r49.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $261
        mul (16|M16)             r55.0<1>:df   r10.0<0;1,0>:df   r51.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $261
        mov (16|M0)              r57.0<1>:uq   r53.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $262
        mov (16|M16)             r59.0<1>:uq   r55.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $262
        mov (16|M0)              r63.0<1>:d    r57.1<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $265
        mov (16|M16)             r64.0<1>:d    r59.1<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $266
        mov (16|M0)              r61.0<1>:d    r57.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $263
(W)     cmp (32|M0)   (lt)f1.0   null<1>:d     r3.12<0;1,0>:d    0:w                                 //  ALU pipe: int; $268
        mov (16|M16)             r62.0<1>:d    r59.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $264
        cmp (32|M0)   (lt)f3.0   null<1>:ud    r63.0<1;1,0>:ud   0x1:uw              {I@4}           //  ALU pipe: int; $270
(W)     mul (16|M0)              acc0.0<1>:ud  r61.0<1;1,0>:ud   r3.24<0;1,0>:uw  {I@4}              //  ALU pipe: int; $279
        mov (16|M0)              r65.0<1>:d    r57.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $267
        mov (16|M16)             r66.0<1>:d    r59.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $267
        macl (16|M0)             r80.0<1>:ud   r61.0<1;1,0>:ud   r3.12<0;1,0>:ud                     //  ALU pipe: int; $280
(W)     mul (16|M16)             acc0.0<1>:ud  r62.0<1;1,0>:ud   r3.24<0;1,0>:uw  {I@6}              //  ALU pipe: int; $280
        macl (16|M16)            r83.0<1>:ud   r62.0<1;1,0>:ud   r3.12<0;1,0>:ud                     //  ALU pipe: int; $281
(W)     mul (16|M0)              acc0.0<1>:ud  r61.0<1;1,0>:ud   r3.24<0;1,0>:uw                     //  ALU pipe: int; $281
(~f3.0) sel (32|M0)              r70.0<1>:d    r3.12<0;1,0>:d    0:w                                 //  ALU pipe: int; $271
(f1.0)  sel (32|M0)              r68.0<1>:d    r65.0<1;1,0>:d    0:w               {I@6}             //  ALU pipe: int; $269
        mach (16|M0)             r1.0<1>:d     r61.0<1;1,0>:ud   r3.12<0;1,0>:ud                     //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r62.0<1;1,0>:ud   r3.24<0;1,0>:uw                     //  ALU pipe: int; $281
        mach (16|M16)            r2.0<1>:d     r62.0<1;1,0>:ud   r3.12<0;1,0>:ud                     //  ALU pipe: int; $283
        add3 (32|M0)             r72.0<1>:d    r68.0<1;0>:d      r33.0<1;0>:d      -r70.0<1>:d      {Compacted,I@4} //  ALU pipe: int; $272
        mov (32|M0)              r74.0<1>:f    r94.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $273
        mov (32|M0)              r4.0<1>:d     0:w                               {Compacted}         //  ALU pipe: int; $284
        mov (16|M0)              r81.0<2>:ud   r80.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $280
        mov (16|M16)             r84.0<2>:ud   r83.0<1;1,0>:ud                                       //  ALU pipe: int; $281
        mov (16|M0)              r76.0<2>:d    r74.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $275
        mov (16|M16)             r78.0<2>:d    r75.0<1;1,0>:d                                        //  ALU pipe: int; $276
        add (16|M0)              r81.1<2>:d    r1.0<1;1,0>:d     r4.0<1;1,0>:d    {I@5}              //  ALU pipe: int; $285
        add (16|M16)             r84.1<2>:d    r2.0<1;1,0>:d     r5.0<1;1,0>:d                       //  ALU pipe: int; $286
        mov (16|M0)              r76.1<2>:d    r72.0<1;1,0>:d                                        //  ALU pipe: int; $277
        mov (16|M16)             r78.1<2>:d    r73.0<1;1,0>:d                                        //  ALU pipe: int; $278
        add (16|M0)              r6.0<1>:q     r76.0<1;1,0>:q    -r81.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $287
        add (16|M16)             r8.0<1>:q     r78.0<1;1,0>:q    -r84.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $287
        mov (16|M0)              r10.0<1>:d    r6.0<2;1,0>:d                    {Compacted,I@2}      //  ALU pipe: int; $288
        mov (16|M16)             r11.0<1>:d    r8.0<2;1,0>:d                    {Compacted,I@2}      //  ALU pipe: int; $289
        cmp (32|M0)   (lt)f2.0   null<1>:ud    r10.0<1;1,0>:ud   r3.12<0;1,0>:ud  {I@1}              //  ALU pipe: int; $292
        mov (16|M0)              r12.0<1>:d    r6.1<2;1,0>:d                    {Compacted}          //  ALU pipe: int; $290
        mov (16|M16)             r13.0<1>:d    r8.1<2;1,0>:d                    {Compacted}          //  ALU pipe: int; $291
(f2.0)  cmp (32|M0)   (eq)f2.0   null<1>:d     r12.0<1;1,0>:d    r91.0<0;1,0>:d   {I@1}              //  ALU pipe: int; $293
(~f2.0) cmp (32|M0)   (lt)f2.0   null<1>:ud    r12.0<1;1,0>:ud   r91.0<0;1,0>:ud                     //  ALU pipe: int; $295
(~f2.0) sel (32|M0)              r14.0<1>:d    r3.12<0;1,0>:d    0:w                                 //  ALU pipe: int; $297
(~f2.0) sel (32|M0)              r16.0<1>:d    r91.0<0;1,0>:d    0:w                                 //  ALU pipe: int; $298
        mov (16|M0)              r18.0<2>:d    r14.0<1;1,0>:d                   {I@2}                //  ALU pipe: int; $301
        mov (16|M16)             r20.0<2>:d    r15.0<1;1,0>:d                                        //  ALU pipe: int; $302
        mov (16|M0)              r18.1<2>:d    r16.0<1;1,0>:d                   {I@3}                //  ALU pipe: int; $303
        mov (16|M16)             r20.1<2>:d    r17.0<1;1,0>:d                                        //  ALU pipe: int; $304
        add (16|M0)              r116.0<1>:q   r6.0<1;1,0>:q     -r18.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $305
        add (16|M16)             r118.0<1>:q   r8.0<1;1,0>:q     -r20.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $305
        goto (32|M0)                         _0_025            _0_027                                // $306
// B013: [inDivergent],  Preds:{B011},  Succs:{B014, B015}
_0_025:
        join (32|M0)                         _0_027                                                  // 
L5216:
(W)     cmp (32|M0)   (eq)f2.0   null<1>:d     r3.12<0;1,0>:d    0:w                                 //  ALU pipe: int; $308
(W&f2.0) jmpi                                _0_028                                                  //  ALU pipe: int; $309
// B014: [inDivergent],  Preds:{B013},  Succs:{B016}
_0_029:
        mov (16|M0)              r1.0<1>:d     r112.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $311
        mov (16|M16)             r2.0<1>:d     r114.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $311
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $312
(W)     mov (1|M0)               r4.0<1>:f     r3.12<0;1,0>:ud                  {A@1}                //  ALU pipe: float; $313
(W)     mov (1|M0)               r11.0<1>:f    0xB4C00000:f                                          //  ALU pipe: float; $318
(W)     math.inv (1|M0)          r10.0<1>:f    r4.0<0;1,0>:f                    {F@2}                //  ALU pipe: math; $317
        mov (32|M0)              r7.0<1>:f     r1.0<1;1,0>:ud                   {I@2}                //  ALU pipe: float; $316
(W)     mad (1|M0)               r12.0<1>:f    r10.0<0;0>:f      r11.0<0;0>:f      r10.0<0>:f       {Compacted,A@1} //  ALU pipe: float; $318
        mov (32|M0)              r15.0<1>:ud   r7.0<1;1,0>:f                    {F@2}                //  ALU pipe: int; $320
        mul (32|M0)              r13.0<1>:f    r7.0<1;1,0>:f     r12.0<0;1,0>:f   {Compacted,F@1}    //  ALU pipe: float; $319
(W)     mov (1|M0)               r5.0<1>:ud    r4.0<0;1,0>:f                                         //  ALU pipe: int; $314
        add (32|M0)              r17.0<1>:d    r1.0<1;1,0>:d     -r15.0<1;1,0>:d  {I@2}              //  ALU pipe: int; $321
        mov (32|M0)              r19.0<1>:ud   r13.0<1;1,0>:f                   {F@1}                //  ALU pipe: int; $322
(W)     add (1|M0)               r6.0<1>:d     r3.12<0;1,0>:d    -r5.0<0;1,0>:d   {I@3}              //  ALU pipe: int; $315
        mov (32|M0)              r27.0<1>:f    r19.0<1;1,0>:ud                  {I@2}                //  ALU pipe: float; $325
        mov (32|M0)              r23.0<1>:f    r17.0<1;1,0>:ud                                       //  ALU pipe: float; $324
(W)     mov (1|M0)               r22.0<1>:f    r6.0<0;1,0>:ud                   {I@1}                //  ALU pipe: float; $323
        mad (32|M0)              acc0.0<1>:f   r7.0<1;0>:f       r27.0<1;0>:f      -r4.0<0>:f       {F@3} //  ALU pipe: float; $327
        mad (32|M0)              acc2.0<1>:f   r23.0<1;0>:f      r27.0<1;0>:f      -r22.0<0>:f      {F@2} //  ALU pipe: float; $329
        add (32|M0)              acc0.0<1>:f   acc0.0<1;1,0>:f   acc2.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $330
        mul (32|M0)              r29.0<1>:f    r12.0<0;1,0>:f    acc0.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $331
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $332
        mov (32|M0)              r31.0<1>:ud   r29.0<1;1,0>:f                   {A@1}                //  ALU pipe: int; $333
        add (32|M0)              r33.0<1>:d    r31.0<1;1,0>:d    r19.0<1;1,0>:d   {I@1}              //  ALU pipe: int; $334
(W)     mul (16|M0)              acc0.0<1>:d   r33.0<1;1,0>:d    r3.24<0;1,0>:uw  {I@1}              //  ALU pipe: int; $335
        macl (16|M0)             r37.0<1>:d    r33.0<1;1,0>:d    r3.12<0;1,0>:d                      //  ALU pipe: int; $335
(W)     mul (16|M16)             acc0.0<1>:d   r34.0<1;1,0>:d    r3.24<0;1,0>:uw                     //  ALU pipe: int; $335
        macl (16|M16)            r38.0<1>:d    r34.0<1;1,0>:d    r3.12<0;1,0>:d                      //  ALU pipe: int; $336
        add (32|M0)              r39.0<1>:d    r1.0<1;1,0>:d     -r37.0<1;1,0>:d  {I@1}              //  ALU pipe: int; $336
        cmp (32|M0)   (lt)f1.0   null<1>:ud    r39.0<1;1,0>:ud   r3.12<0;1,0>:ud  {I@1}              //  ALU pipe: int; $337
(~f1.0) sel (32|M0)              r42.0<1>:d    r3.12<0;1,0>:d    0:w                                 //  ALU pipe: int; $338
        add3 (32|M0)             r98.0<1>:d    r1.0<1;0>:d       -r37.0<1;0>:d     -r42.0<1>:d      {I@1} //  ALU pipe: int; $339
(W)     jmpi                                 _0_030                                                  // $340
// B015: [inDivergent],  Preds:{B013},  Succs:{B016}
_0_028:
        mov (32|M0)              r98.0<1>:d    -1:w                               {Compacted}        //  ALU pipe: int; $342
// B016: [inDivergent],  Preds:{B015, B014},  Succs:{B017}
_0_030:
        mov (16|M0)              r1.0<2>:ud    r98.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $344
        mov (16|M16)             r4.0<2>:ud    r99.0<1;1,0>:ud                                       //  ALU pipe: int; $344
        mov (16|M0)              r116.0<1>:q   r1.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $344
        mov (16|M16)             r118.0<1>:q   r4.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $344
// B017: Preds:{B016, B012},  Succs:{}
_0_027:
        join (32|M0)                         L5808                                                   // 
L5808:
(W)     mul (16|M0)              acc0.0<1>:ud  r94.0<1;1,0>:ud   0xF600:uw                           //  ALU pipe: int; $353
        shl (16|M0)              r1.0<1>:q     r108.0<2;1,0>:d   32:w                                //  ALU pipe: int; $348
        shl (16|M0)              r4.0<1>:q     r116.0<2;1,0>:d   32:w               {I@5}            //  ALU pipe: int; $351
        shl (16|M16)             r6.0<1>:q     r110.0<2;1,0>:d   32:w                                //  ALU pipe: int; $348
        shl (16|M16)             r9.0<1>:q     r118.0<2;1,0>:d   32:w               {I@6}            //  ALU pipe: int; $351
        macl (16|M0)             r8.0<1>:ud    r94.0<1;1,0>:ud   0xFFFFF600:ud                       //  ALU pipe: int; $354
(W)     mul (16|M16)             acc0.0<1>:ud  r95.0<1;1,0>:ud   0xF600:uw                           //  ALU pipe: int; $354
        asr (16|M0)              r11.0<1>:q    r1.0<1;1,0>:q     28:w               {Compacted,I@6}  //  ALU pipe: int; $364
        asr (16|M0)              r13.0<1>:q    r4.0<1;1,0>:q     32:w               {Compacted,I@6}  //  ALU pipe: int; $352
        macl (16|M16)            r15.0<1>:ud   r95.0<1;1,0>:ud   0xFFFFF600:ud                       //  ALU pipe: int; $355
(W)     mul (16|M0)              acc0.0<1>:ud  r94.0<1;1,0>:ud   0xF600:uw                           //  ALU pipe: int; $355
        mul (32|M0)              r16.0<1>:d    r94.0<1;1,0>:ud   -1:w                                //  ALU pipe: int; $356
        asr (16|M16)             r24.0<1>:q    r6.0<1;1,0>:q     28:w               {Compacted,I@7}  //  ALU pipe: int; $364
        asr (16|M16)             r18.0<1>:q    r9.0<1;1,0>:q     32:w               {Compacted,I@7}  //  ALU pipe: int; $352
        mach (16|M0)             r20.0<1>:d    r94.0<1;1,0>:ud   0xFFFFF600:ud                       //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r95.0<1;1,0>:ud   0xF600:uw                           //  ALU pipe: int; $355
        add (16|M0)              r22.0<1>:q    r11.0<1;1,0>:q    r13.0<1;1,0>:q   {Compacted,I@7}    //  ALU pipe: int; $365
        mach (16|M16)            r21.0<1>:d    r95.0<1;1,0>:ud   0xFFFFF600:ud                       //  ALU pipe: int; $356
        add (16|M16)             r34.0<1>:q    r24.0<1;1,0>:q    r18.0<1;1,0>:q   {Compacted,I@5}    //  ALU pipe: int; $365
        mov (16|M0)              r32.0<1>:d    r22.0<2;1,0>:d                   {I@3}                //  ALU pipe: int; $366
(W)     mul (16|M0)              acc0.0<1>:d   r96.0<1;1,0>:d    0xF600:uw                           //  ALU pipe: int; $358
        add (32|M0)              r20.0<1>:d    r20.0<1;1,0>:d    r16.0<1;1,0>:d   {Compacted,I@4}    //  ALU pipe: int; $357
        mov (16|M16)             r33.0<1>:d    r34.0<2;1,0>:d                   {Compacted,I@4}      //  ALU pipe: int; $367
        macl (16|M0)             r16.0<1>:d    r96.0<1;1,0>:d    0xFFFFF600:ud                       //  ALU pipe: int; $358
(W)     mul (16|M16)             acc0.0<1>:d   r97.0<1;1,0>:d    0xF600:uw                           //  ALU pipe: int; $358
        macl (16|M16)            r17.0<1>:d    r97.0<1;1,0>:d    0xFFFFF600:ud                       //  ALU pipe: int; $359
(W)     mul (16|M0)              acc0.0<1>:ud  r32.0<1;1,0>:ud   0xA00:uw              {I@7}         //  ALU pipe: int; $372
        mov (16|M0)              r36.0<1>:d    r22.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $368
        mov (16|M16)             r37.0<1>:d    r34.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $369
        mach (16|M0)             r54.0<1>:d    r32.0<1;1,0>:ud   0xA00:ud                            //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r33.0<1;1,0>:ud   0xA00:uw              {I@7}         //  ALU pipe: int; $372
        mov (16|M0)              r26.0<2>:ud   r8.0<1;1,0>:ud                   {Compacted}          //  ALU pipe: int; $354
        mov (16|M16)             r28.0<2>:ud   r15.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $355
        mach (16|M16)            r55.0<1>:d    r33.0<1;1,0>:ud   0xA00:ud                            //  ALU pipe: int; $374
        add (16|M0)              r26.1<2>:d    r20.0<1;1,0>:d    r16.0<1;1,0>:d   {I@7}              //  ALU pipe: int; $359
        add (16|M16)             r28.1<2>:d    r21.0<1;1,0>:d    r17.0<1;1,0>:d   {I@7}              //  ALU pipe: int; $360
        mul (32|M0)              r44.0<1>:d    r36.0<1;1,0>:d    0xA00:uw              {I@7}         //  ALU pipe: int; $375
        shl (16|M0)              r30.0<1>:q    r104.0<1;1,0>:q   2:w               {Compacted}       //  ALU pipe: int; $362
        shl (16|M16)             r38.0<1>:q    r106.0<1;1,0>:q   2:w               {Compacted}       //  ALU pipe: int; $362
        add (16|M0)              r60.0<1>:q    r26.0<1;1,0>:q    r100.0<1;1,0>:q  {Compacted,I@5}    //  ALU pipe: int; $361
        add (16|M16)             r62.0<1>:q    r28.0<1;1,0>:q    r102.0<1;1,0>:q  {Compacted,I@5}    //  ALU pipe: int; $361
        mul (16|M0)              r40.0<2>:ud   r32.0<1;1,0>:ud   0xA00:uw                            //  ALU pipe: int; $370
        mul (16|M16)             r46.0<2>:ud   r33.0<1;1,0>:ud   0xA00:uw                            //  ALU pipe: int; $371
        add (16|M0)              r65.0<1>:q    r60.0<1;1,0>:q    r30.0<1;1,0>:q   {Compacted,I@4}    //  ALU pipe: int; $363
        add (16|M16)             r69.0<1>:q    r62.0<1;1,0>:q    r38.0<1;1,0>:q   {Compacted,I@4}    //  ALU pipe: int; $363
        add (16|M0)              r40.1<2>:d    r54.0<1;1,0>:d    r44.0<1;1,0>:d                      //  ALU pipe: int; $376
        add (16|M16)             r46.1<2>:d    r55.0<1;1,0>:d    r45.0<1;1,0>:d                      //  ALU pipe: int; $377
        add (16|M0)              r81.0<1>:q    r65.0<1;1,0>:q    r40.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $378
        add (16|M16)             r83.0<1>:q    r69.0<1;1,0>:q    r46.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $378
        asr (16|M0)              r42.0<1>:q    r4.0<1;1,0>:q     30:w               {Compacted}      //  ALU pipe: int; $381
        asr (16|M16)             r48.0<1>:q    r9.0<1;1,0>:q     30:w               {Compacted}      //  ALU pipe: int; $381
        load.ugm.d32.a64 (32|M0)  r7:2          [r81:4+0x64000]    {I@3,$2} // ex_desc:0x64000000; desc:0x8200580 // $380
        load.ugm.d32.a64 (32|M0)  r5:2          [r81:4]            {I@2,$3} // ex_desc:0x0; desc:0x8200580 // $379
        add (16|M0)              r50.0<1>:q    r42.0<1;1,0>:q    r3.4<0;1,0>:q    {Compacted}        //  ALU pipe: int; $384
        add (16|M16)             r52.0<1>:q    r48.0<1;1,0>:q    r3.4<0;1,0>:q    {Compacted,I@2}    //  ALU pipe: int; $384
        add (16|M0)              r56.0<1>:q    r42.0<1;1,0>:q    r3.3<0;1,0>:q    {Compacted}        //  ALU pipe: int; $382
        add (16|M16)             r58.0<1>:q    r48.0<1;1,0>:q    r3.3<0;1,0>:q    {Compacted}        //  ALU pipe: int; $382
        load.ugm.d32.a64 (32|M0)  r67:2         [r50:4]            {I@3,$4} // ex_desc:0x0; desc:0x8200580 // $385
        load.ugm.d32.a64 (32|M0)  r71:2         [r56:4]            {I@1,$5} // ex_desc:0x0; desc:0x8200580 // $383
(W)     mov (1|M0)               r64.0<1>:f    0x43FF0000:f                                          //  ALU pipe: float; $402
(f0.0)  sel (32|M0)              r73.0<1>:d    r3.2<0;1,0>:d     r3.4<0;1,0>:d                       //  ALU pipe: int; $391
(f0.0)  sel (32|M0)              r75.0<1>:d    r3.3<0;1,0>:d     r3.5<0;1,0>:d                       //  ALU pipe: int; $392
        mov (16|M0)              r77.0<2>:d    r73.0<1;1,0>:d                   {I@2}                //  ALU pipe: int; $395
        mov (16|M16)             r79.0<2>:d    r74.0<1;1,0>:d                                        //  ALU pipe: int; $396
        mov (16|M0)              r77.1<2>:d    r75.0<1;1,0>:d                   {I@3}                //  ALU pipe: int; $397
        mov (16|M16)             r79.1<2>:d    r76.0<1;1,0>:d                                        //  ALU pipe: int; $398
        add (16|M0)              r1.0<1>:q     r30.0<1;1,0>:q    r77.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $405
        add (16|M16)             r3.0<1>:q     r38.0<1;1,0>:q    r79.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $405
(W)     mov (16|M0)              r127.0<1>:f   r86.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $407
        sync.nop                             null                             {Compacted,$3.dst}     // $386
        add (32|M0)              r13.0<1>:d    r5.0<1;1,0>:d     r7.0<1;1,0>:d    {$2.dst}           //  ALU pipe: int; $386
        mov (32|M0)              r15.0<1>:f    r13.0<1;1,0>:d                   {I@1}                //  ALU pipe: float; $400
        mov (32|M0)              r9.0<1>:f     r67.0<1;1,0>:d                   {$4.dst}             //  ALU pipe: float; $401
        mul (32|M0)              r11.0<1>:f    r71.0<1;1,0>:f    0x3BDB8BAC:f               {$5.dst} //  ALU pipe: float; $399
        mad (32|M0)              acc2.0<1>:f   r15.0<1;0>:f      -r9.0<1;0>:f      r64.0<0>:f       {Compacted,F@2} //  ALU pipe: float; $403
        mul (32|M0)              r17.0<1>:f    r11.0<1;1,0>:f    acc2.0<1;1,0>:f  {Compacted,F@2}    //  ALU pipe: float; $404
        store.ugm.d32.a64 (32|M0)  [r1:4]       r17:2              {F@1,$6} // ex_desc:0x0; desc:0x8000584 // $406
(W)     send.gtwy (1|M0)         null     r127  null:0  0x0            0x02000010           {EOT,$7} // wr:1+0, rd:0; end of thread // $407
L6800:
(W)     mov (16|M0)              null<1>:ud    0xE875C6B1:ud                                         // 
(W)     mov (16|M0)              null<1>:ud    0xBC10FADA:ud                                         // 
(W)     mov (16|M0)              null<1>:ud    0x0:ud                                                // 
(W)     mov (16|M0)              null<1>:ud    0x4:ud                                                // 


//.BankConflicts: 1
//.ByteRMWs: 0
//


//.numALUInst: 492
//.accSubDef: 7
//.accSubUse: 7
//.accSubCandidateDef: 8
//.accSubCandidateUse: 8
//
//
//.singlePipeAtOneDistNum: 61
//.allAtOneDistNum: 13
//.syncInstCount: 1
//.tokenReuseCount: 0
//.AfterWriteTokenDepCount: 6
//.AfterReadTokenDepCount: 1

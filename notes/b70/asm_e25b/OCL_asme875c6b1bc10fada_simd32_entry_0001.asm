//.kernel _ZTSN4sycl3_V16detail18RoundedRangeKernelINS0_4itemILi1ELb1EEELi1EZL5splitRNS0_5queueEPKiS8_PKfS8_PfSB_iEUlNS0_2idILi1EEEE_EE
//.platform XE2
//.thread_config numGRF=128, numAcc=4, numSWSB=16
//.options_string "-emitCrossThreadOffR0Reloc -hashmovs 3900032689 3155229402 -hashmovs1 0 1 "
//.full_options "-emitLocation -wideMulMadOpsEn -enableCoalesceScalarMoves -supportLSCImmScale 0 -samplerHeaderWA -enablePreemptionR0Only -hasRNEandDenorm -noStitchExternFunc -useInlineData -emitCrossThreadOffR0Reloc -abortonspill -abortOnSpill 4 -enableBCR -enableBundleCR 3 -freqBasedSpillCost 8 -freqBasedSpillCostFunc 1 -boundsChecking -presched-ctrl 6 -presched-rp 100 -nodpsendreorder -SBIDDepLoc -PVCSendWARWA -output -binary -dumpcommonisa -dumpcombinedcisa -dumpvisa -printHexFloatInAsm -noverifyCISA -enableHalfLSC -partialInt64 -activeThreadsOnlyBarrier -hashmovs 3900032689 3155229402 -hashmovs1 0 1 -GRFBumpUpNumber 2 "
//.instCount 376
//.RA type	LOCAL_ROUND_ROBIN_BC_RA
//.git-hash f523d3ae2278a1765cdbdedb3770d11afa642fa5

//.declare BuiltInR0 (0)  rf=r size=64 type=ud align=32 words (r0.0) IsBuiltin
//.declare  (1)  rf=r size=64 type=ud align=32 words (r75.0) IsBuiltin
//.declare BuiltinA0 (2)  rf=a size=4 type=ud align=1 words (a0.0) IsBuiltin
//.declare BuiltinA0Dot2 (3)  rf=a size=4 type=ud align=1 words (a0.2) IsBuiltin
//.declare BuiltinSR0Dot1 (5)  rf=r size=4 type=ud align=2 words IsBuiltin
//.declare %null (10)  rf=r size=4 type=ud align=2 words
//.declare %local_id_x (13)  rf=r size=4 type=ud align=2 words (r0.7)
//.declare %local_id_y (14)  rf=r size=4 type=ud align=2 words (r0.8)
//.declare %local_size_x (15)  rf=r size=4 type=ud align=2 words (r0.3)
//.declare %local_size_y (16)  rf=r size=4 type=ud align=2 words (r0.4)
//.declare %group_id_x (17)  rf=r size=4 type=ud align=2 words (r0.1)
//.declare %group_id_y (18)  rf=r size=4 type=ud align=2 words (r0.6)
//.declare %group_id_z (19)  rf=r size=4 type=ud align=2 words (r0.7)
//.declare %group_count_x (20)  rf=r size=4 type=ud align=2 words (r0.5)
//.declare %group_count_y (21)  rf=r size=4 type=ud align=2 words (r0.6)
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
//.declare V0033 (43)  rf=r size=64 type=d alias=+0 align=32 words (r75.0)
//.declare V0035 (45)  rf=r size=32 type=d alias=+0 align=32 words (r75.0)
//.declare V0036 (46)  rf=r size=12 type=d align=2 words (r2.0)
//.declare V0037 (47)  rf=r size=12 type=d align=2 words (r4.0)
//.declare V0038 (48)  rf=r size=12 type=d align=2 words (r2.3)
//.declare V0039 (49)  rf=r size=64 type=w align=32 words (r1.0)
//.declare V0043 (53)  rf=r size=8 type=q align=4 words (r2.3)
//.declare V0044 (54)  rf=r size=4 type=d align=2 words (r3.0)
//.declare V0045 (55)  rf=r size=1 type=b align=2 words (r3.4)
//.declare V0046 (56)  rf=r size=1 type=b align=2 words (r3.8)
//.declare V0047 (57)  rf=r size=1 type=b align=2 words (r3.12)
//.declare V0048 (58)  rf=r size=1 type=b align=2 words (r3.16)
//.declare V0049 (59)  rf=r size=8 type=q align=4 words (r3.3)
//.declare V0050 (60)  rf=r size=8 type=q align=4 words (r3.4)
//.declare V0051 (61)  rf=r size=8 type=q align=4 words (r3.5)
//.declare V0052 (62)  rf=r size=8 type=q align=4 words (r3.6)
//.declare V0053 (63)  rf=r size=8 type=d align=2 words (r85.0)
//.declare V0054 (64)  rf=r size=8 type=d alias=V0043+0 align=4 words (r2.6)
//.declare V0058 (68)  rf=r size=12 type=ud alias=V0038+0 align=2 words (r2.3)
//.declare V0059 (69)  rf=r size=32 type=ud alias=V0035+0 align=16 words (r75.0)
//.declare V0060 (70)  rf=r size=4 type=d align=32 words (r6.0)
//.declare V0064 (74)  rf=r size=8 type=q align=32 words (r5.0)
//.declare V0065 (75)  rf=r size=8 type=d alias=V0064+0 align=4 words (r5.0)
//.declare V0067 (77)  rf=r size=64 type=uw alias=V0039+0 align=32 words (r1.0)
//.declare V0070 (80)  rf=r size=12 type=ud alias=V0036+0 align=2 words (r2.0)
//.declare V0074 (84)  rf=r size=128 type=d align=32 words (r86.0)
//.declare V0075 (85)  rf=r size=128 type=d align=32 words (r88.0)
//.declare P01 (86)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0076 (87)  rf=r size=128 type=ud alias=V0074+0 align=32 words (r86.0)
//.declare V0077 (88)  rf=r size=8 type=ud alias=V0053+0 align=2 words (r85.0)
//.declare P02 (89)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare P03 (90)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0078 (91)  rf=r size=128 type=ud alias=V0075+0 align=32 words (r88.0)
//.declare V0079 (92)  rf=r size=4 type=d align=2 words (r85.2)
//.declare V0080 (93)  rf=r size=4 type=d align=2 words (r85.3)
//.declare V0081 (94)  rf=r size=4 type=d align=2 words (r85.4)
//.declare V0082 (95)  rf=r size=4 type=ud alias=V0080+0 align=2 words (r85.3)
//.declare V0083 (96)  rf=r size=4 type=ud alias=V0044+0 align=2 words (r3.0)
//.declare V0084 (97)  rf=r size=4 type=d align=32 words (r15.0)
//.declare V0086 (99)  rf=r size=4 type=d align=2 words (r16.0)
//.declare V0088 (101)  rf=r size=8 type=q align=4 words (r2.4)
//.declare V0089 (102)  rf=r size=8 type=d alias=V0088+0 align=4 words (r2.8)
//.declare V0090 (103)  rf=r size=4 type=d align=4 words (r85.6)
//.declare V0091 (104)  rf=r size=8 type=df align=4 words (r3.1)
//.declare V0092 (105)  rf=r size=8 type=uq alias=V0088+0 align=4 words (r2.4)
//.declare V0093 (106)  rf=r size=4 type=f align=4 words (r4.4)
//.declare V0094 (107)  rf=r size=4 type=f align=2 words (r5.0)
//.declare V0095 (108)  rf=r size=8 type=df align=4 words (r6.0)
//.declare V0096 (109)  rf=r size=8 type=df align=4 words (r8.0)
//.declare V0097 (110)  rf=r size=8 type=df align=4 words (r7.0)
//.declare V0098 (111)  rf=r size=8 type=df align=4 words (r11.0)
//.declare V0100 (113)  rf=r size=8 type=df align=4 words (r85.4)
//.declare V0101 (114)  rf=r size=4 type=d align=2 words (r85.5)
//.declare P04 (115)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare P05 (116)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0102 (117)  rf=r size=8 type=q align=4 words (r12.0)
//.declare V0103 (118)  rf=r size=8 type=df align=4 words (r13.0)
//.declare V0104 (119)  rf=r size=8 type=uq alias=V0102+0 align=4 words (r12.0)
//.declare V0105 (120)  rf=r size=4 type=f align=4 words (r14.0)
//.declare V0106 (121)  rf=r size=4 type=f align=2 words (r15.0)
//.declare V0107 (122)  rf=r size=8 type=df align=4 words (r16.0)
//.declare V0108 (123)  rf=r size=8 type=df align=4 words (r17.0)
//.declare V0109 (124)  rf=r size=8 type=df align=4 words (r19.0)
//.declare V0110 (125)  rf=r size=8 type=df align=4 words (r85.5)
//.declare V0111 (126)  rf=r size=8 type=q align=4 words (r85.6)
//.declare V0112 (127)  rf=r size=12 type=ud alias=V0037+0 align=2 words (r4.0)
//.declare V0113 (128)  rf=r size=4 type=f align=2 words (r85.7)
//.declare V0114 (129)  rf=r size=8 type=df align=4 words (r85.7)
//.declare V0116 (131)  rf=r size=128 type=d align=32 words (r90.0)
//.declare V0117 (132)  rf=r size=128 type=d align=32 words (r5.0)
//.declare V0118 (133)  rf=r size=128 type=d align=32 words (r7.0)
//.declare P06 (134)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0119 (135)  rf=r size=128 type=ud alias=V0118+0 align=32 words (r7.0)
//.declare V0120 (136)  rf=r size=128 type=d align=32 words (r92.0)
//.declare V0121 (137)  rf=r size=128 type=d align=32 words (r5.0)
//.declare V0122 (138)  rf=r size=4 type=f align=2 words (r8.0)
//.declare V0123 (139)  rf=r size=4 type=ud alias=V0090+0 align=2 words (r85.6)
//.declare V0124 (140)  rf=r size=4 type=d align=2 words (r9.0)
//.declare V0125 (141)  rf=r size=4 type=ud alias=V0124+0 align=2 words (r9.0)
//.declare V0126 (142)  rf=r size=4 type=d align=2 words (r10.0)
//.declare V0127 (143)  rf=r size=128 type=f align=32 words (r11.0)
//.declare V0128 (144)  rf=r size=128 type=ud alias=V0121+0 align=32 words (r5.0)
//.declare V0129 (145)  rf=r size=4 type=f align=2 words (r14.0)
//.declare V0130 (146)  rf=r size=4 type=f align=2 words (r16.0)
//.declare V0131 (147)  rf=r size=128 type=f align=32 words (r17.0)
//.declare V0132 (148)  rf=r size=128 type=d align=32 words (r19.0)
//.declare V0133 (149)  rf=r size=128 type=ud alias=V0132+0 align=32 words (r19.0)
//.declare V0134 (150)  rf=r size=128 type=d align=32 words (r21.0)
//.declare V0135 (151)  rf=r size=128 type=d align=32 words (r23.0)
//.declare V0136 (152)  rf=r size=128 type=ud alias=V0135+0 align=32 words (r23.0)
//.declare V0137 (153)  rf=r size=4 type=f align=2 words (r26.0)
//.declare V0138 (154)  rf=r size=4 type=ud alias=V0126+0 align=2 words (r10.0)
//.declare V0139 (155)  rf=r size=128 type=f align=32 words (r27.0)
//.declare V0140 (156)  rf=r size=128 type=ud alias=V0134+0 align=32 words (r21.0)
//.declare V0141 (157)  rf=r size=128 type=f align=32 words (r31.0)
//.declare V0147 (163)  rf=r size=128 type=f align=32 words (r33.0)
//.declare V0148 (164)  rf=r size=128 type=d align=32 words (r35.0)
//.declare V0149 (165)  rf=r size=128 type=ud alias=V0148+0 align=32 words (r35.0)
//.declare V0150 (166)  rf=r size=128 type=d align=32 words (r37.0)
//.declare V0151 (167)  rf=r size=128 type=d align=32 words (r39.0)
//.declare V0152 (168)  rf=r size=128 type=d align=32 words (r41.0)
//.declare V0153 (169)  rf=r size=128 type=d align=32 words (r44.0)
//.declare V0154 (170)  rf=r size=128 type=ud alias=V0152+0 align=32 words (r41.0)
//.declare V0155 (171)  rf=r size=128 type=ud alias=V0153+0 align=32 words (r44.0)
//.declare  (172)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0157 (174)  rf=r size=128 type=ud alias=V0120+0 align=32 words (r92.0)
//.declare V0159 (176)  rf=r size=128 type=d align=32 words (r5.0)
//.declare V0161 (178)  rf=r size=128 type=ud alias=V0159+0 align=32 words (r5.0)
//.declare V0163 (180)  rf=r size=128 type=d align=32 words (r21.0)
//.declare V0164 (181)  rf=r size=128 type=ud alias=V0163+0 align=32 words (r21.0)
//.declare V0165 (182)  rf=r size=128 type=d align=32 words (r25.0)
//.declare V0166 (183)  rf=r size=128 type=d align=32 words (r27.0)
//.declare V0169 (186)  rf=r size=128 type=ud alias=V0166+0 align=32 words (r27.0)
//.declare V0178 (195)  rf=r size=128 type=d align=32 words (r55.0)
//.declare V0179 (196)  rf=r size=128 type=d align=32 words (r57.0)
//.declare V0184 (201)  rf=r size=128 type=d align=32 words (r63.0)
//.declare V0185 (202)  rf=r size=128 type=d align=32 words (r65.0)
//.declare V0187 (204)  rf=r size=128 type=d align=32 words (r67.0)
//.declare P07 (205)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare P08 (206)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0188 (207)  rf=r size=128 type=d align=32 words (r69.0)
//.declare V0189 (208)  rf=r size=128 type=d align=32 words (r71.0)
//.declare V0190 (209)  rf=r size=128 type=d align=32 words (r76.0)
//.declare V0196 (215)  rf=r size=128 type=ud alias=V0178+0 align=32 words (r55.0)
//.declare V0197 (216)  rf=r size=4 type=ud alias=V0101+0 align=2 words (r85.5)
//.declare V0200 (219)  rf=r size=128 type=d align=32 words (r13.0)
//.declare V0201 (220)  rf=r size=128 type=d align=32 words (r15.0)
//.declare V0205 (224)  rf=r size=128 type=d align=32 words (r23.0)
//.declare V0206 (225)  rf=r size=128 type=d align=32 words (r25.0)
//.declare P09 (230)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0211 (231)  rf=r size=128 type=ud alias=V0205+0 align=32 words (r23.0)
//.declare P10 (232)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare P11 (233)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0212 (234)  rf=r size=128 type=ud alias=V0206+0 align=32 words (r25.0)
//.declare V0213 (235)  rf=r size=4 type=ud alias=V0081+0 align=2 words (r85.4)
//.declare V0217 (239)  rf=r size=128 type=d align=32 words (r95.0)
//.declare V0218 (240)  rf=r size=128 type=d align=32 words (r5.0)
//.declare V0219 (241)  rf=r size=128 type=ud alias=V0217+0 align=32 words (r95.0)
//.declare V0220 (242)  rf=r size=128 type=ud alias=V0218+0 align=32 words (r5.0)
//.declare V0221 (243)  rf=r size=128 type=d align=32 words (r100.0)
//.declare V0222 (244)  rf=r size=128 type=ud alias=V0221+0 align=32 words (r100.0)
//.declare V0223 (245)  rf=r size=128 type=d align=32 words (r97.0)
//.declare V0224 (246)  rf=r size=4 type=f align=2 words (r2.8)
//.declare V0225 (247)  rf=r size=4 type=d align=2 words (r3.1)
//.declare V0226 (248)  rf=r size=4 type=ud alias=V0225+0 align=2 words (r3.1)
//.declare V0227 (249)  rf=r size=4 type=d align=2 words (r4.3)
//.declare V0228 (250)  rf=r size=128 type=f align=32 words (r5.0)
//.declare V0229 (251)  rf=r size=4 type=f align=2 words (r8.0)
//.declare V0230 (252)  rf=r size=4 type=f align=2 words (r10.0)
//.declare V0231 (253)  rf=r size=128 type=f align=32 words (r11.0)
//.declare V0232 (254)  rf=r size=128 type=d align=32 words (r13.0)
//.declare V0233 (255)  rf=r size=128 type=ud alias=V0232+0 align=32 words (r13.0)
//.declare V0234 (256)  rf=r size=128 type=d align=32 words (r15.0)
//.declare V0235 (257)  rf=r size=128 type=d align=32 words (r17.0)
//.declare V0236 (258)  rf=r size=128 type=ud alias=V0235+0 align=32 words (r17.0)
//.declare V0237 (259)  rf=r size=4 type=f align=2 words (r20.0)
//.declare V0238 (260)  rf=r size=4 type=ud alias=V0227+0 align=2 words (r4.3)
//.declare V0239 (261)  rf=r size=128 type=f align=32 words (r21.0)
//.declare V0240 (262)  rf=r size=128 type=ud alias=V0234+0 align=32 words (r15.0)
//.declare V0241 (263)  rf=r size=128 type=f align=32 words (r25.0)
//.declare V0247 (269)  rf=r size=128 type=f align=32 words (r27.0)
//.declare V0248 (270)  rf=r size=128 type=d align=32 words (r29.0)
//.declare V0249 (271)  rf=r size=128 type=ud alias=V0248+0 align=32 words (r29.0)
//.declare V0250 (272)  rf=r size=128 type=d align=32 words (r31.0)
//.declare V0251 (273)  rf=r size=128 type=d align=32 words (r33.0)
//.declare V0252 (274)  rf=r size=128 type=d align=32 words (r35.0)
//.declare P12 (275)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0253 (276)  rf=r size=128 type=ud alias=V0252+0 align=32 words (r35.0)
//.declare V0254 (277)  rf=r size=128 type=d align=32 words (r37.0)
//.declare V0256 (279)  rf=r size=128 type=ud alias=V0223+0 align=32 words (r97.0)
//.declare V0263 (286)  rf=r size=128 type=d align=32 words (r21.0)
//.declare V0264 (287)  rf=r size=128 type=d align=32 words (r23.0)
//.declare V0265 (288)  rf=r size=128 type=d align=32 words (r25.0)
//.declare P13 (289)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0266 (290)  rf=r size=128 type=ud alias=V0264+0 align=32 words (r23.0)
//.declare V0267 (291)  rf=r size=128 type=d align=32 words (r27.0)
//.declare V0273 (297)  rf=r size=128 type=ud alias=V0263+0 align=32 words (r21.0)
//.declare V0276 (300)  rf=r size=128 type=d align=32 words (r43.0)
//.declare V0277 (301)  rf=r size=128 type=d align=32 words (r45.0)
//.declare V0281 (305)  rf=r size=128 type=d align=32 words (r51.0)
//.declare V0282 (306)  rf=r size=128 type=d align=32 words (r53.0)
//.declare P14 (307)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0283 (308)  rf=r size=128 type=ud alias=V0281+0 align=32 words (r51.0)
//.declare P15 (309)  rf=f32  size=4 type=uw align=2 words (f1.0)
//.declare P16 (310)  rf=f32  size=4 type=uw align=2 words (f2.0)
//.declare V0284 (311)  rf=r size=128 type=ud alias=V0282+0 align=32 words (r53.0)
//.declare V0285 (312)  rf=r size=4 type=ud alias=V0079+0 align=2 words (r85.2)
//.declare V0291 (318)  rf=r size=128 type=d align=32 words (r9.0)
//.declare V0293 (320)  rf=r size=128 type=ud alias=V0291+0 align=32 words (r9.0)
//.declare V0300 (327)  rf=r size=128 type=d align=32 words (r27.0)
//.declare V0301 (328)  rf=r size=128 type=d align=32 words (r29.0)
//.declare V0303 (330)  rf=r size=128 type=ud alias=V0300+0 align=32 words (r27.0)
//.declare V0306 (333)  rf=r size=128 type=d align=32 words (r39.0)
//.declare V0307 (334)  rf=r size=128 type=d align=32 words (r37.0)
//.declare V0308 (335)  rf=r size=256 type=q align=32 words (r67.0)
//.declare V0309 (336)  rf=r size=256 type=uq alias=V0308+0 align=32 words (r67.0)
//.declare V0310 (337)  rf=r size=128 type=d align=32 words (r71.0)
//.declare V0311 (338)  rf=r size=128 type=d align=32 words (r73.0)
//.declare V0313 (340)  rf=r size=256 type=q align=32 words (r47.0)
//.declare V0314 (341)  rf=r size=256 type=uq alias=V0313+0 align=32 words (r47.0)
//.declare V0315 (342)  rf=r size=128 type=f align=32 words (r55.0)
//.declare V0316 (343)  rf=r size=256 type=q align=32 words (r23.0)
//.declare V0317 (344)  rf=r size=256 type=uq alias=V0316+0 align=32 words (r23.0)
//.declare V0318 (345)  rf=r size=128 type=d align=32 words (r51.0)
//.declare V0319 (346)  rf=r size=128 type=d align=32 words (r80.0)
//.declare V0320 (347)  rf=r size=128 type=f align=32 words (r78.0)
//.declare V0321 (348)  rf=r size=128 type=f align=32 words (r83.0)
//.declare V0322 (349)  rf=r size=128 type=f align=32 words (r76.0)
//.declare V0324 (351)  rf=r size=128 type=f align=32 words (r5.0)
//.declare V0326 (353)  rf=r size=256 type=q align=32 words (r63.0)
//.declare V0327 (354)  rf=r size=256 type=uq alias=V0326+0 align=32 words (r63.0)
//.declare V0331 (358)  rf=r size=128 type=d align=32 words (r102.0)
//.declare V0332 (359)  rf=r size=128 type=d align=32 words (r104.0)
//.declare P17 (360)  rf=f32  size=4 type=uw align=2 words (f0.0)
//.declare V0333 (361)  rf=r size=128 type=ud alias=V0331+0 align=32 words (r102.0)
//.declare P18 (362)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare P19 (363)  rf=f32  size=4 type=uw align=2 words (f3.0)
//.declare V0334 (364)  rf=r size=128 type=ud alias=V0332+0 align=32 words (r104.0)
//.declare  (368)  rf=r size=64 type=ud align=32 words (r127.0)
//.declare  (371)  rf=r size=128 type=uw align=32 words (r7.0)
//.declare  (372)  rf=r size=128 type=uw align=32 words (r11.0)
//.declare  (373)  rf=r size=8 type=df align=4 words (r9.0)
//.declare  (375)  rf=r size=4 type=f align=2 words (r15.0)
//.declare  (378)  rf=r size=128 type=ud align=32 words (r5.0)
//.declare  (379)  rf=r size=128 type=ud align=32 words (r7.0)
//.declare  (380)  rf=r size=128 type=ud align=32 words (r19.0)
//.declare  (381)  rf=r size=128 type=ud align=32 words (r23.0)
//.declare  (384)  rf=r size=2 type=w align=1 words (r35.0)
//.declare  (385)  rf=r size=64 type=ud align=32 words (r7.0)
//.declare  (386)  rf=r size=64 type=ud align=32 words (r10.0)
//.declare  (387)  rf=r size=128 type=ud align=32 words (r7.0)
//.declare  (388)  rf=r size=128 type=ud align=32 words (r11.0)
//.declare  (389)  rf=r size=128 type=ud align=32 words (r29.0)
//.declare  (390)  rf=r size=128 type=ud align=32 words (r34.0)
//.declare  (391)  rf=r size=128 type=ud align=32 words (r38.0)
//.declare  (392)  rf=r size=128 type=ud align=32 words (r42.0)
//.declare  (395)  rf=r size=4 type=f align=2 words (r9.0)
//.declare  (396)  rf=r size=128 type=ud align=32 words (r5.0)
//.declare  (397)  rf=r size=128 type=ud align=32 words (r7.0)
//.declare  (400)  rf=r size=64 type=ud align=32 words (r37.0)
//.declare  (401)  rf=r size=64 type=ud align=32 words (r40.0)
//.declare  (402)  rf=r size=128 type=ud align=32 words (r5.0)
//.declare  (403)  rf=r size=128 type=ud align=32 words (r9.0)
//.declare  (404)  rf=r size=128 type=ud align=32 words (r19.0)
//.declare  (405)  rf=r size=128 type=ud align=32 words (r21.0)
//.declare  (408)  rf=r size=128 type=q align=32 words (r9.0)
//.declare  (409)  rf=r size=128 type=q align=32 words (r13.0)
//.declare  (410)  rf=r size=128 type=q align=32 words (r106.0)
//.declare  (411)  rf=r size=128 type=q align=32 words (r108.0)
//.declare  (416)  rf=r size=128 type=q align=32 words (r110.0)
//.declare  (417)  rf=r size=128 type=q align=32 words (r112.0)
//.declare  (418)  rf=r size=128 type=df align=32 words (r9.0)
//.declare  (419)  rf=r size=128 type=df align=32 words (r13.0)
//.declare  (420)  rf=r size=128 type=df align=32 words (r15.0)
//.declare  (421)  rf=r size=128 type=df align=32 words (r17.0)
//.declare  (422)  rf=r size=128 type=df align=32 words (r32.0)
//.declare  (423)  rf=r size=128 type=df align=32 words (r36.0)
//.declare  (424)  rf=r size=128 type=df align=32 words (r39.0)
//.declare  (425)  rf=r size=128 type=df align=32 words (r41.0)
//.declare  (426)  rf=r size=128 type=df align=32 words (r43.0)
//.declare  (427)  rf=r size=128 type=df align=32 words (r45.0)
//.declare  (428)  rf=r size=128 type=df align=32 words (r47.0)
//.declare  (429)  rf=r size=128 type=df align=32 words (r49.0)
//.declare  (430)  rf=r size=128 type=q align=32 words (r51.0)
//.declare  (431)  rf=r size=128 type=q align=32 words (r53.0)
//.declare  (432)  rf=r size=128 type=q align=32 words (r59.0)
//.declare  (433)  rf=r size=128 type=q align=32 words (r61.0)
//.declare  (436)  rf=r size=128 type=d align=32 words (r80.0)
//.declare  (437)  rf=r size=128 type=d align=32 words (r78.0)
//.declare  (438)  rf=r size=128 type=q align=32 words (r82.0)
//.declare  (439)  rf=r size=128 type=q align=32 words (r5.0)
//.declare  (440)  rf=r size=128 type=q align=32 words (r8.0)
//.declare  (441)  rf=r size=128 type=q align=32 words (r11.0)
//.declare  (442)  rf=r size=128 type=q align=32 words (r17.0)
//.declare  (443)  rf=r size=128 type=q align=32 words (r19.0)
//.declare  (446)  rf=r size=128 type=d align=32 words (r29.0)
//.declare  (447)  rf=r size=128 type=d align=32 words (r27.0)
//.declare  (448)  rf=r size=128 type=q align=32 words (r31.0)
//.declare  (449)  rf=r size=128 type=q align=32 words (r33.0)
//.declare  (450)  rf=r size=128 type=q align=32 words (r40.0)
//.declare  (451)  rf=r size=128 type=q align=32 words (r44.0)
//.declare  (452)  rf=r size=128 type=q align=32 words (r36.0)
//.declare  (454)  rf=r size=128 type=q align=32 words (r114.0)
//.declare  (455)  rf=r size=128 type=q align=32 words (r116.0)
//.declare  (456)  rf=r size=128 type=df align=32 words (r7.0)
//.declare  (457)  rf=r size=128 type=df align=32 words (r11.0)
//.declare  (458)  rf=r size=128 type=df align=32 words (r13.0)
//.declare  (459)  rf=r size=128 type=df align=32 words (r15.0)
//.declare  (460)  rf=r size=128 type=q align=32 words (r17.0)
//.declare  (461)  rf=r size=128 type=q align=32 words (r19.0)
//.declare  (464)  rf=r size=128 type=d align=32 words (r31.0)
//.declare  (465)  rf=r size=128 type=d align=32 words (r29.0)
//.declare  (466)  rf=r size=128 type=q align=32 words (r33.0)
//.declare  (467)  rf=r size=128 type=q align=32 words (r35.0)
//.declare  (468)  rf=r size=128 type=q align=32 words (r38.0)
//.declare  (469)  rf=r size=128 type=q align=32 words (r41.0)
//.declare  (470)  rf=r size=128 type=q align=32 words (r47.0)
//.declare  (471)  rf=r size=128 type=q align=32 words (r49.0)
//.declare  (474)  rf=r size=128 type=d align=32 words (r55.0)
//.declare  (475)  rf=r size=128 type=d align=32 words (r57.0)
//.declare  (476)  rf=r size=128 type=q align=32 words (r59.0)
//.declare  (477)  rf=r size=128 type=q align=32 words (r61.0)
//.declare  (480)  rf=r size=128 type=q align=32 words (r31.0)
//.declare  (481)  rf=r size=128 type=q align=32 words (r33.0)
//.declare  (482)  rf=r size=128 type=q align=32 words (r41.0)
//.declare  (483)  rf=r size=128 type=q align=32 words (r43.0)
//.declare  (484)  rf=r size=128 type=q align=32 words (r5.0)
//.declare  (485)  rf=r size=128 type=q align=32 words (r7.0)
//.declare  (486)  rf=r size=128 type=q align=32 words (r15.0)
//.declare  (487)  rf=r size=128 type=q align=32 words (r17.0)
//.declare  (490)  rf=r size=128 type=q align=32 words (r35.0)
//.declare  (491)  rf=r size=128 type=q align=32 words (r45.0)
//.declare  (492)  rf=r size=128 type=q align=32 words (r11.0)
//.declare  (493)  rf=r size=128 type=q align=32 words (r13.0)
//.declare  (494)  rf=r size=128 type=q align=32 words (r59.0)
//.declare  (495)  rf=r size=128 type=q align=32 words (r61.0)
//.declare  (496)  rf=r size=128 type=q align=32 words (r53.0)
//.declare  (497)  rf=r size=128 type=q align=32 words (r57.0)
//.declare  (500)  rf=r size=128 type=d align=32 words (r5.0)
//.declare  (501)  rf=r size=128 type=d align=32 words (r7.0)
//.declare  (502)  rf=r size=128 type=d alias=+0 align=32 words (r106.0)
//.declare  (503)  rf=r size=128 type=d alias=+0 align=32 words (r108.0)
//.declare  (504)  rf=r size=128 type=ud alias=+0 align=32 words (r106.0)
//.declare  (505)  rf=r size=128 type=ud alias=+0 align=32 words (r108.0)
//.declare  (506)  rf=r size=128 type=uq alias=+0 align=32 words (r51.0)
//.declare  (507)  rf=r size=128 type=uq alias=+0 align=32 words (r53.0)
//.declare  (508)  rf=r size=128 type=d alias=+0 align=32 words (r51.0)
//.declare  (509)  rf=r size=128 type=d alias=+0 align=32 words (r53.0)
//.declare  (510)  rf=r size=128 type=uq alias=+0 align=32 words (r59.0)
//.declare  (511)  rf=r size=128 type=uq alias=+0 align=32 words (r61.0)
//.declare  (512)  rf=r size=128 type=d alias=+0 align=32 words (r59.0)
//.declare  (513)  rf=r size=128 type=d alias=+0 align=32 words (r61.0)
//.declare  (514)  rf=r size=128 type=d alias=+0 align=32 words (r82.0)
//.declare  (515)  rf=r size=128 type=d alias=+0 align=32 words (r5.0)
//.declare  (516)  rf=r size=128 type=ud alias=+0 align=32 words (r8.0)
//.declare  (517)  rf=r size=128 type=ud alias=+0 align=32 words (r11.0)
//.declare  (518)  rf=r size=128 type=d alias=+0 align=32 words (r8.0)
//.declare  (519)  rf=r size=128 type=d alias=+0 align=32 words (r11.0)
//.declare  (520)  rf=r size=128 type=d alias=+0 align=32 words (r17.0)
//.declare  (521)  rf=r size=128 type=d alias=+0 align=32 words (r19.0)
//.declare  (522)  rf=r size=128 type=d alias=+0 align=32 words (r31.0)
//.declare  (523)  rf=r size=128 type=d alias=+0 align=32 words (r33.0)
//.declare  (524)  rf=r size=128 type=d alias=+0 align=32 words (r36.0)
//.declare  (525)  rf=r size=128 type=ud alias=+0 align=32 words (r36.0)
//.declare  (526)  rf=r size=128 type=uq alias=+0 align=32 words (r17.0)
//.declare  (527)  rf=r size=128 type=uq alias=+0 align=32 words (r19.0)
//.declare  (528)  rf=r size=128 type=d alias=+0 align=32 words (r17.0)
//.declare  (529)  rf=r size=128 type=d alias=+0 align=32 words (r19.0)
//.declare  (530)  rf=r size=128 type=d alias=+0 align=32 words (r33.0)
//.declare  (531)  rf=r size=128 type=d alias=+0 align=32 words (r35.0)
//.declare  (532)  rf=r size=128 type=ud alias=+0 align=32 words (r38.0)
//.declare  (533)  rf=r size=128 type=ud alias=+0 align=32 words (r41.0)
//.declare  (534)  rf=r size=128 type=d alias=+0 align=32 words (r38.0)
//.declare  (535)  rf=r size=128 type=d alias=+0 align=32 words (r41.0)
//.declare  (536)  rf=r size=128 type=d alias=+0 align=32 words (r47.0)
//.declare  (537)  rf=r size=128 type=d alias=+0 align=32 words (r49.0)
//.declare  (538)  rf=r size=128 type=d alias=+0 align=32 words (r59.0)
//.declare  (539)  rf=r size=128 type=d alias=+0 align=32 words (r61.0)
//.declare  (540)  rf=r size=128 type=d alias=+0 align=32 words (r15.0)
//.declare  (541)  rf=r size=128 type=d alias=+0 align=32 words (r17.0)
//.declare  (542)  rf=r size=128 type=ud alias=+0 align=32 words (r35.0)
//.declare  (543)  rf=r size=128 type=ud alias=+0 align=32 words (r45.0)
//.declare  (544)  rf=r size=128 type=d alias=+0 align=32 words (r35.0)
//.declare  (545)  rf=r size=128 type=d alias=+0 align=32 words (r45.0)
//.declare  (546)  rf=r size=128 type=d alias=+0 align=32 words (r53.0)
//.declare  (547)  rf=r size=128 type=d alias=+0 align=32 words (r57.0)
//.declare r0 (548)  rf=r size=64 type=ud align=32 words (r0.0)
//.declare rtmp (549)  rf=r size=64 type=ud align=32 words (r127.0)
//.declare inlineRegFromTDL (550)  rf=r size=32 type=ud align=2 words (r1.0)
//.declare inlineRegExpectedLocation (551)  rf=r size=32 type=ud align=2 words (r2.0)
//.declare  (552)  rf=r size=64 type=ud align=32 words (r1.0)
//.declare  (553)  rf=r size=64 type=ud align=32 words (r3.0)
//.declare  (554)  rf=r size=32 type=ud align=2 words (r4.0)

// .inputs
// +----------+----------+--------+----------+------------------+
// | id       | type     |  bytes | at       | from             |
// +----------+----------+--------+----------+------------------+
// | V0039    | :w x 32  |   0x40 | r1       | pti[tid]+0x0     |
// | V0036    | :d x 3   |    0xC | r2       | inline+0x0       |
// | V0038    | :d x 3   |    0xC | r2+0xC   | inline+0xC       |
// | V0043    | :q       |    0x8 | r2+0x18  | inline+0x18      |
// | V0044    | :d       |    0x4 | r3       | cti+0x20         |
// | V0045    | :b       |    0x1 | r3+0x4   | cti+0x24         |
// | V0046    | :b       |    0x1 | r3+0x8   | cti+0x28         |
// | V0047    | :b       |    0x1 | r3+0xC   | cti+0x2C         |
// | V0048    | :b       |    0x1 | r3+0x10  | cti+0x30         |
// | V0049    | :q       |    0x8 | r3+0x18  | cti+0x38         |
// | V0050    | :q       |    0x8 | r3+0x20  | cti+0x40         |
// | V0051    | :q       |    0x8 | r3+0x28  | cti+0x48         |
// | V0052    | :q       |    0x8 | r3+0x30  | cti+0x50         |
// | V0037    | :d x 3   |    0xC | r4       | cti+0x60         |
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
// B002: Preds:{B001},  Succs:{B003, B018}
// _main:
(W)     mov (16|M0)              r75.0<1>:ud   r0.0<1;1,0>:ud                   {Compacted}          //  ALU pipe: int; $1
(W)     or (1|M0)                cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x400004C0:ud              {A@1}    // $1
(W)     mul (1|M0)               acc0.0<1>:ud  r2.3<0;1,0>:ud    r75.2<0;1,0>:uw  {A@1}              //  ALU pipe: int; $3
(W)     macl (1|M0)              r5.0<1>:ud    r2.3<0;1,0>:ud    r75.1<0;1,0>:ud  {Compacted}        //  ALU pipe: int; $4
(W)     mul (1|M0)               acc0.0<1>:ud  r2.3<0;1,0>:ud    r75.2<0;1,0>:uw                     //  ALU pipe: int; $4
(W)     mach (1|M0)              r6.0<1>:d     r2.3<0;1,0>:ud    r75.1<0;1,0>:ud                     //  ALU pipe: int; 
        mov (16|M0)              r7.0<4>:uw    r1.0<1;1,0>:uw                   {$0.dst}             //  ALU pipe: int; $15
        mov (16|M16)             r11.0<4>:uw   r1.16<1;1,0>:uw                                       //  ALU pipe: int; $15
(W)     mov (1|M0)               r5.1<1>:d     r6.0<0;1,0>:d                    {Compacted,I@3}      //  ALU pipe: int; $9
(W)     mov (2|M0)               r85.0<1>:d    r2.6<1;1,0>:d                    {Compacted}          //  ALU pipe: int; $2
        add (16|M0)              r9.0<1>:q     r5.0<0;1,0>:q     r7.0<4;1,0>:uw   {I@2}              //  ALU pipe: int; $15
        add (16|M16)             r13.0<1>:q    r5.0<0;1,0>:q     r11.0<4;1,0>:uw                     //  ALU pipe: int; $15
        add (16|M0)              r106.0<1>:q   r9.0<1;1,0>:q     r2.0<0;1,0>:ud   {I@2}              //  ALU pipe: int; $17
        add (16|M16)             r108.0<1>:q   r13.0<1;1,0>:q    r2.0<0;1,0>:ud   {I@2}              //  ALU pipe: int; $17
        mov (16|M0)              r86.0<1>:d    r106.0<2;1,0>:d                  {Compacted,I@2}      //  ALU pipe: int; $18
        mov (16|M16)             r87.0<1>:d    r108.0<2;1,0>:d                  {Compacted,I@2}      //  ALU pipe: int; $19
        cmp (32|M0)   (lt)f3.0   null<1>:ud    r86.0<1;1,0>:ud   r85.0<0;1,0>:ud  {I@1}              //  ALU pipe: int; $22
        mov (16|M0)              r88.0<1>:d    r106.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $20
        mov (16|M16)             r89.0<1>:d    r108.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $21
(f3.0)  cmp (32|M0)   (eq)f3.0   null<1>:d     r88.0<1;1,0>:d    r85.1<0;1,0>:d   {I@1}              //  ALU pipe: int; $23
(W)     asr (1|M0)               r85.2<1>:d    r3.0<0;1,0>:d     31:w               {$1.dst}         //  ALU pipe: int; $27
(~f3.0) cmp (32|M0)   (lt)f3.0   null<1>:ud    r88.0<1;1,0>:ud   r85.1<0;1,0>:ud                     //  ALU pipe: int; $25
(W)     mul (1|M0)               acc0.0<1>:ud  r3.0<0;1,0>:ud    0x280:uw                            //  ALU pipe: int; $29
(W)     mul (1|M0)               r16.0<1>:d    r85.2<0;1,0>:d    0x280:uw              {I@3}         //  ALU pipe: int; $32
(W)     mach (1|M0)              r15.0<1>:d    r3.0<0;1,0>:ud    0x280:ud                            //  ALU pipe: int; 
(W)     mul (1|M0)               r85.3<1>:ud   r3.0<0;1,0>:ud    0x280:uw                            //  ALU pipe: int; $28
(W)     add (1|M0)               r85.4<1>:d    r15.0<0;1,0>:d    r16.0<0;1,0>:d   {I@2}              //  ALU pipe: int; $34
(~f3.0) goto (32|M0)                         _0_019            _0_019                                //  ALU pipe: int; $35
// B003: [inDivergent],  Preds:{B002},  Succs:{B004}
_0_020:
(W)     mov (1|M0)               r2.8<1>:d     r85.3<0;1,0>:d                   {I@3}                //  ALU pipe: int; $37
(W)     mov (1|M0)               r2.9<1>:d     r85.4<0;1,0>:d                   {I@3}                //  ALU pipe: int; $38
(W)     mov (1|M0)               r12.0<1>:q    r3.0<0;1,0>:d                                         //  ALU pipe: int; $54
(W)     mov (1|M0)               r3.1<1>:df    r2.4<0;1,0>:uq                   {I@2}                //  ALU pipe: long; $42
(W)     mov (1|M0)               r13.0<1>:df   r12.0<0;1,0>:uq                  {I@1}                //  ALU pipe: long; $55
(W)     mov (1|M0)               r4.4<2>:f     r3.1<0;1,0>:df                   {@2,$2.dst}          //  ALU pipe: float; $43
(W)     mov (1|M0)               r14.0<2>:f    r13.0<0;1,0>:df                  {L@1}                //  ALU pipe: float; $56
(W)     math.inv (1|M0)          r5.0<1>:f     r4.4<0;1,0>:f                    {F@2}                //  ALU pipe: math; $44
(W)     mov (1|M0)               r7.0<1>:df    0x3FF0000000000000:df                                 //  ALU pipe: long; $46
(W)     math.inv (1|M0)          r15.0<1>:f    r14.0<0;1,0>:f                   {F@1}                //  ALU pipe: math; $57
(W)     mov (1|M0)               r6.0<1>:df    r5.0<0;1,0>:f                    {M@2}                //  ALU pipe: long; $45
(W)     mov (1|M0)               r16.0<1>:df   r15.0<0;1,0>:f                   {M@1}                //  ALU pipe: long; $58
(W)     mov (1|M0)               r9.0<1>:df    0xBCF0000000000000:df                                 //  ALU pipe: long; $49
(W)     mad (1|M0)               r8.0<1>:df    r7.0<0;0>:df      r6.0<0;0>:df      -r3.1<0>:df      {L@3} //  ALU pipe: long; $47
(W)     mad (1|M0)               r17.0<1>:df   r7.0<0;0>:df      r16.0<0;0>:df     -r13.0<0>:df     {L@3} //  ALU pipe: long; $59
(W)     cmp (32|M0)   (eq)f1.0   null<1>:d     r3.0<0;1,0>:d     0:w                                 //  ALU pipe: int; $52
(W)     cmp (32|M0)   (gt)f0.0   null<1>:d     r3.0<0;1,0>:d     -1:w                                //  ALU pipe: int; $53
(W)     add (1|M0)               r11.0<1>:df   r8.0<0;1,0>:df    r9.0<0;1,0>:df   {Compacted,L@2}    //  ALU pipe: long; $49
(W)     add (1|M0)               r19.0<1>:df   r17.0<0;1,0>:df   r9.0<0;1,0>:df   {Compacted,L@2}    //  ALU pipe: long; $60
(W)     and (1|M0)               r85.5<1>:d    r85.3<0;1,0>:d    -128:w                              //  ALU pipe: int; $51
(W)     mov (1|M0)               r85.6<1>:q    r4.0<0;1,0>:ud                                        //  ALU pipe: int; $62
(W)     mov (1|M0)               r85.7<1>:ud   0x43FF0000:ud                                         //  ALU pipe: int; $63
(W)     mov (1|M0)               r85.7<1>:df   0x41F0000000000000:df                                 //  ALU pipe: long; $64
(W)     mov (1|M0)               r85.6<2>:d    r2.4<0;1,0>:q                                         //  ALU pipe: int; $41
(W)     mad (1|M0)               r85.4<1>:df   r6.0<0;0>:df      r11.0<0;0>:df     r6.0<0>:df       {L@3} //  ALU pipe: long; $50
(W)     mad (1|M0)               r85.5<1>:df   r16.0<0;0>:df     r19.0<0;0>:df     r16.0<0>:df      {L@3} //  ALU pipe: long; $61
// B004: [inDivergent],  Preds:{B017, B003},  Succs:{B005, B009}
_0_021:
        or (16|M0)               r7.0<1>:d     r85.4<0;1,0>:d    r106.1<2;1,0>:d                     //  ALU pipe: int; $70
        or (16|M16)              r8.0<1>:d     r85.4<0;1,0>:d    r108.1<2;1,0>:d                     //  ALU pipe: int; $71
        cmp (32|M0)   (lt)f2.0   null<1>:ud    r7.0<1;1,0>:ud    0x1:uw              {I@1}           //  ALU pipe: int; $72
        mov (16|M0)              r90.0<1>:d    r106.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $66
        mov (16|M16)             r91.0<1>:d    r108.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $67
        mov (16|M0)              r5.0<1>:d     r106.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $68
        mov (16|M16)             r6.0<1>:d     r108.1<2;1,0>:d                  {Compacted,L@2}      //  ALU pipe: int; $69
(~f2.0) goto (32|M0)                         _0_022            _0_022                                //  ALU pipe: int; $73
// B005: [inDivergent],  Preds:{B004},  Succs:{B006, B007}
_0_023:
(W&~f1.0) jmpi                               _0_024                                                  //  ALU pipe: int; $75
// B006: [inDivergent],  Preds:{B005},  Succs:{B008}
_0_025:
        mov (32|M0)              r92.0<1>:d    -1:w                               {Compacted}        //  ALU pipe: int; $77
(W)     jmpi                                 _0_026                                                  // $78
// B007: [inDivergent],  Preds:{B005},  Succs:{B008}
_0_024:
        mov (16|M0)              r5.0<1>:d     r106.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $80
        mov (16|M16)             r6.0<1>:d     r108.0<2;1,0>:d                                       //  ALU pipe: int; $80
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $81
(W)     mov (1|M0)               r8.0<1>:f     r85.6<0;1,0>:ud                  {A@1}                //  ALU pipe: float; $82
(W)     mov (1|M0)               r15.0<1>:f    0xB4C00000:f                               {Compacted} //  ALU pipe: float; $87
(W)     math.inv (1|M0)          r14.0<1>:f    r8.0<0;1,0>:f                    {F@2}                //  ALU pipe: math; $86
        mov (32|M0)              r11.0<1>:f    r5.0<1;1,0>:ud                   {I@2}                //  ALU pipe: float; $85
(W)     mad (1|M0)               r16.0<1>:f    r14.0<0;0>:f      r15.0<0;0>:f      r14.0<0>:f       {Compacted,A@1} //  ALU pipe: float; $87
        mov (32|M0)              r19.0<1>:ud   r11.0<1;1,0>:f                   {F@2}                //  ALU pipe: int; $89
        mul (32|M0)              r17.0<1>:f    r11.0<1;1,0>:f    r16.0<0;1,0>:f   {Compacted,F@1}    //  ALU pipe: float; $88
(W)     mov (1|M0)               r9.0<1>:ud    r8.0<0;1,0>:f                                         //  ALU pipe: int; $83
        add (32|M0)              r21.0<1>:d    r5.0<1;1,0>:d     -r19.0<1;1,0>:d  {Compacted,I@2}    //  ALU pipe: int; $90
        mov (32|M0)              r23.0<1>:ud   r17.0<1;1,0>:f                   {F@1}                //  ALU pipe: int; $91
(W)     add (1|M0)               r10.0<1>:d    r85.6<0;1,0>:d    -r9.0<0;1,0>:d   {I@3}              //  ALU pipe: int; $84
        mov (32|M0)              r31.0<1>:f    r23.0<1;1,0>:ud                  {I@2}                //  ALU pipe: float; $94
        mov (32|M0)              r27.0<1>:f    r21.0<1;1,0>:ud                                       //  ALU pipe: float; $93
(W)     mov (1|M0)               r26.0<1>:f    r10.0<0;1,0>:ud                  {I@1}                //  ALU pipe: float; $92
        mad (32|M0)              acc0.0<1>:f   r11.0<1;0>:f      r31.0<1;0>:f      -r8.0<0>:f       {F@3} //  ALU pipe: float; $96
        mad (32|M0)              acc2.0<1>:f   r27.0<1;0>:f      r31.0<1;0>:f      -r26.0<0>:f      {F@2} //  ALU pipe: float; $98
        add (32|M0)              acc0.0<1>:f   acc0.0<1;1,0>:f   acc2.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $99
        mul (32|M0)              r33.0<1>:f    r16.0<0;1,0>:f    acc0.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $100
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $101
        mov (32|M0)              r35.0<1>:ud   r33.0<1;1,0>:f                   {A@1}                //  ALU pipe: int; $102
        add (32|M0)              r37.0<1>:d    r35.0<1;1,0>:d    r23.0<1;1,0>:d   {Compacted,I@1}    //  ALU pipe: int; $103
(W)     mul (16|M0)              acc0.0<1>:d   r37.0<1;1,0>:d    r85.12<0;1,0>:uw {I@1}              //  ALU pipe: int; $104 R{} IR{}{O:2,O:2,},  {BC=1}
        macl (16|M0)             r39.0<1>:d    r37.0<1;1,0>:d    r85.6<0;1,0>:d   {Compacted}        //  ALU pipe: int; $104
(W)     mul (16|M16)             acc0.0<1>:d   r38.0<1;1,0>:d    r85.12<0;1,0>:uw                    //  ALU pipe: int; $104
        macl (16|M16)            r40.0<1>:d    r38.0<1;1,0>:d    r85.6<0;1,0>:d   {Compacted}        //  ALU pipe: int; $105
        add (32|M0)              r41.0<1>:d    r5.0<1;1,0>:d     -r39.0<1;1,0>:d  {Compacted,I@1}    //  ALU pipe: int; $105
        cmp (32|M0)   (ge)f2.0   r44.0<1>:ud   r41.0<1;1,0>:ud   r85.6<0;1,0>:ud  {I@1}              //  ALU pipe: int; $106
        add3 (32|M0)             r92.0<1>:d    r35.0<1;0>:d      r23.0<1;0>:d      -r44.0<1>:d      {Compacted,I@1} //  ALU pipe: int; $107
// B008: [inDivergent],  Preds:{B007, B006},  Succs:{B010}
_0_026:
        mov (16|M0)              r5.0<2>:ud    r92.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $109
        mov (16|M16)             r7.0<2>:ud    r93.0<1;1,0>:ud                                       //  ALU pipe: int; $109
        mov (16|M0)              r110.0<1>:q   r5.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $109
        mov (16|M16)             r112.0<1>:q   r7.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $109
        goto (32|M0)                         _0_022            _0_027                                // $110
// B009: [inDivergent],  Preds:{B004},  Succs:{B010}
_0_022:
        join (32|M0)                         _0_027                                                  // 
L1600:
        mov (16|M0)              r5.0<1>:d     r106.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $112
        mov (16|M16)             r6.0<1>:d     r108.1<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $113
        mov (16|M0)              r7.0<2>:ud    r5.0<1;1,0>:ud                   {Compacted,I@2}      //  ALU pipe: int; $114
        mov (16|M16)             r11.0<2>:ud   r6.0<1;1,0>:ud                   {Compacted,I@2}      //  ALU pipe: int; $114
        mov (16|M0)              r9.0<1>:df    r7.0<2;1,0>:ud                   {I@2}                //  ALU pipe: long; $114
        mov (16|M16)             r13.0<1>:df   r11.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $114
        mul (16|M0)              r15.0<1>:df   r85.4<0;1,0>:df   r9.0<1;1,0>:df   {Compacted,L@2}    //  ALU pipe: long; $115
        mul (16|M16)             r17.0<1>:df   r85.4<0;1,0>:df   r13.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $115
        mov (16|M0)              r19.0<2>:ud   r15.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $116
        mov (16|M16)             r23.0<2>:ud   r17.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $116
        mov (16|M0)              r21.0<1>:ud   r19.0<2;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $116
        mov (16|M16)             r22.0<1>:ud   r23.0<2;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $116
(W)     mul (16|M0)              acc0.0<1>:d   r21.0<1;1,0>:d    r85.12<0;1,0>:uw {I@2}              //  ALU pipe: int; $117 R{} IR{}{O:2,O:2,},  {BC=1}
        macl (16|M0)             r25.0<1>:d    r21.0<1;1,0>:d    r85.6<0;1,0>:d   {Compacted}        //  ALU pipe: int; $117
(W)     mul (16|M16)             acc0.0<1>:d   r22.0<1;1,0>:d    r85.12<0;1,0>:uw {I@3}              //  ALU pipe: int; $117
        macl (16|M16)            r26.0<1>:d    r22.0<1;1,0>:d    r85.6<0;1,0>:d   {Compacted}        //  ALU pipe: int; $118
        add (32|M0)              r27.0<1>:d    r5.0<1;1,0>:d     -r25.0<1;1,0>:d  {Compacted,I@1}    //  ALU pipe: int; $118
        mov (16|M0)              r29.0<2>:ud   r27.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $120
        mov (16|M16)             r34.0<2>:ud   r28.0<1;1,0>:ud                                       //  ALU pipe: int; $120
        mov (16|M0)              r39.0<1>:df   r106.0<2;1,0>:ud                                      //  ALU pipe: long; $121
        mov (16|M16)             r41.0<1>:df   r108.0<2;1,0>:ud                                      //  ALU pipe: long; $121
        mov (16|M0)              r32.0<1>:df   r29.0<2;1,0>:ud                  {I@2}                //  ALU pipe: long; $120
        mov (16|M16)             r36.0<1>:df   r34.0<2;1,0>:ud                  {I@1}                //  ALU pipe: long; $120
        mad (16|M0)              r43.0<1>:df   r39.0<1;0>:df     r32.0<1;0>:df     r85.7<0>:df      {Compacted,L@2} //  ALU pipe: long; $122
        mad (16|M16)             r45.0<1>:df   r41.0<1;0>:df     r36.0<1;0>:df     r85.7<0>:df      {Compacted,L@2} //  ALU pipe: long; $122
        mul (16|M0)              r47.0<1>:df   r85.4<0;1,0>:df   r43.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $123
        mul (16|M16)             r49.0<1>:df   r85.4<0;1,0>:df   r45.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $123
        mov (16|M0)              r51.0<1>:uq   r47.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $124
        mov (16|M16)             r53.0<1>:uq   r49.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $124
        shr (16|M0)              r59.0<1>:uq   r51.0<1;1,0>:uq   32:w               {I@2}            //  ALU pipe: int; $128
        shr (16|M16)             r61.0<1>:uq   r53.0<1;1,0>:uq   32:w               {I@2}            //  ALU pipe: int; $128
        mov (16|M0)              r63.0<1>:d    r59.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $129
        mov (16|M16)             r64.0<1>:d    r61.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $130
        cmp (32|M0)   (eq)f2.0   null<1>:d     r63.0<1;1,0>:d    0:w               {I@1}             //  ALU pipe: int; $135
        mov (16|M0)              r65.0<1>:d    r59.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $131
        mov (16|M16)             r66.0<1>:d    r61.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $132
        mov (16|M0)              r57.0<1>:d    r51.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $127
(f2.0)  cmp (32|M0)   (eq)f2.0   null<1>:d     r65.0<1;1,0>:d    0:w               {I@2}             //  ALU pipe: int; $136
        mov (16|M16)             r58.0<1>:d    r53.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $127
        mov (16|M0)              r55.0<1>:d    r51.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $125
(W)     mul (16|M0)              acc0.0<1>:d   r57.0<1;1,0>:d    r85.8<0;1,0>:uw  {I@4}              //  ALU pipe: int; $138
        mov (16|M16)             r56.0<1>:d    r53.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $126
        macl (16|M0)             r69.0<1>:d    r57.0<1;1,0>:d    r85.4<0;1,0>:d                      //  ALU pipe: int; $138
(W)     mul (16|M16)             acc0.0<1>:d   r58.0<1;1,0>:d    r85.8<0;1,0>:uw  {I@5}              //  ALU pipe: int; $138
(~f2.0) sel (32|M0)              r71.0<1>:d    r85.6<0;1,0>:d    0:w                                 //  ALU pipe: int; $139
        macl (16|M16)            r70.0<1>:d    r58.0<1;1,0>:d    r85.4<0;1,0>:d   {Compacted}        //  ALU pipe: int; $139
(W)     mul (16|M0)              acc0.0<1>:ud  r55.0<1;1,0>:ud   r85.10<0;1,0>:uw {I@7}              //  ALU pipe: int; $148
        macl (16|M0)             r7.0<1>:ud    r55.0<1;1,0>:ud   r85.5<0;1,0>:ud  {Compacted}        //  ALU pipe: int; $149
(W)     mul (16|M16)             acc0.0<1>:ud  r56.0<1;1,0>:ud   r85.10<0;1,0>:uw {I@7}              //  ALU pipe: int; $149
        add (32|M0)              r76.0<1>:d    r69.0<1;1,0>:d    r71.0<1;1,0>:d   {Compacted,I@4}    //  ALU pipe: int; $140
        macl (16|M16)            r10.0<1>:ud   r56.0<1;1,0>:ud   r85.5<0;1,0>:ud  {Compacted}        //  ALU pipe: int; $150
(W)     mul (16|M0)              acc0.0<1>:ud  r55.0<1;1,0>:ud   r85.10<0;1,0>:uw                    //  ALU pipe: int; $150
        mach (16|M0)             r13.0<1>:d    r55.0<1;1,0>:ud   r85.5<0;1,0>:ud                     //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r56.0<1;1,0>:ud   r85.10<0;1,0>:uw                    //  ALU pipe: int; $150
        mach (16|M16)            r14.0<1>:d    r56.0<1;1,0>:ud   r85.5<0;1,0>:ud                     //  ALU pipe: int; $152
        add3 (32|M0)             r78.0<1>:d    r5.0<1;0>:d       -r25.0<1;0>:d     -r76.0<1>:d      {I@6} //  ALU pipe: int; $141
        mov (32|M0)              r80.0<1>:f    r90.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $142
        mov (32|M0)              r15.0<1>:d    0:w                               {Compacted}         //  ALU pipe: int; $153
        mov (16|M0)              r8.0<2>:ud    r7.0<1;1,0>:ud                   {Compacted}          //  ALU pipe: int; $149
        mov (16|M16)             r11.0<2>:ud   r10.0<1;1,0>:ud                  {Compacted,I@7}      //  ALU pipe: int; $150
        mov (16|M0)              r82.0<2>:d    r80.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $144
        mov (16|M16)             r5.0<2>:d     r81.0<1;1,0>:d                                        //  ALU pipe: int; $145
        add (16|M0)              r8.1<2>:d     r13.0<1;1,0>:d    r15.0<1;1,0>:d   {I@5}              //  ALU pipe: int; $154
        add (16|M16)             r11.1<2>:d    r14.0<1;1,0>:d    r16.0<1;1,0>:d                      //  ALU pipe: int; $155
        mov (16|M0)              r82.1<2>:d    r78.0<1;1,0>:d                                        //  ALU pipe: int; $146
        mov (16|M16)             r5.1<2>:d     r79.0<1;1,0>:d                                        //  ALU pipe: int; $147
        add (16|M0)              r17.0<1>:q    r82.0<1;1,0>:q    -r8.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $156
        add (16|M16)             r19.0<1>:q    r5.0<1;1,0>:q     -r11.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $156
        mov (16|M0)              r23.0<1>:d    r17.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $157
        mov (16|M16)             r24.0<1>:d    r19.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $158
        cmp (32|M0)   (ge)f3.0   null<1>:ud    r23.0<1;1,0>:ud   r85.3<0;1,0>:ud  {I@1}              //  ALU pipe: int; $168
        mov (16|M0)              r25.0<1>:d    r17.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $159
        mov (16|M16)             r26.0<1>:d    r19.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $160
(f3.0)  cmp (32|M0)   (eq)f3.0   null<1>:d     r25.0<1;1,0>:d    r85.4<0;1,0>:d   {I@1}              //  ALU pipe: int; $169
(~f3.0) cmp (32|M0)   (gt)f3.0   null<1>:ud    r25.0<1;1,0>:ud   r85.4<0;1,0>:ud                     //  ALU pipe: int; $171
(W)     mov (1|M0)               r35.0<1>:hf   0xFFFF:hf                                             //  ALU pipe: float; $173
        mov (16|M0)              r67.0<1>:d    r51.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $133
        mov (16|M16)             r68.0<1>:d    r53.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $134
(f3.0)  sel (32|M0)              r36.0<1>:d    r35.0<0;1,0>:w    0:w               {F@1}             //  ALU pipe: int; $173
        add (32|M0)              r27.0<1>:d    r67.0<1;1,0>:d    r21.0<1;1,0>:d   {Compacted,I@2}    //  ALU pipe: int; $161
        mov (32|M0)              r29.0<1>:f    r55.0<1;1,0>:f                   {Compacted}          //  ALU pipe: float; $162
        mov (16|M0)              r38.0<2>:ud   r36.0<1;1,0>:ud                  {Compacted,I@2}      //  ALU pipe: int; $174
        mov (16|M16)             r42.0<2>:ud   r37.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $174
        mov (16|M0)              r31.0<2>:d    r29.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $164
        mov (16|M16)             r33.0<2>:d    r30.0<1;1,0>:d                                        //  ALU pipe: int; $165
        mov (16|M0)              r40.0<1>:q    r38.0<2;1,0>:d                   {I@4}                //  ALU pipe: int; $174
        mov (16|M16)             r44.0<1>:q    r42.0<2;1,0>:d                   {I@4}                //  ALU pipe: int; $174
        mov (16|M0)              r31.1<2>:d    r27.0<1;1,0>:d                                        //  ALU pipe: int; $166
        mov (16|M16)             r33.1<2>:d    r28.0<1;1,0>:d                                        //  ALU pipe: int; $167
        add (16|M0)              r110.0<1>:q   r31.0<1;1,0>:q    -r40.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $175
        add (16|M16)             r112.0<1>:q   r33.0<1;1,0>:q    -r44.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $175
// B010: [inDivergent],  Preds:{B009, B008},  Succs:{B011, B015}
_0_027:
        join (32|M0)                         _0_019                                                  // 
L2704:
        mov (16|M0)              r95.0<1>:d    r106.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $177
        mov (16|M16)             r96.0<1>:d    r108.0<2;1,0>:d                  {Compacted}          //  ALU pipe: int; $177
(W)     mul (16|M0)              acc0.0<1>:ud  r95.0<1;1,0>:ud   0xCCCD:uw              {I@2}        //  ALU pipe: int; $178
        mach (16|M0)             r5.0<1>:ud    r95.0<1;1,0>:ud   0xCCCCCCCD:ud                       //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r96.0<1;1,0>:ud   0xCCCD:uw              {I@3}        //  ALU pipe: int; $178
        mach (16|M16)            r6.0<1>:ud    r96.0<1;1,0>:ud   0xCCCCCCCD:ud                       //  ALU pipe: int; $179
        shr (32|M0)              r100.0<1>:ud  r5.0<1;1,0>:ud    9:w               {I@1}             //  ALU pipe: int; $179
(W&~f0.0) jmpi                               _0_028                                                  //  ALU pipe: int; $180
// B011: [inDivergent],  Preds:{B010},  Succs:{B012, B013}
_0_029:
(W&~f1.0) jmpi                               _0_030                                                  //  ALU pipe: int; $182
// B012: [inDivergent],  Preds:{B011},  Succs:{B014}
_0_031:
        mov (32|M0)              r97.0<1>:d    -1:w                                                  //  ALU pipe: int; $184
(W)     jmpi                                 _0_032                                                  // $185
// B013: [inDivergent],  Preds:{B011},  Succs:{B014}
_0_030:
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $187
(W)     mov (1|M0)               r2.8<1>:f     r3.0<0;1,0>:ud                   {A@1}                //  ALU pipe: float; $188
(W)     mov (1|M0)               r9.0<1>:f     0xB4C00000:f                               {Compacted} //  ALU pipe: float; $193
(W)     math.inv (1|M0)          r8.0<1>:f     r2.8<0;1,0>:f                    {F@2}                //  ALU pipe: math; $192
        mov (32|M0)              r5.0<1>:f     r100.0<1;1,0>:ud                 {I@6}                //  ALU pipe: float; $191
(W)     mad (1|M0)               r10.0<1>:f    r8.0<0;0>:f       r9.0<0;0>:f       r8.0<0>:f        {Compacted,A@1} //  ALU pipe: float; $193
        mov (32|M0)              r13.0<1>:ud   r5.0<1;1,0>:f                    {F@2}                //  ALU pipe: int; $195
        mul (32|M0)              r11.0<1>:f    r5.0<1;1,0>:f     r10.0<0;1,0>:f   {Compacted,F@1}    //  ALU pipe: float; $194
(W)     mov (1|M0)               r3.1<1>:ud    r2.8<0;1,0>:f                                         //  ALU pipe: int; $189
        add (32|M0)              r15.0<1>:d    r100.0<1;1,0>:d   -r13.0<1;1,0>:d  {Compacted,I@2}    //  ALU pipe: int; $196
        mov (32|M0)              r17.0<1>:ud   r11.0<1;1,0>:f                   {F@1}                //  ALU pipe: int; $197
(W)     add (1|M0)               r4.3<1>:d     r3.0<0;1,0>:d     -r3.1<0;1,0>:d   {I@3}              //  ALU pipe: int; $190
        mov (32|M0)              r25.0<1>:f    r17.0<1;1,0>:ud                  {I@2}                //  ALU pipe: float; $200
        mov (32|M0)              r21.0<1>:f    r15.0<1;1,0>:ud                                       //  ALU pipe: float; $199
(W)     mov (1|M0)               r20.0<1>:f    r4.3<0;1,0>:ud                   {I@1}                //  ALU pipe: float; $198
        mad (32|M0)              acc0.0<1>:f   r5.0<1;0>:f       r25.0<1;0>:f      -r2.8<0>:f       {F@3} //  ALU pipe: float; $202
        mad (32|M0)              acc2.0<1>:f   r21.0<1;0>:f      r25.0<1;0>:f      -r20.0<0>:f      {F@2} //  ALU pipe: float; $204
        add (32|M0)              acc0.0<1>:f   acc0.0<1;1,0>:f   acc2.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $205
        mul (32|M0)              r27.0<1>:f    r10.0<0;1,0>:f    acc0.0<1;1,0>:f  {Compacted}        //  ALU pipe: float; $206
(W)     xor (1|M0)               cr0.0<1>:ud   cr0.0<0;1,0>:ud   0x30:uw              {A@1}          // $207
        mov (32|M0)              r29.0<1>:ud   r27.0<1;1,0>:f                   {A@1}                //  ALU pipe: int; $208
        add (32|M0)              r31.0<1>:d    r29.0<1;1,0>:d    r17.0<1;1,0>:d   {Compacted,I@1}    //  ALU pipe: int; $209
(W)     mul (16|M0)              acc0.0<1>:d   r31.0<1;1,0>:d    r3.0<0;1,0>:uw   {I@1}              //  ALU pipe: int; $210
        macl (16|M0)             r33.0<1>:d    r31.0<1;1,0>:d    r3.0<0;1,0>:d    {Compacted}        //  ALU pipe: int; $210
(W)     mul (16|M16)             acc0.0<1>:d   r32.0<1;1,0>:d    r3.0<0;1,0>:uw                      //  ALU pipe: int; $210
        macl (16|M16)            r34.0<1>:d    r32.0<1;1,0>:d    r3.0<0;1,0>:d    {Compacted}        //  ALU pipe: int; $211
        add (32|M0)              r35.0<1>:d    r100.0<1;1,0>:d   -r33.0<1;1,0>:d  {Compacted,I@1}    //  ALU pipe: int; $211
        cmp (32|M0)   (lt)f3.0   null<1>:ud    r35.0<1;1,0>:ud   r3.0<0;1,0>:ud   {I@1}              //  ALU pipe: int; $212 R{} IR{}{O:1,O:1,},  R{r3,} IR{} {BC=1}
(~f3.0) sel (32|M0)              r37.0<1>:d    r3.0<0;1,0>:d     0:w                                 //  ALU pipe: int; $213
        add3 (32|M0)             r97.0<1>:d    r100.0<1;0>:d     -r33.0<1;0>:d     -r37.0<1>:d      {I@1} //  ALU pipe: int; $214
// B014: [inDivergent],  Preds:{B013, B012},  Succs:{B016}
_0_032:
        mov (16|M0)              r5.0<2>:ud    r97.0<1;1,0>:ud                  {Compacted,I@1}      //  ALU pipe: int; $216
        mov (16|M16)             r7.0<2>:ud    r98.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $216
        mov (16|M0)              r114.0<1>:q   r5.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $216
        mov (16|M16)             r116.0<1>:q   r7.0<2;1,0>:ud                   {I@2}                //  ALU pipe: int; $216
(W)     jmpi                                 _0_033                                                  // $217
// B015: [inDivergent],  Preds:{B010},  Succs:{B016}
_0_028:
        mov (16|M0)              r5.0<2>:ud    r100.0<1;1,0>:ud                 {Compacted}          //  ALU pipe: int; $219
        mov (16|M16)             r9.0<2>:ud    r101.0<1;1,0>:ud                 {Compacted}          //  ALU pipe: int; $219
        mov (16|M0)              r7.0<1>:df    r5.0<2;1,0>:ud                   {I@2}                //  ALU pipe: long; $219
        mov (16|M16)             r11.0<1>:df   r9.0<2;1,0>:ud                   {I@1}                //  ALU pipe: long; $219
        mul (16|M0)              r13.0<1>:df   r85.5<0;1,0>:df   r7.0<1;1,0>:df   {Compacted,L@2}    //  ALU pipe: long; $220
        mul (16|M16)             r15.0<1>:df   r85.5<0;1,0>:df   r11.0<1;1,0>:df  {Compacted,L@2}    //  ALU pipe: long; $220
        mov (16|M0)              r17.0<1>:uq   r13.0<1;1,0>:df                  {L@2}                //  ALU pipe: int; $221
        mov (16|M16)             r19.0<1>:uq   r15.0<1;1,0>:df                  {L@1}                //  ALU pipe: int; $221
        mov (16|M0)              r23.0<1>:d    r17.1<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $224
        mov (16|M16)             r24.0<1>:d    r19.1<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $225
        mov (16|M0)              r21.0<1>:d    r17.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $222
        mov (16|M16)             r22.0<1>:d    r19.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $223
        cmp (32|M0)   (lt)f2.0   null<1>:ud    r23.0<1;1,0>:ud   0x1:uw              {I@3}           //  ALU pipe: int; $227
(W)     mul (16|M0)              acc0.0<1>:ud  r21.0<1;1,0>:ud   r3.0<0;1,0>:uw   {I@3}              //  ALU pipe: int; $236
        macl (16|M0)             r37.0<1>:ud   r21.0<1;1,0>:ud   r3.0<0;1,0>:ud   {Compacted}        //  ALU pipe: int; $237
(W)     mul (16|M16)             acc0.0<1>:ud  r22.0<1;1,0>:ud   r3.0<0;1,0>:uw   {I@4}              //  ALU pipe: int; $237
        macl (16|M16)            r40.0<1>:ud   r22.0<1;1,0>:ud   r3.0<0;1,0>:ud   {Compacted}        //  ALU pipe: int; $238
(W)     mul (16|M0)              acc0.0<1>:ud  r21.0<1;1,0>:ud   r3.0<0;1,0>:uw                      //  ALU pipe: int; $238
        mov (16|M0)              r25.0<1>:d    r17.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $226
        mov (16|M16)             r26.0<1>:d    r19.0<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $226
(~f2.0) sel (32|M0)              r27.0<1>:d    r3.0<0;1,0>:d     0:w                                 //  ALU pipe: int; $228
        mach (16|M0)             r43.0<1>:d    r21.0<1;1,0>:ud   r3.0<0;1,0>:ud                      //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r22.0<1;1,0>:ud   r3.0<0;1,0>:uw                      //  ALU pipe: int; $238
        mach (16|M16)            r44.0<1>:d    r22.0<1;1,0>:ud   r3.0<0;1,0>:ud                      //  ALU pipe: int; $240
        add (32|M0)              r29.0<1>:d    r25.0<1;1,0>:d    -r27.0<1;1,0>:d  {Compacted,I@4}    //  ALU pipe: int; $229
        mov (32|M0)              r31.0<1>:f    r100.0<1;1,0>:f                  {Compacted}          //  ALU pipe: float; $230
        mov (32|M0)              r45.0<1>:d    0:w                               {Compacted}         //  ALU pipe: int; $241
        mov (16|M0)              r38.0<2>:ud   r37.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $237
        mov (16|M16)             r41.0<2>:ud   r40.0<1;1,0>:ud                                       //  ALU pipe: int; $238
        mov (16|M0)              r33.0<2>:d    r31.0<1;1,0>:d                   {F@1}                //  ALU pipe: int; $232
        mov (16|M16)             r35.0<2>:d    r32.0<1;1,0>:d                                        //  ALU pipe: int; $233
        add (16|M0)              r38.1<2>:d    r43.0<1;1,0>:d    r45.0<1;1,0>:d   {I@5}              //  ALU pipe: int; $242
        add (16|M16)             r41.1<2>:d    r44.0<1;1,0>:d    r46.0<1;1,0>:d                      //  ALU pipe: int; $243
        mov (16|M0)              r33.1<2>:d    r29.0<1;1,0>:d                                        //  ALU pipe: int; $234
        mov (16|M16)             r35.1<2>:d    r30.0<1;1,0>:d                                        //  ALU pipe: int; $235
        add (16|M0)              r47.0<1>:q    r33.0<1;1,0>:q    -r38.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $244
        add (16|M16)             r49.0<1>:q    r35.0<1;1,0>:q    -r41.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $244
        mov (16|M0)              r51.0<1>:d    r47.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $245
        mov (16|M16)             r52.0<1>:d    r49.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $246
        cmp (32|M0)   (lt)f2.0   null<1>:ud    r51.0<1;1,0>:ud   r3.0<0;1,0>:ud   {I@1}              //  ALU pipe: int; $249 R{} IR{}{O:1,O:1,},  R{r3,} IR{} {BC=1}
        mov (16|M0)              r53.0<1>:d    r47.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $247
        mov (16|M16)             r54.0<1>:d    r49.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $248
(f2.0)  cmp (32|M0)   (eq)f2.0   null<1>:d     r53.0<1;1,0>:d    r85.2<0;1,0>:d   {I@1}              //  ALU pipe: int; $250 R{} IR{}{O:2,O:2,},  R{r85,} IR{} {BC=1}
(~f2.0) cmp (32|M0)   (lt)f2.0   null<1>:ud    r53.0<1;1,0>:ud   r85.2<0;1,0>:ud                     //  ALU pipe: int; $252
(~f2.0) sel (32|M0)              r55.0<1>:d    r3.0<0;1,0>:d     0:w                                 //  ALU pipe: int; $254
(~f2.0) sel (32|M0)              r57.0<1>:d    r85.2<0;1,0>:d    0:w                                 //  ALU pipe: int; $255
        mov (16|M0)              r59.0<2>:d    r55.0<1;1,0>:d                   {I@2}                //  ALU pipe: int; $258
        mov (16|M16)             r61.0<2>:d    r56.0<1;1,0>:d                                        //  ALU pipe: int; $259
        mov (16|M0)              r59.1<2>:d    r57.0<1;1,0>:d                   {I@3}                //  ALU pipe: int; $260
        mov (16|M16)             r61.1<2>:d    r58.0<1;1,0>:d                                        //  ALU pipe: int; $261
        add (16|M0)              r114.0<1>:q   r47.0<1;1,0>:q    -r59.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $262
        add (16|M16)             r116.0<1>:q   r49.0<1;1,0>:q    -r61.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $262
// B016: [inDivergent],  Preds:{B015, B014},  Succs:{B017, B018}
_0_033:
        shl (16|M0)              r5.0<1>:q     r110.0<1;1,0>:q   4:w               {Compacted}       //  ALU pipe: int; $268
        shl (16|M16)             r7.0<1>:q     r112.0<1;1,0>:q   4:w               {Compacted}       //  ALU pipe: int; $268
        add (16|M0)              r15.0<1>:q    r5.0<1;1,0>:q     r114.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $269
        add (16|M16)             r17.0<1>:q    r7.0<1;1,0>:q     r116.0<1;1,0>:q  {Compacted,I@2}    //  ALU pipe: int; $269
        mov (16|M0)              r27.0<1>:d    r15.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $270
        mov (16|M16)             r28.0<1>:d    r17.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $271
        mad (32|M0)              r9.0<1>:d     r95.0<1;0>:d      r100.0<1;0>:d     -640:w               //  ALU pipe: int; $264
(W)     mul (16|M0)              acc0.0<1>:ud  r27.0<1;1,0>:ud   0xA00:uw              {I@3}         //  ALU pipe: int; $276
        mov (16|M0)              r29.0<1>:d    r15.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $272
        mov (16|M16)             r30.0<1>:d    r17.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $273
        mach (16|M0)             r39.0<1>:d    r27.0<1;1,0>:ud   0xA00:ud                            //  ALU pipe: int; 
(W)     mul (16|M0)              acc0.0<1>:ud  r28.0<1;1,0>:ud   0xA00:uw              {I@6}         //  ALU pipe: int; $276
        mov (16|M0)              r19.0<2>:ud   r9.0<1;1,0>:ud                   {Compacted,I@6}      //  ALU pipe: int; $266
        mov (16|M16)             r21.0<2>:ud   r10.0<1;1,0>:ud                  {Compacted}          //  ALU pipe: int; $266
        mach (16|M16)            r40.0<1>:d    r28.0<1;1,0>:ud   0xA00:ud                            //  ALU pipe: int; $278
        mul (32|M0)              r37.0<1>:d    r29.0<1;1,0>:d    0xA00:uw              {I@6}         //  ALU pipe: int; $279
        shl (16|M0)              r31.0<1>:q    r19.0<2;1,0>:ud   2:w               {I@4}             //  ALU pipe: int; $266
        shl (16|M16)             r33.0<1>:q    r21.0<2;1,0>:ud   2:w               {I@4}             //  ALU pipe: int; $266
        mul (16|M0)              r35.0<2>:ud   r27.0<1;1,0>:ud   0xA00:uw                            //  ALU pipe: int; $274
        mul (16|M16)             r45.0<2>:ud   r28.0<1;1,0>:ud   0xA00:uw                            //  ALU pipe: int; $275
        add (16|M0)              r41.0<1>:q    r3.3<0;1,0>:q     r31.0<1;1,0>:q   {Compacted,I@4}    //  ALU pipe: int; $267
        add (16|M16)             r43.0<1>:q    r3.3<0;1,0>:q     r33.0<1;1,0>:q   {Compacted,I@4}    //  ALU pipe: int; $267
        add (16|M0)              r35.1<2>:d    r39.0<1;1,0>:d    r37.0<1;1,0>:d                      //  ALU pipe: int; $280
        add (16|M16)             r45.1<2>:d    r40.0<1;1,0>:d    r38.0<1;1,0>:d                      //  ALU pipe: int; $281
        add (16|M0)              r67.0<1>:q    r41.0<1;1,0>:q    r35.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $282
        add (16|M16)             r69.0<1>:q    r43.0<1;1,0>:q    r45.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $282
        shl (16|M0)              r11.0<1>:q    r114.0<1;1,0>:q   2:w               {Compacted}       //  ALU pipe: int; $285
        shl (16|M16)             r13.0<1>:q    r116.0<1;1,0>:q   2:w               {Compacted}       //  ALU pipe: int; $285
        load.ugm.d32.a64 (32|M0)  r71:2         [r67:4]            {I@3,$3} // ex_desc:0x0; desc:0x8200580 // $283
        load.ugm.d32.a64 (32|M0)  r73:2         [r67:4+0x64000]    {$4} // ex_desc:0x64000000; desc:0x8200580 // $284
        add (16|M0)              r23.0<1>:q    r3.6<0;1,0>:q     r11.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $288
        add (16|M16)             r25.0<1>:q    r3.6<0;1,0>:q     r13.0<1;1,0>:q   {Compacted,I@2}    //  ALU pipe: int; $288
        add (16|M0)              r47.0<1>:q    r3.5<0;1,0>:q     r11.0<1;1,0>:q   {Compacted}        //  ALU pipe: int; $286
        add (16|M16)             r49.0<1>:q    r3.5<0;1,0>:q     r13.0<1;1,0>:q   {Compacted}        //  ALU pipe: int; $286
        load.ugm.d32.a64 (32|M0)  r51:2         [r23:4]            {I@3,$5} // ex_desc:0x0; desc:0x8200580 // $289
        load.ugm.d32.a64 (32|M0)  r55:2         [r47:4]            {I@1,$6} // ex_desc:0x0; desc:0x8200580 // $287
        add (16|M0)              r53.0<1>:q    r106.0<1;1,0>:q   r85.6<0;1,0>:q                      //  ALU pipe: int; $299
        add (16|M16)             r57.0<1>:q    r108.0<1;1,0>:q   r85.6<0;1,0>:q                      //  ALU pipe: int; $299
        mov (16|M0)              r102.0<1>:d   r53.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $300
        mov (16|M16)             r103.0<1>:d   r57.0<2;1,0>:d                   {Compacted,I@2}      //  ALU pipe: int; $301
        cmp (32|M0)   (lt)f3.0   null<1>:ud    r102.0<1;1,0>:ud  r85.0<0;1,0>:ud  {I@1}              //  ALU pipe: int; $304
        mov (16|M0)              r104.0<1>:d   r53.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $302
        mov (16|M16)             r105.0<1>:d   r57.1<2;1,0>:d                   {Compacted}          //  ALU pipe: int; $303
(f3.0)  cmp (32|M0)   (eq)f3.0   null<1>:d     r104.0<1;1,0>:d   r85.1<0;1,0>:d   {I@1}              //  ALU pipe: int; $305
        shl (16|M0)              r59.0<1>:q    r106.0<1;1,0>:q   2:w               {Compacted}       //  ALU pipe: int; $296
        shl (16|M16)             r61.0<1>:q    r108.0<1;1,0>:q   2:w               {Compacted}       //  ALU pipe: int; $296
(~f3.0) cmp (32|M0)   (lt)f3.0   null<1>:ud    r104.0<1;1,0>:ud  r85.1<0;1,0>:ud                     //  ALU pipe: int; $307
        add (16|M0)              r63.0<1>:q    r3.4<0;1,0>:q     r59.0<1;1,0>:q   {Compacted,I@3}    //  ALU pipe: int; $297
        sync.nop                             null                             {Compacted,$4.dst}     // $290
        add (32|M0)              r80.0<1>:d    r71.0<1;1,0>:d    r73.0<1;1,0>:d   {$3.dst}           //  ALU pipe: int; $290
        mov (32|M0)              r83.0<1>:f    r80.0<1;1,0>:d                   {I@1}                //  ALU pipe: float; $292
        add (16|M16)             r65.0<1>:q    r3.4<0;1,0>:q     r61.0<1;1,0>:q   {Compacted}        //  ALU pipe: int; $297
        mov (32|M0)              r76.0<1>:f    r51.0<1;1,0>:d                   {$5.dst}             //  ALU pipe: float; $293
        mul (32|M0)              r78.0<1>:f    r55.0<1;1,0>:f    0x3BDB8BAC:f               {$6.dst} //  ALU pipe: float; $291
        mad (32|M0)              acc2.0<1>:f   r83.0<1;0>:f      -r76.0<1;0>:f     r85.7<0>:f       {Compacted,F@2} //  ALU pipe: float; $294
        mul (32|M0)              r5.0<1>:f     r78.0<1;1,0>:f    acc2.0<1;1,0>:f  {F@2}              //  ALU pipe: float; $295
        store.ugm.d32.a64 (32|M0)  [r63:4]      r5:2               {A@1,$7} // ex_desc:0x0; desc:0x8000584 // $298
(~f3.0) goto (32|M0)                         _0_019            _0_019                                //  ALU pipe: int; $309
// B017: [inDivergent],  Preds:{B016},  Succs:{B004}
_0_034:
(f3.0)  sel (32|M0)              r5.0<1>:d     r102.0<1;1,0>:d   r86.0<1;1,0>:d   {$7.src}           //  ALU pipe: int; $311 R{} IR{}{E:3,E:3,},  R{} IR{}{O:3,O:11,},  {BC=1}
(f3.0)  sel (32|M0)              r7.0<1>:d     r104.0<1;1,0>:d   r88.0<1;1,0>:d                      //  ALU pipe: int; $312 R{} IR{}{E:4,E:4,},  R{} IR{}{O:4,O:12,},  {BC=1}
        mov (16|M0)              r106.0<2>:d   r5.0<1;1,0>:d                    {I@2}                //  ALU pipe: int; $315
        mov (16|M16)             r108.0<2>:d   r6.0<1;1,0>:d                                         //  ALU pipe: int; $316
        mov (16|M0)              r106.1<2>:d   r7.0<1;1,0>:d                    {I@3}                //  ALU pipe: int; $317
        mov (16|M16)             r108.1<2>:d   r8.0<1;1,0>:d                                         //  ALU pipe: int; $318
(W)     jmpi                                 _0_021                                                  // $319
// B018: Preds:{B016, B002},  Succs:{}
_0_019:
        join (32|M0)                         L4784                                                   // 
L4784:
(W)     mov (16|M0)              r127.0<1>:f   r75.0<1;1,0>:f                   {$2.src}             //  ALU pipe: float; $321
(W)     send.gtwy (1|M0)         null     r127  null:0  0x0            0x02000010           {EOT,F@1,$8} // wr:1+0, rd:0; end of thread // $321
L4816:
(W)     mov (16|M0)              null<1>:ud    0xE875C6B1:ud                                         // 
(W)     mov (16|M0)              null<1>:ud    0xBC10FADA:ud                                         // 
(W)     mov (16|M0)              null<1>:ud    0x0:ud                                                // 
(W)     mov (16|M0)              null<1>:ud    0x1:ud                                                // 


//.BankConflicts: 7
//.ByteRMWs: 0
//


//.numALUInst: 353
//.accSubDef: 7
//.accSubUse: 7
//.accSubCandidateDef: 8
//.accSubCandidateUse: 8
//
//
//.singlePipeAtOneDistNum: 52
//.allAtOneDistNum: 14
//.syncInstCount: 1
//.tokenReuseCount: 0
//.AfterWriteTokenDepCount: 7
//.AfterReadTokenDepCount: 3

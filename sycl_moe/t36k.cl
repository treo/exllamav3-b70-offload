__kernel void stask2(__global int* p){ p[0] = 5; }
__kernel void addk(__global int* p, int n){ int i = get_global_id(0); if (i < n) p[i] += 1; }


#tic()
#TABLE TAU(I,K)       TRANSITION TIME FROM PROD I TO K
τ = [
    0     2     1.5     1       0.75
    1     0      2     0.75     0.5
    1     1.25   0      1.5      2
    0.5   1      2      0       1.75
    0.7   1.75   2      1.5       0
]

TR = [0.75  0.5  1  0.5  0.7]

#TABLE CTRANS(I,K)       TRANSITION COST FROM PROD I TO K
CTrans = [
    0    760    760   750   760
    745    0     750   770   740
    770   760     0    765   765
    740   740    745    0    750
    740   740    750   750    0
]

TRC = [750  740  760  740  740]

#TABLE CINV(I)      INV COST FOR PRODUCT I AT THE END OF PERIOD T
CInv = 0.0000306


#TABLE COper(I,T)      OPERATING COST FOR PRODUCT I AT THE END OF PERIOD T
#Paper
COper = [0.19  0.32  0.55  0.49  0.38]
#Code
#COper = [0.13  0.22  0.35  0.29  0.25]

#TABLE P(I,T)      SELLING PRICE FOR PRODUCT I AT THE END OF PERIOD T
P = [0.25  0.4  0.65  0.55  0.45]

#TABLE D(I,T)      DEMAND FOR PRODUCT I AT THE END OF PERIOD T
D1 = [
          0          10000        20000        0           10000        20000        0           10000        20000        0           10000        20000        0           10000        20000        0
        15000        10000        5000        15000        10000        5000        15000        10000        5000        15000        10000        5000        15000        10000        5000        15000
        20000        30000        40000       20000        30000        40000       20000        30000        40000       20000        30000        40000       20000        30000        40000       20000
        20000        10000        3000        20000        10000        3000        20000        10000        3000        20000        10000        3000        20000        10000        3000        20000
        20000        10000        2000        20000        10000        2000        20000        10000        2000        20000        10000        2000        20000        10000        2000        20000
]

D2 = [
       10000        20000        0           10000        20000        0           10000        20000
       10000        5000        15000        10000        5000        15000        10000        5000
       30000        40000       20000        30000        40000       20000        30000        40000
       10000        3000        20000        10000        3000        20000        10000        3000
       10000        2000        20000        10000        2000        20000        10000        2000
]

Dlow = hcat(D1,D2)
Dem = Dlow

#PARAMETER R(I)    PRODUCTION RATES FOR PRODUCTS
R = [800  900  1000 1000 1200]

#PARAMETER H(T)    DURATION OF PERIOD T
H = [168 for i in 1:24]

#PARAMETER HT(T)  TOTAL TIME AT THE END OF PERIOD T
HT = [168i for i in 1:24]

#PARAMETER INVI(I)  INITIAL INVENTORY AT HAND
INVI = [0 for i in 1:5]

#run(`cowsay parameters loaded in $(toc())`)

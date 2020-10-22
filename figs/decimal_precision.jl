using SoftPosit, PyPlot, StatsBase, Statistics

include("representable_numbers.jl")

##
float8 = representable_floats(8,3)
float16 = representable_floats(16,5)
bfloat16 = representable_floats(16,8)

f8_am, f8_wda = wcdp_float(float8)
f_am, f_wda = wcdp_float(float16)
bf_am, bf_wda = wcdp_float(bfloat16)

posit8 = Float64.(Posit8.(UInt8.(collect(1:127))))
posit16 = Float64.(Posit16.(UInt16.(collect(1:32767))))
posit16_2 = Float64.(Posit16_2.(UInt16.(collect(1:32767))))

p1_am, p1_wda = wcdp_posit(posit16)
p2_am, p2_wda = wcdp_posit(posit16_2)
p8_am, p8_wda = wcdp_posit(posit8)

i_am = vcat(0.5000001,1.49999999:1:(2^15-1))
i_wda = decprec(i_am,round.(i_am))
i_am[1] = 1

## log fixed point

nint = 7
nfrac = 6

# all integer bit being 1 means NaN
q7p6 = collect((-2.0^(nint-1)):(2.0^-nfrac):(2.0^(nint-1)-1-2.0^-nfrac))
approx16 = 2 .^ q7p6

nint = 5
nfrac = 10
q7p8 = collect((-2.0^(nint-1)):(2.0^-nfrac):(2.0^(nint-1)-2.0^-nfrac))
logfixp16 = 2 .^ q7p8

a16_am, a16_wda = wcdp_approx(approx16)
lfxp16_am, lfxp16_wda = wcdp_approx(logfixp16)

## PLOTTING
ioff()
fig,ax1 = subplots(1,1,figsize=(7,3))

ax1.plot(f_am,f_wda,"k",lw=2)
ax1.plot(bf_am,bf_wda,"0.7",lw=1.4)
ax1.plot(p1_am,p1_wda,"#50C070",lw=1.2)
ax1.plot(p2_am,p2_wda,"#900000",lw=0.8)
ax1.plot(p8_am,p8_wda,"C4",lw=1.8)
ax1.plot(f8_am,f8_wda,"#D0D020",lw=1.3)
ax1.plot(i_am,i_wda,"C0",lw=2)
ax1.plot(i_am/2^10,i_wda,"C1",lw=2)

ax1.plot(a16_am,a16_wda,"C5",lw=2)
ax1.plot(lfxp16_am,lfxp16_wda,"C6",lw=2)

ax1.fill_between(f_am,-0.1,f_wda,edgecolor="k",facecolor="none",linestyle="--")
ax1.fill_between(i_am,-0.1,i_wda,edgecolor="C0",facecolor="none",linestyle="--")
ax1.fill_between(i_am/2^10,-0.1,i_wda,edgecolor="C1",facecolor="none",linestyle="--")
ax1.fill_between(p1_am,-0.1,p1_wda,where=((p1_am .>= posit16[1]).*(p1_am .<= posit16[end])),edgecolor="C2",facecolor="none",linestyle="--")
ax1.fill_between(p8_am,-0.1,p8_wda,where=((p8_am .>= posit8[1]).*(p8_am .<= posit8[end])),edgecolor="C4",facecolor="none",linestyle="--")
ax1.fill_between(f8_am,-0.1,f8_wda,edgecolor="#D0D020",facecolor="none",linestyle="--",zorder=10)

x0,x1 = 1e-16,1e16

ax1.set_xlim(x0,x1)
ax1.set_xscale("log",basex=10)
ax1.set_ylim(0,6)

ax1.set_xlabel("value")
ax1.set_ylabel("decimal places")

ax1.text(1e-12,0.5,"Posit(16,1)",color="#50C070")
ax1.text(2e-15,1.65,"Posit(16,2)",color="#900000")
ax1.text(6e-3,1,"Posit(8,0)",color="C4",rotation=64.5,va="bottom")
ax1.text(3e-2,.6,"Float8",color="#D0D020",rotation=64.5,va="bottom")
ax1.text(5e-7,4.1,"Float16",color="k")
ax1.text(1e-15,3.2,"BFloat16",color="0.3")
ax1.text(6e4,5,"Int16",color="C0")
ax1.text(30,5.3,"Q6.10",color="C1",rotation=0)

ax1.text(1e12,2.2,"Approx14",color="C5",rotation=0)
ax1.text(3e10,3.4,"LogFixPoint16",color="C6",rotation=0)

ax1.set_title("Decimal precision",loc="left")

tight_layout()
savefig("/Users/milan/git/LogFixPoint16s.jl/figs/decimal_precision3.png",dpi=100)
close(fig)

using PyPlot, StatsBase, Statistics

include("representable_numbers.jl")

float8 = representable_floats(8,3)
float16 = representable_floats(16,5)
bfloat16 = representable_floats(16,8)

f8_am, f8_wda = wcdp_float(float8)
f_am, f_wda = wcdp_float(float16)
bf_am, bf_wda = wcdp_float(bfloat16)

i_am = vcat(0.5000001,1.49999999:1:(2^15-1))
i_wda = decprec(i_am,round.(i_am))
i_am[1] = 1

## log fixed point
nint = 8
nfrac = 7

# all integer bit being 1 means NaN
lfxp_bf16 = 2 .^ collect((-2.0^(nint-1)):(2.0^-nfrac):(2.0^(nint-1)-1-2.0^-nfrac))

nint = 5
nfrac = 10
lfxp_f16 = 2 .^ collect((-2.0^(nint-1)):(2.0^-nfrac):(2.0^(nint-1)-2.0^-nfrac))

lfxp_bf16_am, lfxp_bf16_wda = wcdp_approx(lfxp_bf16)
lfxp_f16_am, lfxp_f16_wda = wcdp_approx(lfxp_f16)

# include floatmin/2 which gets round to floatmin
# include the no overflow rounding mode
lfxp_f16_am = vcat(lfxp_f16[1]/2,lfxp_f16_am,lfxp_f16[end]*10)
lfxp_f16_wda = vcat(decprec(lfxp_f16[1]/2,lfxp_f16[1]),lfxp_f16_wda,0)

## PLOTTING
ioff()
fig,ax1 = subplots(1,1,figsize=(7,3))

# dashed lines for reprsentable numbers
ax1.fill_between(i_am,-0.1,i_wda,edgecolor="C0",facecolor="none",linestyle="--")
ax1.plot(ones(2)*float16[1],[0,.5],"k",ls="--")
ax1.plot(ones(2)*float16[end],[0,4],"k",ls="--",lw=2)
ax1.plot(ones(2)*float8[1],[0,.5],"#D0D020",ls="--")
ax1.plot(ones(2)*float8[end],[0,2],"#D0D020",ls="--")
ax1.plot(ones(2)*lfxp_f16[1],[0,3.8],"C6",ls="--")
ax1.plot(ones(2)*lfxp_f16[end],[0,4],"C6",ls="--")

# floats and integers
ax1.plot(f_am,f_wda,"k",lw=2)
ax1.plot(bf_am,bf_wda,"0.7",lw=1.4)
ax1.plot(f8_am,f8_wda,"#D0D020",lw=1.3)
ax1.plot(i_am,i_wda,"C0",lw=2)

# log fix points
ax1.plot(lfxp_bf16_am,lfxp_bf16_wda,"C5",lw=2)
ax1.plot(lfxp_f16_am,lfxp_f16_wda,"C6",lw=2)

x0,x1 = 1e-16,1e16

ax1.set_xlim(x0,x1)
ax1.set_xscale("log",basex=10)
ax1.set_ylim(0,6)

ax1.set_xlabel("value")
ax1.set_ylabel("decimal places")

ax1.text(6e-3,1,"Float8",color="#D0D020",rotation=64.5,va="bottom")
ax1.text(5e-7,4.1,"Float16",color="k")
ax1.text(1e-15,3.2,"BFloat16",color="0.3")
ax1.text(6e4,5,"Int16",color="C0")

ax1.text(2e5,3.7,"LogFixPoint16",color="C6",rotation=0)
ax1.text(1e10,3.2,"BLogFixPoint16",color="C5",rotation=0)

ax1.set_title("Decimal precision",loc="left")

tight_layout()
savefig("/Users/milan/git/LogFixPoint16s.jl/figs/decimal_precision.png",dpi=100)
close(fig)

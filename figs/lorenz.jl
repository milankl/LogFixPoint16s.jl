using LogFixPoint16s, Lorenz63, PyPlot

LogFixPoint16s.set_nfrac(10)

Δt = 0.005
N = 200000

XYZ0 = L63(Float64;N,Δt)
XYZ1 = L63(Float16;N,Δt)
XYZ2 = L63(LogFixPoint16;N,Δt)

## PLOTTING
pygui(true)
fig,(ax1,ax2,ax3) = subplots(1,3,sharex=true,sharey=true,figsize=(10,3.5))

ax1.plot(XYZ0[1,:],XYZ0[3,:],"k",lw=0.1)
ax2.plot(XYZ1[1,:],XYZ1[3,:],"k",lw=0.1)
ax3.plot(XYZ2[1,:],XYZ2[3,:],"k",lw=0.1)

ax1.set_xticks([])
ax1.set_yticks([])
ax1.set_xlabel("x")
ax2.set_xlabel("x")
ax3.set_xlabel("x")
ax1.set_ylabel("y")

ax1.set_title("Float64",loc="left")
ax2.set_title("Float16",loc="left")
ax3.set_title("LogFixPoint16 (10 fraction bits)",loc="left")
ax1.set_title("a",loc="right",fontweight="bold")
ax2.set_title("b",loc="right",fontweight="bold")
ax3.set_title("c",loc="right",fontweight="bold")

tight_layout()
savefig("lorenz_attractor.png",dpi=200)

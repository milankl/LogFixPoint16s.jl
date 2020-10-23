using Statistics
using PyPlot
pygui(true)

function biased(x::Array{Float64,1})
    N = length(x)
    Nsub = Int(round(0.05*N))    # index to disregard the first 5% of the array
    # calculate a cumulative mean, disregard the first 5%
    cummean = (cumsum(x)./Array(1:N))[Nsub:end]
    # for a bias free x, the mean shouldn't be much larger than the std
    bias = abs(mean(cummean)) / std(cummean)
end

function biassample(::Type{T},          # number format to test for bias
                    op=+,               # arithmetic operation
                    rng=rand,          # random number generator, e.g. rand,randn
                    N=1000000) where T

    x = fill(0.0,N)   # preallocate

    for i in 1:N
        a,b = T.(8*rng(2))
        truth = op(Float64(a),Float64(b))
        approx = Float64(op(a,b))
        x[i] = approx-truth
    end

    return x
end

function cummean(x::AbstractArray)
    N = length(x)
    return cumsum(x)./Array(1:N)
end

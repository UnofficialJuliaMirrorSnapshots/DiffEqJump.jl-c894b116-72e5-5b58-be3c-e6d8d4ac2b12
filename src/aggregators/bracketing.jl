# bracketing intervals for RSSA-based aggregators
# see: "On the rejection-based algorithm for simulation and analysis of
#       large-scale reaction networks", Thanh et al, J. Chem. Phys., 2015
# note, expects the type of the bracketing variables [ulow,uhigh] to be the
# same as the fluct_rate and ushift.
struct BracketData{T1,T2}
    fluctrate::T1         # interval should be [1-fluctrate,1+fluctrate] * u
    threshold::T2         # for u below threshold interval is:
    Δu::T2                #   [max(u-Δu,0),u+Δu]
end

# # suggested defaults
# BracketData{T1}() = BracketData(.1, 25, 4)
BracketData{T1,T2}() where {T1,T2} = BracketData(T1(.1),T2(25),T2(4))

# support either vectors of data for each field, or scalars
@inline getfr(bd::BracketData{AbstractVector{T1},T2}, i) where {T1,T2} = bd.fluctrate[i]
@inline getfr(bd::BracketData{T1,T2}, i) where {T1 <: Number,T2} = bd.fluctrate

@inline gettv(bd::BracketData{T1,AbstractVector{T2}}, i) where {T1,T2} = bd.threshold[i]
@inline gettv(bd::BracketData{T1,T2}, i) where {T1,T2 <: Number} = bd.threshold

@inline getΔu(bd::BracketData{T1,AbstractVector{T2}}, i) where {T1,T2} = bd.Δu[i]
@inline getΔu(bd::BracketData{T1,T2}, i) where {T1,T2 <: Number} = bd.Δu


@inline function get_spec_brackets(bd, i, u)
    if u == zero(u)
        return zero(u), zero(u)
    elseif u < gettv(bd, i)
        Δu = getΔu(bd,i)
        return max(zero(Δu), u - Δu), u + Δu
    else
        δ = getfr(bd, i)
        return trunc(typeof(u), (one(δ) - δ) * u), trunc(typeof(u), (one(δ) + δ) * u)
    end
end

@inline get_majump_brackets(ulow, uhigh, k, majumps) = evalrxrate(ulow, k, majumps), evalrxrate(uhigh, k, majumps)

# for constant rate jumps we must check the ordering of the bracket values
@inline function get_cjump_brackets(ulow, uhigh, rate, params, t)
    rlow  = rate(ulow, params, t)
    rhigh = rate(uhigh, params, t)
    if rlow <= rhigh
        return rlow,rhigh
    else
        return rhigh,rlow
    end
end

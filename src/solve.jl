function DiffEqBase.__solve(
  jump_prob::DiffEqBase.AbstractJumpProblem{P},
  alg::DiffEqBase.DEAlgorithm,timeseries=[],ts=[],ks=[],recompile::Type{Val{recompile_flag}}=Val{true};
  kwargs...) where {P,recompile_flag}

  integrator = init(jump_prob,alg,timeseries,ts,ks,recompile;kwargs...)
  solve!(integrator)
  integrator.sol
end

function DiffEqBase.__init(
  jump_prob::DiffEqBase.AbstractJumpProblem{P},
  alg::DiffEqBase.DEAlgorithm,timeseries=[],ts=[],ks=[],recompile::Type{Val{recompile_flag}}=Val{true};
  callback=nothing, seed = rand(UInt64),
  kwargs...) where {P,recompile_flag}

  if !isempty(jump_prob.jump_callback.discrete_callbacks)
    Random.seed!(jump_prob.jump_callback.discrete_callbacks[1].condition.rng,seed)
  end

  if !isempty(jump_prob.variable_jumps)
    @assert jump_prob.prob.u0 isa ExtendedJumpArray
    randexp!(jump_prob.prob.u0.jump_u)
    jump_prob.prob.u0.jump_u .*= -1
  end

  # DDEProblems do not have a recompile_flag argument
  if jump_prob.prob isa DiffEqBase.AbstractDDEProblem
    integrator = init(jump_prob.prob,alg,timeseries,ts,ks;
                      callback=CallbackSet(callback,jump_prob.jump_callback),
                      kwargs...)
  else
    integrator = init(jump_prob.prob,alg,timeseries,ts,ks,recompile;
                      callback=CallbackSet(callback,jump_prob.jump_callback),
                      kwargs...)
  end
end

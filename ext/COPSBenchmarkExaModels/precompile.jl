# Precompile workload (see src/precompile.jl). The CPU workload runs here; the GPU workloads
# run in the backend extensions.

import PrecompileTools
import ExaModels: NLPModels

# A model's type does not depend on its size, so a small instance compiles what a large one
# needs. The tetra and triangle meshes share one expression each, and so do the PDE models.
const _DEVICE_MODELS = (
    (COPSBenchmark.camshape_model, (100,)),
    (COPSBenchmark.chain_model, (100,)),
    (COPSBenchmark.glider_model, (10,)),
    (COPSBenchmark.robot_model, (20,)),
    (COPSBenchmark.rocket_model, (20,)),
    (COPSBenchmark.triangle_pacman_model, ()),
    (COPSBenchmark.tetra_gear_model, ()),
    (COPSBenchmark.dirichlet_model, (5,)),
)

# Their iteration data stays in a host `Array`, which a GPU kernel cannot take as an
# argument, so they run on the CPU only.
const _HOST_MODELS = (
    (COPSBenchmark.bearing_model, (10, 10)),
    (COPSBenchmark.catmix_model, (10,)),
    (COPSBenchmark.channel_model, (20,)),
    (COPSBenchmark.elec_model, (25,)),
    (COPSBenchmark.gasoil_model, (10,)),
    (COPSBenchmark.marine_model, (10,)),
    (COPSBenchmark.methanol_model, (10,)),
    (COPSBenchmark.minsurf_model, (10, 10)),
    (COPSBenchmark.pinene_model, (10,)),
    (COPSBenchmark.polygon_model, (50,)),
    (COPSBenchmark.steering_model, (20,)),
    (COPSBenchmark.torsion_model, (10, 10)),
)

# Each call goes through `invokelatest`, as a call from the top level or from behind a
# solver's model barrier does, so that it is compiled as a standalone method rather than
# only inlined into the workload.
_call(f, args...; kw...) = Base.invokelatest(f, args...; kw...)

function _evaluate_callbacks(m)
    x = copy(NLPModels.get_x0(m))
    T = eltype(x)
    ncon, nnzj, nnzh = NLPModels.get_ncon(m), NLPModels.get_nnzj(m), NLPModels.get_nnzh(m)
    y = fill!(similar(x, ncon), zero(T))
    _call(NLPModels.jac_structure!, m, similar(x, Int, nnzj), similar(x, Int, nnzj))
    _call(NLPModels.hess_structure!, m, similar(x, Int, nnzh), similar(x, Int, nnzh))
    _call(NLPModels.obj, m, x)
    _call(NLPModels.grad!, m, x, similar(x))
    _call(NLPModels.cons!, m, x, similar(x, ncon))
    _call(NLPModels.jac_coord!, m, x, similar(x, nnzj))
    _call(NLPModels.hess_coord!, m, x, y, similar(x, nnzh); obj_weight = one(T))
    return nothing
end

function COPSBenchmark._precompile_workload(backend; T = nothing)
    kw = backend === nothing ? (;) : (; backend)
    kw = T === nothing ? kw : (; kw..., T)
    models = backend === nothing ? (_DEVICE_MODELS..., _HOST_MODELS...) : _DEVICE_MODELS
    for (model, args) in models
        try
            _evaluate_callbacks(_call(model, ExaModelsBackend(), args...; kw...))
        catch err
            @warn "skipping $model in the precompile workload" exception = err
        end
    end
    return nothing
end

PrecompileTools.@compile_workload begin
    if COPSBenchmark.PRECOMPILE
        COPSBenchmark._precompile_workload(nothing)
    end
end

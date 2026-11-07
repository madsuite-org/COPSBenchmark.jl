# Precompile workload (see src/precompile.jl). The CPU workload runs here; the GPU workloads
# run in the backend extensions.

import PrecompileTools

# A model's type does not depend on its size, so a small instance compiles what a large one
# needs. The tetra and triangle meshes share one expression each, and so do the PDE models.
const _MODELS = (
    (COPSBenchmark.camshape_model, (100,)),
    (COPSBenchmark.chain_model, (100,)),
    (COPSBenchmark.glider_model, (10,)),
    (COPSBenchmark.robot_model, (20,)),
    (COPSBenchmark.rocket_model, (20,)),
    (COPSBenchmark.triangle_pacman_model, ()),
    (COPSBenchmark.tetra_gear_model, ()),
    (COPSBenchmark.dirichlet_model, (5,)),
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
    (COPSBenchmark.henon_model, (5,)),
    (COPSBenchmark.lane_emden_model, (5,)),
)

# Models that share the code of a model above and have only their entry point of their own.
const _ENTRY_POINTS = (
    COPSBenchmark.triangle_deer_model, COPSBenchmark.triangle_turtle_model,
    COPSBenchmark.tetra_duct12_model, COPSBenchmark.tetra_duct15_model,
    COPSBenchmark.tetra_duct20_model, COPSBenchmark.tetra_foam5_model,
    COPSBenchmark.tetra_hook_model,
)


# Each call goes through `invokelatest`, as a call from the top level or from behind a
# solver's model barrier does, so that it is compiled as a standalone method rather than
# only inlined into the workload.
_call(f, args...; kw...) = Base.invokelatest(f, args...; kw...)

function COPSBenchmark._precompile_workload(backend; T = nothing)
    kw = backend === nothing ? (;) : (; backend)
    kw = T === nothing ? kw : (; kw..., T)
    # `prod = true` changes the type of a model: a solver on a GPU needs its products
    variants = backend === nothing ? (kw,) : (kw, (; kw..., prod = true))
    for options in variants
        for (model, args) in _MODELS
            try
                ExaModels.precompile_callbacks(_call(model, ExaModelsBackend(), args...; options...))
            catch err
                @warn "skipping $model in the precompile workload" exception = err
            end
        end
        for f in _ENTRY_POINTS
            isempty(options) ? precompile(f, (ExaModelsBackend,)) :
                precompile(Core.kwcall, (typeof(options), typeof(f), ExaModelsBackend))
        end
    end
    return nothing
end

PrecompileTools.@compile_workload begin
    if COPSBenchmark.PRECOMPILE
        COPSBenchmark._precompile_workload(nothing)
    end
end

# Precompiles the COPS models on Intel GPUs (see src/precompile.jl). Needs a functional device at
# precompile time. `ExaModels` and `KernelAbstractions` are triggers so that this package's
# ExaModels extension and ExaModels' backend extensions load while this one precompiles.
# `oneAPI.functional()` is false during precompilation, so the workload does not run.
module COPSBenchmarkoneAPI

import COPSBenchmark
import oneAPI
import ExaModels
import KernelAbstractions
import PrecompileTools

PrecompileTools.@compile_workload begin
    if COPSBenchmark.PRECOMPILE && oneAPI.functional()
        COPSBenchmark._precompile_workload(oneAPI.oneAPIBackend())
    end
end

end # module

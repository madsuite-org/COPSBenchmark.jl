# Precompiles the COPS models on AMD GPUs (see src/precompile.jl). Needs a functional device at
# precompile time. `ExaModels` and `KernelAbstractions` are triggers so that this package's
# ExaModels extension and ExaModels' backend extensions load while this one precompiles.
# Julia 1.11 is excluded: there the workload leaves an image that fails to load or gains nothing.
module COPSBenchmarkAMDGPU

import COPSBenchmark
import AMDGPU
import ExaModels
import KernelAbstractions
import PrecompileTools

PrecompileTools.@compile_workload begin
    if VERSION >= v"1.12" && COPSBenchmark.PRECOMPILE && AMDGPU.functional()
        COPSBenchmark._precompile_workload(AMDGPU.ROCBackend())
    end
end

end # module

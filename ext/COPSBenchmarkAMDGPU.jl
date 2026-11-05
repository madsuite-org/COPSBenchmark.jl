# Precompiles the COPS models on AMD GPUs (see src/precompile.jl). Needs a functional device at
# precompile time. `ExaModels` and `KernelAbstractions` are triggers so that this package's
# ExaModels extension and ExaModels' backend extensions load while this one precompiles.
module COPSBenchmarkAMDGPU

import COPSBenchmark
import AMDGPU
import ExaModels
import KernelAbstractions
import PrecompileTools

PrecompileTools.@compile_workload begin
    if COPSBenchmark.PRECOMPILE && AMDGPU.functional()
        COPSBenchmark._precompile_workload(AMDGPU.ROCBackend())
    end
end

end # module

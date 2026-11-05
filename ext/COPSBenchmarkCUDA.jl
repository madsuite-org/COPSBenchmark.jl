# Precompiles the COPS models on NVIDIA GPUs (see src/precompile.jl). Needs a functional device at
# precompile time. `ExaModels` and `KernelAbstractions` are triggers so that this package's
# ExaModels extension and ExaModels' backend extensions load while this one precompiles.
module COPSBenchmarkCUDA

import COPSBenchmark
import CUDA
import ExaModels
import KernelAbstractions
import PrecompileTools

PrecompileTools.@compile_workload begin
    if COPSBenchmark.PRECOMPILE && CUDA.functional()
        COPSBenchmark._precompile_workload(CUDA.CUDABackend())
    end
end

end # module

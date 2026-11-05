# Precompiles the COPS models on Apple GPUs, in Float32 (see src/precompile.jl). Needs a
# functional device at precompile time. `ExaModels` and `KernelAbstractions` are triggers so
# that this package's ExaModels extension and ExaModels' backend extensions load while this
# one precompiles.
module COPSBenchmarkMetal

import COPSBenchmark
import Metal
import ExaModels
import KernelAbstractions
import PrecompileTools

PrecompileTools.@compile_workload begin
    if COPSBenchmark.PRECOMPILE && Metal.functional()
        COPSBenchmark._precompile_workload(Metal.MetalBackend(); T = Float32)
    end
end

end # module

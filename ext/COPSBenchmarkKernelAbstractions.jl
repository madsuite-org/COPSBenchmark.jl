# Loading KernelAbstractions adds methods that invalidate the CPU code in the ExaModels
# extension's image. This image is loaded after those methods, so what it stores stays valid.
module COPSBenchmarkKernelAbstractions

import COPSBenchmark
import ExaModels
import KernelAbstractions
import PrecompileTools

PrecompileTools.@compile_workload begin
    if COPSBenchmark.PRECOMPILE
        COPSBenchmark._precompile_workload(nothing)
    end
end

end

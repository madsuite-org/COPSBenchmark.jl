# An ExaModel's type encodes its expressions, so every model compiles its own callbacks on
# first use. The `precompile` preference stores that code in the package images. It is read
# at compile time: changing it invalidates the images, and `false`, the default, compiles
# nothing.

const PRECOMPILE = @load_preference("precompile", false)

"""
    set_precompile(flag::Bool)

Turn on or off compiling the ExaModels COPS models into the package images, so that they
build and evaluate in a new Julia session without compiling. The default is `false`.

With `true`, the image of the ExaModels extension holds the models for `Float64` on the
CPU. The extension for a GPU package (CUDA, AMDGPU, Metal or oneAPI) adds the models that
run on a GPU when the package is loaded and a device works at precompile time. oneAPI
reports no device during precompilation, so its workload does not run.

The setting is stored in the active project's `LocalPreferences.toml` and takes effect in
the next Julia session, whose `using COPSBenchmark` rebuilds the images.
"""
function set_precompile(flag::Bool)
    @set_preferences!("precompile" => flag)
    @info "Restart Julia for this to take effect."
    return flag
end

"""
    _precompile_workload(backend; T = nothing)

Build the ExaModels COPS models on `backend` (`nothing` for the CPU) and call the callbacks
a solver uses. A model that throws is logged and skipped. `T` is passed to the models only
when given. Defined by the ExaModels extension.
"""
function _precompile_workload end

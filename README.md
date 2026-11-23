# COPSBenchmark.jl

[![Run tests](https://github.com/MadNLP/COPSBenchmark.jl/actions/workflows/action.yml/badge.svg)](https://github.com/MadNLP/COPSBenchmark.jl/actions/workflows/action.yml)
[![Documentation](https://github.com/MadNLP/COPSBenchmark.jl/actions/workflows/docs.yml/badge.svg)](https://madnlp.github.io/COPSBenchmark.jl/dev/)
[![codecov](https://codecov.io/gh/MadNLP/COPSBenchmark.jl/branch/main/graph/badge.svg)](https://codecov.io/gh/MadNLP/COPSBenchmark.jl)

Implementation of the [COPS benchmark](https://www.mcs.anl.gov/~more/cops/) for nonlinear optimization,
with backends for [JuMP](https://github.com/jump-dev/JuMP.jl) and [ExaModels](https://github.com/exanauts/ExaModels.jl).

## Quick start

```julia
using COPSBenchmark, JuMP, Ipopt

model = COPSBenchmark.rocket_model(COPSBenchmark.JuMPBackend(), 400)
set_optimizer(model, Ipopt.Optimizer)
set_silent(model)
optimize!(model)
```

```julia
using COPSBenchmark, ExaModels, NLPModelsIpopt

model = COPSBenchmark.rocket_model(COPSBenchmark.ExaModelsBackend(), 400)
result = ipopt(model; print_level=0)
```

## Precompiling the ExaModels models

An ExaModels model compiles its own code the first time it is built and evaluated, which can take from seconds to minutes per model. To store that code in the package images instead:

```julia
using COPSBenchmark
COPSBenchmark.set_precompile(true)
```

The setting goes into the active project's `LocalPreferences.toml`. The next Julia session rebuilds the images, which takes minutes and makes them larger, and the models then start without that compile time. The default is `false`, which compiles nothing; `COPSBenchmark.set_precompile(false)` turns it off again.

The CPU workload runs when ExaModels is loaded. A GPU workload runs when CUDA, AMDGPU, Metal or oneAPI is loaded together with ExaModels and KernelAbstractions, and only if a device works at precompile time. Otherwise it is skipped. It covers the models that run on a GPU: camshape, chain, glider, robot, rocket, and the triangle, tetra and PDE models.

oneAPI reports no device during precompilation, so its workload never runs and first calls on an Intel GPU still compile.

## Compiled library

Every model is also published as one compiled shared library implementing the
[cnlp ABI](https://cnlplib.madsuite.org), with CPU and CUDA evaluation and no Julia needed
to use it. Each push to `main` updates the `nightly` release, and each registered version
gets its own release:

```sh
cnlp install cops            # the latest version (https://cnlplib.madsuite.org)
cnlp install cops@nightly    # the latest build of main
cnlp solve @cops:rocket 400
```

From Julia, through [CNLPLib.jl](https://github.com/madsuite-org/CNLPLib.jl):

```julia
using CNLPLib, MadNLP
madnlp(CNLPModel("@cops", :rocket, 400))
```

`bearing`, `minsurf` and `torsion` take two grid sizes; every other model takes one size.
To build the library yourself, with ExaModelsCompiler loaded:
`compile_all(COPSBenchmark; path = "cops", bundle = true)` (add `device = :cuda` for the
CUDA tier).

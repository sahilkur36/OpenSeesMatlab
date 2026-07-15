# NVIDIA cuDSS GPU Solver

!!! note

    - [cuDSS](https://developer.nvidia.com/cudss) is an optional OpenSeesMatlab extension for solving sparse linear systems on an NVIDIA GPU.
    - CPU solvers continue to work without an NVIDIA GPU, CUDA, or cuDSS.
    - The current binary supports the cuDSS 0.8 API. CUDA 12 is validated; CUDA 13 runtime discovery is available but has not yet been validated on a CUDA 13 test machine.

The cuDSS backend can accelerate repeated sparse factorizations in large models.
For small systems, CPU solvers may remain faster because GPU initialization,
data transfer, and kernel-launch overhead are comparable with the solve itself.

## User requirements

To use cuDSS, the user computer needs:

!!! info

    - a CUDA-capable NVIDIA GPU;
    - an NVIDIA driver compatible with the selected CUDA version;
    - [CUDA](https://developer.nvidia.com/cuda-toolkit-archive) 12 or CUDA 13 runtime and cuBLAS libraries;
    - NVIDIA [cuDSS](https://developer.nvidia.com/cudss) **0.8** built for the same CUDA major version; and

Users do not need Visual Studio, CMake, `nvcc`, or MATLAB Parallel Computing
Toolbox. A newer supported NVIDIA GPU is allowed; the MEX is not tied to the GPU
used when it was compiled.

## Configure the cuDSS runtime

If cuDSS is installed in its standard directory, automatic discovery is usually
enough. Otherwise, set the installation directory before creating the solver:

```matlab
% This is usually not necessary because CUDA environment variables are set automatically during installation.
% If you have CUDA V12.6 installed:
% setenv("CUDA_PATH_V12_6", ...
%     "C:\Program Files\NVIDIA GPU Computing Toolkit\CUDA\v12.6");

% Set the following CUDSS environment variables.
setenv("OPENSEES_CUDSS_ROOT", ...
    "C:\Program Files\NVIDIA cuDSS\v0.8");
```

The path may also be supplied directly to `ops.system` with `-runtimePath`.
This is useful when several CUDA or cuDSS versions are installed.

!!! warning

    The cuDSS package must match the selected CUDA major version. Do not mix a CUDA 12 cuDSS DLL with CUDA 13 runtime DLLs. cuDSS 0.9 and 1.x are not accepted by the current MEX until those APIs have been explicitly supported and validated.

## Basic usage

Create the OpenSeesMatlab interface as usual:

```matlab
opsMat = OpenSeesMatlab();
ops = opsMat.opensees;

ops.wipe();
% Define the model, materials, nodes, elements, constraints, and loads.
```

Select the general cuDSS solver before creating the analysis:

```matlab
ops.constraints("Transformation");
ops.numberer("RCM");

ops.system("CuDSS", ...
    "-cudaMajor", "auto", ...
    "-device", "auto", ...
    "-refinement", 0, ...
    "-verbose");

ops.test("NormDispIncr", 1.0e-8, 20);
ops.algorithm("Newton");
ops.integrator("Newmark", 0.5, 0.25);
ops.analysis("Transient");
```

With `-cudaMajor "auto"`, the loader tries CUDA 13 and then CUDA 12. With
`-device "auto"`, it selects an available GPU. The `-verbose` option prints the
loaded runtime and selected device, for example:

```text
CuDSS: loaded CUDA 12 and cuDSS 0.8 at runtime
CuDSS: selected GPU 0 (compute capability 8.6)
```

To select a specific installation and GPU:

```matlab
ops.system("CuDSS", ...
    "-cudaMajor", 12, ...
    "-runtimePath", "C:\Program Files\NVIDIA cuDSS\v0.8", ...
    "-device", 0, ...
    "-refinement", 0);
```

## Choosing the matrix type

The following variants are available:

| Command | Matrix assumption | Recommended use |
| --- | --- | --- |
| `CuDSS` or `CuDSSGeneral` | General sparse matrix | Safest choice for nonlinear analysis |
| `CuDSSSymmetric` | Symmetric indefinite | Use only when symmetry is guaranteed |
| `CuDSSSPD` | Symmetric positive definite | Use only when positive definiteness is guaranteed |

For strongly nonlinear earthquake analysis, start with `CuDSS`. A tangent
matrix may become indefinite even if the initial elastic stiffness is positive
definite.

## CPU fallback

OpenSeesMatlab does not automatically replace cuDSS with a CPU solver when GPU
configuration fails. Select the desired CPU solver explicitly:

```matlab
ops.system("UmfPack");
```

CPU solvers do not load CUDA or cuDSS and are unaffected when the GPU runtime is
not installed.

## Troubleshooting

If cuDSS cannot be selected:

1. Run `nvidia-smi` and confirm that Windows can see the GPU.
2. Confirm that CUDA, cuBLAS, and cuDSS use the same CUDA major version.
3. Pass `-runtimePath` and `-cudaMajor` explicitly.
4. Use `-verbose` to display the selected runtime and GPU.
5. Confirm that MATLAB is loading the GPU-enabled MEX with:

```matlab
which OpenSeesMATLAB -all
```

If an analysis fails only with an SPD or symmetric variant, retry with the
general `CuDSS` solver and check the model constraints, conditioning, and
nonlinear convergence settings.

## Examples

[Extensions Examples](../../examples/extension/index.md)

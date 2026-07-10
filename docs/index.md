# OpenSeesMatlab

**OpenSeesMatlab** brings the OpenSees finite-element engine into MATLAB. You build and analyze a model with familiar OpenSees-style commands, then use MATLAB variables and the toolbox modules to prepare inputs, manage analyses, retrieve results, and visualize them.

![OpenSeesMatlab model visualization](static/images/demo-readme.png)

## Start here

Choose the path that matches what you want to do:

| Goal | Recommended page |
|---|---|
| Understand the toolbox and its modules | [OpenSeesMatlab at a glance](getting_started/overview.md) |
| Install and verify the toolbox | [Installation](getting_started/installation.md) |
| Build and analyze a first model | [Your first analysis](getting_started/quickstart.md) |
| Translate OpenSees or OpenSeesPy commands | [OpenSees command interface](getting_started/opensees.md) |
| Record, retrieve, and visualize results | [Pre/post-processing and visualization](getting_started/post.md) |
| See complete engineering examples | [Examples](examples/index.md) |

!!! tip "New to both OpenSees and OpenSeesMatlab?"

    Read the [toolbox overview](getting_started/overview.md), complete the
    [first analysis](getting_started/quickstart.md), and then open an example
    closest to your own model type.

## The basic workflow

Most projects follow the same sequence:

1. Create one `OpenSeesMatlab` object.
2. Use `.opensees` to define and analyze the OpenSees domain.
3. Read values directly during analysis, use standard OpenSees recorders, or create an OpenSeesMatlab ODB for structured results.
4. Use MATLAB or `.vis` to inspect and visualize the results.
5. Call `wipe` before building an unrelated model in the same MATLAB session.

```matlab
opsMat = OpenSeesMatlab();
ops = opsMat.opensees;

ops.wipe();
ops.model('basic', '-ndm', 2, '-ndf', 2);

ops.node(1, 0.0, 0.0);
ops.node(2, 1.0, 0.0);
ops.fix(1, 1, 1);

% Continue with materials, elements, loads, and analysis commands.

modelInfo = opsMat.post.getModelData(); %#ok<NASGU>
opsMat.vis.plotModel();
% Or open the interactive Polyscope viewer:
% opsMat.vis.polyscope.plotModel();
```

OpenSeesMatlab intentionally keeps the OpenSees command vocabulary. In most cases, an OpenSees or OpenSeesPy command can be translated by changing the call form rather than learning a new modelling language:

```text
OpenSeesPy:  ops.node(2, 1.0, 0.0)
MATLAB:      ops.node(2, 1.0, 0.0);
```

## What the main object provides

| Property | Use it for |
|---|---|
| `opsMat.opensees` | OpenSees model, loading, analysis, recorder, and query commands |
| `opsMat.pre` | Units, sections, meshes, matrices, and other preprocessing helpers |
| `opsMat.anlys` | Higher-level analysis workflows such as robust step handling |
| `opsMat.post` | Model data, eigen data, ODB recording, response retrieval, and export |
| `opsMat.vis` | MATLAB model, mode-shape, deformation, and response plots |
| `opsMat.vis.polyscope` | Interactive Polyscope GUI viewers |
| `opsMat.utils` | General toolbox helpers and example utilities |

The modules share the same OpenSees domain through `opsMat`; do not create a separate top-level object for every module.

## Choosing a result workflow

| Need | Use |
|---|---|
| A few values during or after an analysis | OpenSees query commands such as `nodeDisp`, `nodeReaction`, `eleForce`, and `eleResponse` |
| Maximum performance or OpenSees-compatible text output | Standard OpenSees `recorder` commands |
| Structured time histories for toolbox plotting and export | `opsMat.post.createODB` and the response retrieval functions |

For large transient models, record only the data you need. Convenience layers make exploration easier, while direct OpenSees queries and recorders minimize overhead.

## Scope and requirements

- MATLAB R2023a or later
- Windows (the currently supported platform)
- Command syntax aligned as closely as possible with OpenSees and OpenSeesPy
- MATLAB-native access to returned numeric and structured data

OpenSeesMatlab is an open-source engineering tool under active development. Validate models, units, convergence settings, and results independently before using them for engineering decisions.

## Related resources

- [OpenSees documentation](https://opensees.github.io/OpenSeesDocumentation/)
- [OpenSeesPy documentation](https://openseespydoc.readthedocs.io/)
- [OpenSees command manual](https://opensees.berkeley.edu/wiki/index.php/OpenSees_User)
- [OpenSeesMatlab changelog](getting_started/changelog.md)

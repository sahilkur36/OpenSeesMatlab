# Pre, Post-Processing and Visualization

OpenSeesMatlab provides a comprehensive set of pre- and post-processing tools that work seamlessly with OpenSees. This guide covers the essential workflows for model visualization, response retrieval, and result export.

---

## Table of Contents

1. [Initialization](#initialization)
2. [Model Visualization](#model-visualization)
3. [Eigenvalue Analysis Visualization](#eigenvalue-analysis-visualization)
4. [Response Data Recording (ODB)](#response-data-recording-odb)
5. [Retrieving Responses](#retrieving-responses)
6. [Visualization of Analysis Results](#visualization-of-analysis-results)
7. [Export to ParaView (PVD)](#export-to-paraview-pvd)
8. [Preprocessing Utilities](#preprocessing-utilities)

---

## Initialization

All pre/post-processing features are accessed through the `OpenSeesMatlab` interface. Create an instance and obtain the OpenSees command handle:

```matlab
opsMAT = OpenSeesMatlab();
ops = opsMAT.opensees;
```

The `opsMAT` object provides three main namespaces:

| Namespace | Purpose |
|-----------|---------|
| `opsMAT.opensees` | Native OpenSees Tcl commands |
| `opsMAT.pre` | Preprocessing helpers (sections, loads, units, etc.) |
| `opsMAT.post` | Post-processing (ODB, responses, visualization) |
| `opsMAT.vis` | Visualization (model, eigen, deformation, etc.) |

---

## Model Visualization

At any point during model creation, visualize the current geometry:

```matlab
% Your model code

% Basic model plot
opsMAT.vis.plotModel();

% Customized plot
opts = opsMAT.vis.defaultPlotModelOptions();
opts.nodes.show = true;
opts.nodes.showLabels = true;
disp(opts.help);
opsMAT.vis.plotModel(opts=opts);
```

---

## Eigenvalue Analysis Visualization

Save eigen data during analysis, then visualize mode shapes:

```matlab
% Save eigen analysis results
tag = 1;
opsMAT.post.saveEigenData(tag, 10, solver='-genBandArpack');

% Retrieve eigen data
eigenData = opsMAT.post.getEigenData(odbTag=tag);

% Plot first mode shape
opsMAT.vis.plotEigen(1, eigenData);

% Plot with colormap
opts = opsMAT.vis.defaultPlotEigenOptions();
opts.color.useColormap = true;
opsMAT.vis.plotEigen(3, eigenData, opts=opts);
```

---

## Response Data Recording (ODB)

OpenSeesMatlab uses an **ODB (Output Database)** system to record analysis results in HDF5 format.
For optimal performance, OpenSeesMatlab implements a custom `recorder` object in C++ internally.
Note that `odbTag` is important — it is used to distinguish between different analysis cases.

Create an ODB before analysis:

```matlab
% Create ODB with optional beam interpolation
ODB = opsMAT.post.createODB("myODB");
```

Once created, all subsequent `ops.analyze()` calls automatically write data to the ODB:

```matlab
% Run analysis — data is recorded automatically
ops.analyze(npts, dt);

% Clean up
ops.wipe();

% If you only want to stop recording, use
ODB.close();
```

ODB files are stored in `.openseesmatlab.output/Responses-myODB.odb/output.h5`.

---

## Retrieving Responses

Once the analysis is complete and the ODB has saved the data properly, a series of functions can be used to retrieve the analysis results.
Typically, they return a nested struct (or a struct array if the model data changes).

!!! note

    Once these functions are called, the ODB corresponding to `odbTag` will stop recording. Therefore, it is recommended to read the results only after the analysis is complete.

### Nodal Responses

```matlab
nodeResp = opsMAT.post.getNodalResponse("myODB");
nodeTags = nodeResp.nodeTags;

% Time-history of a specific node
idx = nodeTags == 18;
plot(nodeResp.time, nodeResp.disp.ux(:, idx));

% Available fields (Layout C):
%   nodeResp.disp.ux, .uy, .uz, .rx, .ry, .rz
%   nodeResp.vel, nodeResp.accel, nodeResp.reaction
```

### Element Responses

```matlab
% Frame element responses
frameResp = opsMAT.post.getElementResponse("myODB", eleType="Frame");
sectionForces = frameResp.sectionForces;   % Layout C: .Mz, .My, .N, .Vy, .Vz, .T
sectionDefos  = frameResp.sectionDeformations;

% Shell/Plane/Solid element responses
eleResp = opsMAT.post.getElementResponse("myODB", eleType="Shell");
```


---

## Visualization of Analysis Results

### Nodal Response Visualization

```matlab
nodeResp = opsMAT.post.getNodalResponse("myODB");

% Deformation at peak step
opsMAT.vis.plotDeformation(nodeResp, stepIdx="absMax", scaleFactor=1.0);

% Specific displacement component, or any other response component
opsMAT.vis.plotNodalResponse(nodeResp, stepIdx="absMax", respType="disp", respComponent="ux");
```

### Frame Response Diagrams

```matlab
frameResp = opsMAT.post.getElementResponse("myODB", eleType="Frame");

% Section force diagram
opsMAT.vis.plotFrameResponse(frameResp, stepIdx="absMax", ...
    respType="sectionForces", respComponent="MZ");

% Section deformation diagram
opsMAT.vis.plotFrameResponse(frameResp, stepIdx="absMax", ...
    respType="sectionDeformations", respComponent="curvatureZ");
```

### Plane/Solid Response Visualization

```matlab
% For continuum elements
planeResp = opsMAT.post.getElementResponse("myODB", eleType="Plane");

opsMAT.vis.plotContinuumResponse(planeResp, ...
    respType="StressAtGP", respComponent="sxx");
```

### Step Index Options

All `stepIdx` parameters accept:

| Value | Meaning |
|-------|---------|
| Integer (0-based) | Specific step index |
| `"absMax"` / `"absmin"` | Maximum absolute value step |
| `"max"` / `"min"` | Maximum / minimum value step |

---

## Export to ParaView (PVD)

For high-performance visualization of large models or animations, export ODB data to ParaView-compatible PVD/VTU files:

```matlab
% Export all recorded datasets
opsMAT.post.writeResponsePVD("myODB");
```

Output structure:
```
paraview_output/
├── nodal/
│   ├── vtu/
│   │   ├── model_nodal_000001.vtu
│   │   └── ...
│   └── model_nodal.pvd
├── shell/
│   └── ...
└── solid/
    └── ...
```

Open the `.pvd` file in **ParaView**. For deformation visualization, apply the **"Warp By Vector"** filter to the `disp` field.

---

## Preprocessing Utilities

OpenSeesMatlab provides a variety of preprocessing utilities for model setup, including fiber section generation, gravity loads, MCK matrices, unit system conversion, and GMSH model import.
Details can be found in the [Detailed Examples](../examples/post/index.md).

---

## Complete Example

```matlab
% 1. Setup
opsMAT = OpenSeesMatlab();
ops = opsMAT.opensees;

% 2. Build your model
ops.wipe();
ops.model("BasicBuilder", "-ndm", 3, "-ndf", 6);
% ... nodes, elements, materials, loads ...

% 3. Create ODB (before analysis)
odbTag = "myODB";
ODB = opsMAT.post.createODB(odbTag);

% 4. Run analysis
ops.analyze(100, 0.01);  % run analysis and record results
ODB.close();
ops.wipe();

% 5. Retrieve and visualize
nodeResp = opsMAT.post.getNodalResponse("myODB");
opsMAT.vis.plotDeformation(nodeResp, stepIdx="absMax");

```

---

## Performance Note

!!! tip "Maximum Runtime Efficiency"

    If your top priority is **analysis speed** (matching native OpenSees performance),
    use only the **`opensees`** module (`opsMAT.opensees`) and avoid the
    post-processing wrappers.

    - Use OpenSees `recorder` commands to write `.out` or `.h5` result files.
    - Use query commands (`nodeDisp`, `nodeReaction`, `eleForce`, `eleResponse`,
      `nodeVel`, `nodeAccel`, etc.) to pull data directly into MATLAB variables
      during or after the analysis loop.

    The `post` and `vis` layers add convenience (automatic tag mapping, unified
    data structures, plotting), but they introduce overhead. For large models or
    long transient analyses, the core `opensees` command interface is the fastest
    path.

## Further Reading

- [Detailed Examples](../examples/post/index.md)
- [API Reference](../api/index.md)

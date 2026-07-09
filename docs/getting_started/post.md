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
7. [Interactive GUI Plotters](#interactive-gui-plotters)
8. [Export to ParaView (PVD)](#export-to-paraview-pvd)
9. [Preprocessing Utilities](#preprocessing-utilities)

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
| `opsMAT.post` | Post-processing (ODB creation, saved model/eigen data, response retrieval) |
| `opsMAT.vis` | Visualization (model, eigen modes, deformation, response plots, GUIs) |

---

## Model Visualization

At any point during model creation, visualize the current geometry:

```matlab
% Your model code

% Basic model plot
opsMAT.vis.plotModel();

% Customized plot
opts = opsMAT.vis.defaultPlotModelOptions;
opts.nodes.show = true;
opts.nodes.showLabels = true;
disp(opts.help);
opsMAT.vis.plotModel(opts=opts);

% Interactive Polyscope model window with in-window ImGui controls
opsMAT.vis.polyscope.plotModel();
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
opts = opsMAT.vis.defaultPlotEigenOptions;
opts.color.useColormap = true;
opsMAT.vis.plotEigen(3, eigenData, opts=opts);

% Interactive Polyscope eigen-mode window with in-window ImGui controls
opsMAT.vis.polyscope.plotEigen(1, eigenData);
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

% Interactive Polyscope nodal-response window (with ImPlot history)
opsMAT.vis.polyscope.plotNodalResponse(nodeResp);
```

### Frame Response Diagrams

```matlab
frameResp = opsMAT.post.getElementResponse("myODB", eleType="Frame");

% Section force diagram
opsMAT.vis.plotFrameResponse(frameResp, stepIdx="absMax", ...
    respType="sectionForces", respComponent="MZ");

% Section deformation diagram
opsMAT.vis.plotFrameResponse(frameResp, stepIdx="absMax", ...
    respType="sectionDeformations", respComponent="MZ");

% Interactive frame response GUI
app = opsMAT.vis.plotFrameResponseGUI(frameResp);
```

### Shell Response Visualization

```matlab
shellResp = opsMAT.post.getElementResponse("myODB", eleType="Shell");

opsMAT.vis.plotShellResponse(shellResp);

% Interactive shell response GUI
app = opsMAT.vis.plotShellResponseGUI(shellResp);
```

### Plane/Solid Response Visualization

```matlab
% For continuum elements
planeResp = opsMAT.post.getElementResponse("myODB", eleType="Plane");

opsMAT.vis.plotContinuumResponse(planeResp, ...
    respType="StressAtGP", respComponent="sxx");

% Interactive continuum response GUI
app = opsMAT.vis.plotContinuumResponseGUI(planeResp);
```

### Custom Response Fields and Components

The response plotters and response GUIs can also read user-defined fields
directly from the response data struct. The field name becomes the available
`respType`, and the component list is inferred from the data layout:

```matlab
% Nodal scalar field: component shown as "value" in the GUI
nodeResp.MyScalar = rand(nStep, nNode);

% Nodal vector field: components come from .dofs
nodeResp.MyVector.data = rand(nStep, nNode, nComp);
nodeResp.MyVector.dofs = {'c1','c2','c3'};

% Nodal Layout-C field: components come from numeric subfield names
nodeResp.MyLayoutC.c1 = rand(nStep, nNode);
nodeResp.MyLayoutC.c2 = rand(nStep, nNode);

opsMAT.vis.plotNodalResponse(nodeResp, respType="MyVector", respComponent="c2");
opsMAT.vis.polyscope.plotNodalResponse(nodeResp);
```

Frame response custom fields follow the same idea, with `responseLocation`
used to state whether values are element-level or section/sample-point values:

```matlab
% Element scalar diagram
frameResp.MyScalar = rand(nStep, nEle);
opsMAT.vis.plotFrameResponse(frameResp, ...
    respType="MyScalar", respComponent="value", responseLocation="element");

% Vector field with named components
frameResp.MyVector.data = rand(nStep, nEle, nComp);
frameResp.MyVector.dofs = {'c1','c2','c3'};

% Section-style Layout-C field
frameResp.MySection.c1 = rand(nStep, nEle, nSec);
opsMAT.vis.plotFrameResponse(frameResp, ...
    respType="MySection", respComponent="c1", responseLocation="section");
```

For shell, plane, and solid element responses, custom fields can be stored as
element, Gauss-point, or node data. Names containing `AtNode` are treated as
node fields by default; names containing `AtGP` are treated as Gauss-point
fields; other custom fields are treated as element fields unless
`responseLocation` is set explicitly.

```matlab
% Element/Gauss-point vector field
eleResp.MyStress.data = rand(nStep, nEle, nGP, nComp);
eleResp.MyStress.dofs = {'s11','s22','s12'};
opsMAT.vis.plotContinuumResponse(eleResp, ...
    respType="MyStress", respComponent="s11", responseLocation="gp");

% Node-based Layout-C field
eleResp.MyFieldAtNode.c1 = rand(nStep, nNode);
opsMAT.vis.plotContinuumResponse(eleResp, ...
    respType="MyFieldAtNode", respComponent="c1");
```

For all response GUIs, custom fields and components are populated from the
first response struct entry, for example `nodeResp(1)`, `frameResp(1)`, or
`eleResp(1)`. If a multi-stage response uses struct arrays, put the custom
field names and component metadata in the first entry as well.

### Step Index Options

All `stepIdx` parameters accept:

| Value | Meaning |
|-------|---------|
| Integer (0-based) | Specific step index |
| `"absMax"` / `"absMin"` | Maximum / minimum absolute value step |
| `"Max"` / `"Min"` | Maximum / minimum signed value step |

Selectors are case-insensitive in the plotters, but the examples use the canonical mixed-case spelling.

---

## Interactive GUI Plotters

The `opsMAT.vis` interface includes interactive plotters. Model, eigen, and nodal-response visualisation use Polyscope's in-window ImGui/ImPlot controls. Frame, shell, and continuum responses still provide MATLAB GUI wrappers that return an `app` struct containing the figure, axes, controls, and helper callbacks such as `app.getOptions()`, `app.refresh()`, and `app.reset()`.

### Available GUI Entry Points

| GUI | Typical input | Purpose |
|-----|---------------|---------|
| `opsMAT.vis.polyscope.plotModel()` | current OpenSees model | Interactive Polyscope window with model display options |
| `opsMAT.vis.polyscope.plotEigen(1, eigenData)` | eigen data struct | Switch mode number, component, deformation scale, colors, and view |
| `opsMAT.vis.polyscope.plotNodalResponse(nodeResp)` | nodal response from `getNodalResponse` | Explore nodal fields, deformation, vectors, colormap, and mesh display |
| `plotFrameResponseGUI(frameResp)` | frame element response from `getElementResponse(..., eleType="Frame")` | Explore section/basic/local frame diagrams and step selection |
| `plotShellResponseGUI(shellResp)` | shell response from `getElementResponse(..., eleType="Shell")` | Explore shell section force/deformation, stress, or strain fields |
| `plotContinuumResponseGUI(planeOrSolidResp)` | plane/solid response from `getElementResponse` | Explore plane/solid stress, strain, and stress-measure fields |

### GUI Examples

```matlab
% Polyscope model/eigen/nodal windows
opsMAT.vis.polyscope.plotModel();
opsMAT.vis.polyscope.plotEigen(1, eigenData);
opsMAT.vis.polyscope.plotNodalResponse(nodeResp);

appFrame = opsMAT.vis.plotFrameResponseGUI(frameResp);

appShell = opsMAT.vis.plotShellResponseGUI(shellResp);

appPlane = opsMAT.vis.plotContinuumResponseGUI(planeResp);
```

### Common GUI Controls

The response GUIs share a common set of controls:

- Step selector: explicit 0-based step, `absMax`, `absMin`, `Max`, or `Min`.
- View selector: `auto`, `iso`, `xy`, `xz`, `yz`, `yx`, `zx`, and `zy`.
- Colormap selector: `jet`, `parula`, `turbo`, `hot`, `cool`, `spring`, `summer`, `autumn`, `winter`, and `gray`.
- `Axes off`: hide all axis ticks, labels, and box/grid decorations.
- `Colors...`: edit solid, edge, fixed-node, vector, model, or diagram colors, depending on the plotter.
- `Help`: show the option help text from the underlying plotter.

Some GUI control panels are scrollable. Use the mouse wheel or the panel scrollbar to reach controls below the visible area.

!!! note

    Response GUI functions read model information from the ODB tag stored in the response struct. For shell and continuum response GUIs, the GUI also reads nodal displacement (`respType="disp"`) from the same ODB so deformed geometry and interpolation can be displayed.

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

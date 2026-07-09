function tmp_inspect_display()
    addpath(fullfile(fileparts(mfilename('fullpath')), 'OpenSeesMatlab'));

    modelInfo = struct();
    modelInfo.Nodes.Coords = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0 0 1; 1 0 1; 1 1 1; 0 1 1];
    modelInfo.Nodes.Tags = (1:8)';
    modelInfo.Elements.Families.Beam.CellTypes = int32(3);
    modelInfo.Elements.Families.Beam.Cells = [2 1 2; 2 2 3];
    modelInfo.Elements.Families.Shell.CellTypes = int32(9);
    modelInfo.Elements.Families.Shell.Cells = [4 1 2 3 4];
    modelInfo.Elements.Families.Solid.CellTypes = int32(12);
    modelInfo.Elements.Families.Solid.Cells = [8 1 2 3 4 5 6 7 8];

    P = plotter.polyscope.ModelAdapter.nodeCoords(modelInfo);
    beamEdges = plotter.polyscope.ModelAdapter.lineEdges(modelInfo, 'Beam');
    fprintf('Beam edges: %d x %d\n', size(beamEdges,1), size(beamEdges,2));

    [Vs, Fs, ~, EPs] = plotter.polyscope.ModelAdapter.surfaceMesh(modelInfo, 'Shell');
    fprintf('Shell V=%d F=%d EP=%d\n', size(Vs,1), size(Fs,1), size(EPs,1));

    [Vso, Fso, ~, EPso] = plotter.polyscope.ModelAdapter.surfaceMesh(modelInfo, 'Solid');
    fprintf('Solid V=%d F=%d EP=%d\n', size(Vso,1), size(Fso,1), size(EPso,1));

    opts = plotter.polyscope.Options.defaultModelOptions();
    opts.polyscope.backend = 'openGL_mock';
    opts.polyscope.maximize = false;

    v = plotter.polyscope.ModelViewer(modelInfo, opts);
    v.build();

    ps = v.App.polyscopeHandle();
    fprintf('has Beam: %d\n', ps.has_curve_network('model_Beam'));
    fprintf('has Shell: %d\n', ps.has_surface_mesh('model_Shell'));
    fprintf('has Solid: %d\n', ps.has_surface_mesh('model_Solid'));
    fprintf('has ShellWire: %d\n', ps.has_curve_network('model_ShellWire'));
    fprintf('has SolidWire: %d\n', ps.has_curve_network('model_SolidWire'));
end

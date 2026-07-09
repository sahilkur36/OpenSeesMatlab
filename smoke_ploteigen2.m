modelInfo = struct();
modelInfo.Nodes.Coords = [0 0 0; 1 0 0; 1 1 0; 0 1 0; 0.5 0.5 1];
modelInfo.Nodes.Tags = [1;2;3;4;5];
modelInfo.Elements.Families.Shell.CellTypes = [5; 5];
modelInfo.Elements.Families.Shell.Cells = [3 1 2 5; 3 2 3 5];
modelInfo.Elements.Families.Shell.Tags = [10; 11];

eigenInfo = struct();
eigenInfo.ModeTags = [1; 2];
eigenInfo.EigenVectors.data = zeros(2, 5, 3);
eigenInfo.EigenVectors.data(1, :, 3) = [0; 0.2; 0.4; 0.2; 0.5];
eigenInfo.EigenVectors.data(2, :, 3) = [0; -0.3; -0.2; 0.1; 0.0];
eigenInfo.ModalProps.raw.eigenFrequency = [1.0; 2.5];

opts = plotter.polyscope.Options.defaultEigenOptions();
opts.polyscope.backend = 'openGL_mock';
opts.unstructured.wireframe = true;
opts.color.useColormap = true;
opts.unstructured.showEdges = true;
h = plotter.polyscope.plotEigen(modelInfo, eigenInfo, opts);
h.frameTick();
% turn off colormap -> should revert to solid color
h.Opts.color.useColormap = false;
h.setMode(1);
h.frameTick();
% turn on colormap again
h.Opts.color.useColormap = true;
h.setMode(1);
h.frameTick();
% wireframe off, keep surface edges via update
opts2 = plotter.polyscope.Options.defaultEigenOptions();
opts2.polyscope.backend = 'openGL_mock';
opts2.unstructured.wireframe = false;
opts2.unstructured.showEdges = true;
opts2.color.useColormap = true;
h.update(opts2);
h.frameTick();
% wireframe on, surface edges off
opts3 = plotter.polyscope.Options.defaultEigenOptions();
opts3.polyscope.backend = 'openGL_mock';
opts3.unstructured.wireframe = true;
opts3.unstructured.showEdges = false;
opts3.color.useColormap = true;
h.update(opts3);
h.frameTick();
disp('smoke eigen2 ok');

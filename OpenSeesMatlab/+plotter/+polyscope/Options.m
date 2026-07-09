classdef Options
    %OPTIONS Default option templates for plotter.polyscope viewers.
    %
    %   These templates extend the existing PlotModel / PlotEigen /
    %   PlotNodalResp defaults with Polyscope-specific fields (backend,
    %   radius, material, colour map, etc.).

    methods (Static)

        function opts = defaultModelOptions()
            opts = plotter.PlotModel.defaultOptions();
            opts.polyscope = plotter.polyscope.Options.polyscopeCommon();
            opts.general.view = '3D';
            opts.polyscope.name = 'model';
            opts.polyscope.nodeRadius   = 0.003;   % relative to scene length
            opts.polyscope.edgeRadius   = 0.0012;  % relative to scene length
            opts.polyscope.pointRenderMode = 'sphere';
            opts.polyscope.surfaceMaterial = 'flat';
            opts.polyscope.lineMaterial    = 'flat';
            opts.polyscope.surfaceSmoothShade = false;
            opts.polyscope.vectorRadius = 0.0012;
            opts.polyscope.vectorLength = 0.04;
            opts.polyscope.showNodes = false;
            opts.polyscope.showFixed = true;
            opts.polyscope.showMPConstraint = true;
            opts.polyscope.showScreenAxes = true;
            opts.polyscope.screenAxesSize = 78;
            opts.polyscope.useScreenAxesGizmo = true;
            opts.polyscope.screenAxesGizmoSize = 1.15;
            opts.polyscope.screenAxesMode = 'overlay';
            opts.slice = struct();
            opts.slice.show = false;
            opts.slice.name = 'model_SlicePlane';
            opts.slice.center = [];  % empty means model bounding-box center
            opts.slice.normal = [0, 0, 1];
            opts.slice.drawPlane = true;
            opts.slice.drawWidget = false;
            opts.slice.widgetSize = 0.75;
            opts.slice.color = [0.90, 0.35, 0.55];
            opts.slice.gridColor = [1.00, 1.00, 1.00];
            opts.slice.transparency = 0.45;
            opts.slice.cullWholeElements = false;
        end

        function opts = defaultEigenOptions()
            opts = plotter.PlotEigen.defaultOptions();
            opts.polyscope = plotter.polyscope.Options.polyscopeCommon();
            opts.polyscope.name = 'eigen';
            opts.polyscope.nodeRadius   = 0.003;
            opts.polyscope.edgeRadius   = 0.001;
            opts.polyscope.pointRenderMode = 'sphere';
            opts.polyscope.surfaceMaterial = 'flat';
            opts.polyscope.lineMaterial    = 'flat';
            opts.polyscope.surfaceSmoothShade = false;
            opts.polyscope.showScreenAxes = true;
            opts.polyscope.screenAxesSize = 78;
            opts.polyscope.useScreenAxesGizmo = true;
            opts.polyscope.screenAxesGizmoSize = 1.15;
            opts.polyscope.screenAxesMode = 'overlay';
            opts.polyscope.ghostColor       = [0.82 0.82 0.82];
            opts.polyscope.ghostTransparency = 0.35;
            opts.polyscope.scalarColorMap   = 'viridis';
            opts.polyscope.scalarSymmetry   = false;
            opts.polyscope.onscreenColorbar = false;
            opts.polyscope.onscreenColorbarLocation = [];  % empty = auto, placed near top center
            opts.polyscope.onscreenColorbarSize = 1.0;  % multiplier for the native colorbar size
            opts.polyscope.colorbarTitle = '';  % custom title for the onscreen colorbar
            opts.slice = struct();
            opts.slice.show = false;
            opts.slice.name = 'eigen_SlicePlane';
            opts.slice.center = [];
            opts.slice.normal = [0, 0, 1];
            opts.slice.drawPlane = true;
            opts.slice.drawWidget = false;
            opts.slice.widgetSize = 0.75;
            opts.slice.color = [0.90, 0.35, 0.55];
            opts.slice.gridColor = [1.00, 1.00, 1.00];
            opts.slice.transparency = 0.45;
            opts.slice.cullWholeElements = false;
            opts.unstructured.wireframe = false;
        end

        function opts = defaultNodalResponseOptions()
            opts = plotter.PlotNodalResp.defaultOptions();
            opts.polyscope = plotter.polyscope.Options.polyscopeCommon();
            opts.polyscope.name = 'resp';
            opts.polyscope.nodeRadius   = 0.0025;
            opts.polyscope.edgeRadius   = 0.00075;
            opts.polyscope.pointRenderMode = 'sphere';
            opts.polyscope.surfaceMaterial = 'flat';
            opts.polyscope.lineMaterial    = 'flat';
            opts.polyscope.surfaceSmoothShade = false;
            opts.polyscope.scalarColorMap   = 'viridis';
            opts.polyscope.onscreenColorbar = false;
            opts.polyscope.onscreenColorbarLocation = [1200, 800];
            opts.polyscope.colorbarTitle = '';
            opts.polyscope.vectorColor      = [0.85 0.33 0.10];
            opts.polyscope.vectorLength     = 0.05;  % relative
            opts.polyscope.vectorRadius     = 0.001; % relative
            opts.animation = struct('play', false, 'fps', 12, ...
                                    'loop', true, 'pingpong', false, ...
                                    'updateColors', true, 'updateVectors', false);
            opts.slice = struct();
            opts.slice.show = false;
            opts.slice.name = 'resp_SlicePlane';
            opts.slice.center = [];
            opts.slice.normal = [0, 0, 1];
            opts.slice.drawPlane = true;
            opts.slice.drawWidget = false;
            opts.slice.widgetSize = 0.75;
            opts.slice.color = [0.90, 0.35, 0.55];
            opts.slice.gridColor = [1.00, 1.00, 1.00];
            opts.slice.transparency = 0.45;
            opts.slice.cullWholeElements = false;
            opts.stepIdx = 'absmax';
        end

        function opts = defaultUnstructuredResponseOptions()
            opts = plotter.PlotUnstruResponse.defaultOptions();
            opts.polyscope = plotter.polyscope.Options.polyscopeCommon();
            opts.polyscope.name = 'unstru_resp';
            opts.polyscope.nodeRadius   = 0.0025;
            opts.polyscope.edgeRadius   = 0.00075;
            opts.polyscope.pointRenderMode = 'sphere';
            opts.polyscope.surfaceMaterial = 'flat';
            opts.polyscope.lineMaterial    = 'flat';
            opts.polyscope.surfaceSmoothShade = false;
            opts.polyscope.scalarColorMap   = 'viridis';
            opts.polyscope.onscreenColorbar = false;
            opts.polyscope.onscreenColorbarLocation = [1200, 800];
            opts.polyscope.colorbarTitle = '';
            opts.animation = struct('play', false, 'fps', 12, ...
                                    'loop', true, 'pingpong', false, ...
                                    'updateColors', true);
            opts.color.climMode = 'step';
            opts.nodes = struct('show', false);
            opts.slice = struct();
            opts.slice.show = false;
            opts.slice.name = 'unstru_resp_SlicePlane';
            opts.slice.center = [];
            opts.slice.normal = [0, 0, 1];
            opts.slice.drawPlane = true;
            opts.slice.drawWidget = false;
            opts.slice.widgetSize = 0.75;
            opts.slice.color = [0.90, 0.35, 0.55];
            opts.slice.gridColor = [1.00, 1.00, 1.00];
            opts.slice.transparency = 0.45;
            opts.slice.cullWholeElements = false;
            opts.stepIdx = 'absmax';
            opts.eleType = 'auto';
            opts.respType = 'auto';
            opts.component = 'auto';
            opts.fiberPoint = 'top';
        end

        function out = mergeOpts(base, user)
            out = base;
            if nargin < 2 || isempty(user) || ~isstruct(user)
                return;
            end
            out = plotter.polyscope.Options.mergeStruct_(out, user);
        end

    end

    methods (Static, Access = private)

        function p = polyscopeCommon()
            p = struct();
            p.backend      = 'openGL3_glfw';  % or 'openGL_mock' for headless/tests
            p.maximize     = true;            % maximize the main window on first show
            p.windowSize   = [1280, 800];     % used when maximize == false
            p.backgroundColor = [1, 1, 1];
            p.transparency = 1.0;   % Polyscope opacity: 1 = opaque, 0 = transparent
            p.ssaaFactor = 2;       % supersampling anti-aliasing, valid range 1..4
            p.maxFps = 30;
            p.enableVsync = true;
            p.alwaysRedraw = false;
            p.frameTickLimitFpsMode = 'auto';
            p.groundPlaneMode = 'shadow_only'; % 'shadow_only', 'tile', or 'none'
            p.backFacePolicy = 'identical'; % 'identical', 'different', 'custom', or 'cull'
            p.showModelInfo = false; % show the Model Info window (nodes, elements)
            p.displayNames = struct(); % user-friendly Polyscope structure names, e.g. displayNames.ElasticBeam3d = 'Line mesh';
        end

        function out = mergeStruct_(base, add)
            out = base;
            f = fieldnames(add);
            for i = 1:numel(f)
                n = f{i};
                if isfield(out, n) && isstruct(out.(n)) && isstruct(add.(n))
                    out.(n) = plotter.polyscope.Options.mergeStruct_(out.(n), add.(n));
                else
                    out.(n) = add.(n);
                end
            end
        end

    end
end

classdef TestBeam3DDispInterpolator < matlab.unittest.TestCase
    % Tests for 3D beam displacement interpolation utilities.

    methods (TestClassSetup)
        function addToolboxToPath(testCase)
            repoRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'OpenSeesMatlab')));
        end
    end

    methods (Test)
        function globalDofsConvertAndInterpolateAlongStraightBeam(testCase)
            interp = TestBeam3DDispInterpolator.makeIdentityBeam();
            nodalGlobal = [
                1 2 0 0 0 0
                3 2 0 0 0 0
            ];

            endLocal = interp.globalToLocalEnds(nodalGlobal);
            [points, response, cells] = interp.interpolate(endLocal, 3);

            testCase.verifyEqual(endLocal, ...
                [1 2 0 0 0 0 3 2 0 0 0 0], 'AbsTol', 1.0e-12);
            testCase.verifyEqual(points, [0 0 0; 0.5 0 0; 1 0 0], ...
                'AbsTol', 1.0e-12);
            testCase.verifyEqual(response(:, 1), [1; 2; 3], 'AbsTol', 1.0e-12);
            testCase.verifyEqual(response(:, 2), [2; 2; 2], 'AbsTol', 1.0e-12);
            testCase.verifyEqual(cells, int64([2 1 2; 2 2 3]));
        end

        function batchedInputsPreserveBatchDimension(testCase)
            interp = TestBeam3DDispInterpolator.makeIdentityBeam();
            nodalGlobal = zeros(2, 2, 6);
            nodalGlobal(1, :, 1) = [0 1];
            nodalGlobal(2, :, 1) = [10 20];

            endLocal = interp.globalToLocalEnds(nodalGlobal);
            [~, response] = interp.interpolate(endLocal, 2);

            testCase.verifySize(endLocal, [2 1 12]);
            testCase.verifySize(response, [2 2 3]);
            testCase.verifyEqual(response(1, :, 1), [0 1], 'AbsTol', 1.0e-12);
            testCase.verifyEqual(response(2, :, 1), [10 20], 'AbsTol', 1.0e-12);
        end

        function invalidInputsReportSpecificErrors(testCase)
            interp = TestBeam3DDispInterpolator.makeIdentityBeam();

            testCase.verifyError(@() post.utils.Beam3DDispInterpolator( ...
                [0 0 0; 1 0 0], [1 3], [1 0 0], [0 1 0], [0 0 1]), ...
                'Beam3DDispInterpolator:ConnectivityOutOfRange');
            testCase.verifyError(@() interp.globalToLocalEnds(zeros(3, 6)), ...
                'Beam3DDispInterpolator:NodeCountMismatch');
            testCase.verifyError(@() interp.interpolate(zeros(2, 12)), ...
                'Beam3DDispInterpolator:ElementCountMismatch');
            testCase.verifyError(@() interp.interpolate(zeros(1, 12), 1), ...
                'Beam3DDispInterpolator:InvalidNpts');
        end
    end

    methods (Static, Access = private)
        function interp = makeIdentityBeam()
            interp = post.utils.Beam3DDispInterpolator( ...
                [0 0 0; 1 0 0], ...
                [1 2], ...
                [1 0 0], ...
                [0 1 0], ...
                [0 0 1]);
        end
    end
end

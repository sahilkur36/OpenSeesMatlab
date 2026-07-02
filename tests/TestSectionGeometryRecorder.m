classdef TestSectionGeometryRecorder < matlab.unittest.TestCase
    % Tests for recording and plotting fiber-section geometry.

    methods (TestClassSetup)
        function addToolboxToPath(testCase)
            repoRoot = fileparts(fileparts(mfilename('fullpath')));
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture( ...
                fullfile(repoRoot, 'OpenSeesMatlab')));
        end
    end

    methods (Test)
        function recorderStoresFibersPatchesLayersAndLines(testCase)
            rec = pre.utils.SectionGeometryRecorder();

            rec.addFiber(0, 0, 1, 1);
            testCase.verifyEmpty(fieldnames(rec.Data));

            rec.setSectionTag(10);
            rec.addFiber(0.1, 0.2, 0.03, 7, "-optional");
            rec.addPatch("rect", 1, 2, 3, -1, -2, 1, 2);
            rec.addLayer("straight", 2, 4, 0.01, -1, 0, 1, 0);

            sec = rec.Data.Sec_10;
            testCase.verifyNumElements(sec.Fibers, 1);
            testCase.verifyNumElements(sec.Patches, 1);
            testCase.verifyNumElements(sec.Layers, 1);
            testCase.verifyNumElements(sec.Adds, 3);
            testCase.verifyNumElements(sec.Lines, 7);

            testCase.verifyEqual(sec.Fibers{1}.matTag, 7);
            testCase.verifyEqual(sec.Patches{1}.Type, 'rect');
            testCase.verifyEqual(sec.Layers{1}.Type, 'straight');
        end

        function plotSectionUsesRecordedData(testCase)
            rec = pre.utils.SectionGeometryRecorder();
            rec.setSectionTag(1);
            rec.addFiber(0, 0, pi * 0.1^2, 1);
            rec.addPatch("rect", 1, 1, 1, -0.5, -0.25, 0.5, 0.25);

            fig = figure('Visible', 'off');
            cleanup = onCleanup(@() close(fig));
            ax = axes(fig);

            rec.plotSection(1, ax);

            testCase.verifyEqual(ax.Title.String, 'Section 1');
            testCase.verifyGreaterThanOrEqual(numel(ax.Children), 2);
            testCase.verifyError(@() rec.plotSection(99, ax), ...
                'SectionGeometryRecorder:NotFound');

            clear cleanup
        end

        function clearRemovesRecordedSections(testCase)
            rec = pre.utils.SectionGeometryRecorder();
            rec.setSectionTag(4);
            rec.addFiber(0, 0, 1, 1);

            rec.clear();

            testCase.verifyTrue(isnan(rec.CurrentSecTag));
            testCase.verifyEmpty(fieldnames(rec.Data));
        end
    end
end

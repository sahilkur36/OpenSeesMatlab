classdef TestUnitSystem < matlab.unittest.TestCase
    % Unit tests for the pure MATLAB unit conversion helper.

    methods (TestClassSetup)
        function addToolboxToPath(testCase)
            repoRoot = fileparts(fileparts(mfilename('fullpath')));
            toolboxRoot = fullfile(repoRoot, 'OpenSeesMatlab');
            testCase.applyFixture(matlab.unittest.fixtures.PathFixture(toolboxRoot));
        end
    end

    methods (Test)
        function defaultMetricConversionsAreAvailable(testCase)
            unit = pre.UnitSystem();

            testCase.verifyEqual(unit.m, 1.0);
            testCase.verifyEqual(unit.mm, 1.0e-3, 'AbsTol', 1.0e-12);
            testCase.verifyEqual(unit.N, 1.0e-3, 'AbsTol', 1.0e-12);
            testCase.verifyEqual(unit.kN, 1.0);
            testCase.verifyEqual(unit.sec, 1.0);
        end

        function dynamicPowersAndExpressionsMatch(testCase)
            unit = pre.UnitSystem();

            testCase.verifyEqual(unit.mm2, unit.mm^2, 'AbsTol', 1.0e-18);
            testCase.verifyEqual(unit("N/mm^2"), unit.N / unit.mm^2, ...
                'RelTol', 1.0e-12);
            testCase.verifyEqual(unit("kN*m/sec^2"), unit.kN * unit.m / unit.sec^2, ...
                'RelTol', 1.0e-12);
        end

        function resetChangesBaseUnits(testCase)
            unit = pre.UnitSystem();

            unit.setBasicUnits("mm", "N", "sec");

            testCase.verifyEqual(unit.mm, 1.0);
            testCase.verifyEqual(unit.m, 1000.0);
            testCase.verifyEqual(unit.N, 1.0);
            testCase.verifyEqual(unit.kN, 1000.0);
            testCase.verifyEqual(unit.MPa, 1.0, 'AbsTol', 1.0e-12);
        end

        function aliasesResolveCaseInsensitively(testCase)
            unit = pre.UnitSystem();

            testCase.verifyEqual(unit.s, unit.sec);
            testCase.verifyEqual(unit.ms, unit.msec);
            testCase.verifyEqual(unit.KIPS, unit.kip);
        end

        function invalidExpressionsReportUsefulErrors(testCase)
            unit = pre.UnitSystem();

            testCase.verifyError(@() unit(""), "UnitSystem:EmptyExpression");
            testCase.verifyError(@() unit("N//mm"), "UnitSystem:ParseError");
            testCase.verifyError(@() unit("banana"), "UnitSystem:UnknownUnit");
            testCase.verifyError(@() unit.unknownUnit, "UnitSystem:UnknownUnit");
        end
    end
end

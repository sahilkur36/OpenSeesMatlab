function results = runTests()
%RUNTESTS Run the OpenSeesMatlab automated test suite.
%
%   results = runTests() adds the local toolbox source folder to the MATLAB
%   path, discovers tests under tests/, runs them, and fails if any test does
%   not pass.

    repoRoot = fileparts(mfilename('fullpath'));
    addpath(fullfile(repoRoot, 'OpenSeesMatlab'));

    suite = testsuite(fullfile(repoRoot, 'tests'), 'IncludeSubfolders', true);
    results = run(suite);

    assertSuccess(results);
end

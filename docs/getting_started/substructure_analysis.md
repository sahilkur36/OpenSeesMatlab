# MATLAB Substructure Analysis

!!! note

    - This is an additional feature added to OpenSeesMatlab and is not a native OpenSees command.
    - Currently, it only supports numerical sub-models created within Matlab.
    - Any bugs or new request can be submitted as issues on GitHub.

[`matlabSubstructure`][ops.OpenSeesMatlabCmds.matlabSubstructure] lets an OpenSees model use a substructure calculated by a
MATLAB function. OpenSees treats it like an ordinary Element; when it needs the
Element force or tangent stiffness, it calls your MATLAB callback.

The MATLAB-side workflow is: write one callback, create the OpenSees interface
nodes, register the Element, and run the analysis. The complete example below
keeps those steps together so it can be copied directly.

## Decide what MATLAB and OpenSees each own

Treat `matlabSubstructure` as a condensed boundary Element:

| OpenSees | MATLAB callback |
| --- | --- |
| Owns the global nodes, constraints, loading and solution algorithm | Owns the internal substructure model behind the interface |
| Supplies trial interface displacement, velocity and acceleration | Converts that motion into interface force, tangent and optional mass/damping |
| Accepts or rejects Newton trials and time steps | Produces a candidate history state from the last accepted state |
| May own ground motion and support excitation | May instead own internal ground excitation, but must not duplicate it |

The command does not automatically condense a MATLAB model. Your callback must
already implement the map from interface motion to compatible interface force
and tangent. It must not start another OpenSees command from inside the callback.

## Complete example

First save this callback as `mySubstructure.m` somewhere on the MATLAB path:

```matlab
function [response, trialState, status] = ...
    mySubstructure(action, trial, committedState)
% Linear spring substructure used by the example below.

status = int32(0);
trialState = committedState;

switch lower(string(action))
case {"init", "trial"}
    K = committedState.K;
    response.force = K * trial.disp;
    response.tangent = K;

    if strcmpi(action, "init")
        response.initialStiffness = K;
    end

    trialState.disp = trial.disp;
    trialState.time = trial.time;

case {"commit", "revert", "reverttostart", "shutdown"}
    response = struct();

otherwise
    response = struct();
    status = int32(-1);
end
end
```

Then run this script. It creates the package interface, builds a two-DOF
spring, applies a unit load, performs one static step, and reads the result:

```matlab
opsMAT = OpenSeesMatlab();
ops = opsMAT.opensees;
ops.wipe();

% 1. Data owned by the MATLAB substructure
K0 = 1000 * [1 -1; -1 1];
state0 = struct("K", K0);

% 2. OpenSees model and interface nodes
ops.model("basic", "-ndm", 1, "-ndf", 1);
ops.node(1, 0.0);
ops.node(2, 1.0);
ops.fix(1, 1);

% Each row is [nodeTag, oneBasedDOF]. Row order defines the order of
% trial.disp and response.force, and must match K0.
interfacePairs = [
    1 1
    2 1
];

% 3. Register the callback and create the OpenSees Element
eleTag = 1001;
ops.matlabSubstructure(eleTag, @mySubstructure, state0, K0, ...
    interfacePairs, "matlab");

% 4. Load and analysis
ops.timeSeries("Linear", 1);
ops.pattern("Plain", 1, 1);
ops.load(2, 1.0);
ops.constraints("Plain");
ops.numberer("Plain");
ops.system("BandGeneral");
ops.test("NormUnbalance", 1e-10, 10);
ops.algorithm("Newton");
ops.integrator("LoadControl", 1.0);
ops.analysis("Static");
ok = ops.analyze(1);
if ok ~= 0
    error("OpenSees analysis failed with code %d.", ok);
end

u2 = ops.nodeDisp(2, 1);
fInterface = ops.eleResponse(eleTag, "interfaceForce");

% 5. Query results first, then remove the Element before its callback record.
ops.wipe();
ops.clearMatlabSubstructures();
```

`ok == 0` means the step succeeded. Check it before trusting the queried
results; `u2` should be about `0.001`. The final
argument is optional: `"matlab"` uses the current tangent returned by MATLAB
(the default), whereas `"initial"` always uses `K0`. The wrapper validates the
tag, callback, dimensions, interface rows, and tangent mode before forwarding
the command to the MEX interface.

### Callback sequence during an analysis

OpenSees may evaluate one step as follows:

```text
first update               -> init, then trial
each Newton iteration      -> trial
successful step            -> commit
failed/restarted iteration -> revert
Element removal/wipe       -> shutdown
```

Several `trial` calls can occur at the same analysis time. Thus a callback call
is not a time step. `trial.dt` is measured from the last committed time, and
`trial.isNewTime` only says that the current time differs from that committed
time; neither means the current trial will be accepted.

## Choosing the interface DOFs

`interfacePairs` is an N-by-2 matrix. Each row contains
`[OpenSees node tag, MATLAB-style one-based DOF]`. N must equal the number of
components in `response.force` and both dimensions of `K0` and
`response.tangent`.

```matlab
interfacePairs = [1 1; 1 2; 4 1; 4 2];
```

This maps `trial.disp(1:4)` to node 1 DOFs 1 and 2, followed by node 4 DOFs 1
and 2. All interface vectors use that same order.

The substructure is not restricted to two OpenSees nodes:

- If MATLAB already contains the pile, soil, far-field boundary, and ground
  reference, expose only the pile-head DOFs.
- If MATLAB describes relative behavior between two physical ends, expose
  both ends. The second end may be active or fixed in OpenSees.

For a MATLAB pile-soil model with its own ground reference, a single six-DOF
pile-head node is enough:

```matlab
ops.model("basic", "-ndm", 3, "-ndf", 6);
ops.node(100, 0.0, 0.0, 0.0);
interfacePairs = [(100 * ones(6,1)), (1:6)'];
ops.matlabSubstructure(5001, @pileSoilSubstructure, ...
    state0, K0, interfacePairs);
```

Do not add a fixed OpenSees ground node if the same reference is already inside
MATLAB. Conversely, do not omit the second end if neither side otherwise
defines a reference, or the model may have a rigid-body mechanism. Apply a
given earthquake excitation in either MATLAB or OpenSees unless the formulation
explicitly requires both, so it is not counted twice.

## Callback contract

The main inputs are `trial.disp`, `trial.vel`, `trial.accel`, `trial.time`,
`trial.dt`, and `trial.elementTag`. Additional fields are `action`, `isInitial`,
`isNewTime`, `previousCommittedTime`, `activeDofCount`, `interfacePairs`,
`callId`, and `committedRevision`.

For `init` and `trial`, return finite real doubles in `response.force` (N
values) and `response.tangent` (N-by-N). Optional fields are
`initialStiffness`, `mass`, `damping`, `initialMass`, and `initialDamping`.
Missing initial stiffness falls back to the `K0` supplied when the Element was
created.

When mass or damping is returned, OpenSees forms

```text
R_total = response.force + response.damping * trial.vel
                         + response.mass * trial.accel
```

Do not include the same `C*v` or `M*a` contribution in `response.force`. A
constitutive force that inherently depends on velocity may stay in
`response.force`; normally do not return it again as a damping matrix.

The returned mass and damping are OpenSees Element matrices. Transient analysis
therefore assembles `M*a` and `C*v` from the current nodal kinematics.
`UniformExcitation` is handled by the normal OpenSees
`-M*R*groundAcceleration` element-load convention. If Rayleigh damping is also
assigned to this Element, OpenSees adds the Rayleigh matrix to
`response.damping`; do not duplicate it in the callback.

Under `UniformExcitation`, `trial.accel` is the nodal relative acceleration
used by the transient integrator, not a request to add the ground acceleration
again. If the MATLAB substructure applies ground motion internally, do not also
apply the same excitation to it through OpenSees.

Every callback evaluation starts from `committedState`. Return a candidate
`trialState`; OpenSees accepts it only when the step commits. Do not retain and
reuse uncommitted trial state in MATLAB. Callbacks implementing only `init` and
`trial` are supported; `commit`, `revert`, `reverttostart`, and `shutdown` are
available for logging, reset, or cleanup.

For a path-dependent model, always calculate history this way:

```matlab
[force, tangent, historyTrial] = evaluateModel( ...
    trial.disp, trial.vel, trial.time, committedState.history);
response.force = force;
response.tangent = tangent;
trialState = committedState;
trialState.history = historyTrial;
```

Never advance a persistent/global history on every `trial` call. Newton can
retry the same step, so that would accumulate unaccepted history. The tangent
should be consistent with the returned force; otherwise Newton convergence may
be slow or fail. Selecting `"initial"` tangent mode merely makes OpenSees use a
fixed initial tangent (modified Newton); the callback must still return the
correct nonlinear force.

### Static and transient models

For static stiffness-only behavior, return only `force` and `tangent`. For a
transient model, return mass and damping only if they physically belong to the
MATLAB substructure. Do not also put the same mass on OpenSees interface nodes.
Mass and damping must be full N-by-N matrices; use zero rows and columns for
DOFs that have none.

Omitting mass or damping in a trial means zero for that trial, not “reuse the
last value.” During `init`, `K0` is the fallback `initialStiffness`, and
`initialMass`/`initialDamping` default to the mass/damping returned by `init`.
These initial matrices remain fixed after initialization.

## Querying and recording results

Queries read stored C++ results and do not invoke the callback:

```matlab
f  = ops.eleResponse(eleTag, "interfaceForce");
u  = ops.eleResponse(eleTag, "interfaceDisp");
K  = ops.eleResponse(eleTag, "tangent");
K0 = ops.eleResponse(eleTag, "initialStiffness");
M  = ops.eleResponse(eleTag, "mass");
C  = ops.eleResponse(eleTag, "damping");
rt = ops.eleResponse(eleTag, "forceIncInertia");

ops.recorder("Element", "-file", "interfaceForce.out", ...
    "-ele", eleTag, "interfaceForce");
```

The wrapper may return a matrix as a flattened row vector, although the
underlying OpenSees value remains N-by-N. Aliases include `force`, `forces`,
`globalForce`, `activeForce`, `localForce`, `disp`, `vel`, `accel`, `stiffness`,
`initialMass`, `initialDamping`, and `interfacePairs`. Here `localForce` means
interface force; this Element has no separate geometric local axes.

Performance queries include `callCount`, `trialCallCount`, `commitCount`,
`callbackTime`, `lastCallbackTime`, `maxCallbackTime`, and `meanCallbackTime`:

```matlab
nTrial = ops.eleResponse(eleTag, "trialCallCount");
tMean = ops.eleResponse(eleTag, "meanCallbackTime");
```

They count actual MATLAB calls and reset on `revertToStart()`.

## Restrictions and cleanup

- Do not call `ops`, `opsMAT`, or the underlying MEX interface inside the
  callback; re-entering the MEX call is unsupported.
- Callbacks run only in the local MEX process and are not thread-safe.
- Distributed `sendSelf/recvSelf` is not supported.
- Remove active Elements first (normally with `ops.wipe()`), then use
  `ops.unregisterMatlabSubstructure(eleTag)` for one callback or
  `ops.clearMatlabSubstructures()` for all callbacks.
- Use `ops.hasMatlabSubstructure(eleTag)` to test whether a tag is registered.

The Element does not select the analysis algorithm or integrator. Configure
`Linear`, `Newton`, `ModifiedNewton`, `KrylovNewton`, `NewtonLineSearch`,
`Newmark`, `HHT`, and other methods through the usual OpenSees commands.

## Checklist before a full analysis

- All interface nodes already exist; each `[nodeTag, DOF]` is valid and unique.
- N equals the force length and every dimension of `K0` and the returned
  tangent, mass and damping matrices.
- Every response value is a finite real `double` and uses internal
  resisting-force signs.
- Ground reference, mass, damping and earthquake excitation each exist only
  once across MATLAB and OpenSees.
- The returned tangent has been compared with a small finite-difference change
  in force.
- The script checks `ok == 0` before using results.
- Cleanup is performed with `ops.wipe()` before unregistering or clearing
  callback records.

## Examples

[Numerical Substructure Analysis](../examples/substruct/index.md)

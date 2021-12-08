function [crd, trj, vel] = meanstructure2d(trj, index, mass, tolerance, vel)
%% meanstructure2d
% calc average structure by iterative superimpose in the XY space (Z-axis ignored)
%
%% Syntax
%# crd = meanstructure2d(trj);
%# crd = meanstructure2d(trj);
%# [crd, trj] = meanstructure2d(trj);
%# [crd, trj] = meanstructure2d(trj, index_atom);
%# [crd, trj] = meanstructure2d(trj, index_atom, mass);
%# [crd, trj] = meanstructure2d(trj, index_atom, mass, tolerance);
%# [crd, trj] = meanstructure2d(trj, index_atom, mass, tolerance, vel);
%# [crd, trj, vel] = meanstructure2d(trj, [], [], [], vel);
%
%% Description
% This routine calculates the average structure from given
% trajectory. The algorithm superimposes the trajectories to a
% plausible average structure, then updates the average structrue.
% In the superimpose step, only XY-space is considered (Z-direction
% is ignored, this style should be convenient for membrane proteins).
% This process is repeated until some convergence is achieved in
% the RMSD between the average structures.
% This routine may be useful for a preprocess
% for the subsequent structure-analysis routines, such as Principal
% Component Analysis. 
%
%% Example
%# trj = readnetcdf('ak.nc');
%# [crd, trj] = meanstructure(trj);
%
%% See also
% superimpose
%

%% initialization
ref = trj(1, :);
rmsd = realmax;

if ~exist('index', 'var')
  index = [];
end
  
if ~exist('mass', 'var')
  mass = [];
end

if ~exist('tolerance', 'var') || isempty(tolerance)
  tolerance = 10^(-6);
end

if ~exist('vel', 'var')
  vel = [];
end

%% iterative superimpose
%ref = decenter2d(ref, index, mass);
%trj = decenter2d(trj, index, mass);
if numel(vel) ~= 0
  vel = decenter2d(vel, index, mass);
end

while rmsd > tolerance
  ref_old = ref;
  [~, trj, vel] = superimpose2d(ref, trj, index, mass, vel, true);
  ref = mean(trj);
  %ref = decenter2d(ref, index, mass);
  rmsd = superimpose2d(ref_old, ref, index, mass, [], true);
  fprintf('rmsd from the previous mean structure: %f A\n', rmsd);
end

crd = ref;
[~, trj, vel] = superimpose2d(ref, trj, index, mass, vel);


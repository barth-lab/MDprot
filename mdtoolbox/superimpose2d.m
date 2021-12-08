function [rmsd, trj, vel, Ucell] = superimpose2d(ref, trj, index, mass, vel, isdecentered)
%% superimpose2d
% least-squares fitting of structures in xy-plane by Kabsch's method
%
%% Syntax
%# rmsd = superimpose2d(ref, trj);
%# rmsd = superimpose2d(ref, trj, index_atom);
%# rmsd = superimpose2d(ref, trj, index_atom, mass);
%# rmsd = superimpose2d(ref, trj, [], mass);
%# [rmsd, trj] = superimpose2d(ref, trj, index_atom, mass);
%# [rmsd, trj, vel] = superimpose2d(ref, trj, index_atom, mass, vel);
%# [rmsd, trj, vel] = superimpose2d(ref, trj, index_atom, [], vel);
%# [rmsd, trj, vel] = superimpose2d(ref, trj, [], [], vel);
%
%% Description
%
% * ref        - reference structure 
%                [double natom3]
% * trj        - trajectory fitted to the reference structure in xy-plane
%                [double nframe x natom3]
% * index_atom - index of atoms used in the calculation of fitting
%                [integer n]
% * mass       - mass
%                [double natom]
% * vel        - velocity
%                [double nframe x natom3]
% * rmsd       - root mean square deviations after fitting in xy-plane
%                [double nframe]
% 
%% Example
%# trj = readnetcdf('ak.nc');
%# ref = trj(1,:);
%# [rmsd, trj] = superimpose2d(ref, trj);
%# plot(rmsd)
%
%% See also
% superimpose
%
%% References
% W. Kabsch, "A solution for the best rotation to relate two sets of vectors." 
% Acta Cryst A32, 922-923 (1976)
% W. Kabsch, "A discussion of the solution for the best rotation to relate two sets of vectors." 
% Acta Cryst A34, 827-828 (1978)
% 
%% TODO
% implementation of the Quaternion Characteristic Polynomial method
%

%% preparation
natom3 = size(ref, 2);
natom  = natom3/3;
nframe = size(trj, 1);

if ~exist('index', 'var') || isempty(index)
  index = 1:natom;
else
  if islogical(index)
    index = find(index);
  end
  if iscolumn(index)
    index = index';
  end
end
index3 = to3(index);

if ~exist('mass', 'var') || isempty(mass)
  mass = ones(1, natom);
else
  if iscolumn(mass)
    mass = mass';
  end
end

if ~exist('vel', 'var')
  vel = [];
end

if ~exist('isdecentered', 'var')
  isdecentered = false;
end

if nargout >= 4
  Ucell = cell(nframe, 1);
end

%% remove the center of mass in xy-plane
if ~isdecentered
  trj = decenter2d(trj, index, mass);
  [ref, comy] = decenter2d(ref, index, mass);
  if numel(vel) ~= 0
    vel = decenter2d(vel, index, mass);
  end
else
  comy = [0 0 0];
end

mass = mass(index);
massxyz = repmat(mass, 3, 1);
y = reshape(ref(1, index3), 3, numel(index));
rmsd = zeros(nframe, 1);

%% superimpose
for iframe = 1:nframe
  % calculate R matrix
  x = reshape(trj(iframe, index3), 3, numel(index));
  rmsd(iframe) = 0.5 * sum(mass.*sum(x(1:2, :).^2 + y(1:2, :).^2));
  R = (massxyz(1:2, :).*y(1:2, :)) * x(1:2, :)';
  [V, D, W] = svd(R);
  D = diag(D);

  % check reflection
  is_reflection = det(V)*det(W');
  if(is_reflection < 0) 
    D(2) = -D(2);
    V(:, 2) = -V(:, 2);
  end
  rmsd(iframe) = rmsd(iframe) - sum(D);

  if nargout >= 2
    % calculate rotation matrix
    U = eye(3);
    U(1:2, 1:2) = V*W';
    if nargout >= 4
      Ucell{iframe} = U;
    end

    % rotate molecule
    x = reshape(trj(iframe, :), 3, natom);
    x = U*x;

    % restore the original center of mass
    x(1, :) = x(1, :) + comy(1);
    x(2, :) = x(2, :) + comy(2);
    %x(3, :) = x(3, :) + comy(3);
    trj(iframe, :) = reshape(x, 1, natom3);
  
    if numel(vel) ~= 0
      % rotate velocity
      v = reshape(vel(iframe, :), 3, natom);
      v = U*v;
      vel(iframe, :) = reshape(v, 1, natom3);
    end
  end
end

rmsd = sqrt(2.0*abs(rmsd)./sum(mass));


function ene = calcvdw(parm, trj, cutoff, box);
%% calcvdw
% calculate vdw energy from input coordinates or trajectory
%
%% Syntax
%# ene = calcvdw(parm, trj, cutoff);
%
%% Description
%
%% Example
%# parm = readparm('data/ala.parm');
%# [trj, box] = readnetcdf('data/ala.nc');
%# vdw = calcvdw(parm, trj, 8.0, box)
%# ene = readamberout('data/ala.out');
%
%% See alo
% 
% 

%% setup
% total number of atoms
natom  = parm.natom;

% total number of distinct atom types;
ntypes = parm.ntypes;

%index for the atom types involved in Lennard Jones (6-12)
iac    = parm.atom_type_index;

% index to the nonbon parameter arrays CN1, CN2 and ASOL, BSOL indexed by iac
ico    = parm.nonbonded_parm_index;

% Lennard Jones r**12 coefficients for all possible atom type interactions indexed by ico and iac
cn1    = parm.lennard_jones_acoef;

% Lennard Jones r**6  coefficients for all possible atom type interactions indexed by ico and iac
cn2    = parm.lennard_jones_bcoef;

% r**12 coefficients for hydrogen bonds of all
asol   = parm.hbond_acoef;

% r**10 coefficients for hydrogen bonds of all
bsol   = parm.hbond_bcoef;

%% atom_index -> atom_type_index -> vdw_index -> coefficients

% atom_type_index = iac;

% vdw_index = zeros(ntypes, ntypes);
% for i = 1:ntypes
%   for j = 1:ntypes
%     vdw_index(i, j) = ico(ntypes*(i - 1) + j);
%   end
% end

% vdw_coef_a = cn1;
% vdw_coef_b = cn2;

% [pair, r] = calcpairlist_exhaustive(crd, cutoff, box);
% [pair, irows] = setdiff(pair, parm.excluded_pair, 'rows');
% r = r(irows, :);

% index = arrayfun(@(x,y) vdw_index(x,y), ...
%          atom_type_index(pair(:,1)), atom_type_index(pair(:,2)));

% lj_coef12 = vdw_coef_a(index(index > 0));
% lj_coef6  = vdw_coef_b(index(index > 0));
% lj_r      = r(index > 0);
% ene = sum((lj_coef12./(lj_r.^(12))) - (lj_coef6./(lj_r.^(6))))

% num_vdw_type = zeros(ntypes, 1);
% for i = 1:natom
%   j = atom_type_index(i);
%   num_vdw_type(j) = num_vdw_type(j) + 1;
% end

% lrc = 0;
% for i = 1:ntypes
%   for j = 1:ntypes
%     k = vdw_index(i, j);
%     if(k > 0)
%       lrc = lrc + num_vdw_type(i) * num_vdw_type(j) ...
%             * vdw_coef_b(k);
%     end
%   end
% end
% prefactor = 2.0*pi/(3.0*box(1)*box(2)*box(3)*(cutoff.^3));
% lrc = -prefactor*lrc
% ene = ene + lrc

%% calculate vdw energy
nframe = size(trj, 1);
ene = zeros(nframe, 1);

for iframe = 1:nframe
  iframe
  % calc pair-list within cutoff
  %[pair, r] = calcpairlist_exhaustive(trj(iframe, :), cutoff, box(iframe, :));
  [pair, r] = calcpairlist(trj(iframe, :), cutoff, box(iframe, :));
  % remove exclusion pairs
  [pair, irows] = setdiff(pair, parm.excluded_pair, 'rows');
  r = r(irows, :);

  index     = ico( ntypes*(iac(pair(:, 1)) - 1) + iac(pair(:, 2))  );
  lj_coef12 = cn1(index(index > 0));
  lj_coef6  = cn2(index(index > 0));
  lj_r      = r(index > 0);
  ene(iframe) = sum((lj_coef12./(lj_r.^(12))) - (lj_coef6./(lj_r.^(6))));
end










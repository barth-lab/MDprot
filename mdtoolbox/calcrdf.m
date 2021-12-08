function [rdf, center] = calcrdf(index_atom1, index_atom2, trj, box, edge, nblock)
%% calcrdf
% calculate radial distribution function (RDF) of two atom types specfied index_atom1 and index_atom2
%
%% Syntax
%# [rdf, center] = calcrdf(index_atom1, index_atom2, trj, box);
%# [rdf, center] = calcrdf(index_atom1, index_atom2, trj, box, edge);
%# [rdf, center] = calcrdf(index_atom1, index_atom2, trj, box, edge, nblock);
%
%% Description
% Calculate radial distribution function (RDF) between 
% two atom types specfied by index_atom1 and index_atom2  
%
% * index_atom1 - atom index for atom type 1 [logical index or index n]
% * index_atom2 - atom index for atom type 2 [logical index or index m]
% * trj         - trajectorys [double nframe x natom3]
% * box         - box size [double nframe x 3 or 1 x 3]
% * edge        - edges of bins used for RDF histogram [double 1 x nbin+1]
% * nblock      - the number of blocks used for error evaluation. default is 1 (no error estimation)
%                 [integer scalar]
% * rdf         - radial distribution function [double nbin x 1]
%                 if nblock > 1, twice of standard deviation is added in 2nd column for 95% confidence interval
% * center      - centers of bins [double 1 x nbin]
%
%% Example
%# psf = readpsf('run.psf');
%# index1 = selectname(psf.atom_name, 'OH2');
%# index2 = selectname(psf.atom_name, 'OH2');
%# edge = 0.0:0.1:10.0;
%# [trj, box] = readdcd('run.dcd');
%# [rdf, center] = calcrdf(atom1, atom2, trj, box, edge);
%# plot(center, rdf); formatplot
%
%% See alo
% calcdensity
% 

%% setup
nframe = size(trj, 1);

% box
if ~exist('box', 'var') || isempty(box)
  error('box information is necessary for radial distribution function.');
elseif (size(box, 1) == 1)
  box = repmat(box, nframe, 1);
end

% edge
if ~exist('edge', 'var') || isempty(edge)
  edge = 0:0.1:10.0;
end
rcut  = max(edge);
center = 0.5 * (edge(2:end) + edge(1:(end-1)));
nbin  = numel(center);

% nblock
if ~exist('nblock', 'var') || isempty(nblock)
  nblock = 1;
end

% calculate the number of pairs (npair)
if islogical(index_atom1) && islogical(index_atom2)
  npair = nnz(index_atom1)*nnz(index_atom2) - nnz(index_atom1 & index_atom2);
else
  if islogical(index_atom1)
    index_atom1 = find(index_atom1);
  end
  if islogical(index_atom2)
    index_atom2 = find(index_atom2);
  end
  npair = numel(index_atom1)*numel(index_atom2) - numel(intersect(index_atom1, index_atom2));
end
index_atom1 = to3(index_atom1);
index_atom2 = to3(index_atom2);

% evaluate RDF
interface = round(linspace(0, nframe, nblock+1));
rdf = {};
for iblock = 1:nblock
  istart = interface(iblock)+1;
  iend = interface(iblock+1);
  if nblock > 1
    fprintf('[block %d] from frame %d to frame %d\n', iblock, istart, iend);
  end
  rdf{iblock} = kernelfunction(index_atom1, index_atom2, trj, box, edge, npair, nbin, rcut, istart, iend);
end

rdf = cell2mat(rdf);
if nblock > 1
  rdf = [mean(rdf, 2), 2*std(rdf, [], 2)];
end

%%%%%%%% kernel function
function rdf = kernelfunction(index_atom1, index_atom2, trj, box, edge, npair, nbin, rcut, istart, iend);
count  = zeros(1, nbin);
for iframe = istart:iend
  crd1 = trj(iframe, index_atom1);
  crd2 = trj(iframe, index_atom2);
  [~, dist] = searchrange(crd1, crd2, rcut, box(iframe, :));
  index_different_pair = (dist > 10.^(-6));
  count1 = histc(dist(index_different_pair), edge); count = count + count1(1:nbin)'; % for old versions of MATLAB
  %count1 = histcounts(dist(index_different_pair), edge); count = count + count1; % for new versions of MATLAB
end

shell_volume = (4./3) * pi * (edge(2:end).^3 - edge(1:(end-1)).^3);
s = npair * sum(1.0./prod(box(istart:iend, :), 2)) * shell_volume;
rdf = (count./s)';


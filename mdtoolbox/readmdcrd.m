function [trj, title] = readmdcrd(natom, filename, index)
%% readmdcrd
% read amber ascii-format trajectory file
%
%% Syntax
%# trj = readmdcrd(natom, filename);
%# trj = readmdcrd(natom, filename, index_atom);
%# [trj, title] = readmdcrd(natom, filename, index_atom);
%
%% Description
% The XYZ coordinates of atoms are read into 'trj' variable
% which has 'nframe' rows and '3*natom' columns.
% Each row of 'trj' has the XYZ coordinates of atoms in order 
% [x(1) y(1) z(1) x(2) y(2) z(2) ... x(natom) y(natom) z(natom)].
%
% * natom      - # of atoms [integer]
% * filename   - input amber trajectory filename [chars]
% * index_atom - atom index or logical index specifying atoms to be read
% * trj        - trajectory [nframe x natom3 double]
% * title      - title characters [chars]
%
%% Example
%# trj = readmdcrd('ak.trj');
%
%% See also
% readmdcrdbox
% writemdcrd
% 
%% References
% http://ambermd.org/formats.html#trajectory
%

%% initialization
trj = [];
natom3 = natom*3;
iblock = 1;

if ~exist('index', 'var') || isempty(index)
  index = 1:natom;
else
  if islogical(index)
    index = find(index);
  end
end
index3 = to3(index);

% buffer size is about 1 GByte
nblock = ceil(10^9 / (8*numel(index3)));
if nblock < 3
  nblock = 3;
end

trj_buffer = zeros(nblock, numel(index3));

%% open file
filename = strtrim(filename);
if (numel(filename) >= 3) && strncmpi(filename((end-2):end), '.gz', numel('.gz'))
  dirname = tempname();
  dirname = [dirname '/'];
  mkdir(dirname);
  fprintf('uncompressing %s into %s', filename, dirname);
  filename = gunzip(filename, dirname);
  filename = filename{1};
  disp('done')
  cleaner_rmdir = onCleanup(@() rmdir(dirname, 's'));
end

fid = fopen(filename, 'r');
assert(fid > 0, 'Could not open file.');
cleaner = onCleanup(@() fclose(fid));

%% parse
title = fgetl(fid);
while ~feof(fid)
  % coordinates
  c = textscan(fid, '%8.3f', natom3);
  x = cell2mat(c)';
  if length(x) < natom3; break; end
  trj_buffer(iblock, :) = x(index3);
  % preprocess
  iblock = iblock + 1;
  if iblock > nblock
    trj = [trj; trj_buffer];
    iblock = 1;
  end
end

if iblock > 1
  trj = [trj; trj_buffer(1:(iblock-1), :)];
end


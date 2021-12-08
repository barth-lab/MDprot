function [trj, box, vel] = readmarbletrj(filename, index_atom, index_time)
%% readmarbletrj
% read marble ascii-format trajectory file
%
%% Syntax
%# trj = readmarbletrj(filename);
%# trj = readmarbletrj(filename, index_atom);
%# trj = readmarbletrj(filename, index_atom, index_time);
%# [trj, box] = readmarbletrj(filename, index_atom, index_time);
%# [trj, box, vel] = readmarbletrj(filename, index_atom, index_time);
%
%% Description
% The XYZ coordinates of atoms are read into 'trj' variable
% which has 'nframe' rows and '3*natom' columns.
% Each row of 'trj' has the XYZ coordinates of atoms in order 
% [x(1) y(1) z(1) x(2) y(2) z(2) ... x(natom) y(natom) z(natom)].
%
% * filename   - input marble trajectory filename
% * index_atom - atom index or logical index specifying atoms to be read
% * index_time - time index or logical index specifying time frames to be read
% * trj        - trajectory [nframex3natom double]
% * box        - box size [nframex3 double]
% * vel        - velocities [nframex3natom double]
%
%% Example
%# trj = readmarbletrj('eq.trj');
%
%% See alo
% readmarbletrjbin
% readmarblecrd
%

%% initialization
is_trj = false;
is_box = false;
is_vel = false;

if ~exist('index_time', 'var') || isempty(index_time)
  index_time = [];
end

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

%% read header
line = strtrim(fgetl(fid));
line = regexp(line, ' ', 'split');
natom = str2double(line{6}(1:end-1));
natom3 = natom*3;
trj_type = line{8};

if regexp(trj_type, 'X')
  is_trj = true;
end

if regexp(trj_type, 'B')
  is_box = true;
end

if regexp(trj_type, 'V')
  is_vel = true;
end

if ~exist('index_atom', 'var') || isempty(index_atom)
  index_atom = 1:natom;
else
  if islogical(index_atom)
    index_atom = find(index_atom);
  end
end
index_atom3 = to3(index_atom);

%% allocation
if is_trj
  trj = zeros(1, numel(index_atom3));
end

if is_vel
  vel = zeros(1, numel(index_atom3));
end

if is_box
  box = zeros(1, 3);
end

%% read data
iframe = 0;
idata = 0;
while ~feof(fid)
  iframe = iframe + 1;
  if isempty(index_time) || ismember(iframe, index_time)
    idata = idata + 1;
    if is_trj
      %crd = fscanf(fid, '%f %f %f\n', [3 natom]);
      %trj_buffer(idata, :) = crd';
      crd = textscan(fid, '%f', natom3);
      xx = cell2mat(crd);
      if numel(xx) < natom3; break; end
      trj(idata, :) = xx(index_atom3)';
    end

    if is_vel
      vcrd = textscan(fid, '%f', natom3);
      vv = cell2mat(vcrd);
      if numel(vv) < natom3; break; end
      vel(idata, :) = vv(index_atom3)';
    end

    if is_box
      %crd2 = fscanf(fid, '%f %f %f\n', [3 3]);
      %box_buffer(idata, :) = diag(crd2)';
      bcrd = textscan(fid, '%f', 9);
      bb = cell2mat(bcrd);
      if numel(bb) < 9; break; end
      box(idata, :) = bb([1 5 9])';
    end
  else
    if is_trj
      crd = textscan(fid, '%f', natom3);
    end

    if is_vel
      vcrd = textscan(fid, '%f', natom3);
    end
    
    if is_box
      bcrd = textscan(fid, '%f', 9);
    end
  end
   
  if (~isempty(index_time)) && (iframe >= max(index_time))
    break;
  end
end








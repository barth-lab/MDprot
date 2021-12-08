function writemdcrd(filename, trj, box, title)
%% writemdcrd
% write amber ascii-format trajectory format file
%
%% Syntax
%# writemdcrd(filename, trj)
%# writemdcrd(filename, trj, box)
%# writemdcrd(filename, trj, box, title)
%# writemdcrd(filename, trj, [], title)
%
%% Description
% This code puts trajectories into an amber trajectory format file. 
% If box information is given, box sizes are appended.
%
% * filename  - output dcd trajectory filename
% * trj       - trajectory [nframe x natom3 double]
% * box       - box size [nframe x 3 double]
% * title     - title characters [chars]
%
%% Example
%# natom = 3343;
%# trj = readmdcrd(natom, '4ake.trj');
%# trj(:, 1:3:end) = trj(:, 1:3:end) + 1.5;
%# writemdcrd('4ake_translated.trj', trj, [], 'translated in x axis')
%
%% See also
% readmdcrd
% readmdcrdbox
%
%% References
% http://ambermd.org/formats.html#trajectory
%

%% check existing file
if exist(filename, 'file')
  filename_old = sprintf('%s.old', filename);
  display(sprintf('existing file %s is moved to %s', filename, filename_old));
  movefile(filename, filename_old);
end

%% initialization
natom3 = size(trj, 2);
nframe = size(trj, 1);

if ~exist('title', 'var') || isempty(title)
  title = sprintf('FILENAME=%s CREATED BY MATLAB', filename);
end
for i = (numel(title)+1):80
  title = [title ' '];
end

%% open file
fid = fopen(filename, 'w');
assert(fid > 0, 'Could not open file.');
cleaner = onCleanup(@() fclose(fid));

%% write data
fprintf(fid, '%s\n', title);
for iframe = 1:nframe
  for i = 1:10:natom3
    fprintf(fid, '%8.3f', trj(iframe, i:min(i+9,natom3)));
    fprintf(fid, '\n');
  end
  if exist('box', 'var') && ~isempty(box)
    fprintf(fid, '%8.3f', box(iframe, :));
    fprintf(fid, '\n');
  end
end


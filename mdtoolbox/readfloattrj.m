function [trj,box] = readfloattrj(natom, filename, index, isbox)
%% readfloattrj
% read float trajectory file
%
% function [trj, box, ititle] = readambertrj(natom, filename, index_atom, isbox)
%
% input: natom ���ҿ�
%        filename �ե�����̾
%        index_atom �ɤ߹��ึ���ֹ�Υꥹ��(��ά�ġ���ά���줿���ˤ������Ҥ��ɤ�)
%        isbox �ܥå����դ���trj�ե����뤫�ݤ����֡��ꥢ��(false or true)��(��ά�ġ���ά���줿���ϥܥå����ʤ�=false)
%
% output: trj (nframe x natom*3) �ȥ饸�����ȥ� each row containing coordinates in the order [x1 y1 z1 x2 y2 z2 ...]
%         box (nframe x 3) box
% 
% example:
% �ܥå���̵���ξ��
% natom = 3343;
% trj = readfloattrj(natom,'md.trj');
% �ܥå���ͭ��ξ��
% natom = 62475;
% [trj,box] = readfloattrj(natom,'md_with_box.trj',1:natom,true);
% 

natom3 = natom*3;

if ~exist('index', 'var') || isempty(index)
  index = 1:natom;
end

if ~exist('index', 'var')
  isbox = false;
end

if isbox
  nlimit = natom3 + 3;
else
  nlimit = natom3;
end

index3 = to3(index);

fid = fopen(filename, 'r');
trj = fread(fid, '*float');
fclose(fid);

nframe = length(trj) / nlimit;
trj = reshape(trj,nlimit,nframe)';

if isbox
  box = trj(:, end-2:end);
  trj(:, end-2:end) = [];
end

trj = trj(:, index3);


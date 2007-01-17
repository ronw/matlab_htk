function write_htk_slf(filename, fsm)
% write_htk_slf(filename, fsm)
%

% start state
labels{1} = '!NULL';
[labels{2:fsm.nstates+1}] = deal(fsm.labels{:});
% end state
labels{end+1} = '!NULL';

% create monolithic transition matrix from fsm
transmat = zeros(fsm.nstates+2);
transmat(1,2:end-1) = exp(fsm.start_prob);
transmat(2:end-1,2:end-1) = exp(fsm.transmat);
transmat(2:end-1,end) = exp(fsm.end_prob);

narcs = numel(find(transmat ~= 0));

fid = fopen(filename, 'w');
fprintf(fid, 'VERSION=1.0\n');
fprintf(fid, 'N=%d L=%d\n', fsm.nstates, narcs);

for n = 1:fsm.nstates+2
  fprintf(fid, 'I=%d W=%s\n', n-1, labels{n});
end


arcs_idx = find(transmat ~= 0);
narcs = length(arcs_idx);
for n = 1:narcs
  [s,e] = ind2sub(size(transmat), arcs_idx(n));
  fprintf(fid, 'J=%d, S=%d, E=%d\n', n, s, e);
end

fclose(fid);

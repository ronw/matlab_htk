function write_htk_bnf(filename, fsm)
% write_htk_bnf(filename, fsm)
%
% Write an FSM as an HTK grammar in BNF format.s
%
% 2007-01-12 ronw@ee.columbia.edu

labels = strvcat(deal(fsm.labels{:}));
nstates = fsm.nstates;

fid = fopen(filename, 'w');
fprintf(fid, '$state%d = %s;\n', [1:nstates], labels);  

fprintf(fid, '\n\n(\n');
% start state
idx = find(exp(fsm.start_prob) ~= 0);
fprintf(fid, '[ state%d', idx(1));
fprintf(fid, ' | state%d', idx(2:end));
fprintf(fid, '] ');

% state transitions
for s = 1:nstates
  idx = find(exp(fsm.transmat(s,:)) ~= 0);
  fprintf(fid, '[ state%d', idx(1));
  fprintf(fid, ' | state%d', idx(2:end));
  fprintf(fid, '] ');
end

% end state
idx = find(exp(fsm.end_prob) ~= 0);
fprintf(fid, '[ state%d', idx(1));
fprintf(fid, ' | state%d', idx(2:end));
fprintf(fid, '] ');

fprintf(fid, ')\n');

fclose(fid);

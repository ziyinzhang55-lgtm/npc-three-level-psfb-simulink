function test_npc_pon_modulation()
% Regression test for the NPC leg state machine used by the final model.

n = 200000;
p = (0:n-1)'/n;
zeroDwell = 0.025;
deadNorm = 120e-9*150e3;
phaseShift = 0.18;

gA = zeros(n,4);
gB = zeros(n,4);
stateA = zeros(n,1);
stateB = zeros(n,1);

for k = 1:n
    [gA(k,:),stateA(k)] = npc_pon_gate(p(k),zeroDwell,deadNorm);
    pb = p(k)-phaseShift;
    if pb < 0, pb = pb+1; end
    [gB(k,:),stateB(k)] = npc_pon_gate(pb,zeroDwell,deadNorm);
end

allowed = [1 1 0 0; 0 1 1 0; 0 0 1 1; 0 1 0 0; 0 0 1 0];
assert(all(ismember(gA,allowed,'rows')), 'Leg A emitted an illegal gate state.');
assert(all(ismember(gB,allowed,'rows')), 'Leg B emitted an illegal gate state.');

assert(all(ismember(stateA,[-1 0 1])), 'Leg A emitted an illegal voltage state.');
assert(all(ismember(stateB,[-1 0 1])), 'Leg B emitted an illegal voltage state.');
assert(abs(mean(stateA)) < 2e-4, 'Leg A has non-zero period-average voltage.');
assert(abs(mean(stateB)) < 2e-4, 'Leg B has non-zero period-average voltage.');

uabNorm = 0.5*(stateA-stateB);
assert(abs(mean(uabNorm)) < 2e-4, 'Bridge output has non-zero DC voltage.');
assert(max(abs(uabNorm)) <= 1, 'Bridge output exceeds the DC-link voltage.');
assert(mean(abs(uabNorm)) > 0.1, 'Selected phase shift transfers no useful power.');

fprintf('PASS: NPC P-O-N state machine; Deq=%.6f, mean(uAB/Vin)=%.3g\n', ...
    mean(abs(uabNorm)),mean(uabNorm));
end

function [g,state] = npc_pon_gate(phase,zeroDwell,deadNorm)
% Return the four NPC gate commands and normalized pole-voltage state.

p = phase-floor(phase);
z = zeroDwell;
td = deadNorm;

if p < z
    g = [0 1 1 0];
    state = 0;
elseif p < z+td
    g = [0 1 0 0];
    state = 0;
elseif p < 0.5-z
    g = [1 1 0 0];
    state = 1;
elseif p < 0.5-z+td
    g = [0 1 0 0];
    state = 0;
elseif p < 0.5+z
    g = [0 1 1 0];
    state = 0;
elseif p < 0.5+z+td
    g = [0 0 1 0];
    state = 0;
elseif p < 1-z
    g = [0 0 1 1];
    state = -1;
elseif p < 1-z+td
    g = [0 0 1 0];
    state = 0;
else
    g = [0 1 1 0];
    state = 0;
end
end

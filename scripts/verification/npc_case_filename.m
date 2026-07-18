function file = npc_case_filename(resultDir,vin,stopTime)
file = fullfile(resultDir,sprintf('case_%04dV_%gms.mat',vin,stopTime*1e3));
end

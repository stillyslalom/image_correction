function void = keyrobot(keylist,delay_val)
%% keyrobot(keylist, delay_val)
% Simulates pressing and releasing keys in cell array 'keylist'.
% Pauses for 'delay_val' between each press/release cycle.\

robot = java.awt.Robot;

for i = 1:length(keylist)
    s = keylist{i};
    cmd_str = eval(['java.awt.event.KeyEvent.VK_' upper(s)]);
    robot.keyPress(cmd_str)
    robot.keyRelease(cmd_str)
    pause(delay_val)
end

void = 0;
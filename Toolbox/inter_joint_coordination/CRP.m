function [CRP_data] = CRP(distal_angle,proximal_angle)

% [CRP_data] = CRP(distal_angle,proximal_angle) determines the CRP on a 0-180 scale, correcting for
% discontinuity in the signals >180. 

% Created by Patrick Ippersiel March 2020

temp_CRP=abs(distal_angle-proximal_angle);
idx= temp_CRP > 180; % This corrects discontinuity in the data and puts everything on a 0-180 scale.
temp_CRP(idx) = 360 - temp_CRP(idx);
CRP_data = temp_CRP;
  


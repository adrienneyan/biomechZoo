function data = makebones(data,type,foot_flat,test)

% DATA = MAKEBONES(data) creates segment 'bones' for use in vicon2groodsuntay or for
% visualization in director. Bones are virtual markers representing segment
% axes. This function is deprecated, use makebones_data instead
%
% ARGUMENTS
%
% data             ... trial data
% test             ... test against existing PiG 'bones'
%
% NOTES
% - makebones is deprecated and will be removed in a future version, 
%   use makebones_data instead

% See also makebones_data

warning('makebones is deprecated and will be removed in a future version, use makebones_data instead')


% Set defaults ---------------------------------------------------------------------------
%
if nargin==1
    type = 'dynamic';
    test = 0;
    foot_flat = false;
end

if nargin==2
    test = 0;
    foot_flat = false;
end

if nargin==3
    test = 0;
end

% Extract PiG markers --------------------------------------------------------------------
%
if isfield(data,'RPSI')                                     % in cases where SACR
    RPSI = data.RPSI.line;                                  % marker was not used
    LPSI = data.LPSI.line;                                  % it can be computed
    SACR = (RPSI+LPSI)/2;                                   % from RPSI and LPSI
    data = addchannel_data(data,'SACR',SACR,'video');
else
    SACR = data.SACR.line;
end

LASI = data.LASI.line;
LKNE = data.LKNE.line;
LTIB = data.LTIB.line;
LANK = data.LANK.line;
LHEE = data.LHEE.line;
LTOE = data.LTOE.line;

RASI = data.RASI.line;
RKNE = data.RKNE.line;
RTIB = data.RTIB.line;
RANK = data.RANK.line;
RHEE = data.RHEE.line;
RTOE = data.RTOE.line;



% Extract required anthropometrics -------------------------------------------------------
%
% - these should be measured during data collection and appended to file
%   before running this program
%
% mrkDiam = getanthro(data,'MarkerDiameter');
% rLegL   = getanthro(data,'RLegLength');
% lLegL   = getanthro(data,'LLegLength');
% rKneeW  = getanthro(data,'RKneeWidth');
% lKneeW  = getanthro(data,'LKneeWidth');
% rAnkleW = getanthro(data,'RAnkleWidth');
% lAnkleW = getanthro(data,'LAnkleWidth');



% Extract Hip, Knee, and Ankle joint centres --------------------------------------------
%
% - Hip joint centres are computed from dynamic trial in case marker position changed
%   since static pose
% - Hip joint centre computation based on Davis et al. 1991
% - Knee and Ankle joint center computation based on pyCGM.py's
%   interpretatin of PiG 'chord function'
%
RHipJC = data.RHipJC.line;
RKneeJC = data.RKneeJC.line;
RAnkleJC = data.RAnkleJC.line;

LHipJC = data.LHipJC.line;
LKneeJC = data.LKneeJC.line;
LAnkleJC = data.LAnkleJC.line;


% for testing
% RKneeJC = data.RFEO.line;
% RAnkleJC = data.RTIO.line;
% LKneeJC = data.LFEO.line;
% LAnkleJC = data.LTIO.line;

% exact values for first frame from pyCGM for testing ('C1605A01.zoo')
% if strcmpi(type,'static')
%     RHipJC(1,:) = [162.24567427,  273.65162221,  868.71575397];
%     RKneeJC(1,:) = [  165.76850331,  279.32187514,  491.06883585];
%     RAnkleJC(1,:) = [  159.72078594,  326.35772713,   71.54075074];
% end

% if strcmpi(type,'dynamic')
%     RHipJC(1,:) = [372.02633188,  1569.81507501,   883.98244222];
%     RKneeJC(1,:) = [  165.76850331,  279.32187514,  491.06883585];
%     RAnkleJC(1,:) = [  159.72078594,  326.35772713,   71.54075074];
% end




% Pelvis coordinate system ---------------------------------------------------------------
%
% - The formaula proposed by Davis et al. 1991 to compute PELO as RASI+LASI)/2 is NOT used
% by Vicon. Instead it appears the average HJC position is used. This is not stated
% in any of the literature, but this approach improves agreement (see comparePiG)
%
segment = 'Pelvis';
boneLength = magnitude(LHipJC-RHipJC);
O = (RASI+LASI)/2;
L = makeunit(LASI-RASI);                                             % lateral (L)
temp = makeunit(LASI - SACR);                                        % temp anterior
P = makeunit(cross(temp,L));                                         % proximal (P)
A = makeunit(cross(L,P));                                            % anterior (A)

O(:,1) = mean([LHipJC(:,1) RHipJC(:,1)],2);                          % adjust PELO
O(:,2) = mean([LHipJC(:,2) RHipJC(:,2)],2);
O(:,3) = mean([LHipJC(:,3) RHipJC(:,3)],2);

[PELO,PELA,PELL,PELP] = getGlobalCoord(data,O,A,L,P,segment,boneLength,test);

data = addchannel_data(data,'PELO',PELO,'video');
data = addchannel_data(data,'PELA',PELA,'video');
data = addchannel_data(data,'PELL',PELL,'video');
data = addchannel_data(data,'PELP',PELP,'video');


% Compute Left Femur bones (GOOD) -------------------------------------------------------------
%
segment= 'Left Femur';
boneLength = magnitude(LHipJC-LKneeJC);

O = LKneeJC;
P = LHipJC-O;                            % proximal vector
Ltemp = LKNE - O;                        % temp lateral vector
A = cross(Ltemp,P);                      % anterior vector
L = cross(P,A);                          % lateral vector

[LFEO,LFEA,LFEL,LFEP] = getGlobalCoord(data,O,A,L,P,segment,boneLength,test);

data = addchannel_data(data,'LFEO',LFEO,'video');
data = addchannel_data(data,'LFEA',LFEA,'video');
data = addchannel_data(data,'LFEL',LFEL,'video');
data = addchannel_data(data,'LFEP',LFEP,'video');


% Compute Right Femur bones (GOOD) -----------------------------------------------------------
%
segment= 'Right Femur';
boneLength = magnitude(RHipJC-RKneeJC);

O = RKneeJC;
P = RHipJC-O;                            % proximal vector
Ltemp = -(RKNE - O);                        % temp lateral vector
A = cross(Ltemp,P);                      % anterior vector
L = cross(P,A);                          % lateral vector

[RFEO,RFEA,RFEL,RFEP] = getGlobalCoord(data,O,A,L,P,segment,boneLength,test);

data = addchannel_data(data,'RFEO',RFEO,'video');
data = addchannel_data(data,'RFEA',RFEA,'video');
data = addchannel_data(data,'RFEL',RFEL,'video');
data = addchannel_data(data,'RFEP',RFEP,'video');


% Compute Left Tibia bone (GOOD) --------------------------------------------------------
%
segment = 'Left Tibia';
boneLength = magnitude(LKneeJC-LAnkleJC);

O = LAnkleJC;
P = LKneeJC-O;                                         % proximal vector     (pyCGM: axis_z)
Ltemp = LTIB-LANK;                                     % temp lateral vector (pyCGM: tib_ank_L)
A = cross(Ltemp,P);                                    % anterior vector     (pyCGM: axis_x)
L = cross(P,A);                                        % lateral vector      (pyCGM: axis_y)

% [A,L,P] = tibiaTorsion(A,L,P,lTorsion); % same as pyCGM.py @ ln 615 (ankle axes)

[LTIO,LTIA,LTIL,LTIP] = getGlobalCoord(data,O,A,L,P,segment,boneLength,test);

data = addchannel_data(data,'LTIO',LTIO,'video');
data = addchannel_data(data,'LTIA',LTIA,'video');
data = addchannel_data(data,'LTIL',LTIL,'video');
data = addchannel_data(data,'LTIP',LTIP,'video');


% Compute Right Tibia bone (no torsion) --------------------------------------------------
%
segment = 'Right Tibia';
boneLength = magnitude(RKneeJC-RAnkleJC);

O = RAnkleJC;
P = RKneeJC-O;                             %  proximal vector
Ltemp = -(RTIB-RANK);                         % temp lateral vector
A = cross(Ltemp,P);                        % anterior vector
L = cross(P,A);                            % lateral vector

%[A,L,P] = tibiaTorsion(A,L,P,rTorsion); % same as pyCGM.py @ ln 615 (ankle axes)
[RTIO,RTIA,RTIL,RTIP] = getGlobalCoord(data,O,A,L,P,segment,boneLength,test);


data = addchannel_data(data,'RTIO',RTIO,'video');
data = addchannel_data(data,'RTIA',RTIA,'video');
data = addchannel_data(data,'RTIL',RTIL,'video');
data = addchannel_data(data,'RTIP',RTIP,'video');



% Compute Left Foot 'bone'(GOOD)---------------------------------------------------------
%
% Length of foot calculated here is longer than Vicon PiG version
% LfootLength = magnitude(data.LFOP.line-data.LFOO.line)

segment ='Left Foot';
boneLength =magnitude(LHEE-LTOE);                       % length of bone*

O = LTOE;
P = LAnkleJC-O;                             % proximal vector (pyCGM: L_axis_z)
Ltemp = LTIL-LAnkleJC;
A = cross(Ltemp,P);
L = cross(P,A);

if strcmpi(type,'dynamic')
    LStaticPlantFlex = data.zoosystem.Anthro.LStaticPlantFlex;
    LStaticRotOff    = data.zoosystem.Anthro.LStaticRotOff;
    [A,L,P] = rotateFootAxes(A,L,P,LStaticRotOff,LStaticPlantFlex);
end

[LFOO,LFOA,LFOL,LFOP] = getGlobalCoord(data,O,A,L,P,segment,boneLength,test);

data = addchannel_data(data,'LFOO',LFOO,'video');
data = addchannel_data(data,'LFOA',LFOA,'video');
data = addchannel_data(data,'LFOL',LFOL,'video');
data = addchannel_data(data,'LFOP',LFOP,'video');


if strcmpi(type,'static')
    
    % LF1_RAxis
    O = LTOE;
    P1 = makeunit(LAnkleJC-O);
    Ltemp = LTIL-LAnkleJC;
    A1 = makeunit(cross(Ltemp,P1));
    L1 = makeunit(cross(P1,A1));
    
    A1 = A1+O;
    L1 = L1+O;
    P1 = P1+O;
    
    data = addchannel_data(data,'LF1O',O,'video');
    data = addchannel_data(data,'LF1A',A1,'video');
    data = addchannel_data(data,'LF1L',L1,'video');
    data = addchannel_data(data,'LF1P',P1,'video');
    
    if foot_flat == false
        % LF2_RAxis
        O = LTOE;
        P2 = makeunit(LHEE-O);
        Ltemp = makeunit(LTIL-LAnkleJC);
        A2 = makeunit(cross(Ltemp,P2));                         %
        L2 = makeunit(cross(P2,A2));
        
        A2 = A2+O;
        L2 = L2+O;
        P2 = P2+O;
        
        data = addchannel_data(data,'LF2O',O,'video');
        data = addchannel_data(data,'LF2A',A2,'video');
        data = addchannel_data(data,'LF2L',L2,'video');
        data = addchannel_data(data,'LF2P',P2,'video');
    else
        % LF3_RAxis
        O = LTOE;
        P3 = makeunit(LAnkleJC-O);                             
        hee2_toe = makeunit(LHEE-O);
        hee2_toe(:,3) = 0;
        A = makeunit(cross(hee2_toe,P3));                         
        B = makeunit(cross(A,hee2_toe));
        C = cross(B,A);
        P3 = makeunit(C);                    % L_axis_z
        
        Ltemp = makeunit(LTIL-LAnkleJC);     %y_flex_L
        A3 = makeunit(cross(Ltemp,P3));      % L_axis_x
        L3 = makeunit(cross(P3,A3));
        P3 = cross(A3,L3);
        
        A3 = A3+O;
        L3 = L3+O;
        P3 = P3+O;
        
        data = addchannel_data(data,'LF3O',O,'video');
        data = addchannel_data(data,'LF3A',A3,'video');
        data = addchannel_data(data,'LF3L',L3,'video');
        data = addchannel_data(data,'LF3P',P3,'video');
    end
    
    
end





% Compute Right Foot 'bone'-----------------------------------------------------------------
%
% Length of foot calculated here is longer than Vicon PiG version
% LfootLength = magnitude(data.LFOP.line-data.LFOO.line)
%
segment ='Right Foot';
boneLength =magnitude(RHEE-RTOE);                       % length of bone*

O = RTOE;
P = RAnkleJC-O;                             % proximal vector
Ltemp = RTIL-RAnkleJC;                      % temp lateral vector
A = cross(Ltemp,P);                         % anterior vector
L = cross(P,A);

if strcmpi(type,'dynamic')
    RStaticPlantFlex = data.zoosystem.Anthro.RStaticPlantFlex;
    RStaticRotOff    = data.zoosystem.Anthro.RStaticRotOff;
    [A,L,P] = rotateFootAxes(A,L,P,RStaticRotOff,RStaticPlantFlex);
end



[RFOO,RFOA,RFOL,RFOP] = getGlobalCoord(data,O,A,L,P,segment,boneLength,test);

data = addchannel_data(data,'RFOO',RFOO,'video');
data = addchannel_data(data,'RFOA',RFOA,'video');
data = addchannel_data(data,'RFOL',RFOL,'video');
data = addchannel_data(data,'RFOP',RFOP,'video');


if strcmpi(type,'static')
    
    % RF1_RAxis
    O = RTOE;
    P1 = makeunit(RAnkleJC-O);
    Ltemp = RTIL-RAnkleJC;
    A1 = makeunit(cross(Ltemp,P1));
    L1 = makeunit(cross(P1,A1));
    
    A1 = A1+O;
    L1 = L1+O;
    P1 = P1+O;
    
    data = addchannel_data(data,'RF1O',O,'video');
    data = addchannel_data(data,'RF1A',A1,'video');
    data = addchannel_data(data,'RF1L',L1,'video');
    data = addchannel_data(data,'RF1P',P1,'video');
    
    if foot_flat == false
    % RF2_RAxis
    O = RTOE;
    P2 = makeunit(RHEE-O);
    Ltemp = makeunit(RTIL-RAnkleJC);
    A2 = makeunit(cross(Ltemp,P2));                         %
    L2 = makeunit(cross(P2,A2));
    
    A2 = A2+O;
    L2 = L2+O;
    P2 = P2+O;
    
    data = addchannel_data(data,'RF2O',O,'video');
    data = addchannel_data(data,'RF2A',A2,'video');
    data = addchannel_data(data,'RF2L',L2,'video');
    data = addchannel_data(data,'RF2P',P2,'video');
    else
        % RF3_RAxis
        O = RTOE;
        P3 = makeunit(RAnkleJC-O);                             
        hee2_toe = makeunit(RHEE-O);
        hee2_toe(:,3) = 0;
        A = makeunit(cross(hee2_toe,P3));                         
        B = makeunit(cross(A,hee2_toe));
        C = cross(B,A);
        P3 = makeunit(C);                    % L_axis_z
        
        Rtemp = makeunit(RTIL-RAnkleJC);     %y_flex_L
        A3 = makeunit(cross(Rtemp,P3));      % L_axis_x
        L3 = makeunit(cross(P3,A3));
        P3 = cross(A3,L3);
        
        A3 = A3+O;
        L3 = L3+O;
        P3 = P3+O;
        
        data = addchannel_data(data,'RF3O',O,'video');
        data = addchannel_data(data,'RF3A',A3,'video');
        data = addchannel_data(data,'RF3L',L3,'video');
        data = addchannel_data(data,'RF3P',P3,'video');
    end
    
    
    
end









function [Arot,Lrot,Prot] = rotateFootAxes(A,L,P,StaticRotOff,StaticPlantFlex)

P = makeunit(P);                            % L_axis_z same as pyCGM ln 802
A = makeunit(A);                            % L_axis_x
L = makeunit(L);                            % L_axis_y

% Apply static offset angle to the incorrect foot axes
alpha = StaticRotOff; %0.028639917144370208;
beta = StaticPlantFlex; %0.2466761911406323;



Prot = zeros(size(P));
Arot = zeros(size(A));
Lrot = zeros(size(L));


for i = 1:length(A)
    
    axis = [A(i,:); L(i,:); P(i,:)];
    
    % rotate about y-axis
    roty = [cos(beta)*axis(1,1)+sin(beta)*axis(3,1),...
        cos(beta)*axis(1,2)+sin(beta)*axis(3,2),...
        cos(beta)*axis(1,3)+sin(beta)*axis(3,3);...
        axis(2,1),axis(2,2),axis(2,3);...
        -1*sin(beta)*axis(1,1)+cos(beta)*axis(3,1),...
        -1*sin(beta)*axis(1,2)+cos(beta)*axis(3,2),...
        -1*sin(beta)*axis(1,3)+cos(beta)*axis(3,3)];
    
    % rotate aboux x-axis
    rotyx = [roty(1,1),roty(1,2),roty(1,3);...
        cos(alpha)*roty(2,1)-sin(alpha)*roty(3,1),...
        cos(alpha)*roty(2,2)-sin(alpha)*roty(3,2),...
        cos(alpha)*roty(2,3)-sin(alpha)*roty(3,3);...
        sin(alpha)*roty(2,1)+cos(alpha)*roty(3,1),...
        sin(alpha)*roty(2,2)+cos(alpha)*roty(3,2),...
        sin(alpha)*roty(2,3)+cos(alpha)*roty(3,3)];
    
    
    Arot(i,:) = rotyx(1,:);
    Lrot(i,:) = rotyx(2,:);
    Prot(i,:) = rotyx(3,:);
    
    
end

function [At,Lt,Pt] = tibiaTorsion(A,L,P,torsion)

torsion = deg2rad(torsion);

At = zeros(size(A));
Lt = zeros(size(L));
Pt = zeros(size(P));

for i = 1:length(At)
    
    axis = [A(i,:); L(i,:); P(i,:)];
    
    axisRot = [cos(torsion)*axis(1,1)-sin(torsion)*axis(2,1),...
        cos(torsion)*axis(1,2)-sin(torsion)*axis(2,2),...
        cos(torsion)*axis(1,3)-sin(torsion)*axis(2,3);...
        sin(torsion)*axis(1,1)+cos(torsion)*axis(2,1),...
        sin(torsion)*axis(1,2)+cos(torsion)*axis(2,2),...
        sin(torsion)*axis(1,3)+cos(torsion)*axis(2,3);
        axis(3,1),axis(3,2),axis(3,3)];
    
    At(i,:) = axisRot(1,:);
    Lt(i,:) = axisRot(2,:);
    Pt(i,:) = axisRot(3,:);
    
    
end


function [O,A,L,P] = getGlobalCoord(data,O,A,L,P,segment,boneLength,test)

% make unit vectors
%
P = makeunit(P);
A = makeunit(A);
L = makeunit(L);


% Scale to length of bone
%
for i = 1:3
    A(:,i) = A(:,i).*boneLength;
    L(:,i) = L(:,i).*boneLength;
    P(:,i) = P(:,i).*boneLength;
end

% Move to global coordinate system
%
A = A + O;
L = L + O;
P = P + O;

% Check results
if test ==1
    comparePiG(data,segment,O,A,L,P)
    comparePiGangles(data,segment,O,A,L,P)
end




function [O,A,L,P] = getLocalCoord(data,orig,proxJC,latMkr,disMkr,boneLength,segment,test)

% This function computes local coordinate system for all segments except pelvis


% Create coordinate system
%
O = orig;
P = proxJC-O;                             % unit proximal vector
Ltemp = latMkr-disMkr;                    % temp lateral vector
A = cross(Ltemp,P);                       % unit anterior vector
L = cross(P,A);                           % unit lateral vector

% make unit vectors
%
P = makeunit(P);
A = makeunit(A);
L = makeunit(L);


% Scale to length of bone
%
for i = 1:3
    A(:,i) = A(:,i).*boneLength;
    L(:,i) = L(:,i).*boneLength;
    P(:,i) = P(:,i).*boneLength;
end

% Move to global coordinate system
%
A = A + O;
L = L + O;
P = P + O;

% Check results
if test ==1
    comparePiG(data,segment,O,A,L,P)
    comparePiGangles(data,segment,O,A,L,P)
end



function comparePiGangles(data,segment,mO,mA,mL,mP)

switch segment
    
    case 'Pelvis'
        seg = 'PEL';
        
    case 'Left Femur'
        seg = 'LFE';
        
    case 'Left Tibia'
        seg = 'LTI';
        
    case 'Left Foot';
        seg = 'LFO';
        
    case 'Right Femur'
        seg = 'RFE';
        
    case 'Right Tibia'
        seg = 'RTI';
        
    case 'Right Foot';
        seg = 'RFO';
end


O = data.([seg,'O']).line;
A = data.([seg,'A']).line;
L = data.([seg,'L']).line;
P = data.([seg,'P']).line;


mp = makeunit(mP-mO);
ma = makeunit(mA-mO);
ml = makeunit(mL-mO);

disp('angles between my vectors:')
disp(['P vs A: ',num2str(nanmean(angle(mp,ma)))])
disp(['P vs L: ',num2str(nanmean(angle(mp,ml)))])
disp(['A vs L: ',num2str(nanmean(angle(ma,ml)))])
disp(' ')
p = makeunit(P-O);
a = makeunit(A-O);
l = makeunit(L-O);

disp('angles between PiG vectors:')
disp(['P vs A: ',num2str(nanmean(angle(p,a)))])
disp(['P vs L: ',num2str(nanmean(angle(p,l)))])
disp(['A vs L: ',num2str(nanmean(angle(a,l)))])
disp(' ')

disp('angles between PiG and my vectors:')
disp(['P vs p: ',num2str(nanmean(angle(p,mp)))])
disp(['L vs l: ',num2str(nanmean(angle(l,ml)))])
disp(['A vs a: ',num2str(nanmean(angle(a,ma)))])



function [Qsim, param, varargout] = HydroMod14( P, E, param )
%
% [Qsim, param, varargout] = HydroMod14( P, E, param )
%
% SACRAMENTO hydrological model (modified version)
%
% INPUTS
% P 	= mean areal rainfall (mm)
% E 	= mean areal evapotranspiration (mm)
% param = the nine model parameters (see "param" below) - [9,1]
%
% OUTPUTS
% Qsim  = simulated stream flow (mm)
% inter   = HydroMod14's internal values (varargout 1)
% interq  = HydroMod14's internal flow components (varargout 2)
% param -->
% 	.x(1) = Rounting reservoir capacity
% 	.x(2) = Ground reservoir capacity
% 	.x(3) = Emptying constant of the ground reservoir
% 	.x(4) = Percolation coefficient
% 	.x(5) = Infiltration constant
% 	.x(6) = Emptying constant of the hypodermic flow
% 	.x(7) = Partitioning coefficient
% 	.x(8) = Deep percolation coefficient
% 	.x(9) = Delay
%
% 	.S = Interception reservoir state (mm)
% 	.T = Emptying reservoir state (mm)
% 	.R = Ground reservoir state (mm)
% 	.L = Ground routing reservoir state (mm)
% 	.M = Direct routing reservoir (mm)
%
% FOLLOWING
%  - Burnash, R.J.C., Ferral, R.L., McGuire, R.A., 1973. A generalized 
%    streamflow simulation system � Conceptual modelling for digital 
%    computers. (US National Weather Service, Sacramento, California.)
%  - Perrin, C. (2000). Vers une am�lioration d'un mod�le global pluie-d�bit, 
%    PhD Thesis, Appendix 1, p. 366-371. Retrieved from 
%    https://tel.archives-ouvertes.fr/tel-00006216
%
% Programmed by G. Seiller, Univ. Laval (05-2013)
% Slightly modified by A. Thiboult (2016)

%% Modeling
% Get parameters
%
x = param.x ;
S = param.S ;
T = param.T ;
R = param.R ;
L = param.L ;
M = param.M ;
XF1 = param.XF1;
XF2 = param.XF2;
DL = param.DL ;
HY = param.HY ;

% Surface storage (S)
%
S = S+P;
Es = min(E,S);
S = S-Es;
Er = E-Es;
Is = max(0,S-XF1);
S = S-Is;

% Soil storage (T)
%
T = T+Is;
It = max(0,min(T,x(5)*(1-(R/x(2)))*(T/x(4))));
T = T-It;
Qt1 = T/x(6);
T = T-Qt1;
Et = min(Er*min(1,T/x(4)),T);
T = T-Et;
Ez = Er-Et;
Qt0 = max(0,T-x(4));
T = T-Qt0;

% Groundwater storages (L & R)
%
L = L+x(7)*It;
Il = max(0,L-XF2);
L = L-Il;
R = R+(1-x(7))*It+Il;
El = (Ez)/(XF1+XF2);
L = L-El;
if L < 0
    Ir = min(-L,max(0,R-(x(2)-XF2)));
    L = max(0,L+Ir);
    R = R-Ir;
end
Qr = R/x(3);
R = R-Qr;
Qr = Qr/x(8);

% Direct routing storage (M)
%
M = M+Qt0;
Qm = M/x(1);
M = M-Qm;

% Total discharge
%
HY = [HY(2:end); 0] + DL * (Qr+Qm+Qt1) ;
Qsim = max( [0; HY(1)] ) ;

param.S = S;
param.T = T;
param.R = R;
param.L = L;
param.M = M;
param.HY = HY ;

if nargout>2
    inter = [ S T R L M Is It Qt0 Qt1 Qr Qm ];
    
    % Flow components
    qsf = 0 ;
    qs1 = Qt1 ; qs2 = 0 ; qs = qs1+qs2 ;
    qrs1 = Qm ; qrs2 = 0 ; qrs = qrs1+qrs2 ;
    qss1 = 0 ; qss2 = 0 ; qss = qss1+qss2 ;
    qrss1 = 0 ; qrss2 = 0 ; qrss = qrss1+qrss2 ;
    qn = Qr ;
    qr = 0 ;
    
    interq = [ qsf qs1 qs2 qs qrs1 qrs2 qrs qss1 qss2 qss qrss1 qrss2 qrss qn qr ];
    
    % Outputs
    varargout{1}=inter;
    varargout{2}=interq;
end
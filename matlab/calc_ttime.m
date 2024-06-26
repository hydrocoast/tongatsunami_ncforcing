clear
close all

% ---------------------
% h0 = 2846;
% h1 = 5258;
% w = 17.2e3;
% ---------------------
% h0 = 2790;
% h1 = 5744;
% w = 30.4e3;
% ---------------------
% h0 = 1492;
% h1 = 5068;
% w = 38.0e3;
% ---------------------
h0 = 1991;
h1 = 4219;
w = 17.8e3;
% ---------------------



theta_deg = 0:1:86;

g = 9.8;


traveltime = 2*w./cosd(theta_deg).*(sqrt(g*h1)-sqrt(g*h0))/(g*(h1-h0));


plot(theta_deg,traveltime./60);
xlim([45,85]);
grid on
box on
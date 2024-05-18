clear
close all

matnameA1 = 'waveform_regionA_fg02.mat';
matnameB1 = 'waveform_regionB_fg02.mat';
matnameC1 = 'waveform_regionC_fg02.mat';
DA1 = load(matnameA1);
DB1 = load(matnameB1);
DC1 = load(matnameC1);

matnameA2 = 'waveform_regionA_fg03.mat';
matnameB2 = 'waveform_regionB_fg03.mat';
matnameC2 = 'waveform_regionC_fg03.mat';
DA2 = load(matnameA2);
DB2 = load(matnameB2);
DC2 = load(matnameC2);


fig = figure;
hold on
plot(1*ones(3,1),DA2.etamax_pick(2:4)./DA1.etamax_pick(4),'o');
plot(2*ones(3,1),DB2.etamax_pick(2:4)./DB1.etamax_pick(4),'o');
plot(3*ones(3,1),DC2.etamax_pick(2:4)./DC1.etamax_pick(4),'o');
grid on
box on

xlim([0.8,3.2]);
% ylim([0,2]);

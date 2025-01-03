clear all
close all
clc

Fs = 360; % Sampling Frequency

%% Visualization of ECG Signal
load('100m.mat');
ecgsig = val(2, :);
t = 0:length(ecgsig)-1;
tx = t./Fs;
subplot(4, 1, 1), plot(tx, ecgsig), title('ECG Signal with artifacts'), grid on

%% Removal of Baseline Wander using Biorthogonal Wavelet
[C, L] = wavedec(ecgsig, 9, 'bior3.7'); % Decomposition
a9 = wrcoef('a', C, L, 'bior3.7', 9); % Approximate Component
d1 = wrcoef('d', C, L, 'bior3.7', 1); % Detailed components
d2 = wrcoef('d', C, L, 'bior3.7', 2);
d3 = wrcoef('d', C, L, 'bior3.7', 3);
d4 = wrcoef('d', C, L, 'bior3.7', 4);
d5 = wrcoef('d', C, L, 'bior3.7', 5);
d6 = wrcoef('d', C, L, 'bior3.7', 6);
d7 = wrcoef('d', C, L, 'bior3.7', 7);
d8 = wrcoef('d', C, L, 'bior3.7', 8);
d9 = wrcoef('d', C, L, 'bior3.7', 9);
subplot(4, 1, 2), plot(tx, a9 + d8 + d7 + d6), title('ECG Signal after baseline wander removed'), grid on

%% Removal of Powerline Interference using Notch Filter
Fnotch = 50; % Notch Frequency
BW = 100; % Bandwidth
Apass = 1; % Bandwidth Attenuation
[b, a] = iirnotch(Fnotch/(Fs/2), BW/(Fs/2), Apass);
Hd = dfilt.df2(b, a);
y1 = filter(Hd, ecgsig);
subplot(4, 1, 3), plot(tx, y1), title('ECG signal with powerline interference removed'), grid on

%% Removal of EMG Noise using Biorthogonal Wavelet
[C, L] = wavedec(y1, 4, 'bior3.7'); % Decomposition
a4 = wrcoef('a', C, L, 'bior3.7', 4); % Approximate Component
d1 = wrcoef('d', C, L, 'bior3.7', 1); % Detailed components
d2 = wrcoef('d', C, L, 'bior3.7', 2);
d3 = wrcoef('d', C, L, 'bior3.7', 3);
d4 = wrcoef('d', C, L, 'bior3.7', 4);
y3 = a4 + d4;
subplot(4, 1, 4), plot(tx, y3), title('ECG Signal with high frequency noise removed'), grid on

%% Denoising of ECG Signal using Daubechies Wavelet
[C, L] = wavedec(y2, 4, 'db4'); % Decomposition
a4 = wrcoef('a', C, L, 'db4', 4); % Approximate Component
d1 = wrcoef('d', C, L, 'db4', 1); % Detailed components
d2 = wrcoef('d', C, L, 'db4', 2);
d3 = wrcoef('d', C, L, 'db4', 3);
d4 = wrcoef('d', C, L, 'db4', 4);

%% PQRST Detection
[Rpeaks, locs_r] = findpeaks(y3, t, 'MinPeakHeight', 0.4, 'MinPeakDist', 50);
nohb_r = length(locs_r);

for i = 1:nohb_r
    Speaks(i) = min(y3(locs_r(i):locs_r(i)+15));
    locs_s(i) = find(y3 == Speaks(i));
end

for i = 1:nohb_r
    Qpeaks(i) = min(y3(locs_r(i)-15:locs_r(i)));
    locs_q(i) = find(y3 == Qpeaks(i));
end

for i = 1:nohb_r
    if locs_q(i) - 60 > 0
        Ppeaks(i) = max(y3(locs_q(i)-60:locs_q(i)));
        locs_p(i) = find(y3 == Ppeaks(i));
    else
        Ppeaks(i) = max(y3(locs_q(i)-10:locs_q(i)));
        locs_p(i) = find(y3 == Ppeaks(i));
    end
end

for i = 1:nohb_r
    if locs_s(i) + 130 <= 3600
        Tpeaks(i) = max(y3(locs_s(i):locs_s(i)+130));
        locs_t(i) = find(y3 == Tpeaks(i));
    else
        break
    end
end

timelimit = length(ecgsig) / Fs;
hbpermin = (nohb_r * 60) / timelimit;
disp(strcat('Heart Rate = ', num2str(hbpermin)))

figure
plot(t, y3)
grid on
xlim([0, length(ecgsig)])
hold on
plot(locs_r, Rpeaks, 'xr')
plot(locs_s, Speaks, 'om')
plot(locs_q, Qpeaks, 'xg')
plot(locs_p, Ppeaks, 'xm')
plot(locs_t, Tpeaks, 'pk')
xlabel('samples')
legend('ECG Signal', 'Rpeaks', 'Speaks', 'Qpeaks', 'Ppeaks', 'Tpeaks')
title(strcat('PQRST Detection and Heart Rate = ', num2str(hbpermin)))

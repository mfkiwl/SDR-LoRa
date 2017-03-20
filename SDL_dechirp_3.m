close all
clear

% Read file
[in, Fs] = audioread('SDRSharp_20170317_141725Z_868998100Hz_IQ_125k_x2.wav');
% [in, Fs] = audioread('SDRSharp_20170301_172427Z_868712500Hz_IQ_125k.wav');

% Allocate in-phase and quadrature components
x = (in(:,2) + 1i*in(:,1)).';


% Crop signal in time
n = 3.35*Fs:4.42*Fs; % segment 1
% n = 4.90704*Fs:6.234*Fs; % segment 2 % 4.91523
x = x(n);

% Filter the rest of signals
% freqs = [0 0.33 0.35 0.55 0.57 1];
% damps = [0 0 1 1 0 0];
% order = 50;
% b = firpm(order,freqs,damps);
% x = filter(b,1,x);

% Bring signal to baseband
t = 0:1/Fs:length(x)/Fs-1/Fs;
x = x.*cos(2*pi*1.808e6*t);

% Try filtering or
% convolvution in frequency or
% frequency cropping + convolvution in frequency

% LoRa parameters
BW = 125e3;
SF = 12;
% Nfft = 2^SF;
chirp_rate = BW/2^SF;
Fs_prime = 2*BW;

% Decimation
% x = decimate(x, 2);

% Chirp generation
fo = BW; % reverse fo and f1 for an up-chirp
f1 = 0;
symbol_time = 1/chirp_rate; % 32.8e-3
t = 0:1/Fs:symbol_time;
c = chirp(t,fo,symbol_time,f1); % generate a down-chirp segment and concatenate multiple ones
c = [c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c c];
c = c(1:length(x)); % crop to signal length

% Curently there is a mismatch in chirp BW, so the resulting spectrum
% is split in two,  half of it (non-consecutive pieces) is shifted to the right

% De-chirping
de_chirped = x.*conj(c);
% de_chirped = c;

% Plot spectrogram
Nx = length(x);
window_length = 4096; %round(symbol_time*Fs);
Nfft = 4096;
[s, f, t] = spectrogram(de_chirped, blackman(window_length), round(window_length/2), Nfft, Fs);

% Overlapping option 1
s_first = s(1:round(BW/Fs*Nfft),:); %s(1:BW/Fs*Nfft,:);
s_second = s(round(BW/Fs*Nfft)+1:round(BW/Fs*Nfft)*2,:); % s(BW/Fs*Nfft+1:BW/Fs*Nfft*2-1,:);
padding = zeros(Nfft-round(BW/Fs*Nfft),size(s,2));
s_second_padded = [s_second; padding];
s = s + s_second_padded; % add padding

% Overlapping option 2
% s_first = s(1:round(BW/Fs*Nfft),:);
% s_second = s(round(BW/Fs*Nfft)+1:round(BW/Fs*Nfft)*2,:);
% s = s_first + s_second;
% f = f(1:round(BW/Fs*Nfft));

surf(f,t,10*log10(abs(s')),'EdgeColor','none')
axis xy; axis tight; colormap(jet); view(0,90);
ylabel('Time');
xlabel('Frequency (Hz)');

% xlim([0 2*BW])
% ylim([0.001 0.81])
% printfigure('Caputred LoRa signal')

% % Plot spectrum
% X = fft(x, Nfft)/Nfft;
% f = Fs*linspace(0,1,Nfft);
% plot(f,10*log10(abs(X)))

% % Test to crop signal in frequency
% X = X(.5781/(2*pi)*Nfft:.6875/(2*pi)*Nfft);
% x = ifft(X);
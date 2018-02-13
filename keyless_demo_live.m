% keyless_demo_live.m
%
% Demonstration of receiving and decoding bytes from a keyless entry
% remote. Data is transmitted using on-off keying. This file reads from a 
% FIFO continuously and recovers bytes. 
%
% Adam Gannon, adamgannon.com, 2018.

clear variables;
close all
clc


%% Parameters

threshold = 0.2;
pkt_len = 6000;
pulse_len = 22;
window_len = 10;

%buffer_len = 50000;
buffer_len = 80000;

rx_pkts = zeros(35,35);
pkt_counter = 0;

runLive = true;
debugMode = false;


%% Data

if (runLive)
    fi = fopen('/tmp/keyless_mag_fifo','rb');
else
    fi= fopen('/tmp/keyless_mag_data.dat','rb');
end


handFig = figure(1);
set(gcf,'Color', 'white')
set(handFig, 'Position', [0 0 1600 300])
clf
set(gca,'Color','white');
set(gca,'XColor','white');
set(gca,'YColor','white');


good_str = 'Transmission Received';
disp_counter = 0;
tic

%% Energy Detection

in_buff = fread(fi, buffer_len, 'float');
rawBuf = in_buff;

while(1)

s=toc;
if (s>3)
  clf
  set(gca,'Color','white');
  set(gca,'XColor','white');
  set(gca,'YColor','white');
  clear goodHand
  clear dataHand
end

drawnow

%% Packet Detection

% Apply a moving average filter to create a plateau 
nSignalAvg = 100;
signalAvgTaps = ones(nSignalAvg,1)./nSignalAvg;
shortAvg = abs(filter(signalAvgTaps,1,rawBuf));


% Apply a longer moving average filter
nEnergyAvg = 1000;
energyAvgTaps = ones(nEnergyAvg,1)./nEnergyAvg;
longAvg = abs(filter(energyAvgTaps,1,rawBuf));

% Take the difference to show when energy rises sharply
rawNorm = shortAvg./(longAvg);
rawNorm = rawNorm(nEnergyAvg:end)./10;


% Find indices when energy rises sharply
% If no plateau is found, read more samples from the buffer.
indAboveThresh = find(rawNorm > threshold);
if isempty(indAboveThresh)
    rawBuf = fread(fi, buffer_len, 'float');
    continue;
end

% Because of the filtering, the actual start of the packet will be nEnergy
% samples after the detected peak. This is okay.
startInd = indAboveThresh(1);



% If the packet is partially cut off by the buffer boundaries, read in more
% samples from the buffer and append them to the packet
if (startInd+pkt_len)>length(rawBuf)
    in_buff = fread(fi, buffer_len, 'float');
    if (isempty(in_buff))
        %display('Buffer Empty')
        continue
    end
    rawBuf = cat(1,rawBuf,in_buff);
end


% Plot the start of the packet
if (debugMode)
    
    startVec = zeros(size(rawBuf));
    startVec(startInd) = 1;
    
    figure; 
    plot(rawBuf);
    hold on;
    plot(startVec,'r')
    
    pause
    close
end


% Cut the packet starting with the detected peak
pktCut = rawBuf(startInd:startInd+pkt_len);
rawBuf = rawBuf(startInd+pkt_len+1:end);


%% Filter The Signal

% Apply a moving-average filter to the individual peaks. 
nFilt=4;
pktFilt = filter(ones(1,nFilt)/nFilt,1,pktCut);

% Sign limit the packet. 
decodeThresh = 0.5;
pktDec = pktFilt;
pktDec(pktDec>decodeThresh) = 1;
pktDec(pktDec~=1) = 0;

% The packet will start with a (1), so cut any silence beforehand.
indAboveThresh = find(pktDec);
if (isempty(indAboveThresh))
    continue;
end
start_ind = indAboveThresh(1);
pktDec = pktDec(start_ind:end);






%% Decode The Bits
counter =0;
bit_ind = 1;
for ii=2:length(pktDec)-1
    if (pktDec(ii)~=pktDec(ii-1)) % Transition
        counter = 0;
    else
        counter=counter+1;
        if (counter>16)
            counter=0;
            bit(bit_ind) = pktDec(ii);
            bit_ind=bit_ind+1;
        end
    end
end

npad = ceil(length(bit)/8)*8 - length(bit);
bit_pad = [bit zeros(1,npad)];
bit_group = reshape(bit_pad,8,[]).';
%bit_group = vec2mat(bit,8);




bit_str = num2str(fliplr(bit_group));
byte = bin2dec(bit_str).';

%byte = bi2de(bit_group)';

%% Decode The Packet
known_sync = 85*ones(1,13);
if (length(byte)<14)
    continue
end
sync = byte(1:13);
payload = byte(14:end);

pkt_good = false;
if (isequal(sync,known_sync))
    display('Received Pkt')
    pkt_good=true;
end



if (pkt_good)
    disp_counter = 4
    goodHand = text(0,0.5,good_str,'fontsize',16,'color','r');
end 
drawnow

if (~pkt_good)
   continue
end


dec2hex(payload)
pkt_counter=pkt_counter+1;
rx_payload(pkt_counter,1:length(payload)) = payload;
   

%% Plot the results
text_str = [];
for ii=1:length(byte)
    text_str = strcat(text_str, sprintf(' %d  ',byte(ii)));
end

preamble_str = [];
for ii=1:length(sync)
    preamble_str = strcat(preamble_str, sprintf(' %d  ',sync(ii)));
end

if (exist('dataHand'))
    delete(dataHand)
    clear dataHand
end
dataHand = text(0,0.1,text_str,'fontsize',16,'color','k');

text(0,0,' |----------------------Sync----------------------|',...
    'fontsize',16,'color','b')
text(0.25,0,' |--------------------------------------------Button Code ---------------------------------------------------------------------|',...
    'fontsize',16,'color','b')

drawnow
tic


end

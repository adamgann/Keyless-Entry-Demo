%
%
%

vaporize


%% Parameters

threshold = 0.2;
pkt_len = 6000;
pulse_len = 22;
window_len = 10;

buffer_len = 50000;


rx_pkts = zeros(35,35);
pkt_counter = 0;



%% Data


%keyless_mag = read_float_binary('data/keyless_mag.dat');
fi = fopen('data/keyless_mag_fifo','rb');



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
raw = in_buff;

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
  
eng_mat = vec2mat(raw,10);
x_mag = abs(eng_mat).^2;
x_sum = sum(x_mag,2);

b = x_sum(2:end);
a = x_sum(1:end-1);

x_diff = b./a;
x_norm = x_diff./max(x_diff);



x_ind = find(x_norm>threshold);
if (isempty(x_ind))
    x_ind = 1;
end

start_ind = x_ind(1)*window_len;


if (start_ind+pkt_len)>length(raw)
    in_buff = fread(fi, buffer_len, 'float');
    if (isempty(in_buff))
        %display('Buffer Empty')
        continue
    end
    raw = cat(1,raw,in_buff);
end



vec = zeros(size(raw));
vec(start_ind) = 1;

x_pkt = raw(start_ind:start_ind+pkt_len);
raw = raw(start_ind+pkt_len+1:end);


%% Filter The Signal

n=2;
x_filt = filter(ones(1,n)/n,1,x_pkt);


x_dec = x_filt;
x_dec(x_dec>0.3) = 1;
x_dec(x_dec~=1) = 0;



x_ind = find(x_dec);

if (isempty(x_ind))
    continue;
end

start_ind = x_ind(1);

x_dec = x_dec(start_ind:end);






%% Decode The Bits
counter =0;
bit_ind = 1;
for ii=2:length(x_dec)-1
    if (x_dec(ii)~=x_dec(ii-1)) % Transition
        counter = 0;
    else
        counter=counter+1;
        if (counter>16)
            counter=0;
            bit(bit_ind) = x_dec(ii);
            bit_ind=bit_ind+1;
        end
    end
end

%bit = bit(1:2:end);
bit_group = vec2mat(bit,8);
byte = bi2de(bit_group)';


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

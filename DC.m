clc; clear; close all; rng(7);
%% RELIABLE DIGITAL TRANSMISSION OF EMERGENCY MESSAGES
% 1. Text-to-binary conversion
% 2. BPSK and QPSK modulation
% 3. AWGN and burst interference
% 4. CRC-16 error detection
% 5. Repetition-code forward error correction
% 6. Priority-based retransmission
% 7. BER and packet-delivery performance plots
% Requires MATLAB R2016b or newer.
% No Communications Toolbox is required.
%% USER SETTINGS
message='DC PROJECT';
priority='HIGH';
modulation='BPSK';
SNR_dB=10;
enableBurst=true;
enableFEC=true;
enableCRC=true;
maxRetransmissions=4;
%% TRANSMITTER: TEXT TO BITS
dataBits=textToBits(message);
fprintf('\n===== EMERGENCY DIGITAL COMMUNICATION SIMULATION =====\n');
fprintf('Original message : %s\n',message);
fprintf('Priority         : %s\n',priority);
fprintf('Modulation       : %s\n',modulation);
fprintf('SNR              : %.1f dB\n',SNR_dB);
fprintf('FEC enabled      : %d\n',enableFEC);
fprintf('CRC enabled      : %d\n',enableCRC);
fprintf('Burst enabled    : %d\n\n',enableBurst);

%% ADD CRC CHECK BITS
if enableCRC
    txPacket=appendCRC16(dataBits);
else
    txPacket=dataBits;
end
%% APPLY FORWARD ERROR CORRECTION
if enableFEC
    encodedBits=repetitionEncode(txPacket,3);
else
    encodedBits=txPacket;
end
%% SINGLE TRANSMISSION
[rxDecodedBits,rxSamples,txSymbols,bitErrors,ber,crcOK]=...
    transmitOnce(encodedBits,txPacket,modulation,SNR_dB,...
    enableBurst,enableFEC,enableCRC);

fprintf('Bits in original message : %d\n',numel(dataBits));
fprintf('Bits in packet            : %d\n',numel(txPacket));
fprintf('Bits sent after FEC       : %d\n',numel(encodedBits));
fprintf('Bit errors (packet bits)  : %d\n',bitErrors);
fprintf('Measured BER              : %.6f\n',ber);

if enableCRC
    fprintf('CRC result: %s\n',passFail(crcOK));
else
    fprintf('CRC result: NOT ENABLED\n');
end

if numel(rxDecodedBits)>=numel(dataBits)
    recoveredBits=rxDecodedBits(1:numel(dataBits));
    recoveredMessage=bitsToText(recoveredBits);
    fprintf('Recovered message         : %s\n',recoveredMessage);
else
    fprintf('Recovered message         : [Unable to recover message]\n');
end
%% PRIORITY-BASED RETRANSMISSION
fprintf('\n===== PRIORITY / RETRANSMISSION SIMULATION =====\n');

if enableCRC
    packetOK=crcOK;
else
    packetOK=numel(rxDecodedBits)>=numel(txPacket)&&...
        isequal(rxDecodedBits(1:numel(txPacket)),txPacket);
end

attempts=1;
maxAttempts=1;
if strcmpi(priority,'HIGH')
    maxAttempts=1+maxRetransmissions;
end

while ~packetOK&&attempts<maxAttempts
    attempts=attempts+1;
    [rxDecodedBits,~,~,bitErrors,ber,crcOK]=...
        transmitOnce(encodedBits,txPacket,modulation,SNR_dB,...
        enableBurst,enableFEC,enableCRC);
    if enableCRC
        packetOK=crcOK;
    else
        packetOK=numel(rxDecodedBits)>=numel(txPacket)&&...
            isequal(rxDecodedBits(1:numel(txPacket)),txPacket);
    end
end

fprintf('Transmission attempts : %d\n',attempts);
fprintf('Packet accepted       : %s\n',passFail(packetOK));
if ~packetOK
    fprintf('Packet was not recovered within the allowed attempts.\n');
end
%% BER VS SNR
testBits=randi([0 1],1,20000);
snrValues=-4:2:14;
berBPSK=zeros(size(snrValues));
berQPSK=zeros(size(snrValues));
berBPSK_FEC=zeros(size(snrValues));

for k=1:numel(snrValues)
    berBPSK(k)=measureBER(testBits,'BPSK',snrValues(k),false,false);
    berQPSK(k)=measureBER(testBits,'QPSK',snrValues(k),false,false);
    berBPSK_FEC(k)=measureBER(testBits,'BPSK',snrValues(k),true,false);
end

%% PACKET DELIVERY RATE VS SNR
packetTrials=100;
deliveryBPSK=zeros(size(snrValues));
deliveryBPSK_FEC=zeros(size(snrValues));

for k=1:numel(snrValues)
    good1=0;
    good2=0;
    for trial=1:packetTrials
        trialBits=randi([0 1],1,128);
        packet=appendCRC16(trialBits);

        % Uncoded BPSK with CRC
        [~,~,~,~,~,ok1]=transmitOnce(packet,packet,'BPSK',...
            snrValues(k),false,false,true);
        good1=good1+double(ok1);

        % Repetition-coded BPSK with CRC
        codedPacket=repetitionEncode(packet,3);
        [~,~,~,~,~,ok2]=transmitOnce(codedPacket,packet,'BPSK',...
            snrValues(k),false,true,true);
        good2=good2+double(ok2);
    end
    deliveryBPSK(k)=good1/packetTrials;
    deliveryBPSK_FEC(k)=good2/packetTrials;
end

%% PLOT 1: TRANSMITTED AND RECEIVED SYMBOLS
figure('Name','Transmitted and Received Symbols');
numShow=min(80,numel(txSymbols));
subplot(2,1,1);
stem(real(txSymbols(1:numShow)),'filled');
grid on;
title([modulation ' Transmitted Symbols']);
xlabel('Symbol index'); ylabel('Amplitude');

subplot(2,1,2);
plot(real(rxSamples(1:min(numShow,numel(rxSamples)))),'.-');
grid on;
title('Received Samples (Real Part)');
xlabel('Symbol index'); ylabel('Amplitude');
%% PLOT 2: BER VS SNR
figure('Name','BER vs SNR');
semilogy(snrValues,max(berBPSK,1e-6),'o-','LineWidth',1.5);
hold on;
semilogy(snrValues,max(berQPSK,1e-6),'s-','LineWidth',1.5);
semilogy(snrValues,max(berBPSK_FEC,1e-6),'d-','LineWidth',1.5);
grid on;
xlabel('SNR (dB)'); ylabel('Bit Error Rate (BER)');
title('BER Performance Comparison');
legend('BPSK uncoded','QPSK uncoded',...
    'BPSK with repetition FEC','Location','southwest');

%% PLOT 3: PACKET DELIVERY RATE
figure('Name','Packet Delivery Rate');
plot(snrValues,100*deliveryBPSK,'o-','LineWidth',1.5);
hold on;
plot(snrValues,100*deliveryBPSK_FEC,'s-','LineWidth',1.5);
grid on;
xlabel('SNR (dB)'); ylabel('Packets accepted (%)');
title('Packet Delivery Rate with CRC');
legend('BPSK uncoded','BPSK with repetition FEC',...
    'Location','southeast');
ylim([0 100]);

%% PLOT 4: BURST INTERFERENCE EFFECT
burstBER=zeros(1,2);
burstLabels={'AWGN only','AWGN + burst'};
for k=1:2
    burstBER(k)=measureBER(testBits,'BPSK',6,false,k==2);
end

figure('Name','Burst Interference Comparison');
bar(burstBER);
set(gca,'XTick',1:2,'XTickLabel',burstLabels);
ylabel('Bit Error Rate (BER)');
title('Effect of Burst Interference at 6 dB SNR');
grid on;

fprintf('\nSimulation complete. Figures have been generated.\n');
fprintf('Use the graphs and measured results in your project report.\n');
%% ================= LOCAL FUNCTIONS =================

function bits=textToBits(message)
    bytes=uint8(message);
    bitMatrix=dec2bin(bytes,8)-'0';
    bits=reshape(bitMatrix.',1,[]);
end

function message=bitsToText(bits)
    bits=double(bits(:).');
    numberOfCompleteBytes=floor(numel(bits)/8);
    bits=bits(1:numberOfCompleteBytes*8);
    if isempty(bits)
        message='';
        return;
    end
    bitMatrix=reshape(bits,8,[]).';
    byteValues=uint8(bin2dec(char(bitMatrix+'0')));
    message=char(byteValues);
end

function packet=appendCRC16(dataBits)
    polynomial=uint16(hex2dec('1021'));
    reg=uint16(hex2dec('FFFF'));
    dataBits=double(dataBits(:).');
    for i=1:numel(dataBits)
        inputBit=uint16(dataBits(i));
        topBit=bitget(reg,16);
        reg=bitshift(reg,1);
        if bitxor(topBit,inputBit)~=0
            reg=bitxor(reg,polynomial);
        end
    end
    crcBits=zeros(1,16);
    for i=1:16
        crcBits(i)=double(bitget(reg,17-i));
    end
    packet=[dataBits crcBits];
end

function ok=checkCRC16(packet)
    if numel(packet)<16
        ok=false;
        return;
    end
    payload=packet(1:end-16);
    expectedPacket=appendCRC16(payload);
    expectedCRC=expectedPacket(end-15:end);
    receivedCRC=packet(end-15:end);
    ok=isequal(expectedCRC,receivedCRC);
end

function encoded=repetitionEncode(bits,repeatCount)
    bits=double(bits(:).');
    encoded=repelem(bits,repeatCount);
end

function decoded=repetitionDecode(bits,repeatCount)
    bits=double(bits(:).');
    nGroups=floor(numel(bits)/repeatCount);
    bits=bits(1:nGroups*repeatCount);
    grouped=reshape(bits,repeatCount,[]);
    decoded=double(sum(grouped,1)>repeatCount/2);
end

function [decodedPacket,rxSamples,txSymbols,nErrors,ber,crcOK]=...
    transmitOnce(encodedBits,originalPacket,modulation,SNR_dB,...
    enableBurst,enableFEC,enableCRC)

    encodedBits=double(encodedBits(:).');
    originalPacket=double(originalPacket(:).');

    if strcmpi(modulation,'BPSK')
        txSymbols=2*encodedBits-1;
        rxSamples=addChannel(txSymbols,SNR_dB,enableBurst);
        recoveredEncoded=double(real(rxSamples)>0);

    elseif strcmpi(modulation,'QPSK')
        bitsForModulation=encodedBits;
        if mod(numel(bitsForModulation),2)
            bitsForModulation=[bitsForModulation 0];
        end
        bitPairs=reshape(bitsForModulation,2,[]).';
        txSymbols=((1-2*bitPairs(:,1))+...
            1i*(1-2*bitPairs(:,2)))/sqrt(2);
        rxSamples=addChannel(txSymbols,SNR_dB,enableBurst);
        % One row per symbol: first bit and second bit.
        rxPairs=[real(rxSamples(:))<0,imag(rxSamples(:))<0];
        recoveredEncoded=reshape(double(rxPairs.'),1,[]);
        recoveredEncoded=recoveredEncoded(1:numel(encodedBits));

    else
        error('Modulation must be BPSK or QPSK.');
    end

    if enableFEC
        decodedPacket=repetitionDecode(recoveredEncoded,3);
    else
        decodedPacket=recoveredEncoded;
    end

    compareLength=min(numel(decodedPacket),numel(originalPacket));
    if compareLength==0
        nErrors=numel(originalPacket);
        ber=1;
    else
        nErrors=sum(decodedPacket(1:compareLength)~=...
            originalPacket(1:compareLength))+...
            abs(numel(originalPacket)-numel(decodedPacket));
        ber=nErrors/numel(originalPacket);
    end

    if enableCRC
        crcOK=checkCRC16(decodedPacket);
    else
        crcOK=false;
    end
end

function rx=addChannel(tx,SNR_dB,enableBurst)
    tx=tx(:).';
    signalPower=mean(abs(tx).^2);
    noisePower=signalPower/(10^(SNR_dB/10));
    if isreal(tx)
        noise=sqrt(noisePower)*randn(size(tx));
    else
        noise=sqrt(noisePower/2)*(randn(size(tx))+...
            1i*randn(size(tx)));
    end
    rx=tx+noise;

    if enableBurst&&numel(rx)>=10
        burstFraction=0.02;
        burstAmplitude=sqrt(signalPower);
        burstLength=max(1,floor(burstFraction*numel(rx)));
        startIndex=randi(numel(rx)-burstLength+1);
        endIndex=startIndex+burstLength-1;
        if isreal(rx)
            polarity=2*(rand>0.5)-1;
            rx(startIndex:endIndex)=rx(startIndex:endIndex)+...
                polarity*burstAmplitude;
        else
            phase=exp(1i*2*pi*rand);
            rx(startIndex:endIndex)=rx(startIndex:endIndex)+...
                burstAmplitude*phase;
        end
    end
end

function ber=measureBER(bits,modulation,SNR_dB,enableFEC,enableBurst)
    bits=double(bits(:).');
    if enableFEC
        txBits=repetitionEncode(bits,3);
    else
        txBits=bits;
    end

    if strcmpi(modulation,'BPSK')
        txSymbols=2*txBits-1;
        rx=addChannel(txSymbols,SNR_dB,enableBurst);
        rxBits=double(real(rx)>0);

    elseif strcmpi(modulation,'QPSK')
        if mod(numel(txBits),2)
            txBits=[txBits 0];
        end
        pairs=reshape(txBits,2,[]).';
        txSymbols=((1-2*pairs(:,1))+...
            1i*(1-2*pairs(:,2)))/sqrt(2);
        rx=addChannel(txSymbols,SNR_dB,enableBurst);
        % One row per symbol; preserve the correct bit-pair order.
        rxPairs=[real(rx(:))<0,imag(rx(:))<0];
        rxBits=reshape(double(rxPairs.'),1,[]);
        rxBits=rxBits(1:numel(txBits));

    else
        error('Modulation must be BPSK or QPSK.');
    end

    if enableFEC
        rxBits=repetitionDecode(rxBits,3);
    end
    n=min(numel(bits),numel(rxBits));
    ber=sum(bits(1:n)~=rxBits(1:n))/n;
end

function out=passFail(value)
    if value
        out='PASS';
    else
        out='FAIL';
    end
end
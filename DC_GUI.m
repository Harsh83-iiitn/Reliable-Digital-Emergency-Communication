function DC_GUI
clc; rng(7);
%% MAIN WINDOW
app=uifigure('Name','Reliable Digital Emergency Communication',...
    'Position',[20 40 1200 780],'Color',[0.96 0.97 0.99]);
try
    app.WindowState='maximized';
catch
end
screen=get(0,'ScreenSize');
resultHeight=min(280,max(230,round(screen(4)*0.28)));
main=uigridlayout(app,[2 2]);
main.RowHeight={'1x',resultHeight};
main.ColumnWidth={350,'1x'};
main.Padding=[8 8 8 8]; main.RowSpacing=8; main.ColumnSpacing=8;
%% TRANSMISSION SETTINGS
left=uipanel(main,'Title','Transmission Settings','FontWeight','bold');
left.Layout.Row=1; left.Layout.Column=1;
g=uigridlayout(left,[15 1]);
g.RowHeight={22,30,20,30,20,30,22,42,22,42,24,24,24,40,'1x'};
g.Padding=[10 8 10 8]; g.RowSpacing=4;
uilabel(g,'Text','Emergency message','FontWeight','bold');
messageField=uieditfield(g,'text','Value','DC PROJECT');
uilabel(g,'Text','Priority');
priorityDrop=uidropdown(g,'Items',{'HIGH','NORMAL','LOW'},'Value','HIGH');
uilabel(g,'Text','Modulation');
modDrop=uidropdown(g,'Items',{'BPSK','QPSK'},'Value','BPSK');
snrLabel=uilabel(g,'Text','SNR: 10 dB','FontWeight','bold');
snrSlider=uislider(g,'Limits',[-5 30],'Value',10,'MajorTicks',-5:5:30);
retryLabel=uilabel(g,'Text','Maximum retransmissions: 4','FontWeight','bold');
retrySlider=uislider(g,'Limits',[0 10],'Value',4,'MajorTicks',0:2:10);
burstCheck=uicheckbox(g,'Text','Enable burst interference','Value',true);
fecCheck=uicheckbox(g,'Text','Enable FEC (3-bit repetition)','Value',true);
crcCheck=uicheckbox(g,'Text','Enable CRC-16','Value',true);
runButton=uibutton(g,'push','Text','RUN SIMULATION','FontWeight','bold',...
    'BackgroundColor',[0.12 0.38 0.72],'FontColor',[1 1 1]);
%% SIMULATION DASHBOARD
right=uipanel(main,'Title','Simulation Dashboard','FontWeight','bold');
right.Layout.Row=1; right.Layout.Column=2;
rg=uigridlayout(right,[2 2]);
rg.RowHeight={'1x','1x'}; rg.ColumnWidth={'1x','1x'};
rg.Padding=[6 6 6 6]; rg.RowSpacing=8; rg.ColumnSpacing=8;
ax1=uiaxes(rg); ax2=uiaxes(rg); ax3=uiaxes(rg); ax4=uiaxes(rg);
title(ax1,'Transmitted and received symbols');
title(ax2,'BER versus SNR');
title(ax3,'Packet delivery rate');
title(ax4,'Burst interference comparison');
grid(ax1,'on'); grid(ax2,'on'); grid(ax3,'on'); grid(ax4,'on');
%% RESULTS PANEL
resultPanel=uipanel(main,'Title','Transmission Results','FontWeight','bold');
resultPanel.Layout.Row=2; resultPanel.Layout.Column=[1 2];
resultGrid=uigridlayout(resultPanel,[2 2]);
resultGrid.RowHeight={32,'1x'}; resultGrid.ColumnWidth={'1x',170};
resultGrid.Padding=[8 8 8 8];
statusLabel=uilabel(resultGrid,'Text','Status: Ready','FontWeight','bold',...
    'FontColor',[0.05 0.45 0.15]);
statusLabel.Layout.Row=1; statusLabel.Layout.Column=1;
resetButton=uibutton(resultGrid,'push','Text','RESET SETTINGS','FontWeight','bold');
resetButton.Layout.Row=1; resetButton.Layout.Column=2;
outputArea=uitextarea(resultGrid,'Editable','off','FontName','Consolas','FontSize',11);
outputArea.Layout.Row=2; outputArea.Layout.Column=[1 2];
outputArea.Value={'Enter a message and click RUN SIMULATION.'};
%% AUTOMATIC UPDATE CALLBACKS
isResetting=false;
messageField.ValueChangedFcn=@settingsChanged;
priorityDrop.ValueChangedFcn=@settingsChanged;
modDrop.ValueChangedFcn=@settingsChanged;
snrSlider.ValueChangingFcn=@previewSNR;
snrSlider.ValueChangedFcn=@settingsChanged;
retrySlider.ValueChangingFcn=@previewRetry;
retrySlider.ValueChangedFcn=@settingsChanged;
burstCheck.ValueChangedFcn=@settingsChanged;
fecCheck.ValueChangedFcn=@settingsChanged;
crcCheck.ValueChangedFcn=@settingsChanged;
runButton.ButtonPushedFcn=@runSimulation;
resetButton.ButtonPushedFcn=@resetSettings;
runSimulation([],[]);
%% SLIDER DISPLAY
    function previewSNR(~,event)
        snrLabel.Text=sprintf('SNR: %.1f dB',event.Value);
    end
    function previewRetry(~,event)
        retryLabel.Text=sprintf('Maximum retransmissions: %d',round(event.Value));
    end
%% AUTOMATIC SIMULATION
    function settingsChanged(~,~)
        if isResetting, return; end
        snrLabel.Text=sprintf('SNR: %.1f dB',snrSlider.Value);
        retryLabel.Text=sprintf('Maximum retransmissions: %d',round(retrySlider.Value));
        runSimulation([],[]);
    end
%% RESET SETTINGS
    function resetSettings(~,~)
        isResetting=true;
        messageField.Value='';
        priorityDrop.Value='HIGH'; modDrop.Value='BPSK';
        snrSlider.Value=10; retrySlider.Value=4;
        burstCheck.Value=true; fecCheck.Value=true; crcCheck.Value=true;
        snrLabel.Text='SNR: 10 dB';
        retryLabel.Text='Maximum retransmissions: 4';
        isResetting=false;
        statusLabel.Text='Status: Waiting for message';
        statusLabel.FontColor=[0.1 0.4 0.2];
        outputArea.Value={'===== SETTINGS RESET =====';'Message input cleared.';...
            'Default settings restored.';'Enter a new message to begin.'};
        cla(ax1); cla(ax2); cla(ax3); cla(ax4);
    end
%% MAIN SIMULATION
    function runSimulation(~,~)
        msg=char(messageField.Value);
        if isempty(strtrim(msg))
            statusLabel.Text='Status: Waiting for message';
            outputArea.Value={'Please enter an emergency message.';...
                'The simulation will update automatically.'};
            cla(ax1); cla(ax2); cla(ax3); cla(ax4);
            return;
        end
        if any(double(msg)>127)
            outputArea.Value={'Use standard ASCII characters only.'};
            statusLabel.Text='Status: Invalid message';
            return;
        end
        runButton.Enable='off';
        statusLabel.Text='Status: Running...'; drawnow;
        try
            priority=priorityDrop.Value; modulation=modDrop.Value;
            snrDb=snrSlider.Value; retries=round(retrySlider.Value);
            useBurst=burstCheck.Value; useFEC=fecCheck.Value; useCRC=crcCheck.Value;
            %% MESSAGE ENCODING
            data=textToBits(msg);
            if useCRC, packet=appendCRC(data); else, packet=data; end
            if useFEC, encoded=repetitionEncode(packet,3); else, encoded=packet; end
            %% RETRANSMISSION LIMIT
            if strcmp(priority,'HIGH')
                maxAttempts=1+retries;
            elseif strcmp(priority,'NORMAL')
                maxAttempts=min(2,1+retries);
            else
                maxAttempts=1;
            end
            %% TRANSMISSION
            attempts=0; accepted=false;
            decoded=[]; tx=[]; rx=[]; errors=0; ber=1; crcOK=false;
            while attempts<maxAttempts && ~accepted
                attempts=attempts+1;
                [decoded,tx,rx,errors,ber,crcOK]=transmit(...
                    encoded,packet,modulation,snrDb,useBurst,useFEC,useCRC);
                accepted=packetCheck(decoded,packet,useCRC,crcOK);
            end
            %% MESSAGE RECOVERY
            if numel(decoded)>=numel(data)
                recovered=bitsToText(decoded(1:numel(data)));
            else
                recovered='[Unable to recover message]';
            end
            if useCRC, crcResult=passFail(crcOK); else, crcResult='NOT ENABLED'; end
            %% RESULTS
            lines=cell(0,1);
            lines{end+1,1}='===== EMERGENCY COMMUNICATION RESULTS =====';
            lines{end+1,1}=['Original message: ' msg];
            lines{end+1,1}=['Recovered message: ' recovered];
            lines{end+1,1}=sprintf('Priority: %s | Modulation: %s',priority,modulation);
            lines{end+1,1}=sprintf('SNR: %.1f dB | Burst: %s',snrDb,onOff(useBurst));
            lines{end+1,1}=sprintf('FEC: %s | CRC: %s',onOff(useFEC),onOff(useCRC));
            lines{end+1,1}=sprintf('Message bits: %d | Packet bits: %d',numel(data),numel(packet));
            lines{end+1,1}=sprintf('Transmitted bits after FEC: %d',numel(encoded));
            lines{end+1,1}=sprintf('Decoded bit errors: %d | BER: %.6f',errors,ber);
            lines{end+1,1}=sprintf('CRC result: %s',crcResult);
            lines{end+1,1}=sprintf('Transmission attempts: %d',attempts);
            lines{end+1,1}=sprintf('Packet accepted: %s',passFail(accepted));
            if ~accepted, lines{end+1,1}='Packet failed after the allowed attempts.'; end
            outputArea.Value=lines;
            if accepted
                statusLabel.Text='Status: Packet accepted';
                statusLabel.FontColor=[0.05 0.45 0.15];
            else
                statusLabel.Text='Status: Packet rejected';
                statusLabel.FontColor=[0.75 0.1 0.1];
            end
            %% GRAPH 1: TRANSMITTED AND RECEIVED SYMBOLS
            cla(ax1); n=min(60,numel(tx)); nr=min(n,numel(rx));
            txValues=real(tx(1:n)); rxValues=real(rx(1:nr));
            txValues=txValues(:); rxValues=rxValues(:);
            stem(ax1,(1:n)',txValues,'filled'); hold(ax1,'on');
            plot(ax1,(1:nr)',rxValues,'x-'); hold(ax1,'off');
            xlabel(ax1,'Symbol index'); ylabel(ax1,'Amplitude');
            legend(ax1,{'Transmit','Receive'},'Location','best');
            title(ax1,'Transmitted and received symbols'); grid(ax1,'on');
            %% PERFORMANCE SIMULATION
            testBits=randi([0 1],1,4000); snrs=-4:2:14;
            bp=zeros(size(snrs)); bq=zeros(size(snrs)); bf=zeros(size(snrs));
            dp=zeros(size(snrs)); df=zeros(size(snrs)); trials=20;
            for k=1:numel(snrs)
                bp(k)=measureBER(testBits,'BPSK',snrs(k),false,false);
                bq(k)=measureBER(testBits,'QPSK',snrs(k),false,false);
                bf(k)=measureBER(testBits,'BPSK',snrs(k),true,false);
                goodPlain=0; goodFEC=0;
                for t=1:trials
                    randomData=randi([0 1],1,128);
                    randomPacket=appendCRC(randomData);
                    [decoded1,~,~,~,~,ok1]=transmit(randomPacket,randomPacket,...
                        'BPSK',snrs(k),false,false,true);
                    goodPlain=goodPlain+double(packetCheck(decoded1,...
                        randomPacket,true,ok1));
                    codedPacket=repetitionEncode(randomPacket,3);
                    [decoded2,~,~,~,~,ok2]=transmit(codedPacket,randomPacket,...
                        'BPSK',snrs(k),false,true,true);
                    goodFEC=goodFEC+double(packetCheck(decoded2,...
                        randomPacket,true,ok2));
                end
                dp(k)=goodPlain/trials; df(k)=goodFEC/trials;
            end
            %% GRAPH 2: BER VERSUS SNR
            cla(ax2);
            semilogy(ax2,snrs,max(bp,1e-6),'o-','LineWidth',1.2);
            hold(ax2,'on');
            semilogy(ax2,snrs,max(bq,1e-6),'s-','LineWidth',1.2);
            semilogy(ax2,snrs,max(bf,1e-6),'d-','LineWidth',1.2);
            hold(ax2,'off');
            xlabel(ax2,'SNR (dB)'); ylabel(ax2,'Bit Error Rate');
            legend(ax2,{'BPSK uncoded','QPSK uncoded','BPSK + FEC'},...
                'Location','southwest');
            title(ax2,'BER versus SNR'); grid(ax2,'on');
            %% GRAPH 3: PACKET DELIVERY RATE
            cla(ax3);
            plot(ax3,snrs,100*dp,'o-','LineWidth',1.2); hold(ax3,'on');
            plot(ax3,snrs,100*df,'s-','LineWidth',1.2); hold(ax3,'off');
            xlabel(ax3,'SNR (dB)'); ylabel(ax3,'Packets accepted (%)');
            ylim(ax3,[0 100]);
            legend(ax3,{'Uncoded + CRC','FEC + CRC'},'Location','southeast');
            title(ax3,'Packet delivery rate'); grid(ax3,'on');
            %% GRAPH 4: BURST INTERFERENCE
            cla(ax4); burstValues=zeros(1,2);
            burstValues(1)=measureBER(testBits,'BPSK',6,false,false);
            burstValues(2)=measureBER(testBits,'BPSK',6,false,true);
            bar(ax4,1:2,burstValues);
            ax4.XTick=[1 2]; ax4.XTickLabel={'AWGN only','AWGN + burst'};
            ylabel(ax4,'Bit Error Rate');
            title(ax4,'Burst interference at 6 dB'); grid(ax4,'on');
        catch ME
            statusLabel.Text='Status: Error';
            statusLabel.FontColor=[0.75 0.1 0.1];
            details=cell(0,1);
            details{end+1,1}='SIMULATION ERROR';
            details{end+1,1}=ME.message;
            details{end+1,1}='Error location:';
            for j=1:numel(ME.stack)
                details{end+1,1}=sprintf('%s, line %d',ME.stack(j).name,ME.stack(j).line);
            end
            outputArea.Value=details;
            disp(getReport(ME,'extended','hyperlinks','off'));
        end
        runButton.Enable='on';
    end
end

%% TEXT TO BINARY
function bits=textToBits(message)
m=dec2bin(uint8(message),8)-'0';
bits=reshape(m.',1,[]);
end
%% BINARY TO TEXT
function message=bitsToText(bits)
bits=double(bits(:).'); n=floor(numel(bits)/8)*8; bits=bits(1:n);
if isempty(bits), message=''; return; end
m=reshape(bits,8,[]).';
values=uint8(bin2dec(char(m+'0')));
message=char(values(:).');
end
%% CRC-16 GENERATION
function packet=appendCRC(data)
data=double(data(:).'); reg=uint16(hex2dec('FFFF')); poly=uint16(hex2dec('1021'));
for k=1:numel(data)
    top=bitget(reg,16); reg=bitshift(reg,1);
    if xor(logical(top),logical(data(k))), reg=bitxor(reg,poly); end
end
crcBits=zeros(1,16);
for k=1:16, crcBits(k)=double(bitget(reg,17-k)); end
packet=zeros(1,numel(data)+16);
packet(1:numel(data))=data;
packet(numel(data)+1:end)=crcBits;
end

%% CRC VERIFICATION
function ok=verifyCRC(packet)
packet=double(packet(:).');
if numel(packet)<16, ok=false; return; end
expected=appendCRC(packet(1:end-16));
ok=isequal(expected(end-15:end),packet(end-15:end));
end

%% REPETITION ENCODER
function encoded=repetitionEncode(bits,n)
encoded=repelem(double(bits(:).'),n);
end
%% REPETITION DECODER
function decoded=repetitionDecode(bits,n)
bits=double(bits(:).'); count=floor(numel(bits)/n); bits=bits(1:count*n);
if count==0, decoded=[]; return; end
groups=reshape(bits,n,[]);
decoded=double(sum(groups,1)>n/2);
end
%% TRANSMITTER AND RECEIVER
function [decoded,tx,rx,nErrors,ber,crcOK]=transmit(...
    encoded,packet,modulation,snrDb,burst,fec,useCRC)
encoded=double(encoded(:).'); packet=double(packet(:).');
if strcmpi(modulation,'BPSK')
    tx=2*encoded-1; rx=channel(tx,snrDb,burst);
    received=double(real(rx)>0);
elseif strcmpi(modulation,'QPSK')
    bits=encoded;
    if mod(numel(bits),2), bits(end+1)=0; end
    pairs=reshape(bits,2,[]).';
    I=1-2*pairs(:,1); Q=1-2*pairs(:,2);
    tx=complex(I,Q)/sqrt(2); tx=tx(:).';
    rx=channel(tx,snrDb,burst);
    realBits=double(real(rx(:))<0); imagBits=double(imag(rx(:))<0);
    pairBits=zeros(numel(realBits),2);
    pairBits(:,1)=realBits; pairBits(:,2)=imagBits;
    received=reshape(pairBits.',1,[]);
    received=received(1:numel(encoded));
else
    error('Choose BPSK or QPSK.');
end
if fec, decoded=repetitionDecode(received,3); else, decoded=received; end
n=min(numel(decoded),numel(packet));
nErrors=sum(decoded(1:n)~=packet(1:n))+abs(numel(decoded)-numel(packet));
ber=nErrors/max(1,numel(packet));
if useCRC, crcOK=verifyCRC(decoded); else, crcOK=false; end
end
%% AWGN AND BURST CHANNEL
function rx=channel(tx,snrDb,burst)
tx=tx(:).'; power=mean(abs(tx).^2);
noisePower=power/(10^(snrDb/10));
if isreal(tx)
    noise=sqrt(noisePower/2)*randn(size(tx));
else
    noise=sqrt(noisePower/2)*(randn(size(tx))+1i*randn(size(tx)));
end
rx=tx+noise;
if burst && numel(rx)>=10
    burstLength=max(1,floor(0.02*numel(rx)));
    startIndex=randi(numel(rx)-burstLength+1);
    indices=startIndex:startIndex+burstLength-1;
    amplitude=2*sqrt(power);
    if isreal(rx)
        polarity=2*(rand>0.5)-1;
        rx(indices)=rx(indices)+polarity*amplitude;
    else
        phase=exp(1i*2*pi*rand);
        rx(indices)=rx(indices)+amplitude*phase;
    end
end
end
%% BER MEASUREMENT
function ber=measureBER(bits,modulation,snrDb,fec,burst)
bits=double(bits(:).');
if fec, txBits=repetitionEncode(bits,3); else, txBits=bits; end
if strcmpi(modulation,'BPSK')
    tx=2*txBits-1; rx=channel(tx,snrDb,burst);
    received=double(real(rx)>0);
else
    if mod(numel(txBits),2), txBits(end+1)=0; end
    pairs=reshape(txBits,2,[]).';
    I=1-2*pairs(:,1); Q=1-2*pairs(:,2);
    tx=complex(I,Q)/sqrt(2); rx=channel(tx,snrDb,burst);
    realBits=double(real(rx(:))<0); imagBits=double(imag(rx(:))<0);
    pairBits=zeros(numel(realBits),2);
    pairBits(:,1)=realBits; pairBits(:,2)=imagBits;
    received=reshape(pairBits.',1,[]);
    received=received(1:numel(txBits));
end
if fec, received=repetitionDecode(received,3); end
n=min(numel(bits),numel(received));
ber=sum(bits(1:n)~=received(1:n))/max(1,n);
end
%% PACKET ACCEPTANCE
function ok=packetCheck(decoded,packet,useCRC,crcOK)
decoded=double(decoded(:).'); packet=double(packet(:).');
if useCRC
    ok=crcOK && numel(decoded)==numel(packet);
else
    ok=numel(decoded)==numel(packet) && isequal(decoded,packet);
end
end
%% DISPLAY FUNCTIONS
function s=passFail(flag)
if flag, s='PASS'; else, s='FAIL'; end
end

function s=onOff(flag)
if flag, s='ON'; else, s='OFF'; end
end
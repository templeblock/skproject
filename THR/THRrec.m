function S = THRrec(dev, ToneFreq, BurstDur, NonBurstDur, MinSPL, MaxSPL, StartSPL, StepSPL, DAchan, SpikeDiffCrit, MaxNpres);
% THRrec - adaptive measurement of tonal threshold for one frequency
% Usage:
%   THRrec(dev, ToneFreq, BurstDur, NonBurstDur, MinSPL, MaxSPL, StartSPL, StepSPL, DAchan, SpikeDiffCrit, MaxNpres);
%   Helper function of THRcurve.
%   THR Circuit must be loaded at call time.
 
CI = sys3circuitinfo(dev);
Fsam = CI.Fsam;


% amplitudes
NSPL = 1+round((MaxSPL-MinSPL)/StepSPL);
SPL = linspace(MinSPL, MaxSPL, NSPL);
DL = calibrate(EXP, Fsam*1e3, DAchan, ToneFreq);

% Generate waveforms to be able to use maxSPL
P.Fcar = ToneFreq;�@% P��Probe tone�Ƃ����Ӗ����H
P.BurstDur = 100;
P.ISI = 100;
P.DAC = DAchan;
P.FreqTolMode = 'exact';
[P.ModFreq, P.ModDepth, P.ModStartPhase, P.ModTheta, ...
    P.OnsetDelay, P.RiseDur, P.FallDur, P.WavePhase, ...
    P.FineITD, P.GateITD, P.ModITD] = deal(0);% []���̕ϐ��ɑS��0�����蓖�Ă�B
Attenuations = zeros(1,length(SPL));
NumScales = zeros(1,length(SPL));
for i=1:length(SPL)
    P.SPL = SPL(i);
    P = toneStim(P);% THR\helpers\toneStim.m���g����P.Fcar=ToneFreq�̎��g��������Tone�����B�����SPL�̐������J��Ԃ��B
    % Calculate attenuation values using maxSPL
    [dum, Attenuation] = maxSPL(P.Waveform, EXP);% ������Probe tone�����ۂɒ񎦂���Atten�����߂�BTHR\@Waveform\maxSPL.m���g���B�����FiltGain��FiltGoef�Ƒg�ݍ��킹��Ɖ��p�ł��邩�B
    Attenuations(i) = Attenuation.AnaAtten;
    NumScales(i) = Attenuation.NumScale;
end

LinAmp = sqrt(2)*db2a(SPL+DL).*NumScales;
sys3write(LinAmp, 'ToneAmpBuf', dev);
[dum, iStart] = min(abs(SPL-StartSPL));
sys3setpar(iStart-1, 'iAmp', dev); % -1 because of min index = 0
SetAttenuators(EXP, Attenuations(iStart));% SetAttenuator.m��������Ȃ��BLeuven�ɖ₢���킹�邩�H

% freq, timing, thr criterion
sys3setpar(ToneFreq, 'ToneFreq', dev);
sys3setpar(BurstDur, 'BurstDur', dev);
sys3setpar(NonBurstDur, 'NonBurstDur', dev);


% read amplitude history
iAmpHist = [];
i = 0;
while 1,
    i = i + 1;
    % GO
    sys3setpar(1, 'Run', 'RX6');
    pause((BurstDur+NonBurstDur)/1e3);
    sys3setpar(0, 'Run', 'RX6');
    iAmp = sys3getpar('iAmp', dev) + 1;% iAmp���P���₷�B
    iAmpHist(end+1) = iAmp;
    [isReady, Thr] = local_thr(iAmpHist, MaxNpres, SPL);%�R�񓯂�Amp�Œ񎦂�����Thr�Ƃ݂Ȃ���Ƃ����Ӗ��H
    if isReady
        break;%���̎��g����臒l���肵�ďI���Ƃ����Ӗ��H
    else
        SpikeDiff = sys3getpar('SpikeDiff', dev);%SpikeDiff�͉��h������spike count���特���I�������̎������΂�spike count���Ђ������̂��B
        if SpikeDiff <= SpikeDiffCrit
            iAmpNew = iAmp + 2;%���΂�SpikeDiffCrit�ɒB���Ȃ����iAmp���Q���₵�ĉ�����傫������B������SpikeDiffCrit���ǂ̒��x�ɂ��ׂ����͂܂��s���B
        else
            iAmpNew = iAmp - 1;%���΂�SpikeDiffCrit�ɒB���Ă����iAmp���P���炵�ĉ���������������B2U1D���̗p���Ă���悤���B
        end
        
        if iAmpNew > NSPL || iAmpNew < 1
            error('Amplitude out of bounds');%iAmpNew���p�ӂ��Ă������X�g�ɂȂ��ꍇ
        else
            iAmp = iAmpNew;%iAmp���X�V���ă��[�v�̎���i�ɔ�����
        end
        
        sys3setpar(iAmp-1, 'iAmp', dev);
        SetAttenuators(EXP, Attenuations(iAmp));
    end;
end
sys3setpar(0, 'Run', 'RX6'); % stop playing

% return arg
AmpHist = SPL(iAmpHist);
ExpName = name(EXP);
S = collectInStruct(ExpName, ToneFreq, MinSPL, MaxSPL, StartSPL, StepSPL, SPL, DAchan, SpikeDiffCrit, '-', iAmpHist, AmpHist, Thr);

%=============================================================
function [isReady, Thr] = local_thr(iAmp, Nmax, SPL);
% criterion
Thr = nan;
isReady = 0;
Namp = numel(iAmp);
for i=7:Namp
    % check if previous level was higher & if level was the same three presentations ago
    isReady = (iAmp(i-1) > iAmp(i)) && (iAmp(i-3) == iAmp(i)); %%&& (iAmp(i-6) == iAmp(i)));�R�񓯂�Amp�Œ񎦂�����Thr�Ƃ݂Ȃ���Ƃ����Ӗ��H
    if isReady,
        Thr = SPL(iAmp(i));
        break;
    end
end
if Namp>Nmax,
    isReady = 1;
end



%================
%      Name: 'ToneFreq'
%     DataType: 'SingleFloat'
%      TagSize: 1
%  
%         Name: 'ToneAmpBuf'
%     DataType: 'DataBuffer'
%      TagSize: 1000
%  
%         Name: 'iStartAmp'
%     DataType: 'Integer'
%      TagSize: 1
%  
%         Name: 'SpikeDiffCrit'
%     DataType: 'Integer'
%      TagSize: 1
%  
%         Name: 'AmpHistory'
%     DataType: 'DataBuffer'
%      TagSize: 10000
% 
%         Name: 'Run'
%     DataType: 'Logical'
%      TagSize: 1
%  
%         Name: 'BurstDur'
%     DataType: 'SingleFloat'
%      TagSize: 1
%  
%         Name: 'NonBurstDur'
%     DataType: 'SingleFloat'
%      TagSize: 1
%  


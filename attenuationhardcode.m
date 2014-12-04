divideby = 1/32;
a = sqrt(divideby);
x = [1:1:32];
x = a*(x).^(0.5);
x=x*2^7;
binvalues = dec2bin(x);
halfsec = 2*10^7;
threesec = 6*halfsec;
sec = 2* halfsec;
values = ['whole01'; ...
'frac002'; ...
'frac004'; ...
'frac008'; ...
'frac016'; ...
'frac032'; ...
'frac064'; ...
'frac128'];
values2 = [ 'wave;     '; ...
            'wave[7:1];'; ...
            'wave[7:2];'; ...
            'wave[7:3];'; ...
            'wave[7:4];'; ...
            'wave[7:5];'; ...
            'wave[7:6];'; ...
            'wave[7];  '];


for i = 1:1:32
    fprintf('if(cnt < 32''d')
        fprintf(num2str(round(i*(halfsec)/32)))
        fprintf(') \n begin \n')
    for k = 1:1:8
        fprintf('\t');
        fprintf(values(k,:));
        fprintf(' <= ');
        if ( binvalues(i,k) == '1')
            fprintf(values2(k,:));
        else
            fprintf(' 8''b0;');
        end
        if(k<8)
            fprintf('\n')
        end
    end
    fprintf('\n end');
    fprintf('\n else ')
end

divideby = 1/64;
a = sqrt(divideby);
x = [1:1:32];
x = a*(65-x).^(0.5);
x=x*2^7;
binvalues = dec2bin(x);


for i = 1:1:64
    fprintf('if(cnt < 32''d')
        fprintf(num2str(round(i*(halfsec)/32)))
        fprintf(') \n begin \n')
    for k = 1:1:8
        fprintf('\t');
        fprintf(values(k,:));
        fprintf(' <= ');
        if ( binvalues(i,k) == '1')
            fprintf(values2(k,:));
        else
            fprintf(' 8''b0;');
        end
        if(k<8)
            fprintf('\n')
        end
    end
    fprintf('\n end');
    fprintf('\n else ')
end

% divideby = 1/32;
% xrise = [1:1:32];
% xrise = xrise.^0.5*divideby^.5;
% xrise=xrise*2^8;
% xrise = round(xrise)/2^8;
% 
% tot = zeros(193,1);
% 
% for i = 1:192
%    if(i<33)
%     tot(i) = xrise(i);
%    elseif(i<65)
%        tot(i) = 1;
%    else
%        tot(i) = round(x(ceil((i-64)/2)))/2^7;
%    end
% end
% 
% t = 0:3/192:3;
% tot(193) = 0;
% 
% plot(t,tot)
% xlabel('Seconds')
% ylabel('Amplitude as multiple of input signal')
% title('Attenuation')

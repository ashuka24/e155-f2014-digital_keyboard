divideby = 1/32;
x = [1:1:32];
x = x*divideby;
x=x*2^8;
binvalues = dec2bin(x);

values = ['whole01'; ...
          'frac002'; ...
          'frac004'; ...
          'frac008'; ...
          'frac016'; ...
          'frac032'; ...
          'frac064'; ...
          'frac128'];

total = 'wave =';
found = 0;
for i = 1:1:32
    for k = 1:1:8
        if ( binvalues(i,k) == '1' & found ==0)
            total = [total, values(k,:)];
            found = 1;
        elseif (binvalues(i,k) == '1')
           total = [total, ' + ', values(k,:)];
        end
    end
    fprintf('if() \n    ')
    fprintf(total)
    fprintf(';\n else ')
    total = 'wave = ';
    found = 0;
end
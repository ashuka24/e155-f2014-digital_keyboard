decimal = zeros(64,1);
binary = zeros(64,4);
num = 0;
for i=0:63
     num = sin(2*pi*i/64) + 1;
     decimal(i+1) = num;
     num = num*8;
     num2 = round(num);
     binary(i+1) = num2;
     disp(['6''d',num2str(i), ' : wave = 4''b', num2str(dec2bin(num,4)), ';    // exact:', num2str(num/16), '       approx:', num2str(num2/16)]);
end

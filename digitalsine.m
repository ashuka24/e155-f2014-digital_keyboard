decimal = zeros(512,1);
rounded = zeros(512,4);
num = 0;
fprintf('sine = [');
for i=0:511
     num = sin(2*pi*i/512) + 1;
     decimal(i+1) = num*256;
     num2 = num*128;
     num2 = round(num2);
     if(num2 == 256)
         num2=255;
     end
     rounded(i+1) = num2;
     %num2 = round(num);
     %binary(i+1) = num2;
     %disp(['6''d',num2str(i), ' : wave = 4''b', num2str(dec2bin(num,4)), ';    // exact:', num2str(num/16), '       approx:', num2str(num2/16)]);
     fprintf(num2str(num2));
     if(i < 511)
        fprintf(', ');
     end
end
fprintf(']; \n');

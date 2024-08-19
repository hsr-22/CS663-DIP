clear;
clc;
im1 = double(imread('T1.jpg')); im1 = im1 + 1;
im2 = double(imread('T2.jpg')); im2 = im2 + 1;
im3 = imrotate(im2,28.5,'bilinear','crop');

theta_min = -45;
theta_max = 45;
LL = (theta_max - theta_min)+1;
binwidth = 10;
thetavals = theta_min:theta_max;

ncc = zeros(LL,1);
qmi = ncc;
je = ncc;

count = 1;
for theta = -45:1:45
   fprintf ('\n%f',theta);
   im4 = imrotate(im3,theta,'bilinear','crop'); 
   
   valid_indices = find(im4 > 0);
   m1 = mean(im1(valid_indices));
   m2 = mean(im4(valid_indices));
   ncc(count) = abs(dot(im1(valid_indices)-m1,im4(valid_indices)-m2))/( sqrt(sum((im1(valid_indices)-m1).^2)) * sqrt(sum((im4(valid_indices)-m2).^2)) );
   
   p12 = joint_hist(im1(valid_indices),im4(valid_indices),binwidth);
   p2 = sum(p12,1); % marginal histogram of the second image (im4) as im1 is being integrated out
   p1 = sum(p12,2); % marginal histogram of the first image (im1) as im4 is being integrated out
   je(count) = -sum(p12(p12>0).*log(p12(p12>0)));
   
   numbins = length(p1);
   p1p2 = zeros(numbins);
   for i=1:numbins
       for j=1:numbins
           p1p2(i,j) = p1(i)*p2(j); 
       end
   end
   qmi(count) = sum(sum( (p12-p1p2).^2));
   
   count = count+1;
end


plot(thetavals,je);
title ('JE versus angle');
[minval,minind] = min(je);
fprintf('\nMin. value of JE = %f, which occurs at %f',minval,thetavals(minind));

figure; plot(thetavals,ncc);
title ('NCC versus angle');
[maxval,maxind] = max(ncc);
fprintf('\nMax. value of NCC = %f, which occurs at %f',maxval,thetavals(maxind));

figure; plot(thetavals,qmi);
title ('QMI versus angle');
[maxval,maxind] = max(qmi);
fprintf('\nMax. value of QMI = %f, which occurs at %f',maxval,thetavals(maxind));



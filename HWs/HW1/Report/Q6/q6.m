clear;
clc;
im1 = double((imread('goi1.jpg')));
im2 = double((imread('goi2_downsampled.jpg')));
[H,W] = size(im1);
n = 12;

choice = 2; % 1 for GUI

if choice == 1
for i=1:n
   figure(1); imshow(im1/255); [x1(i),y1(i)] = ginput(1);
   figure(2); imshow(im2/255); [x2(i),y2(i)] = ginput(1);
end
else
   load stored_points.mat; 
end

P2 = [x2; y2; ones(1,n)];
P1 = [x1; y1; ones(1,n)];
A = P2*P1'*inv(P1*P1');

im3 = im1; im3(:,:) = 0;

interp_choice = 1; % nearest neighbor
for i=1:H 
    for j=1:W 
        dxy = A\[j i 1]'; 
        xx = round(dxy(1)); 
        yy = round(dxy(2)); 
        
        if xx > 0 && xx <= W && yy > 0 && yy <= H 
            if interp_choice == 1
                im3(i,j) = im1(yy,xx); % nearest neighbor interpolation
            else
                w1 = (xx+1-dxy(1))*(yy+1-dxy(2));
                w4 = (dxy(1)-xx)*(dxy(2)-yy);
                w3 = (yy+1-dxy(2))*(dxy(1)-xx);
                w2 = (xx+1-dxy(1))*(dxy(2)-yy);
                im3(i,j) = im1(yy,xx)*w1+im1(yy+1,xx)*w2+im1(yy,xx+1)*w3+im1(yy+1,xx+1)*w4; 
            end
        end
    end
end

figure(1); imshow(im1/255);
figure(2); imshow(im2/255);
figure(3); imshow(im3/255);


clear;
clc;

% Images
im1 = double((imread('.\..\..\goi1.jpg')));
im2 = double((imread('.\..\..\goi2_downsampled.jpg')));
[H,W] = size(im1);

%%% (a)
n = 12;

choice = 1;

if choice == 1
    for i = 1:n
        figure(1); imshow(im1/255); 
        [x1(i),y1(i)] = ginput(1);
        figure(2); imshow(im2/255); 
        [x2(i),y2(i)] = ginput(1);
    end
end

disp("Figure 1 goi1 selected points are:")
disp([x1, y1])
disp("Figure 2 goi2 selected points are:")
disp([x2, y2])

%%% (b)
P2 = [x2; y2; ones(1,n)];
P1 = [x1; y1; ones(1,n)];
A = P2*P1'*inv(P1*P1');

disp("Matrix A:")
disp(A);

% Rotation, Scaling, Shearing
% Figure 1 goi1 selected points are:
% 202.3677  512.4066  277.6984  179.0214  316.9202  484.0798  264.9358  118.3210  424.9358  373.8852  367.3482  201.1226  256.7646  294.7412  251.4728  218.4767  219.4105  301.2782  175.8307  246.1809  178.3210   19.5661  210.0720  243.0681


% Figure 2 goi2 selected points are:
%   236.6089  570.6167  313.8074  212.9514  353.0292  537.3093  299.1770  150.6946  467.2704  414.3521  406.2588  162.5233  277.9319  313.7296  271.0837  238.0875  238.7101  321.5117  192.6401  266.4144  191.3949   32.0175  230.3054  255.2082


% Matrix A:
%     1.1047   -0.0012    1.2435
%    -0.0032    1.0283   12.6563
%          0         0    1.0000

% Matrix A:
A = [1.1047, -0.0012, 1.2435;
    -0.0032, 1.0283, 12.6563;
    0, 0, 1.0000];
%%% (c)
im3 = zeros(size(im1));

for i = 1:H 
    for j = 1:W 
        dxy = A\[j i 1]'; 
        xx = round(dxy(1)); 
        yy = round(dxy(2)); 
        
        if xx > 0 && xx <= W && yy > 0 && yy <= H 
            im3(i,j) = im1(yy,xx); % nearest neighbor interpolation
        end
    end
end

figure(1); imshow(im1/255);
figure(2); imshow(im2/255);
figure(3); imshow(im3/255);

% Save all the images
saveas(figure(1), 'nn_im1.png');
saveas(figure(2), 'nn_im2.png');
saveas(figure(3), 'nn_im3.png');

%%% (d)
im4 = zeros(size(im1));

for i = 1:H 
    for j = 1:W 
        dxy = A\[j i 1]'; 
        xx = round(dxy(1)); 
        yy = round(dxy(2)); 
        
        if xx > 0 && xx <= W && yy > 0 && yy <= H 
            w1 = (xx+1-dxy(1))*(yy+1-dxy(2));
            w4 = (dxy(1)-xx)*(dxy(2)-yy);
            w3 = (yy+1-dxy(2))*(dxy(1)-xx);
            w2 = (xx+1-dxy(1))*(dxy(2)-yy);
            im4(i,j) = im1(yy,xx)*w1+im1(yy+1,xx)*w2+im1(yy,xx+1)*w3+im1(yy+1,xx+1)*w4; 
        end
    end
end

figure(1); imshow(im1/255);
figure(2); imshow(im2/255);
figure(3); imshow(im4/255);

% Save all the images
saveas(figure(1), 'bilinear_im1.png');
saveas(figure(2), 'bilinear_im2.png');
saveas(figure(3), 'bilinear_im4.png');
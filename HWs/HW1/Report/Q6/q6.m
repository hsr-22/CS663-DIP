clear;
clc;

% Images
im1 = double((imread('.\..\..\goi1.jpg')));
im2 = double((imread('.\..\..\goi2_downsampled.jpg')));
[H,W] = size(im1);

%%% (a)
n = 12;

choice = 0;

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

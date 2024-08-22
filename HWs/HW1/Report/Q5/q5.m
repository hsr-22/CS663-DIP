clear;
clc;

% Images
J1 = im2double(imread('.\..\..\T1.jpg'));
J2 = im2double(imread('.\..\..\T2.jpg'));

%%% (a)
J3 = imrotate(J2, 28.5, 'bilinear', 'crop');
J3(isnan(J3)) = 0;

% Displaying and saving the image
figure, imshow(J3), title('Rotated Image J3')
imwrite(J3, 'J3.jpg', 'jpg')

%%% (b)
angles = -45:1:45;

ncc = zeros(size(angles));
je = ncc;
qmi = ncc;

for i = 1:length(angles)
    J4 = imrotate(J3, angles(i), 'bilinear', 'crop');
    J4(isnan(J4)) = 0;
    
    J4 = (J4 - mean(J4(:))) / std(J4(:));
    J1 = (J1 - mean(J1(:))) / std(J1(:));
    
    ncc(i) = sum(J1(:) .* J4(:)) / numel(J1);
    
    jointHist = histcounts2(J1(:), J4(:), 256);
    jointProb = jointHist / sum(jointHist(:));
    je(i) = -sum(jointProb(jointProb > 0) .* log2(jointProb(jointProb > 0)));
    
    qmi(i) = QMI(J1, J4);
end

function qmi = QMI(im1, im2)
    % Quadradic Mutual Information

    bins = 256;

    hist_1 = histcounts(im1, bins);
    hist_2 = histcounts(im2, bins);

    joint_hist = zeros(bins);

    for i = 1:size(im1, 1)
        for j = 1:size(im1, 2)
            joint_hist(im1(i, j) + 1, im2(i, j) + 1) = joint_hist(im1(i, j) + 1, im2(i, j) + 1) + 1;
        end
    end
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
    
    normJ4 = (J4 - mean(J4(:))) / std(J4(:));
    normJ1 = (J1 - mean(J1(:))) / std(J1(:));
    
    ncc(i) = sum(normJ1(:) .* normJ4(:)) / numel(J1);
    
    jointHist = histcounts2(normJ1(:), normJ4(:), 7); % 256^(1/3) bins approximately
    jointProb = jointHist / sum(jointHist(:));
    je(i) = -sum(jointProb(jointProb > 0) .* log2(jointProb(jointProb > 0)));
    
    P1 = sum(jointProb, 1);
    P2 = sum(jointProb, 2);
    P1P2 = zeros(length(P1));
    for j = 1:length(P1)
        for k = 1:length(P2)
            P1P2(j, k) = P1(j) * P2(k);
        end
    end
    qmi(i) = sum(sum((jointHist - P1P2).^2));
end

%%% (c)
figure; plot(angles, ncc);
title('NCC vs Angle');
xlabel('Angle (degrees)');
ylabel('NCC');
saveas(gcf, 'NCC_vs_Angle.jpg');

figure; plot(angles, je);
title('JE vs Angle');
xlabel('Angle (degrees)');
ylabel('JE');
saveas(gcf, 'JE_vs_Angle.jpg');

figure; plot(angles, qmi);
title('QMI vs Angle');
xlabel('Angle (degrees)');
ylabel('QMI');
saveas(gcf, 'QMI_vs_Angle.jpg');

%%% (d)
[~, nccIndex] = min(ncc);
[~, jeIndex] = min(je);
[~, qmiIndex] = max(qmi);

fprintf('Best NCC angle: %.2f degrees (NCC value: %.4f)\n', angles(nccIndex), ncc(nccIndex));
fprintf('Best JE angle: %.2f degrees (JE value: %.4f)\n', angles(jeIndex), je(jeIndex));
fprintf('Best QMI angle: %.2f degrees (QMI value: %.4f)\n', angles(qmiIndex), qmi(qmiIndex));

%%% (e)
optimJ4 = imrotate(J3, angles(jeIndex), 'bilinear', 'crop');
optimJ4(isnan(optimJ4)) = 0;

bins = 37;

histJ1 = histcounts(J1(:), bins);
histJ4 = histcounts(optimJ4(:), bins);

jointHist = zeros(bins);

for i = 1:size(J1, 1)
    for j = 1:size(optimJ4, 2)
        intensity_bin1 = floor(J1(i, j) * (bins - 1)) + 1;
        intensity_bin2 = floor(optimJ4(i, j) * (bins - 1)) + 1;
        jointHist(intensity_bin1, intensity_bin2) = jointHist(intensity_bin1, intensity_bin2) + 1;
    end
end

% Normalize the joint histogram to create a joint probability distribution
jointProb = jointProb / sum(jointHist(:));

% Plot the joint histogram
figure; imagesc(jointProb);
colormap jet;
colorbar;
xlabel('Intensity in J4 (Rotated)');
ylabel('Intensity in J1');
title('Joint Histogram between J1 and J4 (Optimal JE)');
axis xy;
 
% Save the plot as an image
saveas(gcf, 'JointHist_Optimal_JE.jpg');
tic;
clear; close all;

% Input images

barbara = im2double(imread('../images/barbara256.png'));
figure(1); imagesc(barbara); colormap("gray"); title("Original Image barbara256");
kodak = im2double(imread('../images/kodak24.png'));
figure(2); imagesc(kodak); colormap("gray"); title("Original Image kodak24");

% Make noisy images
std_devs = {5,10};
ctr = 3;
for k1 = 1:length(std_devs)
    StdDev = std_devs{k1} ; % noise standard deviation
    
    noisyBarbara = barbara + StdDev/255 * randn(size(barbara));
    noisyKodak = kodak + StdDev/255 * randn(size(kodak));
    
    figure(ctr); imagesc(noisyBarbara); colormap("gray"); title("Noisy barbara256 with \sigma_n = " + num2str(StdDev ));
    ctr = ctr+1;
    figure(ctr); imagesc(noisyKodak); colormap("gray"); title("Noisy kodak24 with \sigma_n = " + num2str(StdDev ));
    ctr = ctr+1;
    
    list_of_ss_sr = {{2,2},{3,15}} ;
    for k2 = 1:length(list_of_ss_sr)
        
        sigma_s = list_of_ss_sr{k2}{1};  %define sigma values as variable
        sigma_r = list_of_ss_sr{k2}{2};
        
        barbaraFiltered = RunMeanShift(noisyBarbara, sigma_s, sigma_r );
        kodakFiltered = RunMeanShift(noisyKodak, sigma_s, sigma_r );
        
        figure(ctr); imagesc(barbaraFiltered); colormap("gray");
        ctr = ctr+1;
        title("barbara256 - Mean shifted filter for \sigma_n = " + num2str(StdDev ) + ", \sigma_s = " + num2str(sigma_s) + ", \sigma_r = " + num2str(sigma_r));
        figure(ctr); imagesc(kodakFiltered); colormap("gray");
        ctr = ctr+1;
        title("kodak24 - Mean shifted filter for \sigma_n = " + num2str(StdDev ) + ", \sigma_s = " + num2str(sigma_s) + ", \sigma_r = " + num2str(sigma_r));
        
    end
end

toc;

function filtered_I = RunMeanShift(I, sig_s, sig_r)
filtered_I = zeros(size(I));  % initialize a black image of the same size as orignal image to store filtered output
[r, c] = size(I);


neigh = ceil(3 * sig_s) + 1;   %to define the neighbourhood for performing the filter
epsilon = 0.01;   %convergence criteria

for x = 1:c
    for y = 1:r
        feature_vector = [x, y, I(y, x)];
        %now iterate till convergence
        while true
            i1 = max(y - neigh, 1);
            i2 = min(y + neigh, r);
            j1 = max(x - neigh, 1);
            j2 = min(x + neigh, c);
            
            local_intensity = I(i1:i2, j1:j2);
            [X, Y] = meshgrid(j1:j2, i1:i2);
            
            Gaussian_s = exp(-((X - feature_vector(1)).^2 + (Y - feature_vector(2)).^2) / (2 * sig_s^2));  %bilateral filter gaussians
            Gaussian_r = exp(-((local_intensity - feature_vector(3)).^2) / (2 * sig_r^2));
            G = Gaussian_s .* Gaussian_r;
            
            
            fy = sum(G .* Y, 'all') / sum(G, 'all');
            fx = sum(G .* X, 'all') / sum(G, 'all');      %replace with the newly calculated intensities
            
            fI = sum(G .* local_intensity, 'all') / sum(G, 'all');
            
            if norm(feature_vector - [fx, fy, fI]) > epsilon
                feature_vector = [fx, fy, fI];
            else
                break;
            end
        end
        
        filtered_I(y, x) = feature_vector(3);
    end
end
end
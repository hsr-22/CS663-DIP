function BF = mybilateralfilter(I, sigs, sigr)
    BF = zeros(size(I));
    
    % bilateral filter window size
    BWby2 = ceil(3 * sigs);
    
    [rows, cols] = size(I);
    
    for x = 1:cols
        for y = 1:rows
            % window boundaries
            im = max(y - BWby2, 1);
            iM = min(y + BWby2, rows);
            jm = max(x - BWby2, 1);
            jM = min(x + BWby2, cols);
            
            localPatch = I(im:iM, jm:jM);
            
            % coordinate grids for the local patch
            [X, Y] = meshgrid(jm:jM, im:iM);
            
            % spatial Gaussian kernel
            Gs = exp(-((X - x).^2 + (Y - y).^2) / (2 * sigs^2));
            
            % range Gaussian kernel
            Gr = exp(-((localPatch - I(y, x)).^2) / (2 * sigr^2));
            
            BF(y, x) = sum(Gs .* Gr .* localPatch, 'all') / sum(Gs .* Gr, 'all');
        end
    end
end

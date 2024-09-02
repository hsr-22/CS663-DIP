clear;
clc;

% Images
im = imread('.\..\images\LC2.jpg');
im_copy = im;

dim_left = 7;
dim_right = 7;

mid_val = round((dim_left*dim_right)/2);

var = 0;

for i = 1:dim_left
    for j = 1:dim_right
        var = var+1;
        if (var == mid_val)
            m_pad = i-1;
            n_pad = j-1;
            break;
        end
    end
end

B = padarray(im,[m_pad,n_pad]);

for i = 1:size(B,1)-((m_pad*2)+1)
    for j = 1:size(B,2)-((n_pad*2)+1)
        cdf = zeros(256,1);
        inc = 1;
        for x = 1:dim_left
            for y = 1:dim_right        
                if (inc == mid_val)
                    ele = B(i+x-1,j+y-1)+1;
                end
                    pos = B(i+x-1,j+y-1)+1;
                    cdf(pos) = cdf(pos)+1;
                    inc = inc+1;
            end
        end
        for l = 2:256
            cdf(l) = cdf(l)+cdf(l-1);
        end
            im_copy(i,j) = round(cdf(ele)/(dim_left*dim_right)*255);
     end
end

imwrite(im_copy, '.\..\images\LC2_local_7.jpg');
figure,imshow(im_copy);
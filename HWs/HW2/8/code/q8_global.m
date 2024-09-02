function q8_global()
    im = imread('.\..\images\LC1.png');
    im_g = histeq(im);
    imwrite(im_g, '.\..\images\LC1_global.png');
    %imwrite(f,"LC2_histo_global.jpg");
    figure, imshow(im_g);
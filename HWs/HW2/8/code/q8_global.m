function q8_global()
    im = imread('.\..\images\LC2.jpg');
    im_g = histeq(im);
    imwrite(im_g, '.\..\images\LC2_global.png');
    %imwrite(f,"LC2_histo_global.jpg");
    figure, imshow(im_g);
clc,clear,close all

img_raw = imread('lena.jpg');

figure('Name','img_raw'),imshow(img_raw,[])

%% rgb2ycbcr
img_ycbcr = rgb2ycbcr(img_raw);

img_y  = img_ycbcr(:,:,1);
img_cb = img_ycbcr(:,:,2);
img_cr = img_ycbcr(:,:,3);

%% detail detected
kernel0 = fspecial('average',7);
blur0   = imfilter(img_y,kernel0);
details = img_y - blur0;

%% USM
alpha = 4;
img_sharp = img_y + alpha*details;

%% ycbcr2rgb
img_sharp_ycbcr = uint8(cat(3,img_sharp,img_cb,img_cr));
img_rgb = ycbcr2rgb(img_sharp_ycbcr);
figure('Name','img_rgb'),imshow(img_rgb,[])

%% ASOC (overshoot/undershoot control)
[rows,cols] = size(img_y);
padSize = 3;
alpha_white = 0.1;      % overshoot  gain
alpha_black = 0.1;      % undershoot gain
img_y_pad = zeros(rows+padSize*2,cols+padSize*2);
img_y_pad(1+padSize:rows+padSize,1+padSize:cols+padSize) = img_y;
for row = 1:rows
    for col = 1:cols
        row_ctr = row + padSize;
        col_ctr = col + padSize;

        win = img_y_pad(row_ctr-padSize:row_ctr+padSize,col_ctr-padSize:col_ctr+padSize);
        maxV = max(win(:));
        minV = min(win(:));

        if img_sharp(row,col) > maxV
            img_sharp(row,col) = maxV + alpha_white * (img_sharp(row,col) - maxV);
        elseif img_sharp(row,col) < minV
            img_sharp(row,col) = minV - alpha_black * (minV - img_sharp(row,col));
        else
            img_sharp(row,col) = img_sharp(row,col);
        end
    end
end

%% ycbcr2rgb
img_sharp_ycbcr = uint8(cat(3,img_sharp,img_cb,img_cr));
img_rgb = ycbcr2rgb(img_sharp_ycbcr);
figure('Name','img_rgb_ASOC'),imshow(img_rgb,[])





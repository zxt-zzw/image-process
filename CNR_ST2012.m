clear,clc,close all
path        = '.\';
fileName    = 'chroma_noise.png';
img_rgb     = imread(strcat(path,'\',fileName));

kernelSize  = [19,19];
img_ycbcr   = rgb2ycbcr(img_rgb);
[h,w,c]     = size(img_rgb);

%% 添加chroma noise噪声
% 生成高斯分布的均值为0、标准差为15的噪声向量
% mean_val    = 0;
% std_dev     = 3;
% noise1       = uint8(mean_val + std_dev * randn(size(img_ycbcr(:,:,1))));
% noise2       = uint8(mean_val + std_dev * randn(size(img_ycbcr(:,:,1))));
% img_ycbcr(:, :, 2) = img_ycbcr(:, :, 2) + noise1; 
% img_ycbcr(:, :, 3) = img_ycbcr(:, :, 3) + noise2; 
 
figure();
subplot(131),imshow(uint8(img_ycbcr(:,:,1))),title('Y');
subplot(132),imshow(uint8(img_ycbcr(:,:,2))),title('Cb');
subplot(133),imshow(uint8(img_ycbcr(:,:,3))),title('Cr');

%% pad
padSize = floor(kernelSize/2);
img_ycbcr_pad = double(padarray(img_ycbcr,padSize,'replicate','both'));
des_img = zeros(h,w,c);

sigmaY = 2;
sigmaCr= 2;
sigmaCb= 2;

Y_pad = img_ycbcr_pad(:,:,1);
Cb_pad= img_ycbcr_pad(:,:,2);
Cr_pad= img_ycbcr_pad(:,:,3);

%% color noise reduction
M = kernelSize(1);
N = kernelSize(2);
halfM = floor(M/2);
halfN = floor(N/2);

denoise_Cr = zeros(h,w);
denoise_Cb = zeros(h,w);
for row = 1+halfM:h+halfM
    for col = 1+halfN:w+halfN
        
        % 权重窗口处理
        WCrk_Arry = zeros(M,N);
        WCbk_Arry = zeros(M,N);
        
        for w_row = -halfM:halfM
            for w_col = -halfN:halfN
                WCrk_Y = exp(-1/2*abs(Y_pad(row+w_row,col+w_col)-Y_pad(row,col) / sigmaY));
                
                % Cr权重
                WCrk_Cr = exp(-1/2*abs(Cr_pad(row+w_row,col+w_col) - Cr_pad(row,col)) / sigmaCr);
                WCrk    = WCrk_Y * WCrk_Cr;
                
                WCrk_Arry(w_row+halfM+1,w_col+halfN+1) = WCrk;
                
                % Cb权重
                WCbk_Cb = exp(-1/2*abs(Cb_pad(row+w_row,col+w_col) - Cb_pad(row,col)) / sigmaCb);
                WCbk    = WCrk_Y * WCbk_Cb;
                
                WCbk_Arry(w_row+halfM+1,w_col+halfN+1) = WCbk;
            end
        end
        
        WCrk_Arry_Norm = WCrk_Arry ./ sum(WCrk_Arry,'all');
        WCbk_Arry_Norm = WCbk_Arry ./ sum(WCbk_Arry,'all');
        
        % 加权平均
        row_raw = row - halfM;
        col_raw = col - halfN;
        denoise_Cr(row_raw,col_raw) = sum(WCrk_Arry_Norm .* double(Cr_pad(row-halfM:row+halfM,col-halfN:col+halfN)),'all');
        denoise_Cb(row_raw,col_raw) = sum(WCbk_Arry_Norm .* double(Cb_pad(row-halfM:row+halfM,col-halfN:col+halfN)),'all');
    end
end

% output
des_img(:,:,1) = img_ycbcr(:,:,1);
des_img(:,:,2) = denoise_Cb;
des_img(:,:,3) = denoise_Cr;

des_img_rgb = ycbcr2rgb(uint8(des_img));
imwrite(des_img_rgb,strcat(path,'\',fileName(1:end-4),'_denoise_ST2012.png'));

figure
subplot(131),imshow(uint8(des_img(:,:,1))), title('desY');
subplot(132),imshow(uint8(des_img(:,:,2))), title('desCb');
subplot(133),imshow(uint8(des_img(:,:,3))), title('desCr');

figure('Name','原图')
imshow(img_rgb,[])

figure('Name','滤波图')
imshow(des_img_rgb,[])

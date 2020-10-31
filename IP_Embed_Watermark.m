clc
clear all

% Reading the cover image and watermark image

cvr_img = imread('check_img.jpg');  % cover image
wtmk_img = imread('watermark_img.jpg');  %watermark image

% converting the watermark image to gray level scale

wtmk_img = rgb2gray(wtmk_img);
figure(1); imshow(wtmk_img); title('gray scale watermark image');

% Applying Arnold Transform to watermark image

wtmk_img = arnold(wtmk_img,20);

% Displaying Image

figure(2); imshow(cvr_img); title('The image in which we insert watermark');
figure(3); imshow(wtmk_img); title('transformed watermark image to be embedded');

% Decomposition of red, green and blue component of the image

rmat = cvr_img(:,:,1);  % matrix of the red component
gmat = cvr_img(:,:,2);  % matrix of the green component
bmat = cvr_img(:,:,3);  % matrix of the blue component

% 2-level Discrete Wavelet Trasform on green component

[LLG1, HLG1, LHG1, HHG1] = dwt2(gmat, 'haar');
[LLG2, HLG2, LHG2, HHG2] = dwt2(LLG1, 'haar');

% 2-level Discrete Wavelet Trasform on blue component

[LLB1, HLB1, LHB1, HHB1] = dwt2(rmat, 'haar');
[LLB2, HLB2, LHB2, HHB2] = dwt2(LLB1, 'haar');

% Calculating the energy of LLG2

[LL2row, LL2col] = size(LLB2); % or [LL2row, LL2col] = size(LLG2)

sum_LLG2 = 0;
for i = 1:LL2row
    for j = 1:LL2col
        sum_LLG2 = sum_LLG2 + (LLG2(i,j))^2;
    end
end
LLG2en = sum_LLG2/(LL2row * LL2col);

sum_LLB2 = 0;
for i = 1:LL2row
    for j = 1:LL2col
        sum_LLB2 = sum_LLB2 + (LLB2(i,j))^2;
    end
end
LLB2en = sum_LLB2/(LL2row * LL2col);

% calculation of beta

bet = LLB2en/LLG2en;

% Selection of low frequency subband

if bet >= 1
    sLL2 = LLB2;
    alp = 10000;
    comp = "blue";
else
    sLL2 = LLG2;
    alp = 0.01;
    comp = "green";
end

% Embedding watermark in the selected subband

wtmk_img = im2double(wtmk_img);
for i = 1:50
    for j = 1:82
        sLL2(i,j) = sLL2(i,j) + alp*wtmk_img(i,j);
    end
end

% 2-level Inverse Discrete Wavelet Transform on the selected component

if comp == "blue"
    LLB1 = idwt2(sLL2, HLB2, LHB2, HHB2, 'haar');
    LLB1(:,346) = [];
    LLB1(140,:) = [];
    webc = idwt2(LLB1, HLB1, LHB1, HHB1, 'haar');
    % webc(278,:) = [];
    webc = uint8(webc);
else
    LLG1 = idwt2(sLL2, HLG2, LHG2, HHG2, 'haar');
    LLG1(:,298) = [];
    wegc = idwt2(LLG1, HLG1, LHG1, HHG1, 'haar');
    wegc(276,:) = [];
    wegc = uint8(wegc);
end    

% Resulting watermarked image

if comp == "blue"
    wtmked_img_mat = cat(3, rmat, gmat, webc);
else
    wtmked_img_mat = cat(3, rmat, wegc, bmat);
end

figure(4); imshow(wtmked_img_mat); title('Watermarked image');

%  Performance Evaluation Indexes of the Algorithm

psnrval = psnr(wtmked_img_mat,cvr_img)

% Arnold transform

function y=arnold(im,num)
[rown,coln]=size(im);
for inc=1:num
for row=1:rown
    for col=1:coln
        nrowp = row;
        ncolp=col;
        for ite=1:inc
            newcord =[1 1;1 2]*[nrowp ncolp]';
            nrowp=newcord(1);
            ncolp=newcord(2);
        end
        newim(row,col)=im((mod(nrowp,rown)+1),(mod(ncolp,coln)+1));  
    end
end
end
y=newim;
end
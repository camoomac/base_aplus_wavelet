function [ imgs ] =scaleup_wavelet_zeyde_L2( conf,imgs )
%UNTITLED3 Summary of this function goes here
%   Detailed explanation goes here
lamda = 0.01;

wavelet_name = conf.wavelet_name;
midres = resize(imgs, conf.upsample_factor, conf.interpolate_kernel);
midres_wave = cell([numel(midres) 1]);
for i=1:numel(midres)
    [midres_wave{i}(:,:,1),midres_wave{i}(:,:,2),midres_wave{i}(:,:,3),midres_wave{i}(:,:,4)] = dwt2(midres{i},wavelet_name);
end
for i=1:numel(imgs)
    features_all = collect(conf, midres_wave(i), conf.upsample_factor, conf.filters);
    result = cell(4,1);
    for j=1:4
        features = features_all((1:prod(conf.window)*conf.scale^2) + (j-1)*prod(conf.window)*conf.scale^2,:);
        if j==1
            dict_lores = conf.dict_loresLL;
            dict_hires = conf.dict_hiresLL;
        elseif j==2
            dict_lores = conf.dict_loresLH;
            dict_hires = conf.dict_hiresLH;
        elseif j==3
            dict_lores = conf.dict_loresHL;
            dict_hires = conf.dict_hiresHL;
        elseif j==4
            dict_lores = conf.dict_loresHH;
            dict_hires = conf.dict_hiresHH;
        end
        
        % L2 reconstruction
        A = dict_lores'*dict_lores;
        coeffs = (A + lamda*eye(size(A, 1))) \( dict_lores' * features);
        % Reconstruct using patches' dictionary 
        patches = dict_hires * full(coeffs) + collect(conf, {midres_wave{i}(:,:,j)}, conf.upsample_factor, {});
        % Combine all patches into one image
        img_size = size(midres_wave{i}(:,:,1));
        [grid,x,y] = sampling_grid(img_size, ...
        conf.window, conf.overlap, conf.border, conf.scale);
        result{j} = overlap_add(patches, img_size, grid);
        result{j}(1:conf.border(1)*conf.scale,:) = midres_wave{i}(1:conf.border(1)*conf.scale,:,j);
        result{j}(x+1:end,:) = midres_wave{i}(x+1:end,:,j);
        result{j}(:,1:conf.border(2)*conf.scale) = midres_wave{i}(:,1:conf.border(2)*conf.scale,j);
        result{j}(:,y+1:end) = midres_wave{i}(:,y+1:end,j);
    end
    imgs{i} = idwt2(result{1},result{2},result{3},result{4},wavelet_name); % for the next iteration
end
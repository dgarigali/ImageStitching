%% Script to run function (homog.m) that returns the projective transformation (i.e., homography) between each image and the reference image (i.e., first image) and registers and composes images into a single panoramic image 

%Clear screen and command window
clear;
clc;

%Read images from selected dataset
folder_name = 'datasets/translation/';
d = dir(strcat(folder_name, '*.jpg'));
image_list = cell(length(d),1);
for i=1:length(d)
    image_list{i} = strcat(folder_name, d(i).name);
end

%Obtain projective transformations
tic
[Homog] = homog(image_list);
toc

%Determine image corners in image 1 reference coordinate frame
world_pts_x = zeros(length(image_list), 4);
world_pts_y = zeros(length(image_list), 4);
for i=1:length(image_list)
    im = imread(image_list{i});
    [rows, cols, ~] = size(im);
    corners = [1 cols cols 1; 1 1 rows rows; ones(1, 4)];
    wrld_corners = Homog{i, 1} * corners;
    world_pts_x(i, :) = wrld_corners(1, :)./wrld_corners(3, :);
    world_pts_y(i, :) = wrld_corners(2, :)./wrld_corners(3, :);
end

%Calculate mosaic dimensions
minx = min(world_pts_x(:));
miny = min(world_pts_y(:));
maxx = max(world_pts_x(:));
maxy = max(world_pts_y(:));

%Build mosaic
mosaic = zeros([fix(maxy-miny+1) fix(maxx-minx+1) 3]);
mosaic2 = mosaic;
for i = 1:length(image_list)
    im2 = imread(image_list{i});
    tt = projective2d(Homog{i,1}');
    im3c1 = imwarp(uint8(ones(size(im2))),tt,'OutputView',imref2d([size(mosaic,1) size(mosaic,2)],[minx maxx],[miny maxy]));
    im3c = imwarp(im2,tt,'OutputView',imref2d([size(mosaic,1) size(mosaic,2)],[minx maxx],[miny maxy]));
    mosaic = mosaic + double(im3c);
    mosaic2 = mosaic2 + double(im3c1);
    imagesc((mosaic./mosaic2)/255);
    drawnow;
end
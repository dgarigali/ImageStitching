%Function that returns the projective transformation (i.e., homography) between each image and the reference image (i.e., first image)
function [H] = homog(image_list)
    
    %applies projective transformation
    function [H] = projective_transf(num_points)
        
        %Repeate each value of u1 and v1 twice
        u1_2 = [u1'; u1'];
        u1_2 = u1_2(:);
        v1_2 = [v1'; v1'];
        v1_2 = v1_2(:);

        %Preparing columns 7 and 8 of I1 matrix
        col_7 = (u1_2.*I2)*(-1);
        col_8 = (v1_2.*I2)*(-1);
        I1_3 = [col_7' ; col_8'];
        I1_3_odd = I1_3(:,1:2:end); %all rows, odd cols
        I1_3_even = I1_3(:,2:2:end); %all rows, even cols

        %Prepare I1 matrix
        I1_1 = [u1'; v1'; ones(1, num_points)];
        I1_2 = repmat(zeros(1,num_points), [3 1]);
        I1 = [I1_1; I1_2; I1_3_odd; I1_2; I1_1; I1_3_even];
        I1 = reshape(I1, [8, 2*num_points])';

        %GET Projective H model with DLT
        warning('off')
        H = (I1'*I1)\(I1'*I2);
        warning('on')
        H(9) = 1;
        H = reshape(H, [3,3])';
    end

    %load first image
    num_images = numel(image_list); 
    im1 = imread(image_list{1});
       
    %prepare output variables
    H = cell(num_images);
    H{1,1} = eye(3);
    
    % Setup RANSAC (determine number of iterations) 
    threshold = 49; %set threshold (|r_i|<epsilon) - inlier criteria
    bigP = 0.99; %probability of success after k tries
    smallP = 0.28; %fraction of matches that are inliers - pessimistic assumption
    K = ceil(log(1-bigP)/log(1-smallP^(4))); %number of iterations: formula from slides
    
    %loop for each sequential pair of images
    for i = 2:num_images
        
        %load next image
        im2 = imread(image_list{i});
       
    %--------%
    %  SURF  %
    %--------%    
        
        % Automatically select points based on SURF features
        [f1, vp1] = extractFeatures(rgb2gray(im1), detectSURFFeatures(rgb2gray(im1)));
        [f2, vp2] = extractFeatures(rgb2gray(im2), detectSURFFeatures(rgb2gray(im2)));
        [idxPairs, ~] = matchFeatures(f1, f2);
        p1 = double(vp1(idxPairs(:,1),:).Location); % [u1 v1]
        p2 = double(vp2(idxPairs(:,2),:).Location); % [u2 v2]

    %---------%
    %  RANSAC %
    %---------%
    
        % Prepare variables
        num_SURF_matches = length(p1(:, 1));
        max_inliers = 0;
        SURF_pts = [p1'; p2'];

        % Loop for RANSAC
        for k = 1:K

            %Randomly pick 4 points
            comb = randperm(num_SURF_matches, 4); 
            pickedPts = SURF_pts(:, comb(:))';
            u1 = full(pickedPts(:, 1));
            v1 = full(pickedPts(:, 2));
            u2 = full(pickedPts(:, 3));
            v2 = full(pickedPts(:, 4));

            %Prepare I2 vector and apply projective transformation
            I2 = [u2' ; v2'];
            I2 = I2(:);
            [H_model] = projective_transf(4);

            %Pass all points through the H_model transform
            pts1 = [p1'; ones(1, size(p1', 2))];
            pts2 = p2';
            pts2_ = full(H_model)*pts1; %pts1 has all image points [w1_2_; w2_2_;w3_2_ ] = H_model*[x1; y1; 1]
            pts2_ = [pts2_(1, :)./pts2_(3,:) ; pts2_(2, :)./pts2_(3,:)]; %[x2_ ; y2_]

            %Get difference from image2 actual points
            diff = pts2_ - pts2;   
            mod_diff = diag(diff'*diff); %diagonal values are norm^2
            
            %Count inliers and update best model accordingly (model with more inliers)
            num_inliers = sum(mod_diff < threshold); % - 4;
            if num_inliers > max_inliers
                max_inliers = num_inliers;

                %Save inliers, exclude pickedPts as well
                ransac_inliers = SURF_pts.*((mod_diff < threshold)'); %get only coordinates from inliers
                ransac_inliers(:, all(~ransac_inliers, 1)) = []; %remove empty cols
            end
        end
               
    %----------------------%
    %   Transformations    %
    %----------------------%
    
        %Split inliers coordinates
        u1 = ransac_inliers(1,:)';
        v1 = ransac_inliers(2,:)';
        u2 = ransac_inliers(3,:)';
        v2 = ransac_inliers(4,:)';
        
        %Get all inlier points
        num_points = length(u1);
        
        %Prepare I2 vector
        I2 = [u2' ; v2'];
        I2 = I2(:);
        
        %Apply homography
        [T_proj] = projective_transf(num_points);
                
    %---------------%
    %  H transform  %
    %---------------%
        H{i,i} = eye(3);
        for k = 1:i-1
            H{k,i} = T_proj*H{k,i-1};
            H{i,k} = inv(H{k,i});
        end     
        
        %Update image
        im1 = im2;        
    end
end
# ImageStitching

This project was developed for the Computer Vision course. The objective is to build a single panoramic image from a sequence of overlapping images in Matlab. For example, from the following sequence of five overlapping images:

![Screenshot](images/sequence.png)

we obtain the following panoramic image:

![Screenshot](images/result_from_sequence.png)

## Approach

The project was divided in two scripts: **homog.m** which consists of a function responsible for returning the projective transformation (i.e., homography) between each image and the reference image (i.e., first image) and **run.m** which calls the previous function and composes the single panoramic image based on the homographies.

To obtain the homographies, the script **homog.m** performs the following steps:

**Feature matching:** First, the SURF features of each consecutive pair of images (by using native Matlab methods) are matched by means of the Nearest Neighbour method. These matches represent keypoints that are common to the pair of images and are going to be used to obtain the projective transformation between them.

**Outlier rejection:** Usually, some matches are wrong (known as outliers) as one can see in the next image which contains 3 outliers highlighted with a red rectangle:

![Screenshot](images/before_RANSAC.png)

To remove the outliers, a method called RANSAC is performed. These method has the following steps:
1) Randomly select the minimum number of matches (pair of points) needed for the transformation
2) Estimate the parameters of the model based on those matches
3) Using the remaining matches and the model obtained in step 2, determine the transformation for each match point and calculate the error
4) Count the number of matches whose error is inferior to a given threshold (these points are known as inliers)
5) Repeat all formers steps for a given number of iterations and choose the matches that correspond to the highest number of inliers

For a 2D projective transformation (i.e., homography), the minimum number of points (for step 1) is 4, as it will be explained below. After applying RANSAC, the 3 ouliers are removed:

![Screenshot](images/after_RANSAC.png)




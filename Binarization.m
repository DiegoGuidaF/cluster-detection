%Author DiegoFG

pkg load image
graphics_toolkit('gnuplot')
clear all
close all


%cd "../Images/XMCD_051/Original(Divided)/"

%UI requesting the folder containing the images to process.
dname = uigetdir(pwd, 'Select Directory containing images')
files=dir(dname '/*.tif');

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%% Parameters%%%%%%%%%%%%%%%%%%%%%%
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
%Subimages/mesh
NBlockY=40;     %Double, sets number of image splittings in Y axis. Resulting mesh is NBlockX x NBlockY grid of subimages.
NBlockX=40;		%Double, sets number of image splittings in X axis.

%--Morphological filtering:
%Erosion/Dilatation process
DiskRad=1; 		%Erosion disk radius, augment if noise is accumulated
NErosions=2;		 %Number of erosions and dilatations done, good between 2-3
%--

%Final Noise Removal (Very important & time consuming)
MinClusterSize=350; 	%Sets the minimum cluster size. Noise clusters ~ 100-500.

%%Generic Filters
MedFilt=false;      %Boolean, enable/disable median filter.
GaussBlur=false;    %Boolean, enable/disable gaussian blur. Useful only if good contrast between noise/signal
GaussSpread=30; 	%Double, set GaussianBlur spread, smooths results but mixes noise with signal, dificulting the erosion process.
imgEq=false;        %Boolean, enable disable image histogram equalization. Useful if wanting to check results. Be sure to enable "img" writing.

%%%%Image characteristics%%%%
inverted=false;	    %Boolean, enable if the inverted domains are white instead of the expected black.
double_domain=false;%Boolean, enable if the original uncutted imaged contained multiple domains (In order to ignore blank area).

%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%

for k=1:numel(files)
     img=imread(files(k).name);
     [d f]= size(img);
     
	 %Cut until 10% of image avg value (Flatten causes edges to blur)
     %%Change to 1.5 if inverted. 0.5 if not.
     if double_domain %If image has a double domain, split them and process them.
        idxwhite= img > 40000;
        idxblack=img == 0;
        cropped=logical(idxwhite+idxblack);	
        if inverted
             val = 1.5;
        else
             val = 0.5;
        endif	  	
        img(idxwhite)=val*mean(mean(img(~cropped)));
        img(idxwhite)=imnoise(img,'gaussian')(idxwhite);
     endif
     thresh=0.1*mean(mean(img));
     
	 %
     %If upper border Found don't search for Bottom (same for left/right)
     UpperBorder=find(img(:,int16(f/2))>thresh,1,'first');
     BottBorder=find(img(:,int16(f/2))>thresh,1,'last');
     LeftBorder=find(img(int16(d/2),:)>thresh,1,'first');
     RightBorder=find(img(int16(d/2),:)>thresh,1,'last');
     %%Remove black borders from image
     img=img(UpperBorder:BottBorder,LeftBorder:RightBorder);
     %Make a mask with the exactly white pixels for later removal of them.
     if inverted
       img=65535-img;
     endif  
     
    %imshow(img)
    %%%%%%%%%%%%%%%%%%%%%	Filters %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    %%%%%% Filters don't improve results because they mix noise with information.%%
    %%%%%%% Better to remove it at the end with an erode/dilate process %%%%%%%%%%
    %%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%
    
    %Median filtering, check medfilt2 for more options
    if MedFilt
      img= medfilt2(img);
    endif  

    %Equalizing the histogram we improve the accuracy of the graythresh (Better Dynamic Range)
    %Useful when ilumination is mostly homogeneous
    if imgEq
      img=histeq(img);
    endif

     %Applies Gaussian Blurring to the image
    if GaussBlur
       f_gauss = fspecial("gaussian", 9,GaussSpread);
       img=imfilter(img,f_gauss);
     endif
       
    %The next process divides the image into a NBlockX x NBlockY mesh and
    %finds for each subimage the corresponding gray threshold.
     [r c]=size(img);
     resdX=r-NBlockX.*int16(r./NBlockX)
     resdY=c-NBlockY.*int16(c./NBlockY)
     if resdX < 0
       img(r:r+abs(resdX),:)=mean(mean(img));
     endif
     
     if resdY < 0
        img(:,c:c+abs(resdY))=mean(mean(img));
     endif 	 
     %The function we apply to each subimage
     funct=@(X) im2bw(X,graythresh(X,'moments'));
     %The short version of the subimage generation
     imgbw=blockproc(img,[int16(r/NBlockX),int16(c/NBlockY)], funct);
     %Remove posible paddings (Bottom and right ones)
     imgbw=imgbw(1:r,1:c);
     
     if inverted
       idxwhite=idxwhite(1:r,1:c);
     %Remove the detected spots where initial image was exactly white (Cut out).
       imgbw(idxwhite)=1;
     endif 
     %Create the structure (a disk) used to erode/dilate each pixel.
     SE = strel('disk',DiskRad);
     %Erotions are needed in order to make noise fully dissapear when noise signal is similar to information's signal.
     for n=1:NErosions
        imgbw = ~imerode(~imgbw,SE);
     endfor  
     %%Same Nº of dilatations to restore information total area.
     for m=1:NErosions
       imgbw =~imdilate(~imgbw,SE);
      endfor   
     %
     %We remove addittional noise by removing objets with area less than N-pixels
     %Eliminates whites (So we use the ~ operand to invert the bits)
     %imgbw=~(bwareaopen(~imgbw,MinClusterSize));
     
     %Finally we get the black area of each image
     %%A(k) = sum(sum(~imgbw))/(r*c-sum(sum(idxwhite)))*100;
     %%imwrite(imgbw, ['Final/' files(k).name]);
     %figure,  imshow(imgbw)
     %imwrite(img, ['Equalized/Equal_' files(k).name]);
end  

    %We save the black area of each image column-wise
     %A=A';
     %%save black_area.txt A
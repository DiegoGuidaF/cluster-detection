pkg load image
graphics_toolkit('gnuplot')
clear all
close all


cd "/home/diego/Dropbox/Universidad/TFG/Informe/Images/XMCD_051/Processed/"
workdir=pwd;
files=dir('*.TIF');
temp=zeros(500,numel(files));
Nucleation=zeros(numel(files),1,'uint8');
NuclMatrix=zeros(2048,"uint8");
NuclMask= NuclMatrix;
NuclThresh=3;
ExpansionCoal=zeros(numel(files),1,'uint8');
Coalescence=zeros(numel(files),1,'uint8');
Expansion=zeros(numel(files),1,'uint8');
Expansion_area=zeros(numel(files),1);
Coalescence_area=zeros(numel(files),1);
Coalescence_mask=zeros(2048,"uint8");
Expansion_mask=zeros(2048,"uint8");
Expansion_maskbak=0;
Coalescence_maskbak=0;
notExpansion=zeros(numel(files),1,'uint8');
MaxNAreas=0;
Error_Area=0.20 #Error  percentage
for k=1:numel(files)
    %disp(files(k).name)
     img=imread(files(k).name);
     #Siguiente Tarea:
     #Guardar las areas de la img_ant para en la imagen siguiente comparar la nueva area por si solo coalesce, coalesce y expande, o solo expande.
     #La idea es aadir el check al comprobar coalescencia y luego al comprobar expansion.
     #Para hacerlo, utilizar la funcin"(prop_ant(k).Area + prop_ant(j) >= prop_nuevo(k))"
     %prop=regionprops(~img,'area');
     %temp(1:size(prop,2),k)=[prop.Area];
     %NAreas=size(prop,2);
    %
     %MaxNAreas=max(NAreas,MaxNAreas);
     NuclMask(NuclMask != 2) = 0; #Reset all non nucleated clusters.
     if k == 1
        [label_ant, num_labels_ant]=bwlabel(!img);
        prop_ant=regionprops(~img,'area');
       temp(1:size(prop_ant,2),k)=[prop_ant.Area];
       NAreas=size(prop_ant,2);
    
       MaxNAreas=max(NAreas,MaxNAreas);
     endif
        
     if k>=2
         #Get which image is smaller in order to avoid out of bounds errors	
         dim1=min(size(img,1),size(imgbak,1));
         dim2=min(size(img,2),size(imgbak,2));
         k
         if dim1 > size(label_ant,1)
         	disp("Resizing")
	dim1-size(label_ant,1)
	disp("")
         	label_ant=resize(label_ant,dim1,size(label_ant,2));
	NuclMatrix=resize(NuclMatrix,dim1,size(NuclMatrix,2));
	NuclMask=resize(NuclMask,dim1,size(NuclMask,2));
	
         endif	
         
         if dim2 > size(label_ant,2)
         	disp("Resizing")
	dim2-size(label_ant,2)
	disp("")
         	label_ant=resize(label_ant,size(label_ant,1),dim2);
	NuclMatrix=resize(NuclMatrix,size(NuclMatrix,1),dim2);
	NuclMask=resize(NuclMask,size(NuclMask,1),dim2);
	
         endif	
         	
         #Obtain objects boundaries
         #boundaries=bwboundaries(img);
         #We assign different numbers to each different cluster
         #In order to compare images with same size, we cut the border of the biggest one.
         [labels,num_labels]=bwlabel(!img(1+size(img,1)-dim1:end,1+size(img,2)-dim2:end));
         prop=regionprops(!img(1+size(img,1)-dim1:end,1+size(img,2)-dim2:end),'area');
         temp(1:size(prop,2),k)=[prop.Area];
         NAreas=size(prop,2);
    
         MaxNAreas=max(NAreas,MaxNAreas);
         label_ant=label_ant(1+size(label_ant,1)-dim1:end,1+size(label_ant,2)-dim2:end);
         cluster=logical(zeros(dim1,dim2));
         NuclMatrix=NuclMatrix(1+size(NuclMatrix,1)-dim1:end,1+size(NuclMatrix,2)-dim2:end);
         NuclMask=NuclMask(1+size(NuclMask,1)-dim1:end,1+size(NuclMask,2)-dim2:end);
         Expansion_mask=Expansion_mask(1+size(Expansion_mask,1)-dim1:end,1+size(Expansion_mask,2)-dim2:end);
         Coalescence_mask=Coalescence_mask(1+size(Coalescence_mask,1)-dim1:end,1+size(Coalescence_mask,2)-dim2:end);
         #We iterate over the number of clusters on the new image
  	#disp('Image:'), disp(k)
  	#disp('Clusters:'), disp(num_labels)
         for j=1:size(prop,2)
         	NucleatedCluster(j)=0;
         	#disp('Cluster:'),disp(j)
         	cluster= ( labels == j ); % Extract each cluster individually
         	prevclusters=unique(label_ant(cluster)); %Check with which clusters from prev. img. it collides.
         	#If only collides with cluster of 0's, means it's background-> Nucleation
         	#if ((any(unique(NuclMatrix(cluster)) <= NuclThresh)) && any(any(NuclMatrix(cluster)))) && any(NuclMask != 2) || all(prevclusters == 0)
         	#If here wasn't a cluster before or if there is, but the NuclMask doesn't see anything already nucleated there:
         	if all(prevclusters == 0) || all(NuclMask(cluster) != 2)
         		#Nucl_Area(k,j) = sum(NuclMatrix(cluster)  <= NuclThresh & NuclMatrix(cluster) != 0);
         		NuclMatrix(cluster) = NuclMatrix(cluster) + 1;
		if all(prevclusters == 0) 
			NuclMask(cluster) = 1;
			NuclMatrix(cluster)=1;
		elseif any(NuclMatrix(cluster) == NuclThresh)
			Nucleation(k) = Nucleation(k) + 1;
			NuclMatrix(cluster)=0;
			NuclMask(cluster) = 2;
			#Expansion_mask(cluster)=1;
#			disp("Nucleation")
#			NuclatedCluster(j)=NuclMatrix(cluster);
		elseif any(NuclMatrix(cluster) < NuclThresh)
			NuclMask(cluster) = 1;
		endif	

			
         	#If its two numbers distinct from 0 or 3 numbers, it's coalescence         
         	elseif (length(prevclusters) > 2 && any(NuclMask(cluster) == 2)) || ((length(prevclusters) > 1) && !any(prevclusters == 0) && any(NuclMask(cluster) == 2))
         		#disp('Coalescence');
         		Coalescence(k)=Coalescence(k) +1;
         		#If the coalesced area is greater than the one from previous clusters, add expansion as an event.  			
         		#Coalescence_area(k)=Coalescence_area(k) + (prop(j).Area - sum([prop_ant(prevclusters(prevclusters != 0)).Area]));
		Coalescence_mask(cluster)=1;

         		NuclMask(cluster) == 2;
         		
         	elseif (length(prevclusters) == 2 && any(NuclMask(cluster) == 2)) || ((length(prevclusters) == 1) && !any(prevclusters == 0) && any(NuclMask(cluster) == 2))
         		#disp('Expansion');
      		 NuclMask(cluster) == 2;
         	      	            	      	
         		if prop(j).Area > sum([prop_ant(prevclusters(prevclusters != 0)).Area])*(1+Error_Area)
         			Expansion(k) = Expansion(k) +1;
         			#Expansion_area(k)=Expansion_area(k) + ((prop(j).Area - sum([prop_ant(prevclusters(prevclusters != 0)).Area])));
      			Expansion_mask(cluster)=1;
         		else
         			notExpansion(k)= notExpansion(k)+1;		
         		endif	
         		
         	else
         		disp('Unknown')
         	endif          
         endfor
         NuclMatrix(NuclMask == 0) = 0; #Where there weren't any clusters, reset it to 0.
        prop_ant=prop;
        label_ant=labels;
        Expansion_area(k) = sum(sum(Expansion_mask)) - Expansion_maskbak;
        Coalescence_area(k) = sum(sum(Coalescence_mask)) - Coalescence_maskbak;
        Expansion_maskbak = sum(sum(Expansion_mask));
        Coalescence_maskbak = sum(sum(Coalescence_mask));
         #Obtain differences btw images
         #diff=abs(img(1:dim1,1:dim2)-imgbak(1:dim1,1:dim2));
         #index=false
         %for j=1:size(boundaries,1)
           %Amin(j,:)=min(boundaries{j,:});
           %Amax(j,:)=max(boundaries{j,:});
         %endfor
        endif 
        imgbak=img;
endfor
Areas=temp(1:MaxNAreas,:);

%save "areas.txt" Areas
csvwrite("areas.txt",Areas)
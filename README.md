# cluster-detection
Octave algorithm used for automatically detecting clusters in stacks of low-contrast images.

## Binarization.m
Algorithm used to detect clusters in a gray image. Clusters of information should have a higher level of intensity than background otherwise specify if the opposite is true by setting the parameter "inverted" to true.

 I/O:
 
* Input: Folder containing .tif images to analized.
* Output: Each image under a new folder "Final".
  
## DomainAnalisis.m
Algorithm used to follow cluster evolution through the images. Nucleation, Expansion and Coalescence events are tracked by comparing the images. Images should be alphabetically ordered by default.

Events:

* Nucleation: When a cluster appears where there was none before. Has to remain for NuclThresh Nº of images to be considered. Otherwise discarded as noise.
* Expansion: When a cluster total area increases above the Error_Area parameter. It is considered to have increased size and therefore expanded.
* Coalescence: When two or more clusters suddenly merge together into one. From that point on, the clusters are to be considered a single one.

I/O:

* Input: Folder containing the alphabetically ordered images.
* Output: Table with the Nº of events per image as well as the total cluster area.

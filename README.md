%%%%%%%% Hello welcome to the repository for my Driveline Open Biomechanics work in progress project %%%%%%%%%

The goal of this project is to allow me to develop and showcase my experience working with biomechanics data.

This respository features a number of MATLAB functions and a front end script that I have created to read and analyze the data.

In order to run the functions you will need the BTK folder in the saem file path as well as a path to the folder where the Driveline c3d files are located.

DL_Frontend is the script to call on the functions and is very straightforward.

DL_batch reads the c3d folder and creates a data struct of all of the batting files excluding the last file in each folder (which is the static trial) using the DL_read function.

Inside the DL_read function is the all of the other functions used to pull key metrics and add them to the struct.

the DL_animateDatabase is the final function used to generate the report which includes a stick figure animation of a selected swing session
and compares the bat speed profile and X-factor to sessions above a certian bat speed threshold on the right graphs.

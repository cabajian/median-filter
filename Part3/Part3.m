%clear existing variables, close any figure windows, clear the command line
close all
clear all
clc

% Read image
filename = 'Lena.pgm';
im_orig = imread(filename);
im_orig_info = imfinfo(filename);
numRows = im_orig_info.Height;
numCols = im_orig_info.Width;
imgSize = numRows * numCols;
z = floor(imgSize/20);

% Clear any existing serial ports
delete(instrfind);

% Create a serial port object
serialPort = serial('COM8', 'BaudRate', 115200, 'DataBits', 8, 'Parity', 'none', 'StopBit', 1, 'OutputBufferSize', imgSize, 'InputBufferSize', imgSize);

% open the serial port for reading/writing
fopen(serialPort);

% send image to the FPGA

% FULL SPEED
fprintf('Sending Write Command to FPGA... '); tic;
fwrite(serialPort, hex2dec('01'), 'uint8'); toc;

fprintf('Sending Number of Rows to FPGA... '); tic;
fwrite(serialPort, numRows, 'uint16'); toc;

fprintf('Sending Number of Columns to FPGA... '); tic;
fwrite(serialPort, numCols, 'uint16'); toc;

fprintf('Sending Image Size to FPGA... '); tic;
fwrite(serialPort, imgSize, 'uint32'); toc;

fprintf('Writing Image Data to FPGA... '); tic;
fwrite(serialPort, im_orig(:)); toc;

% request FPGA filters the image
fprintf('Sending Filter Command to FPGA... '); tic;
fwrite(serialPort, hex2dec('04'), 'uint8'); toc;

% read data back from the FPGA
fprintf('Sending Readback Command to FPGA... '); tic;
fwrite(serialPort, hex2dec('02'), 'uint8'); toc;

fprintf('Reading back from FPGA... '); tic;
im_final = fread(serialPort, imgSize, 'uint8'); toc;

% read back filtered image from FPGA
fprintf('Sending Filter-Readback Command to FPGA... '); tic;
fwrite(serialPort, hex2dec('03'), 'uint8'); toc;

fprintf('Reading back from FPGA... '); tic;
% TODO Modify the second parameter to match the size of the filtered image
im_final_filtered = fread(serialPort, imgSize-2*numCols, 'uint8'); toc;

im_final = reshape(im_final, [numRows numCols]);
% TODO Modify numRows and numCols to match the size of the filtered image
im_final_filtered_rs = reshape(im_final_filtered, [numRows numCols-2]);

% close the serial port
fclose(serialPort);

% Analyze and display results
if isequal(im_orig, im_final)
    fprintf('SUCCESS!\n');
    subplot(1,3,1);
    imshow(mat2gray(im_orig));
    title('Original');
    subplot(1,3,2);
    imshow(mat2gray(im_final));
    title('Received');
    subplot(1,3,3);
    imshow(mat2gray(im_final_filtered_rs));
    title('Filtered');
else
    fprintf('FAILURE!\n');
end

//////////////////////////////////////////////////////////////////////////////////
// Company: UofT - ISML
// Engineer: Motasem Ahmed Sakr
//
// Create Date: 11/15/2020 03:10:24 PM
// Design Name:
// Module Name: Mask Generation Top (MG)
// Project Name: T7
// Target Devices:
// Tool Versions:
// Description:
//
// Dependencies:
//
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
//
//////////////////////////////////////////////////////////////////////////////////
// Cols is the important factor from Image Sensor Resolution as we generate the mask row by row. Rows number is not important.
// Supported Image Sensors
// Image Sensor Resolution: Cols x Rows
// T4/6: 320 x 320
// VGA : 640 x 480
// HD  : 1280 x 720
// FHD : 1920 x 1080


module mask_generation_VGA
(
	input clk,    // Clock
	input clk_en, // Clock Enable
	input rst_n,  // Asynchronous reset active low

	// Pattern Input passed through the micro-processor
	input [4:0] pattern_w, 	// size of the pattern W 
	input pattern,	// Bits for the repeated pattern (0: pixel 0 in row n, 1: pixel 0 in row n, ..., 31: pixel 31 in row n )
	input right_sliding,	// Direction of sliding 1-- right / 0 -- left
	input load_pattern, 	// to load the pattern for repetition

	input mask_type,	// Choose the type of mask between sliding pattern 0 - Random Mask 1 

	output logic [0:639] mg_mask,
	output logic [0:639] mg_mask_n,

	output logic rp_valid // Valid signal for the output
);

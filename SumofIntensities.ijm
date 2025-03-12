Table.create("Final Results");
run("Set Measurements...", "integrated redirect=None decimal=0");
run("Options...", "iterations=4 count=1 pad do=Nothing");


//allow user to select folder
Dialog.create("Choose A Folder");
Dialog.addDirectory("Images Folder", "");
Dialog.show();
path = Dialog.getString();

setBatchMode(true);


//runs the function on all czi files in the folder
files = getFileList(path);
for (i = 0; i < files.length; i++) {
	if (endsWith(files[i], ".czi")) {
		run("Bio-Formats Importer", "open=["+path+files[i]+"] color_mode=Default rois_import=[ROI manager] view=Hyperstack stack_order=XYCZT");
		name = getTitle();
		results = MeasureCell(name);
		size = Table.size("Final Results");
		Table.set("Name", size, name, "Final Results");
		Table.set("IntDen", size, results[0], "Final Results");
		Table.set("RawIntDen", size, results[1], "Final Results");
		Table.set("#ROIs", size, results[2], "Final Results");
		close("*");
	}
}

print("Finished!");

function MeasureCell(name) {
	// returns the sum of intensities within the RNA cloud in the cell
	rename("Image");
	run("Split Channels");
	selectImage("C2-Image");
	close;
	selectImage("C1-Image");
	setSlice(round(nSlices/2));
	run("Enhance Contrast", "saturated=0.05");
	setAutoThreshold("Otsu dark 16-bit no-reset");
	setOption("BlackBackground", false);
	run("Convert to Mask", "method=Otsu background=Dark create");
	run("Options...", "iterations=4 count=1 pad do=Nothing");
	run("Dilate", "stack");
	run("Fill Holes", "stack");
	run("Erode", "stack");
	run("Analyze Particles...", "size=0.3-Infinity add stack");
	selectImage("MASK_C1-Image");
	close;
	selectImage("C1-Image");
	resetThreshold;

	roiManager("Deselect");
	roiManager("Measure");
	
	IntDen = 0;
	IntDenArray = Table.getColumn("IntDen", "Results");
	for (ii = 0; ii < IntDenArray.length; ii++) {
		IntDen = IntDen + IntDenArray[ii];
	}
	
	RawIntDen = 0;
	RawIntDenArray = Table.getColumn("RawIntDen", "Results");
	for (ii = 0; ii < IntDenArray.length; ii++) {
		RawIntDen = RawIntDen + RawIntDenArray[ii];
	}
	
	//print(IntDen);
	//print(RawIntDen);
	
	results = newArray(IntDen, RawIntDen, roiManager("count"));
	
	roiManager("Save", path+name+"RoiSet.zip");
	run("Clear Results");
	roiManager("reset");
	return results;
}


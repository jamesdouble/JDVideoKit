![Alt text](https://raw.githubusercontent.com/jamesdouble/JDSwiftHeatMap/master/Readme_img/logo.png?token=AJBUU8PbfD_WRNgAB4UEqbt1vDhm2iS3ks5ZbgTowA%3D%3D)

**JDVideoKit** 

![Alt text](https://img.shields.io/badge/SwiftVersion-3.0+-red.svg?link=http://left&link=http://right)
![Alt text](https://img.shields.io/badge/IOSVersion-9.0+-green.svg)
![Alt text](https://img.shields.io/badge/BuildVersion-1.0.0-green.svg)
![Alt text](https://img.shields.io/badge/Author-JamesDouble-blue.svg?link=http://https://jamesdouble.github.io/index.html&link=http://https://jamesdouble.github.io/index.html)

# Introduction

# USAGE

### 1.[Use My Two Layout](#use-my-two-layout)

### 2.[Use Only Capturing Layout](#use-only-capturing-layout)

### 3.[Use Only Editing Layout](#use-only-editing-layout)

### 4.[Convert Video Directly](#convert-video-directly)

## Delegate

```
public protocol JDVideoKitDelegate {
    //1.If return nil means call JDProcessingViewController
    func videoResource(forkit kit:JDVideoKit)->Any?
    
    //2.Only will call when above function return nil. Can make some setting for JDProcessingViewController
    func willPresent(cameraViewController vc:JDProcessingViewController,forkit:JDVideoKit)->JDProcessingViewController
    
    //3.Can make some setting for JDPresentingViewController, if return nil jump to next delegate
    func willPresent(edtingViewController vc:JDPresentingViewController,originVideo:AVAsset,forkit:JDVideoKit)->JDPresentingViewController?
    
    //4.Set your type
    func ConvertType(forVideo resource:Any,forkit:JDVideoKit)->videoProcessType
    
    //5.Call When user click save.
    func FinalOutput(final video:AVAsset,url:URL)
}

```

1.***(NonOptional)*** 

Return the video resource if you allready have one. 
Return nil, will call Capturing Layout.
	 
2.***(Optional)***

You can make some setting to customize [ProcessingViewController](#convert-video-directly) and return it.

3.***(Optional)***

You can make some setting to customize [PresentingViewController](#convert-video-directly) and return it.




### Use My Two Layout

You may not have 


### Use Only Capturing Layout

### Use Only Editing Layout

### Convert Video Directly

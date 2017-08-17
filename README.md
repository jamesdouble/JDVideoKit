![Alt text](https://raw.githubusercontent.com/jamesdouble/JDVideoKit/master/Readme_img/logo.png?token=AJBUU5gmbNsF0N3vztr8i0SF0ctX6HR5ks5Znj7cwA%3D%3D)

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

```swift
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

1. ***(NonOptional)*** 

Return the video resource if you allready have one and Skip to Delegate 3.

Return nil, will call Capturing Layout.
	 
2. ***(Optional)***

You can make some setting to customize [ProcessingViewController](#convert-video-directly) and return it.

3. ***(Optional)***

Call when Capturing Finish.

You can make some setting to customize [PresentingViewController](#convert-video-directly) and return it.

Return nil if you don't need edting layout and end it here.

4. ***(Optional)***

Specific the Convert type. **(.Boom , .Speed , .Reverse)**

5. ***(NonOptional)*** 

Call When user click save button in Editing Layout or direct transfer complete.

---
### Use My Two Layout -> Implement 1 , 5
```swift
class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        let vk = JDVideoKit(delegate: self).getProperVC()
        self.present(vk, animated: true, completion: nil)
    }
}
extension ViewController:JDVideoKitDelegate
{
    func videoResource(forkit kit: JDVideoKit) -> Any? {
        return nil
    }
    func FinalOutput(final video:AVAsset,url:URL)
    {
        print(url)
    }
}
```

### Use Only Capturing Layout -> Implement 1 , 3 , 4 , 5
```swift
class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        let vk = JDVideoKit(delegate: self).getProperVC()
        self.present(vk, animated: true, completion: nil)
    }
}
extension ViewController:JDVideoKitDelegate
{
    func videoResource(forkit kit: JDVideoKit) -> Any? {
        return nil
    }
    func FinalOutput(final video:AVAsset,url:URL)
    {
        
    }
    func willPresent(edtingViewController vc: JDPresentingViewController, originVideo: AVAsset, forkit: JDVideoKit) -> JDPresentingViewController? {
        return nil
    }
    func ConvertType(forVideo resource: Any, forkit: JDVideoKit) -> videoProcessType {
        return .Boom
    }
}
```

### Use Only Editing Layout -> Implement 1 , 5

```swift
class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        let vk = JDVideoKit(delegate: self).getProperVC()
        self.present(vk, animated: true, completion: nil)
    }
}
extension ViewController:JDVideoKitDelegate
{
    func videoResource(forkit kit: JDVideoKit) -> Any? {
        return URL( url or asset of video)
    }
    func FinalOutput(final video:AVAsset,url:URL)
    {
        print(url)
    }
}
```

### Convert Video Directly -> Implement 1 , 4 , 5
```swift
class ViewController: UIViewController {
    override func viewDidAppear(_ animated: Bool) {
        let vk2 = JDVideoKit(delegate: self)
        vk2.getVideoDirectly { (progress) in
            print(progress)
        }
    }
}
extension ViewController:JDVideoKitDelegate
{
    func videoResource(forkit kit: JDVideoKit) -> Any? {
        return URL( url or asset of video)
    }
    func FinalOutput(final video:AVAsset,url:URL)
    {
        print(url)
    }
    func ConvertType(forVideo resource: Any, forkit: JDVideoKit) -> videoProcessType {
        return .Boom
    }
}

```
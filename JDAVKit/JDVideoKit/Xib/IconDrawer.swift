//
//  IconDrawer.swift
//  JDVideoKit
//
//  Created by 郭介騵 on 2017/8/4.
//  Copyright © 2017年 james12345. All rights reserved.
//

import UIKit

class IconDraw: UIView {
    override init(frame: CGRect)
    {
        super.init(frame: frame)
        self.backgroundColor = UIColor.clear
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.backgroundColor = UIColor.clear
    }
    
    override func prepareForInterfaceBuilder() {
        self.backgroundColor = UIColor.clear
    }

}

@IBDesignable class FlashIconDraw:IconDraw
{
    @IBInspectable var testcolor:UIColor = UIColor.black
    
    
    func CGPointMake(_ x:CGFloat,_ y:CGFloat)->CGPoint
    {
        let originWidth:CGFloat = 30
        let originHeight:CGFloat = 47
        
        let swidth = self.frame.width
        let sheight = self.frame.height
        
        let sx = x * (swidth / originWidth)
        let sy = y * (sheight / originHeight)
        
        return CGPoint(x: sx, y: sy)
    }
    

    override func draw(_ rect: CGRect) {
        let layers = CAShapeLayer()
        layers.fillColor = UIColor.white.cgColor
        layers.path = drawCanvas1()
        self.layer.addSublayer(layers)
    }
    
    func drawCanvas1()->CGPath
    {
        //// flash.svg Group
        //// Group 2
        //// Group 3
        //// Bezier 2 Drawing
        var bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPointMake(29.85, 16.12))
        bezier2Path.addCurve(to: CGPointMake(29.05, 15.67), controlPoint1: CGPointMake(29.71, 15.84), controlPoint2: CGPointMake(29.39, 15.67))
        bezier2Path.addLine(to: CGPointMake(18.6, 15.67))
        bezier2Path.addLine(to: CGPointMake(28.91, 1.2))
        bezier2Path.addCurve(to: CGPointMake(28.94, 0.41), controlPoint1: CGPointMake(29.09, 0.96), controlPoint2: CGPointMake(29.1, 0.66))
        bezier2Path.addCurve(to: CGPointMake(28.17, 0), controlPoint1: CGPointMake(28.79, 0.16), controlPoint2: CGPointMake(28.49, 0))
        bezier2Path.addLine(to: CGPointMake(14.05, 0))
        bezier2Path.addCurve(to: CGPointMake(13.26, 0.43), controlPoint1: CGPointMake(13.72, 0), controlPoint2: CGPointMake(13.41, 0.17))
        bezier2Path.addLine(to: CGPointMake(0.03, 23.93))
        bezier2Path.addCurve(to: CGPointMake(0.07, 24.69), controlPoint1: CGPointMake(-0.11, 24.18), controlPoint2: CGPointMake(-0.1, 24.46))
        bezier2Path.addCurve(to: CGPointMake(0.82, 25.07), controlPoint1: CGPointMake(0.23, 24.93), controlPoint2: CGPointMake(0.51, 25.07))
        bezier2Path.addLine(to: CGPointMake(9.89, 25.07))
        bezier2Path.addLine(to: CGPointMake(0, 45.91))
        bezier2Path.addCurve(to: CGPointMake(0.36, 46.88), controlPoint1: CGPointMake(-0.17, 46.27), controlPoint2: CGPointMake(-0.02, 46.68))
        bezier2Path.addCurve(to: CGPointMake(0.81, 47), controlPoint1: CGPointMake(0.5, 46.96), controlPoint2: CGPointMake(0.66, 47))
        bezier2Path.addCurve(to: CGPointMake(1.49, 46.72), controlPoint1: CGPointMake(1.07, 47), controlPoint2: CGPointMake(1.32, 46.9))
        bezier2Path.addLine(to: CGPointMake(29.73, 16.96))
        bezier2Path.addCurve(to: CGPointMake(29.85, 16.12), controlPoint1: CGPointMake(29.95, 16.72), controlPoint2: CGPointMake(30, 16.4))
        bezier2Path.close()
        bezier2Path.miterLimit = 4;

        bezier2Path.fill()
        return bezier2Path.cgPath
    }
}


@IBDesignable class SwitchIconDraw:IconDraw
{
 
    func CGPointMake(_ x:CGFloat,_ y:CGFloat)->CGPoint
    {
        let originWidth:CGFloat = 40
        let originHeight:CGFloat = 29
        
        let swidth = self.frame.width
        let sheight = self.frame.height
        
        let sx = x * (swidth / originWidth)
        let sy = y * (sheight / originHeight)
        
        return CGPoint(x: sx, y: sy)
    }
    
    override func draw(_ rect: CGRect) {
        let layers = CAShapeLayer()
        layers.fillColor = UIColor.white.cgColor
        layers.path = drawCanvas1()
        self.layer.addSublayer(layers)
        
        let layers2 = CAShapeLayer()
        layers2.fillColor = UIColor.white.cgColor
        layers2.path = drawCanvas2()
        self.layer.addSublayer(layers2)
    }
    
    func drawCanvas1()->CGPath
    {
        //// flash.svg Group
        //// Group 2
        //// Group 3
        //// Bezier 2 Drawing
        let bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPointMake(31.51, 0))
        bezier2Path.addLine(to: CGPointMake(30.2, 0.83))
        bezier2Path.addLine(to: CGPointMake(36.59, 4.89))
        bezier2Path.addLine(to: CGPointMake(9.46, 4.89))
        bezier2Path.addCurve(to: CGPointMake(0.14, 10.8), controlPoint1: CGPointMake(4.32, 4.89), controlPoint2: CGPointMake(0.14, 7.54))
        bezier2Path.addLine(to: CGPointMake(0.14, 14.47))
        bezier2Path.addLine(to: CGPointMake(2, 14.47))
        bezier2Path.addLine(to: CGPointMake(2, 10.8))
        bezier2Path.addCurve(to: CGPointMake(9.46, 6.07), controlPoint1: CGPointMake(2, 8.19), controlPoint2: CGPointMake(5.34, 6.07))
        bezier2Path.addLine(to: CGPointMake(36.59, 6.07))
        bezier2Path.addLine(to: CGPointMake(30.2, 10.12))
        bezier2Path.addLine(to: CGPointMake(31.51, 10.96))
        bezier2Path.addLine(to: CGPointMake(40.15, 5.48))
        bezier2Path.addLine(to: CGPointMake(31.51, 0))
        bezier2Path.close()
        bezier2Path.miterLimit = 4;
        bezier2Path.fill()
        return bezier2Path.cgPath
    }
    
    func drawCanvas2()->CGPath
    {
        //// flash.svg Group
        //// Group 2
        //// Group 3
        //// Bezier 2 Drawing
        let bezier3Path = UIBezierPath()
        bezier3Path.move(to: CGPointMake(38, 14.52))
        bezier3Path.addLine(to: CGPointMake(38, 18.2))
        bezier3Path.addCurve(to: CGPointMake(30.54, 22.93), controlPoint1: CGPointMake(38, 20.81), controlPoint2: CGPointMake(34.66, 22.93))
        bezier3Path.addLine(to: CGPointMake(3.41, 22.93))
        bezier3Path.addLine(to: CGPointMake(9.8, 18.87))
        bezier3Path.addLine(to: CGPointMake(8.49, 18.04))
        bezier3Path.addLine(to: CGPointMake(-0.15, 23.52))
        bezier3Path.addLine(to: CGPointMake(8.49, 29))
        bezier3Path.addLine(to: CGPointMake(9.8, 28.17))
        bezier3Path.addLine(to: CGPointMake(3.41, 24.11))
        bezier3Path.addLine(to: CGPointMake(30.54, 24.11))
        bezier3Path.addCurve(to: CGPointMake(39.86, 18.2), controlPoint1: CGPointMake(35.68, 24.11), controlPoint2: CGPointMake(39.86, 21.46))
        bezier3Path.addLine(to: CGPointMake(39.86, 14.52))
        bezier3Path.addLine(to: CGPointMake(38, 14.52))
        bezier3Path.addLine(to: CGPointMake(38, 14.52))
        bezier3Path.close()
        bezier3Path.miterLimit = 4;
        
        tintColor.setFill()
        bezier3Path.fill()
        return bezier3Path.cgPath
    }
}

@IBDesignable class BackIconDraw:IconDraw
{

    func CGPointMake(_ x:CGFloat,_ y:CGFloat)->CGPoint
    {
        let originWidth:CGFloat = 50
        let originHeight:CGFloat = 50
        
        let swidth = self.frame.width
        let sheight = self.frame.height
        
        let sx = x * (swidth / originWidth)
        let sy = y * (sheight / originHeight)
        
        return CGPoint(x: sx, y: sy)
    }
    
    
    
    override func draw(_ rect: CGRect) {
        let layers = CAShapeLayer()
        layers.fillColor = UIColor.white.cgColor
        layers.path = drawCanvas1()
        self.layer.addSublayer(layers)
        
        let layers2 = CAShapeLayer()
        layers2.fillColor = UIColor.white.cgColor
        layers2.path = drawCanvas2()
        self.layer.addSublayer(layers2)
    }
    
    func drawCanvas1()->CGPath
    {
        //// flash.svg Group
        //// Group 2
        //// Group 3
        //// Bezier 2 Drawing
        var bezierPath = UIBezierPath()
        bezierPath.move(to: CGPointMake(22.59, 49.63))
        bezierPath.addLine(to: CGPointMake(29, 42.59))
        bezierPath.addLine(to: CGPointMake(12.82, 24.82))
        bezierPath.addLine(to: CGPointMake(29, 7.04))
        bezierPath.addLine(to: CGPointMake(22.59, 0))
        bezierPath.addLine(to: CGPointMake(0, 24.82))
        bezierPath.addLine(to: CGPointMake(22.59, 49.63))
        bezierPath.close()
        bezierPath.miterLimit = 4;
        bezierPath.fill()
        return bezierPath.cgPath
    }
    
    func drawCanvas2()->CGPath
    {
        //// Bezier 2 Drawing
        var bezier2Path = UIBezierPath()
        bezier2Path.move(to: CGPointMake(43.59, 0))
        bezier2Path.addLine(to: CGPointMake(21, 24.82))
        bezier2Path.addLine(to: CGPointMake(43.59, 49.63))
        bezier2Path.addLine(to: CGPointMake(50, 42.59))
        bezier2Path.addLine(to: CGPointMake(33.82, 24.82))
        bezier2Path.addLine(to: CGPointMake(50, 7.04))
        bezier2Path.addLine(to: CGPointMake(43.59, 0))
        bezier2Path.close()
        bezier2Path.miterLimit = 4;
        bezier2Path.fill()
        return bezier2Path.cgPath
    }
}

@IBDesignable class InfinityIconDraw:IconDraw
{
    @IBInspectable var testcolor:UIColor = UIColor.black
    
    func CGPointMake(_ x:CGFloat,_ y:CGFloat)->CGPoint
    {
        let originWidth:CGFloat = 50
        let originHeight:CGFloat = 50
        
        let swidth = self.frame.width
        let sheight = self.frame.height
        
        let sx = x * (swidth / originWidth)
        let sy = y * (sheight / originHeight)
        
        return CGPoint(x: sx, y: sy)
    }
    
    override func draw(_ rect: CGRect) {
        let layers = CAShapeLayer()
        layers.fillColor = UIColor.white.cgColor
        layers.path = drawCanvas1()
        self.layer.addSublayer(layers)
    }
    
    func drawCanvas1()->CGPath
    {
        var bezierPath = UIBezierPath()
        bezierPath.move(to: CGPointMake(36.33, 0))
        bezierPath.addCurve(to: CGPointMake(22.66, 24.83), controlPoint1: CGPointMake(28.79, 0), controlPoint2: CGPointMake(22.66, 11.14))
        bezierPath.addCurve(to: CGPointMake(13.67, 41.15), controlPoint1: CGPointMake(22.66, 33.83), controlPoint2: CGPointMake(18.63, 41.15))
        bezierPath.addCurve(to: CGPointMake(4.69, 24.83), controlPoint1: CGPointMake(8.72, 41.15), controlPoint2: CGPointMake(4.69, 33.83))
        bezierPath.addCurve(to: CGPointMake(13.67, 8.51), controlPoint1: CGPointMake(4.69, 15.84), controlPoint2: CGPointMake(8.72, 8.51))
        bezierPath.addCurve(to:CGPointMake(18.66, 11.26), controlPoint1: CGPointMake(15.46, 8.51), controlPoint2: CGPointMake(17.19, 9.47))
        bezierPath.addCurve(to:CGPointMake(20.04, 13.31), controlPoint1: CGPointMake(19.16, 11.87), controlPoint2: CGPointMake(19.62, 12.56))
        bezierPath.addCurve(to:CGPointMake(23.35, 13.33), controlPoint1: CGPointMake(20.92, 14.93), controlPoint2: CGPointMake(22.46, 14.93))
        bezierPath.addCurve(to:CGPointMake(23.36, 7.31), controlPoint1: CGPointMake(24.27, 11.67), controlPoint2: CGPointMake(24.27, 8.97))
        bezierPath.addCurve(to:CGPointMake(21.27, 4.19), controlPoint1: CGPointMake(22.72, 6.15), controlPoint2: CGPointMake(22.02, 5.1))
        bezierPath.addCurve(to:CGPointMake(13.67, 0), controlPoint1: CGPointMake(19.02, 1.45), controlPoint2: CGPointMake(16.39, 0))
        bezierPath.addCurve(to:CGPointMake(0, 24.83), controlPoint1: CGPointMake(6.13, 0), controlPoint2: CGPointMake(0, 11.14))
        bezierPath.addCurve(to:CGPointMake(13.67, 49.67), controlPoint1: CGPointMake(0, 38.53), controlPoint2: CGPointMake(6.13, 49.67))
        bezierPath.addCurve(to:CGPointMake(27.34, 24.83), controlPoint1: CGPointMake(21.21, 49.67), controlPoint2: CGPointMake(27.34, 38.53))
        bezierPath.addCurve(to:CGPointMake(36.33, 8.51), controlPoint1: CGPointMake(27.34, 15.84), controlPoint2: CGPointMake(31.37, 8.51))
        bezierPath.addCurve(to:CGPointMake(45.31, 24.83), controlPoint1: CGPointMake(41.28, 8.51), controlPoint2: CGPointMake(45.31, 15.84))
        bezierPath.addCurve(to:CGPointMake(36.33, 41.15), controlPoint1: CGPointMake(45.31, 33.83), controlPoint2: CGPointMake(41.28, 41.15))
        bezierPath.addCurve(to:CGPointMake(29.98, 36.38), controlPoint1: CGPointMake(33.93, 41.15), controlPoint2: CGPointMake(31.67, 39.46))
        bezierPath.addCurve(to:CGPointMake(26.66, 36.38), controlPoint1: CGPointMake(29.09, 34.77), controlPoint2: CGPointMake(27.55, 34.77))
        bezierPath.addCurve(to:CGPointMake(25.98, 39.39), controlPoint1: CGPointMake(26.22, 37.18), controlPoint2: CGPointMake(25.98, 38.25))
        bezierPath.addCurve(to:CGPointMake(26.66, 42.4), controlPoint1: CGPointMake(25.98, 40.52), controlPoint2: CGPointMake(26.22, 41.59))
        bezierPath.addCurve(to:CGPointMake(36.33, 49.67), controlPoint1: CGPointMake(29.24, 47.09), controlPoint2: CGPointMake(32.68, 49.67))
        bezierPath.addCurve(to:CGPointMake(50, 24.83), controlPoint1: CGPointMake(43.87, 49.67), controlPoint2: CGPointMake(50, 38.53))
        bezierPath.addCurve(to:CGPointMake(36.33, 0), controlPoint1: CGPointMake(50, 11.14), controlPoint2: CGPointMake(43.87, 0))
        bezierPath.close()
        bezierPath.miterLimit = 4;
        bezierPath.fill()
        return bezierPath.cgPath
    }
}

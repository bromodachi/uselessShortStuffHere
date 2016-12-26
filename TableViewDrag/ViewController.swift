//
//  ViewController.swift
//  TableViewDrag
//
//  Created by Conrado Uraga on 2016/12/11.
//  Copyright © 2016 Conrado Uraga. All rights reserved.
//

import UIKit

class ViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    var snapShot: UIView?
    var sourceIndexPath: IndexPath?
    var scrollRate: Double = 0
    var longPressGestureForTableView: UILongPressGestureRecognizer!
    var scrollDisplayLink : CADisplayLink?
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = arrayOfFakeString[indexPath.row]
        return cell!
    }
    
    func addLongGesture() {
        longPressGestureForTableView = UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:)))
        tableView.addGestureRecognizer(longPressGestureForTableView)
        
    }
    
    func handleLongPress(sender: UILongPressGestureRecognizer) {
        let location = sender.location(in: tableView)
        guard let indexPath = tableView.indexPathForRow(at: location) else {
            return
        }
        
        switch sender.state {
        case .began:
            sourceIndexPath = indexPath
            guard let cell = tableView.cellForRow(at: indexPath) else {
                return
            }
            
            snapShot = customSnapShot(inputView: cell)
            
            var center = CGPoint(x: cell.center.x, y: cell.center.y)
            snapShot?.center = center
            snapShot?.alpha = 0.0
            tableView.addSubview(snapShot!)
            //            UIView.animate(withDuration: <#T##TimeInterval#>, animations: <#T##() -> Void#>, completion: <#T##((Bool) -> Void)?##((Bool) -> Void)?##(Bool) -> Void#>)
            UIView.animate(withDuration: 0.25, animations: {
                center.y = location.y
                self.snapShot?.center = center
                self.snapShot?.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                self.snapShot?.alpha = 0.98
                
                cell.alpha = 0.0
            }, completion: { [unowned self] _ in cell.isHidden = true})
            self.scrollDisplayLink = CADisplayLink(target: self, selector: #selector(self._scrollTableWithCell(_:)))
            self.scrollDisplayLink?.add(to: RunLoop.main, forMode: RunLoopMode.defaultRunLoopMode)
        case .changed:
            guard let snapShot = snapShot else {
                return
            }
            
            guard let sourceIndexPathTemp = sourceIndexPath else {
                return
            }
            
            var center = snapShot.center
            center.y = location.y
            snapShot.center = center
            print(tableView.bounds)
            print("COntentOffset:\(tableView.contentOffset) ")
            print("contentInset:\(tableView.contentInset) ")
            print(tableView.contentInset)
            var rect = tableView.bounds
            rect.size.height -= tableView.contentInset.top
            
            let scrollZoneHeight = rect.size.height / 6
            let bottomScrollBeginning = tableView.contentOffset.y + tableView.contentInset.top + rect.size.height - scrollZoneHeight
            let topScrollBeginning = tableView.contentOffset.y + tableView.contentInset.top  + scrollZoneHeight
            
            if location.y >= bottomScrollBeginning {
                scrollRate = Double(location.y - bottomScrollBeginning) / Double(scrollZoneHeight)
            }
                // We're in the top zone.
            else if location.y <= topScrollBeginning {
                scrollRate = Double(location.y - topScrollBeginning) / Double(scrollZoneHeight)
            }
            else {
                scrollRate = 0.0
            }
            
            if indexPath != sourceIndexPathTemp {
                swap(&arrayOfFakeString[indexPath.row], &arrayOfFakeString[sourceIndexPathTemp.row])
                tableView.moveRow(at: indexPath, to: sourceIndexPathTemp)
                sourceIndexPath = indexPath
            }
            
            
        default:
            guard let sourceIndexPathTmp = sourceIndexPath else {
                return
            }
            guard let cell = tableView.cellForRow(at: sourceIndexPathTmp) else {
                return
            }
            scrollDisplayLink?.invalidate()
            scrollDisplayLink = nil
            scrollRate = 0.0
            cell.isHidden = false
            cell.alpha = 0.0
            
            UIView.animate(withDuration: 0.25, animations: {
                self.snapShot?.center = cell.center
                //                self.snapShot?.transform = CGAffineTransform
                self.snapShot?.alpha = 0.0
                
                cell.alpha = 1.0
            }, completion: { _ in
                self.sourceIndexPath = nil
                self.snapShot?.removeFromSuperview()
                self.snapShot = nil
            })
        }
    }
    
    //http://stackoverflow.com/questions/32521725/autoscroll-smoothly-uitableview-while-dragging-uitableviewcells-in-ios-app
    internal func _scrollTableWithCell(_ sender : CADisplayLink)
    {
        if let gesture = self.longPressGestureForTableView {
            
            let location = gesture.location(in: self.tableView)
            
            print("scrollrate: \(scrollRate)")
            if !(location.y.isNaN || location.x.isNaN) {
                
                let yOffset = Double(self.tableView.contentOffset.y) + scrollRate * 10.0
                var newOffset = CGPoint(x: self.tableView.contentOffset.x, y: CGFloat(yOffset))
                
                if newOffset.y < -self.tableView.contentInset.top {
                    newOffset.y = -self.tableView.contentInset.top
                } else if (self.tableView.contentSize.height + self.tableView.contentInset.bottom) < self.tableView.frame.size.height {
                    newOffset = self.tableView.contentOffset
                } else if newOffset.y > ((self.tableView.contentSize.height + self.tableView.contentInset.bottom) - self.tableView.frame.size.height) {
                    newOffset.y = (self.tableView.contentSize.height + self.tableView.contentInset.bottom) - self.tableView.frame.size.height
                }
                
                self.tableView.contentOffset = newOffset
                
                if let draggingView = self.snapShot {
                    if (location.y >= 0) && (location.y <= (self.tableView.contentSize.height + 50.0)) {
                        snapShot?.center = CGPoint(x: self.tableView.center.x, y: location.y)
                    }
                }
            }
        }
    }
    func customSnapShot(inputView: UIView) -> UIImageView {
        UIGraphicsBeginImageContextWithOptions(inputView.bounds.size, false, 0)
        inputView.layer.render(in: UIGraphicsGetCurrentContext()!)
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        let snapShot = UIImageView(image: image)
        snapShot.layer.masksToBounds = false
        snapShot.layer.cornerRadius = 0.0
        snapShot.layer.shadowOffset = CGSize(width: -5.0, height: 0.0)
        snapShot.layer.shadowRadius = 5.0
        snapShot.layer.shadowOpacity = 0.4
        
        return snapShot
    }
    var arrayOfFakeString = ["test", "fuck", "boo"]
    
    func randomString(length: Int) -> String {
        
        let letters : NSString = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let len = UInt32(letters.length)
        
        var randomString = ""
        
        for _ in 0 ..< length {
            let rand = arc4random_uniform(len)
            var nextChar = letters.character(at: Int(rand))
            randomString += NSString(characters: &nextChar, length: 1) as String
        }
        
        return randomString
    }
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        for _ in 0..<100 {
            arrayOfFakeString.append(randomString(length: 20))
        }
        tableView.delegate = self
        tableView.dataSource = self
        addLongGesture()
        // Do any additional setup after loading the view, typically from a nib.
    }
    
    
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return arrayOfFakeString.count
    }
    func numberOfSections(in tableView: UITableView) -> Int {
        // #warning Incomplete implementation, return the number of sections
        return 1
    }
    
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    
}


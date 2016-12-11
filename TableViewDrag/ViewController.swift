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
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell")
        cell?.textLabel?.text = arrayOfFakeString[indexPath.row]
        return cell!
    }

    func addLongGesture() {
        tableView.addGestureRecognizer(UILongPressGestureRecognizer(target: self, action: #selector(handleLongPress(sender:))))
        
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
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
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


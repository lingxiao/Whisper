//
//  BreakoutRoomCell.swift
//  byte
//
//  Created by Xiao Ling on 1/26/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView


protocol BreakoutRoomCellDelegate {
    func onTapRoom( at: Room? ) -> Void
}


//MARK:- Cell-

private let textHt : CGFloat = 10 + AppFontSize.body2 + AppFontSize.footer


/*
 @Use: display user's screen
*/
class BreakoutRoomCell: UITableViewCell, BreakoutRoomCellDelegate {

    static var identifier: String = "BreakoutRoomCell"
    
    static let textHeight = textHt
    
    var parent: UIView?
    var delegate: BreakoutRoomCellDelegate?

    fileprivate var cells : [BreakoutRoomView] = []
    
    /*
     @use: reset all child views
     https://stackoverflow.com/questions/54188027/how-to-reset-uicollectionview-in-swift
     */
    override func prepareForReuse() {
        super.prepareForReuse()
        for c in cells {
            c.removeFromSuperview()
        }
        self.cells = []
        parent?.removeFromSuperview()
    }
    
    func onTapRoom(at room: Room?){
        delegate?.onTapRoom(at: room)
    }

    
    func config( with rooms: [Room], row: Int ){
        
        if rooms.count == 0 { return }
        let f = self.frame
        let pv = UIView(frame: CGRect(x: 20, y: 5, width: f.width-20, height: f.height))
        pv.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 20)
        addSubview(pv)
        self.parent = pv

        //left
        var dx : CGFloat = 15
        let wd = (f.width - 2*dx - 10)/2
        let ht = f.height - 10
        
        for room in rooms {
            let v = BreakoutRoomView(frame: CGRect(x: dx, y: 10, width: wd, height: ht))
            v.config(with: room, row:row)
            addSubview(v)
            v.delegate = self
            self.cells.append(v)
            dx += wd + 10
        }
        
    }
        

}


//MARK:- one room view

fileprivate class BreakoutRoomView : UIView {
    
    var room: Room?
    var delegate: BreakoutRoomCellDelegate?
    
    var child: UIImageView?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
    
    func config( with room: Room, row: Int){
        self.room = room
        let _ = self.tappable(with: #selector(onTap))
        layout(row)

    }
    
    
    @objc func onTap(){
        delegate?.onTapRoom(at: self.room)
    }
    
    private func layout(_ row: Int){

        let f = self.frame
        let v = UIImageView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height-20))
        v.roundCorners(corners: [.topLeft,.bottomLeft,.topRight,.bottomRight], radius: 5)
        v.backgroundColor = Color.blue1
        addSubview(v)
        self.child = v
        mountFaces(row)
    }
    
    
    private func mountFaces( _ row: Int){
        
        guard let v = self.child else { return }
        let f = v.frame
        let R  : CGFloat = (f.width - 10 - 30)/2 - AppFontSize.footerLight/2
        
        var users : [User] = []
        
        if GLOBAL_DEMO {
            let k = Int.random(in: 2..<8)
            let raw = Array(UserList.shared.cached.values).prefix(k)
            users = Array(raw)
        } else {
            users = room?.getAttending() ?? []
        }
        
        if users.count == 0 {
            let ht = AppFontSize.body2
            let h1 = UILabel()
            h1.frame = CGRect( x:10, y: (f.height-ht)/2, width: f.width-20, height: ht)
            h1.font = UIFont(name: FontName.bold, size: AppFontSize.body2)
            h1.textAlignment = .right
            h1.lineBreakMode = .byWordWrapping
            h1.textColor = Color.primary_dark
            h1.text = "Empty room"
            h1.sizeToFit()
            v.addSubview(h1)            
            
            if let user = UserList.shared.get(room?.createdBy) {
                h1.text = "Empty room created by \(user.get_H1())"
            }

            
        } else if users.count == 1 {

            mkImg(dx: (f.width-R)/2, dy: (f.height-R)/2, R: R, user: users[0])

        } else {

            var dx : CGFloat = (f.width - 2*R  - 10)/2
            var dy : CGFloat = (f.height - 2*R - 20)/2

            if users.count == 2 {
                dx += R + 10
            }
                        
            mkImg(dx: dx, dy: dy, R: R, user: users[0])

            if users.count < 2 { return }
            
            if users.count == 2 {
                dx -= (R + 10)
                dy += R + 10 + AppFontSize.footerLight
            } else {
                dx += R + 10
            }
            
            mkImg(dx: dx, dy: dy, R: R, user: users[1])
            
            if users.count >= 3 {
                                
                dy += R + 10 + AppFontSize.footerLight

                if users.count == 3 {
                    dx -= (R + 10)/2
                } else {
                    dx -= (R + 10)
                }
                
                mkImg(dx: dx, dy: dy, R: R, user: users[2])

                dx += R + 10

                if users.count == 4 {

                    mkImg(dx: dx, dy: dy, R: R, user: users[3])

                } else if users.count > 4 {
                    
                    let label = UILabel()
                    label.frame = CGRect( x:dx, y: dy, width: R, height:R)
                    label.font = UIFont(name: FontName.bold, size: AppFontSize.footer)
                    label.textAlignment = .center
                    label.lineBreakMode = .byTruncatingTail
                    label.textColor = Color.grayPrimary
                    v.addSubview(label)
                    label.text = "+ \(users.count-3)"
                }
            }

        }
        
    }
    
    private func mkImg( dx: CGFloat, dy: CGFloat, R: CGFloat, user: User? ){

        let p = UIImageView(frame: CGRect(x: dx, y: dy, width: R, height: R))
        let _ = p.round()
        let _ = p.border(width: 2.0, color: Color.redLite.cgColor)
        p.backgroundColor = Color.blue1

        // add txt
        let h1 = UILabel()
        h1.frame = CGRect( x:dx+5, y: dy+R+5, width: R-10, height: AppFontSize.footerLight+2)
        h1.font = UIFont(name: FontName.regular, size: AppFontSize.footerLight)
        h1.textAlignment = .center
        h1.textColor = Color.primary_dark

        child?.addSubview(h1)
        child?.addSubview(p)

        if GLOBAL_DEMO {
            let (rand_name,rand_img) = RandomUserGenerator.shared.getUser()
            let pic = UIImage(named: rand_img)
            p.image = pic
            h1.text = rand_name
        } else {
            DispatchQueue.main.async {
                ImageLoader.shared.injectImage(from: user?.fetchThumbURL(), to: p){ _ in return }
            }
            h1.text = user?.get_H1() ?? ""
        }
    }


}


extension RangeExpression where Bound: FixedWidthInteger {
    func randomElements(_ n: Int) -> [Bound] {
        precondition(n > 0)
        switch self {
        case let range as Range<Bound>: return (0..<n).map { _ in .random(in: range) }
        case let range as ClosedRange<Bound>: return (0..<n).map { _ in .random(in: range) }
        default: return []
        }
    }
}

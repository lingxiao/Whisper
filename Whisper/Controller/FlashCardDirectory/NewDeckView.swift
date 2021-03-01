//
//  NewDeckView.swift
//  byte
//
//  Created by Xiao Ling on 1/4/21.
//  Copyright © 2021 Xiao Ling. All rights reserved.
//

import Foundation
import UIKit
import NVActivityIndicatorView



class NewDeckView: UIViewController, RowOfColorsDelegate {

    // style
    let headerHeight: CGFloat = 40
    let footerHeight: CGFloat = 80
    
    var club : Club?
    var delegate: NewDeckViewDelegate?
    
    // main child view
    var header: AppHeader?
    var h1: UITextView?
    var dotView: NVActivityIndicatorView?
    var activeImg: UIImageView?

    // style guide
    let imagePicker = UIImagePickerController()
    var newlyPickedImage: UIImage?
    var color: UIColor = Color.purple2

    override func viewDidLoad() {
        super.viewDidLoad()
    }

    static func height() -> CGFloat {
        var dy : CGFloat = 10
        dy += 40 + 25
        dy += AppFontSize.H2 + 20
        dy += AppFontSize.footer + 10
        dy += 50 + 10
        dy += AppFontSize.body2 + 20
        dy += 20
        return dy
    }
    
    /*
     @use: call this to load data
    */
    func config( from club : Club? ){

        self.club = club
        primaryGradient(on: self.view)
        addGestureResponders()
        layout()
        imagePicker.delegate = self

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0 ) { [weak self] in
            self?.h1?.becomeFirstResponder()
        }
    }
    
    //MARK:- event
    
    func didSelectColor( at color: UIColor ){
        self.color = color
        if color == UIColor.clear {
            showImagePicker()
        } else {
            self.activeImg?.image = nil
            self.activeImg?.backgroundColor = color
        }
    }
    
    
    //MARK:- view
    
    func layout(){

        let f = view.frame

        // header
        let header = AppHeader(frame: CGRect(x:0,y:10, width:f.width,height:headerHeight))
        header.delegate = self
        header.config( showSideButtons: true, left: "", right: "xmark", title: "Create new deck", mode: .light, small: true )
        header.label?.textColor = Color.primary_dark
        view.addSubview(header)
        header.backgroundColor = UIColor.clear
        self.header = header

        var dy = headerHeight+25
        
        // selected color
        let R = AppFontSize.H1 + 10
        let img = UIImageView(frame: CGRect(x: 20, y: dy, width:R, height: R))
        let _ = img.round()
        let _ = img.border(width: 2.0, color: Color.grayPrimary.cgColor)
        img.backgroundColor = Color.primary
        view.addSubview(img)
        self.activeImg = img
        
        // fill in name
        let h1 = UITextView(frame:CGRect(x:20+5+R,y:dy,width:f.width-50-R,height:AppFontSize.H1+10))
        h1.textAlignment = .left
        h1.backgroundColor = UIColor.clear
        h1.font = UIFont(name: FontName.bold, size: AppFontSize.H3)
        h1.text = NDTOP
        h1.textColor = Color.grayPrimary
        h1.textContainer.lineBreakMode = .byWordWrapping
        h1.isUserInteractionEnabled = true
        h1.delegate = self
        self.h1 = h1
        view.addSubview(h1)
        
        dy += AppFontSize.H1 + 10
        
        // pick colors
        let h2 = UITextView(frame:CGRect(x:20,y:dy,width:f.width-20,height:AppFontSize.footer+10))
        h2.textAlignment = .left
        h2.backgroundColor = UIColor.clear
        h2.font = UIFont(name: FontName.light, size: AppFontSize.footer)
        h2.text = "Pick cover color"
        h2.textColor = Color.primary_dark.lighter(by: 10)
        h2.textContainer.lineBreakMode = .byTruncatingTail
        h2.isUserInteractionEnabled = false
        view.addSubview(h2)
        
        dy += AppFontSize.footer + 20
        
        let v = RowOfColors(frame: CGRect(x: 20, y: dy, width: f.width-40, height: 40))
        v.config()
        v.delegate = self
        view.addSubview(v)
        
        dy += 40 + 20
        
        // footer
        let w = f.width/2
        let h = AppFontSize.body2 + 20
        let b2 = TinderTextButton()
        b2.frame = CGRect(x:(f.width-w)/2,y:dy, width:w,height:h)
        b2.config(with: "Create", color: Color.redLite, font: UIFont(name: FontName.bold, size: AppFontSize.footer))
        b2.addTarget(self, action: #selector(handleTapAdd), for: .touchUpInside)
        b2.backgroundColor = Color.redDark
        view.addSubview(b2)
    }
        
    // create footer
    @objc func handleTapAdd( _ button: TinderButton ){
        
        guard let str = h1?.text else {
            return ToastSuccess(title: "Oh no!", body: "An error occured")
        }
        
        if str == "" {
            ToastSuccess(title: "Please enter a name", body: "")
            self.h1?.becomeFirstResponder()
        } else {
            delegate?.onCreateNewDeck(with: str, color:self.color, image: self.newlyPickedImage)
        }
    }
        

}



extension NewDeckView : UITextViewDelegate {
    
    func textViewDidBeginEditing(_ textView: UITextView) {
        
        if textView.text == NDTOP {
            textView.text = ""
            textView.textColor = UIColor.black
        }

    }
    
    func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
        if text == "\n" {
            let str = textView.text
            if str == "" {
                ToastSuccess(title: "Please enter a name", body: "")
                return false
            } else {
                textView.resignFirstResponder()
                return false
            }
        }
        return true
    }
    
}

extension NewDeckView: UIImagePickerControllerDelegate,UINavigationControllerDelegate  {

    func showImagePicker(){
        permitAVCapture(){(succ,msg) in
            if ( succ ){
                self.openImagePicker()
            } else {
                return ToastSuccess(title: "", body: "We do not have permission to open your files")
            }
        }
    }

    //@use: open picker for file only
    func openImagePicker(){
        DispatchQueue.main.async {
            self.imagePicker.allowsEditing = true
            self.imagePicker.sourceType = .photoLibrary
            self.present(self.imagePicker, animated: true, completion: nil)
        }
    }


    // @use: reset image in the view, *then* save to db
    func imagePickerController(
         _ picker: UIImagePickerController
        , didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any])
    {

        if let pickedImage = info[UIImagePickerController.InfoKey.originalImage] as? UIImage {
            self.newlyPickedImage = pickedImage
            self.activeImg?.image = pickedImage
        }

        self.dismiss(animated: true, completion: nil)
    }

}





//MARK:- gesture

extension NewDeckView: AppHeaderDelegate {

    func onHandleDismiss(){
        delegate?.onDismissNewDeckView()
    }
    
    func addGestureResponders(){

        let swipeRt = UISwipeGestureRecognizer(target: self, action: #selector(respondToSwipeGesture))
        swipeRt.direction = .down
        self.view.addGestureRecognizer(swipeRt)
    }
    
    // Swipe gesture
    @objc func respondToSwipeGesture(gesture: UIGestureRecognizer) {
        
        if let swipeGesture = gesture as? UISwipeGestureRecognizer {

            switch swipeGesture.direction {
            
            case .right:
                break;
            case .down:
                delegate?.onDismissNewDeckView()
            case .left:
                break;
            case .up:
                break;
            default:
                break
            }
        }
    }
}


//MARK:- row of colors-

protocol RowOfColorsDelegate {
    func didSelectColor( at color: UIColor ) -> Void
}


class RowOfColors : UIView, UICollectionViewDataSource, UICollectionViewDelegate, RowOfColorsDelegate, UICollectionViewDelegateFlowLayout {

    var delegate: RowOfColorsDelegate?
    var colView: UICollectionView?
    private var edgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 0)

    var dataSource: [UIColor] = ACCENT_COLORS

    override init(frame: CGRect) {
        super.init(frame: frame)
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
    }
    
    func didSelectColor( at color: UIColor ){
        delegate?.didSelectColor(at: color)
    }
    
    func config(){

        let f = self.frame
        
        // layout
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = UICollectionView.ScrollDirection.horizontal
        layout.minimumInteritemSpacing = 0
        layout.minimumLineSpacing = 0
        layout.sectionInset = edgeInsets
        layout.itemSize = CGSize(width:f.height,height:f.height)
        
        let collection = UICollectionView(frame: CGRect(x: 0, y: 0, width: f.width, height: f.height), collectionViewLayout: layout)
        collection.backgroundColor = Color.transparent
        collection.showsHorizontalScrollIndicator = false
        collection.alwaysBounceHorizontal = true

        // mount + register cell
        self.addSubview(collection)
        self.colView = collection

        colView?.register(ColorRowCell.self, forCellWithReuseIdentifier: ColorRowCell.identifier)
        colView?.delegate = self
        colView?.dataSource = self
        
        colView?.reloadData()

    }
    
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return dataSource.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {

        let row = indexPath.row
        
        let color = dataSource[row]
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "ColorRowCell", for: indexPath) as! ColorRowCell
        cell.delegate = self
        cell.config(with: color)
        return cell
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, minimumLineSpacingForSectionAt section: Int) -> CGFloat {
        return 20
    }
    
}

class ColorRowCell: UICollectionViewCell {
    
    // storyboard identifier
    static let identifier = "ColorRowCell"

    var v: UIView?
    var b: TinderButton?

    var color: UIColor = Color.primary
    var delegate:RowOfColorsDelegate?

    override func prepareForReuse(){
        super.prepareForReuse()
        v?.removeFromSuperview()
    }
    
    
    func config( with color: UIColor){

        self.color = color
        
        let f = self.frame
        
        if color == UIColor.clear {

            let b = TinderButton()
            b.frame = CGRect(x: 0, y: 0, width: f.height, height: f.height)
            b.changeImage(to: "photo-stack", alpha: 1.0, scale: 1/2, color: Color.grayPrimary)
            b.backgroundColor = Color.white
            addSubview(b)
            b.addTarget(self, action: #selector(onAdd), for: .touchUpInside)
            self.b = b
            
        } else {
        
            let c3 = UIImageView(frame: CGRect(x: 0, y: 0, width: f.height, height: f.height))
            let _ = c3.round()
            c3.backgroundColor = color
            let _ = c3.addBorder(width: 2.0, color: Color.grayPrimary.cgColor)
            
            addSubview(c3)
            c3.isUserInteractionEnabled = true
            let g1 = UITapGestureRecognizer(target: self, action:  #selector(onHandleTapColor))
            c3.addGestureRecognizer(g1)
            self.v = c3
                
        }
    }
    
    @objc func onAdd(_ button: TinderButton ){
        delegate?.didSelectColor(at: UIColor.clear)
    }
    
    @objc func onHandleTapColor(sender : UITapGestureRecognizer){
        delegate?.didSelectColor(at: self.color)
    }
}


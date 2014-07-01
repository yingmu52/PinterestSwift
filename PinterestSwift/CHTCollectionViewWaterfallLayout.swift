//
//  CHTCollectionViewWaterfallLayout.swift
//  PinterestSwift
//
//  Created by Nicholas Tau on 6/30/14.
//  Copyright (c) 2014 Nicholas Tau. All rights reserved.
//

import Foundation
import UIKit

@objc protocol CHTCollectionViewDelegateWaterfallLayout: UICollectionViewDelegate{
    
    func collectionView (collectionView: UICollectionView!,layout collectionViewLayout: UICollectionViewLayout,
        sizeForItemAtIndexPath indexPath: NSIndexPath) -> CGSize
    
    @optional func colletionView (collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout,
        heightForHeaderInSection section: NSInteger) -> CGFloat
    
    @optional func colletionView (collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout,
        heightForFooterInSection section: NSInteger) -> CGFloat
    
    @optional func colletionView (collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout,
        insetForSectionAtIndex section: NSInteger) -> UIEdgeInsets
    
    @optional func colletionView (collectionView: UICollectionView!, layout collectionViewLayout: UICollectionViewLayout,
        minimumInteritemSpacingForSectionAtIndex section: NSInteger) -> CGFloat
}

enum CHTCollectionViewWaterfallLayoutItemRenderDirection : Int{
    case CHTCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst
    case CHTCollectionViewWaterfallLayoutItemRenderDirectionLeftToRight
    case CHTCollectionViewWaterfallLayoutItemRenderDirectionRightToLeft
}

class CHTCollectionViewWaterfallLayout : UICollectionViewLayout{
    let  CHTCollectionElementKindSectionHeader = "CHTCollectionElementKindSectionHeader"
    let CHTCollectionElementKindSectionFooter = "CHTCollectionElementKindSectionFooter"
    
    var columnCount : NSInteger{
    didSet{
        invalidateLayout()
    }}
    
    var minimumColumnSpacing : CGFloat{
    didSet{
        invalidateLayout()
    }}
    
    var minimumInteritemSpacing : CGFloat{
    didSet{
        invalidateLayout()
    }}
    
    var headerHeight : CGFloat{
    didSet{
        invalidateLayout()
    }}

    var footerHeight : CGFloat{
    didSet{
        invalidateLayout()
    }}

    var sectionInset : UIEdgeInsets{
    didSet{
        invalidateLayout()
    }}
    
    
    var itemRenderDirection : CHTCollectionViewWaterfallLayoutItemRenderDirection{
    didSet{
        invalidateLayout()
    }}
    
    
//    private property and method above.
    weak var delegate : CHTCollectionViewDelegateWaterfallLayout?{
    get{
        return self.collectionView.delegate as? CHTCollectionViewDelegateWaterfallLayout
    }
    }
    var columnHeights : NSMutableArray
    var sectionItemAttributes : NSMutableArray
    var allItemAttributes : NSMutableArray
    var headersAttributes : NSMutableDictionary
    var footersAttributes : NSMutableDictionary
    var unionRects : NSMutableArray
    let unionSize = 20
    
    init(){
        self.headerHeight = 0.0
        self.footerHeight = 0.0
        self.columnCount = 2
        self.minimumInteritemSpacing = 10
        self.minimumColumnSpacing = 10
        self.sectionInset = UIEdgeInsetsZero
        self.itemRenderDirection =
        CHTCollectionViewWaterfallLayoutItemRenderDirection.CHTCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst

        headersAttributes = NSMutableDictionary()
        footersAttributes = NSMutableDictionary()
        unionRects = NSMutableArray()
        columnHeights = NSMutableArray()
        allItemAttributes = NSMutableArray()
        sectionItemAttributes = NSMutableArray()
        
        super.init()
    }
    
    func itemWidthInSectionAtIndex (section : NSInteger) -> CGFloat {
        var insets : UIEdgeInsets
        if let sectionInsets = self.delegate?.colletionView?(self.collectionView, layout: self, insetForSectionAtIndex: section){
            insets = sectionInsets
        }else{
            insets = self.sectionInset
        }
        let width = self.collectionView.frame.size.width - sectionInset.left-sectionInset.right
        return floorf((width - (self.columnCount - 1) * self.minimumColumnSpacing) / self.columnCount);
    }
    
    override func prepareLayout(){
        super.prepareLayout()
        
        let numberOfSections = self.collectionView.numberOfSections()
        if numberOfSections == 0 {
            return
        }
        
        self.headersAttributes.removeAllObjects()
        self.footersAttributes.removeAllObjects()
        self.unionRects.removeAllObjects()
        self.columnHeights.removeAllObjects()
        self.allItemAttributes.removeAllObjects()
        self.sectionItemAttributes.removeAllObjects()
        
        var idx = 0
        while idx<self.columnCount{
            self.columnHeights.addObject(0)
            idx++
        }
        
        var top : CGFloat = 0.0
        var attributes = UICollectionViewLayoutAttributes()
        
        for var section = 0; section < numberOfSections; ++section{
            /*
            * 1. Get section-specific metrics (minimumInteritemSpacing, sectionInset)
            */
            var minimumInteritemSpacing : CGFloat
            if let miniumSpaceing = self.delegate?.colletionView?(self.collectionView, layout: self, minimumInteritemSpacingForSectionAtIndex: section){
                minimumInteritemSpacing = miniumSpaceing
            }else{
                minimumInteritemSpacing = self.minimumColumnSpacing
            }
            
            var sectionInsets :  UIEdgeInsets
            if let insets = self.delegate?.colletionView?(self.collectionView, layout: self, insetForSectionAtIndex: section){
                sectionInsets = insets
            }else{
                sectionInsets = self.sectionInset
            }
            
            let width = self.collectionView.frame.size.width - sectionInset.left - sectionInset.right
            let itemWidth = floorf((width - (self.columnCount - 1) * self.minimumColumnSpacing) / self.columnCount)
            
            /*
            * 2. Section header
            */
            var heightHeader : CGFloat
            if let height = self.delegate?.colletionView?(self.collectionView, layout: self, heightForHeaderInSection: section){
                heightHeader = height
            }else{
                heightHeader = self.headerHeight
            }
            
            if heightHeader > 0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: CHTCollectionElementKindSectionHeader, withIndexPath: NSIndexPath(forRow: 0, inSection: section))
                attributes.frame = CGRectMake(0, top, self.collectionView.frame.size.width, heightHeader)
                self.headersAttributes.setObject(attributes, forKey: (section))
                self.allItemAttributes.addObject(attributes)
            
                top = CGRectGetMaxX(attributes.frame)
            }
            top += sectionInset.top
            for var idx = 0; idx < self.columnCount; idx++ {
                self.columnHeights.setObject(top, atIndexedSubscript: idx)
            }
            
            /*
            * 3. Section items
            */
            let itemCount = self.collectionView.numberOfItemsInSection(section)
            let itemAttributes = NSMutableArray(capacity: itemCount)

            // Item will be put into shortest column.
            for var idx = 0; idx < itemCount; idx++ {
                let indexPath = NSIndexPath(forItem: idx, inSection: section)
                
                let columnIndex = self.nextColumnIndexForItem(idx)
                let xOffset = sectionInset.left + (itemWidth + self.minimumColumnSpacing) * columnIndex
                let yOffset = self.columnHeights.objectAtIndex(columnIndex).floatValue
                let itemSize = self.delegate?.collectionView(self.collectionView, layout: self, sizeForItemAtIndexPath: indexPath)
                var itemHeight : CGFloat = 0.0
                if itemSize?.height > 0 && itemSize?.width > 0 {
                    itemHeight = floorf(itemSize!.height*itemWidth/itemSize!.width)
                }

                attributes = UICollectionViewLayoutAttributes(forCellWithIndexPath: indexPath)
                attributes.frame = CGRectMake(xOffset, yOffset, itemWidth, itemHeight)
                itemAttributes.addObject(attributes)
                self.allItemAttributes.addObject(attributes)
                self.columnHeights.setObject(CGRectGetMaxY(attributes.frame) + minimumInteritemSpacing, atIndexedSubscript: columnIndex)
            }
            self.sectionItemAttributes.addObject(itemAttributes)
            
            /*
            * 4. Section footer
            */
            var footerHeight : CGFloat = 0.0
            let columnIndex  = self.longestColumnIndex()
            top = self.columnHeights.objectAtIndex(columnIndex).floatValue - minimumInteritemSpacing + sectionInset.bottom
    
            if let height = self.delegate?.colletionView?(self.collectionView, layout: self, heightForFooterInSection: section){
                footerHeight = height
            }else{
                footerHeight = self.footerHeight
            }
            
            if footerHeight > 0 {
                attributes = UICollectionViewLayoutAttributes(forSupplementaryViewOfKind: CHTCollectionElementKindSectionFooter, withIndexPath: NSIndexPath(forItem: 0, inSection: section))
                attributes.frame = CGRectMake(0, top, self.collectionView.frame.size.width, footerHeight)
                self.footersAttributes.setObject(attributes, forKey: section)
                self.allItemAttributes.addObject(attributes)
                top = CGRectGetMaxY(attributes.frame)
            }
            
            for var idx = 0; idx < self.columnCount; idx++ {
                self.columnHeights.setObject(top, atIndexedSubscript: idx)
            }
        }
    }
    
    override func collectionViewContentSize() -> CGSize{
        var numberOfSections = self.collectionView.numberOfSections()
        if numberOfSections == 0{
            return CGSizeZero
        }
        
        var contentSize = self.collectionView.bounds.size
        contentSize.height = self.columnHeights.objectAtIndex(0).floatValue
        return  contentSize
    }
    
    override func layoutAttributesForItemAtIndexPath(indexPath: NSIndexPath!) -> UICollectionViewLayoutAttributes!{
        if indexPath.section >= self.sectionItemAttributes.count{
            return nil
        }
        if indexPath.item >= self.sectionItemAttributes.objectAtIndex(indexPath.section)?.count{
            return nil;
        }
        var list = self.sectionItemAttributes.objectAtIndex(indexPath.section) as NSArray
        return list.objectAtIndex(indexPath.item) as UICollectionViewLayoutAttributes
    }
    
    override func layoutAttributesForSupplementaryViewOfKind(elementKind: String!, atIndexPath indexPath: NSIndexPath!) -> UICollectionViewLayoutAttributes!{
        var attribute = UICollectionViewLayoutAttributes()
        if elementKind == CHTCollectionElementKindSectionHeader{
            attribute = self.headersAttributes.objectForKey(indexPath.section) as UICollectionViewLayoutAttributes
        }else if elementKind == CHTCollectionElementKindSectionFooter{
            attribute = self.footersAttributes.objectForKey(indexPath.section) as UICollectionViewLayoutAttributes
        }
        return attribute
    }
    
    override func layoutAttributesForElementsInRect (rect : CGRect) -> AnyObject[]! {
        var i = 0
        var begin = 0, end = self.unionRects.count
        var attrs = NSMutableArray()
        
        for var i = 0; i < end; i++ {
            if CGRectIntersectsRect(rect, self.unionRects.objectAtIndex(i).CGRectValue()){
                begin = i * unionSize;
                break
            }
        }
        for var i = self.unionRects.count - 1; i>=0; i-- {
            if CGRectIntersectsRect(rect, self.unionRects.objectAtIndex(i).CGRectValue()){
                end = min((i+1)*unionSize,self.allItemAttributes.count)
                break
            }
        }
        for var i = begin; i < end; i++ {
            var attr = self.allItemAttributes.objectAtIndex(i) as UICollectionViewLayoutAttributes
            if CGRectIntersectsRect(rect, attr.frame) {
                attrs.addObject(attr)
            }
        }
            
        return NSArray(array: attrs)
    }
    
    override func shouldInvalidateLayoutForBoundsChange (newBounds : CGRect) -> Bool {
        var oldBounds = self.collectionView.bounds
        if CGRectGetWidth(newBounds) != CGRectGetWidth(oldBounds){
            return true
        }
        return false
    }


    /**
    *  Find the shortest column.
    *
    *  @return index for the shortest column
    */
    func shortestColumnIndex () -> NSInteger {
        var index = 0
        var shorestHeight = MAXFLOAT
        
        self.columnHeights.enumerateObjectsUsingBlock({(object : AnyObject!, idx : NSInteger,pointer :CMutablePointer<ObjCBool>) in
            let height = object.floatValue
            if (height<shorestHeight){
                shorestHeight = height
                index = idx
            }
            })
        return index
    }
    
    /**
    *  Find the longest column.
    *
    *  @return index for the longest column
    */

    func longestColumnIndex () -> NSInteger {
        var index = 0
        var longestHeight:CGFloat = 0.0
        
        self.columnHeights.enumerateObjectsUsingBlock({(object : AnyObject!, idx : NSInteger,pointer :CMutablePointer<ObjCBool>) in
            let height = object.floatValue as CGFloat
            if (height > longestHeight){
                longestHeight = height
                index = idx
            }
            })
        return index
    }

    /**
    *  Find the index for the next column.
    *
    *  @return index for the next column
    */
    func nextColumnIndexForItem (item : NSInteger) -> Int {
        var index = 0
        switch (self.itemRenderDirection){
        case .CHTCollectionViewWaterfallLayoutItemRenderDirectionShortestFirst :
            index = self.shortestColumnIndex()
        case .CHTCollectionViewWaterfallLayoutItemRenderDirectionLeftToRight :
            index = (item%self.columnCount)
        case .CHTCollectionViewWaterfallLayoutItemRenderDirectionRightToLeft:
            index = (self.columnCount - 1) - (item % self.columnCount);
        default:
            index = self.shortestColumnIndex()
        }
        return index
    }
}
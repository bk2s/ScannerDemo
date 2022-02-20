//
//  CameraViewModel.swift
//  Scanner Demo
//
//  Created by  Stepanok Ivan on 19.02.2022.
//

import UIKit
import GPUImage
import RxSwift
import RxCocoa

protocol ViewModelInputOutput: AnyObject {
    associatedtype Input
    associatedtype Output
}

protocol ViewModel: ViewModelInputOutput {
    func transform(input: Input) -> Output
}

class FilterViewModel: ViewModel {
    
    // MARK: - Properties
    private let filtered = PublishSubject<UIImage>()
    private var bag = DisposeBag()
    
    // MARK: - Transform
    func transform(input: Input) -> Output {
        input.firstFilter.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { _ in
                self.filtered.onNext(self.pictureFilter(filter: .grayscale, img: input.selectedItem))
            }).disposed(by: bag)
        input.grayPressed.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { _ in
                self.filtered.onNext(self.pictureFilter(filter: .grayscale, img: input.selectedItem))
            }).disposed(by: bag)
        input.pixelatePressed.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { _ in
                self.filtered.onNext(self.pictureFilter(filter: .pixelate, img: input.selectedItem))
            }).disposed(by: bag)
        return Output(filteredPicture: filtered)
    }
    
    // MARK: - Methods
    private func pictureFilter(filter: Filters, img: UIImage) -> UIImage {
        var filteredImage: UIImage!
        switch filter {
        case .grayscale:
            filteredImage = OpenCVWrapper.toGray(img)
        case .pixelate:
            let pixelate = GPUImagePixellateFilter()
            pixelate.fractionalWidthOfAPixel = 0.01
            filteredImage = pixelate.image(byFilteringImage: img)
        }
        return UIImage(cgImage: filteredImage.cgImage!, scale: 1, orientation: .right)
    }
    
    // MARK: - Input&Output
    struct Input {
        let firstFilter: PublishRelay<Void>
        let selectedItem: UIImage
        let grayPressed: Driver<Void>
        let pixelatePressed: Driver<Void>
    }
    
    struct Output {
        let filteredPicture: PublishSubject<UIImage>
    }
}

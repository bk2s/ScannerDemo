//
//  FilterViewController.swift
//  Scanner Demo
//
//  Created by  Stepanok Ivan on 19.02.2022.
//

import UIKit
import GPUImage
import RxSwift
import RxCocoa

enum Filters {
    case grayscale
    case pixelate
}

class FilterViewController: UIViewController {
    
    typealias ViewModel = FilterViewModel
    private struct Colors {
        static let selectedColor = UIColor(red: 44/255.0, green: 44/255.0, blue: 44/255.0, alpha: 1)
        static let defaultColor = UIColor(red: 27/255.0, green: 27/255.0, blue: 27/255.0, alpha: 1)
    }
    
    // MARK: - Properties
    private var bag = DisposeBag()
    private let runFilter = PublishRelay<Void>()
    private let viewModel = ViewModel()
    private var image: UIImage!
    
    // MARK: - Outlets
    @IBOutlet weak var currentImage: UIImageView!
    @IBOutlet weak var leftButtonView: UIView!
    @IBOutlet weak var rightButtonView: UIView!
    @IBOutlet weak var leftButton: UIButton!
    @IBOutlet weak var rightButton: UIButton!
    @IBOutlet weak var doneButton: UIButton!
    
    // MARK: - Init
    convenience init(image: UIImage) {
        self.init()
        self.image = image
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.selectedButton()
        self.setupCorners(radius: 10)
        self.bind(with: self.viewModel)
        self.runFilter.accept(())
    }
    
    // MARK: - Actions
    @IBAction func donePressed(_ sender: Any) {
        self.dismiss(animated: true)
    }
    
    // MARK: - Configuration
    private func setupCorners(radius: CGFloat) {
        self.currentImage.layer.cornerRadius = radius
        self.leftButtonView.layer.cornerRadius = radius
        self.rightButtonView.layer.cornerRadius = radius

    }
    
    // MARK: - Methods
    private func designButtons(selected: Filters) {
        switch selected {
        case .grayscale:
            self.leftButtonView.backgroundColor = Colors.selectedColor
            self.rightButtonView.backgroundColor = Colors.defaultColor
        case .pixelate:
            self.leftButtonView.backgroundColor = Colors.defaultColor
            self.rightButtonView.backgroundColor = Colors.selectedColor
        }
    }
    
    private func selectedButton() {
        leftButton.rx.tap.asDriver(onErrorDriveWith: .empty()).drive(onNext: {
            self.designButtons(selected: .grayscale)
        }).disposed(by: bag)
        rightButton.rx.tap.asDriver(onErrorDriveWith: .empty()).drive(onNext: {
            self.designButtons(selected: .pixelate)
        }).disposed(by: bag)
    }
    
    // MARK: - RxBinds
    private func bind(with viewModel: ViewModel) {
        let input = ViewModel.Input(firstFilter: self.runFilter,
                                    selectedItem: self.image,
                                    grayPressed: self.leftButton.rx.tap.asDriver(),
                                    pixelatePressed: self.rightButton.rx.tap.asDriver())
        let output = viewModel.transform(input: input)
        output.filteredPicture.asDriver(onErrorDriveWith: .empty())
            .drive(onNext: { image in
                self.currentImage.image = image
            }).disposed(by: bag)
    }
}

//
//  ViewController.swift
//  chip8
//
//  Created by Mirza Ucanbarlic on 25. 3. 2022..
//

import UIKit
import Chip8Kit

class ViewController: UIViewController {
    enum Section {
        case main
    }
    struct KeyboardItem: Hashable, Equatable {
        let id = UUID()
        let value: Int
        let label: String
    }
    let keyboardItems = [KeyboardItem(value: 1, label: "1"),
                         KeyboardItem(value: 2, label: "2"),
                         KeyboardItem(value: 3, label: "3"),
                         KeyboardItem(value: 12, label: "C"),
                         KeyboardItem(value: 4, label: "4"),
                         KeyboardItem(value: 5, label: "5"),
                         KeyboardItem(value: 6, label: "6"),
                         KeyboardItem(value: 13, label: "D"),
                         KeyboardItem(value: 7, label: "7"),
                         KeyboardItem(value: 8, label: "8"),
                         KeyboardItem(value: 9, label: "9"),
                         KeyboardItem(value: 14, label: "E"),
                         KeyboardItem(value: 10, label: "A"),
                         KeyboardItem(value: 0, label: "0"),
                         KeyboardItem(value: 11, label: "B"),
                         KeyboardItem(value: 15, label: "F"),
    ]
    private var isPlaying = true {
        didSet {
            if isPlaying {
                pauseButton.setTitle("Pause", for: .normal)
                self.resume()
            } else {
                pauseButton.setTitle("Resume", for: .normal)
                self.pause()
            }
        }
    }
    var speed: Double = 400
    private var dataSource: UICollectionViewDiffableDataSource<Section, KeyboardItem>! = nil
    private var chip8 = Chip8()
    private let imageView: UIImageView = {
        let image = UIImageView()
        image.translatesAutoresizingMaskIntoConstraints = false
        image.layer.magnificationFilter = .nearest
        image.layer.borderColor = UIColor.black.cgColor
        image.layer.borderWidth = 1
        return image
    }()
    private var collectionView: UICollectionView! = nil
    private var timer: Timer! = nil
    private let stackView: UIStackView = {
        let stack = UIStackView()
        stack.translatesAutoresizingMaskIntoConstraints = false
        stack.axis = .horizontal
        stack.spacing = 20
        return stack
    }()
    private var loadButton: UIButton!
    private var pauseButton: UIButton!
    private var slider: UISlider = {
        let slider = UISlider(frame: .zero)
        slider.translatesAutoresizingMaskIntoConstraints = false
        slider.minimumValue = 200
        slider.maximumValue = 5000
        slider.addTarget(self, action: #selector(sliderDidChange), for: .valueChanged)
        return slider
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        configureDataSource()
        configureChip()
    }
    
    // MARK: Configure UI
    private func setupUI() {
        view.addSubview(imageView)
        setupButtons()
        setupCollectionView()
        setupStackView()
        view.addSubview(collectionView)
        view.addSubview(slider)
        view.addSubview(stackView)
        view.addSubview(slider)
        NSLayoutConstraint.activate([
            imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 50),
            imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -50),
            imageView.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 20),
            imageView.heightAnchor.constraint(equalTo: view.heightAnchor, multiplier: 0.2),
            slider.topAnchor.constraint(equalTo: imageView.bottomAnchor, constant: 20),
            slider.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            slider.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            stackView.topAnchor.constraint(equalTo: slider.bottomAnchor, constant: 20),
            stackView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            stackView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20),
            collectionView.topAnchor.constraint(equalTo: stackView.bottomAnchor, constant: 20),
            collectionView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            collectionView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            collectionView.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -50)
        ])
    }
    
    private func setupButtons() {
        loadButton = UIButton(configuration: .filled(), primaryAction: UIAction(handler: { [weak self] _ in
            self?.showRomPickerViewController()
        }))
        loadButton.setTitle("Load ROM", for: .normal)
        loadButton.setImage(UIImage(systemName: "folder"), for: .normal)
        pauseButton = UIButton(configuration: .filled(), primaryAction: UIAction(handler: { [weak self] _ in
            self?.isPlaying.toggle()
        }))
        pauseButton.setTitle("Pause", for: .normal)
    }
    
    private func setupStackView() {
        stackView.addArrangedSubview(loadButton)
        stackView.addArrangedSubview(pauseButton)
    }
    
    private func setupCollectionView() {
        let itemSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(0.25),
                                              heightDimension: .fractionalHeight(1.0))
        let item = NSCollectionLayoutItem(layoutSize: itemSize)
        item.contentInsets = NSDirectionalEdgeInsets(top: 5, leading: 5, bottom: 5, trailing: 5)
        let groupSize = NSCollectionLayoutSize(widthDimension: .fractionalWidth(1.0),
                                               heightDimension: .fractionalWidth(0.2))
        let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize,
                                                       subitems: [item])
        let section = NSCollectionLayoutSection(group: group)
        let layout = UICollectionViewCompositionalLayout(section: section)
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.translatesAutoresizingMaskIntoConstraints = false
        collectionView.isScrollEnabled = false
        collectionView.delegate = self
    }
    
    func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<ButtonCollectionViewCell, KeyboardItem> { (cell, indexPath, keyboardItem) in
            cell.label.text = keyboardItem.label
            cell.contentView.layer.masksToBounds = true
            cell.contentView.layer.cornerRadius = 20
            cell.contentView.layer.borderColor = UIColor.black.withAlphaComponent(0.8).cgColor
            cell.contentView.layer.borderWidth = 1
            cell.label.textAlignment = .center
            cell.label.font = UIFont.preferredFont(forTextStyle: .title1)
        }
        dataSource = UICollectionViewDiffableDataSource<Section, KeyboardItem>(collectionView: collectionView, cellProvider: { collectionView, indexPath, itemIdentifier in
            let cell = collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: itemIdentifier)
            return cell
        })
        var snapshot = NSDiffableDataSourceSnapshot<Section, KeyboardItem>()
        snapshot.appendSections([.main])
        snapshot.appendItems(keyboardItems)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
    
    // MARK: Wire Chip8 to UI
    private func configureChip() {
        try! load(file: "snake")
        let displayLink = CADisplayLink(target: self, selector: #selector(update))
        displayLink.add(to: .main, forMode: .common)
        timer = Timer.scheduledTimer(timeInterval: 1 / speed, target: self, selector: #selector(cycle), userInfo: nil, repeats: true)
    }
    
    private func load(file: String) throws {
        guard let fileUrl = Bundle.main.url(forResource: file, withExtension: "ch8") else {
            fatalError("Coudn't open file \(file)")
        }
        let data = try! Data(contentsOf: fileUrl)
        try chip8.loadROM(from: data)
    }
    
    @objc func cycle() {
        chip8.cycle()
    }
    
    @objc func update(_ displayLink: CADisplayLink) {
        let bitmap = Bitmap(buffer: chip8.video, width: 64)
        imageView.image = UIImage(bitmap: bitmap)
    }
    
    @objc func sliderDidChange() {
        speed = Double(slider.value)
        pause()
        resume()
    }
    
    private func resume() {
        timer = Timer.scheduledTimer(timeInterval: 1 / speed, target: self, selector: #selector(cycle), userInfo: nil, repeats: true)
    }
    
    private func pause() {
        timer.invalidate()
    }
}



extension ViewController {
    private func showRomPickerViewController() {
        let vc = RomPickerViewController()
        vc.modalPresentationStyle = .popover
        vc.delegate = self
        self.navigationController?.present(vc, animated: true, completion: nil)
    }
}

extension ViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        chip8.select(key: keyboardItems[indexPath.row].value)
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        chip8.deselect(key: keyboardItems[indexPath.row].value)
    }
}

extension ViewController: RomPickerDelegate {
    func didPick(rom: String) {
        chip8.reset()
        try! load(file: rom)
    }
}

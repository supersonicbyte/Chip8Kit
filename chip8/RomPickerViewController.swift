//
//  RomPickerViewController.swift
//  chip8
//
//  Created by Mirza Ucanbarlic on 7. 4. 2022..
//

import UIKit

protocol RomPickerDelegate: AnyObject {
    func didPick(rom: String)
}

class RomPickerViewController: UIViewController {
    enum Section {
        case main
    }
    weak var delegate: RomPickerDelegate?
    var dataSource: UICollectionViewDiffableDataSource<Section, String>! = nil
    var collectionView: UICollectionView! = nil
    var items = [String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        navigationItem.title = "Pick a ROM"
        configureHierarchy()
        configureDataSource()
    }
    
    private func createLayout() -> UICollectionViewLayout {
        let config = UICollectionLayoutListConfiguration(appearance: .insetGrouped)
        return UICollectionViewCompositionalLayout.list(using: config)
    }
    
    private func configureHierarchy() {
        collectionView = UICollectionView(frame: view.bounds, collectionViewLayout: createLayout())
        collectionView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.addSubview(collectionView)
        collectionView.delegate = self
    }
    private func configureDataSource() {
        let cellRegistration = UICollectionView.CellRegistration<UICollectionViewListCell, String> { (cell, indexPath, item) in
            var content = cell.defaultContentConfiguration()
            content.text = item
            cell.contentConfiguration = content
        }
        
        dataSource = UICollectionViewDiffableDataSource<Section, String>(collectionView: collectionView) {
            (collectionView: UICollectionView, indexPath: IndexPath, identifier: String) -> UICollectionViewCell? in
            
            return collectionView.dequeueConfiguredReusableCell(using: cellRegistration, for: indexPath, item: identifier)
        }
        var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
        snapshot.appendSections([.main])
        items = getRomFileNames()
        snapshot.appendItems(items)
        dataSource.apply(snapshot, animatingDifferences: false)
    }
}

extension RomPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        collectionView.deselectItem(at: indexPath, animated: true)
        let rom = items[indexPath.row]
        delegate?.didPick(rom: rom)
        dismiss(animated: true, completion: nil)
    }
}

extension RomPickerViewController {
    func getRomFileNames() -> [String] {
        let fm = FileManager.default
        let path = Bundle.main.resourcePath!
        do {
            let items = try fm.contentsOfDirectory(atPath: path)
            return items.filter {  $0.contains(".ch8") }.map { $0.replacingOccurrences(of: ".ch8", with: "")}
        } catch {
            // handle error
        }
        return []
    }
}

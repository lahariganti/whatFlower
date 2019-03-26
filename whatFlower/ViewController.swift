//
//  ViewController.swift
//  whatFlower
//
//  Created by Lahari Ganti on 2/27/19.
//  Copyright © 2019 Lahari Ganti. All rights reserved.
//

import UIKit
import CoreML
import Vision
import Alamofire
import SwiftyJSON
import SDWebImage

class ViewController: UIViewController, UINavigationControllerDelegate, UIImagePickerControllerDelegate {
    @IBOutlet weak var flowerImageView: UIImageView!
    @IBOutlet weak var flowerInfoLabel: UILabel!
    let flowerImagePicker = UIImagePickerController()
    let wikipediaURL = "https://en.wikipedia.org/w/api.php"

    override func viewDidLoad() {
        navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .camera, target: self, action: #selector(cameraTapped))
        super.viewDidLoad()
        flowerImagePicker.sourceType = .camera
        flowerImagePicker.allowsEditing = true
    }

    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        if let userPickedImage = info[UIImagePickerController.InfoKey.editedImage] as? UIImage {
            guard let coreImage = CIImage(image: userPickedImage) else {
                fatalError("could not convert picked image into CIImage")
            }
            detectImage(image: coreImage)
        }
        flowerImagePicker.dismiss(animated: true, completion: nil)
    }

    func detectImage(image: CIImage) {
        guard let model = try? VNCoreMLModel(for: FlowerClassifier().model) else {
            fatalError("training model failed to load")
        }

        let request = VNCoreMLRequest(model: model) { (request, error) in
            guard let classifications = request.results as? [VNClassificationObservation] else {
                fatalError("model failed to process image")
            }

            if let flowerName = classifications.first?.identifier {
                self.title = flowerName.capitalized
                self.fetchFlowerInfo(flowerName: flowerName)
            }
        }

        let handler = VNImageRequestHandler(ciImage: image)
        do {
            try handler.perform([request])
        } catch {
            print(error)
        }
    }

    func fetchFlowerInfo(flowerName: String) {
        let params : [String:String] = [
            "format": "json",
            "action": "query",
            "prop": "extracts|pgimages",
            "exintro": "",
            "explaintext": "",
            "titles": flowerName,
            "indexpageids": "",
            "redirects": "1",
            "pithumbsize": "500"
            ]

        Alamofire.request(wikipediaURL, method: .get, parameters: params).responseJSON { (response) in
            if response.result.isSuccess {
                if let result = response.result.value {
                    let flowerJSON = JSON(result)
                    let pageID = flowerJSON["query"]["pageid"][0].stringValue
                    let flowerDescription = flowerJSON["query"]["pages"][pageID]["extract"].stringValue
                    let flowerImage = flowerJSON["query"]["pages"][pageID]["thumbnail"]["source"].stringValue
                    self.flowerImageView.sd_setImage(with: URL(string: flowerImage))
                    self.flowerInfoLabel.text = flowerDescription
                }
            }
        }
    }

    @objc func cameraTapped() {
        present(flowerImagePicker, animated: true, completion: nil)
    }
}

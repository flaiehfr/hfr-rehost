//
//  ShareViewController.swift
//  Share
//
//  Created by Flaie on 13/01/2021.
//

import UIKit
import MobileCoreServices
import Social


@objc(CustomShareNavigationController)
class CustomShareNavigationController: UINavigationController {
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
        
        self.setViewControllers([ShareViewController()], animated: false)
    }
    
    @available(*, unavailable)
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
    }
}

@objc(ShareExtensionViewController)
class ShareViewController: UIViewController, UITableViewDelegate, UITableViewDataSource {
    let tableView = UITableView()
    var safeArea: UILayoutGuide!
    var albumLabels = ["Fetching albums..."]
    var albumSource = [String:String]()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = .systemGray6
        safeArea = view.layoutMarginsGuide
        
        // navbar
        self.navigationItem.title = "HFR Rehost"
        let itemCancel = UIBarButtonItem(barButtonSystemItem: .cancel, target: self, action: #selector(cancelAction))
        self.navigationItem.setLeftBarButton(itemCancel, animated: false)
        
        let itemDone = UIBarButtonItem(barButtonSystemItem: .done, target: self, action: #selector(doneAction))
        self.navigationItem.setRightBarButton(itemDone, animated: false)
        
        login()
        
        setupTableView()
    }
    
    func setupTableView() {
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false
        tableView.topAnchor.constraint(equalTo: safeArea.topAnchor).isActive = true
        tableView.leftAnchor.constraint(equalTo: view.leftAnchor).isActive = true
        tableView.bottomAnchor.constraint(equalTo: view.bottomAnchor).isActive = true
        tableView.rightAnchor.constraint(equalTo: view.rightAnchor).isActive = true
        
        tableView.register(UITableViewCell.self, forCellReuseIdentifier: "cell")
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let label = albumLabels[indexPath.row]
        let albumId = albumSource[label]!
        handleSharedFile(albumId: albumId)
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return albumLabels.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "cell", for: indexPath as IndexPath)
        cell.textLabel!.text = "\(albumLabels[indexPath.row])"
        return cell
    }
    
    @objc private func cancelAction() {
        let error = NSError(domain: "hfr.bundle.cancel", code: 0, userInfo: [NSLocalizedDescriptionKey: "Image wasn't uploaded"])
        extensionContext?.cancelRequest(withError: error)
    }
    
    @objc private func doneAction() {
        extensionContext?.completeRequest(returningItems: [], completionHandler: nil)
    }
    
    func getPostString(params:[String:Any]) -> String {
        var data = [String]()
        for(key, value) in params {
            data.append(key + "=\(value)")
        }
        return data.map { String($0) }.joined(separator: "&")
    }
    
    func login() {
        let url = URL(string: "https://rehost.diberie.com/Account/Login")!
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        
        // Update with your credentials
        let params = ["Email" : "foo@bar.com", "Password": "abc123"]
        let postString = self.getPostString(params: params)
        request.httpBody = postString.data(using: .utf8)
        
        let session = URLSession(configuration: .default, delegate: self, delegateQueue: nil)
        
        let task = session.dataTask(with: request) { data, response, error in
            if (error == nil) {
                
                if let httpUrlResponse = response as? HTTPURLResponse {
                    if let url = httpUrlResponse.url,
                       let allHeaderFields = httpUrlResponse.allHeaderFields as? [String : String] {
                        let cookies = HTTPCookie.cookies(withResponseHeaderFields: allHeaderFields, for: url)
                        let cookie = cookies[0]
                        
                        let jar = HTTPCookieStorage.shared
                        let cookieHeaderField = ["Set-Cookie": cookie.name + "=" + cookie.value]
                        let newCookies = HTTPCookie.cookies(withResponseHeaderFields: cookieHeaderField, for: URL(string:"https://rehost.diberie.com/")!)
                        jar.setCookies(newCookies, for: URL(string:"https://rehost.diberie.com/")!, mainDocumentURL: URL(string:"https://rehost.diberie.com/")!)
                        
                        let hostUrl = URL(string: "https://rehost.diberie.com/Host")!
                        var request2 = URLRequest(url: hostUrl)
                        request2.httpMethod = "GET"
                        
                        let task2 = URLSession.shared.dataTask(with: request2) {
                            data2, response2, error2 in
                            if(error2 == nil) {
                                let html = String(decoding: data2!, as: UTF8.self)
                                var albums = html.components(separatedBy: "\n")
                                    .filter({ $0.contains("<option value=")})
                                    .reduce(into: [String:String]()) {
                                        let value = $1.components(separatedBy:"\"")[1]
                                        let label = $1.components(separatedBy:">")[1].components(separatedBy:"<")[0]
                                        $0[label] = value
                                    }
                                
                                DispatchQueue.main.async {
                                    self.albumLabels = ["[Dossier Racine]"] + Array(albums.keys).sorted()
                                    albums["Dossier Racine"] = "0"
                                    self.albumSource = albums
                                    self.tableView.reloadData()
                                    self.tableView.setNeedsDisplay()
                                }
                            }
                        }
                        
                        task2.resume()
                    }
                }
            }
        }
        task.resume()
    }
    
    private func handleSharedFile(albumId: String) {
        let attachments = (self.extensionContext?.inputItems.first as? NSExtensionItem)?.attachments ?? []
        let contentType = kUTTypeData as String
        for provider in attachments {
            if provider.hasItemConformingToTypeIdentifier(contentType) {
                provider.loadItem(forTypeIdentifier: contentType, options: nil) {
                    [unowned self] (data, error) in
                    guard error == nil else { return }
                    
                    if let url = data as? URL,
                       let imageData = try? Data(contentsOf: url) {
                        
                        let url = URL(string: "https://rehost.diberie.com/Host/UploadFiles?SelectedAlbumId=\(albumId)")!
                        var request = URLRequest(url: url)
                        request.httpMethod = "POST"
                        let boundary = "Boundary-7MA4YWxkTLLu0UIW"
                        request.setValue("multipart/form-data; boundary=\(boundary)", forHTTPHeaderField: "Content-Type")
                        var body = Data()
                        
                        body.append("--\(boundary)\r\n")
                        body.append("Content-Disposition: form-data; name=\"foo.png\"; filename=\"foo.png\"\r\n")
                        body.append("Content-Type: image/png\r\n\r\n")
                        body.append(imageData)
                        body.append("\r\n")
                        body.append("--\(boundary)--\r\n")
                        request.httpBody = body
                        
                        let task = URLSession.shared.dataTask(with: request) { data, response, error in
                            
                            if (error == nil) {
                                do {
                                    let resp = try JSONDecoder().decode(Upload.self, from: data!)
                                    let pasteboard = UIPasteboard.general
                                    pasteboard.string = resp.resizedBBLink!
                                    
                                    DispatchQueue.main.async {
                                        self.showToast(message: " BBCode in clipboard ", font: .systemFont(ofSize: 16.0))
                                    }
                                    
                                    DispatchQueue.main.asyncAfter(deadline: .now() + 1) {
                                        self.doneAction()
                                    }
                                } catch let error {
                                    print(error)
                                }
                            }
                        }
                        task.resume()
                    }
                }
            }
        }
    }
}

struct Upload: Codable {
    let comment: String?
    let picBB: String?
    let picURL: String?
    let picID: Int?
    let previewHeight: String?
    let previewWidth: String?
    let resizedBBLink: String?
    let resizedURL: String?
    let thumbBB: String?
    let thumbBBLink: String?
    let thumbURL: String?

    enum CodingKeys: String, CodingKey {
        case comment = "comment"
        case picBB = "picBB"
        case picURL = "picURL"
        case picID = "picID"
        case previewHeight = "previewHeight"
        case previewWidth = "previewWidth"
        case resizedBBLink = "resizedBBLink"
        case resizedURL = "resizedURL"
        case thumbBB = "thumbBB"
        case thumbBBLink = "thumbBBLink"
        case thumbURL = "thumbURL"
    }
}

extension Data {
    mutating func append(_ string: String, using encoding: String.Encoding = .utf8) {
        if let data = string.data(using: encoding) {
            append(data)
        }
    }
}


extension UIViewController {

func showToast(message : String, font: UIFont) {

    let toastLabel = UILabel(frame: CGRect(x: self.view.frame.size.width/2 - 75, y: self.view.frame.size.height-100, width: 150, height: 35))
    toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.6)
    toastLabel.textColor = UIColor.white
    toastLabel.font = font
    toastLabel.textAlignment = .center;
    toastLabel.text = message
    toastLabel.alpha = 1.0
    toastLabel.layer.cornerRadius = 10;
    toastLabel.clipsToBounds  =  true
    self.view.addSubview(toastLabel)
    UIView.animate(withDuration: 4.0, delay: 0.1, options: .curveEaseOut, animations: {
         toastLabel.alpha = 0.0
    }, completion: {(isCompleted) in
        toastLabel.removeFromSuperview()
    })
} }

extension ShareViewController: URLSessionDelegate, URLSessionTaskDelegate {
    func urlSession(_ session: URLSession, task: URLSessionTask, willPerformHTTPRedirection response: HTTPURLResponse, newRequest request: URLRequest, completionHandler: @escaping (URLRequest?) -> Void) {
        // Stops the redirection, and returns (internally) the response body.
        completionHandler(nil)
    }
}

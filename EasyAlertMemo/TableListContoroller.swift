//
//  TableListContoroller.swift
//  simpleAlertMemo
//
//  Created by 津本拓也 on 2023/11/03.
//

import UIKit
import UserNotifications


class ListController: UIViewController,UITableViewDelegate,UITableViewDataSource {
    //    class pickerContoroller: ListController,UIPickerViewDelegate,UIPickerViewDataSource {
    @IBOutlet var tableView: UITableView!
    
    var receivedData: String?
    var notification: String?
    var details: [String] = ["",""] {
        didSet {
            tableView.reloadData()
        }
    }
    //    var pickerSelectString: String?
    var pickerIndexPath: IndexPath?
    let pickerData = (10...30).map { String($0) }
    var fontSizeVariableA: String?
    let pickerView = UIPickerView()
    let textField = UITextField(frame: CGRect.zero)
    
    //    フォントサイズピッカーのスタートを設定値から始める
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        let selectedRow = UserDefaults.standard.integer(forKey: "pickerValue")
        pickerView.selectRow(selectedRow, inComponent: 0, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        //        フォントサイズの設定値をdetalisへ格納
        if let fontSizeString = UserDefaults.standard.value(forKey: "newFontSize") as? String {
            details[0] = fontSizeString
        } else {
            details[0] = "15"
        }
        
        //        通知のオンオフ表記をdetailsに格納
        if let notificationTrue = receivedData{
//            notification = notificationTrue
            details[1] = notificationTrue
//            details.append(notificationTrue)
        }
        
        //        ピッカービューの見た目を設定
        pickerView.delegate = self
        pickerView.dataSource = self
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissPicker))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
        
        let toolBar = UIToolbar()
        toolBar.sizeToFit()
        
        let doneButton = UIBarButtonItem(title: "完了", style: .plain, target: self, action: #selector(self.donePicker))
        let spaceButton = UIBarButtonItem(barButtonSystemItem: .flexibleSpace, target: nil, action: nil)
        
        toolBar.setItems([spaceButton, doneButton], animated: false)
        toolBar.isUserInteractionEnabled = true
        
        textField.inputAccessoryView = toolBar
    }
    
    //    セルの設定
    let settings = ["フォントサイズ","通知状態"]
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return settings.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "Cell", for: indexPath)

        cell.textLabel!.text = settings[indexPath.row]
        cell.detailTextLabel?.text = details[indexPath.row]
        return cell
    }
}


extension ListController: UIPickerViewDelegate,UIPickerViewDataSource {
    
    //    セルをタップした時の処理
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        switch indexPath.row {
        case 0:
            textField.inputView = pickerView
            self.view.addSubview(textField)
            textField.becomeFirstResponder()
            fontSizeVariableA = textField.text
            
        case 1:
            alertSetting()
            
        default:
            break
        }
        tableView.deselectRow(at: indexPath, animated: true)
    }
    
    private func alertSetting() {
        let alertController = UIAlertController(title: "通知設定", message: "通知を設定しますか？", preferredStyle: .alert)
        alertController.addAction(UIAlertAction(title: "設定を開く", style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url, options: [:], completionHandler: nil)
            }
        }))
        alertController.addAction(UIAlertAction(title: "キャンセル", style: .cancel))
        
        present(alertController, animated: true)
    }
    
    //    ピッカービューの設定
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 1
    }
    func pickerView(_ pickerView: UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        pickerData.count
    }
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        pickerData[row]
    }
    
    //    画面外をタップして、ピッカービューを閉じる
    @objc func dismissPicker() {
        view.endEditing(true)
    }
    
    //    ピッカービューの完了ボタンを押した処理
    @objc func donePicker() {
        let selectedRow = pickerView.selectedRow(inComponent: 0)
        UserDefaults.standard.set(selectedRow, forKey: "pickerValue")
        textField.text = pickerData[selectedRow]
        fontSizeVariableA = textField.text
        
        if  fontSizeVariableA != nil {
            UserDefaults.standard.set(fontSizeVariableA, forKey: "newFontSize")
        }
        if let fontSizeString = UserDefaults.standard.value(forKey: "newFontSize") as? String {
            details[0] = fontSizeString
        }
        view.endEditing(true)
    }
}

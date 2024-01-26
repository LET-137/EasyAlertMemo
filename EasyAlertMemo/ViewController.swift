//
//  ViewController.swift
//  simpleAlertMemo
//
//  Created by 津本拓也 on 2023/11/03.
//

import UIKit
import UserNotifications


class ViewController: UIViewController,UITextViewDelegate {
    @IBOutlet weak var textView: UITextView!
    @IBOutlet weak var datePicker: UIDatePicker!
    @IBOutlet weak var setUpLabel: UILabel!
  
    
    var dataToPass: String = ""
    let currentDate = Date()

//    設定されている時刻を取得
    func fetchTargetTime() -> Date? {
        let defaults = UserDefaults.standard
        guard let month = defaults.value(forKey: "month") as? Int,let day = defaults.value(forKey: "day") as? Int,let hour = defaults.value(forKey: "hour") as? Int,let minute = defaults.value(forKey: "minute") as? Int else {
            return nil
        }
        var targetComponents = DateComponents()
        let year = Calendar.current.component(.year, from: currentDate)
        targetComponents.year = year
        targetComponents.month = month
        targetComponents.day = day
        targetComponents.hour = hour
        targetComponents.minute = minute
        targetComponents.timeZone = TimeZone(identifier: "Asia/Tokyo")
        
        guard let targetDate = Calendar.current.date(from: targetComponents) else {return nil}
        return targetDate
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // 次の画面のBackボタンを「戻る」に変更
            self.navigationItem.backBarButtonItem = UIBarButtonItem(title:  "戻る", style:  .plain, target: nil, action: nil)
        
//      枠線の設定
        NotificationCenter.default.addObserver(self, selector: #selector(handleAppWillEnterForeground), name: UIApplication.willEnterForegroundNotification, object: nil)
        //        self.view.backgroundColor = UIColor.white
        textView.backgroundColor = UIColor.white
        textView.layer.borderColor = UIColor.gray.cgColor
        textView.layer.borderWidth = 0.3
        textView.layer.cornerRadius = 5.0
        textView.textColor = UIColor.black
        datePicker.setValue(UIColor.black, forKey: "textColor")
        datePicker.layer.backgroundColor = UIColor.white.cgColor
        textView.becomeFirstResponder()
        
        if let fontSizeString = UserDefaults.standard.value(forKey: "newFontSize") as? String {
            textView.font = UIFont.systemFont(ofSize: 15)
        }
        
//        テキストビューの設定
        if let savedText = UserDefaults.standard.string(forKey: "memo") {
            textView.text = savedText
        }
        if textView.text == "" {
            textView.delegate = self
            textView.text = "ここにメモを入力してください" // プレースホルダーとしてのテキスト
            textView.textColor = UIColor.lightGray
        }
        if let savedSetUp = UserDefaults.standard.string(forKey: "setUp") {
            setUpLabel.text = savedSetUp
        }
                
        //   現在時刻よりも過去を選択できないようにする
        datePicker.minimumDate = currentDate
        // Do any additional setup after loading the view.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
            // Handle error
        }
        
//           通知のオン、オフを判定
            UNUserNotificationCenter.current().getNotificationSettings { setting in
            if setting.authorizationStatus == .authorized {
                self.dataToPass = "ON"
            } else {
                self.dataToPass = "OFF"
            }
        }
    }
    

    override func viewDidAppear(_ animated: Bool) {
        textView.becomeFirstResponder()
    }
    //    通知の状態を設定画面のコードに引き継ぎ
    override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
        if segue.identifier == "showListScreen" {
            if let destinationVC = segue.destination as? ListController {
                destinationVC.receivedData = dataToPass
            }
        }
    }
    
//    フォントサイズを設定
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        if let fontSizeString = UserDefaults.standard.value(forKey: "newFontSize") as? String {
            let fontSize: Int! = Int(fontSizeString)
            textView.font = UIFont.systemFont(ofSize: CGFloat(fontSize))
        }
        
        
        let currentDate = Date()
        if let targetDate = fetchTargetTime() {
            if currentDate > targetDate {
                setUpLabel.text = nil
                UserDefaults.standard.set(setUpLabel.text, forKey: "setUp")
            }
        }
    }
    //    キーボードを画面外をタップすることで非表示に
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.view.endEditing(true)
    }
    
    //    フォアグラウンドに戻った時の処理
    @objc func handleAppWillEnterForeground() {
        let currentDate = Date()
        
        datePicker.minimumDate = currentDate
        // Do any additional setup after loading the view.
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
        }
        
        UNUserNotificationCenter.current().getNotificationSettings { setting in
            if setting.authorizationStatus == .authorized {
                self.dataToPass = "ON"
            } else {
                self.dataToPass = "OFF"
            }
        }
        
        if let targetDate = fetchTargetTime() {
            if currentDate > targetDate {
                setUpLabel.text = nil
                UserDefaults.standard.set(setUpLabel.text, forKey: "setUp")
            }
        }
        textView.becomeFirstResponder()
    }
    
    @IBAction func okButton(_ sender: Any) {
        UserDefaults.standard.set(textView.text, forKey: "memo")
        
        scheduleNotification(at: datePicker.date)
    }
    
//    通知トリガーを設定
    func scheduleNotification(at date: Date) {
        let calendar = Calendar(identifier: .gregorian)
        let components = calendar.dateComponents(in: .current, from: date)
        let newComponents = DateComponents(calendar: calendar, timeZone: .current, month: components.month, day:components.day, hour:components.hour,minute:components.minute)
        
        
        let trigger = UNCalendarNotificationTrigger(dateMatching: newComponents, repeats: false)
        
        let content = UNMutableNotificationContent()
        content.title = "メモ"
        content.body = textView.text
        content.sound = UNNotificationSound.default
        
        let request = UNNotificationRequest(identifier: "uniqueIdentifier", content:  content, trigger: trigger)
        UNUserNotificationCenter.current().add(request)
        
        guard let newDate = newComponents.date else {
            print("データが見つかりません")
            return
        }
        let current = Date()
        let currentMonht = calendar.component(.month, from: current)
        let currentDay = calendar.component(.day, from: current)
        
        let formatter = DateFormatter()
        let defaults = UserDefaults.standard
        
        //        設定時刻を中央上部に表示
        if currentMonht == components.month && currentDay == components.day {
            formatter.dateFormat = "HH:mm"
            let dateString = "本日 " + formatter.string(from: newDate) + " に設定中"
            defaults.set(dateString,forKey: "setUp")
            setUpLabel.text = dateString
        } else {
            formatter.dateFormat = "MM/dd HH:mm"
            let dateString = formatter.string(from: newDate) + " に設定中"
            defaults.set(dateString,forKey: "setUp")
            setUpLabel.text = dateString
        }
        
        defaults.set(newComponents.month,forKey: "month")
        defaults.set(newComponents.day,forKey: "day")
        defaults.set(newComponents.hour,forKey: "hour")
        defaults.set(newComponents.minute,forKey: "minute")
    }
    
    //    リセットボタンを押してリセット
    @IBAction func textRecet(_ sender: Any) {
        textView.text = ""
        UserDefaults.standard.set(textView.text,forKey: "memo")
        setUpLabel.text = nil
        UserDefaults.standard.set(setUpLabel.text,forKey: "setUp")
        let center = UNUserNotificationCenter.current()
        center.removePendingNotificationRequests(withIdentifiers: ["uniqueIdentifier"])
    }
    
    //    textViewにプレースホルダーを入力
    func textViewDidBeginEditing(_ textView: UITextView) {
        if textView.textColor == UIColor.lightGray {
            textView.text = nil
            textView.textColor = UIColor.black
        }
    }
    
    func textViewDidEndEditing(_ textView: UITextView) {
        if textView.text.isEmpty {
            textView.text = "メモを入力してください"
            textView.textColor = UIColor.lightGray
        }
    }
    
    override var supportedInterfaceOrientations: UIInterfaceOrientationMask {
        return .portrait
    }
}
//

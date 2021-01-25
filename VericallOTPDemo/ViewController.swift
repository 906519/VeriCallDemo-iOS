//
//  ViewController.swift
//  VericallOTPDemo
//
//  Created by Alvin Resmana on 2020/12/16.
//

import UIKit
import VeriCallOTP

class ViewController: UIViewController {
    private lazy var service: VeriCallOTP = VeriCallOTP(baseURL: "Base_URL", xApiKey: "Your_API_KEY")
    
    @IBOutlet var rOTPBtn: UIButton!
    @IBOutlet var rAI: UIActivityIndicatorView!
    
    @IBOutlet var verifyView: UIView!
    @IBOutlet var textField: UITextField!
    @IBOutlet var vBtn: UIButton!
    @IBOutlet var vAI: UIActivityIndicatorView!
    
    @IBOutlet weak var otpIdTF: UITextField!
    var otpId: String = ""
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
    }
    
    @IBAction func requestOTPAction(_ sender: Any) {
        //otpID = can be anything like memberId or any uniqueID
        otpId = self.otpIdTF.text ?? ""
        
        if otpId.isEmpty {
            showAlertStatus(title: "", message: "Please input OTP id")
            return
        }
        requestOTP()
    }
    
    @IBAction func verifyOTPAction(_ sender: Any) {
        verifyOTP(otpId: otpId)
    }
    
    // Request OTP
    func requestOTP() {
        let requestData: VCOTPRequest.OTPRequest = VCOTPRequest.OTPRequest(duration: 60, length: 3, maxAttempt: 3, user: "Phone_Number", ringingDuration: 1, device_id: "UUID/AnyUniqueID")
        rAI.isHidden = false
        
        self.service.sendVericallOtp(uniqueId: otpId, requestData: requestData) {[weak self] (result) in
            
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.rAI.isHidden = true
            }
            
            switch result {
            
            case .success(let response):
                if let response: VeriCallOTPResponse = response {
                    print("user: ", response.user ?? "")
                    print("duration: ", response.duration ?? 0)
                    print("maxAttempt: ", response.max_attempt ?? 0)
                    print("length: ", response.length ?? 0)
                    print("ringingDuration: ", response.ringing_duration ?? 0)
                    print("prefix: ", response.prefix ?? "")
                    print("device_id: ", response.device_id ?? "")
                    DispatchQueue.main.async {
                        if let prefix: String = response.prefix {
                            self.showAlertStatus(title: "OTP Sent", message: "Caller Prefix: \(prefix)")
                        }
                    }
                    
                    let reqData: VCOTPRequest.ReceiveRequest = VCOTPRequest.ReceiveRequest(device_id: response.device_id)
                    
                    // Receiving OTP Code, because iOS block access to user recent call.
                    self.service.receiveVericallOtp(otpId: self.otpId, requestData: reqData) {[weak self] (result) in
                        guard let self = self else { return }
                        
                        switch result {
                        
                        case .success(let response):
                            DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
                                if let otp_code = response?.otp_code {
                                    self.textField.text = otp_code
                                }
                            }
                            
                        case .failure(let error):
                            DispatchQueue.main.async {
                                switch error.systemCode {
                                case .MissingAPIKey:
                                    self.showAlertStatus(title: "OTP Fail", message: "" )
                                default:
                                    self.showAlertStatus(title: "OTP Fail", message: "" )
                                }
                            }
                            
                            print(error.systemCode)
                        }
                    }
                }
                
                break
                
            case .failure(let error):
                DispatchQueue.main.async {
                    print(error.systemCode)
                    if let message: String = error.message {
                        self.showAlertStatus(title: "Error", message: message)
                    }
                    
                    DispatchQueue.main.async {
                        switch error.systemCode {
                        case .OtherSituation:
                            self.showAlertStatus(title: "OTP Fail", message: "\(String(describing: error.httpCode?.description))" )
                        default:
                            self.showAlertStatus(title: "OTP Fail", message: "" )
                        }
                    }
                }
                
                break
            }
        }
    }
    
    func verifyOTP(otpId: String) {
        let requestData: VCOTPRequest.VerifyRequest = VCOTPRequest.VerifyRequest(password: self.textField.text)
        vAI.isHidden = false
        self.service.verifyMisscallOtp(otpId: otpId, requestData: requestData) {[weak self] (result) in
            
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.vAI.isHidden = true
            }
            
            switch result {
            
            case .success(let response):
                if let message: String = response?.message {
                    DispatchQueue.main.async {
                        self.showAlertStatus(title: "Success", message: message)
                    }
                }
                break
                
            case .failure(let error):
                DispatchQueue.main.async {
                    print(error.systemCode)
                    print(error.message)
                    self.showAlertStatus(title: "Fail", message: error.message)
                }
                
                break
            }
        }
    }
    
    func showAlertStatus(title: String, message: String) {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: UIAlertAction.Style.default, handler: nil))
        self.present(alert, animated: true, completion: nil)
    }
}



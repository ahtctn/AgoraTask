//
//  LoginRegisterViewController.swift
//  AgoraTask
//
//  Created by Ahmet Ali ÇETİN on 8.04.2023.
//

import UIKit
import FirebaseAuth
import FirebaseCore

class LoginRegisterViewController: UIViewController {

    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var firebaseLoginButton: UIButton!
    @IBOutlet weak var firebaseRegisterButton: UIButton!
    
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
    private func alertUserLoginError() {
        let alert = UIAlertController(title: "Woops", message: "Please enter all information correctly.", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Dissmis", style: .cancel))
        present(alert, animated: true)
    }


    @IBAction func firebaseLoginButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, let password = passwordTextField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        print("registiration successful to firebase")
        
        let vc = self.storyboard?.instantiateViewController(withIdentifier: "FinalScreen") as! ViewController
        self.navigationController?.pushViewController(vc, animated: true)
        
//        let vc = storyboard?.instantiateViewController(withIdentifier: "LoginNRegisterID")
//        self.navigationController?.pushViewController(vc!, animated: true)
    }

    @IBAction func firebaseRegisterButtonTapped(_ sender: UIButton) {
        guard let email = emailTextField.text, let password = passwordTextField.text,
              !email.isEmpty, !password.isEmpty, password.count >= 6 else {
            alertUserLoginError()
            return
        }
        
        Auth.auth().createUser(withEmail: email, password: password) { user, error in
            if error != nil {
                print(error?.localizedDescription as Any)
            }
            
            print("registiration successfull for firebase")
            print("\(user?.user) logged in")
            let vc = self.storyboard?.instantiateViewController(withIdentifier: "FinalScreen") as! ViewController
            
            self.navigationController?.pushViewController(vc, animated: true)
            
            
            
        }
        
//        let vc = storyboard?.instantiateViewController(withIdentifier: "LoginNRegisterID")
//        self.navigationController?.pushViewController(vc!, animated: true)
    }


}

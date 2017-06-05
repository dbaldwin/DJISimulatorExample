//
//  LoginViewController.swift
//  DJISimulatorExample
//
//  Created by CANO-14 on 25/05/17.
//  Copyright © 2017 Unmanned Airlines, LLC. All rights reserved.
//

import UIKit
import GoogleSignIn
import FirebaseAuth
import FacebookCore
import FacebookLogin

class LoginViewController: UIViewController {

    @IBOutlet weak var activityIndicator: UIActivityIndicatorView!
    @IBOutlet weak var signInButton: GIDSignInButton!
    
    var loginButton : LoginButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        initialConfiguration()
    }
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    @IBAction func actionOnFacebookLogin(_ sender: Any) {
        
        if let accessToken = AccessToken.current {
            let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
            self.authenticateWithFirebase(credential: credential)
        }else{
        let loginManager = LoginManager()
        loginManager.logIn([ .publicProfile ], viewController: self) { loginResult in
            switch loginResult {
            case .failed(let error):
                debugPrint(error.localizedDescription)
                self.showAlert(title: "Message", message: "Could not sign in right now, Please try again later")
                break
            case .cancelled:
                break
            case .success(_, _, let accessToken):
                print("Logged in!")
                let credential = FacebookAuthProvider.credential(withAccessToken: accessToken.authenticationToken)
                self.authenticateWithFirebase(credential: credential)
                break
            }
         }
       }
    }
 
    //MARK:- UIButton Action Method
    @IBAction func actionOnLoginWithGoogleButton(_ sender: Any) {
    }
    
}

//Private Methods
fileprivate extension LoginViewController {

    func initialConfiguration() -> Void {
        
        GIDSignIn.sharedInstance().delegate = self
        GIDSignIn.sharedInstance().uiDelegate = self
        signInButton.colorScheme = .dark
        signInButton.style = .wide
        activityIndicator.isHidden = true
        
    }
    func showProgress() -> Void {
        activityIndicator.isHidden = false
        activityIndicator.startAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = true
    }
    func hideProgress() -> Void {
        activityIndicator.isHidden = true
        activityIndicator.stopAnimating()
        UIApplication.shared.isNetworkActivityIndicatorVisible = false
    }

    
    func authenticateWithFirebase(credential:AuthCredential){
        Auth.auth().signIn(with: credential) { (user, error) in
            // ...
            self.hideProgress()
            if let error = error {
                debugPrint(error.localizedDescription)
                self.showAlert(title: "Message", message: "Could not sign in right now, Please try again later")
                return
            }else{
                self.performSegue(withIdentifier: "backToDB", sender: nil)
            }
        }
    }
}

//MARK:- Signin UI delegate
extension LoginViewController : GIDSignInDelegate,GIDSignInUIDelegate {
    //MARK:- Google Sign In Delegate
    func sign(_ signIn: GIDSignIn!, didSignInFor user: GIDGoogleUser!, withError error: Error?) {
        // ...
        if let error = error {
            debugPrint(error)
            self.showAlert(title: "Message", message: "Could not sign in right now, Please try again later")
            self.hideProgress()
            return
        }
        
        guard let authentication = user.authentication else { return }
        let credential = GoogleAuthProvider.credential(withIDToken: authentication.idToken,
                                                       accessToken: authentication.accessToken)
        self.authenticateWithFirebase(credential: credential)
    }
    
    func sign(_ signIn: GIDSignIn!, didDisconnectWith user: GIDGoogleUser!, withError error: Error!) {
    }
    
    func sign(inWillDispatch signIn: GIDSignIn!, error: Error!) {
        showProgress()
    }
    
}

extension UIViewController {
    
    func showAlert(title:String?,message:String?) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction((UIAlertAction(title: "Ok", style: .cancel, handler: nil)))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
    
    func showAlert(title:String?,message:String?,withCompletion completion:@escaping ((_ action:AnyObject)->Void)) -> Void {
        let alert = UIAlertController(title: title, message: message, preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Ok", style: .cancel, handler: { (action) in
            completion(action)
        }))
        DispatchQueue.main.async {
            self.present(alert, animated: true, completion: nil)
        }
    }
}


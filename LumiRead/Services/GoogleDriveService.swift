import Foundation
import GoogleSignIn
import GoogleAPIClientForREST_Drive

class GoogleDriveService: ObservableObject {
    static let shared = GoogleDriveService()
    
    @Published var isSignedIn = false
    @Published var userEmail: String? = nil
    
    private let service = GTLRDriveService()
    
    init() {
        checkSignInStatus()
    }
    
    func checkSignInStatus() {
        if let user = GIDSignIn.sharedInstance.currentUser {
            self.isSignedIn = true
            self.userEmail = user.profile?.email
            self.configureService(with: user)
        } else {
            self.isSignedIn = false
            self.userEmail = nil
        }
    }
    
    private func configureService(with user: GIDGoogleUser) {
        if user.accessToken != nil {
            service.authorizer = user.fetcherAuthorizer
        }
    }
    
    func signIn(completion: @escaping (Bool, Error?) -> Void) {
        guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let presentingViewController = windowScene.windows.first?.rootViewController else {
            completion(false, NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取根视图控制器"]))
            return
        }
        
        GIDSignIn.sharedInstance.signIn(withPresenting: presentingViewController) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                completion(false, error)
                return
            }
            
            guard let user = result?.user else {
                completion(false, NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取用户信息"]))
                return
            }
            
            self.isSignedIn = true
            self.userEmail = user.profile?.email
            self.configureService(with: user)
            completion(true, nil)
        }
    }
    
    func signOut(completion: @escaping (Bool, Error?) -> Void) {
        GIDSignIn.sharedInstance.signOut()
        self.isSignedIn = false
        self.userEmail = nil
        completion(true, nil)
    }
    
    func listJSONFiles(completion: @escaping ([GTLRDrive_File]?, Error?) -> Void) {
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "mimeType='application/json'"
        query.fields = "files(id, name, modifiedTime)"
        
        service.executeQuery(query) { (ticket, result, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let fileList = result as? GTLRDrive_FileList else {
                completion(nil, NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取文件列表"]))
                return
            }
            
            completion(fileList.files, nil)
        }
    }
    
    func downloadFile(fileId: String, completion: @escaping (Data?, Error?) -> Void) {
        let query = GTLRDriveQuery_FilesGet.queryForMedia(withFileId: fileId)
        
        service.executeQuery(query) { (ticket, result, error) in
            if let error = error {
                completion(nil, error)
                return
            }
            
            guard let data = (result as? GTLRDataObject)?.data else {
                completion(nil, NSError(domain: "GoogleDriveService", code: -1, userInfo: [NSLocalizedDescriptionKey: "无法获取文件数据"]))
                return
            }
            
            completion(data, nil)
        }
    }
}
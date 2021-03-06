
//
//  AppDelegate.swift
//  minimalTunes
//
//  Created by John Moody on 5/29/16.
//  Copyright © 2016 John Moody. All rights reserved.
//

import Cocoa
//import sReto


@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate {
    
    var mainWindowController: MainWindowController?
    var databaseManager: DatabaseManager?
    var preferencesWindowController: PreferencesWindowController?
    var setupWindowController: InitialSetupWindowController?
    var equalizerWindowController: EqualizerWindowController?
    var importWindowController: ImportWindowController?
    var importProgressBar: ImportProgressBar?
    var iTunesParser: iTunesLibraryParser?
    var audioModule: AudioModule = AudioModule()
    let fileHandler = FileManager.default
    let handler = DatabaseManager()
    var serviceBrowser: ConnectivityManager?
    var importErrorWindowController: ImportErrorWindowController?
    @IBOutlet weak var shuffleMenuItem: NSMenuItem!
    @IBOutlet weak var repeatMenuItem: NSMenuItem!
    
    @IBAction func jumpToCurrentSong(_ sender: AnyObject) {
        mainWindowController!.jumpToCurrentSong()
    }
    
    @IBAction func previousMenuItemAction(_ sender: AnyObject) {
        mainWindowController?.skipBackward()
    }
    @IBAction func nextMenuItemAction(_ sender: AnyObject) {
        mainWindowController?.skip()
    }
    @IBAction func pauseMenuItemAction(_ sender: AnyObject) {
        if mainWindowController!.paused != true {
            mainWindowController?.pause()
        }
    }
    
    @IBAction func playMenuItemAction(_ sender: AnyObject) {
        if mainWindowController!.paused != false {
            mainWindowController?.playPressed(self)
        }
    }
    @IBAction func shuffleMenuItemAction(_ sender: AnyObject) {
        shuffleMenuItem.state = shuffleMenuItem.state == NSOnState ? NSOffState : NSOnState
        mainWindowController?.shuffleButton.state = shuffleMenuItem.state
        mainWindowController?.shuffleButtonPressed(self)
    }
    
    @IBAction func repeatMenuItemAction(_ sender: AnyObject) {
        repeatMenuItem.state = repeatMenuItem.state == NSOnState ? NSOffState : NSOnState
        mainWindowController?.repeatButton.state = repeatMenuItem.state
        mainWindowController?.repeatButtonPressed(self)
    }
    
    func initializeLibraryAndShowMainWindow() {
        mainWindowController = MainWindowController(windowNibName: "MainWindowController")
        mainWindowController?.delegate = self
        if UserDefaults.standard.bool(forKey: "hasMusic") == true {
            mainWindowController?.hasMusic = true
        }
        else {
            mainWindowController?.hasMusic = false
        }
        mainWindowController?.showWindow(self)
        self.serviceBrowser = ConnectivityManager(delegate: self, slvc: mainWindowController!.sourceListViewController!)
        let defaultsEQOnState = UserDefaults.standard.integer(forKey: DEFAULTS_IS_EQ_ENABLED_STRING)
        audioModule.toggleEqualizer(defaultsEQOnState)
    }
    
    @IBAction func openImportWindow(_ sender: AnyObject) {
        importWindowController = ImportWindowController(windowNibName: "ImportWindowController")
        importWindowController?.mainWindowController = mainWindowController
        importWindowController?.showWindow(self)
    }
    
    @IBAction func addToLibrary(_ sender: AnyObject) {
        openFiles()
    }
    
    func getFilesAsURLStringsInURLList(_ urls: [URL]) -> ([String],[FileAddToDatabaseError]) {
        var urlStrings = [String]()
        var errors = [FileAddToDatabaseError]()
        for url in urls {
            var isDirectory = ObjCBool(true)
            if fileHandler.fileExists(atPath: url.path, isDirectory: &isDirectory) {
                if isDirectory.boolValue {
                    
                    let enumerator = fileHandler.enumerator(at: url, includingPropertiesForKeys: nil, options: .skipsHiddenFiles, errorHandler: self.handler.handleDirectoryEnumerationError)
                    for fileURLElement in enumerator! {
                        let fileURL = fileURLElement as! URL
                        if fileURL.pathExtension != nil && VALID_FILE_TYPES.contains(fileURL.pathExtension.lowercased()) {
                            urlStrings.append(fileURL.absoluteString)
                        } else {
                            let error = FileAddToDatabaseError(url: fileURL.absoluteString, error: "invalid file type")
                            errors.append(error)
                        }
                    }
                } else {
                    if url.pathExtension != nil && VALID_FILE_TYPES.contains(url.pathExtension.lowercased()) {
                        urlStrings.append(url.absoluteString)
                    }
                }
            }
        }
        return (urlStrings, errors)
    }
    
    func openFiles() {
        let myFileDialog: NSOpenPanel = NSOpenPanel()
        myFileDialog.allowsMultipleSelection = true
        myFileDialog.allowedFileTypes = VALID_FILE_TYPES
        myFileDialog.canChooseDirectories = true
        let modalResult = myFileDialog.runModal()
        if modalResult == NSFileHandlingPanelOKButton {
            let directoryCrawlResult = getFilesAsURLStringsInURLList(myFileDialog.urls)
            let urlStrings = directoryCrawlResult.0
            var errors = directoryCrawlResult.1
            let errorResults = addURLStringsToLibrary(urlStrings)
            errors.append(contentsOf: errorResults)
            showImportErrors(errors)
            UserDefaults.standard.set(true, forKey: "hasMusic")
            self.mainWindowController?.hasMusic = true
        }
    }
    
    func showImportErrors(_ errors: [FileAddToDatabaseError]) {
        if errors.count > 0 {
            self.importErrorWindowController = ImportErrorWindowController(windowNibName: "ImportErrorWindowController")
            self.importErrorWindowController?.errors = errors
            self.importErrorWindowController?.showWindow(self)
        }
    }
    
    func addURLStringsToLibrary(_ urlStrings: [String]) -> [FileAddToDatabaseError] {
        let result = handler.addTracksFromURLStrings(urlStrings)
        return result
    }
    
    func initializeProgressBarWindow() {
        importProgressBar = ImportProgressBar(windowNibName: "ImportProgressBar")
        importProgressBar!.iTunesParser = self.iTunesParser!
        importProgressBar!.initialize()
        importProgressBar!.showWindow(self)
    }

    @IBAction func openPreferences(_ sender: AnyObject) {
        preferencesWindowController = PreferencesWindowController(windowNibName: "PreferencesWindowController")
        preferencesWindowController?.showWindow(self)
    }
    
    func showEqualizer() {
        print("show equalizer called")
        self.equalizerWindowController = EqualizerWindowController(windowNibName: "EqualizerWindowController")
        self.equalizerWindowController?.audioModule = self.audioModule
        self.equalizerWindowController?.showWindow(self)
    }
    
    @IBAction func showAdvancedFilter(_ sender: AnyObject) {
        if let item = sender as? NSMenuItem {
            item.state = item.state == NSOnState ? NSOffState : NSOnState
        }
        mainWindowController?.toggleFilterVisibility(self)
    }
    
    @IBAction func testyThing(_ sender: AnyObject) {
        showEqualizer()
    }
    
    func setInitialDefaults() {
        UserDefaults.standard.set(NSOffState, forKey: "shuffle")
        UserDefaults.standard.set(NSOnState, forKey: "queueVisible")
    }
    
    func applicationDidFinishLaunching(_ aNotification: Notification) {
        for fetchRequest in BATCH_PURGE_NETWORK_FETCH_REQUESTS {
            do {
                fetchRequest.predicate = IS_NETWORK_PREDICATE
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try persistentStoreCoordinator.execute(deleteRequest, with: managedObjectContext)
            } catch {
                print(error)
            }
        }
        purgeCurrentlyPlaying()
        // Insert code here to initialize your application
        let fuckTransform = TransformerIntegerToTimestamp()
        databaseManager = DatabaseManager()
        ValueTransformer.setValueTransformer(fuckTransform, forName: NSValueTransformerName("AssTransform"))
        if UserDefaults.standard.bool(forKey: DEFAULTS_ARE_INITIALIZED_STRING) != true {
            print("has not started before")
            setInitialDefaults()
            setupWindowController = InitialSetupWindowController(windowNibName: "InitialSetupWindowController")
            setupWindowController?.showWindow(self)
        } else {
            initializeLibraryAndShowMainWindow()
        }
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        // Insert code here to tear down your application
         do {
         try managedObjectContext.save()
         } catch {
         fatalError("Failure to save context: \(error)")
         }
    }
    
    func showMainWindow() {
        mainWindowController = MainWindowController(windowNibName: "MainWindowController")
        mainWindowController!.showWindow(self)
    }

    // MARK: - Core Data stack

    lazy var applicationDocumentsDirectory: URL = {
        // The directory the application uses to store the Core Data store file. This code uses a directory named "jcm.minimalTunes" in the user's Application Support directory.
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls[urls.count - 1]
        return appSupportURL.appendingPathComponent("jcm.jmc")
    }()

    lazy var managedObjectModel: NSManagedObjectModel = {
        // The managed object model for the application. This property is not optional. It is a fatal error for the application not to be able to find and load its model.
        let modelURL = Bundle.main.url(forResource: "jmc", withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()

    lazy var persistentStoreCoordinator: NSPersistentStoreCoordinator = {
        // The persistent store coordinator for the application. This implementation creates and returns a coordinator, having added the store for the application to it. (The directory for the store is created, if necessary.) This property is optional since there are legitimate error conditions that could cause the creation of the store to fail.
        let fileManager = FileManager.default
        var failError: NSError? = nil
        var shouldFail = false
        var failureReason = "There was an error creating or loading the application's saved data."

        // Make sure the application files directory is there
        do {
            let properties = try (self.applicationDocumentsDirectory as NSURL).resourceValues(forKeys: [URLResourceKey.isDirectoryKey])
            if !(properties[URLResourceKey.isDirectoryKey]! as AnyObject).boolValue {
                failureReason = "Expected a folder to store application data, found a file \(self.applicationDocumentsDirectory.path)."
                shouldFail = true
            }
        } catch  {
            let nserror = error as NSError
            if nserror.code == NSFileReadNoSuchFileError {
                do {
                    try fileManager.createDirectory(atPath: self.applicationDocumentsDirectory.path, withIntermediateDirectories: true, attributes: nil)
                } catch {
                    failError = nserror
                }
            } else {
                failError = nserror
                
            }
        }
    
        // Create the coordinator and store
        var coordinator: NSPersistentStoreCoordinator? = nil
        if failError == nil {
            coordinator = NSPersistentStoreCoordinator(managedObjectModel: self.managedObjectModel)
            let url = self.applicationDocumentsDirectory.appendingPathComponent("CocoaAppCD.storedata")
            do {
                var options = [AnyHashable : Any]()
                options[NSMigratePersistentStoresAutomaticallyOption] = true
                options[NSInferMappingModelAutomaticallyOption] = true
                options[NSSQLitePragmasOption] = ["journal_mode" : "DELETE"]
                try coordinator!.addPersistentStore(ofType: NSSQLiteStoreType, configurationName: nil, at: url, options: options)
            } catch {
                failError = error as NSError
            }
        }
        
        if shouldFail || (failError != nil) {
            // Report any error we got.
            var dict = [String: AnyObject]()
            dict[NSLocalizedDescriptionKey] = "Failed to initialize the application's saved data" as AnyObject?
            dict[NSLocalizedFailureReasonErrorKey] = failureReason as AnyObject?
            if failError != nil {
                dict[NSUnderlyingErrorKey] = failError
            }
            let error = NSError(domain: "YOUR_ERROR_DOMAIN", code: 9999, userInfo: dict)
            NSApplication.shared().presentError(error)
            abort()
        } else {
            return coordinator!
        }
    }()

    lazy var managedObjectContext: NSManagedObjectContext = {
        // Returns the managed object context for the application (which is already bound to the persistent store coordinator for the application.) This property is optional since there are legitimate error conditions that could cause the creation of the context to fail.
        let coordinator = self.persistentStoreCoordinator
        var managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
        
    }()

    // MARK: - Core Data Saving and Undo support

    @IBAction func saveAction(_ sender: AnyObject!) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.shared().presentError(nserror)
            }
        }
    }

    func windowWillReturnUndoManager(_ window: NSWindow) -> UndoManager? {
        // Returns the NSUndoManager for the application. In this case, the manager returned is that of the managed object context for the application.
        return managedObjectContext.undoManager
    }

    func applicationShouldTerminate(_ sender: NSApplication) -> NSApplicationTerminateReply {
        // Save changes in the application's managed object context before the application terminates.
        for fetchRequest in BATCH_PURGE_NETWORK_FETCH_REQUESTS {
            do {
                fetchRequest.predicate = IS_NETWORK_PREDICATE
                let deleteRequest = NSBatchDeleteRequest(fetchRequest: fetchRequest)
                try persistentStoreCoordinator.execute(deleteRequest, with: managedObjectContext)
            } catch {
                print(error)
            }
        }
        purgeCurrentlyPlaying()
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing to terminate")
            return .terminateCancel
        }
        
        if !managedObjectContext.hasChanges {
            return .terminateNow
        }
        
        do {
            try managedObjectContext.save()
        } catch {
            let nserror = error as NSError
            // Customize this code block to include application-specific recovery steps.
            let result = sender.presentError(nserror)
            if (result) {
                return .terminateCancel
            }
            
            let question = NSLocalizedString("Could not save changes while quitting. Quit anyway?", comment: "Quit without saves error question message")
            let info = NSLocalizedString("Quitting now will lose any changes you have made since the last successful save", comment: "Quit without saves error question info");
            let quitButton = NSLocalizedString("Quit anyway", comment: "Quit anyway button title")
            let cancelButton = NSLocalizedString("Cancel", comment: "Cancel button title")
            let alert = NSAlert()
            alert.messageText = question
            alert.informativeText = info
            alert.addButton(withTitle: quitButton)
            alert.addButton(withTitle: cancelButton)
            
            let answer = alert.runModal()
            if answer == NSAlertFirstButtonReturn {
                return .terminateCancel
            }
        }
        // If we got here, it is time to quit.
        return .terminateNow
    }

}


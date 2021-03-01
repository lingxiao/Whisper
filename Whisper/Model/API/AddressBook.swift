//
//  PhoneContacts.swift
//  byte
//
//  Created by Xiao Ling on 5/21/20.
//  Copyright © 2020 Xiao Ling. All rights reserved.
//  Source: https://stackoverflow.com/questions/33973574/fetching-all-contacts-in-ios-swift
//

import Foundation
import ContactsUI




//MARK: - elementary datatypes

enum ContactsFilter {
    case none
    case mail
    case message
}


//MARK: - app wide singelton to get contacts each time the user opens the phone-

class PhoneContacts: Sink {
    
    static let shared : PhoneContacts = PhoneContacts()
    
    var addressBook : [PhoneContact] = []
    var filter: ContactsFilter = .none

    init(){}

    /*
     @Use: listen for all phone contacts and create list of `PhoneContact`, then broadcast list
    */
    func await(){
        var res : [PhoneContact] = []
        for data in PhoneContacts.shared.getContactsFromAddressBook() {
            let contact = PhoneContact(contact:data)
            res.append(contact)
        }
        self.addressBook = res

        if !UserAuthed.shared.didSyncContacts {
            putDb()
        }
    }
    
    private func putDb(){
        if UserAuthed.shared.didSyncContacts { return }
        for user in addressBook {
            if  user.phoneNumber.count == 0 {
                continue
            }
            let number = user.phoneNumber[0]
            var id = number.trimmingCharacters(in: .whitespacesAndNewlines)
            let bad_chars: Set<Character> = ["(", ")", "-", " "]
            id.removeAll(where: { bad_chars.contains($0) })
            let res : FirestoreData = [
                "ID"  : id,
                "name": user.name,
                "phone": number,
                "email": user.email.count > 0 ? user.email[0] : "",
                "onApp": false,
                "timeStamp": now()
            ]
            let res2 : FirestoreData = ["userID": UserAuthed.shared.uuid,"timeStamp":now()]
            UserAuthed.contactsRef(at: id)?.setData(res){e in return }
            UserAuthed.contactsHostUser(at: id, from: UserAuthed.shared.uuid)?.setData(res2){e in return }
        }
        UserAuthed.shared.syncedContacts()
    }
    

    func batch() -> [PhoneContact] {
        return self.addressBook
    }
    
    private func getContactsFromAddressBook(filter: ContactsFilter = .none) -> [CNContact] {

        let contactStore = CNContactStore()
        let keysToFetch = [
            CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
            CNContactPhoneNumbersKey,
            CNContactEmailAddressesKey,
            CNContactThumbnailImageDataKey
        ] as [Any]

        var allContainers: [CNContainer] = []
        do {
            allContainers = try contactStore.containers(matching: nil)
        } catch {
            return []
        }

        var results: [CNContact] = []
        
        for container in allContainers {
            let fetchPredicate = CNContact.predicateForContactsInContainer(withIdentifier: container.identifier)

            do {
                let containerResults = try contactStore.unifiedContacts(matching: fetchPredicate, keysToFetch: keysToFetch as! [CNKeyDescriptor])
                results.append(contentsOf: containerResults)
            } catch {
                return []
            }
        }
        return results
    }
    
}

//MARK:- one contact-

class PhoneContact: NSObject, Renderable {

    var uuid: UniqueID = ""
    
    var name: String?
    var avatarData: Data?
    var phoneNumber: [String] = []
    var email: [String] = []
    var isSelected: Bool = false
    var isInvited = false
    var _queries : [String] = []
    
    init(contact: CNContact) {
        name        = contact.givenName + " " + contact.familyName
        avatarData  = contact.thumbnailImageData
        for phone in contact.phoneNumbers {
            let num = formatPhoneNumber(phone.value.stringValue)
            if ( num != nil ){
                phoneNumber.append( num! )
            }
        }
        for mail in contact.emailAddresses {
            email.append(mail.value as String)
        }
    }
    
    override init() {
        super.init()
    }
    
    
    func get_H1() -> String {
        return self.name ?? ""
    }
    
    func get_H2() -> String {
        if phoneNumber.count > 0 {
            return phoneNumber[0]
        } else {
            return ""
        }
    }
    
    func fetchThumbURL() -> URL? {
        return nil
    }
    
    func match(query: String?) -> Bool {
        guard let xs = query else { return false }

        if self._queries.count == 0 {
            let _email = self.email.count > 0 ? self.email[0] : ""
            let _queries = generateSearchQueriesForUser(name: get_H1(), email: _email)
            self._queries = _queries
        }
        let patterns = generateSearchQueriesForUser(name: xs, email: "")
        let hat = self._queries.filter { patterns.contains($0) }
        return hat.count > 0
    }
    
    func should_bold_h2() -> Bool {
        return false
    }
    
}

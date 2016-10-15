//
//  TweetersTableViewController.swift
//  Smashtag
//
//  Created by CS193p Instructor.
//  Copyright © 2016 Stanford University. All rights reserved.
//

import UIKit
import CoreData

// используем CoreDataTableViewController в качестве superclass,
// так что все, что нам нужно сделать:
// 1. установить переменную fetchedResultsController и
// 2. реализовать tableView(cellForRowAtIndexPath:)

class TweetersTableViewController: CoreDataTableViewController
{
    var mention: String? { didSet { updateUI() } }
    var managedObjectContext: NSManagedObjectContext? { didSet { updateUI() } }
    
    private func updateUI() {
        if let context = managedObjectContext where mention?.characters.count > 0 {
            
            let request = NSFetchRequest(entityName: "TwitterUser")
            
            request.predicate = NSPredicate(format:
                "any tweets.text contains[c] %@ and !screenName beginswith[c] %@",
                                            mention!, "darkside")
            request.sortDescriptors = [NSSortDescriptor(
                key: "screenName",
                ascending: true,
                selector: #selector(NSString.localizedCaseInsensitiveCompare(_:))
            )]
            
            fetchedResultsController = NSFetchedResultsController(
                                                           fetchRequest: request,
                                                   managedObjectContext: context,
                                                     sectionNameKeyPath: nil,
                                                              cacheName: nil
            )
        } else {
            fetchedResultsController = nil
        }
    }
    
    // это единственный метод UITableViewDataSource, который нужно реализовать,
    // если мы используем CoreDataTableViewController
    // очень важная часть - 
    // вызов fetchedResultsController?.objectAtIndexPath(indexPath)
    // (так мы получаем объект, который находится в той строке)
    
    override func tableView(tableView: UITableView,
                cellForRowAtIndexPath indexPath: NSIndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCellWithIdentifier("TwitterUserCell",
                                                          forIndexPath: indexPath)

        if let twitterUser = fetchedResultsController?.objectAtIndexPath(indexPath)
                                                                 as? TwitterUser {
            var screenName: String?
            twitterUser.managedObjectContext?.performBlockAndWait {
                screenName = twitterUser.screenName
            }
            cell.textLabel?.text = screenName
            if let count = tweetCountWithMentionByTwitterUser(twitterUser) {
                cell.detailTextLabel?.text =
                                       (count == 1) ? "1 tweet" : "\(count) tweets"
            } else {
                cell.detailTextLabel?.text = ""
            }
        }
    
        return cell
    }
    
    // private func, которая определяет сколько tweets, содержащих наш mention,
    // были посланы заданным пользователем
    
    private func tweetCountWithMentionByTwitterUser(user: TwitterUser) -> Int?
    {
        var count: Int?
        user.managedObjectContext?.performBlockAndWait {
            let request = NSFetchRequest(entityName: "Tweet")
            request.predicate = NSPredicate(format: "text contains[c] %@ and tweeter = %@", self.mention!, user)
            count = try! user.managedObjectContext?.countForFetchRequest(request)
        }
        return count
    }
}

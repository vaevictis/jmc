//
//  Track+CoreDataProperties.swift
//  minimalTunes
//
//  Created by John Moody on 11/25/16.
//  Copyright © 2016 John Moody. All rights reserved.
//
//  Choose "Create NSManagedObject Subclass…" from the Core Data editor menu
//  to delete and recreate this implementation file for your updated model.
//

import Foundation
import CoreData

extension Track {

    @NSManaged var bit_rate: NSNumber?
    @NSManaged var bpm: NSNumber?
    @NSManaged var comments: String?
    @NSManaged var date_added: Date?
    @NSManaged var date_last_played: Date?
    @NSManaged var date_last_skipped: Date?
    @NSManaged var date_modified: Date?
    @NSManaged var disc_number: NSNumber?
    @NSManaged var equalizer_preset: String?
    @NSManaged var file_kind: String?
    @NSManaged var id: NSNumber?
    @NSManaged var is_network: NSNumber?
    @NSManaged var is_playing: NSNumber?
    @NSManaged var location: String?
    @NSManaged var misc_search_field: String?
    @NSManaged var movement_name: String?
    @NSManaged var movement_number: NSNumber?
    @NSManaged var name: String?
    @NSManaged var play_count: NSNumber?
    @NSManaged var rating: NSNumber?
    @NSManaged var sample_rate: NSNumber?
    @NSManaged var size: NSNumber?
    @NSManaged var skip_count: NSNumber?
    @NSManaged var sort_album: String?
    @NSManaged var sort_album_artist: String?
    @NSManaged var sort_artist: String?
    @NSManaged var sort_composer: String?
    @NSManaged var sort_name: String?
    @NSManaged var status: NSNumber?
    @NSManaged var time: NSNumber?
    @NSManaged var track_num: NSNumber?
    @NSManaged var album: Album?
    @NSManaged var artist: Artist?
    @NSManaged var composer: Composer?
    @NSManaged var genre: Genre?
    @NSManaged var user_defined_properties: NSSet?
    @NSManaged var view: TrackView?

}

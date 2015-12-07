//
//  SKYAccessControlTests.m
//  SkyKit
//
//  Created by Kenji Pa on 10/6/15.
//  Copyright (c) 2015 Kwok-kuen Cheung. All rights reserved.
//

#import <SkyKit/SkyKit.h>

#import "SKYAccessControl_Private.h"
#import "SKYAccessControlDeserializer.h"
#import "SKYAccessControlEntry.h"
#import "SKYAccessControlSerializer.h"
#import "SKYUserRecordID_Private.h"

// Currently there are no methods to access the internal state of SKYAccessControl.
// Before that comes, use serialization for assertion.
NSArray *serializedAccessControl(SKYAccessControl *accessControl)
{
    SKYAccessControlSerializer *serializer = [SKYAccessControlSerializer serializer];
    return [serializer arrayWithAccessControl:accessControl];
}

SpecBegin(SKYAccessControl)

    describe(@"Public Access Control", ^{
        __block SKYAccessControl *accessControl = nil;

        beforeEach(^{
            accessControl = [SKYAccessControl publicReadWriteAccessControl];
        });

        it(@"is public", ^{
            expect(accessControl.public).to.equal(YES);
            expect(serializedAccessControl(accessControl)).to.equal(nil);
        });

        it(@"is not public after mutated", ^{
            [accessControl addReadAccessForRelation:[SKYRelation followedRelation]];
            expect(accessControl.public).to.equal(NO);
            expect(serializedAccessControl(accessControl))
                .to.equal(@[
                    @{ @"relation" : @"follow",
                       @"level" : @"read" },
                ]);
        });
    });

describe(@"Access Control", ^{
    __block SKYAccessControl *accessControl = nil;
    __block SKYUserRecordID *userID = nil;

    beforeEach(^{
        userID = [SKYUserRecordID recordIDWithUsername:@"userid"];

        SKYAccessControlEntry *entry = [SKYAccessControlEntry writeEntryForUserID:userID];
        accessControl = [SKYAccessControl accessControlWithEntries:@[ entry ]];
    });

    it(@"is not public", ^{
        expect(accessControl.public).to.equal(NO);
        expect(serializedAccessControl(accessControl))
            .to.equal(@[
                @{ @"relation" : @"$direct",
                   @"level" : @"write",
                   @"user_id" : @"userid" },
            ]);
    });

    it(@"is not public after removing all entries", ^{
        [accessControl removeWriteAccessForUserID:userID];
        expect(accessControl.public).to.equal(NO);
        expect(serializedAccessControl(accessControl)).to.equal(@[]);
    });

    it(@"is public after setting public read write access", ^{
        [accessControl setPublicReadWriteAccess];
        expect(accessControl.public).to.equal(YES);
        expect(serializedAccessControl(accessControl)).to.equal(nil);
    });

    it(@"does not add same entry twice", ^{
        [accessControl addWriteAccessForUserID:[SKYUserRecordID recordIDWithUsername:@"userid"]];
        expect(serializedAccessControl(accessControl))
            .to.equal(@[
                @{ @"relation" : @"$direct",
                   @"level" : @"write",
                   @"user_id" : @"userid" },
            ]);
    });
});

describe(@"Access Control Entry", ^{
    it(@"serializes correctly", ^{
        SKYAccessControlEntry *readRelationEntry =
            [SKYAccessControlEntry readEntryForRelation:[SKYRelation friendRelation]];
        SKYAccessControlEntry *writeRelationEntry =
            [SKYAccessControlEntry writeEntryForRelation:[SKYRelation followedRelation]];
        SKYAccessControlEntry *readUserIDEntry = [SKYAccessControlEntry
            readEntryForUserID:[SKYUserRecordID recordIDWithUsername:@"userid0"]];
        SKYAccessControlEntry *writeUserIDEntry = [SKYAccessControlEntry
            writeEntryForUserID:[SKYUserRecordID recordIDWithUsername:@"userid1"]];

        SKYAccessControl *accessControl = [SKYAccessControl accessControlWithEntries:@[
            readRelationEntry,
            writeRelationEntry,
            readUserIDEntry,
            writeUserIDEntry,
        ]];
        expect(serializedAccessControl(accessControl))
            .to.equal(@[
                @{ @"relation" : @"friend",
                   @"level" : @"read" },
                @{ @"relation" : @"follow",
                   @"level" : @"write" },
                @{ @"relation" : @"$direct",
                   @"level" : @"read",
                   @"user_id" : @"userid0" },
                @{ @"relation" : @"$direct",
                   @"level" : @"write",
                   @"user_id" : @"userid1" },
            ]);
    });
});

describe(@"SKYAccessControlDeserializer", ^{

    __block SKYAccessControlDeserializer *deserializer = nil;

    beforeEach(^{
        deserializer = [SKYAccessControlDeserializer deserializer];
    });

    it(@"deserializes nil correctly", ^{
        SKYAccessControl *accessControl = [deserializer accessControlWithArray:nil];
        expect(accessControl.public).to.equal(YES);
        expect(serializedAccessControl(accessControl)).to.equal(nil);
    });

    it(@"empty array", ^{
        SKYAccessControl *accessControl = [deserializer accessControlWithArray:@[]];
        expect(accessControl.public).to.equal(NO);
        expect(serializedAccessControl(accessControl)).to.equal(@[]);
    });

    it(@"access control entries", ^{
        NSArray *undeserialized = @[
            @{ @"relation" : @"friend",
               @"level" : @"read" },
            @{ @"relation" : @"follow",
               @"level" : @"write" },
            @{ @"relation" : @"$direct",
               @"level" : @"read",
               @"user_id" : @"userid0" },
            @{ @"relation" : @"$direct",
               @"level" : @"write",
               @"user_id" : @"userid1" },
        ];
        SKYAccessControl *accessControl = [deserializer accessControlWithArray:undeserialized];
        expect(accessControl.public).to.equal(NO);
        expect(serializedAccessControl(accessControl)).to.equal(undeserialized);
    });

});

SpecEnd

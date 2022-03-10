using Inprotech.Tests.Integration.DbHelpers;
using InprotechKaizen.Model.Cases.Events;

namespace Inprotech.Tests.Integration.EndToEnd.Configuration.General.Events.EventNoteTypes
{
    public class EventNoteTypesDbSetup : DbSetup
    {
        public const string EventNoteTypeDescription = "e2e - EventNoteTypes";
        public const string EventNoteTypeToBeAdded = "e2e - AddedEventNoteTypes";
        public const string EventNoteTypeToBeEdit = "e2e - EditedEventNoteTypes";
        public const string EventNoteTypeToBeDuplicate = "e2e - DuplicateEventNoteTypes";
        public const string EventNoteTypeInUse = "e2e-inUseEventNoteTypes";

        public void Prepare()
        {
            InsertWithNewId(new EventNoteType
            {
                Description = EventNoteTypeDescription,
                IsExternal = true,
                SharingAllowed = true
            });

            var inUseEventNoteType = InsertWithNewId(new EventNoteType
            {
                Description = EventNoteTypeInUse,
                IsExternal = true,
                SharingAllowed = true
            });

            InsertWithNewId(new EventText
            {
                EventNoteType = inUseEventNoteType,
                Text = "abcd"
            });
        }
    }
}

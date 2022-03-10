using System;
using Newtonsoft.Json;

namespace Inprotech.Web.CaseSupportData
{
    public class CaseEventNotesData
    {
        public int EventId { get; set; }
        public short Cycle { get; set; }
        public string EventText { get; set; }
        public short? NoteType { get; set; }

        [JsonIgnore]
        public string NoteTypeText { get; set; }

        public bool? IsDefault { get; set; }

        [JsonIgnore]
        public bool? IsExternal { get; set; }

        public DateTime? LastUpdatedDateTime { get; set; }
    }

    public class CaseEventNotes
    {
        public short? EventNoteType { get; set; }
        public string EventText { get; set; }
        public long CaseEventId { get; set; }
    }

    public class ViewData
    {
        public string FriendlyName { get; set; }
        public string DateStyle { get; set; }
        public string TimeFormat { get; set; }
    }
}
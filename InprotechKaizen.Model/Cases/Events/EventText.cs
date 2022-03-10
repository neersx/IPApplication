using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases.Events
{
    [Table("EVENTTEXT")]
    public class EventText
    {
        [Obsolete("For persistence only.")]
        public EventText()
        {
        }

        public EventText(int id)
        {
            Id = id;
        }
        public EventText(int id, EventNoteType eventNoteType)
        {
            Id = id;
            EventNoteType = eventNoteType;
            EventNoteTypeId = eventNoteType?.Id;
        }

        public EventText(string text, EventNoteType eventNoteType)
        {
            Text = text;
            EventNoteType = eventNoteType;
        }

        [Key]
        [Column("EVENTTEXTID")]
        public int Id { get; protected set; }

        [Column("EVENTTEXT")]
        public string Text { get; set; }

        [Column("EVENTTEXT_TID")]
        public int? TextTId { get; set; }

        [Column("EVENTTEXTTYPEID")]
        public short? EventNoteTypeId { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LogDateTimeStamp { get; set; }
        
        public EventNoteType EventNoteType { get; set; }

    }
}
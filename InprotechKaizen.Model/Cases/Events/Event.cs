using System;
using System.Collections.Generic;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Rules;

namespace InprotechKaizen.Model.Cases.Events
{
    [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Event")]
    [Table("EVENTS")]
    public class Event
    {
        [Obsolete("For persistence only.")]
        public Event()
        {
        }

        public Event(int id)
        {
            Id = id;
        }

        public Event(int id, string description)
        {
            Id = id;
            Description = description;
        }

        [Key]
        [Column("EVENTNO")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; internal set; }

        [Column("NUMCYCLESALLOWED")]
        public short? NumberOfCyclesAllowed { get; set; }

        [MaxLength(10)]
        [Column("EVENTCODE")]
        public string Code { get; set; }

        [MaxLength(100)]
        [Column("EVENTDESCRIPTION")]
        public string Description { get; set; }

        [Column("EVENTDESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        [Column("POLICINGIMMEDIATE")]
        public bool ShouldPoliceImmediate { get; set; }

        [MaxLength(2)]
        [Column("CONTROLLINGACTION")]
        public string ControllingAction { get; set; }

        [MaxLength(2)]
        [Column("IMPORTANCELEVEL")]
        public string ImportanceLevel { get; set; }

        [MaxLength(2)]
        [Column("CLIENTIMPLEVEL")]
        public string ClientImportanceLevel { get; set; }

        [Column("CATEGORYID")]
        public short? CategoryId { get; set; }

        [Column("EVENTGROUP")]
        public int? GroupId { get; set; }

        [Column("DRAFTEVENTNO")]
        public int? DraftEventId { get; set; }

        [Column("RECALCEVENTDATE")]
        public bool? RecalcEventDate { get; set; }

        [Column("ACCOUNTINGEVENTFLAG")]
        public bool? IsAccountingEvent { get; set; }

        [Column("SUPPRESSCALCULATION")]
        public bool? SuppressCalculation { get; set; }

        [MaxLength(254)]
        [Column("DEFINITION")]
        public string Notes { get; set; }

        [Column("DEFINITION_TID")]
        public int? NotesTId { get; set; }

        public bool IsCyclic
        {
            get { return NumberOfCyclesAllowed > 1; }
        }

        [Column("NOTEGROUP")]
        public int? NoteGroupId { get; set; }

        [Column("NOTESSHAREDACROSSCYCLES")]
        public bool? NotesSharedAcrossCycles { get; set; }

        public virtual ICollection<ValidEvent> ValidEvents { get; set; }

        [ForeignKey("ImportanceLevel")]
        public virtual Importance InternalImportance { get; set; }

        [ForeignKey("ClientImportanceLevel")]
        public virtual Importance ClientImportance { get; set; }

        [ForeignKey("ControllingAction")]
        public virtual Action Action { get; set; }

        [ForeignKey("DraftEventId")]
        public virtual Event DraftEvent { get; set; }

        [ForeignKey("GroupId")]
        public virtual TableCode Group { get; set; }

        [ForeignKey("CategoryId")]
        public virtual EventCategory Category { get; set; }

        [ForeignKey("NoteGroupId")]
        public virtual TableCode NoteGroup { get; set; }
        
    }
}
using InprotechKaizen.Model.Cases.Events;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASERELATION")]
    public class CaseRelation
    {
        [Obsolete("For persistence only.")]
        public CaseRelation()
        {
        }
        
        public CaseRelation(string relationship, int? fromEventId)
        {
            Relationship = relationship;
            FromEventId = fromEventId;
        }
        public CaseRelation(string relationship, string description, int? fromEventId)
        {
            Relationship = relationship;
            Description = description;
            FromEventId = fromEventId;
        }

        [Key]
        [Column("RELATIONSHIP")]
        [MaxLength(3)]
        public string Relationship { get; set; }

        [Column("FROMEVENTNO")]
        public int? FromEventId { get; set; }

        [Column("EVENTNO")]
        public int? ToEventId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("EARLIESTDATEFLAG")]
        public decimal? EarliestDateFlag { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("SHOWFLAG")]
        public decimal? ShowFlag { get; set; }

        [Column("POINTERTOPARENT")]
        public decimal? PointsToParent { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("PRIORARTFLAG")]
        public bool? PriorArtFlag { get; set; }

        [Column("NOTES")]
        public string Notes { get; set; }

        [MaxLength(50)]
        [Column("RELATIONSHIPDESC")]
        public string Description { get; set; }

        [Column("RELATIONSHIPDESC_TID")]
        public int? DescriptionTId { get; set; }

        [Column("DISPLAYEVENTNO")]
        public int? DisplayEventId { get; set; }

        [ForeignKey("FromEventId")]
        public virtual Event FromEvent { get; set; }

        [ForeignKey("ToEventId")]
        public virtual Event ToEvent { get; set; }

        [ForeignKey("DisplayEventId")]
        public virtual Event DisplayEvent { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flags")]
        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        public void SetFlags(bool? earliestDateFlag = null, bool? showFlag = null, bool? pointsToParent = null, bool? priorArtFlag = null)
        {
            if (earliestDateFlag.HasValue) EarliestDateFlag = earliestDateFlag.GetValueOrDefault() ? 1m : 0m;
            if (showFlag.HasValue) ShowFlag = showFlag.GetValueOrDefault() ? 1m : 0m;
            if (pointsToParent.HasValue) PointsToParent = pointsToParent.GetValueOrDefault() ? 1m : 0m;
            if (priorArtFlag.HasValue) PriorArtFlag = priorArtFlag;
        }

        public void SetEvents(int? fromEventId, int? toEventId, int? displayEventId)
        {
            FromEventId = fromEventId;
            ToEventId = toEventId;
            DisplayEventId = displayEventId;
        }

        public void SetNotes(string description, string notes)
        {
            Description = description;
            Notes = notes;
        }
    }
}

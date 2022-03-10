using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using Action = InprotechKaizen.Model.Cases.Action;

namespace InprotechKaizen.Model.ValidCombinations
{
    [Table("VALIDACTDATES")]
    public class DateOfLaw
    {
        [Key]
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; set; }

        [Key]
        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [Key]
        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyTypeId { get; set; }

        [Key]
        [Column("DATEOFACT")]
        public DateTime Date { get; set; }

        [Key]
        [Column("SEQUENCENO")]
        public short SequenceNo { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "RetroAction")]
        [MaxLength(2)]
        [Column("RETROSPECTIVEACTIO")]
        public string RetroActionId { get; set; }

        [Column("ACTEVENTNO")]
        public int? LawEventId { get; set; }

        [Column("RETROEVENTNO")]
        public int? RetroEventId { get; set; }

        [ForeignKey("CountryId")]
        public virtual Country Country { get; set; }

        [ForeignKey("PropertyTypeId")]
        public virtual PropertyType PropertyType { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1702:CompoundWordsShouldBeCasedCorrectly", MessageId = "RetroAction")]
        [ForeignKey("RetroActionId")]
        public virtual Action RetroAction { get; set; }

        [ForeignKey("LawEventId")]
        public virtual Event LawEvent { get; set; }

        [ForeignKey("RetroEventId")]
        public virtual Event RetroEvent { get; set; }
    }
}

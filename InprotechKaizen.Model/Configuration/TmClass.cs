using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;

namespace InprotechKaizen.Model.Configuration
{
    [Table("TMCLASS")]
    public class TmClass
    {
        public TmClass(string countryCode, string classId, string propertyType, int sequenceNo = 0)
        {
            CountryCode = countryCode;
            Class = classId;
            PropertyType = propertyType;
            SequenceNo = sequenceNo;
        }

        [Obsolete("For persistence only.")]
        public TmClass()
        {

        }

        [Key]
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int Id { get; protected set; }

        [Required]
        [MaxLength(3)]
        [Column("COUNTRYCODE", Order = 0)]
        public string CountryCode { get; protected set; }

        [Required]
        [MaxLength(5)]
        [Column("CLASS", Order = 1)]
        public string Class { get; protected set; }

        [Required]
        [MaxLength(1)]
        [Column("PROPERTYTYPE", Order = 2)]
        [ForeignKey("Property")]
        public string PropertyType { get; protected set; }

        [Column("SEQUENCENO", Order = 3)]
        public int SequenceNo { get; protected set; }

        [MaxLength(254)]
        [Column("INTERNATIONALCLASS")]
        public string IntClass { get; set; }

        [MaxLength(1)]
        [Column("GOODSSERVICES")]
        public string GoodsOrService { get; set; }

        [MaxLength(5)]
        [Column("SUBCLASS")]
        public string SubClass { get; set; }

        [Column("CLASSHEADING")]
        public string Heading { get; set; }

        [Column("CLASSHEADING_TID")]
        public int? HeadingTId { get; set; }

        [Column("CLASSNOTES")]
        public string Notes { get; set; }

        [Column("EFFECTIVEDATE")]
        public DateTime? EffectiveDate { get; set; }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Property")]
        public virtual PropertyType Property { get; set; }

    }
}

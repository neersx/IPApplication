using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;

namespace InprotechKaizen.Model.Configuration.SiteControl
{
    public interface ISiteControlDataTypeFormattable
    {
        string DataType { get; }

        int? IntegerValue { get; }

        string StringValue { get; }

        bool? BooleanValue { get; }

        decimal? DecimalValue { get; }

        DateTime? DateValue { get; }

        string InitialValue { get; }
    }

    [Table("SITECONTROL")]
    public class SiteControl : ISiteControlDataTypeFormattable
    {
        [Obsolete("For persistence only.")]
        public SiteControl()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public SiteControl(string siteControlId)
        {
            if (string.IsNullOrEmpty(siteControlId)) throw new ArgumentNullException("siteControlId");
            ControlId = siteControlId;
            Components = new Collection<Component>();
            Tags = new Collection<Tag>();
        }

        [SuppressMessage("Microsoft.Naming", "CA1720:IdentifiersShouldNotContainTypeNames", MessageId = "string")]
        public SiteControl(string siteControlId, string stringValue)
            : this(siteControlId)
        {
            StringValue = stringValue;
        }

        public SiteControl(string siteControlId, bool? booleanValue)
            : this(siteControlId)
        {
            BooleanValue = booleanValue;
        }

        public SiteControl(string siteControlId, int? integerValue)
            : this(siteControlId)
        {
            IntegerValue = integerValue;
        }

        public SiteControl(string siteControlId, decimal? decimalValue)
            : this(siteControlId)
        {
            DecimalValue = decimalValue;
        }

        public SiteControl(string siteControlId, DateTime? dateValue)
            : this(siteControlId)
        {
            DateValue = dateValue;
        }

        [Column("ID")]
        public int Id { get; set; }

        [MaxLength(1)]
        [Column("OWNER")]
        public string Owner { get; set; }

        [Key]
        [Column("CONTROLID")]
        [MaxLength(50)]
        public string ControlId { get; set; }

        [MaxLength(512)]
        [Column("COMMENTS")]
        public string SiteControlDescription { get; set; }

        [Column("COMMENTS_TID")]
        public int? SiteControlDescriptionTId { get; set; }

        [Column("VERSIONID")]
        public int? VersionId { get; set; }

        [Column("NOTES")]
        public string Notes { get; set; }

        [Column("NOTES_TID")]
        public int? NotesTId { get; set; }

        public virtual ICollection<Component> Components { get; set; }

        public virtual ICollection<Tag> Tags { get; set; }

        [ForeignKey("VersionId")]
        public virtual ReleaseVersion ReleaseVersion { get; set; }

        [Column("COLINTEGER")]
        public int? IntegerValue { get; set; }

        [MaxLength(254)]
        [Column("COLCHARACTER")]
        public string StringValue { get; set; }

        [Column("COLBOOLEAN")]
        public bool? BooleanValue { get; set; }

        [Column("COLDECIMAL")]
        public decimal? DecimalValue { get; set; }

        [Column("COLDATE")]
        public DateTime? DateValue { get; set; }

        [MaxLength(254)]
        [Column("INITIALVALUE")]
        public string InitialValue { get; set; }

        [Required]
        [MaxLength(1)]
        [Column("DATATYPE")]
        public string DataType { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastChanged { get; set; }
    }
}
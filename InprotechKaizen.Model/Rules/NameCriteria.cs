using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Rules
{
    [Table("NAMECRITERIA")]
    public class NameCriteria
    {
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public NameCriteria()
        {
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("NAMECRITERIANO")]
        public int Id { get; set; }

        [Required]
        [MaxLength(1)]
        [Column("PURPOSECODE")]
        public string PurposeCode { get; set; }

        [MaxLength(8)]
        [Column("PROGRAMID")]
        public string ProgramId { get; set; }

        [Column("USEDASFLAG")]
        public short? UsedAsFlag { get; set; }

        [Column("SUPPLIERFLAG")]
        public decimal? SupplierFlag { get; set; }

        [Column("DATAUNKNOWN")]
        public short? DataUnknown { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string CountryId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("LOCALCLIENTFLAG")]
        public decimal? LocalClientFlag { get; set; }

        [Column("CATEGORY")]
        public int? CategoryId { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeId { get; set; }

        [MaxLength(3)]
        [Column("RELATIONSHIP")]
        public string RelationShipId { get; set; }

        [Column("PROFILEID")]
        public int? ProfileId { get; set; }

        [Column("RULEINUSE")]
        public decimal? RuleInUse { get; set; }

        [Column("DESCRIPTION")]
        [MaxLength(254)]
        public string Description { get; set; }

        [Column("DESCRIPTION_TID")]
        public int? DescriptionTId { get; set; }

        public virtual Profile Profile { get; set; }
    }
}

using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDECASEDETAILS")]
    public class EdeCaseDetails
    {
        [Key]
        [Column("ROWID")]
        public int RowId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("CASEPROPERTYTYPECODE")]
        public string CasePropertyTypeCode { get; set; }

        [MaxLength(50)]
        [Column("CASECOUNTRYCODE")]
        public string CaseCountryCode { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [MaxLength(80)]
        [Column("CASEOFFICE")]
        public string Office { get; set; }

        [MaxLength(20)]
        [Column("FAMILY")]
        public string Family { get; set; }
    }
}

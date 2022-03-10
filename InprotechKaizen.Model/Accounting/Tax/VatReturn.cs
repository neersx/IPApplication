using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Tax
{
    [Table("VATRETURN")]
    public class VatReturn
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        [Column("ID")]
        public int Id { get; private set; }

        [Column("NAMENO")]
        public int EntityId { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("OBLIGATIONPERIODID")]
        public string PeriodId { get; set; }

        [Column("DATA")]
        public string Data { get; set; }

        [Column("SUBMITTED")]
        public bool IsSubmitted { get; set; }

        [MaxLength(254)]
        [Column("TAXNO")]
        public string TaxNumber { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }
    }
}
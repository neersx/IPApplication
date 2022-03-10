using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Cases
{
    [Table("CPASEND")]
    public class CpaSend
    {
        public CpaSend()
        {

        }

        public CpaSend(Case @case, int batchNo, DateTime batchDate, string propertyType)
        {
            if(@case == null) throw new ArgumentNullException("case");

            CaseId = @case.Id;
            BatchNo = batchNo;
            BatchDate = batchDate;
            PropertyType = propertyType;
        }

        [Key]
        [Column("ROWID")]
        [Required]
        public int RowId { get; set; }

        [Column("BATCHNO")]
        public int BatchNo { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("BATCHDATE")]
        public DateTime? BatchDate { get; set; }

        [Column("PROPERTYTYPE")]
        [MaxLength(1)]
        public string PropertyType { get; set; }
    }
}

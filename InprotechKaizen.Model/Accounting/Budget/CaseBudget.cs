using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Budget
{
    [Table("CASEBUDGET")]
    public class CaseBudget
    {
        [Key]
        [Column("CASEID", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int CaseId { get; set; }

        [Key]
        [Column("SEQUENCENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public short SequenceNo { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeNo { get; set; }

    }
}

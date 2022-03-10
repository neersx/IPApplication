using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Cost
{
    [Table("COSTRATE")]
    public class CostRate
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("COSTRATENO")]
        public int CostRateNo { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeNo { get; set; }

    }
}

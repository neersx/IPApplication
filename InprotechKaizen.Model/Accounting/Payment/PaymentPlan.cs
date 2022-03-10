using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Payment
{
    [Table("PAYMENTPLAN")]
    public class PaymentPlan
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("PLANID")]
        public int PlanId { get; set; }

        [Column("BANKNAMENO")]
        public int BankNameNo { get; set; }

    }
}

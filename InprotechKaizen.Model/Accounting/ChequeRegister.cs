using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting
{
    [Table("CHEQUEREGISTER")]
    public class ChequeRegister
    {
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("CHEQUEREGISTERID")]
        public int ChequeRegisterId { get; set; }

        [Column("BANKNAMENO")]
        public int BankNameNo { get; set; }
    }
}
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Creditor
{
    [Table("CRENTITYDETAIL")]
    public class CreditorEntityDetail
    {
        [Key]
        [Column("NAMENO", Order = 0)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int NameId { get; set; }

        [Key]
        [Column("ENTITYNAMENO", Order = 1)]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int EntityNameNo { get; set; }

        [Column("BANKNAMENO")]
        public int BankNameNo { get; set; }

        [Column("SEQUENCENO")]
        public int SequenceNo { get; set; }

        [Required]
        [MaxLength(30)]
        [Column("SUPPLIERACCOUNTNO")]
        public string SupplierAccountNumber { get; set; }
    }
}

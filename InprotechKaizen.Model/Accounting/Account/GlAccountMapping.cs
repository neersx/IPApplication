using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Accounting.Account
{
    [Table("GLACCOUNTMAPPING")]
    public class GlAccountMapping
    {
        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("RULESEQNO")]
        public int RuleSeqNo { get; set; }

        [Column("WIPEMPLOYEENO")]
        public int? WipStaffId { get; set; }

        [Column("BANKENTITYNO")]
        public int? BankEntityId { get; set; }

        [Column("BANKNAMENO")]
        public int? BankNameId { get; set; }
    }
}

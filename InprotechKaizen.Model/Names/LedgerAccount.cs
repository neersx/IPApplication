using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Names
{
    [Table("LEDGERACCOUNT")]
    public class LedgerAccount
    {
        public LedgerAccount()
        {
            
        }

        public LedgerAccount(int id)
        {
            Id = id;
        }

        [Key]
        [Column("ACCOUNTID")]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        public int Id { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("DESCRIPTION")]
        public string Description { get; set; }

        [Required]
        [MaxLength(100)]
        [Column("ACCOUNTCODE")]
        public string AccountCode { get; set; }

        [Column("ACCOUNTTYPE")]
        public int AccountType { get; set; }

        [Column("PARENTACCOUNTID")]
        public int? ParentAccountId { get; set; }

        [Column("DISBURSETOWIP")]
        public decimal? DisburseToWip { get; set; }

        [Column("ISACTIVE")]
        public decimal? IsActive { get; set; }

        [Column("BUDGETMOVEMENT")]
        public decimal BudgetMovement { get; set; }
    }
}
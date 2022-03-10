using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Configuration;

namespace InprotechKaizen.Model.Ede
{
    [Table("EDETRANSACTIONBODY")]
    public class EdeTransactionBody
    {
        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public EdeTransactionBody()
        {
            OutstandingIssues = new Collection<EdeOutstandingIssues>();
            DescriptionDetails = new Collection<EdeDescriptionDetails>();
            IdentifierNumberDetails = new Collection<EdeIdentifierNumberDetails>();
        }

        [System.Diagnostics.CodeAnalysis.SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public EdeTransactionBody(EdeOutstandingIssues[] outstandingIssues)
        {
            OutstandingIssues = new Collection<EdeOutstandingIssues>(outstandingIssues);
            DescriptionDetails = new Collection<EdeDescriptionDetails>();
            IdentifierNumberDetails = new Collection<EdeIdentifierNumberDetails>();
        }

        [Column("BATCHNO")]
        public int? BatchId { get; set; }

        [Required]
        [MaxLength(50)]
        [Column("TRANSACTIONIDENTIFIER")]
        public string TransactionIdentifier { get; set; }

        [MaxLength(50)]
        [Column("TRANSACTIONRETURNCODE")]
        public string TransactionReturnCode { get; set; }

        public virtual TableCode TransactionStatus { get; set; }

        public virtual ICollection<EdeOutstandingIssues> OutstandingIssues { get; set; }

        public virtual ICollection<EdeDescriptionDetails> DescriptionDetails { get; set; }

        public virtual EdeCaseDetails CaseDetails { get; set; }

        public virtual EdeCaseMatch CaseMatch { get; set; }

        public virtual ICollection<EdeIdentifierNumberDetails> IdentifierNumberDetails { get; set; }
    }
}
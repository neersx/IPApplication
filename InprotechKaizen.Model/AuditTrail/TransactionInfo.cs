using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.AuditTrail
{
    [Table("TRANSACTIONINFO")]
    public class TransactionInfo
    {
        [Obsolete("For persistence only.")]
        public TransactionInfo()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public TransactionInfo(Case @case, DateTime transactionDate, int messageNo, int? reasonNo = null)
        {
            TransactionDate = transactionDate;
            MessageNo = messageNo;
            Case = @case;
            ReasonNo = reasonNo;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public TransactionInfo(int caseId, DateTime transactionDate, int messageNo, int? reasonNo = null)
        {
            TransactionDate = transactionDate;
            MessageNo = messageNo;
            CaseId = caseId;
            ReasonNo = reasonNo;
        }

        public TransactionInfo(DateTime transactionDate, int messageNo, int nameId)
        {
            TransactionDate = transactionDate;
            MessageNo = messageNo;
            NameId = nameId;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public TransactionInfo(DateTime transactionDate, int messageNo, Name name)
        {
            TransactionDate = transactionDate;
            MessageNo = messageNo;
            Name = name;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public TransactionInfo(DateTime transactionDate, int batchId)
        {
            TransactionDate = transactionDate;
            BatchId = batchId;
        }

        [Key]
        [Column("LOGTRANSACTIONNO")]
        public int Id { get; protected set; }

        [Column("TRANSACTIONDATE")]
        public DateTime TransactionDate { get; protected set; }

        [Column("TRANSACTIONMESSAGENO")]
        public int? MessageNo { get; protected set; }

        [Column("TRANSACTIONREASONNO")]
        public int? ReasonNo { get; protected set; }

        [Column("BATCHNO")]
        public int? BatchId { get; protected set; }

        [ForeignKey("CaseId")]
        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Case")]
        public virtual Case Case { get; protected set; }

        [ForeignKey("NameId")]
        public virtual Name Name { get; protected set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }
        
        [Column("NAMENO")]
        public int? NameId { get; set; }

        public virtual OperatorSession Session { get; protected set; }

        public void SetSession(OperatorSession session)
        {
            Session = session;
        }
    }
}
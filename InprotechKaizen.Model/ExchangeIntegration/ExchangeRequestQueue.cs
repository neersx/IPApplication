using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.ExchangeIntegration
{
    [Table("EXCHANGEREQUESTQUEUE")]
    public class ExchangeRequestQueueItem
    {
        [Obsolete("For persistence only.")]
        public ExchangeRequestQueueItem()
        {
        }

        public ExchangeRequestQueueItem(int staffId, DateTime seqDate, DateTime created, short requestType, short statusId)
        {
            StaffId = staffId;
            SequenceDate = seqDate;
            DateCreated = created;
            RequestTypeId = requestType;
            StatusId = statusId;
        }

        [Key]
        [Column("ID")]
        public long Id { get; protected set; }

        [Column("EMPLOYEENO")]
        [ForeignKey("StaffName")]
        public int StaffId { get; set; }

        [Column("MESSAGESEQ")]
        public DateTime SequenceDate { get; set; }

        [Column("DATECREATED")]
        public DateTime DateCreated { get; set; }

        [MaxLength(100)]
        [Column("REFERENCE")]
        public string Reference { get; set; }

        [Column("STATUSID")]
        public short StatusId { get; set; }

        [Column("REQUESTTYPE")]
        public short RequestTypeId { get; set; }

        [Column("ERRORMESSAGE")]
        public string ErrorMessage { get; set; }

        [Column("CASEID")]
        [ForeignKey("Case")]
        public int? CaseId { get; set; }

        [Column("NAMENO")]
        [ForeignKey("Name")]
        public int? NameId { get; set; }

        [Column("ALERTNAMENO")]
        [ForeignKey("AlertName")]
        public int? AlertNameId { get; set; }

        [Column("EVENTNO")]
        [ForeignKey("Event")]
        public int? EventId { get; set; }

        [Column("IDENTITYID")]
        [ForeignKey("UserIdentity")]
        public int? IdentityId { get; set; }

        [MaxLength(254)]
        [Column("MAILBOX")]
        public string MailBox { get; set; }

        [Column("RECIPIENTS")]
        public string Recipients { get; set; }

        [Column("CCRECIPIENTS")]
        public string CcRecipients { get; set; }

        [Column("BCCRECIPIENTS")]
        public string BccRecipients { get; set; }

        [Column("SUBJECT")]
        public string Subject { get; set; }

        [Column("BODY")]
        public string Body { get; set; }

        [Column("ISBODYHTML")]
        public bool IsBodyHtml { get; set; }

        [Column("ATTACHMENTS")]
        public string Attachments { get; set; }
        
        public virtual Name StaffName { get; set; }
        public virtual Case Case { get; set; }
        public virtual Name Name { get; set; }
        public virtual Name AlertName { get; set; }
        public virtual Event Event { get; set; }
        public virtual User UserIdentity { get; set; }
    }
}
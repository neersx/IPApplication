using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using InprotechKaizen.Model.Cases.Events;

namespace InprotechKaizen.Model.Cases
{
    [Table("CASEEVENT")]
    public class CaseEvent
    {
        [Obsolete("For persistence only...")]
        public CaseEvent()
        {
        }

        public CaseEvent(int caseId, int eventNo, short cycle)
        {
            CaseId = caseId;
            EventNo = eventNo;
            Cycle = cycle;
        }
        
        [Key]
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public long Id { get; set; }

        [Column("CASEID")]
        [ForeignKey("Case")]
        public int CaseId { get; protected set; }

        [Column("EVENTNO")]
        public int EventNo { get; protected set; }

        [Column("CYCLE")]
        public short Cycle { get; protected set; }

        [Column("EVENTDATE")]
        public DateTime? EventDate { get; set; }

        [Column("EVENTDUEDATE")]
        public DateTime? EventDueDate { get; set; }

        [Column("DATEREMIND")]
        public DateTime? ReminderDate { get; set; }

        [Column("DATEDUESAVED")]
        public decimal? IsDateDueSaved { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("OCCURREDFLAG")]
        public decimal? IsOccurredFlag { get; set; }

        [Column("CREATEDBYCRITERIA")]
        public int? CreatedByCriteriaKey { get; set; }

        [MaxLength(2)]
        [Column("CREATEDBYACTION")]
        public string CreatedByActionKey { get; set; }

        [Column("ENTEREDDEADLINE")]
        public int? EnteredDeadline { get; set; }

        [MaxLength(1)]
        [StringLength(1)]
        [Column("PERIODTYPE")]
        public string PeriodType { get; set; }

        [MaxLength(254)]
        [Column("EVENTTEXT")]
        public string EventText { get; set; }

        [Column("EVENTLONGTEXT")]
        public string EventLongText { get; set; }

        [Column("LONGFLAG")]
        public decimal? IsLongEventText { get; set; }

        [MaxLength(3)]
        [Column("DUEDATERESPNAMETYPE")]
        public string DueDateResponsibilityNameType { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeNo { get; set; }

        [Column("FROMCASEID")]
        public int? FromCaseId { get; internal set; }

        [Column("GOVERNINGEVENTNO")]
        public int? GoverningEventNo { get; set; }

        [MaxLength(50)]
        [Column("LOGUSERID")]
        public string LogUserId { get; set; }

        [MaxLength(128)]
        [Column("LOGAPPLICATION")]
        public string LogApplication { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Event")]
        public virtual Event Event { get; set; }

        public virtual Case Case { get; set; }
    }

    public static class CaseEventExt
    {
        public static bool HasOccurred(this CaseEvent source)
        {
            if (source == null) throw new ArgumentNullException("source");
            return HasOccured(source.IsOccurredFlag);
        }

        public static IQueryable<CaseEvent> WhereNotOccurred(this IQueryable<CaseEvent> source)
        {
            return source.Where(_ => _.IsOccurredFlag == null || _.IsOccurredFlag == 0);
        }
        public static IQueryable<CaseEvent> WhereHasOccurred(this IQueryable<CaseEvent> source)
        {
            return source.Where(_ => _.IsOccurredFlag >= 1 && _.IsOccurredFlag <= 8);
        }

        public static IQueryable<CaseEvent> WhereNotManuallyEnteredEventDate(this IQueryable<CaseEvent> source)
        {
            return source.Where(_ => _.IsOccurredFlag < 9);
        }

        public static string EffectiveEventText(this CaseEvent source)
        {
            if (source == null) throw new ArgumentNullException("source");

            return source.IsLongEventText.GetValueOrDefault() == 1 ? source.EventLongText : source.EventText;
        }

        public static bool HasOccured(decimal? isOccurredFlag)
        {
            if (!isOccurredFlag.HasValue) return false;
            return isOccurredFlag.Value >= 1 && isOccurredFlag <= 8;
        }
    }
}
using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Reminders
{
    [Table("ALERT")]
    public class AlertRule
    {
        [Obsolete("For persistence only.")]
        public AlertRule()
        {
        }

        public AlertRule(int staffId, DateTime dateCreated)
        {
            StaffId = staffId;
            DateCreated = dateCreated;
        }

        [Key]
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public long Id { get; set; }

        [Column("EMPLOYEENO")]
        [ForeignKey("StaffName")]
        public int StaffId { get; set; }

        [Column("ALERTSEQ")]
        public DateTime DateCreated { get; set; }

        [Column("CASEID")]
        [ForeignKey("Case")]
        public int? CaseId { get; set; }

        [Column("SEQUENCENO")]
        public int SequenceNo { get; set; }

        [Column("NAMENO")]
        [ForeignKey("Name")]
        public int? NameId { get; set; }

        [Column("EVENTNO")]
        [ForeignKey("Event")]
        public int? EventId { get; set; }

        [MaxLength(20)]
        [Column("REFERENCE")]
        public string Reference { get; set; }

        [MaxLength(2)]
        [Column("IMPORTANCELEVEL")]
        public string Importance { get; set; }

        [Column("ALERTDATE")]
        public DateTime? AlertDate { get; set; }

        [Column("DUEDATE")]
        public DateTime? DueDate { get; set; }

        [MaxLength(1000)]
        [Column("ALERTMESSAGE")]
        public string AlertMessage { get; set; }

        [Column("OCCURREDFLAG")]
        public decimal? OccurredFlag { get; set; }

        [Column("DATEOCCURRED")]
        public DateTime? DateOccurred { get; set; }

        [Column("TRIGGEREVENTNO")]
        [ForeignKey("TriggerEvent")]
        public int? TriggerEventNo { get; set; }

        [Column("DELETEDATE")]
        public DateTime? DeleteDate { get; set; }

        [Column("STOPREMINDERSDATE")]
        public DateTime? StopReminderDate { get; set; }

        [Column("MONTHLYFREQUENCY")]
        public short? MonthlyFrequency { get; set; }

        [Column("MONTHSLEAD")]
        public short? MonthsLead { get; set; }

        [Column("DAYSLEAD")]
        public short? DaysLead { get; set; }

        [Column("DAILYFREQUENCY")]
        public short? DailyFrequency { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeId { get; set; }

        [Column("EMPLOYEEFLAG")]
        public bool EmployeeFlag { get; set; }

        [Column("SIGNATORYFLAG")]
        public bool SignatoryFlag { get; set; }

        [Column("CRITICALFLAG")]
        public bool CriticalFlag { get; set; }

        [Column("RELATIONSHIP")]
        public string Relationship { get; set; }

        [Column("SENDELECTRONICALLY")]
        public decimal? SendElectronically { get; set; }

        [MaxLength(100)]
        [Column("EMAILSUBJECT")]
        public string EmailSubject { get; set; }

        [Column("CYCLE")]
        public short? Cycle { get; set; }

        public virtual Name StaffName { get; set; }

        public virtual Case Case { get; set; }

        public virtual Name Name { get; set; }

        public virtual Event Event { get; set; }
        public virtual Event TriggerEvent { get; set; }

    }
}
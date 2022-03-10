using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Reminders
{
    [Table("EMPLOYEEREMINDER")]
    public class StaffReminder
    {
        [Obsolete("For persistence only.")]
        public StaffReminder()
        {

        }
        public StaffReminder(int staffId, DateTime dateCreated)
        {
            StaffId = staffId;
            DateCreated = dateCreated;
        }

        [Key]
        [Column("ID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public long EmployeeReminderId { get; set; }

        [Column("EMPLOYEENO")]
        [ForeignKey("StaffName")]
        public int StaffId { get; set; }

        [Column("MESSAGESEQ")]
        public DateTime DateCreated { get; set; }

        [Column("CASEID")]
        [ForeignKey("Case")]
        public int? CaseId { get; set; }

        [Column("NAMENO")]
        [ForeignKey("Name")]
        public int? NameId { get; set; }

        [Column("FORWARDEDFROM")]
        [ForeignKey("ForwardedFromName")]
        public int? ForwardedFrom { get; set; }

        [Column("ALERTNAMENO")]
        [ForeignKey("AlertName")]
        public int? AlertNameId { get; set; }

        [MaxLength(20)]
        [Column("REFERENCE")]
        public string Reference { get; set; }

        [Column("EVENTNO")]
        [ForeignKey("Event")]
        public int? EventId { get; set; }

        [Column("CYCLENO")]
        public short? Cycle { get; set; }

        [Column("DUEDATE")]
        public DateTime? DueDate { get; set; }

        [Column("REMINDERDATE")]
        public DateTime? ReminderDate { get; set; }

        [Column("HOLDUNTILDATE")]
        public DateTime? HoldUntilDate { get; set; }

        [Column("DATEUPDATED")]
        public DateTime? DateUpdated { get; set; }
        
        [MaxLength(254)]
        [Column("SHORTMESSAGE")]
        public string ShortMessage { get; set; }

        [Column("LONGMESSAGE")]
        public string LongMessage { get; set; }

        [Column("COMMENTS")]
        public string Comments { get; set; }

        [Column("SEQUENCENO")]
        public int SequenceNo { get; set; }

        [Column("MESSAGE_TID")]
        public int? MessageTId { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LogDateTimeStamp { get; set; }

        [Column("SOURCE")]
        public decimal? Source { get; set; }

        [Column("READFLAG")]
        public Decimal? IsRead { get; set; }

        public virtual Name StaffName { get; set; }

        public virtual Case Case { get; set; }

        public virtual Name Name { get; set; }

        public virtual Name AlertName { get; set; }

        public virtual Name ForwardedFromName { get; set; }

        public virtual Event Event { get; set; }
    }
}
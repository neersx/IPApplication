using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;

namespace InprotechKaizen.Model.Reminders
{
    [Table("ALERTTEMPLATE")]
    public class AlertTemplate
    {
        [Key]
        [Column("ALERTTEMPLATECODE")]
        public string AlertTemplateCode { get; set; }

        [Column("ALERTMESSAGE")]
        public string AlertMessage { get; set; }

        [Column("MONTHLYFREQUENCY")]
        public short? MonthlyFrequency { get; set; }

        [Column("MONTHSLEAD")]
        public short? MonthsLead { get; set; }

        [Column("DAYSLEAD")]
        public short? DaysLead { get; set; }

        [Column("DAILYFREQUENCY")]
        public short? DailyFrequency { get; set; }

        [Column("STOPALERT")]
        public short? StopAlert { get; set; }

        [Column("DELETEALERT")]
        public short? DeleteAlert { get; set; }

        [Column("SENDELECTRONICALLY")]
        public bool? SendElectronically { get; set; }

        [Column("EMAILSUBJECT")]
        public string EmailSubject { get; set; }

        [Column("EMPLOYEEFLAG")]
        public bool? EmployeeFlag { get; set; }

        [Column("SIGNATORYFLAG")]
        public bool? SignatoryFlag { get; set; }

        [Column("CRITICALFLAG")]
        public bool? CriticalFlag { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameTypeId { get; set; }

        [Column("RELATIONSHIP")]
        public string Relationship { get; set; }

        [Column("EMPLOYEENO")]
        public int? StaffId { get; set; }

        [MaxLength(2)]
        [Column("IMPORTANCELEVEL")]
        public string Importance { get; set; }
    }
}
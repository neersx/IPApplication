using System;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Security;
using Action = InprotechKaizen.Model.Cases.Action;

namespace InprotechKaizen.Model.Policing
{
    [Table("POLICING")]
    public class PolicingRequest
    {
        [Obsolete("For persistence only.")]
        public PolicingRequest()
        {
        }

        public PolicingRequest(int? caseId)
        {
            CaseId = caseId;
        }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("TYPEOFREQUEST")]
        public short? TypeOfRequest { get; set; }

        [Column("SYSGENERATEDFLAG")]
        public decimal? IsSystemGenerated { get; set; }

        [Column("DATEENTERED")]
        public DateTime DateEntered { get; set; }

        [Column("POLICINGSEQNO")]
        public int SequenceNo { get; set; }

        [Column("BATCHNO")]
        public int? BatchNumber { get; set; }

        [Column("ONHOLDFLAG")]
        public decimal? OnHold { get; set; }

        [Column("EVENTNO")]
        public int? EventNo { get; set; }

        [Column("CYCLE")]
        public short? EventCycle { get; set; }

        [Column("CRITERIANO")]
        public int? CriteriaNo { get; set; }

        [Required]
        [MaxLength(40)]
        [Column("POLICINGNAME")]
        public string Name { get; set; }

        [Column("EMPLOYEENO")]
        public int? EmployeeId { get; set; }

        [Column("IDENTITYID")]
        public int? IdentityId { get; set; }

        [Key]
        [Column("REQUESTID")]
        [DatabaseGenerated(DatabaseGeneratedOption.Identity)]
        public int RequestId { get; set; }

        [Column("LOGDATETIMESTAMP")]
        public DateTime? LastModified { get; set; }

        public virtual User User { get; set; }

        public virtual Case Case { get; set; }

        [MaxLength(2)]
        [Column("ACTION")]
        public string Action { get; set; }

        [Column("EXCLUDEACTION")]
        public decimal? ExcludeAction { get; set; }

        [MaxLength(50)]
        [Column("SQLUSER")]
        public string SqlUser { get; set; }

        [Column("SPIDINPROGRESS")]
        public int? ProcessIdInProgress { get; set; }

        [Column("SCHEDULEDDATETIME")]
        public DateTime? ScheduledDateTime { get; set; }

        [Column("NOTES")]
        public string Notes { get; set; }

        [Column("POLICINGNAME_TID")]
        public int? PolicingNameTId { get; set; }

        [Column("NOTES_TID")]
        public int? NotesTId { get; set; }

        [Column("FROMDATE")]
        public DateTime? FromDate { get; set; }

        [Column("UNTILDATE")]
        public DateTime? UntilDate { get; set; }

        [Column("LETTERDATE")]
        public DateTime? LetterDate { get; set; }

        [Column("NOOFDAYS")]
        public short? NoOfDays { get; set; }

        [Column("DUEDATEONLYFLAG")]
        public decimal? IsDueDateOnly { get; set; }

        [Column("REMINDERFLAG")]
        public decimal? IsReminder { get; set; }

        [Column("LETTERFLAG")]
        public decimal? IsLetter { get; set; }

        [Column("ADHOCFLAG")]
        public decimal? IsAdhocReminder { get; set; }

        [Column("UPDATEFLAG")]
        public decimal? IsUpdate { get; set; }

        [Column("CRITERIAFLAG")]
        public decimal? IsRecalculateCriteria { get; set; }

        [Column("CALCREMINDERFLAG")]
        public decimal? IsRecalculateReminder { get; set; }

        [Column("DUEDATEFLAG")]
        public decimal? IsRecalculateDueDate { get; set; }

        [Column("RECALCEVENTDATE")]
        public bool? IsRecalculateEventDate { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("EMAILFLAG")]
        public bool? IsEmailFlag { get; set; }

        [MaxLength(3)]
        [Column("COUNTRYCODE")]
        public string Jurisdiction { get; set; }

        [Column("EXCLUDECOUNTRY")]
        public decimal? ExcludeJurisdiction { get; set; }

        [MaxLength(1)]
        [Column("PROPERTYTYPE")]
        public string PropertyType { get; set; }

        [Column("EXCLUDEPROPERTY")]
        public decimal? ExcludeProperty { get; set; }

        [MaxLength(1)]
        [Column("CASETYPE")]
        public string CaseType { get; set; }

        [MaxLength(2)]
        [Column("CASECATEGORY")]
        public string CaseCategory { get; set; }

        [MaxLength(2)]
        [Column("SUBTYPE")]
        public string SubType { get; set; }

        [MaxLength(254)]
        [Column("CASEOFFICEID")]
        public string Office { get; set; }

        [Column("DATEOFACT")]
        public DateTime? DateOfLaw { get; set; }

        [MaxLength(3)]
        [Column("NAMETYPE")]
        public string NameType { get; set; }

        [Column("NAMENO")]
        public int? NameNo { get; set; }

        [MaxLength(30)]
        [Column("IRN")]
        public string Irn { get; set; }

        public CaseType CaseTypeRecord { get; set; }

        public Country JurisdictionRecord { get; set; }

        public Name NameRecord { get; set; }

        public NameType NameTypeRecord { get; set; }

        public Event Event { get; set; }

        public Action ActionRecord { get; set; }

        public PropertyType PropertyTypeRecord { get; set; }

        public SubType SubTypeRecord { get; set; }
    }
}
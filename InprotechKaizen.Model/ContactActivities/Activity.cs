using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.ContactActivities
{
    [Table("ACTIVITY")]
    public class Activity
    {
        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        [Obsolete("For Persistence Only")]
        public Activity()
        {
            Attachments = new Collection<ActivityAttachment>();
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Activity(int id, string summary, TableCode activityCategory, TableCode activityType)
        {
            if (summary == null) throw new ArgumentNullException("summary");
            if (activityCategory == null) throw new ArgumentNullException("activityCategory");
            if (activityType == null) throw new ArgumentNullException("activityType");

            Id = id;
            Summary = summary;
            ActivityCategory = activityCategory;
            ActivityType = activityType;

            Attachments = new Collection<ActivityAttachment>();
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public Activity(int id, string summary, TableCode activityCategory, TableCode activityType, Case @case,
                        Name staffName, Name callerName, Name contactName, Name regardingName, Name referredToName)
        {
            if (summary == null) throw new ArgumentNullException("summary");
            if (activityCategory == null) throw new ArgumentNullException("activityCategory");
            if (activityType == null) throw new ArgumentNullException("activityType");

            Id = id;
            Summary = summary;
            ActivityCategory = activityCategory;
            ActivityType = activityType;
            Case = @case;
            StaffName = staffName;
            CallerName = callerName;
            ContactName = contactName;
            RelatedName = regardingName;
            ReferredToName = referredToName;

            Attachments = new Collection<ActivityAttachment>();
        }

        [Key]
        [DatabaseGenerated(DatabaseGeneratedOption.None)]
        [Column("ACTIVITYNO")]
        public int Id { get; set; }

        [Required(AllowEmptyStrings = true)]
        [MaxLength(254)]
        [Column("SUMMARY")]
        public string Summary { get; set; }

        [Column("ACTIVITYDATE")]
        public DateTime? ActivityDate { get; set; }

        [Column("ACTIVITYCATEGORY")]
        public int ActivityCategoryId { get; set; }

        public virtual TableCode ActivityCategory { get; set; }

        [Column("ACTIVITYTYPE")]
        public int ActivityTypeId { get; set; } 

        public virtual TableCode ActivityType { get; set; }

        [Column("NAMENO")]
        public int? ContactNameId { get; set; }

        [Column("EMPLOYEENO")]
        public int? StaffNameId { get; set; }

        [Column("CALLER")]
        public int? CallerNameId { get; set; }

        [Column("RELATEDNAME")]
        public int? RelatedNameId { get; set; }

        [Column("REFERREDTO")]
        public int? ReferredToNameId { get; set; }

        [Column("CALLTYPE")]
        public decimal? CallType { get; set; }

        [Column("CALLSTATUS")]
        public short? CallStatus { get; set; }

        [Column("INCOMPLETE")]
        public decimal Incomplete { get; set; }

        [MaxLength(20)]
        [Column("REFERENCENO")]
        public string ReferenceNo { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("LONGFLAG")]
        public decimal? LongFlag { get; set; }

        [MaxLength(254)]
        [Column("NOTES")]
        public string Notes { get; set; }

        [Column("LONGNOTES")]
        public string LongNotes { get; set; }

        [Column("USERIDENTITYID")]
        public int? UserIdentityId { get; set; }

        [MaxLength(50)]
        [Column("CLIENTREFERENCE")]
        public string ClientReference { get; set; }

        [Column("PRIORARTID")]
        public int? PriorartId { get; set; }

        [Column("CYCLE")]
        public short? Cycle { get; set; }

        [Column("CASEID")]
        public int? CaseId { get; set; }

        [Column("EVENTNO")]
        public int? EventId { get; set; }

        public virtual ICollection<ActivityAttachment> Attachments { get; protected set; }

        public virtual Name StaffName { get; protected set; }

        public virtual Name ContactName { get; protected set; }

        public virtual Name CallerName { get; protected set; }

        public virtual Name RelatedName { get; protected set; }

        public virtual Name ReferredToName { get; protected set; }

        [SuppressMessage("Microsoft.Naming", "CA1716:IdentifiersShouldNotMatchKeywords", MessageId = "Case")]
        public virtual Case Case { get; protected set; }
    }
}
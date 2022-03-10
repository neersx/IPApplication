using System;
using System.Collections.Generic;
using System.Collections.ObjectModel;
using System.ComponentModel.DataAnnotations;
using System.ComponentModel.DataAnnotations.Schema;
using System.Diagnostics.CodeAnalysis;
using System.Linq;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Configuration.Screens;

namespace InprotechKaizen.Model.Rules
{
    [Table("DETAILCONTROL")]
    public class DataEntryTask
    {
        [Obsolete("For persistence only.")]
        public DataEntryTask()
        {
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public DataEntryTask(Criteria criteria, short entryId)
        {
            if (criteria == null) throw new ArgumentNullException(nameof(criteria));
            CriteriaId = criteria.Id;
            Criteria = criteria;
            Id = entryId;
        }

        public DataEntryTask(int criteriaId, short entryId)
        {
            CriteriaId = criteriaId;
            Id = entryId;
        }

        [SuppressMessage("Microsoft.Usage", "CA2214:DoNotCallOverridableMethodsInConstructors")]
        public DataEntryTask(
            Criteria criteria,
            short entryId,
            Status caseStatus,
            Status renewalStatus,
            NumberType numberType,
            TableCode fileLocation) :
            this(criteria, entryId)
        {
            CaseStatus = caseStatus;
            RenewalStatus = renewalStatus;
            OfficialNumberType = numberType;
            FileLocation = fileLocation;

            FileLocationId = FileLocation?.Id;
            CaseStatusCodeId = CaseStatus?.Id;
            RenewalStatusId = RenewalStatus?.Id;
            OfficialNumberTypeId = OfficialNumberType?.NumberTypeCode;
        }

        [Key]
        [Column("CRITERIANO", Order = 0)]
        public int CriteriaId { get; set; }

        [Key]
        [Column("ENTRYNUMBER", Order = 1)]
        public short Id { get; set; }

        [MaxLength(100)]
        [Column("ENTRYDESC")]
        public string Description { get; set; }

        [Column("ENTRYDESC_TID")]
        public int? DescriptionTId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("TAKEOVERFLAG")]
        public decimal? TakeoverFlag { get; set; }

        [Column("DISPLAYSEQUENCE")]
        public short DisplaySequence { get; set; }

        [Column("DIMEVENTNO")]
        public int? DimEventNo { get; set; }

        [Column("DISPLAYEVENTNO")]
        public int? DisplayEventNo { get; set; }

        [Column("HIDEEVENTNO")]
        public int? HideEventNo { get; set; }

        [Column("STATUSCODE")]
        public short? CaseStatusCodeId { get; set; }

        [Column("RENEWALSTATUS")]
        public short? RenewalStatusId { get; set; }

        [MaxLength(3)]
        [Column("NUMBERTYPE")]
        public string OfficialNumberTypeId { get; set; }

        [Column("FILELOCATION")]
        public int? FileLocationId { get; set; }

        [MaxLength(254)]
        [Column("USERINSTRUCTION")]
        public string UserInstruction { get; set; }

        [Column("USERINSTRUCTION_TID")]
        public int? UserInstructionTId { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("ATLEAST1FLAG")]
        public decimal? AtLeastOneFlag { get; set; }

        [Column("POLICINGIMMEDIATE")]
        public bool ShouldPoliceImmediate { get; set; }

        [Column("PARENTCRITERIANO")]
        public int? ParentCriteriaId { get; set; }

        [Column("PARENTENTRYNUMBER")]
        public short? ParentEntryId { get; set; }

        [Column("INHERITED")]
        public decimal? Inherited { get; set; }

        [NotMapped]
        public bool IsInherited
        {
            get { return Inherited.GetValueOrDefault(0) != 0; }
            set { Inherited = value ? 1 : 0; }
        }

        [MaxLength(10)]
        [Column("ENTRYCODE")]
        public string EntryCode { get; set; }

        [Column("SHOWTABS")]
        public decimal? ShowTabs { get; set; }

        [Column("SHOWMENUS")]
        public decimal? ShowMenus { get; set; }

        [Column("SHOWTOOLBAR")]
        public decimal? ShowToolBar { get; set; }

        [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "Flag")]
        [Column("CHARGEGENERATION")]
        public decimal? ChargeGenerationFlag { get; set; }

        [Column("ISSEPARATOR")]
        public bool IsSeparator { get; set; }

        public bool AtLeastOneEventMustBeEntered => AtLeastOneFlag.GetValueOrDefault() == 1;

        public virtual Status CaseStatus { get; internal set; }

        public virtual Status RenewalStatus { get; internal set; }

        public virtual ICollection<UserControl> UsersAllowed { get; set; } = new Collection<UserControl>();

        public virtual ICollection<RolesControl> RolesAllowed { get; set; } = new List<RolesControl>();

        public virtual ICollection<GroupControl> GroupsAllowed { get; set; } = new List<GroupControl>();

        public virtual ICollection<AvailableEvent> AvailableEvents { get; set; } = new Collection<AvailableEvent>();

        public virtual Criteria Criteria { get; protected set; }

        public virtual NumberType OfficialNumberType { get; set; }

        public virtual TableCode FileLocation { get; set; }

        public virtual ICollection<DocumentRequirement> DocumentRequirements { get; set; } = new Collection<DocumentRequirement>();

        public virtual ICollection<WindowControl> TaskSteps { get; set; } = new List<WindowControl>();

        public virtual Event DisplayEvent { get; set; }

        public virtual Event HideEvent { get; set; }

        public virtual Event DimEvent { get; set; }

        public bool HasEventsRequiringAnImmediatePolicingService
        {
            get { return AvailableEvents.Any(ae => ae.Event.ShouldPoliceImmediate); }
        }

        [NotMapped]
        public InheritanceLevel InheritanceLevel { get; set; }

        public bool IsPartiallyInherited
        {
            get { return Inherited == 1 || AvailableEvents.Any(_ => _.Inherited == 1) || DocumentRequirements.Any(_ => _.Inherited == 1); }
        }

        public WindowControl WorkflowWizard
        {
            get { return TaskSteps.SingleOrDefault(_ => _.Name == "WorkflowWizard"); }
        }

        public bool ShouldConfirmStatusChangeOnSave(Case @case)
        {
            if (@case == null) throw new ArgumentNullException(nameof(@case));

            var isRequired = false;
            if (CaseStatusCodeId.HasValue && !CaseStatus.Equals(@case.CaseStatus))
            {
                isRequired = CaseStatus.IsConfirmationRequired;
            }

            return isRequired;
        }

        public void SetFileLocation(TableCode fileLocation)
        {
            FileLocation = fileLocation;
            FileLocationId = FileLocation?.Id;
        }

        public void SetOfficialNumberType(NumberType numberType)
        {
            OfficialNumberType = numberType;
        }

        public void AddWorkflowWizardStep(params TopicControl[] step)
        {
            var workflowWizard = WorkflowWizard;
            if (workflowWizard == null)
            {
                workflowWizard = new WindowControl(CriteriaId, Id);
                TaskSteps.Add(workflowWizard);
            }

            if (step != null)
            {
                workflowWizard.TopicControls.AddRange(step);
            }
        }
    }

    public static class DataEntryTaskExt
    {
        public static IEnumerable<DataEntryTask> Separators(this IEnumerable<DataEntryTask> entries)
        {
            return entries.Where(_ => _.IsSeparator);
        }

        public static IEnumerable<DataEntryTask> WithoutSeparators(this IEnumerable<DataEntryTask> entries)
        {
            return entries.Where(_ => !_.IsSeparator);
        }

        public static bool CompareDescriptions(this DataEntryTask d, string otherDescription)
        {
            return d.IsSeparator ? string.Equals(d.Description, otherDescription, StringComparison.CurrentCultureIgnoreCase)
                : string.Equals(d.Description.StripNonAlphanumerics(), otherDescription.StripNonAlphanumerics(), StringComparison.CurrentCultureIgnoreCase);
        }
    }
}
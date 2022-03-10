using System.Collections.Generic;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance.Steps;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public class WorkflowEntryControlSaveModel
    {
        public WorkflowEntryControlSaveModel()
        {
            EntryEventDelta = new Delta<EntryEventDelta>();
            EntryEventsMoved = new EntryEventMovementsBase[0];

            StepsDelta = new Delta<StepDelta>();
            StepsMoved = new StepMovements[0];
            DocumentsDelta = new Delta<EntryDocumentDelta>();
            UserAccessDelta = new Delta<int>();
        }

        public bool ResetInheritance { get; set; }

        public int CriteriaId { get; set; }
        public short Id { get; set; }
        public string Description { get; set; }
        public string UserInstruction { get; set; }

        public Delta<EntryEventDelta> EntryEventDelta { get; set; }
        public IEnumerable<EntryEventMovementsBase> EntryEventsMoved { get; set; }
        public Delta<StepDelta> StepsDelta { get; set; }
        public IEnumerable<StepMovements> StepsMoved { get; set; }
        public Delta<EntryDocumentDelta> DocumentsDelta { get; set; }
        public Delta<int> UserAccessDelta{ get; set; }

        public bool AtLeastOneFlag { get; set; }
        public bool ShouldPoliceImmediate { get; set; }
        public string OfficialNumberTypeId { get; set; }
        public int? FileLocationId { get; set; }
        public bool ApplyToDescendants { get; set; }
        public int? DisplayEventNo { get; set; }
        public int? HideEventNo { get; set; }
        public int? DimEventNo { get; set; }
        public short? CaseStatusCodeId { get; set; }
        public short? RenewalStatusId { get; set; }
    }

    public class WorkflowEntryControlModel
    {
        public WorkflowEntryControlModel Parent { get; set; }
        public int CriteriaId { get; set; }
        public int EntryId { get; set; }
        public bool IsProtected { get; set; }
        public bool CanEditProtected { get; set; }
        public bool EditBlockedByDescendents { get; set; }
        public PicklistModel<string> OfficialNumberType { get; set; }
        public PicklistModel<int> FileLocation { get; set; }
        public bool AtLeastOneEventFlag { get; set; }
        public bool PoliceImmediately { get; set; }
        public PicklistModel<short> ChangeCaseStatus { get; set; }
        public PicklistModel<short> ChangeRenewalStatus { get; set; }
        public string Description { get; set; }
        public string UserInstruction { get; set; }

        public bool IsSeparator { get; set; }
        public bool CanEdit { get; set; }
        public bool EditBlockedByDescendants { get; set; }
        public PicklistModel<int> DisplayEvent { get; set; }
        public PicklistModel<int> HideEvent { get; set; }
        public PicklistModel<int> DimEvent { get; set; }
        public bool HasParent { get; set; }
        public bool HasChildren { get; set; }
        public dynamic Characteristics { get; set; }
        public string InheritanceLevel { get; set; }
        public bool IsInherited { get; set; }
        /// <summary>
        /// Parent Entry based on Fuzzy Match if Inheritance is not already set.
        /// </summary>
        public bool HasParentEntry { get; set; }
        public bool ShowUserAccess { get; set; }
        public bool CanAddValidCombinations { get; set; }
    }

    public class EntryEventDelta
    {
        public int EventId { get; set; }
        public short? EventAttribute { get; set; }
        public short? DueAttribute { get; set; }
        public short? PolicingAttribute { get; set; }
        public short? DueDateResponsibleNameAttribute { get; set; }
        public short? OverrideDueAttribute { get; set; }
        public short? OverrideEventAttribute { get; set; }
        public short? PeriodAttribute { get; set; }
        public int? AlsoUpdateEventId { get; set; }
        public int? RelativeEventId { get; set; }
        public int? PreviousEventId { get; set; }
        
        public short? OverrideDisplaySequence { get; set; }
    }

    public class EntryEventMovementsBase
    {
        public EntryEventMovementsBase()
        {
        }

        public EntryEventMovementsBase(int eventId, int? prevEventId = null)
        {
            EventId = eventId;
            PrevEventId = prevEventId;
        }

        public int EventId { get; set; }

        public int? PrevEventId { get; set; }
    }

    public class StepMovements
    {
        public StepMovements()
        {
        }

        public StepMovements(int stepId, string prevStepIdentifier = null)
        {
            StepId = stepId;
            PrevStepIdentifier = prevStepIdentifier;
        }

        public int StepId { get; set; }

        public string PrevStepIdentifier { get; set; }
    }
    
    public class EntryDocumentDelta
    {
        public EntryDocumentDelta()
        {
            
        }
        public EntryDocumentDelta(short documentId, bool mustProduce)
        {
            DocumentId = documentId;
            MustProduce = mustProduce;
        }
        public short? PreviousDocumentId { get; set; }
        public short DocumentId { get; set; }
        public bool MustProduce { get; set; }
    }

    public static class WorkflowEntryControlSaveModelExt
    {
        public static WorkflowEntryControlSaveModel GetResetModelFrom(DataEntryTask p, bool appliesToDescendants)
        {
            return new WorkflowEntryControlSaveModel
            {
                ResetInheritance = true,
                ApplyToDescendants = appliesToDescendants,
                Description = p.Description,
                UserInstruction = p.UserInstruction,
                AtLeastOneFlag = p.AtLeastOneEventMustBeEntered,
                ShouldPoliceImmediate = p.ShouldPoliceImmediate,
                OfficialNumberTypeId = p.OfficialNumberTypeId,
                FileLocationId = p.FileLocationId,
                DisplayEventNo = p.DisplayEventNo,
                HideEventNo = p.HideEventNo,
                DimEventNo = p.DimEventNo,
                CaseStatusCodeId = p.CaseStatusCodeId,
                RenewalStatusId = p.RenewalStatusId
            };
        }
    }
}
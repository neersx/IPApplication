using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.Configuration.Rules.Workflow.EntryControlMaintenance;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Extensions;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IWorkflowEntryControlService
    {
        Task<WorkflowEntryControlModel> GetEntryControl(int criteriaId, int entryId, bool suppressParent = false);

        void ResetEntryControl(int criteriaId, int entryId, bool appliesToDescendants);

        void BreakEntryControlInheritance(int criteriaId, int entryId);
    }

    internal class WorkflowEntryControlService : IWorkflowEntryControlService
    {
        readonly IDbContext _dbContext;
        readonly IInheritance _inheritance;
        readonly IWorkflowPermissionHelper _permissionHelper;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IEnumerable<ISectionMaintenance> _sectionMaintenances;
        readonly IInprotechVersionChecker _inprotechVersionChecker;
        readonly IWorkflowEntryDetailService _workflowEntryDetailService;
        readonly ITaskSecurityProvider _taskSecurity;

        public WorkflowEntryControlService(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IWorkflowPermissionHelper permissionHelper, IInheritance inheritance,
                                           IEnumerable<ISectionMaintenance> sectionMaintenances,
                                           IInprotechVersionChecker inprotechVersionChecker, IWorkflowEntryDetailService workflowEntryDetailService, ITaskSecurityProvider taskSecurity)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _permissionHelper = permissionHelper;
            _inheritance = inheritance;
            _sectionMaintenances = sectionMaintenances;
            _inprotechVersionChecker = inprotechVersionChecker;
            _workflowEntryDetailService = workflowEntryDetailService;
            _taskSecurity = taskSecurity;
        }

        public async Task<WorkflowEntryControlModel> GetEntryControl(int criteriaId, int entryId, bool suppressParent = false)
        {
            var culture = _preferredCultureResolver.Resolve();
            var criteria = await _dbContext.Set<Criteria>().WhereWorkflowCriteria()
                                           .Where(_ => _.Id == criteriaId)
                                           .Select(_ => new
                                                        {
                                                            Criteria = _,
                                                            Characteristics = new
                                                                              {
                                                                                  Jurisdiction = _.Country == null
                                                                                      ? null
                                                                                      : new
                                                                                        {
                                                                                            Key = _.Country.Id,
                                                                                            Value = DbFuncs.GetTranslation(_.Country.Name, null, _.Country.NameTId, culture)
                                                                                        },
                                                                                  PropertyType = _.PropertyType == null
                                                                                      ? null
                                                                                      : new
                                                                                        {
                                                                                            Key = _.PropertyType.Code,
                                                                                            Value = DbFuncs.GetTranslation(_.PropertyType.Name, null, _.PropertyType.NameTId, culture)
                                                                                        },
                                                                                  CaseType = _.CaseType == null
                                                                                      ? null
                                                                                      : new
                                                                                        {
                                                                                            Key = _.CaseType.Code,
                                                                                            Value = DbFuncs.GetTranslation(_.CaseType.Name, null, _.CaseType.NameTId, culture)
                                                                                        }
                                                                              }
                                                        })
                                           .SingleAsync();

            var model = await _dbContext.Set<DataEntryTask>()
                                        .Where(_ => (_.CriteriaId == criteriaId) && (_.Id == entryId))
                                        .Select(_ => new
                                                     {
                                                         dataEntryTask = _,
                                                         _.Description,
                                                         _.UserInstruction,
                                                         OfficialNumberType = _.OfficialNumberTypeId == null ? null : DbFuncs.GetTranslation(_.OfficialNumberType.Name, null, _.OfficialNumberType.NameTId, culture),
                                                         FileLocation = _.FileLocationId == null ? null : DbFuncs.GetTranslation(_.FileLocation.Name, null, _.FileLocation.NameTId, culture),
                                                         CaseStatus = _.CaseStatusCodeId == null ? null : DbFuncs.GetTranslation(_.CaseStatus.Name, null, _.CaseStatus.NameTId, culture),
                                                         RenewalStatus = _.RenewalStatusId == null ? null : DbFuncs.GetTranslation(_.RenewalStatus.Name, null, _.RenewalStatus.NameTId, culture),
                                                         DisplayEvent = _.DisplayEventNo == null ? null : DbFuncs.GetTranslation(_.DisplayEvent.Description, null, _.DisplayEvent.DescriptionTId, culture),
                                                         HideEvent = _.HideEventNo == null ? null : DbFuncs.GetTranslation(_.HideEvent.Description, null, _.HideEvent.DescriptionTId, culture),
                                                         DimEvent = _.DimEventNo == null ? null : DbFuncs.GetTranslation(_.DimEvent.Description, null, _.DimEvent.DescriptionTId, culture)
                                                     }).SingleAsync();

            bool editblockedByDescendants;
            var canEdit = _permissionHelper.CanEdit(criteria.Criteria, out editblockedByDescendants);

            var parentInheritance = _dbContext.Set<Inherits>().SingleOrDefault(i => i.CriteriaNo == criteriaId);
            var hasParent = model.dataEntryTask.IsInherited && parentInheritance != null;
            var hasChildren = _dbContext.Set<Inherits>()
                                        .Any(i => (i.FromCriteriaNo == criteriaId)
                                                  && i.Criteria.DataEntryTasks
                                                      .Any(e => DbFuncs.StripNonAlphanumerics(e.Description) == DbFuncs.StripNonAlphanumerics(model.dataEntryTask.Description) && e.Inherited == 1));
            var inheritanceLevel = _inheritance.GetInheritanceLevel(criteriaId, model.dataEntryTask);
            var isInherited = inheritanceLevel != InheritanceLevel.None;

            var description = model.Description;
            var instructions = model.UserInstruction;
            if (!canEdit)
            {
                var translated = _dbContext.Set<DataEntryTask>()
                                  .Where(_ => _.CriteriaId == criteriaId && _.Id == entryId)
                                  .Select(_ => new
                                               {
                                                   Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture),
                                                   UserInstructions = DbFuncs.GetTranslation(_.UserInstruction, null, _.UserInstructionTId, culture)
                                               }).Single();
                description = translated.Description;
                instructions = translated.UserInstructions;
            }

            var showUserAccess = _inprotechVersionChecker.CheckMinimumVersion(12, 1);

            var hasParentEntry = isInherited || _inheritance.HasParentEntryWithFuzzyMatch(model.dataEntryTask);

            WorkflowEntryControlModel parent = null;
            if (isInherited && !suppressParent)
            {
                var parentEntry = parentInheritance.FromCriteria.DataEntryTasks.Where(d => d.CompareDescriptions(description)).ToArray();
                if (parentEntry.Length == 1)
                    parent = await GetEntryControl(parentInheritance.FromCriteriaNo, parentEntry.First().Id, true);
            }

            return new WorkflowEntryControlModel
                   {
                       Parent = parent,
                       CriteriaId = criteriaId,
                       EntryId = entryId,
                       IsProtected = criteria.Criteria.IsProtected,
                       CanEdit = canEdit,
                       EditBlockedByDescendants = editblockedByDescendants,
                       Description = description,
                       UserInstruction = instructions,
                       IsSeparator = model.dataEntryTask.IsSeparator,
                       OfficialNumberType = PicklistModelHelper.GetPicklistOrNull(model.dataEntryTask.OfficialNumberTypeId, model.OfficialNumberType),
                       FileLocation = PicklistModelHelper.GetPicklistOrNull(model.dataEntryTask.FileLocationId, model.FileLocation),
                       AtLeastOneEventFlag = model.dataEntryTask.AtLeastOneEventMustBeEntered,
                       PoliceImmediately = model.dataEntryTask.ShouldPoliceImmediate,
                       ChangeCaseStatus = PicklistModelHelper.GetPicklistOrNull(model.dataEntryTask.CaseStatusCodeId, model.CaseStatus),
                       ChangeRenewalStatus = PicklistModelHelper.GetPicklistOrNull(model.dataEntryTask.RenewalStatusId, model.RenewalStatus),
                       DisplayEvent = PicklistModelHelper.GetPicklistOrNull(model.dataEntryTask.DisplayEventNo, model.DisplayEvent),
                       HideEvent = PicklistModelHelper.GetPicklistOrNull(model.dataEntryTask.HideEventNo, model.HideEvent),
                       DimEvent = PicklistModelHelper.GetPicklistOrNull(model.dataEntryTask.DimEventNo, model.DimEvent),
                       Characteristics = criteria.Characteristics,
                       HasParent = hasParent,
                       HasChildren = hasChildren,
                       IsInherited = isInherited,
                       InheritanceLevel = inheritanceLevel.ToString(),
                       HasParentEntry = hasParentEntry,
                       ShowUserAccess = showUserAccess,
                       CanAddValidCombinations = _taskSecurity.HasAccessTo(ApplicationTask.MaintainValidCombinations, ApplicationTaskAccessLevel.Execute)
                   };
        }

        public void ResetEntryControl(int criteriaId, int entryId, bool appliesToDescendants)
        {
            var entryToReset = _dbContext.Set<DataEntryTask>()
                .Single(_ => _.CriteriaId == criteriaId && _.Id == entryId);

            var parentEntry = ResolveParentEntry(entryToReset);

            var saveModel = WorkflowEntryControlSaveModelExt.GetResetModelFrom(parentEntry, appliesToDescendants);
            saveModel.CriteriaId = entryToReset.CriteriaId;
            saveModel.Id = entryToReset.Id;

            foreach (var sectionMaintenance in _sectionMaintenances)
                sectionMaintenance.Reset(entryToReset, parentEntry, saveModel);
            
            _workflowEntryDetailService.UpdateEntryDetail(entryToReset, saveModel);

            entryToReset.IsInherited = true;
            entryToReset.ParentCriteriaId = parentEntry.CriteriaId;
            entryToReset.ParentEntryId = parentEntry.Id;

            _dbContext.SaveChanges();
        }

        public void BreakEntryControlInheritance(int criteriaId, int entryId)
        {
            var entryToReset = _dbContext.Set<DataEntryTask>()
                                         .Single(_ => _.CriteriaId == criteriaId && _.Id == entryId);
            entryToReset.RemoveInheritance();
            _dbContext.SaveChanges();
        }

        DataEntryTask ResolveParentEntry(DataEntryTask childEntry)
        {
            if(childEntry.ParentCriteriaId.HasValue && childEntry.ParentEntryId.HasValue)
                return _dbContext.Set<DataEntryTask>().Single(_ => _.CriteriaId == childEntry.ParentCriteriaId && _.Id == childEntry.ParentEntryId);

            var parentEntry = _inheritance.GetParentEntryWithFuzzyMatch(childEntry);
            if(parentEntry==null)
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            return parentEntry;
        }
    }
}
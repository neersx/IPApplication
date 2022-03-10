using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Compatibility;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Validations;
using Inprotech.Web.Configuration.Rules.Workflow.EventControlMaintenance;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.Rules.Workflow;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.StandingInstructions;
using InprotechKaizen.Model.ValidCombinations;
using InstructionType = InprotechKaizen.Model.StandingInstructions.InstructionType;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    public interface IWorkflowEventControlService
    {
        Task<WorkflowEventControlModel> GetEventControl(int criteriaId, int eventId, bool suppressParent = false);
        Task<IEnumerable<string>> GetUsedInInstructions(short? characteristicId);
        Task<IEnumerable<KeyValuePair<short, string>>> GetCharacteristicOptions(string instructionTypeCode);
        void SetUpdatedValuesForEvent(ValidEvent @event, ValidEvent newEventValues, EventControlFieldsToUpdate eventControlFieldsToUpdate);
        void UpdateEventControl(ValidEvent eventControl, WorkflowEventControlSaveModel allNewValues, EventControlFieldsToUpdate fieldsToUpdate = null);
        void NormaliseSaveModel(WorkflowEventControlSaveModel saveModel);
        IEnumerable<ValidationError> ValidateSaveModel(WorkflowEventControlSaveModel saveModel);
        void SetOriginalHashes(ValidEvent validEvent, WorkflowEventControlSaveModel formData);
        string ResetEventControl(int criteriaId, int eventId, bool applyToDescendents, bool? updateRespNameOnCases = null);
        bool CheckDueDateRespNameChange(ValidEvent parent, ValidEvent child);
    }

    public class WorkflowEventControlService : IWorkflowEventControlService
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IWorkflowPermissionHelper _permissionHelper;
        readonly IInheritance _inheritance;
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;
        readonly IEnumerable<IEventSectionMaintenance> _maintainableSections;
        readonly ITaskSecurityProvider _taskSecurity;
        readonly IIndex<string, ICharacteristicsService> _characteristicsService;

        readonly IInprotechVersionChecker _inprotechVersionChecker;

        public WorkflowEventControlService(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, IWorkflowPermissionHelper permissionHelper,
                                           IInheritance inheritance, IWorkflowEventInheritanceService workflowEventInheritanceService,
                                           IInprotechVersionChecker inprotechVersionChecker, IEnumerable<IEventSectionMaintenance> maintainableSections, ITaskSecurityProvider taskSecurity,
                                           IIndex<string, ICharacteristicsService> characteristicsService)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _permissionHelper = permissionHelper;
            _inheritance = inheritance;
            _workflowEventInheritanceService = workflowEventInheritanceService;
            _inprotechVersionChecker = inprotechVersionChecker;

            _maintainableSections = maintainableSections;
            _taskSecurity = taskSecurity;
            _characteristicsService = characteristicsService;
        }

        public async Task<WorkflowEventControlModel> GetEventControl(int criteriaId, int eventId, bool suppressParent = false)
        {
            var culture = _preferredCultureResolver.Resolve();

            var model = await _dbContext.Set<ValidEvent>()
                                        .Where(_ => _.CriteriaId == criteriaId && _.EventId == eventId)
                                        .Select(_ => new
                                        {
                                            ValidEvent = _,
                                            Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture),
                                            BaseDescription = DbFuncs.GetTranslation(_.Event.Description, null, _.Event.DescriptionTId, culture),
                                            DueDateRespNameTypeDescription = _.DueDateRespNameTypeCode == null ? null : DbFuncs.GetTranslation(_.DueDateRespNameType.Name, null, _.DueDateRespNameType.NameTId, culture),
                                            DateAdjustmentDescription = _.SyncedEventDateAdjustment == null ? null : DbFuncs.GetTranslation(_.SyncedEventDateAdjustment.Description, null, _.SyncedEventDateAdjustment.DescriptionTId, culture),
                                            ChargeOneDescription = _.InitialFee == null ? null : DbFuncs.GetTranslation(_.InitialFee.Description, null, _.InitialFee.DescriptionTId, culture),
                                            ChargeTwoDescription = _.InitialFee2 == null ? null : DbFuncs.GetTranslation(_.InitialFee2.Description, null, _.InitialFee2.DescriptionTId, culture),
                                            ChangeStatusDescription = _.ChangeStatusId == null ? null : DbFuncs.GetTranslation(_.ChangeStatus.Name, null, _.ChangeStatus.NameTId, culture),
                                            ChangeRenewalStatusDescription = _.ChangeRenewalStatusId == null ? null : DbFuncs.GetTranslation(_.ChangeRenewalStatus.Name, null, _.ChangeRenewalStatus.NameTId, culture),
                                            UserDefinedStatusDescription = _.UserDefinedStatus == null ? null : DbFuncs.GetTranslation(_.UserDefinedStatus, null, _.UserDefinedStatusTId, culture),
                                            ChangeNameTypeDescription = _.ChangeNameTypeCode == null ? null : DbFuncs.GetTranslation(_.ChangeNameType.Name, null, _.ChangeNameType.NameTId, culture),
                                            CopyFromNameTypeDescription = _.CopyFromNameTypeCode == null ? null : DbFuncs.GetTranslation(_.CopyFromNameType.Name, null, _.CopyFromNameType.NameTId, culture),
                                            MoveOldNameToNameTypeDescription = _.MoveOldNameToNameTypeCode == null ? null : DbFuncs.GetTranslation(_.MoveOldNameToNameType.Name, null, _.MoveOldNameToNameType.NameTId, culture),
                                            OpenActionDescription = _.OpenActionId == null ? null : DbFuncs.GetTranslation(_.OpenAction.Name, null, _.OpenAction.NameTId, culture),
                                            CloseActionDescription = _.CloseActionId == null ? null : DbFuncs.GetTranslation(_.CloseAction.Name, null, _.CloseAction.NameTId, culture)
                                        }).SingleAsync();

            var criteriaModel = await _dbContext.Set<Criteria>()
                                                .WhereWorkflowCriteria()
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
            var criteria = criteriaModel.Criteria;

            var validEvent = model.ValidEvent;
            validEvent.Description = model.Description;

            bool editblockedByDescendants, isNonConfigurableEvent;
            var canEdit = _permissionHelper.CanEditEvent(criteria, eventId, out editblockedByDescendants, out isNonConfigurableEvent);
            var canDelete = _permissionHelper.CanEdit(criteria);

            var parentCriteria = _dbContext.Set<Inherits>().SingleOrDefault(i => i.CriteriaNo == criteriaId && i.FromCriteria.ValidEvents.Any(_ => _.EventId == validEvent.EventId));
            var isInherited = validEvent.IsInherited && parentCriteria != null;
            var canResetInheritance = canEdit && parentCriteria != null;

            var hasChildren = _dbContext.Set<Inherits>().Any(i => i.FromCriteriaNo == criteriaId && i.Criteria.ValidEvents.Any(e => e.EventId == eventId && e.Inherited == 1));
            var dueDateRespType = DueDateRespTypes.NotApplicable;

            if (validEvent.Name != null)
                dueDateRespType = DueDateRespTypes.Name;
            else if (validEvent.DueDateRespNameType != null)
                dueDateRespType = DueDateRespTypes.NameType;

            var isRenewalStatusSupported = _inprotechVersionChecker.CheckMinimumVersion(12, 1);

            var caseStatus = PicklistModelHelper.GetPicklistOrNull(validEvent.ChangeStatusId, null, model.ChangeStatusDescription);
            var renewalStatus = PicklistModelHelper.GetPicklistOrNull(validEvent.ChangeRenewalStatusId, null, model.ChangeRenewalStatusDescription);
            if (isRenewalStatusSupported && model.ValidEvent.ChangeStatus != null && model.ValidEvent.ChangeStatus.IsRenewal && model.ValidEvent.ChangeRenewalStatusId == null)
            {
                renewalStatus = caseStatus;
                caseStatus = null;
            }

            WorkflowEventControlModel parent = null;
            if (isInherited && !suppressParent)
                parent = await GetEventControl(parentCriteria.FromCriteriaNo, eventId, true);

            var validCharacteristics = _characteristicsService[CriteriaPurposeCodes.EventsAndEntries].GetValidCharacteristics(new WorkflowCharacteristics()
            {
                Office = validEvent.OfficeId,
                CaseType = validEvent.CaseTypeId,
                Jurisdiction = validEvent.CountryCode,
                PropertyType = validEvent.PropertyTypeId,
                CaseCategory = validEvent.CaseCategoryId,
                SubType = validEvent.SubTypeId,
                Basis = validEvent.BasisId
            });

            var eventsExist = _dbContext.Set<RequiredEventRule>().Where(_ => _.CriteriaId == criteriaId && _.EventId == eventId).ToArray()
                                        .Select(_ => new InheritablePicklistModel(_.RequiredEventId, null, DbFuncs.GetTranslation(_.RequiredEvent.Description, null, _.RequiredEvent.DescriptionTId, culture), _.Inherited));

            var dueDateOccurs = (validEvent.SaveDueDate.GetValueOrDefault() & 2) == 2 ? "Immediate" : ((validEvent.SaveDueDate.GetValueOrDefault() & 4) == 4 ? "OnDueDate" : "NotApplicable");

            return new WorkflowEventControlModel
            {
                Parent = parent,
                CriteriaId = criteriaId,
                AllowDueDateCalcJurisdiction = criteria.Country == null,
                EventId = eventId,
                IsProtected = criteria.IsProtected,
                InheritanceLevel = _inheritance.GetInheritanceLevel(criteriaId, eventId).ToString(),
                CanEdit = canEdit,
                CanDelete = canDelete,
                EditBlockedByDescendants = editblockedByDescendants,
                IsNonConfigurableEvent = isNonConfigurableEvent,
                IsInherited = isInherited,
                HasChildren = hasChildren,
                HasDueDateOnCase = GetDueDatesForEventControl(criteriaId, eventId).WhereNotOccurred().Any(),
                IsRenewalStatusSupported = isRenewalStatusSupported,
                CanResetInheritance = canResetInheritance,
                HasOffices = _dbContext.Set<InprotechKaizen.Model.Cases.Office>().Any(),
                PtaDelay = validEvent.PtaDelay == null ? PtaDelayMode.NotApplicable : (PtaDelayMode) validEvent.PtaDelay,
                Overview = new EventControlOverview
                {
                    BaseDescription = model.BaseDescription,

                    ImportanceLevelOptions = await GetImportanceLevels(culture),

                    Data = new EventControlOverview.EventControlOverviewData
                    {
                        Description = validEvent.Description,
                        MaxCycles = validEvent.NumberOfCyclesAllowed,
                        Notes = validEvent.Notes,
                        ImportanceLevel = validEvent.ImportanceLevel,
                        NameType = validEvent.DueDateRespNameType == null
                            ? null
                            : new
                            {
                                Key = validEvent.DueDateRespNameType.Id,
                                Code = validEvent.DueDateRespNameType.NameTypeCode,
                                Value = validEvent.DueDateRespNameType.Name
                            },
                        Name = validEvent.Name == null
                            ? null
                            : new
                            {
                                Key = validEvent.Name.Id,
                                Code = validEvent.Name.NameCode,
                                DisplayName = validEvent.Name.Formatted()
                            },
                        DueDateRespType = dueDateRespType
                    }
                },
                StandingInstruction = new EventControlStandingInstruction
                {
                    InstructionType = PicklistInstructionType(validEvent.RequiredCharacteristic?.InstructionType),
                    CharacteristicsOptions = await GetCharacteristicOptions(validEvent.InstructionType, culture),
                    RequiredCharacteristic = validEvent.FlagNumber,
                    Instructions = await GetUsedInInstructions(validEvent.FlagNumber)
                },
                DatesLogicComparisonType = validEvent.DatesLogicComparisonType.ToString(),
                DueDateCalcSettings = new EventControlDueDateCalcSettings
                {
                    DateToUse = validEvent.DateToUse,
                    IsSaveDueDate = validEvent.IsSaveDueDate,
                    ExtendDueDate = validEvent.ExtendDueDate,
                    ExtendDueDateOptions = new DropDownGroup<short?>(validEvent.ExtendPeriod, validEvent.ExtendPeriodType),
                    RecalcEventDate = validEvent.RecalcEventDate,
                    DoNotCalculateDueDate = validEvent.SuppressDueDateCalculation,
                    DateAdjustmentOptions = await GetDateAdjustmentOptionsForDueDateCalc(culture)
                },
                DesignatedJurisdictions = await GetDesignatedJurisdictions(criteria, validEvent, culture),
                SyncedEventSettings = new SyncedEventSettings
                {
                    CaseOption = validEvent.SyncedFromCaseOption.ToString(),
                    UseCycle = validEvent.UseCycle.ToString(),
                    FromEvent = PicklistModelHelper.GetPicklistOrNull(validEvent.SyncedEventId, validEvent.SyncedEvent?.Description),
                    FromRelationship = PicklistModelHelper.GetPicklistOrNull(validEvent.SyncedCaseRelationshipId, validEvent.SyncedCaseRelationship?.Description),
                    LoadNumberType = PicklistModelHelper.GetPicklistOrNull(validEvent.SyncedNumberTypeId, validEvent.SyncedNumberType?.Name),
                    DateAdjustment = validEvent.SyncedEventDateAdjustmentId,
                    DateAdjustmentOptions = await GetDateAdjustmentOptions(culture)
                },
                Charges = new Charges
                {
                    ChargeOne = new Charge
                    {
                        IsPayFee = validEvent.IsPayFee,
                        IsRaiseCharge = validEvent.IsRaiseCharge,
                        IsEstimate = validEvent.IsEstimate,
                        IsDirectPay = validEvent.IsDirectPay ?? false,
                        ChargeType = validEvent.InitialFee == null
                            ? null
                            : new
                            {
                                Key = validEvent.InitialFee.Id,
                                Value = model.ChargeOneDescription
                            }
                    },
                    ChargeTwo = new Charge
                    {
                        IsPayFee = validEvent.IsPayFee2,
                        IsRaiseCharge = validEvent.IsRaiseCharge2,
                        IsEstimate = validEvent.IsEstimate2,
                        IsDirectPay = validEvent.IsDirectPay2 ?? false,
                        ChargeType = validEvent.InitialFee2 == null
                            ? null
                            : new
                            {
                                Key = validEvent.InitialFee2.Id,
                                Value = model.ChargeTwoDescription
                            }
                    }
                },
                ChangeStatus = caseStatus,
                ChangeRenewalStatus = renewalStatus,
                UserDefinedStatus = model.UserDefinedStatusDescription,
                NameChangeSettings = new NameChangeSettings
                {
                    ChangeNameType = PicklistModelHelper.GetPicklistOrNull(validEvent.ChangeNameType?.Id, validEvent.ChangeNameTypeCode, model.ChangeNameTypeDescription),
                    CopyFromNameType = PicklistModelHelper.GetPicklistOrNull(validEvent.CopyFromNameType?.Id, validEvent.CopyFromNameTypeCode, model.CopyFromNameTypeDescription),
                    DeleteCopyFromName = validEvent.DeleteCopyFromName.GetValueOrDefault(),
                    MoveOldNameToNameType = PicklistModelHelper.GetPicklistOrNull(validEvent.MoveOldNameToNameType?.Id, validEvent.MoveOldNameToNameTypeCode, model.MoveOldNameToNameTypeDescription),
                },
                ChangeAction = new ChangeAction
                {
                    OpenAction = new KeyValuePair<string, string>(validEvent.OpenActionId, model.OpenActionDescription),
                    CloseAction = new KeyValuePair<string, string>(validEvent.CloseActionId, model.CloseActionDescription),
                    RelativeCycle = validEvent.RelativeCycle
                },
                Report = validEvent.IsThirdPartyOn == true ? ReportMode.On : validEvent.IsThirdPartyOff == true ? ReportMode.Off : ReportMode.NoChange,
                Characteristics = criteriaModel.Characteristics,
                CanAddValidCombinations = _taskSecurity.HasAccessTo(ApplicationTask.MaintainValidCombinations, ApplicationTaskAccessLevel.Execute),
                EventOccurrence = new EventOccurrence
                {
                    DueDateOccurs = dueDateOccurs,
                    Characteristics = validCharacteristics,
                    MatchOffice = validEvent.OfficeIsThisCase.GetValueOrDefault(),
                    MatchJurisdiction = validEvent.CountryCodeIsThisCase.GetValueOrDefault(),
                    MatchPropertyType = validEvent.PropertyTypeIsThisCase.GetValueOrDefault(),
                    MatchCaseCategory = validEvent.CaseCategoryIsThisCase.GetValueOrDefault(),
                    MatchSubType = validEvent.SubTypeIsThisCase.GetValueOrDefault(),
                    MatchBasis = validEvent.BasisIsThisCase.GetValueOrDefault(),
                    EventsExist = eventsExist
                }
            };
        }

        internal async Task<IEnumerable<KeyValuePair<string, string>>> GetImportanceLevels(string culture)
        {
            var importance = await _dbContext.Set<Importance>()
                                             .Select(_ => new
                                             {
                                                 _.Level,
                                                 Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                             })
                                             .OrderBy(_ => _.Level)
                                             .ToArrayAsync();

            return importance.Select(_ => new KeyValuePair<string, string>(_.Level, _.Description));
        }

        public async Task<IEnumerable<string>> GetUsedInInstructions(short? characteristicId)
        {
            return await _dbContext.Set<SelectedCharacteristic>()
                                   .Where(_ => _.CharacteristicId == characteristicId)
                                   .Select(_ => _.Instruction.Description)
                                   .ToArrayAsync();
        }

        public Task<IEnumerable<KeyValuePair<short, string>>> GetCharacteristicOptions(string instructionTypeCode)
        {
            var culture = _preferredCultureResolver.Resolve();

            return GetCharacteristicOptions(instructionTypeCode, culture);
        }

        internal async Task<IEnumerable<KeyValuePair<short, string>>> GetCharacteristicOptions(string instructionType, string culture)
        {
            var characteristics = await _dbContext.Set<InprotechKaizen.Model.StandingInstructions.Characteristic>()
                                                  .Where(_ => _.InstructionTypeCode == instructionType)
                                                  .Select(_ => new
                                                  {
                                                      _.Id,
                                                      Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
                                                  })
                                                  .ToArrayAsync();

            return characteristics.Select(_ => new KeyValuePair<short, string>(_.Id, _.Description));
        }

        internal async Task<IEnumerable<KeyValuePair<string, string>>> GetDateAdjustmentOptions(string culture)
        {
            var adjustments = await _dbContext.Set<DateAdjustment>()
                                              .Where(_ => !_.Id.StartsWith("~"))
                                              .ToArrayAsync();

            var sorted = adjustments.SortForPickList().Select(_ => new
            {
                _.Id,
                Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
            });

            return sorted.Select(_ => new KeyValuePair<string, string>(_.Id, _.Description));
        }

        internal async Task<IEnumerable<KeyValuePair<string, string>>> GetDateAdjustmentOptionsForDueDateCalc(string culture)
        {
            var adjustments = await _dbContext.Set<DateAdjustment>()
                                              .Where(_ => !new[] {"~1", "~2", "~3", "~4", "~5", "~6", "~7", "~8"}.Contains(_.Id))
                                              .ToArrayAsync();

            var sorted = adjustments.SortForPickList().Select(_ => new
            {
                _.Id,
                Description = DbFuncs.GetTranslation(_.Description, null, _.DescriptionTId, culture)
            });

            return sorted.Select(_ => new KeyValuePair<string, string>(_.Id, _.Description));
        }

        internal Picklists.InstructionType PicklistInstructionType(InstructionType instructionType)
        {
            return instructionType == null ? null : new Picklists.InstructionType {Key = instructionType.Id, Code = instructionType.Code, Value = instructionType.Description};
        }

        internal async Task<EventControlDesignatedJurisdictions> GetDesignatedJurisdictions(Criteria criteria, ValidEvent validEvent, string culture)
        {
            if (criteria.Country != null && criteria.Country.IsGroup)
            {
                var countryFlags = await _dbContext.Set<CountryFlag>()
                                                   .Where(_ => _.CountryId == criteria.CountryId)
                                                   .Select(_ => new
                                                   {
                                                       _.FlagNumber,
                                                       Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture)
                                                   })
                                                   .ToArrayAsync();

                return new EventControlDesignatedJurisdictions
                {
                    CountryFlagForStopReminders = validEvent.CheckCountryFlag,
                    CountryFlags = countryFlags.Select(_ => new KeyValuePair<int, string>(_.FlagNumber, _.Name))
                };
            }

            return null;
        }

        public void UpdateEventControl(ValidEvent eventControl, WorkflowEventControlSaveModel allNewValues, EventControlFieldsToUpdate fieldsToUpdate = null)
        {
            fieldsToUpdate = fieldsToUpdate ?? _workflowEventInheritanceService.GenerateEventControlFieldsToUpdate(allNewValues);
            var children = _inheritance.GetChildren(eventControl.CriteriaId);
            foreach (var child in children)
            {
                var childEvent = child.ValidEvents.SingleOrDefault(_ => _.EventId == eventControl.EventId && _.Inherited == 1);
                if (childEvent == null) continue;

                if (allNewValues.ApplyToDescendants)
                {
                    var childFieldsToUpdate = fieldsToUpdate.Clone();
                    _workflowEventInheritanceService.SetInheritedFieldsToUpdate(childEvent, eventControl, childFieldsToUpdate, allNewValues);

                    foreach (var m in _maintainableSections)
                    {
                        m.SetChildInheritanceDelta(childEvent, allNewValues, childFieldsToUpdate);
                    }

                    UpdateEventControl(childEvent, allNewValues, childFieldsToUpdate);
                }
                else
                {
                    foreach (var m in _maintainableSections)
                    {
                        m.RemoveInheritance(childEvent, fieldsToUpdate);
                    }
                }
            }

            ApplyChanges(eventControl, allNewValues, fieldsToUpdate, children);
        }

        public virtual void ApplyChanges(ValidEvent eventControl, WorkflowEventControlSaveModel allNewValues, EventControlFieldsToUpdate fieldsToUpdate, Criteria[] children)
        {
            // DueDateResp Name and NameType both have to be inherited from parent to update case events
            var shouldUpdateFieldDueDateResp = fieldsToUpdate.DueDateRespNameId && fieldsToUpdate.DueDateRespNameTypeCode;
            if (allNewValues.ChangeRespOnDueDates && shouldUpdateFieldDueDateResp)
            {
                UpdateDueDatesResponsibilityOnCaseEvents(eventControl.CriteriaId, eventControl.EventId, allNewValues);
            }

            foreach (var m in _maintainableSections)
            {
                m.ApplyChanges(eventControl, allNewValues, fieldsToUpdate);
            }

            SetUpdatedValuesForEvent(eventControl, allNewValues, fieldsToUpdate);

            ResetDefaults(eventControl);
        }

        static void ResetDefaults(ValidEvent eventControl)
        {
            if (!eventControl.DueDateCalcs.Any(_ => _.IsDateComparison))
                eventControl.DatesLogicComparisonType = DatesLogicComparisonType.Any;
        }

        public virtual void SetUpdatedValuesForEvent(ValidEvent @event, ValidEvent newEventValues, EventControlFieldsToUpdate eventControlFieldsToUpdate)
        {
            foreach (var propToUpdate in typeof(EventControlFieldsToUpdate).GetProperties().Where(_ => _.PropertyType == typeof(bool)))
            {
                if ((bool) propToUpdate.GetValue(eventControlFieldsToUpdate))
                {
                    // get valid event prop from propToUpdate prop name
                    var validEventProp = typeof(ValidEvent).GetProperty(propToUpdate.Name);

                    // set value for property of validEvent from newEventValues
                    var newValue = validEventProp.GetValue(newEventValues);
                    validEventProp.SetValue(@event, newValue);
                }
            }
        }

        public virtual IQueryable<CaseEvent> GetDueDatesForEventControl(int criteriaId, int eventId)
        {
            var caseEventsForCriteria = from openAction in _dbContext.Set<OpenAction>()
                                        where openAction.CriteriaId == criteriaId && openAction.PoliceEvents == 1
                                        join caseEvent in _dbContext.Set<CaseEvent>()
                                            on openAction.CaseId equals caseEvent.CaseId
                                        where caseEvent.EventNo == eventId &&
                                              (caseEvent.Event.ControllingAction == null
                                                  ? caseEvent.CreatedByCriteriaKey == criteriaId
                                                  : caseEvent.Event.ControllingAction == openAction.ActionId)
                                        select caseEvent;

            return caseEventsForCriteria;
        }

        public virtual void UpdateDueDatesResponsibilityOnCaseEvents(int criteriaId, int eventId, WorkflowEventControlSaveModel saveModel)
        {
            var caseEvents = GetDueDatesForEventControl(criteriaId, eventId);

            if (saveModel.DueDateRespType == DueDateRespTypes.Name)
            {
                UpdateNameResponsibility(saveModel.DueDateRespNameId, caseEvents);
            }
            else if (saveModel.DueDateRespType == DueDateRespTypes.NameType)
            {
                UpdateNameTypeResponsibility(saveModel.DueDateRespNameTypeCode, caseEvents);
            }
            else
            {
                ClearResponsibility(caseEvents);
            }
        }

#pragma warning disable 618

        internal void ClearResponsibility(IQueryable<CaseEvent> caseEvents)
        {
            _dbContext.Update(caseEvents, _ => new CaseEvent
            {
                EmployeeNo = null,
                DueDateResponsibilityNameType = null
            });
        }

        internal void UpdateNameResponsibility(int? dueDateRespNameId, IQueryable<CaseEvent> caseEvents)
        {
            _dbContext.Update(caseEvents.WhereNotOccurred(), _ => new CaseEvent
            {
                EmployeeNo = dueDateRespNameId,
                DueDateResponsibilityNameType = null
            });
        }

#pragma warning restore 618

        internal void UpdateNameTypeResponsibility(string dueDateRespNameTypeCode, IQueryable<CaseEvent> caseEvents)
        {
            var caseNames = from cn in _dbContext.Set<CaseName>()
                            where cn.NameTypeId == dueDateRespNameTypeCode && (cn.ExpiryDate == null || cn.ExpiryDate > DateTime.Now)
                            group cn by cn.CaseId
                            into g
                            select g.OrderBy(_ => _.Sequence).FirstOrDefault();

            var caseEventsCaseNames = from ce in caseEvents.WhereNotOccurred()
                                      join cn in caseNames
                                          on ce.CaseId equals cn.CaseId into cnce
                                      from cn in cnce.DefaultIfEmpty()
                                      select new {CaseEvent = ce, CaseName = cn};

            foreach (var model in caseEventsCaseNames.ToList())
            {
                model.CaseEvent.EmployeeNo = model.CaseName?.NameId;
                model.CaseEvent.DueDateResponsibilityNameType = model.CaseName == null ? dueDateRespNameTypeCode : null;
            }
        }

        public void NormaliseSaveModel(WorkflowEventControlSaveModel saveModel)
        {
            NormaliseDueDateResponsible(saveModel);
            NormaliseLoadEvent(saveModel);
            NormaliseNameChange(saveModel);
            NormaliseRelatedEvents(saveModel);
            NormaliseDocuments(saveModel);
            NormaliseCharges(saveModel);
        }

        internal static void NormaliseDueDateResponsible(WorkflowEventControlSaveModel formData)
        {
            if (formData.DueDateRespType == DueDateRespTypes.Name)
            {
                formData.DueDateRespNameTypeCode = null;
                formData.DueDateRespNameId = formData.DueDateRespNameId;
            }
            else if (formData.DueDateRespType == DueDateRespTypes.NameType)
            {
                formData.DueDateRespNameTypeCode = formData.DueDateRespNameTypeCode;
                formData.DueDateRespNameId = null;
            }
            else
            {
                formData.DueDateRespNameTypeCode = null;
                formData.DueDateRespNameId = null;
            }
        }

        internal static void NormaliseLoadEvent(WorkflowEventControlSaveModel formData)
        {
            if (formData.CaseOption == SyncedFromCaseOption.NotApplicable)
            {
                formData.FromEvent = null;
                formData.DateAdjustment = null;
                formData.FromRelationship = null;
                formData.LoadNumberType = null;
                formData.UseReceivingCycle = null;
            }
            else if (formData.CaseOption == SyncedFromCaseOption.SameCase)
            {
                formData.FromRelationship = null;
                formData.LoadNumberType = null;
                formData.UseReceivingCycle = null;
            }
        }

        internal static void NormaliseNameChange(WorkflowEventControlSaveModel formData)
        {
            if (!string.IsNullOrEmpty(formData.ChangeNameTypeCode) && !string.IsNullOrEmpty(formData.CopyFromNameTypeCode)) return;
            formData.ChangeNameTypeCode = null;
            formData.CopyFromNameTypeCode = null;
            formData.DeleteCopyFromName = null;
            formData.MoveOldNameToNameTypeCode = null;
        }

        internal static void NormaliseRelatedEvents(WorkflowEventControlSaveModel formData)
        {
            foreach (var s in formData.SatisfyingEventsDelta.AllDeltas())
            {
                s.IsSatisfyingEvent = true;
            }

            foreach (var s in formData.EventsToUpdateDelta.AllDeltas())
            {
                s.IsUpdateEvent = true;
            }
        }

        internal static void NormaliseDocuments(WorkflowEventControlSaveModel formData)
        {
            foreach (var s in formData.DocumentDelta.AllDeltas())
            {
                if (s.UpdateEvent != null)
                {
                    s.LeadTime = null;
                    s.PeriodType = null;
                    s.Frequency = null;
                    s.FreqPeriodType = null;
                    s.StopTime = null;
                    s.StopTimePeriodType = null;
                    s.MaxLetters = null;
                }
                else
                {
                    if (s.Frequency == 0)
                    {
                        s.StopTime = null;
                        s.StopTimePeriod = null;
                        s.MaxLetters = null;
                    }
                }

                if (s.LetterFeeId == null)
                {
                    s.PayFeeCode = null;
                    s.EstimateFlag = null;
                    s.DirectPayFlag = null;
                }
            }
        }

        internal static void NormaliseCharges(WorkflowEventControlSaveModel saveModel)
        {
            if (saveModel.InitialFeeId == null)
            {
                saveModel.IsPayFee = false;
                saveModel.IsRaiseCharge = false;
                saveModel.IsEstimate = false;
                saveModel.IsDirectPay = false;
            }
            else if (!saveModel.IsRaiseCharge && saveModel.IsPayFee && saveModel.IsEstimate)
            {
                saveModel.IsEstimate = false;
            }
            else if (saveModel.IsDirectPay.GetValueOrDefault())
            {
                saveModel.IsPayFee = false;
                saveModel.IsRaiseCharge = false;
                saveModel.IsEstimate = false;
            }

            if (saveModel.InitialFee2Id == null)
            {
                saveModel.IsPayFee2 = false;
                saveModel.IsRaiseCharge2 = false;
                saveModel.IsEstimate2 = false;
                saveModel.IsDirectPay2 = false;
            }
            else if (!saveModel.IsRaiseCharge2 && saveModel.IsPayFee2 && saveModel.IsEstimate2)
            {
                saveModel.IsEstimate2 = false;
            }
            else if (saveModel.IsDirectPay2.GetValueOrDefault())
            {
                saveModel.IsPayFee2 = false;
                saveModel.IsRaiseCharge2 = false;
                saveModel.IsEstimate2 = false;
            }
        }

        public IEnumerable<ValidationError> ValidateSaveModel(WorkflowEventControlSaveModel saveModel)
        {
            var errors = new List<ValidationError>();

            errors.AddRange(ValidateOverview(saveModel));
            errors.AddRange(ValidateStatusChanges(saveModel));

            foreach (var m in _maintainableSections)
            {
                errors.AddRange(m.Validate(saveModel));
            }

            return errors;
        }

        IEnumerable<ValidationError> ValidateOverview(WorkflowEventControlSaveModel model)
        {
            if (model.NumberOfCyclesAllowed.HasValue)
            {
                if (model.DueDateCalcDelta.Added.Any(x => x.Cycle > model.NumberOfCyclesAllowed) ||
                    model.DueDateCalcDelta.Updated.Any(x => x.Cycle > model.NumberOfCyclesAllowed))
                {
                    yield return ValidationErrors.TopicError("overview", "Trying to save DueDate with Cycle > NumberOfCyclesAllowed.");
                }
            }

            var exclude = model.DueDateCalcDelta.Deleted.Select(x => x.Sequence)
                               .Union(model.DueDateCalcDelta.Updated.Select(x => x.Sequence));

            if (_dbContext.Set<DueDateCalc>().Any(x => x.EventId == model.EventId && x.CriteriaId == model.CriteriaId &&
                                                       !exclude.Contains(x.Sequence) &&
                                                       x.Cycle > model.NumberOfCyclesAllowed))
            {
                yield return ValidationErrors.TopicError("overview", "Some DueDate calcs already have Cycle > NumberOfCyclesAllowed.");
            }
        }

        IEnumerable<ValidationError> ValidateStatusChanges(WorkflowEventControlSaveModel model)
        {
            var criteria = _dbContext.Set<Criteria>().SingleOrDefault(_ => _.Id == model.OriginatingCriteriaId);

            if (!string.IsNullOrEmpty(criteria?.PropertyTypeId) && !string.IsNullOrEmpty(criteria.CaseTypeId))
            {
                var validStatuses = _dbContext.Set<ValidStatus>().Include(_ => _.Status).Where(_ => _.PropertyTypeId == criteria.PropertyTypeId && _.CaseTypeId == criteria.CaseTypeId && (_.CountryId == criteria.CountryId || _.CountryId == "ZZZ")).ToArray();
                var validStatusWithCountry = validStatuses.Where(_ => _.CountryId == criteria.CountryId).ToArray();
                var validStatusZzz = validStatuses.Where(_ => _.CountryId == InprotechKaizen.Model.KnownValues.DefaultCountryCode).ToArray();

                if (validStatusWithCountry.Any())
                {
                    // If there is no change renewal status, we might be pre-Inprotech 12.1 which allows renewal statuses in the change status field
                    var validCaseStatuses = validStatusWithCountry.Where(_ => model.ChangeRenewalStatusId == null || !_.Status.IsRenewal).Select(_ => _.StatusCode).ToArray();
                    if (model.ChangeStatusId.HasValue && validCaseStatuses.Any() && !validCaseStatuses.Contains(model.ChangeStatusId.Value))
                        yield return ValidationErrors.TopicError("changeStatus", $"Change Status {model.ChangeStatusId} is not a Valid Status. Add a Valid Status with Country {criteria.CountryId}, PropertyType {criteria.PropertyTypeId}, CaseType {criteria.CaseTypeId}.");

                    var validRenewalStatuses = validStatusWithCountry.Where(_ => _.Status.IsRenewal).Select(_ => _.StatusCode).ToArray();
                    if (model.ChangeRenewalStatusId.HasValue && validRenewalStatuses.Any() && !validRenewalStatuses.Contains(model.ChangeRenewalStatusId.Value))
                        yield return ValidationErrors.TopicError("changeStatus", $"Change Renewal Status {model.ChangeRenewalStatusId} is not a Valid Status. Add a Valid Status with Country {criteria.CountryId}, PropertyType {criteria.PropertyTypeId}, CaseType {criteria.CaseTypeId}.");
                }
                else if (validStatusZzz.Any())
                {
                    // If there is no change renewal status, we might be pre-Inprotech 12.1 which allows renewal statuses in the change status field
                    var validCaseStatuses = validStatusZzz.Where(_ => model.ChangeRenewalStatusId == null || !_.Status.IsRenewal).Select(_ => _.StatusCode).ToArray();
                    if (model.ChangeStatusId.HasValue && validCaseStatuses.Any() && !validCaseStatuses.Contains(model.ChangeStatusId.Value))
                        yield return ValidationErrors.TopicError("changeStatus", $"Change Status {model.ChangeStatusId} is not a Valid Status. Add a Valid Status with Default Country ZZZ, PropertyType {criteria.PropertyTypeId}, CaseType {criteria.CaseTypeId}.");

                    var validRenewalStatuses = validStatusZzz.Where(_ => _.Status.IsRenewal).Select(_ => _.StatusCode).ToArray();
                    if (model.ChangeRenewalStatusId.HasValue && validRenewalStatuses.Any() && !validRenewalStatuses.Contains(model.ChangeRenewalStatusId.Value))
                        yield return ValidationErrors.TopicError("changeStatus", $"Change Renewal Status {model.ChangeRenewalStatusId} is not a Valid Status. Add a Valid Status with Default Country ZZZ, PropertyType {criteria.PropertyTypeId}, CaseType {criteria.CaseTypeId}.");
                }
            }

            if (model.ChangeRenewalStatusId == null) yield break;
            var renewalStatus = _dbContext.Set<InprotechKaizen.Model.Cases.Status>().Single(_ => _.Id == model.ChangeRenewalStatusId);
            if (!renewalStatus.IsRenewal)
                yield return ValidationErrors.TopicError("changeStatus", "Change Renewal Status invalid. Status must be set to a Renewal Status.");

            if (model.ChangeStatusId == null) yield break;
            var status = _dbContext.Set<InprotechKaizen.Model.Cases.Status>().Single(_ => _.Id == model.ChangeStatusId);
            if (status.IsRenewal)
                yield return ValidationErrors.TopicError("changeStatus", "Change Status invalid. Status cannot be a Renewal Status.");
        }

        public void SetOriginalHashes(ValidEvent validEvent, WorkflowEventControlSaveModel formData)
        {
            SetOriginalDueDateCalcHashes(validEvent.DueDateCalcs, formData.DueDateCalcDelta);
            SetOriginalNameTypeMapHashes(validEvent.NameTypeMaps, formData.NameTypeMapDelta);
            SetOriginalDateComparisonHashes(validEvent.DueDateCalcs, formData.DateComparisonDelta);
            SetOriginalRelatedEventHashes(validEvent.RelatedEvents.WhereIsSatisfyingEvent(), formData.SatisfyingEventsDelta);
            SetOriginalRelatedEventHashes(validEvent.RelatedEvents.WhereEventsToClear(), formData.EventsToClearDelta);
            SetOriginalRelatedEventHashes(validEvent.RelatedEvents.WhereEventsToUpdate(), formData.EventsToUpdateDelta);
            SetOriginalReminderRuleHashes(validEvent.Reminders.WhereReminder(), formData.ReminderRuleDelta);
            SetOriginalReminderRuleHashes(validEvent.Reminders.WhereDocument(), formData.DocumentDelta);
            SetOriginalDatesLogicHashes(validEvent.DatesLogic, formData.DatesLogicDelta);
        }

        public string ResetEventControl(int criteriaId, int eventId, bool applyToDescendents, bool? updateRespNameOnCases = null)
        {
            var inherits = _dbContext.Set<Inherits>().Single(_ => _.CriteriaNo == criteriaId);
            var parentValidEvent = inherits.FromCriteria.ValidEvents.Single(_ => _.EventId == eventId);
            var validEvent = inherits.Criteria.ValidEvents.Single(_ => _.EventId == eventId);

            if (updateRespNameOnCases == null &&
                CheckDueDateRespNameChange(parentValidEvent, validEvent))
            {
                // go ask the user if they want to update due dates on cases
                return "updateNameRespOnCases";
            }

            var allNewValues = new WorkflowEventControlSaveModel {OriginatingCriteriaId = criteriaId, ApplyToDescendants = applyToDescendents, ResetInheritance = true};
            allNewValues.InheritRulesFrom(parentValidEvent);
            allNewValues.ChangeRespOnDueDates = updateRespNameOnCases.GetValueOrDefault();
            if (allNewValues.ChangeRespOnDueDates)
            {
                if (!string.IsNullOrEmpty(allNewValues.DueDateRespNameTypeCode))
                    allNewValues.DueDateRespType = DueDateRespTypes.NameType;
                else if (allNewValues.DueDateRespNameId != null)
                    allNewValues.DueDateRespType = DueDateRespTypes.Name;
                else
                    allNewValues.DueDateRespType = DueDateRespTypes.NotApplicable;
            }

            foreach (var s in _maintainableSections)
            {
                s.Reset(allNewValues, parentValidEvent, validEvent);
            }

            UpdateEventControl(validEvent, allNewValues);

            validEvent.IsInherited = true;

            _dbContext.SaveChanges();

            return "success";
        }

        public bool CheckDueDateRespNameChange(ValidEvent parent, ValidEvent child)
        {
            return (parent.DueDateRespNameTypeCode != child.DueDateRespNameTypeCode ||
                    parent.DueDateRespNameId != child.DueDateRespNameId)
                   && GetDueDatesForEventControl(child.CriteriaId, child.EventId).WhereNotOccurred().Any();
        }

        void SetOriginalDueDateCalcHashes(IEnumerable<DueDateCalc> existingDueDateCalcs, Delta<DueDateCalcSaveModel> dueDateCalcDelta)
        {
            foreach (var d in dueDateCalcDelta.Deleted.Union(dueDateCalcDelta.Updated))
            {
                d.OriginalHashKey = existingDueDateCalcs.Single(_ => _.Sequence == d.Sequence).HashKey();
            }
        }

        void SetOriginalNameTypeMapHashes(IEnumerable<NameTypeMap> existingNameTypeMaps, Delta<NameTypeMapSaveModel> nameTypeMapDelta)
        {
            foreach (var d in nameTypeMapDelta.Deleted.Union(nameTypeMapDelta.Updated))
            {
                d.OriginalHashKey = existingNameTypeMaps.Single(_ => _.Sequence == d.Sequence).HashKey();
            }
        }

        void SetOriginalDateComparisonHashes(IEnumerable<DueDateCalc> existingDueDateCalcs, Delta<DateComparisonSaveModel> dateComparisonDelta)
        {
            foreach (var d in dateComparisonDelta.Deleted.Union(dateComparisonDelta.Updated))
            {
                d.OriginalHashKey = existingDueDateCalcs.Single(_ => _.Sequence == d.Sequence).HashKey();
            }
        }

        void SetOriginalRelatedEventHashes(IEnumerable<RelatedEventRule> existingRelatedEvents, Delta<RelatedEventRuleSaveModel> relatedEventDelta)
        {
            foreach (var s in relatedEventDelta.Deleted.Union(relatedEventDelta.Updated))
            {
                var existingRelatedEvent = existingRelatedEvents.Single(_ => _.Sequence == s.Sequence);
                s.OriginalHashKey = existingRelatedEvent.HashKey();
                s.OriginalRelatedEventId = existingRelatedEvent.RelatedEventId.Value;
                s.OriginalRelatedCycleId = existingRelatedEvent.RelativeCycleId.Value;
            }

            foreach (var r in relatedEventDelta.Added)
            {
                r.OriginalRelatedEventId = r.RelatedEventId.Value;
                r.OriginalRelatedCycleId = r.RelativeCycleId.Value;
            }
        }

        void SetOriginalReminderRuleHashes(IEnumerable<ReminderRule> existingReminderRules, Delta<ReminderRuleSaveModel> reminderRuleDelta)
        {
            foreach (var s in reminderRuleDelta.Deleted.Union(reminderRuleDelta.Updated))
            {
                var existingReminderRule = existingReminderRules.Single(_ => _.Sequence == s.Sequence);
                s.OriginalHashKey = existingReminderRule.HashKey();
            }
        }

        void SetOriginalDatesLogicHashes(IEnumerable<DatesLogic> existingDatesLogic, Delta<DatesLogicSaveModel> datesLogicDelta)
        {
            foreach (var d in datesLogicDelta.Deleted.Union(datesLogicDelta.Updated))
            {
                d.OriginalHashKey = existingDatesLogic.Single(_ => _.Sequence == d.Sequence).HashKey();
            }
        }
    }

    class InheritablePicklistModel : PicklistModel<int>
    {
        public InheritablePicklistModel(int key, string code, string value, bool isInherited) : base(key, code, value)
        {
            IsInherited = isInherited;
        }

        public bool IsInherited { get; set; }
    }
}
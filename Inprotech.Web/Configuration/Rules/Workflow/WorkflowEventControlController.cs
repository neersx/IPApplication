using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;

namespace Inprotech.Web.Configuration.Rules.Workflow
{
    [Authorize]
    [NoEnrichment]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRules)]
    [RequiresAccessTo(ApplicationTask.MaintainWorkflowRulesProtected)]
    [RoutePrefix("api/configuration/rules/workflows")]
    public class WorkflowEventControlController : ApiController
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IWorkflowEventControlService _workflowEventControlService;
        readonly IWorkflowPermissionHelper _workflowPermissionHelper;
        readonly IWorkflowEventInheritanceService _workflowEventInheritanceService;

        public WorkflowEventControlController(IDbContext dbContext, IWorkflowEventControlService workflowEventControlService,
                                              IPreferredCultureResolver preferredCultureResolver, IWorkflowPermissionHelper workflowPermissionHelper, IWorkflowEventInheritanceService workflowEventInheritanceService)
        {
            _dbContext = dbContext;
            _workflowEventControlService = workflowEventControlService;
            _preferredCultureResolver = preferredCultureResolver;
            _workflowPermissionHelper = workflowPermissionHelper;
            _workflowEventInheritanceService = workflowEventInheritanceService;
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}")]
        public async Task<WorkflowEventControlModel> GetEventControl(int criteriaId, int eventId)
        {
            return await _workflowEventControlService.GetEventControl(criteriaId, eventId);
        }

        [HttpPut]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic UpdateEventControl(int criteriaId, int eventId, WorkflowEventControlSaveModel formData)
        {
            if (string.IsNullOrWhiteSpace(formData.Description)) throw new ArgumentNullException("description");
            if (formData.NumberOfCyclesAllowed == null || formData.NumberOfCyclesAllowed == 0) throw new ArgumentNullException("maxCycles");
            if (string.IsNullOrWhiteSpace(formData.ImportanceLevel)) throw new ArgumentNullException("importanceLevel");

            formData.EventId = eventId;
            formData.CriteriaId = criteriaId;

            _workflowPermissionHelper.EnsureEditEventControlPermission(criteriaId, eventId);

            formData.OriginatingCriteriaId = criteriaId;

            _workflowEventControlService.NormaliseSaveModel(formData);
            var errors = _workflowEventControlService.ValidateSaveModel(formData).ToArray();
            if (errors.Any())
            {
                return new
                {
                    Status = "error",
                    Errors = errors
                };
            }

            var eventControl = _dbContext.Set<ValidEvent>().Single(_ => _.CriteriaId == criteriaId && _.EventId == eventId);

            _workflowEventControlService.SetOriginalHashes(eventControl, formData);

            _workflowEventControlService.UpdateEventControl(eventControl, formData);

            _dbContext.SaveChanges();

            return new
            {
                Status = "success"
            };
        }

        [HttpPut]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/reset")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic ResetEventControl(int criteriaId, int eventId, bool applyToDescendants, bool? updateRespNameOnCases = null)
        {
            _workflowPermissionHelper.EnsureEditEventControlPermission(criteriaId, eventId);
            var result = _workflowEventControlService.ResetEventControl(criteriaId, eventId, applyToDescendants, updateRespNameOnCases);
            return new
            {
                Status = result
            };
        }

        [HttpPut]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/break")]
        [AppliesToComponent(KnownComponents.WorkflowDesigner)]
        public dynamic BreakEventControl(int criteriaId, int eventId)
        {
            _workflowPermissionHelper.EnsureEditEventControlPermission(criteriaId, eventId);
            _workflowEventInheritanceService.BreakEventsInheritance(criteriaId, eventId);
            return new
            {
                Status = "success"
            };
        }

        [HttpGet]
        [Route("{criteriaId:int}/events/{eventId:int}/duedates")]
        public IEnumerable<dynamic> GetDueDateCalcData(int criteriaId, int eventId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var duedatecalcs = _dbContext.Set<DueDateCalc>().Where(_ => _.EventId == eventId && _.CriteriaId == criteriaId).WhereDueDateCalc();
            return duedatecalcs.Select(_ => new
                               {
                                   _.Sequence,
                                   _.Inherited,
                                   _.Cycle,
                                   _.JurisdictionId,
                                   JurisdictionName = _.Jurisdiction == null ? null : DbFuncs.GetTranslation(_.Jurisdiction.Name, null, _.Jurisdiction.NameTId, culture),
                                   FromEventId = _.FromEvent == null ? (int?) null : _.FromEvent.Id,
                                   FromEventName = _.FromEvent == null ? null : DbFuncs.GetTranslation(_.FromEvent.Description, null, _.FromEvent.DescriptionTId, culture),
                                   OverrideLetterName = _.OverrideLetter == null ? null : DbFuncs.GetTranslation(_.OverrideLetter.Name, null, _.OverrideLetter.NameTId, culture),
                                   _.Operator,
                                   _.PeriodType,
                                   _.DeadlinePeriod,
                                   _.EventDateFlag,
                                   _.RelativeCycle,
                                   _.MustExist,
                                   _.Adjustment,
                                   _.Message2Flag,
                                   _.SuppressReminders,
                                   WorkDay = _.Workday,
                                   _.OverrideLetterId
                               })
                               .OrderBy(_ => _.JurisdictionName)
                               .ThenBy(_ => _.Cycle)
                               .ThenBy(_ => _.FromEventName)
                               .ToArray()
                               .Select(_ => new
                               {
                                   _.Sequence,
                                   Inherited = _.Inherited == 1,
                                   MustExist = _.MustExist == 1,
                                   Jurisdiction = PicklistModelHelper.GetPicklistOrNull(_.JurisdictionId, _.JurisdictionId, _.JurisdictionName),
                                   FromEvent = PicklistModelHelper.GetPicklistOrNull(_.FromEventId, _.FromEventName),
                                   Period = new {Type = _.PeriodType, Value = _.DeadlinePeriod},
                                   _.Cycle,
                                   _.Operator,
                                   FromTo = _.EventDateFlag,
                                   _.RelativeCycle,
                                   AdjustBy = _.Adjustment,
                                   ReminderOption = ReminderOptions.DeriveOption(_.Message2Flag, _.SuppressReminders),
                                   NonWorkDay = _.WorkDay,
                                   Document = PicklistModelHelper.GetPicklistOrNull(_.OverrideLetterId, _.OverrideLetterName)
                               });
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/nametypemaps")]
        public IEnumerable<dynamic> GetNameTypeMaps(int criteriaId, int eventId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var nameTypeMaps = _dbContext.Set<NameTypeMap>().Where(_ => _.CriteriaId == criteriaId && _.EventId == eventId)
                                         .Select(_ => new
                                         {
                                             NameTypeMap = _,
                                             NameTypeDescription = DbFuncs.GetTranslation(_.ApplicableNameType.Name, null, _.ApplicableNameType.NameTId, culture),
                                             SuitableNameTypeDescription = DbFuncs.GetTranslation(_.SubstituteNameType.Name, null, _.SubstituteNameType.NameTId, culture)
                                         }).ToArray();

            return nameTypeMaps.Select(_ => new
                               {
                                   _.NameTypeMap.Sequence,
                                   IsInherited = _.NameTypeMap.Inherited,
                                   NameType = PicklistModelHelper.GetPicklistOrNull(_.NameTypeMap.ApplicableNameTypeKey, _.NameTypeMap.ApplicableNameTypeKey,  _.NameTypeDescription),
                                   CaseNameType = PicklistModelHelper.GetPicklistOrNull(_.NameTypeMap.SubstituteNameTypeKey, _.NameTypeMap.SubstituteNameTypeKey, _.SuitableNameTypeDescription),
                                   _.NameTypeMap.MustExist
                               })
                               .OrderBy(_ => _.Sequence);
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/datecomparisons")]
        public IEnumerable<dynamic> GetDateComparisons(int criteriaId, int eventId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var dateComparisons = _dbContext.Set<DueDateCalc>()
                                            .Where(_ => _.CriteriaId == criteriaId && _.EventId == eventId)
                                            .WhereDateComparison()
                                            .Select(_ => new
                                            {
                                                DateComparison = _,
                                                EventADescription = DbFuncs.GetTranslation(_.FromEvent.Description, null, _.FromEvent.DescriptionTId, culture),
                                                EventBDescription = _.CompareEvent == null ? null : DbFuncs.GetTranslation(_.CompareEvent.Description, null, _.CompareEvent.DescriptionTId, culture),
                                                RelationshipDescription = _.CompareRelationship == null ? null : DbFuncs.GetTranslation(_.CompareRelationship.Description, null, _.CompareRelationship.DescriptionTId, culture)
                                            })
                                            .ToArray();

            return dateComparisons.Select(_ => new
                                  {
                                      _.DateComparison.IsInherited,
                                      _.DateComparison.Sequence,
                                      EventA = PicklistModelHelper.GetPicklistOrNull(_.DateComparison.FromEventId, _.EventADescription),
                                      EventADate = ((DueDateCalcExt.DateOption) _.DateComparison.EventDateFlag.GetValueOrDefault(1)).ToString(),
                                      EventARelativeCycle = _.DateComparison.RelativeCycle,
                                      ComparisonOperator = PicklistModelHelper.GetPicklistOrNull(_.DateComparison.Comparison, _.DateComparison.Comparison),
                                      EventB = PicklistModelHelper.GetPicklistOrNull(_.DateComparison.CompareEventId, _.EventBDescription),
                                      EventBDate = _.DateComparison.CompareEventFlag == null ? null : ((DueDateCalcExt.DateOption) _.DateComparison.CompareEventFlag.Value).ToString(),
                                      EventBRelativeCycle = _.DateComparison.CompareCycle,
                                      CompareRelationship = PicklistModelHelper.GetPicklistOrNull(_.DateComparison.CompareRelationshipId, _.RelationshipDescription),
                                      _.DateComparison.CompareDate,
                                      _.DateComparison.CompareSystemDate
                                  })
                                  .OrderBy(_ => _.Sequence);
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/designatedjurisdictions")]
        public IEnumerable<dynamic> GetDesignatedJurisdictions(int criteriaId, int eventId)
        {
            var culture = _preferredCultureResolver.Resolve();

            var criteria = _dbContext.Set<Criteria>().WhereWorkflowCriteria().Single(_ => _.Id == criteriaId);
            var designations = _dbContext.Set<DueDateCalc>().Where(_ => _.CriteriaId == criteria.Id && _.EventId == eventId).WhereDesignatedJurisdiction();

            return designations.Select(_ => new
                               {
                                   Key = _.JurisdictionId,
                                   Value = DbFuncs.GetTranslation(_.Jurisdiction.Name, null, _.Jurisdiction.NameTId, culture),
                                   IsInherited = _.Inherited == 1
                               })
                               .OrderBy(_ => _.Value);
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/satisfyingevents")]
        public IEnumerable<dynamic> GetSatisfyingEvents(int criteriaId, int eventId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var satisfyingEvents = _dbContext.Set<RelatedEventRule>()
                                             .Where(_ => _.CriteriaId == criteriaId && _.EventId == eventId && _.SatisfyEvent == 1)
                                             .Select(_ => new
                                             {
                                                 SatisfyingEvent = _,
                                                 SatisfyingEventDesc = DbFuncs.GetTranslation(_.RelatedEvent.Description, null, _.RelatedEvent.DescriptionTId, culture)
                                             })
                                             .ToArray();

            return satisfyingEvents.Select(_ => new
                                   {
                                       _.SatisfyingEvent.IsInherited,
                                       _.SatisfyingEvent.Sequence,
                                       SatisfyingEvent = PicklistModelHelper.GetPicklistOrNull(_.SatisfyingEvent.RelatedEventId, _.SatisfyingEventDesc),
                                       RelativeCycle = _.SatisfyingEvent.RelativeCycleId
                                   })
                                   .OrderBy(_ => _.Sequence);
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/eventstoupdate")]
        public IEnumerable<dynamic> GetEventsToUpdate(int criteriaId, int eventId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var satisfyingEvents = _dbContext.Set<RelatedEventRule>()
                                             .Where(_ => _.CriteriaId == criteriaId && _.EventId == eventId && _.UpdateEvent == 1)
                                             .Select(_ => new
                                             {
                                                 Event = _,
                                                 AdjustDate = _.DateAdjustment.Id,
                                                 Description = DbFuncs.GetTranslation(_.RelatedEvent.Description, null, _.RelatedEvent.DescriptionTId, culture)
                                             })
                                             .ToArray();

            return satisfyingEvents.Select(_ => new
                                   {
                                       _.Event.IsInherited,
                                       _.Event.Sequence,
                                       EventToUpdate = PicklistModelHelper.GetPicklistOrNull(_.Event.RelatedEventId, _.Description),
                                       RelativeCycle = _.Event.RelativeCycleId,
                                       _.AdjustDate
                                   })
                                   .OrderBy(_ => _.Sequence);
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/dateslogic")]
        public IEnumerable<dynamic> GetDatesLogic(int criteriaId, int eventId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var dl = _dbContext.Set<DatesLogic>()
                               .Where(_ => _.CriteriaId == criteriaId && _.EventId == eventId)
                               .Select(_ => new
                               {
                                   DatesLogic = _,
                                   CompareEvent = DbFuncs.GetTranslation(_.CompareEvent.Description, null, _.CompareEvent.DescriptionTId, culture),
                                   CaseRelationship = _.CaseRelationship == null ? null : DbFuncs.GetTranslation(_.CaseRelationship.Description, null, _.CaseRelationship.DescriptionTId, culture)
                               })
                               .ToArray();

            return dl.Select(_ => new
            {
                _.DatesLogic.IsInherited,
                _.DatesLogic.Sequence,
                AppliesTo = _.DatesLogic.DateType.ToString(),
                Operator = PicklistModelHelper.GetPicklistOrNull(_.DatesLogic.Operator, _.DatesLogic.Operator),
                CompareEvent = PicklistModelHelper.GetPicklistOrNull(_.DatesLogic.CompareEventId, _.CompareEvent),
                CompareType = _.DatesLogic.CompareDateType.ToString(),
                CaseRelationship = PicklistModelHelper.GetPicklistOrNull(_.DatesLogic.CaseRelationshipId, _.CaseRelationship),
                _.DatesLogic.RelativeCycle,
                EventMustExist = _.DatesLogic.MustExist == 1,
                IfRuleFails = _.DatesLogic.DisplayErrorFlag == 1 ? DatesLogicDisplayErrorOptions.Block.ToString() : DatesLogicDisplayErrorOptions.Warn.ToString(),
                FailureMessage = _.DatesLogic.ErrorMessage
            }).OrderBy(_ => _.Sequence);
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/eventstoclear")]
        public IEnumerable<dynamic> GetEventsToClear(int criteriaId, int eventId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var eventsToClear = _dbContext.Set<RelatedEventRule>()
                                          .Where(
                                                 _ => _.CriteriaId == criteriaId && _.EventId == eventId
                                                )
                                          .WhereEventsToClear()
                                          .Select(_ => new
                                          {
                                              EventToClear = _,
                                              Event = _.RelatedEvent == null ? null : DbFuncs.GetTranslation(_.RelatedEvent.Description, null, _.RelatedEvent.DescriptionTId, culture)
                                          })
                                          .ToArray();

            return eventsToClear.Select(_ => new
                                {
                                    _.EventToClear.Sequence,
                                    _.EventToClear.IsInherited,
                                    EventToClear = PicklistModelHelper.GetPicklistOrNull(_.EventToClear.RelatedEventId, _.Event),
                                    RelativeCycle = _.EventToClear.RelativeCycleId,
                                    ClearEventOnEventChange = _.EventToClear.IsClearEvent,
                                    ClearDueDateOnEventChange = _.EventToClear.IsClearDue,
                                    ClearEventOnDueDateChange = _.EventToClear.ClearEventOnDueChange,
                                    ClearDueDateOnDueDateChange = _.EventToClear.ClearDueOnDueChange
                                })
                                .OrderBy(_ => _.Sequence);
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/reminders")]
        public IEnumerable<dynamic> GetReminders(int criteriaId, int eventId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var reminders = _dbContext.Set<ReminderRule>()
                                      .Where(_ => _.CriteriaId == criteriaId && _.EventId == eventId && _.LetterNo == null)
                                      .Select(_ => new
                                      {
                                          ReminderRule = _,
                                          StandardMessage = DbFuncs.GetTranslation(null, _.Message1, _.Message1TId, culture),
                                          AlternateMessage = DbFuncs.GetTranslation(null, _.Message2, _.Message2TId, culture),
                                          NameRelationDescription = _.NameRelation == null ? null : DbFuncs.GetTranslation(null, _.NameRelation.RelationDescription, _.NameRelation.RelationDescriptionTId, culture)
                                      })
                                      .ToArray();

            var distinctNameTypes = reminders.SelectMany(n => n.ReminderRule.NameTypes).Distinct();
            var nameTypes = _dbContext.Set<NameType>()
                                      .Where(n => distinctNameTypes.Contains(n.NameTypeCode))
                                      .Select(_ => new
                                              {
                                                  _.Id,
                                                  _.NameTypeCode,
                                                  Desc = DbFuncs.GetTranslation(null, _.Name, _.NameTId, culture)
                                              }
                                             )
                                      .ToArray();

            return reminders.Select(_ => new
                            {
                                _.ReminderRule.Sequence,
                                _.StandardMessage,
                                _.AlternateMessage,
                                UseOnAndAfterDueDate = _.ReminderRule.UseMessage1 == 1,
                                SendEmail = _.ReminderRule.SendElectronically == 1,
                                _.ReminderRule.EmailSubject,
                                StartBefore = new {Type = _.ReminderRule.PeriodType, Value = _.ReminderRule.LeadTime},
                                RepeatEvery = _.ReminderRule.Frequency == 0 ? null : new {Type = _.ReminderRule.FreqPeriodType ?? _.ReminderRule.PeriodType, Value = _.ReminderRule.Frequency},
                                StopTime = new {Type = _.ReminderRule.StopTimePeriodType, Value = _.ReminderRule.StopTime},
                                SendToStaff = _.ReminderRule.EmployeeFlag == 1,
                                SendToSignatory = _.ReminderRule.SignatoryFlag == 1,
                                SendToCriticalList = _.ReminderRule.CriticalFlag == 1,
                                Name = _.ReminderRule.RemindEmployee == null
                                    ? null
                                    : new
                                    {
                                        Key = _.ReminderRule.RemindEmployeeId,
                                        Code = _.ReminderRule.RemindEmployee?.NameCode,
                                        DisplayName = _.ReminderRule.RemindEmployee?.FormattedNameOrNull()
                                    },
                                NameTypes = nameTypes.Where(nt => _.ReminderRule.NameTypes.Contains(nt.NameTypeCode)).Select(nt => new PicklistModel<string>(nt.Id.ToString(), nt.NameTypeCode, nt.Desc)),
                                Relationship = PicklistModelHelper.GetPicklistOrNull(
                                                                                     _.ReminderRule.RelationshipId,
                                                                                     _.NameRelationDescription
                                                                                    ),
                                _.ReminderRule.IsInherited
                            })
                            .OrderBy(_ => _.Sequence);
        }

        [HttpGet]
        [Route("{criteriaId:int}/eventcontrol/{eventId:int}/documents")]
        public IEnumerable<dynamic> GetDocuments(int criteriaId, int eventId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var documents = _dbContext.Set<ReminderRule>()
                                      .Where(_ => _.CriteriaId == criteriaId && _.EventId == eventId && _.LetterNo != null)
                                      .Select(_ => new
                                      {
                                          Document = _,
                                          DocumentName = DbFuncs.GetTranslation(_.Letter.Name, null, _.Letter.NameTId, culture),
                                          ChargeName = _.LetterFeeId == null ? null : DbFuncs.GetTranslation(_.LetterFee.Description, null, _.LetterFee.DescriptionTId, culture)
                                      })
                                      .ToArray();

            return documents.Select(_ => new
                            {
                                _.Document.Sequence,
                                Document = new PicklistModel<short>(_.Document.LetterNo.Value, _.Document.Letter.Code, _.DocumentName),
                                Produce = _.Document.UpdateEvent == 2 ? ProduceWhenOptions.EventOccurs : _.Document.UpdateEvent == 1 ? ProduceWhenOptions.OnDueDate : ProduceWhenOptions.AsScheduled,

                                StartBefore = (_.Document.LeadTime == 0 || _.Document.PeriodType == null) ? null : new {Type = _.Document.PeriodType, Value = _.Document.LeadTime},
                                RepeatEvery = (_.Document.Frequency == 0 || _.Document.FreqPeriodType == null) ? null : new {Type = _.Document.FreqPeriodType ?? _.Document.PeriodType, Value = _.Document.Frequency},
                                StopTime = new {Type = _.Document.StopTimePeriodType, Value = _.Document.StopTime},
                                MaxDocuments = _.Document.MaxLetters == 0 ? null : _.Document.MaxLetters,

                                ChargeType = PicklistModelHelper.GetPicklistOrNull(_.Document.LetterFeeId, null, _.ChargeName),
                                IsPayFee = (int.Parse(_.Document.PayFeeCode ?? "0") & 1) == 1,
                                IsRaiseCharge = (int.Parse(_.Document.PayFeeCode ?? "0") & 2) == 2,
                                IsEstimate = _.Document.EstimateFlag == 1,
                                IsDirectPay = _.Document.DirectPayFlag == true,
                                IsCheckCycleForSubstitute = _.Document.CheckOverride.GetValueOrDefault() == 1,
                                _.Document.IsInherited
                            })
                            .OrderBy(_ => _.Document.Value);
        }

        [HttpGet]
        [Route("eventcontrol/characteristics/{characteristicId:int}/usedin")]
        public Task<IEnumerable<string>> UsedInInstructions(short characteristicId)
        {
            return _workflowEventControlService.GetUsedInInstructions(characteristicId);
        }

        [HttpGet]
        [Route("eventcontrol/instructiontypes/{instructionTypeCode}/characteristics")]
        public Task<IEnumerable<KeyValuePair<short, string>>> GetCharacteristicOptions(string instructionTypeCode)
        {
            return _workflowEventControlService.GetCharacteristicOptions(instructionTypeCode);
        }
    }
}
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Cases.EventRules.Models;
using InprotechKaizen.Model.Components.Cases.Rules.Visualisation;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace Inprotech.Web.Cases.EventRules
{
    public interface IEventRulesService
    {
        EventRulesModel.EventRulesDetailsModel GetEventRulesDetails(EventRulesModel.EventRulesRequest eventRulesRequest);
    }
    public class EventRulesService : IEventRulesService
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly IDueDateCalculationService _dueDateCalculationService;
        readonly IRemindersService _remindersService;
        readonly IDocumentsService _documentsService;
        readonly IDatesLogicService _datesLogicService;
        readonly IEventUpdateDetailsService _eventUpdateDetailsService;

        public EventRulesService(IDbContext dbContext,
                                 ISecurityContext securityContext,
                                 IPreferredCultureResolver preferredCultureResolver,
                                 IDueDateCalculationService dueDateCalculationService,
                                 IRemindersService remindersService,
                                 IDocumentsService documentsService,
                                 IDatesLogicService datesLogicService,
                                 IEventUpdateDetailsService eventUpdateDetailsService
        )
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _dueDateCalculationService = dueDateCalculationService;
            _remindersService = remindersService;
            _documentsService = documentsService;
            _datesLogicService = datesLogicService;
            _eventUpdateDetailsService = eventUpdateDetailsService;
        }

        public EventRulesModel.EventRulesDetailsModel GetEventRulesDetails(EventRulesModel.EventRulesRequest eventRulesRequest)
        {
            var result = _dbContext.GetEventRuleDetails(_securityContext.User.Id,
                                                        _preferredCultureResolver.Resolve(), eventRulesRequest.CaseId, eventRulesRequest.EventNo, eventRulesRequest.Cycle, eventRulesRequest.Action);

            var ecDetails = result.EventControlDetails;
            return new EventRulesModel.EventRulesDetailsModel
            {
                EventDescription = ecDetails.EventDescription,
                CaseReference = ecDetails.Irn,
                Action = ecDetails.ActionName,
                Notes = ecDetails.Notes,
                EventInformation = new EventRulesModel.EventInformation
                {
                    CriteriaNumber = ecDetails.CriteriaNo,
                    MaximumCycle = ecDetails.NumCyclesAllowed,
                    ByLogin = ecDetails.LoginId,
                    Cycle = eventRulesRequest.Cycle,
                    EventDate = ecDetails.EventDate,
                    EventNumber = ecDetails.EventNo,
                    ImportanceLevel = ecDetails.ImportanceLevel,
                    LastModified = ecDetails.LogDateTimeStamp,
                    From = ecDetails.LogApplication
                },
                DueDateCalculationInfo = _dueDateCalculationService.GetDueDateCalculations(result),
                RemindersInfo = _remindersService.GetReminders(result.ReminderDetails),
                DocumentsInfo = _documentsService.GetDocuments(result.DocumentsDetails),
                DatesLogicInfo = _datesLogicService.GetDatesLogicDetails(result.DatesLogicDetails),
                EventUpdateInfo = _eventUpdateDetailsService.GetEventUpdateDetails(result)
            };
        }
    }
}

using System;
using System.Collections.Generic;
using System.Linq;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Policy;
using Inprotech.Infrastructure.ResponseEnrichment;
using Inprotech.Infrastructure.Security;
using Inprotech.Web.CaseSupportData;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Reminders;

namespace Inprotech.Web.Cases.Details
{
    [Authorize]
    [NoEnrichment]
    [RoutePrefix("api/case")]
    public class EventNotesController : ApiController
    {
        readonly IEventNotesResolver _eventNotesResolver;
        readonly ISiteControlReader _siteControlReader;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteDateFormat _siteDateFormat;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _now;
        readonly IDbContext _dbContext;

        public EventNotesController(IEventNotesResolver eventNotesResolver, ISiteControlReader siteControlReader,
                                    IPreferredCultureResolver preferredCultureResolver, ISiteDateFormat siteDateFormat, ISecurityContext securityContext,
                                    Func<DateTime> now, IDbContext dbContext)
        {
            _eventNotesResolver = eventNotesResolver;
            _siteControlReader = siteControlReader;
            _preferredCultureResolver = preferredCultureResolver;
            _siteDateFormat = siteDateFormat;
            _securityContext = securityContext;
            _now = now;
            _dbContext = dbContext;
        }

        [HttpGet]
        [Route("event-note-types")]
        public IEnumerable<NotesTypeData> GetEventNoteTypes()
        {
            return _eventNotesResolver.EventNoteTypesWithDefault();
        }

        [HttpGet]
        [Route("eventNotesDetails")]
        [NoEnrichment]
        public List<CaseEventNotesData> GetEventNotesDetails(string taskPlannerRowKey)
        {
            if (string.IsNullOrEmpty(taskPlannerRowKey)) return new List<CaseEventNotesData>();
            var taskPlannerData = taskPlannerRowKey.Split('^');
            int? caseKey, eventNo;
            short? cycle;
            if (taskPlannerRowKey.StartsWith(KnownRowKeyType.ProvideInstruction))
            {
                caseKey =Convert.ToInt32(taskPlannerData[1]);
                eventNo = Convert.ToInt32(taskPlannerData[2]);
                cycle = Convert.ToInt16(taskPlannerData[3]);
            }
            else
            {
                if (!taskPlannerData.Any()) return new List<CaseEventNotesData>();
                if (taskPlannerData[0] == KnownReminderTypes.AdHocDate) return new List<CaseEventNotesData>();

                var caseEventId = !string.IsNullOrWhiteSpace(taskPlannerData[1]) ? Convert.ToInt32(taskPlannerData[1]) : (int?) null;
                var employeeReminderId = !string.IsNullOrWhiteSpace(taskPlannerData[2]) ? Convert.ToInt64(taskPlannerData[2]) : (long?)null;

                var caseEvent = _dbContext.Set<CaseEvent>().SingleOrDefault(_ => _.Id == caseEventId);
                var staffReminder = _dbContext.Set<StaffReminder>().SingleOrDefault(_ => _.EmployeeReminderId == employeeReminderId);

                caseKey = caseEvent?.CaseId ?? staffReminder?.CaseId;
                eventNo = caseEvent?.EventNo ?? staffReminder?.EventId;
                cycle = caseEvent?.Cycle ?? staffReminder?.Cycle;
            }

            var eventNotes = _eventNotesResolver.Resolve(caseKey.GetValueOrDefault(), new[] { eventNo.GetValueOrDefault() }).Where(c => c.Cycle == cycle);
            return eventNotes.ToList();
        }
        
        [HttpGet]
        [Route("default-adhoc-info")]
        [NoEnrichment]
        public DefaultAdhocInfo GetDefaultAdHocInfo(string taskPlannerRowKey)
        {
            if (string.IsNullOrEmpty(taskPlannerRowKey))
                throw new HttpResponseException(HttpStatusCode.BadRequest);

            var taskPlannerData = taskPlannerRowKey.Split('^');
            var caseEventId = !string.IsNullOrWhiteSpace(taskPlannerData[1]) ? Convert.ToInt32(taskPlannerData[1]) : (int?)null;
            var employeeReminderId = !string.IsNullOrWhiteSpace(taskPlannerData[2]) ? Convert.ToInt64(taskPlannerData[2]) : (long?)null;

            var caseEvent = _dbContext.Set<CaseEvent>().SingleOrDefault(_ => _.Id == caseEventId);
            var staffReminder = _dbContext.Set<StaffReminder>().SingleOrDefault(_ => _.EmployeeReminderId == employeeReminderId);

            var caseKey = caseEvent?.CaseId ?? staffReminder?.CaseId;
            var eventNo = caseEvent?.EventNo ?? staffReminder?.EventId;
            var cycle = caseEvent?.Cycle ?? staffReminder?.Cycle;

            var shouldDefaultAdHocInfo = _siteControlReader.Read<bool>(SiteControls.DefaultAdhocInfoFromEvent);
            if (shouldDefaultAdHocInfo)
                return _eventNotesResolver.GetDefaultAdhocInfo(caseKey.GetValueOrDefault(), eventNo.GetValueOrDefault(), cycle.GetValueOrDefault());

            return new DefaultAdhocInfo
            {
                DueDate = _now(),
                Message = _eventNotesResolver.Resolve(caseKey.GetValueOrDefault(),
                                                      new[] { eventNo.GetValueOrDefault() })
                                             .FirstOrDefault(c => c.Cycle == cycle)?.EventText,
                Case = new Picklists.Case
                {
                    Key = caseEvent.Case.Id,
                    Code = caseEvent.Case.Irn,
                    Value = caseEvent.Case.Title
                }
            };
        }

        [HttpPost]
        [Route("eventNotesDetails/update")]
        [NoEnrichment]
        [RequiresAccessTo(ApplicationTask.AnnotateDueDates)]
        [RequiresAccessTo(ApplicationTask.MaintainTaskPlannerApplication)]
        public async Task<dynamic> MaintainEventNotes(CaseEventNotes eventNotes)
        {
            return await _eventNotesResolver.Update(eventNotes);
        }

        [HttpGet]
        [Route("eventNotesDetails/isPredefinedNoteTypeExist")]
        [NoEnrichment]
        public bool IsPredefinedNotesExists()
        {
            var isPredefinedNotesExists = false;
            var predefinedNotes = _eventNotesResolver.GetPredefinedNotes();
            if (predefinedNotes.Any())
            {
                isPredefinedNotesExists = true;
            }

            return isPredefinedNotesExists;
        }

        [HttpGet]
        [Route("eventNotesDetails/siteControlId")]
        [NoEnrichment]
        public dynamic SiteControlId()
        {
            return _siteControlReader.Read<int>(SiteControls.AutomaticEventTextFormat);
        }

        [HttpGet]
        [Route("eventNotesDetails/viewData/formatting")]
        [NoEnrichment]
        public dynamic ViewDataFormatting()
        {
            var loggedInUser = _securityContext.User.Name;
            var formattedName = FormattedName.For(loggedInUser.LastName, loggedInUser.FirstName, loggedInUser.Title,
                loggedInUser.MiddleName, loggedInUser.Suffix,
                EffectiveNameStyle(loggedInUser.NameStyle, loggedInUser.Nationality?.NameStyleId, NameStyles.FirstNameThenFamilyName));

            var culture = _preferredCultureResolver.Resolve();
            var viewData = new ViewData
            {
                FriendlyName = formattedName,
                DateStyle = _now().ToString(_siteDateFormat.Resolve(culture)),
                TimeFormat = _now().ToString("HH:mm")
            };

            return viewData;
        }

        NameStyles EffectiveNameStyle(int? nameStyle, int? nationalityNameStyle, NameStyles fallbackNameStyle)
        {
            var dataNameStyle = nameStyle ?? nationalityNameStyle;
            return dataNameStyle != null
                ? (NameStyles)dataNameStyle
                : fallbackNameStyle;
        }
    }

    public class DefaultAdhocInfo
    {
        public DateTime? DueDate { get; set; }
        public string Message { get; set; }
        public Web.Picklists.Case Case { get; set; }
    }
}
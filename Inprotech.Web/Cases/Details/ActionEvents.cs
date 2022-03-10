using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Policy.AuditTrails;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;

namespace Inprotech.Web.Cases.Details
{
    public interface IActionEvents
    {
        IQueryable<ActionEventData> Events(Case _case, string actionId, ActionEventQuery query);
        Task<IEnumerable<ActionEventData>> ClearValueByCaseAndNameAccess(IEnumerable<ActionEventData> data);
    }

    public class ActionEvents : IActionEvents
    {
        readonly IAuditLogs _auditLogs;
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControl;
        readonly ICaseViewEventsDueDateClientFilter _eventsDueDateClientFilter;
        readonly INameAuthorization _nameAuthorization;
        readonly ICaseAuthorization _caseAuthorization;
        readonly ISubjectSecurityProvider _subjectSecurity;

        public ActionEvents(IDbContext dbContext, ISecurityContext securityContext, IPreferredCultureResolver preferredCultureResolver, ISiteControlReader siteControl, ICaseViewEventsDueDateClientFilter eventsDueDateClientFilter, ICaseAuthorization caseAuthorization, INameAuthorization nameAuthorization, ISubjectSecurityProvider subjectSecurity, IAuditLogs auditLogs)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControl = siteControl;
            _eventsDueDateClientFilter = eventsDueDateClientFilter;
            _nameAuthorization = nameAuthorization;
            _subjectSecurity = subjectSecurity;
            _auditLogs = auditLogs;
            _caseAuthorization = caseAuthorization;
        }

        public class CaseEventValidAction
        {
            public CaseEvent Ce { get; set; }

            public ValidEvent Ve { get; set; }

        }

        public IQueryable<ActionEventData> Events(Case _case, string actionId, ActionEventQuery query)
        {
            var userId = _securityContext.User.Id;
            var isExternalUser = _securityContext.User.IsExternalUser;
            var culture = _preferredCultureResolver.Resolve();
            DateTime? overdueRangeFrom = _eventsDueDateClientFilter.MaxDueDateLimit();
            var sortSiteControl = _siteControl.Read<string>(SiteControls.CaseEventDefaultSorting);
            var canLinkToWorkflow = _siteControl.Read<bool>(SiteControls.EventLinktoWorkflowAllowed);
            IQueryable<CaseEventValidAction> caseEventJoin;
            var activities = GetAttachments(_case, query, isExternalUser);
            var eventHistories = _auditLogs.AuditLogRows<CaseEventILog>(_ => _.CaseId == _case.Id);
            var caseEvents = _dbContext.Set<CaseEvent>().Where(_ => _.CaseId == _case.Id).WhereNotManuallyEnteredEventDate();
            var validEvents = _dbContext.Set<ValidEvent>().Where(_ => _.CriteriaId == query.CriteriaId);
            var names = _dbContext.Set<Name>();
            var nameTypes = _dbContext.Set<NameType>();
            var tableCodes = _dbContext.Set<TableCode>().Where(tc => tc.TableTypeId == (int)TableTypes.PeriodType);
            var validActions = _dbContext.Set<ValidAction>()
                                         .Where(_ => _.PropertyTypeId == _case.PropertyType.Code && _.CaseTypeId == _case.TypeId);
            validActions = validActions.Any(_ => _.Country.Id == _case.Country.Id)
                ? validActions.Where(_ => _.Country.Id == _case.Country.Id)
                : validActions.Where(_ => _.Country.Id == InprotechKaizen.Model.KnownValues.DefaultCountryCode);

            if (query.AllEvents)
            {
                if (query.IsCyclic)
                {
                    caseEvents = caseEvents.Where(_ => _.Cycle == query.Cycle);
                }

                caseEvents = caseEvents.Where(_ => overdueRangeFrom == null || _.EventDueDate == null || _.IsOccurredFlag > 0 || _.EventDueDate >= overdueRangeFrom);
                caseEventJoin = from ve in validEvents
                                join ce1 in caseEvents on ve.EventId equals ce1.EventNo into ce1
                                from ce in ce1.DefaultIfEmpty()
                                select new CaseEventValidAction { Ce = ce, Ve = ve };
            }
            else
            {
                if (query.IsCyclic)
                {
                    caseEvents = caseEvents.Where(_ => overdueRangeFrom == null || _.IsOccurredFlag > 0 || _.EventDueDate >= overdueRangeFrom);
                    caseEvents = caseEvents.Where(_ => _.Cycle == query.Cycle && !(_.EventDate == null && _.EventDueDate == null && _.ReminderDate == null));
                }
                else
                {
                    if (query.MostRecent && sortSiteControl != "CD")
                    {
                        caseEvents = from c in caseEvents
                                     join cMin1 in _dbContext.Set<CaseEvent>().Where(_ => _.IsOccurredFlag == 0 && _.EventDueDate != null)
                                                             .GroupBy(_ => new { _.CaseId, _.EventNo })
                                                             .Select(g => new { g.Key, Cycle = (short?)g.Min(_ => _.Cycle) })
                                     on new { c.CaseId, c.EventNo } equals new { cMin1.Key.CaseId, cMin1.Key.EventNo } into cMin1
                                     from cMin in cMin1.DefaultIfEmpty()
                                     join cMax1 in _dbContext.Set<CaseEvent>().Where(_ => _.IsOccurredFlag >= 1 && _.IsOccurredFlag <= 8 && _.EventDate != null)
                                                             .GroupBy(_ => new { _.CaseId, _.EventNo })
                                                             .Select(g => new { g.Key, Cycle = (short?)g.Max(_ => _.Cycle) })
                                     on new { c.CaseId, c.EventNo } equals new { cMax1.Key.CaseId, cMax1.Key.EventNo } into cMax1
                                     from cMax in cMax1.DefaultIfEmpty()
                                     where c.Cycle == (cMin.Cycle ?? cMax.Cycle)
                                     select c;
                    }
                    else
                    {
                        caseEvents = caseEvents.Where(_ => !(_.EventDate == null && _.EventDueDate == null && _.ReminderDate == null));
                    }

                    caseEvents = caseEvents.Where(_ => overdueRangeFrom == null || _.EventDueDate == null || _.EventDueDate >= overdueRangeFrom);
                }

                caseEventJoin = from ce in caseEvents
                                join ve in validEvents on ce.EventNo equals ve.EventId
                                select new CaseEventValidAction { Ce = ce, Ve = ve };
            }

            var data = from j in caseEventJoin
                       join fc1 in _dbContext.Set<Case>() on j.Ce.FromCaseId equals fc1.Id into fc1
                       from fc in fc1.DefaultIfEmpty()
                       join n1 in names on j.Ce.EmployeeNo equals n1.Id into n1
                       from n in n1.DefaultIfEmpty()
                       join nt1 in nameTypes on j.Ce.DueDateResponsibilityNameType equals nt1.NameTypeCode into nt1
                       from nt in nt1.DefaultIfEmpty()
                       join tc1 in tableCodes on j.Ce.PeriodType equals tc1.UserCode into tc1
                       from tc in tc1.DefaultIfEmpty()
                       join fnt1 in _dbContext.FilterUserNameTypes(userId, culture, isExternalUser, false) on nt.NameTypeCode equals fnt1.NameType into fnt1
                       from fnt in fnt1.DefaultIfEmpty()
                       join va1 in validActions on j.Ce.CreatedByActionKey equals va1.ActionId into va1
                       from va in va1.DefaultIfEmpty()
                       join activity in activities on j.Ce == null ? j.Ve.EventId : j.Ce.EventNo equals activity.EventId into activities1
                       join eventHistory in eventHistories on j.Ce == null ? j.Ve.EventId : j.Ce.EventNo equals eventHistory.EventNo into eventHistories1
                       select new ActionEventData
                       {
                           AttachmentCount = activities1.Count(),
                           HasEventHistory = eventHistories1.Any(),
                           EventNo = j.Ce == null ? j.Ve.EventId : j.Ce.EventNo,
                           EventDescription = DbFuncs.GetTranslation(j.Ve.Description, null, j.Ve.DescriptionTId, culture) ??
                                              DbFuncs.GetTranslation(j.Ve.Event.Description, null, j.Ve.Event.DescriptionTId, culture),
                           EventDate = j.Ce.EventDate,
                           EventDueDate = j.Ce.EventDueDate,
                           NextPoliceDate = j.Ce.ReminderDate,
                           Cycle = j.Ce.Cycle,
                           IsManuallyEntered = j.Ce.IsDateDueSaved.HasValue && j.Ce.IsDateDueSaved.Value > 0,
                           IsOccurredFlag = j.Ce.IsOccurredFlag,
                           CreatedByAction = j.Ce.CreatedByActionKey,
                           CreatedByActionDesc = (va == null) ? null : (DbFuncs.GetTranslation(va.ActionName, null, va.ActionNameTId, culture) ?? DbFuncs.GetTranslation(va.Action.Name, null, va.Action.NameTId, culture)),
                           CreatedByCriteria = j.Ce.CreatedByCriteriaKey,
                           RespName = n,
                           StopPolicing = (j.Ce.EventDate != null || (j.Ce.IsOccurredFlag != null)) && (j.Ce.IsOccurredFlag.Value >= 1 && j.Ce.IsOccurredFlag <= 8),                //CaseEventExt.HasOccured(j.Ce.IsOccurredFlag),
                           NameType = (fnt == null) ? null : nt.Name, //fnt.Name
                           NameTypeId = (fnt == null) ? (int?) null : nt.Id,
                           IsNew = j.Ce.CaseId == 0,
                           FromCaseIrn = fc.Irn,
                           FromCaseKey = fc.Id,
                           CaseKey = _case.Id,
                           Period = j.Ce.EnteredDeadline + " " + tc.Name,
                           ImportanceLevel = _securityContext.User.IsExternalUser ? j.Ve.Event.ClientImportanceLevel : j.Ve.ImportanceLevel,
                           DisplaySequence = j.Ve.DisplaySequence,
                           IsProtentialEvents = (j.Ce == null) || (j.Ce.EventDate == null && j.Ce.EventDueDate == null),
                           CanLinkToWorkflow = canLinkToWorkflow && j.Ce != null && DbFuncs.DoesEntryExistForCaseEvent(userId, _case.Id, j.Ce.EventNo, j.Ce.Cycle)
                       };

            if (query.ImportanceLevel.HasValue)
            {
                data = data.Where(_ => string.Compare(_.ImportanceLevel, query.ImportanceLevel.ToString(), StringComparison.InvariantCultureIgnoreCase) >= 0);
            }
            return data.Sort(sortSiteControl);
        }

        IQueryable<Activity> GetAttachments(Case _case, ActionEventQuery query, bool isExternalUser)
        {
            var activities = new List<Activity>().AsQueryable();
            if (_subjectSecurity.HasAccessToSubject(ApplicationSubject.Attachments))
            {
                activities = _dbContext.Set<Activity>().Where(_ => _.CaseId == _case.Id && (!isExternalUser || _.Attachments.All(a => a.PublicFlag == 1)));
                if (query.Cycle.HasValue)
                {
                    activities = activities.Where(_ => _.Cycle == query.Cycle);
                }
            }

            return activities;
        }

        public async Task<IEnumerable<ActionEventData>> ClearValueByCaseAndNameAccess(IEnumerable<ActionEventData> data)
        {
            var dataArray = data as CaseViewEventsData[] ?? data.ToArray();
            if (!dataArray.Any()) return dataArray;

            var nameIds = dataArray.Where(d => d.NameId != null).Select(d => (int)d.NameId).Distinct().ToArray();
            var caseIds = dataArray.Where(d => d.FromCaseKey != null).Select(d => (int)d.FromCaseKey).Distinct().ToArray();

            var accessibleNames = (await _nameAuthorization.AccessibleNames(nameIds)).ToArray();
            var accessibleCases = (await _caseAuthorization.AccessibleCases(caseIds)).ToArray();

            foreach (var t in dataArray)
            {
                if (t.FromCaseKey != null && !accessibleCases.Contains((int)t.FromCaseKey))
                {
                    t.FromCaseIrn = null;
                    t.FromCaseKey = null;
                }

                if (t.NameId != null && !accessibleNames.Contains((int)t.NameId))
                {
                    t.RespName = null;
                }
            }

            return dataArray;
        }
    }
}
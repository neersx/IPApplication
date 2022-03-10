using System;
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Cases.Events;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using Action = InprotechKaizen.Model.Cases.Action;

namespace Inprotech.Web.Cases.Details
{
    public interface ICaseViewEvents
    {
        IQueryable<CaseViewEventsData> Occurred(int caseId);
        IQueryable<CaseViewEventsData> Due(int caseId);
        Task ClearUnauthorisedDetails(IEnumerable<CaseViewEventsData> data);
    }

    public class CaseViewEvents : ICaseViewEvents
    {
        readonly IDbContext _dbContext;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISiteControlReader _siteControlReader;
        readonly ISecurityContext _securityContext;
        readonly ICaseViewEventsDueDateClientFilter _eventsDueDateClientFilter;
        readonly ICaseViewAttachmentsProvider _attachmentsProvider;
        readonly INameAuthorization _nameAuthorization;
        readonly ICaseAuthorization _caseAuthorization;

        public CaseViewEvents(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver,
                              ISiteControlReader siteControlReader, ISecurityContext securityContext, ICaseAuthorization caseAuthorization, INameAuthorization nameAuthorization, ICaseViewEventsDueDateClientFilter eventsDueDateClientFilter,
                              ICaseViewAttachmentsProvider attachmentsProvider)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _siteControlReader = siteControlReader;
            _securityContext = securityContext;
            _eventsDueDateClientFilter = eventsDueDateClientFilter;
            _attachmentsProvider = attachmentsProvider;
            _nameAuthorization = nameAuthorization;
            _caseAuthorization = caseAuthorization;
        }

        bool IsExternalUser => _securityContext.User?.IsExternalUser == true;

        public IQueryable<CaseViewEventsData> Occurred(int caseId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var userId = _securityContext.User.Id;
            var showAllEventsDates = _siteControlReader.Read<bool?>(SiteControls.AlwaysShowEventDate) ?? false;

            var caseEvents = _dbContext.Set<CaseEvent>().Where(_ => _.CaseId == caseId).WhereHasOccurred();
            var events = _dbContext.Set<Event>();

            var maxOpenActionCycle = from oa in _dbContext.Set<OpenAction>()
                                     where oa.CaseId == caseId
                                     group oa by oa.ActionId
                                     into g
                                     select new
                                     {
                                         g.Key,
                                         Cycle = g.DefaultIfEmpty().Max(_ => _.Cycle)
                                     };

            var openAction = from oa in _dbContext.Set<OpenAction>()
                             where oa.CaseId == caseId
                             join oaMax in maxOpenActionCycle on new {oa.ActionId, oa.Cycle} equals new {ActionId = oaMax.Key, oaMax.Cycle} into oaMax1
                             from oaMax in oaMax1.DefaultIfEmpty()
                             select oa;

            var eventControl = _dbContext.Set<ValidEvent>();

            var renewalEvent = from oa in _dbContext.Set<OpenAction>()
                               where oa.CaseId == caseId
                               join va in _dbContext.Set<ValidEvent>() on oa.CriteriaId equals va.CriteriaId
                               join a in _dbContext.Set<Action>() on oa.ActionId equals a.Code
                               group a.ActionType by new
                               {
                                   oa.CaseId,
                                   va.EventId
                               }
                               into g
                               select new
                               {
                                   g.Key.CaseId,
                                   g.Key.EventId,
                                   ACTIONTYPEFLAG = g.DefaultIfEmpty().Max()
                               };

            var activities = _attachmentsProvider.GetActivityWithAttachments(caseId);

            var caseOccurredDates = from ce in caseEvents
                                    join fc1 in _dbContext.Set<Case>() on ce.FromCaseId equals fc1.Id into fc1
                                    from fc in fc1.DefaultIfEmpty()
                                    join n1 in _dbContext.Set<Name>() on ce.EmployeeNo equals n1.Id into n1
                                    from n in n1.DefaultIfEmpty()
                                    join nt1 in _dbContext.Set<NameType>() on ce.DueDateResponsibilityNameType equals nt1.NameTypeCode into nt1
                                    from nt in nt1.DefaultIfEmpty()
                                    join fnt1 in _dbContext.FilterUserNameTypes(userId, culture, IsExternalUser, false) on ce.DueDateResponsibilityNameType equals fnt1.NameType into fnt1
                                    from fnt in fnt1.DefaultIfEmpty()
                                    join e in events on ce.EventNo equals e.Id
                                    join oa1 in openAction on e.ControllingAction equals oa1.ActionId into oa1
                                    from oa in oa1.DefaultIfEmpty()
                                    join ec in eventControl on new {EventId = ce.EventNo, CriteriaId = oa == null || oa.CriteriaId == (int?) null ? ce.CreatedByCriteriaKey : oa.CriteriaId.Value}
                                        equals new {ec.EventId, CriteriaId = (int?) ec.CriteriaId} into ec1
                                    from ec in ec1.DefaultIfEmpty()
                                    join r in renewalEvent on new {ce.CaseId, EventId = ce.EventNo} equals new {r.CaseId, r.EventId}
                                    join activity in activities on new {EventNo = (int?)ce.EventNo, ce.Cycle} equals new {EventNo = activity.EventId, Cycle = activity.Cycle ?? 1} into activities1  
                                    where ce.EventDate != null && (showAllEventsDates || e.ControllingAction == null || oa != null && oa.PoliceEvents == 1)
                                    select new
                                    {
                                        ce.CaseId,
                                        ce.EventNo,
                                        ce.Cycle,
                                        ce.EventDate,
                                        ce.EventDueDate,
                                        EventDescription = ec != null && ec.Description != null ? ec.Description : e.Description,
                                        EventDescriptionTId = ec != null && ec.Description != null ? ec.DescriptionTId : e.DescriptionTId,
                                        ImportanceLevel = ec != null && ec.ImportanceLevel != null ? ec.ImportanceLevel : e.ImportanceLevel,
                                        e.ClientImportanceLevel,
                                        ce.FromCaseId,
                                        ce.EmployeeNo,
                                        ce.DueDateResponsibilityNameType,
                                        nt = fnt == null ? null : nt == null ? null : nt.Name,
                                        Irn = fc == null ? null : fc.Irn,
                                        n = ce.DueDateResponsibilityNameType == null ? n : null,
                                        Notes = ec == null || ec.Event == null ? null : ec.Event.Notes,
                                        NotesTId = (ec == null || ec.Event == null) ? null : ec.Event.NotesTId,
                                        attachmentCount = activities1.Count(),
                                        actionId = ce.CreatedByActionKey
                                    };

            var k = from ce in caseOccurredDates
                    select new CaseViewEventsData
                    {
                        CaseKey = ce.CaseId,
                        EventNo = ce.EventNo,
                        Cycle = ce.Cycle,
                        EventDescription = DbFuncs.GetTranslation(ce.EventDescription, null, ce.EventDescriptionTId, culture),
                        EventDate = ce.EventDate,
                        EventDueDate = ce.EventDueDate,
                        ImportanceLevel = IsExternalUser ? ce.ClientImportanceLevel : ce.ImportanceLevel,
                        NameType = ce.nt,
                        FromCaseKey = ce.FromCaseId,
                        FromCaseIrn = ce.Irn,
                        RespName = ce.n,
                        EventDefinition = DbFuncs.GetTranslation(ce.Notes, null, ce.NotesTId, culture),
                        AttachmentCount = ce.attachmentCount,
                        CreatedByAction = ce.actionId
                    };

            return k.Distinct().OrderByDescending(_ => _.EventDate).ThenBy(_ => _.EventDescription);
        }

        public IQueryable<CaseViewEventsData> Due(int caseId)
        {
            var culture = _preferredCultureResolver.Resolve();
            var userId = _securityContext.User.Id;
            DateTime? overdueRangeFrom = _eventsDueDateClientFilter.MaxDueDateLimit();
            var anyOpenActionForDueDate = _siteControlReader.Read<bool>(SiteControls.AnyOpenActionForDueDate);

            var caseEvents = _dbContext.Set<CaseEvent>().Where(_ => _.CaseId == caseId).WhereNotOccurred();

            var policedOpenAction = from oa1 in _dbContext.Set<OpenAction>().Where(_ => _.CaseId == caseId)
                                    join ec1 in _dbContext.Set<ValidEvent>() on oa1.CriteriaId equals ec1.CriteriaId
                                    join a1 in _dbContext.Set<Action>() on oa1.ActionId equals a1.Code
                                    where oa1.PoliceEvents == 1
                                    select new
                                    {
                                        oa1.CaseId,
                                        ec1.EventId,
                                        oa1.ActionId,
                                        oa1.Cycle,
                                        a1.NumberOfCyclesAllowed
                                    };

            var activities = _attachmentsProvider.GetActivityWithAttachments(caseId);

            var caseDueDates = from ce in caseEvents
                               join fc1 in _dbContext.Set<Case>() on ce.FromCaseId equals fc1.Id into fc1
                               from fc in fc1.DefaultIfEmpty()
                               join n1 in _dbContext.Set<Name>() on ce.EmployeeNo equals n1.Id into n1
                               from n in n1.DefaultIfEmpty()
                               join nt1 in _dbContext.Set<NameType>() on ce.DueDateResponsibilityNameType equals nt1.NameTypeCode into nt1
                               from nt in nt1.DefaultIfEmpty()
                               join fnt1 in _dbContext.FilterUserNameTypes(userId, culture, IsExternalUser, false) on ce.DueDateResponsibilityNameType equals fnt1.NameType into fnt1
                               from fnt in fnt1.DefaultIfEmpty()
                               join oa in _dbContext.Set<OpenAction>() on ce.CaseId equals oa.CaseId
                               join ec in _dbContext.Set<ValidEvent>() on new {oa.CriteriaId, ce.EventNo} equals new {CriteriaId = (int?) ec.CriteriaId, EventNo = ec.EventId}
                               join e in _dbContext.Set<Event>() on ce.EventNo equals e.Id
                               join a in _dbContext.Set<Action>() on oa.ActionId equals a.Code
                               join activity in activities on new {EventNo = (int?)ce.EventNo, ce.Cycle} equals new {EventNo = activity.EventId, Cycle = activity.Cycle ?? 1} into activities1  
                               where ce.EventDueDate != null
                                     && (oa.ActionId == e.ControllingAction || e.ControllingAction == null && ec.CriteriaId == ce.CreatedByCriteriaKey)
                                     && oa.Cycle == (a.NumberOfCyclesAllowed > 1 ? ce.Cycle : 1)
                                     && policedOpenAction.Any(_ => _.EventId == ce.EventNo
                                                                   && _.ActionId == (anyOpenActionForDueDate ? _.ActionId : e.ControllingAction != null ? e.ControllingAction : _.ActionId)
                                                                   && _.Cycle == (_.NumberOfCyclesAllowed > 1 ? ce.Cycle : 1))
                               select new
                               {
                                   ce.CaseId,
                                   ce.EventNo,
                                   ce.Cycle,
                                   ce.EventDueDate,
                                   EventDescription = ec.Description,
                                   EventDescriptionTId = ec.DescriptionTId,
                                   ec.ImportanceLevel,
                                   e.ClientImportanceLevel,
                                   ce.FromCaseId,
                                   ce.EmployeeNo,
                                   nt = fnt == null ? null : nt.Name,
                                   Irn = fc == null ? null : fc.Irn,
                                   n = ce.DueDateResponsibilityNameType == null ? n : null,
                                   Notes = ec == null || ec.Event == null ? null : ec.Event.Notes,
                                   NotesTId = ec == null || ec.Event == null ? null : ec.Event.NotesTId,
                                   attachmentCount = activities1.Count(),
                                   actionId = ce.CreatedByActionKey
                               };

            var k = from ce in caseDueDates
                    where overdueRangeFrom == null || ce.EventDueDate >= overdueRangeFrom
                    select new CaseViewEventsData
                    {
                        CaseKey = ce.CaseId,
                        EventNo = ce.EventNo,
                        Cycle = ce.Cycle,
                        EventDescription = DbFuncs.GetTranslation(ce.EventDescription, null, ce.EventDescriptionTId, culture),
                        EventDate = ce.EventDueDate,
                        ImportanceLevel = IsExternalUser ? ce.ClientImportanceLevel : ce.ImportanceLevel,
                        NameType = ce.nt,
                        FromCaseKey = ce.FromCaseId,
                        FromCaseIrn = ce.Irn,
                        RespName = ce.n,
                        EventDefinition = DbFuncs.GetTranslation(ce.Notes, null, ce.NotesTId, culture),
                        AttachmentCount = ce.attachmentCount,
                        CreatedByAction = ce.actionId
                    };

            return k.Distinct().OrderBy(_ => _.EventDate).ThenBy(_ => _.EventDescription);
        }

        public async Task ClearUnauthorisedDetails(IEnumerable<CaseViewEventsData> data)
        {
            var dataArray = data as CaseViewEventsData[] ?? data.ToArray();
            if (dataArray.Any())
            {
                var accessibleNames = (await _nameAuthorization.AccessibleNames(dataArray.Where(d => d.NameId.HasValue).Select(d => d.NameId.GetValueOrDefault()).Distinct().ToArray())).ToArray();
                var accessibleCases = (await _caseAuthorization.AccessibleCases(dataArray.Where(d => d.FromCaseKey.HasValue).Select(d => d.FromCaseKey.GetValueOrDefault()).Distinct().ToArray())).ToArray();

                foreach (var t in dataArray)
                {
                    if (!accessibleCases.Contains(t.FromCaseKey.GetValueOrDefault()))
                    {
                        t.FromCaseIrn = null;
                        t.FromCaseKey = null;
                    }

                    if (!accessibleNames.Contains(t.NameId.GetValueOrDefault()))
                    {
                        t.RespName = null;
                    }
                }
            }
        }
    }
}
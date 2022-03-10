using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Picklists;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;
using ServiceStack.Text;
using Action = InprotechKaizen.Model.Cases.Action;
using KnownValues = InprotechKaizen.Model.KnownValues;

namespace Inprotech.Web.CaseSupportData
{
    public interface IActions
    {
        IEnumerable<ActionData> Get(string country, string propertyType, string caseType, string action = null);

        IEnumerable<dynamic> ImportanceLevels();

        ActionData GetActionByCode(string code);

        IQueryable<ActionData> CaseViewActions(int caseId, string country, string propertyType, string caseType);

        IQueryable<CodeDescription> GetActionsDescription(string country, string propertyType, string caseType, IEnumerable<string> actionCodes);
    }

    public class Actions : IActions
    {
        readonly IDbContext _dbContext;
        readonly IActionEventNotes _actionEventNotes;
        readonly IPreferredCultureResolver _preferredCultureResolver;
        readonly ISecurityContext _securityContext;
        readonly Func<DateTime> _systemTime;
        readonly ITaskSecurityProvider _taskSecurityProvider;
        public Actions(IDbContext dbContext, IPreferredCultureResolver preferredCultureResolver, ISecurityContext securityContext, Func<DateTime> systemTime, IActionEventNotes actionEventNotes, ITaskSecurityProvider taskSecurityProvider)
        {
            _dbContext = dbContext;
            _preferredCultureResolver = preferredCultureResolver;
            _securityContext = securityContext;
            _systemTime = systemTime;
            _actionEventNotes = actionEventNotes;
            _taskSecurityProvider = taskSecurityProvider;
        }

        public IEnumerable<ActionData> Get(string country, string propertyType, string caseType, string actionKey = null)
        {
            var culture = _preferredCultureResolver.Resolve();

            if (!string.IsNullOrWhiteSpace(country) && !string.IsNullOrWhiteSpace(propertyType) &&
                !string.IsNullOrWhiteSpace(caseType))
            {
                var validActions = _dbContext.Set<ValidAction>()
                                             .Where(_ => _.PropertyTypeId == propertyType && _.CaseTypeId == caseType);

                validActions = validActions.Any(_ => _.Country.Id == country)
                    ? validActions.Where(_ => _.Country.Id == country)
                    : validActions.Where(_ => _.Country.Id == KnownValues.DefaultCountryCode);

                var results = validActions.Select(_ => new ActionData
                {
                    Id = _.Action.Id,
                    Code = _.ActionId,
                    Name = DbFuncs.GetTranslation(_.ActionName, null, _.ActionNameTId, culture),
                    BaseName = DbFuncs.GetTranslation(_.Action.Name, null, _.Action.NameTId, culture),
                    Cycles = _.Action.NumberOfCyclesAllowed,
                    IsDefaultJurisdiction = _.CountryId == KnownValues.DefaultCountryCode ? 1 : 0,
                    ActionType = _.Action.ActionType
                }).ToList();

                if (actionKey == null || results.Any(_ => _.Code == actionKey))
                {
                    return results;
                }
            }

            return _dbContext.Set<Action>().Select(_ => new ActionData
            {
                Id = _.Id,
                Code = _.Code,
                Name = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                BaseName = DbFuncs.GetTranslation(_.Name, null, _.NameTId, culture),
                Cycles = _.NumberOfCyclesAllowed,
                ActionType = _.ActionType,
                ImportanceLevel = _.ImportanceLevel
            });
        }

        public IEnumerable<dynamic> ImportanceLevels()
        {
            return _dbContext.Set<Importance>().OrderByDescending(_ => _.Level).Select(_ => new
            {
                _.Level,
                _.Description
            }).ToArray();
        }

        public ActionData GetActionByCode(string code)
        {
            var culture = _preferredCultureResolver.Resolve();
            var action = _dbContext.Set<Action>().SingleOrDefault(x => x.Code == code);

            if (action == null) return null;

            return new ActionData
            {
                Id = action.Id,
                Code = action.Code,
                Name = DbFuncs.GetTranslation(action.Name, null, action.NameTId, culture),
                BaseName = DbFuncs.GetTranslation(action.Name, null, action.NameTId, culture),
                Cycles = action.NumberOfCyclesAllowed,
                ActionType = action.ActionType,
                ImportanceLevel = action.ImportanceLevel
            };
        }

        public IQueryable<ActionData> CaseViewActions(int caseId, string country, string propertyType, string caseType)
        {
            var openActions = _dbContext.Set<OpenAction>().Where(_ => _.CaseId == caseId);
            if (!openActions.Any())
                return Enumerable.Empty<ActionData>().AsQueryable();

            var culture = _preferredCultureResolver.Resolve();
            var profileId = _securityContext.User.Profile?.Id;
            var now = _systemTime();

            if (!string.IsNullOrWhiteSpace(country) && !string.IsNullOrWhiteSpace(propertyType) &&
                !string.IsNullOrWhiteSpace(caseType))
            {
                var validActions = _dbContext.Set<ValidAction>()
                                             .Where(_ => _.PropertyTypeId == propertyType && _.CaseTypeId == caseType);

                validActions = validActions.Any(_ => _.Country.Id == country)
                    ? validActions.Where(_ => _.Country.Id == country)
                    : validActions.Where(_ => _.Country.Id == KnownValues.DefaultCountryCode);

                var data = from va in validActions
                           join oa in openActions
                               on va.ActionId equals oa.ActionId
                               into availableActions
                           from aa in availableActions.DefaultIfEmpty()
                           select new
                           {
                               aa,
                               va.ActionId,
                               name = DbFuncs.GetTranslation(va.ActionName, null, va.ActionNameTId, culture) ??
                                      DbFuncs.GetTranslation(va.Action.Name, null, va.Action.NameTId, culture),
                               policeEvents = aa != null ? aa.PoliceEvents : (decimal?)null,
                               va.DisplaySequence,
                               cycle = aa != null ? aa.Cycle : (short?)null,
                               criteriaId = (aa != null) ? aa.CriteriaId : DbFuncs.GetCriteriaNo(caseId, "E", va.Action.Code, now, profileId),
                               va.Action.NumberOfCyclesAllowed,
                               va.Action.ImportanceLevel
                           };

                var canUpdateProtectedRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRulesProtected);
                var canUpdateUnprotectedRules = _taskSecurityProvider.HasAccessTo(ApplicationTask.MaintainWorkflowRules);

                var actionEventNotes = _actionEventNotes.ActionIdsWithEventNotes(caseId).ToList();

                return from act in data
                       join cc in _dbContext.Set<Criteria>()
                                            .WhereWorkflowCriteria()
                                            .Where(_ => _.UserDefinedRule == null || _.UserDefinedRule == 0 && canUpdateProtectedRules || _.UserDefinedRule == 1 && canUpdateUnprotectedRules)
                           on act.criteriaId equals cc.Id into editableCriteria
                       from criteria in editableCriteria.DefaultIfEmpty()
                       orderby act.policeEvents descending, act.DisplaySequence, act.cycle
                       select new ActionData
                       {
                           Code = act.ActionId,
                           HasEventsWithNotes = actionEventNotes.Contains(act.ActionId),
                           Name = act.name,
                           Cycle = act.cycle,
                           IsOpen = act.policeEvents == 1,
                           IsClosed = act.aa != null && act.policeEvents != 1,
                           IsPotential = act.aa == null,
                           Cycles = act.NumberOfCyclesAllowed,
                           Status = act.aa == null ? null : act.aa.Status,
                           CriteriaId = act.criteriaId,
                           DisplaySequence = act.DisplaySequence,
                           ImportanceLevel = act.ImportanceLevel,
                           HasEditableCriteria = criteria != null
                       };
            }

            return Enumerable.Empty<ActionData>().AsQueryable();
        }

        public IQueryable<CodeDescription> GetActionsDescription(string country, string propertyType, string caseType, IEnumerable<string> actionCodes)
        {
            if (string.IsNullOrEmpty(country) || string.IsNullOrWhiteSpace(propertyType) || string.IsNullOrWhiteSpace(caseType) || !actionCodes.Any())
                return Enumerable.Empty<CodeDescription>().AsQueryable();

            var culture = _preferredCultureResolver.Resolve();
            actionCodes = actionCodes.Distinct().ToArray();

            var validActions = _dbContext.Set<ValidAction>()
                                         .Where(_ => _.PropertyTypeId == propertyType && _.CaseTypeId == caseType);

            validActions = validActions.Any(_ => _.Country.Id == country)
                ? validActions.Where(_ => _.Country.Id == country)
                : validActions.Where(_ => _.Country.Id == KnownValues.DefaultCountryCode);

            return
                from va in validActions
                where actionCodes.Contains(va.ActionId)
                select new CodeDescription
                {
                    Code = va.ActionId,
                    Description = DbFuncs.GetTranslation(va.ActionName, null, va.ActionNameTId, culture) ??
                                  DbFuncs.GetTranslation(va.Action.Name, null, va.Action.NameTId, culture)
                };
        }
    }
}
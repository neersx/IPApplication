using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Extensions;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration.SiteControl;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Rules;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Cases.Extensions
{
    public static class CaseExtensions
    {
        public static IEnumerable<OfficialNumber> CurrentNumbersIssuedByIpOffices(this Case @case)
        {
            if(@case == null) throw new ArgumentNullException("case");

            return @case.OfficialNumbers
                        .Where(
                               o => o.IsCurrent.GetValueOrDefault() == 1
                                    && o.NumberType.IssuedByIpOffice);
        }

        public static OfficialNumber CurrentOfficialNumberFor(this Case @case, DataEntryTask dataEntryTask)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");

            if(dataEntryTask.OfficialNumberType == null)
                return null;

            return @case.OfficialNumbers.FirstOrDefault(
                                                        o =>
                                                        o.NumberTypeId == dataEntryTask.OfficialNumberType.NumberTypeCode &&
                                                        o.IsCurrent == 1);
        }

        public static short? CurrentStatus(this Case @case)
        {
            if(@case == null) throw new ArgumentNullException("case");

            if(@case.CaseStatus == null)
                return null;

            return @case.CaseStatus.Id;
        }

        public static IEnumerable<DataEntryTask> GetAccessibleDataEntryTasks(
            this Case @case,
            User user,
            IDbContext dbContext)
        {
            if(@case == null) throw new ArgumentNullException(nameof(@case));
            if(user == null) throw new ArgumentNullException(nameof(user));
            if(dbContext == null) throw new ArgumentNullException(nameof(dbContext));

            var existingDataEntryTasks =
                @case.OpenActions
                     .Where(openAction => openAction.Criteria != null)
                     .SelectMany(openAction => openAction.Criteria.DataEntryTasks).ToArray();

            var criteriaNos = existingDataEntryTasks.Select(dc => dc.CriteriaId).Distinct();

            var userControls = dbContext.Set<UserControl>()
                                        .Where(uc => criteriaNos.Contains(uc.CriteriaNo)).ToList();
            var roleControls = dbContext.Set<RolesControl>()
                                        .Where(rc => criteriaNos.Contains(rc.CriteriaId)).ToList();

            return AccessibleDataEntryTasks(userControls, roleControls, existingDataEntryTasks, user);
        }

        public static IEnumerable<ValidAction> GetAllValidActionsForCase(this Case @case, IDbContext dbContext)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dbContext == null) throw new ArgumentNullException("dbContext");

            var allValidActions = dbContext.Set<ValidAction>()
                                           .Include(va => va.Action)
                                           .Where(
                                                  va =>
                                                  va.CaseType.Code == @case.Type.Code &&
                                                  va.PropertyType.Code == @case.PropertyType.Code &&
                                                  (va.Country.Id == @case.Country.Id ||
                                                   va.Country.Id == KnownValues.DefaultCountryCode))
                                           .ToArray();

            var splittedActions = allValidActions.Split(va => va.Country.Id == @case.Country.Id);
            var exactMatches = splittedActions.Included;
            var defaultMatches = splittedActions.Excluded;

            var uniqueDefaultMatches = defaultMatches
                .Where(
                       dm => !exactMatches
                                  .Any(
                                       em => em.CaseType == dm.CaseType &&
                                             em.PropertyType == dm.PropertyType &&
                                             em.ActionId == dm.ActionId));

            return exactMatches.Concat(uniqueDefaultMatches).ToArray();
        }

        public static void RecordNewCaseLocation(this Case @case, CaseLocation caseLocation, IDbContext dbContext)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(caseLocation == null) throw new ArgumentNullException("caseLocation");
            if(dbContext == null) throw new ArgumentNullException("dbContext");

            if(caseLocation.CaseId != @case.Id)
                throw new ArgumentException("case must match when recording a new case location");

            @case.CaseLocations.Add(caseLocation);

            var maxHistoricalLocationAllowed = dbContext.Set<SiteControl>()
                                                        .SingleOrDefault(sc => sc.ControlId == SiteControls.MAXLOCATIONS);

            if(maxHistoricalLocationAllowed == null || !maxHistoricalLocationAllowed.IntegerValue.HasValue)
                return;

            while(@case.CaseLocations.Count > maxHistoricalLocationAllowed.IntegerValue)
            {
                var caseLocationToPurge = @case.CaseLocations
                                               .OrderBy(cl => cl.WhenMoved)
                                               .First(cl => cl.CaseId == @case.Id);

                @case.CaseLocations.Remove(caseLocationToPurge);
                dbContext.Set<CaseLocation>().Remove(caseLocationToPurge);
            }
        }

        public static void RecordCaseStatusChangeActivity(
            this Case @case,
            DataEntryTask dataEntryTask,
            User user,
            DateTime activityPerformed)
        {
            if(@case == null) throw new ArgumentNullException("case");
            if(dataEntryTask == null) throw new ArgumentNullException("dataEntryTask");
            if(user == null) throw new ArgumentNullException("user");

            @case.History.Add(
                              new CaseActivityHistory(@case, activityPerformed, user.UserName)
                              {
                                  ActionId = dataEntryTask.Criteria.Action.Code,
                                  CaseId = @case.Id,
                                  CaseStatusCode = dataEntryTask.CaseStatus.Id,
                                  IdentityId = user.Id,
                                  ProgramId = KnownValues.SystemId
                              });
        }

        public static IEnumerable<OpenAction> ByCriteria(this IEnumerable<OpenAction> openActions, int criteriaId)
        {
            return openActions.Where(oa => oa.Criteria != null && oa.Criteria.Id == criteriaId);
        }

        public static IEnumerable<OpenAction> CurrentOpenActions(this Case @case)
        {
            if(@case == null) throw new ArgumentNullException("case");
            return @case.OpenActions.Where(oa => oa.IsOpen);
        }

        static IEnumerable<DataEntryTask> AccessibleDataEntryTasks(IList<UserControl> userControls, IList<RolesControl> rolesControls, DataEntryTask[] existingDataEntryTasks, User user)
        {
            var restrictedUserEntries = RestrictedUserEntries(user, existingDataEntryTasks, userControls);

            var restrictedRolesEntries = RestrictedRolesEntries(rolesControls, existingDataEntryTasks, user);

            if (restrictedRolesEntries != null && restrictedUserEntries != null)
                return existingDataEntryTasks.Except(restrictedRolesEntries.Intersect(restrictedUserEntries));

            if (restrictedRolesEntries != null)
                return existingDataEntryTasks.Except(restrictedRolesEntries);

            if (restrictedUserEntries != null)
                return existingDataEntryTasks.Except(restrictedUserEntries);

            return existingDataEntryTasks;
        }

        static IEnumerable<DataEntryTask> RestrictedUserEntries(User user, IEnumerable<DataEntryTask> existingDataEntryTasks, IList<UserControl> userControls)
        {
            if (!userControls.Any()) return null;

            return existingDataEntryTasks.Where(
                                                dc => userControls.Any(
                                                                       uc =>
                                                                           StringComparer
                                                                               .InvariantCultureIgnoreCase
                                                                               .Compare(
                                                                                        uc.UserId,
                                                                                        user.UserName) !=
                                                                           0 &&
                                                                           uc.CriteriaNo ==
                                                                           dc.CriteriaId &&
                                                                           uc.DataEntryTaskId == dc.Id))
                                         .Where(dc => !userControls.Any(
                                                                        uc =>
                                                                            StringComparer
                                                                                .InvariantCultureIgnoreCase
                                                                                .Compare(
                                                                                         uc.UserId,
                                                                                         user.UserName) ==
                                                                            0 &&
                                                                            uc.CriteriaNo ==
                                                                            dc.CriteriaId &&
                                                                            uc.DataEntryTaskId == dc.Id));
        }

        static IEnumerable<DataEntryTask> RestrictedRolesEntries(IList<RolesControl> rolesControls, IEnumerable<DataEntryTask> existingDataEntryTasks, User user)
        {
            if (!rolesControls.ToArray().Any()) return null;

            var validRoles = user.Roles.Select(ur => ur.Id).ToArray();

            return existingDataEntryTasks.Where(dc => rolesControls.ToArray().Any(
                                                                                  rc =>
                                                                                      !validRoles.Contains(rc.RoleId) &&
                                                                                      rc.CriteriaId ==
                                                                                      dc.CriteriaId &&
                                                                                      rc.DataEntryTaskId == dc.Id))
                                         .Where(dc => !rolesControls.Any(
                                                                         rc =>
                                                                             validRoles.Contains(rc.RoleId) &&
                                                                             rc.CriteriaId ==
                                                                             dc.CriteriaId &&
                                                                             rc.DataEntryTaskId == dc.Id));
        }

    }
}
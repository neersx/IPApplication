using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using System.Threading.Tasks;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class RolesTasksSubjectsAndModulesProvider : IAnalyticsEventProvider
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;

        public RolesTasksSubjectsAndModulesProvider(IDbContext dbContext, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _now = now;
        }

        public async Task<IEnumerable<AnalyticsEvent>> Provide(DateTime lastChecked)
        {
            var today = _now().Date;
            var tasks = new Dictionary<int, Interim>();
            var subjects = new Dictionary<int, Interim>();
            var modules = new Dictionary<int, Interim>();

            var roles = await _dbContext.Set<Role>().ToDictionaryAsync(k => k.Id, v => v.RoleName);
            var externalRoles = await _dbContext.Set<Role>().Where(_ => _.IsExternal == true).Select(_ => _.Id).ToArrayAsync();

            foreach (var r in roles)
            {
                var roleKey = r.Key.ToString();

                var isExternal = externalRoles.Contains(r.Key);

                await CaptureIntoResultSet(r.Value,
                                           modules,
                                           async () => await (from p in _dbContext.PermissionsForLevel("ROLE", roleKey, "MODULE", null, null, today)
                                                              join m in _dbContext.Set<WebpartModule>() on p.ObjectIntegerKey equals m.Id into m1
                                                              from m in m1
                                                              where p.CanExecute || p.CanSelect || p.CanInsert || p.CanUpdate || p.CanDelete
                                                              select m)
                                               .ToDictionaryAsync(k => k.Id,
                                                                  v => isExternal ? v.Title + " (Client Access)" : v.Title));

                await CaptureIntoResultSet(r.Value,
                                           tasks,
                                           async () => await (from p in _dbContext.PermissionsForLevel("ROLE", roleKey, "TASK", null, null, today)
                                                              join t in _dbContext.Set<SecurityTask>() on p.ObjectIntegerKey equals t.Id into t1
                                                              from t in t1
                                                              where p.CanExecute || p.CanSelect || p.CanInsert || p.CanUpdate || p.CanDelete
                                                              select t)
                                               .ToDictionaryAsync(k => (int)k.Id, v => v.Name));

                await CaptureIntoResultSet(r.Value,
                                           subjects,
                                           async () => await (from p in _dbContext.PermissionsForLevel("ROLE", roleKey, "DATATOPIC", null, null, today)
                                                              join dt in _dbContext.Set<DataTopic>() on p.ObjectIntegerKey equals dt.Id into dt1
                                                              from dt in dt1
                                                              where p.CanExecute || p.CanSelect || p.CanInsert || p.CanUpdate || p.CanDelete
                                                              select dt)
                                               .ToDictionaryAsync(k => (int)k.Id, v => v.Name));
            }

            var events = new List<AnalyticsEvent>();

            events.AddRange(from m in modules
                            select new AnalyticsEvent
                            {
                                Name = AnalyticsEventCategories.RolesWebPartPrefix + m.Value.Description,
                                Value = string.Join(", ", m.Value.Values.OrderBy(_ => _))
                            });

            events.AddRange(from t in tasks
                            select new AnalyticsEvent
                            {
                                Name = AnalyticsEventCategories.RolesTasksPrefix + t.Value.Description,
                                Value = string.Join(", ", t.Value.Values.OrderBy(_ => _))
                            });

            events.AddRange(from s in subjects
                            select new AnalyticsEvent
                            {
                                Name = AnalyticsEventCategories.RolesSubjectPrefix + s.Value.Description,
                                Value = string.Join(", ", s.Value.Values.OrderBy(_ => _))
                            });

            return events;
        }

        static async Task CaptureIntoResultSet(string role, IDictionary<int, Interim> resultSet, Func<Task<Dictionary<int, string>>> resolver)
        {
            foreach (var availableInRole in await resolver())
            {
                if (!resultSet.ContainsKey(availableInRole.Key))
                {
                    resultSet[availableInRole.Key] = new Interim { Description = availableInRole.Value };
                }

                resultSet[availableInRole.Key].Values.Add(role);
            }
        }

        class Interim
        {
            public Interim()
            {
                Values = new HashSet<string>();
            }

            public string Description { get; set; }

            public HashSet<string> Values { get; }
        }
    }
}
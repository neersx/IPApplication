using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public class SessionTasksProvider : ITaskSecurityProvider, ISessionValidator
    {
        readonly Func<DateTime> _clock;
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IAuthSettings _settings;
        readonly ITaskSecurityProviderCache _taskSecurityProviderCache;

        public SessionTasksProvider(IDbContext dbContext, ISecurityContext securityContext, ITaskSecurityProviderCache taskSecurityProviderCache, Func<DateTime> clock, IAuthSettings settings)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _taskSecurityProviderCache = taskSecurityProviderCache;
            _clock = clock;
            _settings = settings;
        }

        public bool IsSessionValid(long logId)
        {
            var maxExtensionTime = _clock().AddMinutes(-1 * _settings.SessionTimeout);

            if (_securityContext.User == null)
            {
                return false;
            }

            return (from session in _dbContext.Set<UserIdentityAccessLog>()
                    where session.LogId == logId
                          && session.LogoutTime == null
                          && (session.LoginTime > maxExtensionTime || session.LastExtension != null && session.LastExtension > maxExtensionTime)
                    select true).SingleOrDefault();
        }

        public IEnumerable<ValidSecurityTask> ListAvailableTasks(int? userId = null)
        {
            return AvailableTasks(userId).Values;
        }

        public bool HasAccessTo(ApplicationTask applicationTask)
        {
            return AvailableTasks().TryGetValue((short) applicationTask, out _);
        }

        public bool HasAccessTo(ApplicationTask applicationTask, ApplicationTaskAccessLevel level)
        {
            return AvailableTasks().TryGetValue((short) applicationTask, out var task) && HasAccess(task, level);
        }

        public bool UserHasAccessTo(int userId, ApplicationTask applicationTask)
        {
            return AvailableTasks(userId).TryGetValue((short) applicationTask, out _);
        }

        IDictionary<short, ValidSecurityTask> AvailableTasks(int? userId = null)
        {
            var identityId = userId ?? _securityContext.User.Id;
            return _taskSecurityProviderCache.Resolve(x =>
            {
                return AvailableTasksFromDb(identityId)
                    .ToDictionary(k => k.TaskId, v => v);
            }, identityId);
        }

        IQueryable<ValidSecurityTask> AvailableTasksFromDb(int userId)
        {
            var today = _clock().Date;

            var tasks = _dbContext.PermissionsGranted(userId, "TASK", null, null, today)
                                  .Where(_ => _.CanExecute || _.CanDelete || _.CanInsert || _.CanUpdate);

            return from t in tasks
                   select new ValidSecurityTask
                   {
                       TaskId = (short) t.ObjectIntegerKey,
                       CanInsert = t.CanInsert,
                       CanUpdate = t.CanUpdate,
                       CanDelete = t.CanDelete,
                       CanExecute = t.CanExecute
                   };
        }

        static bool HasAccess(ValidSecurityTask task, ApplicationTaskAccessLevel level)
        {
            var hasAccess = true;

            hasAccess &= (level & ApplicationTaskAccessLevel.Create) != ApplicationTaskAccessLevel.Create ||
                         task.CanInsert;
            hasAccess &= (level & ApplicationTaskAccessLevel.Modify) != ApplicationTaskAccessLevel.Modify ||
                         task.CanUpdate;
            hasAccess &= (level & ApplicationTaskAccessLevel.Delete) != ApplicationTaskAccessLevel.Delete ||
                         task.CanDelete;
            hasAccess &= (level & ApplicationTaskAccessLevel.Execute) != ApplicationTaskAccessLevel.Execute ||
                         task.CanExecute;

            return hasAccess;
        }
    }
}
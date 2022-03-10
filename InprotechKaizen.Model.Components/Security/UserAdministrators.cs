using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public class UserAdministrators : IUserAdministrators
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _now;

        public UserAdministrators(IDbContext dbContext, Func<DateTime> now)
        {
            _dbContext = dbContext;
            _now = now;
        }

        public IEnumerable<UserEmail> Resolve(int? identityId = null)
        {
            var now = _now();

            var users = _dbContext.Set<User>();

            var externalUsers = _dbContext.Set<User>();

            var emails = _dbContext.Set<Telecommunication>();

            var permissions = _dbContext.PermissionsGrantedAll("TASK", (int) ApplicationTask.MaintainUser, null, now);

            return from p in permissions
                   join u in users on new {IdentityId = p.IdentityKey} equals new {IdentityId = u.Id} into u1
                   from u in u1.DefaultIfEmpty()
                   join ue in externalUsers on identityId equals ue.Id into u2
                   from ue in u2.DefaultIfEmpty()
                   join e in emails on u.Name.MainEmailId equals e.Id into e1
                   from e in e1.DefaultIfEmpty()
                   where p.CanInsert | p.CanUpdate | p.CanDelete &&
                         (!u.IsExternalUser ||
                          u.IsExternalUser && u.AccessAccount.Id == ue.AccessAccount.Id) && e != null
                   select new UserEmail
                          {
                              Id = u.Id,
                              Email = e.TelecomNumber
                          };
        }
    }
}
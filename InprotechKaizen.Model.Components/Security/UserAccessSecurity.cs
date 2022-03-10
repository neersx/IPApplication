using System;
using System.Collections.Generic;
using System.Data.Entity;
using System.Linq;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public interface IUserAccessSecurity
    {
        bool HasRowAccessSecurity(string accessType);
        IEnumerable<RowAccessDetail> CurrentUserRowAccessDetails(string accessType, short permissionLevel);
    }

    public class UserAccessSecurity : IUserAccessSecurity
    {
        private readonly IDbContext _dbContext;
        private readonly ISecurityContext _securityContext;

        public UserAccessSecurity(IDbContext dbContext, ISecurityContext securityContext)
        {
            _dbContext = dbContext ?? throw new ArgumentNullException(nameof(dbContext));
            _securityContext = securityContext ?? throw new ArgumentNullException(nameof(securityContext));
        }

        public bool HasRowAccessSecurity(string accessType)
        {
            if (_securityContext.User.IsExternalUser) return false;

            return _dbContext.Set<User>()
                .Include(u => u.RowAccessPermissions)
                .Include(u => u.RowAccessPermissions.Select(r => r.Details))
                .SelectMany(u => u.RowAccessPermissions)
                .SelectMany(r => r.Details.Where(d => d.AccessType == accessType)).Any();
        }

        public IEnumerable<RowAccessDetail> CurrentUserRowAccessDetails(string accessType, short permissionLevel)
        {
            var a = _securityContext.User.RowAccessPermissions;
            var userRowAccessPermissions = a.SelectMany(
                r =>
                    r.Details.Where(
                        d =>
                            d.AccessType == accessType &&
                            (d.AccessLevel & permissionLevel) == permissionLevel));

            return userRowAccessPermissions;
        }
    }
}
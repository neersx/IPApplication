using System;
using System.Data.Entity;
using System.Linq;
using System.Security.Claims;
using System.Security.Principal;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public interface IPrincipalUser
    {
        User From(IPrincipal identity, string claimType = null);
    }

    public class PrincipalUser : IPrincipalUser
    {
        readonly IDbContext _dbContext;

        public PrincipalUser(IDbContext dbContext)
        {
            if (dbContext == null) throw new ArgumentNullException(nameof(dbContext));
            _dbContext = dbContext;
        }

        public User From(IPrincipal principal, string claimType = null)
        {
            string name;
            ClaimsPrincipal claimPrincipal;
            if (!string.IsNullOrWhiteSpace(claimType) && (claimPrincipal = principal as ClaimsPrincipal) != null)
            {
                name = (claimPrincipal.Identity as ClaimsIdentity)?.FindFirst(claimType)?.Value;
            }
            else
            {
                name = principal?.Identity.Name;
            }

            if (string.IsNullOrWhiteSpace(name))
                return null;

            var userNameToMatch = new[]
            {
                name,
                name.Split('\\').Last()
            }.Distinct();

            return _dbContext.Set<User>()
                             .Include(u => u.Name)
                             .FirstOrDefault(u => userNameToMatch.Contains(u.UserName));
        }
    }
}
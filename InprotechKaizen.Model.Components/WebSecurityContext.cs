using System;
using System.Threading;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Security.ExternalApplications;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components
{
    public class WebSecurityContext : ISecurityContext
    {
        readonly ILifetimeScopeCache _perLifetime;
        readonly IPrincipalUser _principalUser;

        public WebSecurityContext(IPrincipalUser principalUser, ILifetimeScopeCache perLifetime)
        {
            if (principalUser == null) throw new ArgumentNullException(nameof(principalUser));
            if (perLifetime == null) throw new ArgumentNullException(nameof(perLifetime));

            _principalUser = principalUser;
            _perLifetime = perLifetime;
        }

        public User User
        {
            get
            {
                var externalApplicationPrincipal = Thread.CurrentPrincipal as ExternalApplicationPrincipal;

                if (externalApplicationPrincipal != null && !externalApplicationPrincipal.HasUserContext)
                    return null;

                return _perLifetime.GetOrAdd(this, 0, x => _principalUser.From(Thread.CurrentPrincipal));
            }
        }

        public int IdentityId => User.Id;
    }
}
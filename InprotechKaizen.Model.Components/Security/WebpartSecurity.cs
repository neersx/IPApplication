using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Security
{

    public class WebPartSecurity : IWebPartSecurity
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly ILifetimeScopeCache _perLifetime;
        readonly Func<DateTime> _clock;

        public WebPartSecurity(IDbContext dbContext, ISecurityContext securityContext, ILifetimeScopeCache perLifetime, Func<DateTime> clock)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _perLifetime = perLifetime;
            _clock = clock;
        }

        IEnumerable<WebPartAccess> ListAvailableWebParts()
        {
            return _perLifetime.GetOrAdd(this, 0, x => AvailableWebParts().ToArray());
        }

        IQueryable<WebPartAccess> AvailableWebParts()
        {
            var today = _clock().Date;

            var webParts = _dbContext.PermissionsGranted(_securityContext.User.Id, "MODULE", null, null, today)
                                     .Where(_ => _.CanSelect);

            return from t in webParts
                   select new WebPartAccess
                   {
                       WebPartId = (short)t.ObjectIntegerKey,
                       CanSelect = t.CanSelect
                   };
        }

        public bool HasAccessToWebPart(ApplicationWebPart webPart)
        {
            return ListAvailableWebParts().Any(v => v.WebPartId == (short)webPart);
        }
    }
}

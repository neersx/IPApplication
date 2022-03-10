using System;
using System.Globalization;
using System.Security.Claims;
using Inprotech.Infrastructure.Security;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Names;

namespace InprotechKaizen.Model.Components.Security
{
    public class CurrentWebUser : ICurrentUser
    {
        readonly ISecurityContext _securityContext;

        public CurrentWebUser(ISecurityContext securityContext)
        {
            if (securityContext == null) throw new ArgumentNullException("securityContext");
            _securityContext = securityContext;
        }

        public ClaimsIdentity Identity
        {
            get
            {
                return _securityContext.User == null
                    ? null
                    : new ClaimsIdentity(
                                         new[]
                                         {
                                             new Claim(ClaimTypes.Name, _securityContext.User.UserName),
                                             new Claim(CustomClaimTypes.NameId, _securityContext.User.NameId.ToString()),
                                             new Claim(CustomClaimTypes.DisplayName, _securityContext.User.Name.Formatted()),
                                             new Claim(CustomClaimTypes.Id, _securityContext.User.Id.ToString(CultureInfo.InvariantCulture)),
                                             new Claim(CustomClaimTypes.IsExternalUser, _securityContext.User.IsExternalUser.ToString())
                                         });
            }
        }
    }
}
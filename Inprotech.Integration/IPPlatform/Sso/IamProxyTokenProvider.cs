using System.Diagnostics.CodeAnalysis;
using System.Security.Claims;
using CPA.IAM.Proxy;
using CPA.SingleSignOn.Client;
using CPA.SingleSignOn.Client.Services;

namespace Inprotech.Integration.IPPlatform.Sso
{
    [SuppressMessage("Microsoft.Performance", "CA1812:AvoidUninstantiatedInternalClasses")]
    public class IamProxyTokenProvider : ITokenProvider
    {
        readonly ITokenManagementService _tokenManagement;

        public IamProxyTokenProvider(ITokenManagementService tms)
        {
            _tokenManagement = tms;
        }

        public string GetClientAccessToken()
        {
            return _tokenManagement.GetForClient().AccessToken;
        }

        public string GetUserAccessToken()
        {
            var claimsId = ClaimsPrincipal.Current.Identity as ClaimsIdentity;
            return claimsId.GetAccessToken();
        }
    }
}
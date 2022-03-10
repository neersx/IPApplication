using CPA.IAM.Proxy;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Integration.IPPlatform.Sso
{
    public interface IAccessTokenProvider
    {
        string GetAccessToken();
    }

    public class UserAccessToken : IAccessTokenCache, IAccessTokenProvider
    {
        string _accessToken;

        public void Store(string accessToken)
        {
            _accessToken = accessToken;
        }

        public string GetAccessToken()
        {
            return _accessToken;
        }
    }

    public class ApplicationAccessToken : IAccessTokenProvider
    {
        readonly ITokenProvider _tokenProvider;

        public ApplicationAccessToken(ITokenProvider tokenProvider)
        {
            _tokenProvider = tokenProvider;
        }

        public string GetAccessToken()
        {
            return _tokenProvider.GetClientAccessToken();
        }
    }
}
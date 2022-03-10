using System;
using CPA.SingleSignOn.Client.Models;
using CPA.SingleSignOn.Client.Services;
using Inprotech.Infrastructure.Security;

namespace Inprotech.Web.Security
{
    class TokenRefresh : ITokenRefresh
    {
        readonly IAdfsAuthenticator _adfsAuthenticator;
        readonly ITokenValidationService _tokenValidationService;
        readonly ITokenManagementService _tokenManagement;

        public TokenRefresh(IAdfsAuthenticator adfsAuthenticator, ITokenValidationService tokenValidationService, ITokenManagementService tokenManagement)
        {
            _adfsAuthenticator = adfsAuthenticator;
            _tokenValidationService = tokenValidationService;
            _tokenManagement = tokenManagement;
        }

        public (string AccessToken, string RefreshToken) Refresh(string accessToken, string refreshToken, string authMode)
        {

            if (authMode == AuthenticationModeKeys.Adfs)
                return ToResponse(_adfsAuthenticator.Refresh(refreshToken));

            if(authMode!=AuthenticationModeKeys.Sso)
                throw new Exception("sso-not-applicable");

            if (SafeValidateAccessToken(accessToken))
            {
                return ToResponse(new SSOProviderResponse
                {
                    AccessToken = accessToken,
                    RefreshToken = refreshToken
                });
            }

            return ToResponse(_tokenManagement.Refresh(refreshToken));
        }

        bool SafeValidateAccessToken(string accessToken)
        {
            try
            {
                _tokenValidationService.ValidateToPrincipal(accessToken);
                return true;
            }
            catch
            {
                return false;
            }
        }

        (string AccessToken, string RefreshToken) ToResponse(SSOProviderResponse response)
        {
            return (response.AccessToken, response.RefreshToken);
        }
    }
}
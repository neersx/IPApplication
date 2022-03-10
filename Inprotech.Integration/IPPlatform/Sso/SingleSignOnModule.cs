using System;
using System.Diagnostics.CodeAnalysis;
using System.IdentityModel.Tokens;
using System.Security.Claims;
using Autofac;
using CPA.IAM.Proxy;
using CPA.SingleSignOn.Autofac.Modules;
using CPA.SingleSignOn.Client.Autofac.Modules;
using CPA.SingleSignOn.Client.Models;
using CPA.SingleSignOn.Client.Services;

namespace Inprotech.Integration.IPPlatform.Sso
{
    [SuppressMessage("Microsoft.Naming", "CA1726:UsePreferredTerms", MessageId = "SignOn")]
    public static class SingleSignOnModule
    {
        public static void Assemble(ContainerBuilder builder)
        {
            builder.RegisterModule<SSOClientModule>();
            builder.RegisterModule<SSOModule>();
            builder.RegisterModule<IAMProxyModule>();
            builder.RegisterType<IamProxyTokenProvider>().As<ITokenProvider>();
        }

        public static void AssembleFake(ContainerBuilder builder)
        {
            builder.RegisterType<FakeTokenManagementService>().AsImplementedInterfaces();
            builder.RegisterType<FakeTokenValidationService>().AsImplementedInterfaces();
        }
    }

    [SuppressMessage("Microsoft.Performance", "CA1812:AvoidUninstantiatedInternalClasses")]
    public class FakeTokenManagementService : ITokenManagementService
    {
        public string GetAuthorizationUrl()
        {
            throw new NotImplementedException();
        }

        public string GetLoginUrl()
        {
            throw new NotImplementedException();
        }

        public string GetLogoutUrl()
        {
            throw new NotImplementedException();
        }

        public SSOProviderResponse GetByCode(string code, string redirectUri)
        {
            throw new NotImplementedException();
        }

        public SSOProviderResponse GetForClient()
        {
            throw new NotImplementedException();
        }

        public SSOProviderResponse Refresh(string refreshToken)
        {
            throw new NotImplementedException();
        }

        public void Revoke(string accessToken, string sessionId)
        {
            throw new NotImplementedException();
        }
    }

    [SuppressMessage("Microsoft.Performance", "CA1812:AvoidUninstantiatedInternalClasses")]
    public class FakeTokenValidationService : ITokenValidationService
    {
        public TokenValidationParameters GetTokenValidationParameters()
        {
            throw new NotImplementedException();
        }

        public ClaimsPrincipal ValidateToPrincipal(string accessToken, bool validateScope = true)
        {
            throw new NotImplementedException();
        }
    }
}
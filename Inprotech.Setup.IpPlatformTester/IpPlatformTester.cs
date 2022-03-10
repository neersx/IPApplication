using System;
using Autofac;
using CPA.IAM.Proxy;
using CPA.SingleSignOn.Autofac.Modules;
using CPA.SingleSignOn.Client.Services;

namespace Inprotech.Setup.IpPlatformTester
{
    class IpPlatformTester
    {
        readonly ITokenProvider _tokenProvider;

        static IContainer BuildContainer()
        {
            var builder = new ContainerBuilder();
            builder.RegisterModule<SSOModule>();
            builder.RegisterType<TokenProvider>().As<ITokenProvider>();

            return builder.Build();
        }

        public IpPlatformTester()
        {
            var container = BuildContainer();
            _tokenProvider = container.Resolve<ITokenProvider>();
        }

        public bool Test()
        {
            return TestTokenGeneration();
        }

        bool TestTokenGeneration()
        {
            try
            {
                var token = _tokenProvider.GetClientAccessToken();
                if (string.IsNullOrWhiteSpace(token))
                {
                    Console.WriteLine("error-token-generation");
                    return false;
                }
            }
            catch (Exception ex)
            {
                Console.Error.WriteLine(ex.Message);
                Console.WriteLine("error-token-generation");
                Environment.Exit(-1);
            }
            return true;
        }
    }

    class TokenProvider : ITokenProvider
    { 
        readonly ITokenManagementService _tokenManagement;

        public TokenProvider(ITokenManagementService tokenManagementService)
        {
            _tokenManagement = tokenManagementService;
        }

        public string GetClientAccessToken()
        {
            return _tokenManagement.GetForClient().AccessToken;
        }

        public string GetUserAccessToken()
        {
            throw new NotImplementedException();
        }
    }
}
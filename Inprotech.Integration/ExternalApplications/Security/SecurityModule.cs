using Autofac;
using Inprotech.Infrastructure.Security.ExternalApplications;
using Inprotech.Integration.ExternalApplications.Security.Authentication.ApiKey;
using Inprotech.Integration.ExternalApplications.Security.Authentication.User;

namespace Inprotech.Integration.ExternalApplications.Security
{
    public class SecurityModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<UserValidator>().As<IUserValidator>();
            builder.RegisterType<ApiKeyValidator>().As<IApiKeyValidator>();
        }
    }
}
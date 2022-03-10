using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Security.Licensing;
using Microsoft.Owin.Security.Cookies;

namespace Inprotech.Infrastructure.Security
{
    public class SecurityModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<CryptoService>().As<ICryptoService>();
            builder.RegisterType<LicenseAuthorization>().As<ILicenseAuthorization>();

            builder.RegisterType<FormsAuthHandler>().AsSelf();
            builder.Register(
                             c =>
                             {
                                 var authSettings = c.Resolve<IAuthSettings>();
                                 return new CookieAuthenticationOptions
                                 {
                                     CookieName = authSettings.SessionCookieName,
                                     CookiePath = authSettings.SessionCookiePath,
                                     CookieDomain = authSettings.SessionCookieDomain
                                 };
                             });

            builder.RegisterType<IpPlatformSession>().As<IIpPlatformSession>();
        }
    }
}
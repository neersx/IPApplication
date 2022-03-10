using Autofac;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration.IPPlatform.FileApp.Builders;
using Inprotech.Web.Security.ResetPassword;
using Inprotech.Web.Security.TwoFactorAuth;

namespace Inprotech.Web.Security
{
    public class SecurityModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<TwoFactorAuthVerify>().As<ITwoFactorAuthVerify>();
            builder.RegisterType<TwoFactorApp>()
                   .Keyed<ITwoFactorAuth>(TwoFactorAuthVerify.App);
            builder.RegisterType<TwoFactorEmail>()
                   .Keyed<ITwoFactorAuth>(TwoFactorAuthVerify.Email);
            builder.RegisterType<TwoFactorApp>().As<ITwoFactorApp>();
            builder.RegisterType<TwoFactorTotp>().As<ITwoFactorTotp>();
            builder.RegisterType<UserValidation>().As<IUserValidation>();
            builder.RegisterType<LicenseAuthorization>().As<ILicenseAuthorization>();
            builder.RegisterType<ConfiguredAccess>().As<IConfiguredAccess>();
            builder.RegisterType<AdfsAuthenticator>().As<IAdfsAuthenticator>();
            builder.RegisterType<AdfsSettingsResolver>().As<IAdfsSettingsResolver>();
            builder.RegisterType<TokenExtender>().As<ITokenExtender>();
            builder.RegisterType<TokenRefresh>().As<ITokenRefresh>();
            builder.RegisterType<ResetPasswordHelper>().As<IResetPasswordHelper>();
            builder.RegisterType<PasswordManagementController>().As<IPasswordManagementController>();
            builder.RegisterType<PasswordPolicy>().As<IPasswordPolicy>();
            builder.RegisterType<PasswordVerifier>().As<IPasswordVerifier>();

        }
    }
}
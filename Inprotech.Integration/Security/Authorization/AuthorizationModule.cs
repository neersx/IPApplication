using Autofac;
using Inprotech.Infrastructure.Notifications;

namespace Inprotech.Integration.Security.Authorization
{
    public class AuthorizationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ExpiringLicenses>().AsSelf();
            builder.RegisterType<ExpiringPassword>().AsSelf();

            builder.RegisterType<EmailNotification>().As<IEmailNotification>();
            builder.RegisterType<PopupNotification>().As<IPopupNotification>();

            builder.RegisterType<UserAccountLocked>().AsSelf();
            builder.RegisterType<UserAccountLockedHandler>().AsImplementedInterfaces();
            builder.RegisterType<UserAccountLockedHandlerPerformJob>().AsImplementedInterfaces();

            builder.RegisterType<UserTwoFactorEmailRequired>().AsSelf();
            builder.RegisterType<UserTwoFactorEmailRequiredHandler>().AsImplementedInterfaces();
            builder.RegisterType<UserTwoFactorEmailRequiredHandlerPerformJob>().AsImplementedInterfaces();
            
            builder.RegisterType<AbsoluteLogout>().AsSelf();
            builder.RegisterType<ExpiredAccessTokens>().AsSelf();

            builder.RegisterType<UserResetPasswordEmailRequired>().AsSelf();
            builder.RegisterType<UserResetPasswordEmailRequiredHandler>().AsImplementedInterfaces();
            builder.RegisterType<UserResetPasswordEmailRequiredHandlerPerformJob>().AsImplementedInterfaces();
        }
    }
}
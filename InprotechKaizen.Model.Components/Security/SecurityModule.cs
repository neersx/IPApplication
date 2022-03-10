using Autofac;
using Inprotech.Contracts.Messages.Security;
using Inprotech.Infrastructure.Caching;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Security.Licensing;
using InprotechKaizen.Model.Security;

namespace InprotechKaizen.Model.Components.Security
{
    public class SecurityModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SessionTasksProvider>().AsImplementedInterfaces();
            builder.RegisterType<TaskAuthorisation>().As<ITaskAuthorisation>();
            builder.RegisterType<TaskSecurityProviderCache>()
                   .As<ITaskSecurityProviderCache>()
                   .As<IDisableApplicationCache>()
                   .As<IHandle<UserSessionStartedMessage>>()
                   .As<IHandle<UserSessionInvalidatedMessage>>()
                   .As<IHandle<UserSessionsInvalidatedMessage>>();

            builder.RegisterType<SubjectSecurityProviderCache>()
                   .As<ISubjectSecurityProviderCache>()
                   .As<IDisableApplicationCache>()
                   .As<IHandle<UserSessionStartedMessage>>()
                   .As<IHandle<UserSessionInvalidatedMessage>>()
                   .As<IHandle<UserSessionsInvalidatedMessage>>();

            builder.RegisterType<AuthorizationResultCache>()
                   .As<IAuthorizationResultCache>()
                   .As<IDisableApplicationCache>()
                   .As<IHandle<UserSessionStartedMessage>>()
                   .As<IHandle<UserSessionInvalidatedMessage>>()
                   .As<IHandle<UserSessionsInvalidatedMessage>>();
            
            builder.RegisterType<CurrentWebUser>().As<ICurrentUser>();
            builder.RegisterType<CurrentPrincipal>().As<ICurrentPrincipal>();
            builder.RegisterType<UserAccessSecurity>().As<IUserAccessSecurity>();
            builder.RegisterType<PrincipalUser>().As<IPrincipalUser>();
            builder.RegisterType<LicenseSecurityProvider>().As<ILicenseSecurityProvider>();
            builder.RegisterType<Licenses>().As<ILicenses>();
            builder.RegisterType<UserAdministrators>().As<IUserAdministrators>();
            builder.RegisterType<UserIdentityAccessManager>().As<IUserIdentityAccessManager>();
            builder.RegisterType<UserFilteredTypes>().As<IUserFilteredTypes>();
            builder.RegisterType<CaseAuthorization>().As<ICaseAuthorization>();
            builder.RegisterType<NameAuthorization>().As<INameAuthorization>();
            builder.RegisterType<SubjectSecurityProvider>().As<ISubjectSecurityProvider>();
            builder.RegisterType<WebPartSecurity>().As<IWebPartSecurity>();
            builder.RegisterType<AuthorizeCriteriaPurposeCodeTaskSecurity>().As<IAuthorizeCriteriaPurposeCodeTaskSecurity>();
            builder.RegisterType<UserPasswordExpiryValidator>().As<IUserPasswordExpiryValidator>();
            builder.RegisterType<FunctionSecurityProvider>().As<IFunctionSecurityProvider>();
            builder.RegisterType<ClassicUserResolver>().As<IClassicUserResolver>();
        }
    }
}
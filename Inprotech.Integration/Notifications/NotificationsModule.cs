using Autofac;

namespace Inprotech.Integration.Notifications
{
    public class NotificationsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<CaseDetailsLoader>().As<ICaseDetailsLoader>();
            builder.RegisterType<NotificationResponse>().As<INotificationResponse>();
            builder.RegisterType<CaseIdsResolver>().As<ICaseIdsResolver>();
            builder.RegisterType<CaseDetailsWithSecurity>().As<ICaseDetailsWithSecurity>();
            builder.RegisterType<ExternalSystems>().As<IExternalSystems>();
            builder.RegisterType<RequestedCases>().As<IRequestedCases>();
            builder.RegisterType<MatchingCases>().As<IMatchingCases>();
            builder.RegisterType<CaseNotifications>().As<ICaseNotifications>();
            builder.RegisterType<CpaXmlProvider>().As<ICpaXmlProvider>();
            builder.RegisterType<SourceCaseRejection>().As<ISourceCaseRejection>();

            builder.RegisterType<CaseNotificationsForCases>().As<ICaseNotificationsForCases>();
            builder.RegisterType<CaseNotificationsForExecution>().As<ICaseNotificationsForExecution>();
            builder.RegisterType<CaseNotificationsLastChanged>().As<ICaseNotificationsLastChanged>();

            builder.RegisterType<CaseNotificationsForDuplicates>().As<ICaseNotificationsForDuplicates>();
            builder.RegisterType<CaseNotificationsForDuplicates>().As<CaseNotificationsForDuplicates>();
            builder.RegisterType<InnographyDuplicateCasesFinder>().Keyed<IDuplicateCasesFinder>(DataSourceType.IpOneData);
        }
    }
}
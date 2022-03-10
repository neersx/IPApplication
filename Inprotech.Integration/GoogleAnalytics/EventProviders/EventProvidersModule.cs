using Autofac;

namespace Inprotech.Integration.GoogleAnalytics.EventProviders
{
    public class EventProvidersModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<RoleUsersProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<RolesTasksSubjectsAndModulesProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<LanguageSettingsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<UsersProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<PriorArtSearchAnalyticsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<SchemaMappingGeneratedAnalyticsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<SystemVersionProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<InstallationDatesProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<IntegrationsStatusProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<LawUpdateAnalyticsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<GeneralStatisticsAnalyticsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<SiteControlAnalyticsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<EfilingTransactionsAnalyticsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<AuthenticationTypesAnalyticsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<PriorArtImportAnalyticsEventProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<InprodocGenerationAnalyticsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<TaskPlannerAnalyticsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<ModuleUsageAnalyticsProvider>().As<IAnalyticsEventProvider>();
            builder.RegisterType<TimeRecordingAnalyticsProvider>().As<IAnalyticsEventProvider>();
        }
    }
}
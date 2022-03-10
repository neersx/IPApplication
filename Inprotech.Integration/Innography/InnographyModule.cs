using Autofac;
using Inprotech.Integration.Notifications;
using Inprotech.Integration.PostSourceUpdate;
using InprotechKaizen.Model.Components.Integration.DataVerification;

namespace Inprotech.Integration.Innography
{
    public class InnographyModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<InnographyRequestMessage>().AsSelf();
            builder.RegisterType<InnographyClient>().As<IInnographyClient>();

            builder.RegisterType<InnographySettingsResolver>().As<IInnographySettingsResolver>();
            builder.RegisterType<InnographySettingsPersister>().As<IInnographySettingsPersister>();

            builder.RegisterType<InnographyIdFromCpaXml>().As<IInnographyIdFromCpaXml>();
            builder.RegisterType<InnographyIdUpdater>().As<IInnographyIdUpdater>();

            builder.RegisterType<LinkConfirmedHandler>()
                   .Keyed<ISourceNotificationReviewedHandler>(DataSourceType.IpOneData)
                   .Keyed<ISourceUpdatedHandler>(DataSourceType.IpOneData);

            builder.RegisterType<SourceCaseMatchRejectable>()
                   .Keyed<ISourceCaseMatchRejectable>(DataSourceType.IpOneData);

            builder.RegisterType<PatentScoutUrlFormatter>().As<IPatentScoutUrlFormatter>();
            builder.RegisterType<CaseComparisonResultPatentScoutUrlFormatter>()
                   .Keyed<ISourceCaseUrlFormatter>(DataSourceType.IpOneData);

            builder.RegisterType<ParentRelatedCases>().As<IParentRelatedCases>();
        }
    }
}
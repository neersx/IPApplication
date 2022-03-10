using Autofac;
using Inprotech.Integration;
using Inprotech.IntegrationServer.PtoAccess.Activities;

namespace Inprotech.IntegrationServer.PtoAccess.Innography.Activities
{
    public class ActivitiesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<DueSchedule>().AsSelf();
            builder.RegisterType<EnsureScheduleValid>().AsSelf();
            builder.RegisterType<DownloadedCase>().As<IDownloadedCase>();
            builder.RegisterType<VerificationRequired>().AsSelf();
            builder.RegisterType<DownloadRequired>().AsSelf();
            builder.RegisterType<ResolveEligibleCases>().AsSelf();
            builder.RegisterType<DetailsAvailable>()
                   .As<IDetailsAvailable>()
                   .AsSelf();

            builder.RegisterType<DetailsUnavailable>().AsSelf();

            builder.RegisterType<VersionableContentResolver>()
                   .Keyed<IVersionableContentResolver>(DataSourceType.IpOneData);
            
            builder.RegisterType<NotificationReviewStatusModifier>()
                   .Keyed<ISourceNotificationModifier>(DataSourceType.IpOneData);

            builder.RegisterType<DownloadCaseDispatcher>().As<IDownloadCaseDispatcher>();
            builder.RegisterType<TypeCodeResolver>().As<ITypeCodeResolver>();
            builder.RegisterType<CountryCodeResolver>().As<ICountryCodeResolver>();
            builder.RegisterType<RelationshipCodeResolver>().As<IRelationshipCodeResolver>();
            builder.RegisterType<MappedParentRelatedCasesResolver>().As<IMappedParentRelatedCasesResolver>();
            builder.RegisterType<PatentsDownload>().As<IPatentsDownload>();
            builder.RegisterType<TrademarksDownload>().As<ITrademarksDownload>();
            builder.RegisterType<PatentsVerification>().As<IPatentsVerification>();
            builder.RegisterType<TrademarksVerification>().As<ITrademarksVerification>();
            builder.RegisterType<InnographyTrademarksImage>().As<IInnographyTrademarksImage>();
        }
    }
}
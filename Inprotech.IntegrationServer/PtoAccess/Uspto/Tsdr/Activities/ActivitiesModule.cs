using Autofac;

namespace Inprotech.IntegrationServer.PtoAccess.Uspto.Tsdr.Activities
{
    public class ActivitiesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
     
            builder.RegisterType<DueSchedule>().AsSelf();
            builder.RegisterType<ResolveEligibleCases>().AsSelf();
            builder.RegisterType<CaseRequired>().AsSelf();
            builder.RegisterType<DetailsAvailable>().AsSelf();
            builder.RegisterType<EnsureScheduleValid>().AsSelf();
            builder.RegisterType<DocumentList>().AsSelf();
            builder.RegisterType<DownloadDocument>().AsSelf();
            builder.RegisterType<DownloadRequired>().AsSelf();
        }
    }
}
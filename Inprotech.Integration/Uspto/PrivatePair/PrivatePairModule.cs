using Autofac;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;

namespace Inprotech.Integration.Uspto.PrivatePair
{
    public class PrivatePairModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SponsorshipProcessor>().As<ISponsorshipProcessor>();

            builder.RegisterType<UsptoSponsorshipScheduleMessages>()
                   .Keyed<IScheduleMessages>(DataSourceType.UsptoPrivatePair);
        }
    }
}
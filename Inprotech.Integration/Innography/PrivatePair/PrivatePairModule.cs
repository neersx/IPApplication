using Autofac;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Schedules;

namespace Inprotech.Integration.Innography.PrivatePair
{
    public class PrivatePairModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<CryptographyService>().As<ICryptographyService>();
            builder.RegisterType<PrivatePairService>().As<IPrivatePairService>();

            builder.RegisterType<InnographyPrivatePairSettings>().As<IInnographyPrivatePairSettings>();

            builder.RegisterType<UsptoSponsorshipScheduleMessages>()
                   .Keyed<IScheduleMessages>(DataSourceType.UsptoPrivatePair);

            builder.RegisterType<InnographyPrivatePairSettingsValidator>().AsImplementedInterfaces();
        }
    }
}
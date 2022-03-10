using Autofac;
using Inprotech.Contracts;
using Inprotech.Infrastructure.DateTimeHelpers;

namespace Inprotech.Integration.DataSources
{
    public class DataSourcesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<AvailableDataSources>().As<IAvailableDataSources>();
            builder.RegisterType<DataSourceAvailabilityResolver>().As<IAvailabilityResolver>();
            builder.RegisterType<TimeZoneService>().As<ITimeZoneService>();
            builder.RegisterType<AvailabilityCalculator>().As<IAvailabilityCalculator>();
        }
    }
}
using Autofac;

namespace InprotechKaizen.Model.Components.Policing.Forecast
{
    public class ForecastModule : Autofac.Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<PolicingServerSps>().AsImplementedInterfaces();
            builder.RegisterType<PolicingRequestSps>().AsImplementedInterfaces();
        }
    }
}
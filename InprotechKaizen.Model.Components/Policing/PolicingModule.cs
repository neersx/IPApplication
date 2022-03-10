using Autofac;
using InprotechKaizen.Model.Components.Policing.Monitoring;

namespace InprotechKaizen.Model.Components.Policing
{
    public class PolicingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<SummaryReader>().As<ISummaryReader>();
            builder.RegisterType<LogReader>().As<ILogReader>();
            builder.RegisterType<UpdatePolicingRequest>().As<IUpdatePolicingRequest>();
            builder.RegisterType<PolicingEngine>().As<IPolicingEngine>();
        }
    }
}

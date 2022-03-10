using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Events
{
    public class EventsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<OccurredEvents>().As<IOccurredEvents>();
            builder.RegisterType<ValidEventResolver>().As<IValidEventResolver>();
            builder.RegisterType<ValidEventsResolver>().As<IValidEventsResolver>();
        }
    }
}
using Autofac;
using InprotechKaizen.Model.Integration.PtoAccess;

namespace InprotechKaizen.Model.Components.Integration.PtoAccess
{
    public class PtoAccessModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<FilterDataExtractCases>().As<IFilterDataExtractCases>();
            builder.RegisterType<EventMappingsResolver>().As<IEventMappingsResolver>();
        }
    }
}
using Autofac;

namespace InprotechKaizen.Model.Components.Cases.Comparison.DataMapping
{
    public class DataMappingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<MappingResolver>().As<IMappingResolver>();
        }
    }
}

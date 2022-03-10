using Autofac;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Processor.RunMappers
{
    public class RunMapperModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<RunStoredProcedureMapper>().AsSelf();
            builder.RegisterType<RunQueryMapper>().AsSelf();
        }
    }
}

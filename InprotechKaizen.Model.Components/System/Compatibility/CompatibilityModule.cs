using Autofac;

namespace InprotechKaizen.Model.Components.System.Compatibility
{
    public class CompatibilityModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<StoredProcedureParameterHandler>().As<IStoredProcedureParameterHandler>();
        }
    }
}

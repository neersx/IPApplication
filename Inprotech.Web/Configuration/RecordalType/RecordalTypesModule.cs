using Autofac;

namespace Inprotech.Web.Configuration.RecordalType
{
    public class RecordalTypesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<RecordalTypes>().As<IRecordalTypes>();
        }
    }
}

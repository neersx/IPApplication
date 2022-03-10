using Autofac;

namespace Inprotech.Web.Dates
{
    public class DatesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<AdHocDates>().As<IAdHocDates>();
        }
    }
}

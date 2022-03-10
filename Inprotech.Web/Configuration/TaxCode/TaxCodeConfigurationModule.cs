using Autofac;

namespace Inprotech.Web.Configuration.TaxCode
{
    public class TaxCodeConfigurationModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<TaxCodeSearchService>().As<ITaxCodeSearchService>();
            builder.RegisterType<TaxCodeMaintenanceService>().As<ITaxCodeMaintenanceService>();
            builder.RegisterType<TaxCodesValidator>().As<ITaxCodesValidator>();
            builder.RegisterType<TaxCodeDetailService>().As<ITaxCodeDetailService>();
        }
    }
}
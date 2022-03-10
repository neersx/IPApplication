using Autofac;

namespace Inprotech.Web.Search.CaseSupportData
{
    public class CaseSupportDataModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<Offices>().As<IOffices>();
            builder.RegisterType<RenewalStatuses>().As<IRenewalStatuses>();
            builder.RegisterType<TypeOfMark>().As<ITypeOfMark>();
        }
    }
}

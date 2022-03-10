using Autofac;
using Inprotech.Infrastructure.ResponseShaping.Picklists;

namespace Inprotech.Web.Picklists.ResponseShaping
{
    public class ResponseShapingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<Maintainability>().As<IPicklistPayloadData>();
            builder.RegisterType<Columns>().As<IPicklistPayloadData>();
            builder.RegisterType<DuplicateFromServer>().As<IPicklistPayloadData>();
            builder.RegisterType<MaintainabilityActions>().As<IPicklistPayloadData>();
        }
    }
}

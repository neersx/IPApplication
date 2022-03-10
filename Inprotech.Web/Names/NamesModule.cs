using Autofac;
using Inprotech.Web.Attachment;
using Inprotech.Web.ContactActivities;
using Inprotech.Web.Names.Details;

namespace Inprotech.Web.Names
{
    public class NamesModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<NameViewResolver>().As<INameViewResolver>();
            builder.RegisterType<SupplierDetailsMaintenance>().As<ISupplierDetailsMaintenance>();
            builder.RegisterType<TrustAccountingResolver>().As<ITrustAccountingResolver>();
            builder.RegisterType<NameActivityAttachmentMaintenance>().As<IActivityAttachmentMaintenance>().Keyed<IActivityAttachmentMaintenance>(AttachmentFor.Name).WithParameter("attachmentFor", AttachmentFor.Name);
        }
    }
}

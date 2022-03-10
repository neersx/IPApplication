using Autofac;
using Inprotech.Web.Maintenance.Topics;
using InprotechKaizen.Model.Names;

namespace Inprotech.Web.Names.Maintenance.Validators
{
    class NameMaintenanceValidatorsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SupplierDetailsTopicValidator>()
                   .Keyed<ITopicValidator<Name>>(TopicGroups.Names + KnownNameMaintenanceTopics.SupplierDetails);
        }
    }
}

using Autofac;
using Inprotech.Web.Maintenance.Topics;

namespace Inprotech.Web.Names.Maintenance.Updaters
{
    public class NameMaintenanceUpdateDataModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<SupplierDetailsTopicDataUpdater>()
                   .Keyed<ITopicDataUpdater<InprotechKaizen.Model.Names.Name>>(TopicGroups.Names + KnownNameMaintenanceTopics.SupplierDetails);
        }
    }
}

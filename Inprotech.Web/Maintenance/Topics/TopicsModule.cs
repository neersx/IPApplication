using Autofac;
using Inprotech.Web.Cases.Maintenance;
using Inprotech.Web.Names.Maintenance;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Names;

namespace Inprotech.Web.Maintenance.Topics
{
    public class TopicsModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            builder.RegisterType<CaseTopicsUpdater>().As<ITopicsUpdater<Case>>();
            builder.RegisterType<NameTopicsUpdater>().As<ITopicsUpdater<Name>>();
        }
    }
}
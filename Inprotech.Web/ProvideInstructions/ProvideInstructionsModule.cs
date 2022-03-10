using Autofac;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.CaseSupportData;
using Inprotech.Web.Search;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.ProvideInstructions
{
    public class ProcessingModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);
            builder.RegisterType<ProvideInstructionFilterCriteriaBuilder>().As<IProvideInstructionFilterCriteriaBuilder>();
            builder.RegisterType<ProvideInstructionManager>().As<IProvideInstructionManager>();
            builder.RegisterType<ProvideInstructionsXmlFilterCriteriaBuilder>()
                   .Keyed<IXmlFilterCriteriaBuilder>(QueryContext.CaseInstructionSearchInternal);
            builder.RegisterType<ProvideInstructionsFilterableColumnsMap>()
                   .Keyed<IFilterableColumnsMap>(QueryContext.CaseInstructionSearchInternal);
            builder.RegisterType<EventNotesResolver>().As<IEventNotesResolver>();
            
        }
    }
}

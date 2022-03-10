using Autofac;
using Inprotech.Infrastructure.Web;
using Inprotech.Web.Search.Export;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search.Case
{
    public class CaseModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            base.Load(builder);

            builder.RegisterType<ListPrograms>().As<IListPrograms>();
            builder.RegisterType<CpaXmlExporter>().As<ICpaXmlExporter>();

            builder.RegisterType<CaseXmlFilterCriteriaBuilder>()
                   .Keyed<IXmlFilterCriteriaBuilder>(QueryContext.CaseSearch)
                   .Keyed<IXmlFilterCriteriaBuilder>(QueryContext.CaseSearchExternal);

            builder.RegisterType<FilterableColumnsMap>()
                   .Keyed<IFilterableColumnsMap>(QueryContext.CaseSearch)
                   .Keyed<IFilterableColumnsMap>(QueryContext.CaseSearchExternal);
        }
    }
}
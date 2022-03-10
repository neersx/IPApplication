using Autofac;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Web.ContentManagement;
using Inprotech.Web.Reports;
using Inprotech.Web.Search.Case;
using Inprotech.Web.Search.Case.SanityCheck;
using Inprotech.Web.Search.Columns;
using Inprotech.Web.Search.Export;
using Inprotech.Web.Search.Name;
using Inprotech.Web.Search.Roles;
using Inprotech.Web.Search.WipOverview;
using InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search;
using InprotechKaizen.Model.Components.Queries;

namespace Inprotech.Web.Search
{
    public class SearchModule : Module
    {
        protected override void Load(ContainerBuilder builder)
        {
            //Business
            builder.RegisterType<SearchTypeParser>().As<ISearchTypeParser>();
            builder.RegisterType<SavedQueries>().As<ISavedQueries>();
            builder.RegisterType<CaseSearchService>().As<ICaseSearchService>();
            builder.RegisterType<NameSearchService>().As<INameSearchService>();
            builder.RegisterType<SearchPresentationService>().As<ISearchPresentationService>();
            builder.RegisterType<SavedSearchService>().As<ISavedSearchService>();
            builder.RegisterType<SearchExportService>().As<ISearchExportService>();
            builder.RegisterType<SanityCheckService>().As<ISanityCheckService>();
            builder.RegisterType<SearchService>().As<ISearchService>();
            builder.RegisterType<Search>().As<ISearch>();
            builder.RegisterType<XmlFilterCriteriaBuilderResolver>().As<IXmlFilterCriteriaBuilderResolver>();
            builder.RegisterType<SearchMaintainabilityResolver>().As<ISearchMaintainabilityResolver>();
            builder.RegisterType<SearchColumnMaintainabilityResolver>().As<ISearchColumnMaintainabilityResolver>();
            builder.RegisterType<QueryContextTypeResolver>().As<IQueryContextTypeResolver>();
            builder.RegisterType<FilterableColumnsMapResolver>().As<IFilterableColumnsMapResolver>();
            builder.RegisterType<SavedSearchValidator>().As<ISavedSearchValidator>();
            builder.RegisterType<SearchResultSelector>().As<ISearchResultSelector>();
            builder.RegisterType<RoleSearchService>().As<IRoleSearchService>();
            builder.RegisterType<RoleDetailsService>().As<IRoleDetailsService>();
            builder.RegisterType<RoleMaintenanceService>().As<IRoleMaintenanceService>();
            builder.RegisterType<RolesValidator>().As<IRolesValidator>();

            //Data
            builder.RegisterType<SearchDataProvider>().As<ISearchDataProvider>();

            //Export
            builder.RegisterType<ExportSettingsLoader>().As<IExportSettings>();
            builder.RegisterType<CpaXmlExporter>().As<ICpaXmlExporter>();
            builder.RegisterType<ExportContentService>().As<IExportContentService>();
            builder.RegisterType<ExportContentMonitor>().AsImplementedInterfaces();

            builder.RegisterType<WipOverviewSearchController>().As<ISearchController<WipOverviewSearchRequestFilter>, IExportableSearchController<WipOverviewSearchRequestFilter>>();
            builder.RegisterType<ReportsController>().As<IReportsController>();
        }
    }
}
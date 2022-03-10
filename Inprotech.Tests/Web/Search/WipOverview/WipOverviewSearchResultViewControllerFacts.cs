using System;
using System.Collections.Generic;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Messaging;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.ContentManagement;
using Inprotech.Web.Reports;
using Inprotech.Web.Search;
using Inprotech.Web.Search.WipOverview;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Components.Accounting.Wip.Overview.Search;
using InprotechKaizen.Model.Components.Reporting;
using InprotechKaizen.Model.Components.Search.WipOverview;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Queries;
using InprotechKaizen.Model.Security;
using NSubstitute;
using NSubstitute.ReturnsExtensions;
using Xunit;

namespace Inprotech.Tests.Web.Search.WipOverview
{
    public class WipOverviewSearchResultViewControllerFacts : FactBase
    {
        [Fact]
        public async Task GetViewData()
        {
            var id = Fixture.Integer();
            var query = new Query { Id = id, Name = Fixture.String("Query") }.In(Db);

            var f = new WipOverviewSearchResultViewControllerFixture(Db);

            f.TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>(), Arg.Any<ApplicationTaskAccessLevel>()).Returns(true);
            f.ReportProvider.GetReportProviderInfo().ReturnsNull();
            var results = await f.Subject.Get(id, QueryContext.WipOverviewSearch);
            Assert.NotNull(results);
            Assert.Equal(query.Name, results.QueryName);
            Assert.True(results.Permissions.CanMaintainDebitNote);
        }
    }

    public class WipOverviewSearchResultViewControllerPostFacts : FactBase
    {
        string GetXmlCriteriaString()
        {
            return @"<Search><Filtering><wp_ListWorkInProgress><FilterCriteria><EntityKey Operator='0'>-283575757</EntityKey><BelongsTo><ActingAs><IsWipStaff>0</IsWipStaff><AssociatedName>1</AssociatedName><AnyNameType>1</AnyNameType></ActingAs></BelongsTo><Debtor IsRenewalDebtor='1' /><ItemDate><DateRange Operator='7'><From>2019-05-30</From><To>2020-05-29</To></DateRange></ItemDate><WipStatus><IsActive>1</IsActive><IsLocked>1</IsLocked></WipStatus><RenewalWip><IsRenewal>1</IsRenewal><IsNonRenewal>1</IsNonRenewal></RenewalWip></FilterCriteria><AggregateFilterCriteria /></wp_ListWorkInProgress></Filtering><SelectedColumns><Column><ColumnKey>-2201</ColumnKey><DisplaySequence>1</DisplaySequence><SortOrder>2</SortOrder><SortDirection>A</SortDirection></Column><Column><ColumnKey>-2202</ColumnKey><DisplaySequence>2</DisplaySequence><SortOrder>3</SortOrder><SortDirection>A</SortDirection></Column><Column><ColumnKey>-77</ColumnKey><DisplaySequence>3</DisplaySequence><SortOrder>1</SortOrder><SortDirection>A</SortDirection></Column></SelectedColumns></Search>";
        }

        [Fact]
        public void AdditionalViewDataWhenHasAllSelectedIsFalse()
        {
            var request = new WipOverviewSearchResultViewController.AdditionalViewDataRequest
            {
                HasAllSelected = false,
                SearchRequestParams = new WipOverviewSearchResultViewController.ExtendedSearchRequestParam
                {
                    Criteria = new WipOverviewSearchRequestFilter
                    {
                        XmlSearchRequest = GetXmlCriteriaString()
                    }
                }
            };
            var f = new WipOverviewSearchResultViewControllerFixture(Db);

            var result = f.Subject.AdditionalViewData(request).Result;

            Assert.True(result.isNonRenewalWip);
            Assert.True(result.isRenewalWip);
            Assert.True(result.isUseRenewalDebtor);
            Assert.Null(result.searchResult);
            Assert.Equal(((DateTime)result.filterFromDate).Date.ToString("dd/MM/yyyy"), "30/05/2019");
            Assert.Equal(((DateTime)result.filterToDate).Date.ToString("dd/MM/yyyy"), "29/05/2020");
        }

        [Fact]
        public void AdditionalViewDataWhenHasAllSelectedIsTrueAndDirectSearch()
        {
            var request = new WipOverviewSearchResultViewController.AdditionalViewDataRequest
            {
                HasAllSelected = true,
                SearchRequestParams = new WipOverviewSearchResultViewController.ExtendedSearchRequestParam
                {
                    QueryKey = null,
                    Criteria = new WipOverviewSearchRequestFilter
                    {
                        XmlSearchRequest = string.Empty
                    },
                    QueryContext = QueryContext.WipOverviewSearch
                },
                DeSelectedIds = new[] { 3 }
            };

            var f = new WipOverviewSearchResultViewControllerFixture(Db);
            var list = new List<Dictionary<string, object>>
            {
                new()
                {
                    { "1", new { DebtorKey = 100, CaseKey = 201 } },
                    { "RowKey", 1 }
                },
                new()
                {
                    { "2", new { DebtorKey = 101, CaseKey = 202 } },
                    { "RowKey", 2 }
                },
                new()
                {
                    { "3", new { DebtorKey = 103, CaseKey = 205 } },
                    { "RowKey", 3 }
                }
            };
            var searchResult = new SearchResult { Rows = list, TotalRows = list.Count };

            list = new List<Dictionary<string, object>>
            {
                new()
                {
                    { "1", new { DebtorKey = 100, CaseKey = 201 } },
                    { "RowKey", 1 }
                },
                new()
                {
                    { "2", new { DebtorKey = 101, CaseKey = 202 } },
                    { "RowKey", 2 }
                }
            };
            f.WipOverviewSearchController.RunSearch(request.SearchRequestParams).Returns(searchResult);
            f.SearchResultSelector.GetActualSelectedRecords(searchResult, request.SearchRequestParams.QueryContext, request.DeSelectedIds).Returns(new SearchResult { Rows = list, TotalRows = list.Count });
            var result = f.Subject.AdditionalViewData(request).Result;

            Assert.NotNull(result.searchResult);
            Assert.Equal(result.searchResult.Rows.Count, list.Count);
        }

        [Fact]
        public void AdditionalViewDataWhenHasAllSelectedIsTrueAndSavedSearch()
        {
            var request = new WipOverviewSearchResultViewController.AdditionalViewDataRequest
            {
                HasAllSelected = true,
                SearchRequestParams = new WipOverviewSearchResultViewController.ExtendedSearchRequestParam
                {
                    QueryKey = 10,
                    Criteria = new WipOverviewSearchRequestFilter
                    {
                        XmlSearchRequest = string.Empty
                    },
                    QueryContext = QueryContext.WipOverviewSearch
                }
            };
            var f = new WipOverviewSearchResultViewControllerFixture(Db);
            var list = new List<Dictionary<string, object>>
            {
                new() { { "1", new { debtorKey = 100, caseKey = 201 } } },
                new() { { "1", new { debtorKey = 101, caseKey = 202 } } }
            };
            var param = request.SearchRequestParams as SavedSearchRequestParams<WipOverviewSearchRequestFilter>;
            param.QueryKey = request.SearchRequestParams.QueryKey.Value;

            f.WipOverviewSearchController.RunEditedSavedSearch(param).Returns(new SearchResult { Rows = list });
            var result = f.Subject.AdditionalViewData(request).Result;

            Assert.NotNull(result.searchResult);
            Assert.Equal(result.searchResult.Rows.Count, list.Count);
        }
    }

    public class WipOverviewSearchResultViewControllerFixture : IFixture<WipOverviewSearchResultViewController>
    {
        public IBus Bus;
        public IExportContentService ExportContentService;
        public IIndex<string, IReportsManager> ReportManager;
        public IReportProvider ReportProvider;
        public IUserPreferenceManager UserPreferences;

        public WipOverviewSearchResultViewControllerFixture(InMemoryDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            User = new UserBuilder(db) { Profile = new ProfileBuilder().Build().In(db) }.Build().In(db);
            SecurityContext.User.Returns(User);
            TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
            SearchService = Substitute.For<ISearchService>();
            var exportService = Substitute.For<ISearchExportService>();
            CreateBillValidator = Substitute.For<ICreateBillValidator>();
            Entities = Substitute.For<IEntities>();
            WipOverviewSearchController = new WipOverviewSearchController(SearchService, exportService,CreateBillValidator,Entities);
            UserPreferences = Substitute.For<IUserPreferenceManager>();
            ReportProvider = Substitute.For<IReportProvider>();
            ExportContentService = Substitute.For<IExportContentService>();
            ReportManager = Substitute.For<IIndex<string, IReportsManager>>();
            SearchResultSelector = Substitute.For<ISearchResultSelector>();
            Bus = Substitute.For<IBus>();
            var logger = Substitute.For<ILogger<ReportsController>>();
            ReportsController = new ReportsController(ReportProvider, ExportContentService, Bus, logger, ReportManager);
            TaskSecurityProvider.HasAccessTo(Arg.Any<ApplicationTask>(), Arg.Any<ApplicationTaskAccessLevel>()).Returns(true);
            SiteControlReader = Substitute.For<ISiteControlReader>();
            Entities = Substitute.For<IEntities>();
            Subject = new WipOverviewSearchResultViewController(db, SecurityContext, TaskSecurityProvider, WipOverviewSearchController, ReportsController, SearchResultSelector, SiteControlReader, Entities);
        }

        public User User { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public ITaskSecurityProvider TaskSecurityProvider { get; set; }
        public ISearchService SearchService { get; set; }
        public WipOverviewSearchController WipOverviewSearchController { get; set; }
        public IReportsController ReportsController { get; set; }
        public ISearchResultSelector SearchResultSelector { get; set; }
        public ISiteControlReader SiteControlReader { get; set; }
        public IEntities Entities { get; set; }
        public ICreateBillValidator CreateBillValidator { get; set; }
        public WipOverviewSearchResultViewController Subject { get; }
    }
}
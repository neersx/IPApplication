using System.Threading.Tasks;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.Search;
using Inprotech.Web.Search.Case;
using Inprotech.Web.Search.Case.GlobalCaseChange;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.GlobalCaseChange
{
    public class GlobalCaseChangeResultsControllerFacts
    {
        public class GlobalCaseChangeResultsControllerFixture : IFixture<GlobalCaseChangeResultsController>
        {
            public GlobalCaseChangeResultsControllerFixture(InMemoryDbContext db)
            {
                Db = db;
                CaseSearchService = Substitute.For<ICaseSearchService>();
                SearchExporter = Substitute.For<ISearchResultsExport>();
                ExportSettings = Substitute.For<IExportSettings>();
                SecurityContext = Substitute.For<ISecurityContext>();
                Subject = new GlobalCaseChangeResultsController(CaseSearchService, ExportSettings, SearchExporter);
            }
            public InMemoryDbContext Db { get; }

            public ICaseSearchService CaseSearchService { get; set; }
            public ISearchResultsExport SearchExporter { get; set; }
            public IExportSettings ExportSettings { get; set; }
            public GlobalCaseChangeResultsController Subject { get; }

            public ISecurityContext SecurityContext { get; set; }
        }

        public class RunSearchMethod : FactBase
        {
            [Fact]
            public async Task RunSearch()
            {
                var fixture = new GlobalCaseChangeResultsControllerFixture(Db);
                fixture.SecurityContext.User.Returns(new UserBuilder(Db).Build().WithKnownId(Fixture.Integer()));

                var request = new GlobalCaseChangeRequestParam
                {
                    GlobalProcessKey = 1,
                    PresentationType = "GlobalCaseChangeResults",
                    Params = new CommonQueryParameters(),
                    SearchName = "Bulk Field Update",
                    QueryContext = (int) QueryContext.CaseSearch
                };

                var caseSearchResult = new SearchResult();

                fixture.CaseSearchService.GlobalCaseChangeResults(request.Params, request.GlobalProcessKey, request.PresentationType).ReturnsForAnyArgs(caseSearchResult);

                var results = await fixture.Subject.RunSearch(request);

                Assert.Equal(caseSearchResult, results);
                
                fixture.CaseSearchService.Received(1).GlobalCaseChangeResults(request.Params, request.GlobalProcessKey, request.PresentationType)
                       .IgnoreAwaitForNSubstituteAssertion();

            }

        }
    }
}

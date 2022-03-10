using System.Threading.Tasks;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Search.Case.SanityCheck;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.SanityCheck
{
    public class SanityCheckServiceFacts : FactBase
    {
        int CreateSanityCheckResultData()
        {
            var caseOne = new CaseBuilder().Build().In(Db);
            var name = new NameBuilder(Db).Build().In(Db);
            var nameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.StaffMember, Name = "Staff Member"}.Build().In(Db);
            new CaseNameBuilder(Db) {NameType = nameType, Name = name}.BuildWithCase(caseOne).In(Db);
            var sanityCheckResults = new SanityCheckResultBuilder {CaseId = caseOne.Id}.Build().In(Db);
            return sanityCheckResults.ProcessId;
        }

        [Fact]
        public async Task VerifyExportWithInvalidProcessId()
        {
            var fixture = new SanityCheckServiceFixture(Db);
            var result = await fixture.Subject.Export(new SanityResultRequestParams {ExportFormat = ReportExportFormat.Excel, ProcessId = 0});
            Assert.Null(result);
        }

        [Fact]
        public async Task VerifyExportWithValidParams()
        {
            var fixture = new SanityCheckServiceFixture(Db);
            var processId = CreateSanityCheckResultData();
            var request = new SanityResultRequestParams {ExportFormat = ReportExportFormat.Excel, ProcessId = processId};
            fixture.SearchResultsExport.Export(Arg.Any<ExportRequest>(), Arg.Any<SearchResultsSettings>())
                   .Returns(new ExportResult
                   {
                       ContentType = "application/excel",
                       FileName = "abc.xls",
                       Content = new byte[0]
                   });

            var result = await fixture.Subject.Export(request);
            Assert.Equal("abc.xls", result.FileName);
            Assert.Equal("application/excel", result.ContentType);
        }

        [Fact]
        public async Task VerifySanityCheckResultsWithInvalidProcessId()
        {
            var f = new SanityCheckServiceFixture(Db);
            var result = await f.Subject.GetSanityCheckResults(new SanityResultRequestParams());
            Assert.Equal(0, result.Length);
        }

        [Fact]
        public async Task VerifySanityCheckResultsWithValidProcessId()
        {
            var f = new SanityCheckServiceFixture(Db);
            var processId = CreateSanityCheckResultData();
            var req = new SanityResultRequestParams
            {
                Params = new CommonQueryParameters {Skip = 0, Take = 10},
                ProcessId = processId
            };
            var result = await f.Subject.GetSanityCheckResults(req);
            Assert.Equal(1, result.Length);
        }
    }

    public class SanityCheckServiceFixture : IFixture<SanityCheckService>
    {
        public SanityCheckServiceFixture(InMemoryDbContext db)
        {
            SearchResultsExport = Substitute.For<ISearchResultsExport>();
            var exportSettings = Substitute.For<IExportSettings>();
            exportSettings.GetExportLimitorDefault(Arg.Any<ReportExportFormat>()).ReturnsForAnyArgs(10);
            exportSettings.Load(Arg.Any<string>(), Arg.Any<QueryContext>()).ReturnsForAnyArgs(new SearchResultsSettings());

            Subject = new SanityCheckService(exportSettings,
                                             SearchResultsExport, db,
                                             Substitute.For<IFormattedNameAddressTelecom>(),
                                             Substitute.For<IStaticTranslator>(),
                                             Substitute.For<IPreferredCultureResolver>());
        }

        public ISearchResultsExport SearchResultsExport { get; set; }
        public SanityCheckService Subject { get; }
    }
}
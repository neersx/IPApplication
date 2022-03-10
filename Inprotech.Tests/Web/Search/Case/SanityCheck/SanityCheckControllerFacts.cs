using System;
using System.Collections.Generic;
using System.Net;
using System.Threading.Tasks;
using System.Web.Http;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using Inprotech.Web.Search.Case.SanityCheck;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Search.Case.SanityCheck
{
    public class SanityCheckControllerFacts : FactBase
    {
        dynamic SetData()
        {
            var c1 = new CaseBuilder().Build().In(Db);
            var name = new NameBuilder(Db).Build().In(Db);
            var nameType = new NameTypeBuilder {NameTypeCode = KnownNameTypes.StaffMember, Name = "Staff Member"}.Build().In(Db);
            new CaseNameBuilder(Db) {NameType = nameType, Name = name}.BuildWithCase(c1).In(Db);
            var sanityCheckResults = new SanityCheckResultBuilder {CaseId = c1.Id}.Build().In(Db);
            return new
            {
                sanityCheckResults.Id,
                c1,
                sanityCheckResults.ProcessId,
                sanityCheckResults.IsWarning,
                sanityCheckResults.CanOverride,
                sanityCheckResults.DisplayMessage
            };
        }

        [Fact]
        public async Task ShouldThrowBadRequestExceptionIfRequestInvalid()
        {
            var exception = await Assert.ThrowsAsync<HttpResponseException>(
                                                                            async () =>
                                                                            {
                                                                                var fixture = new SanityCheckControllerFixture(Db);
                                                                                await fixture.Subject.GetSanityCheckResults(new SanityResultRequestParams());
                                                                            });

            Assert.Equal(HttpStatusCode.BadRequest, exception.Response.StatusCode);
        }

        [Fact]
        public void VerifyExportWithInvalidProcessId()
        {
            SetData();
            var request = new SanityResultRequestParams {ExportFormat = ReportExportFormat.Excel, ProcessId = 0};
            var fixture = new SanityCheckControllerFixture(Db);
            Assert.ThrowsAsync<ArgumentNullException>(() => fixture.Subject.Export(request));
        }

        [Fact]
        public async Task VerifyExportWithValidParams()
        {
            var data = SetData();
            var request = new SanityResultRequestParams {ExportFormat = ReportExportFormat.Excel, ProcessId = data.ProcessId};
            var fixture = new SanityCheckControllerFixture(Db);
            fixture.SearchResultsExport.Export(Arg.Any<ExportRequest>(), Arg.Any<SearchResultsSettings>())
                   .Returns(new ExportResult
                   {
                       ContentType = "application/excel",
                       FileName = "abc.xls",
                       Content = new byte[0]
                   });

            var result = await fixture.Subject.Export(request);
            Assert.NotNull(result);
            fixture.SearchResultsExport
                   .Received(1).Export(Arg.Any<ExportRequest>(), Arg.Any<SearchResultsSettings>())
                   .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task VerifySanityCheckResultsWithValidProcessId()
        {
            var data = SetData();
            var f = new SanityCheckControllerFixture(Db);

            var req = new SanityResultRequestParams
            {
                Params = new CommonQueryParameters {Skip = 0, Take = 10},
                ProcessId = data.ProcessId
            };
            var result = await f.Subject.GetSanityCheckResults(req);
            Assert.Equal(1, result.Pagination.Total);
        }

        [Fact]
        public void VerifySanityCheckWithEmptyCaseList()
        {
            var f = new SanityCheckControllerFixture(Db);
            var result = f.Subject.ApplySanityCheck(new List<int>());
            Assert.False(result.Status);
        }

        [Fact]
        public void VerifySanityCheckWithNullCaseList()
        {
            var f = new SanityCheckControllerFixture(Db);
            var result = f.Subject.ApplySanityCheck(null);
            Assert.False(result.Status);
        }
    }

    public class SanityCheckControllerFixture : IFixture<SanityCheckController>
    {
        public SanityCheckControllerFixture(InMemoryDbContext db)
        {
            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            FormattedNameAddressTelecom = Substitute.For<IFormattedNameAddressTelecom>();
            SecurityContext = Substitute.For<ISecurityContext>();
            User = new User(Fixture.String(), false).In(db);
            SecurityContext.User.Returns(User);
            SearchResultsExport = Substitute.For<ISearchResultsExport>();
            
            var exportSettings = Substitute.For<IExportSettings>();
            exportSettings.GetExportLimitorDefault(Arg.Any<ReportExportFormat>()).ReturnsForAnyArgs(10);
            exportSettings.Load(Arg.Any<string>(), Arg.Any<QueryContext>()).ReturnsForAnyArgs(new SearchResultsSettings());

            SanityCheckService = new SanityCheckService(exportSettings,
                                                        SearchResultsExport,
                                                        db,
                                                        Substitute.For<IFormattedNameAddressTelecom>(),
                                                        Substitute.For<IStaticTranslator>(),
                                                        PreferredCultureResolver);
            Subject = new SanityCheckController(db, PreferredCultureResolver, SecurityContext, SanityCheckService);
        }

        public User User { get; set; }

        public IPreferredCultureResolver PreferredCultureResolver { get; set; }
        public ISecurityContext SecurityContext { get; set; }
        public ICommonQueryService CommonQueryService { get; set; }
        public ISearchResultsExport SearchResultsExport { get; set; }
        public ISanityCheckService SanityCheckService { get; set; }
        public IFormattedNameAddressTelecom FormattedNameAddressTelecom { get; set; }
        public SanityCheckController Subject { get; }
    }
}
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Extensions;
using Inprotech.Web.BulkCaseImport;
using InprotechKaizen.Model.AuditTrail;
using InprotechKaizen.Model.Persistence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class ImportStatusControllerFacts
    {
        public class ImportStatusViewControllerFixture : IFixture<ImportStatusController>
        {
            public ImportStatusViewControllerFixture()
            {
                ImportServer = Substitute.For<IImportServer>();

                ImportStatusSummary = Substitute.For<IImportStatusSummary>();

                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

                DbArtifacts = Substitute.For<IDbArtifacts>();

                Subject = new ImportStatusController(ImportStatusSummary, ImportServer, TaskSecurityProvider, DbArtifacts);
            }

            public IDbArtifacts DbArtifacts { get; set; }

            public IImportServer ImportServer { get; set; }

            public IImportStatusSummary ImportStatusSummary { get; }

            public ITaskSecurityProvider TaskSecurityProvider { get; }

            public ImportStatusController Subject { get; }
        }

        public class GetMethod
        {
            [Fact]
            public async Task UpdatesStatusForAbortedBatchesAndRetrivesData()
            {
                var f = new ImportStatusViewControllerFixture();
                var inputQuery = new CommonQueryParameters {Skip = 0, Take = 50};

                await f.Subject.Get(new HttpRequestMessage(), inputQuery);

                f.ImportServer.Received(1).TryResetAbortedProcesses();

                f.ImportStatusSummary.Received(1).Retrieve(inputQuery)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class GetFilterDataForColumn
        {
            [Theory]
            [InlineData(null)]
            [InlineData("field1")]
            [InlineData("field2")]
            public async Task ShouldCallImportStatusSummaryWithCorrectParameters(string field)
            {
                var f = new ImportStatusViewControllerFixture();

                await f.Subject.GetFilterDataForColumn(field);

                f.ImportStatusSummary.Received(1).RetrieveFilterData(field)
                 .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class PermissionsMethod
        {
            [Theory]
            [InlineData(true, true, true)]
            [InlineData(false, true, false)]
            [InlineData(false, false, false)]
            [InlineData(true, false, false)]
            public void ShouldReturnPermissions(bool hasCasesILog, bool taskPermission, bool expectedResult)
            {
                var f = new ImportStatusViewControllerFixture();

                f.DbArtifacts
                 .Exists(Logging.Cases, SysObjects.Table, SysObjects.View)
                 .Returns(hasCasesILog);

                f.TaskSecurityProvider
                 .HasAccessTo(ApplicationTask.ReverseImportedCases)
                 .Returns(taskPermission);

                var r = f.Subject.Permissions();

                Assert.Equal(expectedResult, r.CanReverseBatch);
            }
        }
    }
}
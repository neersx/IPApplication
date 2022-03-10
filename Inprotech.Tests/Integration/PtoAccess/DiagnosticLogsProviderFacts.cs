using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Schedules;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class DiagnosticLogsProviderFacts
    {
        public class DataAvailableMethod : FactBase
        {
            [Fact]
            public void ReturnsFalseIfPtoDownloadHasNeverBeenUsed()
            {
                Assert.False(new DiagnosticLogsProviderFixture(Db).Subject.DataAvailable);
            }

            [Fact]
            public void ReturnsFalseIfPtoDownloadIsNotActiveleUsed()
            {
                new Schedule
                {
                    IsDeleted = true
                }.In(Db);

                Assert.False(new DiagnosticLogsProviderFixture(Db).Subject.DataAvailable);
            }

            [Fact]
            public void ReturnsTrueIfPtoDownloadsIsActive()
            {
                new Schedule().In(Db);

                Assert.True(new DiagnosticLogsProviderFixture(Db).Subject.DataAvailable);
            }
        }

        public class ExportMethod : FactBase
        {
            [Fact]
            public async Task CallOutAndAppendAllLogsIncludingIntegrationServerForDiagnosticLogs()
            {
                using (var integLogStream = new MemoryStream())
                using (var returnFileStream = new MemoryStream())
                {
                    var f = new DiagnosticLogsProviderFixture(Db);

                    f.FileSystem.AbsoluteUniquePath(Arg.Any<string>(), Arg.Any<string>()).Returns("temp filepath for the archive");

                    f.FileSystem.OpenWrite("temp filepath for the archive").Returns(returnFileStream);

                    f.IntegrationServerClient.GetResponse("api/ptoaccess/diagnostic-logs/export")
                     .Returns(new HttpResponseMessage(HttpStatusCode.OK)
                     {
                         Content = new StreamContent(integLogStream)
                     });

                    await f.Subject.Export();

                    Assert.Equal(integLogStream.ToArray(), returnFileStream.ToArray());

                    f.FileSystem.Received(1).OpenRead("temp filepath for the archive");
                    f.CompressionUtility.AppendArchive(Arg.Any<string>(), Arg.Is<IEnumerable<IArchivable>>(_ => _.Contains(f.CompressedServerLogs)))
                     .IgnoreAwaitForNSubstituteAssertion();
                }
            }
        }

        public class DiagnosticLogsProviderFixture : IFixture<DiagnosticLogsProvider>
        {
            public DiagnosticLogsProviderFixture(InMemoryDbContext db)
            {
                CompressedServerLogs = Substitute.For<ICompressedServerLogs>();

                IntegrationServerClient = Substitute.For<IIntegrationServerClient>();

                FileSystem = Substitute.For<IFileSystem>();

                CompressionUtility = Substitute.For<ICompressionUtility>();

                Subject = new DiagnosticLogsProvider(db, CompressedServerLogs, IntegrationServerClient, FileSystem, CompressionUtility);
            }

            public ICompressedServerLogs CompressedServerLogs { get; set; }

            public IIntegrationServerClient IntegrationServerClient { get; set; }

            public IFileSystem FileSystem { get; set; }

            public ICompressionUtility CompressionUtility { get; set; }

            public DiagnosticLogsProvider Subject { get; }
        }
    }
}
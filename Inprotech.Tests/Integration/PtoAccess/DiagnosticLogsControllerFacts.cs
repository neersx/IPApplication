using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Diagnostics;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class DiagnosticLogsControllerFacts
    {
        public class ExportMethod
        {
            public class AcceptableOne : ICompressedServerLogs
            {
                public string Name { get; } = nameof(AcceptableOne);

                public Task Prepare(string basePath)
                {
                    throw new NotImplementedException();
                }
            }

            public class AcceptableTwo : IDiagnosticsArtefacts
            {
                public string Name { get; } = nameof(AcceptableTwo);

                public Task Prepare(string basePath)
                {
                    throw new NotImplementedException();
                }
            }

            public class NotAcceptable : IArchivable
            {
                public string Name { get; } = nameof(NotAcceptable);

                public Task Prepare(string basePath)
                {
                    throw new NotImplementedException();
                }
            }

            [Fact]
            public async Task CreateDownloadableArchivesFromAllDiagnosticSources()
            {
                var f = new DiagnosticLogsControllerFixture();

                f.Archivables.Add(new AcceptableOne());

                f.Archivables.Add(new AcceptableTwo());

                f.Archivables.Add(new NotAcceptable());

                await f.Subject.Export();

                var shouldNotInclude = f.Archivables.Where(_ => _.GetType() == typeof(NotAcceptable));

                f.CompressionUtility.Received(1).CreateArchive("IntegrationServer.logs.zip",
                                                               Arg.Is<IEnumerable<IArchivable>>(
                                                                                                _ => _.SequenceEqual(f.Archivables.Except(shouldNotInclude))))
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task StreamItDownTheWire()
            {
                var f = new DiagnosticLogsControllerFixture();
                f.Archivables.Add(new AcceptableOne());

                f.CompressionUtility.CreateArchive("IntegrationServer.logs.zip", Arg.Any<IEnumerable<IArchivable>>())
                 .Returns("Path to destination archive");

                var compressedArchive = new MemoryStream();

                f.FileSystem.OpenRead("Path to destination archive").Returns(compressedArchive);

                var r = await f.Subject.Export();

                using (var outStream = new MemoryStream())
                {
                    await r.Content.CopyToAsync(outStream);
                    Assert.Equal(compressedArchive.ToArray(), outStream.ToArray());
                }
            }
        }

        public class DiagnosticLogsControllerFixture : IFixture<DiagnosticLogsController>
        {
            public DiagnosticLogsControllerFixture()
            {
                FileSystem = Substitute.For<IFileSystem>();
                FileSystem.OpenRead(Arg.Any<string>()).Returns(new MemoryStream());

                Archivables = new List<IArchivable>();

                CompressionUtility = Substitute.For<ICompressionUtility>();

                Subject = new DiagnosticLogsController(FileSystem, CompressionUtility, Archivables);
            }

            public IFileSystem FileSystem { get; set; }

            public ICompressionUtility CompressionUtility { get; set; }

            public List<IArchivable> Archivables { get; set; }

            public DiagnosticLogsController Subject { get; }
        }
    }
}
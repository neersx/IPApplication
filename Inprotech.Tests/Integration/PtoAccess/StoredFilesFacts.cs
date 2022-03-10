using System;
using System.Collections.Generic;
using System.IO;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Integration.Diagnostics.PtoAccess;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class StoredFilesFacts
    {
        readonly ISimpleExcelExporter _excelExporter = Substitute.For<ISimpleExcelExporter>();
        readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();
        readonly IFileHelpers _fileHelpers = Substitute.For<IFileHelpers>();

        async Task Fixture(Func<Task> run, Action<string[]> result)
        {
            _fileSystem.AbsolutePath(Arg.Any<string>()).Returns(x => "absolute storage path/" + x[0]);

            using (var stream1 = new MemoryStream())
            using (var stream2 = new MemoryStream())
            {
                var written = new List<string>();

                _fileSystem.OpenWrite(Arg.Any<string>()).Returns(stream1);

                _excelExporter
                    .WhenForAnyArgs(x => x.Export(Arg.Any<IEnumerable<StoredFiles.StorageFileListing>>()))
                    .Do(x =>
                    {
                        var files = (IEnumerable<StoredFiles.StorageFileListing>) x[0];

                        written.AddRange(files.Select(file => file.FilePath));
                    });

                _excelExporter.Export(Arg.Any<IEnumerable<StoredFiles.StorageFileListing>>()).Returns(stream2);

                await run();

                result(written.ToArray());
            }
        }

        [Fact]
        public async Task PreparesStoredFiles()
        {
            _fileHelpers.DirectoryExists("absolute storage path/UsptoIntegration").Returns(true);

            _fileHelpers.DirectoryExists("absolute storage path/PtoIntegration").Returns(true);

            _fileSystem.Files("UsptoIntegration", "*", true)
                       .Returns(new[]
                       {
                           "a", "b", "c"
                       });

            _fileSystem.Files("PtoIntegration", "*", true)
                       .Returns(new[]
                       {
                           "g", "h", "i"
                       });

            var subject = new StoredFiles(_excelExporter, _fileSystem, _fileHelpers);

            await Fixture(async () => await subject.Prepare("ddd"),
                          y => { Assert.Equal(new[] {"a", "b", "c", "g", "h", "i"}, y); });
        }

        [Fact]
        public async Task WillNotCheckPtoIntegrationFilesIfPtoDownloadsNeverBeforeExecuted()
        {
            _fileHelpers.DirectoryExists("absolute storage path/PtoIntegration").Returns(false);

            _fileHelpers.DirectoryExists("absolute storage path/UsptoIntegration").Returns(true);

            _fileSystem.Files("UsptoIntegration", "*", true)
                       .Returns(new[]
                       {
                           "g", "h", "i"
                       });

            var subject = new StoredFiles(_excelExporter, _fileSystem, _fileHelpers);

            await Fixture(async () => await subject.Prepare("ddd"),
                          y =>
                          {
                              Assert.Equal(new[] {"g", "h", "i"}, y);

                              _fileSystem.DidNotReceive().Files("PtoIntegration", "*", true);

                              _fileSystem.Received().Files("UsptoIntegration", "*", true);
                          });
        }

        [Fact]
        public async Task WillNotCheckUsptoIntegrationFilesIfUsptoDownloadsNeverBeforeExecuted()
        {
            _fileHelpers.DirectoryExists("absolute storage path/UsptoIntegration").Returns(false);

            _fileHelpers.DirectoryExists("absolute storage path/PtoIntegration").Returns(true);

            _fileSystem.Files("PtoIntegration", "*", true)
                       .Returns(new[]
                       {
                           "g", "h", "i"
                       });

            var subject = new StoredFiles(_excelExporter, _fileSystem, _fileHelpers);

            await Fixture(async () => await subject.Prepare("ddd"),
                          y =>
                          {
                              Assert.Equal(new[] {"g", "h", "i"}, y);

                              _fileSystem.DidNotReceive().Files("UsptoIntegration", "*", true);

                              _fileSystem.Received().Files("PtoIntegration", "*", true);
                          });
        }
    }
}
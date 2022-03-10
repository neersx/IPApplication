using System.IO;
using System.Linq;
using System.Net;
using System.Web.Http;
using Inprotech.Contracts;
using Inprotech.Web.BulkCaseImport;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class CaseImportTemplatesFacts
    {
        public class ListAvailableMethod
        {
            readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();

            [Theory]
            [InlineData(".a")]
            [InlineData(".txt")]
            [InlineData(".doc")]
            public void ShouldNotReturnUnsupportedFileExtensions(string ext)
            {
                var supported = "a.csv";
                var unsupported = "b" + ext;

                _fileSystem.Files("bulkCaseImport-templates\\standard", "*")
                           .Returns(new[] {unsupported, supported});

                var r = new CaseImportTemplates(_fileSystem).ListAvailable();

                Assert.Equal("a.csv", r.StandardTemplates[0]);
                Assert.Equal(1, r.StandardTemplates.Length);
            }

            [Fact]
            public void ReturnTemplatesFromStandardAndCustomFolders()
            {
                _fileSystem.Files("bulkCaseImport-templates\\standard", "*")
                           .Returns(new[] {"a.xltx", "b.csv"});

                _fileSystem.Files("bulkCaseImport-templates\\custom", "*")
                           .Returns(new[] {"f.xltx", "g.csv"});

                var r = new CaseImportTemplates(_fileSystem).ListAvailable();

                Assert.Equal("a.xltx", r.StandardTemplates[0]);
                Assert.Equal("b.csv", r.StandardTemplates[1]);

                Assert.Equal("f.xltx", r.CustomTemplates[0]);
                Assert.Equal("g.csv", r.CustomTemplates[1]);
            }

            [Fact]
            public void ReturnTemplatesSorted()
            {
                _fileSystem.Files("bulkCaseImport-templates\\standard", "*")
                           .Returns(new[] {"c.xltx", "b.csv", "a.xls"});

                var r = new CaseImportTemplates(_fileSystem)
                        .ListAvailable()
                        .StandardTemplates;

                Assert.True(Enumerable.SequenceEqual(new[] {"a.xls", "b.csv", "c.xltx"}, r));
            }
        }

        public class DownloadMethod
        {
            readonly IFileSystem _fileSystem = Substitute.For<IFileSystem>();

            [Theory]
            [InlineData("standard")]
            [InlineData("custom")]
            public void DownloadsRequested(string type)
            {
                const string requested = "patentImport.xltx";

                using (var template = new MemoryStream())
                using (var returnFileStream = new MemoryStream())
                {
                    var expectedPath = "bulkCaseImport-templates\\" + type + "\\" + requested;

                    _fileSystem.Exists(expectedPath).Returns(true);
                    _fileSystem.OpenRead(expectedPath).Returns(template);

                    var r = new CaseImportTemplates(_fileSystem).Download(requested, type);

                    Assert.Equal(template.ToArray(), returnFileStream.ToArray());

                    Assert.Equal("application/vnd.ms-excel", r.Content.Headers.ContentType.MediaType);
                    Assert.Equal(requested, r.Content.Headers.ContentDisposition.FileName);
                }
            }

            [Fact]
            public void ThrowsWhenRequestedTemplateDoesNotExists()
            {
                _fileSystem.Exists(Arg.Any<string>()).Returns(false);

                var exception = Record.Exception(() => { new CaseImportTemplates(_fileSystem).Download("some.csv", "custom"); });

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsWhenRequestedTemplateExtensionNotSupported()
            {
                _fileSystem.Exists(Arg.Any<string>()).Returns(true);

                var exception = Record.Exception(() => { new CaseImportTemplates(_fileSystem).Download("autoexec.bat", "custom"); });

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }

            [Fact]
            public void ThrowsWhenRequestedTemplateTypeIsUnknown()
            {
                _fileSystem.Exists(Arg.Any<string>()).Returns(true);

                var exception = Record.Exception(() => { new CaseImportTemplates(_fileSystem).Download("some.csv", "unknown type"); });

                Assert.IsType<HttpResponseException>(exception);
                Assert.Equal(HttpStatusCode.NotFound, ((HttpResponseException) exception).Response.StatusCode);
            }
        }
    }
}
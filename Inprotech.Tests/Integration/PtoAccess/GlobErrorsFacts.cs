using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Innography.PrivatePair;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess
{
    public class GlobErrorsFacts
    {
        readonly DataDownload _dataDownload = new DataDownload();

        public class GlobErrorsFixture : IFixture<GlobErrors>
        {
            public GlobErrorsFixture()
            {
                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();
                ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                DataDownloadLocationResolver.ResolveForErrorLog(Arg.Any<DataDownload>()).Returns(string.Empty);
                DataDownloadLocationResolver.ResolveForErrorLog(Arg.Any<DataDownload>(), "12345").Returns(s => (string)s[1]);

                FileSystem = Substitute.For<IFileSystem>();
                FileSystem.Files(Arg.Any<string>(), Arg.Any<string>())
                          .Returns(new[] { "file1.log", "file2.log" });

                BufferedStringReader = Substitute.For<IBufferedStringReader>();
                BufferedStringReader.Read(Arg.Any<string>())
                                    .Returns(Task.FromResult("{\"e\":\"e\"}"));

                Subject = new GlobErrors(DataDownloadLocationResolver, ArtifactsLocationResolver, FileSystem, BufferedStringReader);
            }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public IArtifactsLocationResolver ArtifactsLocationResolver { get; set; }

            public IFileSystem FileSystem { get; set; }

            public IBufferedStringReader BufferedStringReader { get; set; }

            public GlobErrors Subject { get; set; }
        }

        [Fact]
        public async Task GlobContextualErrors()
        {
            var f = new GlobErrorsFixture();
            var r = (await f.Subject.For(_dataDownload, "12345")).ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("e", r.First()["e"]);
            Assert.Equal("e", r.Last()["e"]);

            f.FileSystem.Received(1).Files(Arg.Any<string>(), Arg.Is<string>(s => s.Contains("12345")));
        }

        [Fact]
        public async Task GlobErrors()
        {
            var f = new GlobErrorsFixture();
            var r = (await f.Subject.For(_dataDownload)).ToArray();

            Assert.Equal(2, r.Length);
            Assert.Equal("e", r.First()["e"]);
            Assert.Equal("e", r.Last()["e"]);
        }
    }
}
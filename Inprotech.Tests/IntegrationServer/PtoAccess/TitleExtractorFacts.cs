using System.Threading.Tasks;
using System.Xml.Linq;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.Tests.Builders.CpaXml;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess
{
    public class TitleExtractorFacts
    {
        readonly CpaXmlBuilder _cpaxml = new CpaXmlBuilder();

        public class TitleExtractorFixture : IFixture<TitleExtractor>
        {
            public TitleExtractorFixture()
            {
                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();
                DataDownloadLocationResolver.Resolve(Arg.Any<DataDownload>(), Arg.Any<string>())
                                            .Returns("path");

                BufferedStringReader = Substitute.For<IBufferedStringReader>();

                Subject = new TitleExtractor(DataDownloadLocationResolver, BufferedStringReader);
            }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public IBufferedStringReader BufferedStringReader { get; set; }

            XElement CpaXml { get; set; }

            public TitleExtractor Subject { get; }

            public TitleExtractorFixture ThatReturnsCpaXml(XElement element)
            {
                CpaXml = element;

                BufferedStringReader.Read(Arg.Any<string>()).Returns(Task.FromResult(CpaXml.ToString()));

                return this;
            }
        }

        [Fact]
        public async Task ExtractsNull()
        {
            _cpaxml.CaseDetails = new CaseDetailsBuilder(_cpaxml.Ns).Build();

            var f = new TitleExtractorFixture().ThatReturnsCpaXml(_cpaxml.Build());
            var r = await f.Subject.ExtractFrom(new DataDownload());

            Assert.Null(r);
        }

        [Fact]
        public async Task ExtractsShortTitle()
        {
            _cpaxml.CaseDetails = new CaseDetailsBuilder(_cpaxml.Ns)
                                  .WithDescription("Short Title", "blah")
                                  .Build();

            var f = new TitleExtractorFixture().ThatReturnsCpaXml(_cpaxml.Build());
            var r = await f.Subject.ExtractFrom(new DataDownload());

            Assert.Equal("blah", r);
        }
    }
}
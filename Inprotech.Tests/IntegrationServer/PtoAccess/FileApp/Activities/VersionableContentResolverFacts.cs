using System.Threading.Tasks;
using CPAXML;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.FileApp.Activities;
using InprotechKaizen.Model.Components.Cases.Comparison.CpaXml;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.FileApp.Activities
{
    public class VersionableContentResolverFacts
    {
        IVersionableContentResolver CreateSubject(CaseDetails caseDetails)
        {
            var location = Substitute.For<IDataDownloadLocationResolver>();
            var fileReader = Substitute.For<IBufferedStringReader>();
            var cpaDetailsLoader = Substitute.For<ICpaXmlCaseDetailsLoader>();

            var path = Fixture.String();
            var cpaXmlString = Fixture.String();

            location.Resolve(Arg.Any<DataDownload>(), PtoAccessFileNames.CpaXml)
                    .Returns(path);

            fileReader.Read(path)
                      .Returns(cpaXmlString);

            cpaDetailsLoader.Load(cpaXmlString).Returns((caseDetails, new TransactionMessageDetails[0]));

            return new VersionableContentResolver(location, cpaDetailsLoader, fileReader);
        }

        [Fact]
        public async Task DifferentContentShouldResolveToDifferentString()
        {
            var a = new CaseDetails("Patent", "US");

            var b = new CaseDetails("Patent", "US");

            a.CreateIdentifierNumberDetails("Application", "15273163");

            var a1 = await CreateSubject(a).Resolve(new DataDownload());
            var b1 = await CreateSubject(b).Resolve(new DataDownload());

            Assert.NotEqual(a1, b1);
        }

        [Fact]
        public async Task SameContentShouldResolveToSameString()
        {
            var a = new CaseDetails("Patent", "US");

            var b = new CaseDetails("Patent", "US");

            a.CreateIdentifierNumberDetails("Application", "15273163");

            b.CreateIdentifierNumberDetails("Application", "15273163");

            var a1 = await CreateSubject(a).Resolve(new DataDownload());
            var b1 = await CreateSubject(b).Resolve(new DataDownload());

            Assert.Equal(a1, b1);
        }
    }
}
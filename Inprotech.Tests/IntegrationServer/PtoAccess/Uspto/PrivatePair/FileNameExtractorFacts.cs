using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class FileNameExtractorFacts
    {
        [Theory]
        [InlineData("http://aws.com/abc.pdf", "abc.pdf")]
        [InlineData("http://aws.com/abc.pdf?q=query&a=another", "abc.pdf")]
        [InlineData("http://aws.com/subpath/abc.pdf", "abc.pdf")]
        [InlineData("c:\\Inprotech\\Storage\\UsptoIntegration\\Uspto Schedule\\1c938e38-3b5a-44bb-8f75-cab27b4ffd04\\applications\\11150024\\files\\11150024-2017-12-02-00001-AP.PRE.DEF.pdf", "11150024-2017-12-02-00001-AP.PRE.DEF.pdf")]
        public void TestNames(string filePath, string expectedFileName)
        {
            Assert.Equal(expectedFileName, new FileNameExtractor().AbsoluteUriName(filePath));
        }
    }
}
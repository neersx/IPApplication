using System.Linq;
using Inprotech.IntegrationServer.PtoAccess.Epo;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Epo
{
    public class AllDocumentsExtractorFacts
    {
        const string AssetPath = "Inprotech.Tests.IntegrationServer.PtoAccess.Epo.Assets.";

        [Theory]
        [InlineData(9, "SomeDocuments2.html")]
        [InlineData(29, "SomeDocuments1.html")]
        public void ReturnsAsManyDocumentsAsAreAvailable(int expectedNumDocs, string htmlPath)
        {
            var html = Tools.ReadFromEmbededResource(AssetPath + htmlPath);

            var r = new AllDocumentsTabExtractor().Extract(html).ToArray();

            Assert.Equal(expectedNumDocs, r.Count());
        }

        [Theory]
        [InlineData(0, "Final instructions (application deemed to be withdrawn/application refused)", "Search / examination", "20100617", 1, "EQE200WL2914960")]
        [InlineData(1, "Application deemed to be withdrawn (non-entry into European phase)", "Search / examination", "20100225", 4, "EPX2QTVI9141354")]
        [InlineData(2, "Notice drawing attention to the payment of the renewal fee and additional fee", "Search / examination", "20100223", 2, "EPX2L5ZT2007FI4")]
        [InlineData(3, "Translation of the international preliminary report on patentability", "Search / examination", "20100127", 8, "EPU0A9RZ5026FI4")]
        [InlineData(4, "Copy of the international preliminary report on patentability", "Search / examination", "20100115", 6, "EPTATC945553FI4")]
        [InlineData(5, "Notification of the recording of a change", "Search / examination", "20091109", 1, "EPJONJI92449FI4")]
        [InlineData(6, "Information on entry into European phase", "Search / examination", "20091104", 3, "EPIA733W8731FI4")]
        [InlineData(7, "Notification of the recording of a change", "Search / examination", "20091104", 1, "EPIXXG2K1620FI4")]
        [InlineData(8, "Republication of front page of international application with corrected bibliographic data", "Search / examination", "20090402", 2, "EOPZ50U68004FI4")]
        public void ExtractAllDetails(int index, string description, string procedure, string date, int pageQuantity, string docId)
        {
            var html = Tools.ReadFromEmbededResource(AssetPath + "SomeDocuments2.html");

            var r = new AllDocumentsTabExtractor().Extract(html).ToArray();

            var doc = r.ElementAt(index);

            Assert.Equal(description, doc.DocumentName);
            Assert.Equal(procedure, doc.Procedure);
            Assert.Equal(date, doc.Date.ToString("yyyyMMdd"));
            Assert.Equal(pageQuantity, doc.NumberOfPages);
            Assert.Equal(docId, doc.DocumentId);
        }

        [Fact]
        public void ReturnsNothing()
        {
            var html = Tools.ReadFromEmbededResource(AssetPath + "NoDocuments.html");

            var r = new AllDocumentsTabExtractor().Extract(html).ToArray();

            Assert.Empty(r);
        }
    }
}
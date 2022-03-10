using System.Data;
using System.Xml;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Web.Processing;
using InprotechKaizen.Model.Components.Cases;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Processing
{
    public class CpaXmlExporterFacts
    {
        [Fact]
        public void CallsBackendToFetchXmlToExport()
        {
            const int processId = 5;
            const int userId = 1009;
            var xmlDoc = new XmlDocument();
            xmlDoc.LoadXml("<a></a>");

            var f = new CpaXmlExporterFixture().WithCpaXmlData(xmlDoc);

            var result = f.Subject.DownloadCpaXmlExport(processId, userId);

            f.PreferredCultureResolver.Received(1).Resolve();
            f.CpaXmlData.Received(1).GetCpaXmlData(Arg.Is(userId), Arg.Is(processId), Arg.Any<string>());

            Assert.Equal("text/xml;", result.ContentType);
            Assert.NotNull(result.FileName);
            Assert.Equal(xmlDoc, result.Document);
        }

        [Fact]
        public void GeneratesFileNameFromDateTime()
        {
            var xmlDoc = new XmlDocument();

            xmlDoc.LoadXml("<NewDataSet><Table><CPAXMLDATA></CPAXMLDATA></Table></NewDataSet>");

            var f = new CpaXmlExporterFixture().WithCpaXmlData(xmlDoc);

            var result = f.Subject.DownloadCpaXmlExport(4, 5);

            Assert.Equal("Data Import~01012000000000.xml", result.FileName);
        }

        [Fact]
        public void GeneratesFileNameFromSenderFilename()
        {
            const string fileName = "ILikeToEatAppleAndBanana.xml";

            var ds = new DataSet("NewDataSet");
            ds.Tables.Add("Table");
            ds.Tables[0].Columns.Add("CPAXMLDATA");
            ds.Tables[0].Rows.Add("<?xml version=\"1.0\"?>");
            ds.Tables[0].Rows.Add("<Transaction>");
            ds.Tables[0].Rows.Add($"<TransactionHeader><SenderDetails><SenderFilename>{fileName}</SenderFilename></SenderDetails></TransactionHeader>");
            ds.Tables[0].Rows.Add("<TransactionBody><TransactionIdentifier>1</TransactionIdentifier></TransactionBody>");
            ds.Tables[0].Rows.Add("</Transaction>");

            var xmlDocument = new XmlDocument {XmlResolver = null};
            xmlDocument.LoadXml(ds.GetXml());

            var f = new CpaXmlExporterFixture().WithCpaXmlData(xmlDocument);

            var result = f.Subject.DownloadCpaXmlExport(4, 5);

            Assert.Equal(fileName, result.FileName);
        }
    }

    public class CpaXmlExporterFixture : IFixture<ICpaXmlExporter>
    {
        public CpaXmlExporterFixture()
        {
            CpaXmlData = Substitute.For<ICpaXmlData>();

            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();

            PreferredCultureResolver.Resolve().Returns(Fixture.RandomString(4));

            Subject = new CpaXmlExporter(PreferredCultureResolver, CpaXmlData, Fixture.Today);
        }

        public ICpaXmlData CpaXmlData { get; }
        public IPreferredCultureResolver PreferredCultureResolver { get; }
        public ICpaXmlExporter Subject { get; }

        public CpaXmlExporterFixture WithCpaXmlData(XmlDocument doc)
        {
            CpaXmlData.GetCpaXmlData(Arg.Any<int>(), Arg.Any<int>(), Arg.Any<string>()).Returns(doc);

            return this;
        }
    }
}
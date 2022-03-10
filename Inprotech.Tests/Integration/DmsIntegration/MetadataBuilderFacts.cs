using System;
using System.Data;
using System.IO;
using System.Xml.Linq;
using Inprotech.Contracts.DocItems;
using Inprotech.Integration;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;
using Document = Inprotech.Integration.Documents.Document;

namespace Inprotech.Tests.Integration.DmsIntegration
{
    public class MetadataBuilderFacts : FactBase
    {
        [Theory]
        [InlineData(DataSourceType.UsptoTsdr)]
        [InlineData(DataSourceType.Epo)]
        [InlineData(DataSourceType.UsptoPrivatePair)]
        public void ShouldBuildMetadata(DataSourceType dataSourceType)
        {
            new CaseBuilder().Build().In(Db);
            new DocItem {Name = "DMS_INTEGRATION_DOCUMENT_METADATA"}.In(Db);
            var runner = Substitute.For<IDocItemRunner>();
            var builder = new MetadataBuilder(Db, runner);
            var doc = BuildDocument(DateTime.Parse("2015-01-01"), "d1", dataSourceType);
            var dataset = BuildDataSet("a", "b", "c", "d", "e", "f", "g", "h");
            runner.Run(1, null).ReturnsForAnyArgs(dataset);
            var stream = builder.Build(1, doc);
            var xml = ReadXml(stream);
            var row = dataset.Tables[0].Rows[0];

            Assert.Equal(row["MatterRef"], (string) xml.Element("MatterRef"));
            Assert.Equal(row["ResponsibleAttorneyCode"], (string) xml.Element("ResponsibleAttorney").Attribute("code"));
            Assert.Equal(row["ResponsibleAttorneyName"], (string) xml.Element("ResponsibleAttorney"));
            Assert.Equal(row["ParalegalCode"], (string) xml.Element("Paralegal").Attribute("code"));
            Assert.Equal(row["ParalegalName"], (string) xml.Element("Paralegal"));
            Assert.Equal(row["ClientCode"], (string) xml.Element("Client").Attribute("code"));
            Assert.Equal(row["ClientName"], (string) xml.Element("Client"));
            Assert.Equal(row["ResponsibleOffice"], (string) xml.Element("ResponsibleOffice"));
            Assert.Equal(doc.MailRoomDate, (DateTime) xml.Element("DocumentDate"));
            Assert.Equal(doc.DocumentDescription, (string) xml.Element("Description"));
            Assert.Equal(dataSourceType.ToString(), (string) xml.Element("DataSource"));
        }

        static XElement ReadXml(Stream stream)
        {
            return XElement.Parse(new StreamReader(stream).ReadToEnd());
        }

        static Document BuildDocument(DateTime mailroomDate, string description, DataSourceType type)
        {
            return new Document {MailRoomDate = mailroomDate, DocumentDescription = description, Source = type};
        }

        static DataSet BuildDataSet(string matterRef, string attorneyName, string attorneyCode, string paralegalName, string paralegalCode, string clientName, string clientCode, string office)
        {
            var table = new DataTable();
            table.Columns.Add("MatterRef", typeof(string));
            table.Columns.Add("ResponsibleAttorneyCode", typeof(string));
            table.Columns.Add("ResponsibleAttorneyName", typeof(string));
            table.Columns.Add("ParalegalCode", typeof(string));
            table.Columns.Add("ParalegalName", typeof(string));
            table.Columns.Add("ClientCode", typeof(string));
            table.Columns.Add("ClientName", typeof(string));
            table.Columns.Add("ResponsibleOffice", typeof(string));

            table.Rows.Add(matterRef, attorneyCode, attorneyName, paralegalCode, paralegalName, clientCode, clientName, office);

            var dataSet = new DataSet();
            dataSet.Tables.Add(table);

            return dataSet;
        }
    }
}
using System;
using System.IO;
using System.Xml.Linq;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Web.Exporters;
using Newtonsoft.Json;
using Xunit;

namespace Inprotech.Tests.Exporters
{
    public class ExcelExporterFacts : IDisposable
    {
        public ExcelExporterFacts()
        {
            Directory.CreateDirectory(_tempDirectory);
        }

        readonly string _tempDirectory = Path.GetRandomFileName();

        public void Dispose()
        {
            if (Directory.Exists(_tempDirectory))
            {
                Directory.Delete(_tempDirectory, true);
            }
        }

        static Stream GetSampleExportConfig()
        {
            return typeof(ExcelExporterFacts).Assembly.GetManifestResourceStream("Inprotech.Tests.Exporters.Inprotech.Export.Sample.config");
        }

        [Fact]
        public void ExistingXmlConfigCanBeCopiedAndLoaded()
        {
            // this is to make sure that known XML config format
            // can be copied to new JSON format and that it will be successfully loaded

            var xml = GetSampleExportConfig();

            var xmlConfig = ExportConfig.Load(XElement.Load(xml));

            // "Inprotech.Export.json" is relative to server execution folder.
            File.WriteAllText("Inprotech.Export.json", JsonConvert.SerializeObject(xmlConfig));

            var jsonConfig = new ExportConfigProvider().GetConfig();

            Assert.Equal("#00156E", jsonConfig.Excel.TitleColor);
            Assert.Equal("#FFFFFF", jsonConfig.Excel.TitleBackgroundColor);
            Assert.Equal("#FFFFFF", jsonConfig.Excel.RowBackgroundColor);
            Assert.Equal("#F1FBFF", jsonConfig.Excel.RowAlternateBackgroundColor);
            Assert.Equal("#9FAABF", jsonConfig.Excel.BorderColor);
            Assert.Equal("#CDDEF2", jsonConfig.Excel.ColumnHeaderBackgroundColor);
            Assert.Equal("#CDDEF2", jsonConfig.Excel.ColumnHeaderBackgroundColor);

            Assert.Equal(10, jsonConfig.Word.MarginTop);
            Assert.Equal(10, jsonConfig.Word.MarginBottom);
            Assert.Equal(10, jsonConfig.Word.MarginLeft);
            Assert.Equal(10, jsonConfig.Word.MarginRight);
            Assert.Equal(true, jsonConfig.Word.DisplayLogo);
            Assert.Equal(true, jsonConfig.Word.DisplayLogoOnFirstPageOnly);

            Assert.Equal("client/images/branding-logo.png", jsonConfig.Pdf.CompanyLogo);
            Assert.Equal("client/images/checkbox2.check.png", jsonConfig.Pdf.IconCheckboxChecked);
            Assert.Equal("client/images/checkbox2.uncheck.png", jsonConfig.Pdf.IconCheckboxUnchecked);
        }

        [Fact]
        public void ImportsConfig()
        {
            var xml = GetSampleExportConfig();

            var xmlConfig = ExportConfig.Load(XElement.Load(xml));

            Assert.Equal("#00156E", xmlConfig.Excel.TitleColor);
            Assert.Equal("#FFFFFF", xmlConfig.Excel.TitleBackgroundColor);
            Assert.Equal("#FFFFFF", xmlConfig.Excel.RowBackgroundColor);
            Assert.Equal("#F1FBFF", xmlConfig.Excel.RowAlternateBackgroundColor);
            Assert.Equal("#9FAABF", xmlConfig.Excel.BorderColor);
            Assert.Equal("#CDDEF2", xmlConfig.Excel.ColumnHeaderBackgroundColor);
            Assert.Equal("#CDDEF2", xmlConfig.Excel.ColumnHeaderBackgroundColor);
        }
    }
}
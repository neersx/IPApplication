using System;
using System.IO;
using System.Net.Http;
using Aspose.Cells;
using Inprotech.Infrastructure.SearchResults.Exporters.Config;
using Inprotech.Infrastructure.SearchResults.Exporters.Excel;
using Inprotech.Infrastructure.SearchResults.Exporters.Utils;
using Inprotech.Infrastructure.Web;
using Inprotech.Integration;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.SearchResults.Exporters
{
    public class SimpleExcelExporterFacts
    {
        public SimpleExcelExporterFacts()
        {
            _helperService.LayoutSettings.Returns(new ExportConfig
            {
                Excel = new ExportConfig.ExcelConfig
                {
                    TitleColor = "#FFFFFF",
                    TitleBackgroundColor = "#FFFFFF",
                    RowBackgroundColor = "#FFFFFF",
                    RowAlternateBackgroundColor = "#FFFFFF",
                    ColumnHeaderBackgroundColor = "#FFFFFF",
                    BorderColor = "#FFFFFF"
                }
            });

            _helperService.Translate(Arg.Any<string>()).Returns(x => x[0]);
        }

        readonly IExportHelperService _helperService = Substitute.For<IExportHelperService>();

        readonly PagedResults _data = new PagedResults(new[]
        {
            new DataTransferObject
            {
                Field1 = "a",
                Field2 = "b",
                DateTimeField = Fixture.Today(),
                FieldWithNoHeader = Fixture.Integer(),
                DataSourceType = DataSourceType.UsptoPrivatePair
            },
            new DataTransferObject
            {
                Field1 = "c",
                Field2 = "d",
                DateTimeField = Fixture.PastDate(),
                FieldWithNoHeader = Fixture.Integer(),
                DataSourceType = DataSourceType.Epo
            }
        }, 2);

        ISimpleExcelExporter CreateSubject()
        {
            return new SimpleExcelExporter(_helperService);
        }

        public class DataTransferObject
        {
            [ExcelHeader("Field 1")]
            public string Field1 { get; set; }

            [ExcelHeader("Field 2")]
            public string Field2 { get; set; }

            [ExcelHeader("Date Time Field")]
            public DateTime? DateTimeField { get; set; }

            public int FieldWithNoHeader { get; set; }

            [ExcelHeader("Source", Converter = typeof(EnumToStringConverter))]
            public DataSourceType DataSourceType { get; set; }
        }

        [Fact]
        public void ShouldExportDataInOrderReturned()
        {
            var result = CreateSubject().Export(_data, Fixture.String());

            using (var content = (StreamContent) result.Content)
            using (var ms = new MemoryStream())
            {
                content.CopyToAsync(ms).Wait();
                ms.Seek(0, SeekOrigin.Begin);

                var firstWorksheet = new Workbook(ms).Worksheets[0];

                Assert.Equal("a", firstWorksheet.Cells[1, 0].Value);
                Assert.Equal("b", firstWorksheet.Cells[1, 1].Value);
                Assert.Equal(Fixture.Today(), firstWorksheet.Cells[1, 2].DateTimeValue);

                Assert.Equal("c", firstWorksheet.Cells[2, 0].Value);
                Assert.Equal("d", firstWorksheet.Cells[2, 1].Value);
                Assert.Equal(Fixture.PastDate(), firstWorksheet.Cells[2, 2].DateTimeValue);
            }
        }

        [Fact]
        public void ShouldExportExcel()
        {
            var fileName = Fixture.String();

            var result = CreateSubject().Export(_data, fileName);

            Assert.Equal("application/vnd.ms-excel", result.Content.Headers.ContentType.MediaType);
        }

        [Fact]
        public void ShouldExportHeaderFromDerivedExcelHeaderAttribute()
        {
            var result = CreateSubject().Export(_data, Fixture.String());

            using (var content = (StreamContent) result.Content)
            using (var ms = new MemoryStream())
            {
                content.CopyToAsync(ms).Wait();
                ms.Seek(0, SeekOrigin.Begin);

                var ws = new Workbook(ms).Worksheets[0];

                Assert.Equal("Field 1", ws.Cells[0, 0].Value);
                Assert.Equal("Field 2", ws.Cells[0, 1].Value);
                Assert.Equal("Date Time Field", ws.Cells[0, 2].Value);
                Assert.Equal("Source", ws.Cells[0, 3].Value);
            }
        }

        [Fact]
        public void ShouldExportInTheColumnOrderDefinedByDefault()
        {
            var result = CreateSubject().Export(_data, Fixture.String());

            using (var content = (StreamContent) result.Content)
            using (var ms = new MemoryStream())
            {
                content.CopyToAsync(ms).Wait();
                ms.Seek(0, SeekOrigin.Begin);

                var ws = new Workbook(ms).Worksheets[0];

                // reflection by way of Type.GetProperties is non-deterministic
                // http://stackoverflow.com/questions/9062235/get-properties-in-order-of-declaration-using-reflection
                // Will this test pass all the time?

                Assert.Equal("a", ws.Cells[1, 0].Value);
                Assert.Equal("b", ws.Cells[1, 1].Value);
                Assert.Equal(Fixture.Today(), ws.Cells[1, 2].DateTimeValue);
            }
        }

        [Fact]
        public void ShouldExportWithGivenFileName()
        {
            var fileName = Fixture.String();

            var result = CreateSubject().Export(_data, fileName);

            Assert.Equal(fileName, result.Content.Headers.ContentDisposition.FileName);
        }

        [Fact]
        public void ShouldUseConverter()
        {
            var subject = new SimpleExcelExporter(_helperService);

            var result = subject.Export(_data, Fixture.String());

            using (var content = (StreamContent) result.Content)
            using (var ms = new MemoryStream())
            {
                content.CopyToAsync(ms).Wait();
                ms.Seek(0, SeekOrigin.Begin);

                Assert.Equal("UsptoPrivatePair", new Workbook(ms).Worksheets[0].Cells[1, 3].Value);
                Assert.Equal("Epo", new Workbook(ms).Worksheets[0].Cells[2, 3].Value);
            }
        }

        [Fact]
        public void ShouldUseTranslations()
        {
            _helperService.Translate("Field 1").Returns("おはようございます");

            var subject = new SimpleExcelExporter(_helperService);

            var result = subject.Export(_data, Fixture.String());

            using (var content = (StreamContent) result.Content)
            using (var ms = new MemoryStream())
            {
                content.CopyToAsync(ms).Wait();
                ms.Seek(0, SeekOrigin.Begin);

                Assert.Equal("おはようございます", new Workbook(ms).Worksheets[0].Cells[0, 0].Value);
            }
        }
    }
}
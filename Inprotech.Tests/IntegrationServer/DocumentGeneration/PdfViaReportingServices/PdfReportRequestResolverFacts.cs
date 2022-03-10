using System.Collections.Generic;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Contracts.DocItems;
using Inprotech.Infrastructure.Formatting.Exports;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Integration.Reports;
using Inprotech.IntegrationServer.DocumentGeneration;
using Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.PdfViaReportingServices;
using Inprotech.Tests.Builders;
using Inprotech.Tests.Fakes;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Documents;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.DocumentGeneration.PdfViaReportingServices
{
    public class PdfReportRequestResolverFacts : FactBase
    {
        readonly IDocItemRunner _docItemRunner = Substitute.For<IDocItemRunner>();
        readonly IBackgroundProcessLogger<PdfReportRequestResolver> _logger = Substitute.For<IBackgroundProcessLogger<PdfReportRequestResolver>>();

        PdfReportRequestResolver CreateSubject()
        {
            return new PdfReportRequestResolver(Db, _logger, _docItemRunner);
        }

        [Fact]
        public async Task ShouldResolveEachReportParameterUsingDataItemConfigured()
        {
            var queueItem = new DocGenRequest
            {
                Id = Fixture.Integer(),
                LetterId = new Document().In(Db).Id
            };

            var reportParamName1 = Fixture.String();
            var reportParamName2 = Fixture.String();
            var reportParamResolvedValue1 = Fixture.String();
            var reportParamResolvedValue2 = Fixture.String();

            var reportDataItem1 = new DocItem {Name = Fixture.String(), EntryPointUsage = KnownEntryPoints.ActivityId}.In(Db);
            var reportDataItem2 = new DocItem {Name = Fixture.String(), EntryPointUsage = KnownEntryPoints.ActivityId}.In(Db);

            new ReportParameter {ItemId = reportDataItem1.Id, Name = reportParamName1, LetterId = (short) queueItem.LetterId}.In(Db);
            new ReportParameter {ItemId = reportDataItem2.Id, Name = reportParamName2, LetterId = (short) queueItem.LetterId}.In(Db);

            _docItemRunner.Run(reportDataItem1.Name, Arg.Any<Dictionary<string, object>>())
                          .Returns(new DataItemResultBuilder<string>(reportParamResolvedValue1).Build());
            _docItemRunner.Run(reportDataItem2.Name, Arg.Any<Dictionary<string, object>>())
                          .Returns(new DataItemResultBuilder<string>(reportParamResolvedValue2).Build());

            var subject = CreateSubject();

            var result = await subject.Resolve(queueItem);

            Assert.Equal(reportParamResolvedValue1, result.Parameters[reportParamName1]);
            Assert.Equal(reportParamResolvedValue2, result.Parameters[reportParamName2]);
        }

        [Fact]
        public async Task ShouldWarnIfAssignedDataItemIsNotUsingActivityIdEntryPoint()
        {
            var queueItem = new DocGenRequest
            {
                Id = Fixture.Integer(),
                LetterId = new Document().In(Db).Id
            };

            var validDataItem = new DocItem {Name = Fixture.String(), EntryPointUsage = KnownEntryPoints.ActivityId}.In(Db);
            var invalidDataItem = new DocItem {Name = Fixture.String(), EntryPointUsage = Fixture.Short()}.In(Db);

            new ReportParameter {ItemId = validDataItem.Id, Name = Fixture.String(), LetterId = (short) queueItem.LetterId}.In(Db);
            new ReportParameter {ItemId = invalidDataItem.Id, Name = Fixture.String(), LetterId = (short) queueItem.LetterId}.In(Db);

            _docItemRunner.Run(validDataItem.Name, Arg.Any<Dictionary<string, object>>())
                          .Returns(new DataItemResultBuilder<string>().Build());
            _docItemRunner.Run(invalidDataItem.Name, Arg.Any<Dictionary<string, object>>())
                          .Returns(new DataItemResultBuilder<string>().Build());

            var subject = CreateSubject();

            await subject.Resolve(queueItem);

            _logger.Received(1).Warning(Arg.Is<string>(_ => _.StartsWith("Unexpected Entry Point Value") && _.Contains(invalidDataItem.Name)));
            _logger.DidNotReceive().Warning(Arg.Is<string>(_ => _.StartsWith("Unexpected Entry Point Value") && _.Contains(validDataItem.Name)));
        }

        [Fact]
        public async Task ShouldDefaultToPdf()
        {
            var queueItem = new DocGenRequest
            {
                Id = Fixture.Integer(),
                LetterId = new Document().In(Db).Id
            };

            var subject = CreateSubject();

            var result = await subject.Resolve(queueItem);

            Assert.Equal(ReportExportFormat.Pdf, result.ReportExportFormat);
        }

        [Fact]
        public async Task ShouldReturnReportPathFromTemplatePath()
        {
            var queueItem = new DocGenRequest
            {
                Id = Fixture.Integer(),
                TemplateName = Fixture.String(),
                LetterId = new Document().In(Db).Id
            };

            var subject = CreateSubject();

            var result = await subject.Resolve(queueItem);

            Assert.Equal(queueItem.TemplateName, result.ReportPath);
        }
    }
}
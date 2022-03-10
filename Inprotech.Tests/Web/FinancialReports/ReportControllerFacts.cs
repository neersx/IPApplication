using System.IO;
using System.Net;
using System.Web;
using System.Web.Http;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Reports;
using Inprotech.Web.FinancialReports;
using InprotechKaizen.Model.Reports;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.FinancialReports
{
    public class ReportControllerFacts : FactBase
    {
        readonly IFileHelpers _fileHelpers = Substitute.For<IFileHelpers>();
        readonly ITaskSecurityProvider _taskSecurityProvider = Substitute.For<ITaskSecurityProvider>();

        ReportController CreateSubject()
        {
            return new ReportController(Db, _taskSecurityProvider, _fileHelpers);
        }

        [Fact]
        public void ReturnsRequestedReport()
        {
            var s = new SecurityTask().In(Db);

            var report = new ExternalReportBuilder
                {
                    SecurityTask = s
                }.Build()
                 .In(Db);

            _taskSecurityProvider.ListAvailableTasks()
                                 .Returns(new[]
                                 {
                                     new ValidSecurityTask(s.Id, false, false, false, true)
                                 });

            var path = @"Assets\Reports\Financial\" + report.Path;
            var content = new byte[0];

            _fileHelpers.Exists(path).Returns(true);
            _fileHelpers.OpenRead(path).Returns(new MemoryStream(content));

            var subject = CreateSubject();

            var r = subject.Get(report.Id);

            Assert.Equal("application/vnd.ms-excel", r.Content.Headers.ContentType.MediaType);
            Assert.Equal("attachment", r.Content.Headers.ContentDisposition.DispositionType);
            Assert.Equal(report.Path, r.Content.Headers.ContentDisposition.FileName);
        }

        [Fact]
        public void ThrowsForbiddenWhenRequestedReportIsUnauthorised()
        {
            var r = new ExternalReport().In(Db).Id;

            var exception = Assert.Throws<HttpResponseException>(() => CreateSubject().Get(r));

            Assert.Equal(HttpStatusCode.Forbidden, exception.Response.StatusCode);
        }

        [Fact]
        public void ThrowsNotFoundIfReportNotExistAtPhysicalLocation()
        {
            var s = new SecurityTask().In(Db);

            var r = new ExternalReportBuilder
                {
                    SecurityTask = s
                }.Build()
                 .In(Db);

            _taskSecurityProvider.ListAvailableTasks()
                                 .Returns(new[]
                                 {
                                     new ValidSecurityTask(s.Id, false, false, false, true)
                                 });

            var exception = Assert.Throws<HttpException>(() => CreateSubject().Get(r.Id));

            Assert.Equal((int) HttpStatusCode.NotFound, exception.GetHttpCode());
            Assert.Equal("The requested report does not exist.", exception.Message);
        }

        [Fact]
        public void ThrowsNotFoundWhenNonExistentReportIsRequested()
        {
            var exception = Assert.Throws<HttpResponseException>(() => CreateSubject().Get(Fixture.Integer()));

            Assert.Equal(HttpStatusCode.NotFound, exception.Response.StatusCode);
        }
    }
}
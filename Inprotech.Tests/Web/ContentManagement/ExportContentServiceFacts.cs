using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Web.ContentManagement;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.ContentManagement.Export;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Search.Export;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ContentManagement
{
    public class ExportContentServiceFacts
    {
        internal class ExportContentServiceFixture : IFixture<ExportContentService>
        {
            public ExportContentServiceFixture(InMemoryDbContext db)
            {
                Db = db;
                DateFunc = Substitute.For<Func<DateTime>>();
                DateFunc().Returns(Fixture.Today());
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new User("internal", false));
                Subject = new ExportContentService(db, DateFunc, SecurityContext);
            }

            public InMemoryDbContext Db { get; }
            public Func<DateTime> DateFunc { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public IExportContentService ExportContentService { get; set; }
            public ExportContentService Subject { get; }
        }

        public class GenerateContentIdMethod : FactBase
        {
            [Fact]
            public async Task ShouldReturnTheGeneratedContentId()
            {
                var f = new ExportContentServiceFixture(Db);
                var connectionId = Fixture.String();

                var contentId = await f.Subject.GenerateContentId(connectionId);

                var result = Db.Set<ReportContentResult>().FirstOrDefault(_ => _.Id == contentId);
                Assert.NotNull(result);
                Assert.Equal(result.Status, (int) StatusType.Started);
                Assert.Equal(result.ConnectionId, connectionId);
            }
        }

        public class GetContentByProcessIdMethod : FactBase
        {
            [Fact]
            public void ShouldReturnTheContentForProcessId()
            {
                var fileName = Fixture.String();
                var contentId = Fixture.Integer();
                var backgroundProcessId = Fixture.Integer();

                new ReportContentResult {Id = contentId, Content = new byte[100], FileName = fileName, BackgroundProcess = new BackgroundProcess {Id = backgroundProcessId}}.In(Db);

                var f = new ExportContentServiceFixture(Db);
                var response = f.Subject.GetContentByProcessId(backgroundProcessId);

                Assert.NotNull(response);
                Assert.Equal(response.FileName, fileName);
                Assert.Equal(response.ContentLength, 100);
            }

            [Fact]
            public void ShouldThrowExceptionIfProcessIdNotFound()
            {
                var f = new ExportContentServiceFixture(Db);

                var ex = Assert.Throws<ArgumentException>(() => f.Subject.GetContentByProcessId(1));

                Assert.Equal("ArgumentException", ex.GetType().Name);
                Assert.Equal("Invalid ProcessId", ex.Message);
            }
        }

        public class GetContentByIdMethod : FactBase
        {
            [Fact]
            public void ShouldReturnTheContentForId()
            {
                var fileName = Fixture.String();
                var contentId = Fixture.Integer();

                new ReportContentResult {Content = new byte[2], FileName = fileName, Status = (int) StatusType.Completed}.In(Db).WithKnownId(contentId);

                var f = new ExportContentServiceFixture(Db);
                var response = f.Subject.GetContentById(contentId);

                Assert.NotNull(response);
                Assert.Equal(response.FileName, fileName);
                Assert.Equal(response.ContentLength, 2);
            }

            [Fact]
            public void ShouldThrowExceptionIfProcessIdNotFound()
            {
                var f = new ExportContentServiceFixture(Db);

                var ex = Assert.Throws<ArgumentException>(() => f.Subject.GetContentById(1));

                Assert.Equal("ArgumentException", ex.GetType().Name);
                Assert.Equal("Invalid ContentId", ex.Message);
            }
        }

        public class RemoveContent : FactBase
        {
            [Fact]
            public void ShouldThrowExceptionForInvalidContentId()
            {
                var f = new ExportContentServiceFixture(Db);

                var ex = Assert.Throws<ArgumentException>(() => f.Subject.RemoveContent(1));

                Assert.Equal("ArgumentException", ex.GetType().Name);
                Assert.Equal("Invalid ContentId", ex.Message);
            }
        }
    }
}
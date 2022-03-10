using System.Collections.Generic;
using System.Threading.Tasks;
using System.Web.Http.Results;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.SearchResults.Exporters;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.ContentManagement;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;
using ICpaXmlExporter = Inprotech.Web.Processing.ICpaXmlExporter;

namespace Inprotech.Tests.Web.ContentManagement
{
    public class ExportContentControllerFacts
    {
        internal class SearchExportContentControllerFixture : IFixture<ExportContentController>
        {
            public SearchExportContentControllerFixture(InMemoryDbContext db)
            {
                Db = db;
                BackgroundProcessMessage = Substitute.For<IBackgroundProcessMessageClient>();
                SecurityContext = Substitute.For<ISecurityContext>();
                ExportContentService = Substitute.For<IExportContentService>();

                Subject = new ExportContentController(BackgroundProcessMessage, SecurityContext, ExportContentService);
            }

            public InMemoryDbContext Db { get; }
            public IBackgroundProcessMessageClient BackgroundProcessMessage { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public ICpaXmlExporter CpaXmlExporter { get; set; }
            public IExportContentService ExportContentService { get; set; }

            public ExportContentController Subject { get; }

            public SearchExportContentControllerFixture WithKnownUserId(int userId)
            {
                SecurityContext.User.Returns(new UserBuilder(Db).Build().WithKnownId(userId));
                return this;
            }

            public SearchExportContentControllerFixture WithBackgroundProcessList(int? processId)
            {
                if (processId.HasValue)
                {
                    BackgroundProcessMessage.Get(Arg.Any<IEnumerable<int>>(), Arg.Any<bool>()).Returns(new List<BackgroundProcessMessage> { new BackgroundProcessMessage { ProcessId = processId.Value } });
                    return this;
                }

                BackgroundProcessMessage.Get(Arg.Any<IEnumerable<int>>(), Arg.Any<bool>()).Returns(new List<BackgroundProcessMessage>());

                return this;
            }
        }

        public class GenerateContentIdMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallGenerateContentIdMethod()
            {
                var f = new SearchExportContentControllerFixture(Db);
                var connectionId = Fixture.String();
                f.ExportContentService.GenerateContentId(Arg.Any<string>()).Returns(1);
                
                var response = await f.Subject.GenerateContentId(connectionId);
                
                Assert.Equal(response, 1);

                f.ExportContentService.Received(1).GenerateContentId(connectionId).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class ContentByIdMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallContentByIdMethod()
            {
                var f = new SearchExportContentControllerFixture(Db);
                f.ExportContentService.GetContentById(Arg.Any<int>()).Returns(new ExportResult());

                await f.Subject.ContentById(1);
                f.ExportContentService.Received(1).GetContentById(1);
            }
        }

        public class ContentByProcessIdMethod : FactBase
        {
            [Fact]
            public async Task ShouldCallContentByProcessIdMethod()
            {
                var userId = Fixture.Integer();
                var processId = Fixture.Integer();

                var f = new SearchExportContentControllerFixture(Db).WithKnownUserId(userId)
                                                                  .WithBackgroundProcessList(processId);

                f.ExportContentService.GetContentByProcessId(Arg.Any<int>()).Returns(new ExportResult());

                await f.Subject.ContentByProcessId(processId);
                f.ExportContentService.Received(1).GetContentByProcessId(processId);
            }

            [Fact]
            public async Task ReturnsNotFoundIfUserDoesNotHaveAccessToProcessId()
            {
                var userId = Fixture.Integer();
                var processId = Fixture.Integer();

                var f = new SearchExportContentControllerFixture(Db)
                        .WithKnownUserId(userId)
                        .WithBackgroundProcessList(null);

                var result = await f.Subject.ContentByProcessId(processId);

                Assert.IsType<NotFoundResult>(result);
            }
        }

        public class RemoveContentsByConnection : FactBase
        {
            [Fact]
            public async Task ShouldCallContentByIdMethod()
            {
                var f = new SearchExportContentControllerFixture(Db);
                f.ExportContentService.RemoveContentsByConnection(Arg.Any<string>());
                var connectionId = Fixture.String();
                await f.Subject.RemoveContentsByConnection(connectionId);
                f.ExportContentService.Received().RemoveContentsByConnection(connectionId);
            }
        }
    }
}

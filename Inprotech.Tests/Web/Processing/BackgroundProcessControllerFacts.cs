using System;
using System.Collections.Generic;
using System.Linq;
using System.Web.Http.Results;
using System.Xml;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using Inprotech.Web.ContentManagement;
using Inprotech.Web.Processing;
using Inprotech.Web.Search.Export;
using InprotechKaizen.Model.BackgroundProcess;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;
using ICpaXmlExporter = Inprotech.Web.Processing.ICpaXmlExporter;

namespace Inprotech.Tests.Web.Processing
{
    public class BackgroundProcessControllerFacts
    {
        internal class BackgroundProcessControllerFixture : IFixture<BackgroundProcessController>
        {
            public BackgroundProcessControllerFixture(InMemoryDbContext db)
            {
                Db = db;
                BackgroundProcessMessage = Substitute.For<IBackgroundProcessMessageClient>();
                SecurityContext = Substitute.For<ISecurityContext>();
                CpaXmlExporter = Substitute.For<ICpaXmlExporter>();
                ExportContentService = Substitute.For<IExportContentService>();

                Subject = new BackgroundProcessController(BackgroundProcessMessage, SecurityContext, CpaXmlExporter, ExportContentService);
            }

            public InMemoryDbContext Db { get; }
            public IBackgroundProcessMessageClient BackgroundProcessMessage { get; set; }
            public ISecurityContext SecurityContext { get; set; }
            public ICpaXmlExporter CpaXmlExporter { get; set; }
            public IExportContentService ExportContentService { get; set; }

            public BackgroundProcessController Subject { get; }

            public BackgroundProcessControllerFixture WithKnownUserId(int userId)
            {
                SecurityContext.User.Returns(new UserBuilder(Db).Build().WithKnownId(userId));
                return this;
            }

            public BackgroundProcessControllerFixture WithCpaXmlExportedResponse(FileExportResponse resp)
            {
                CpaXmlExporter.DownloadCpaXmlExport(Arg.Any<int>(), Arg.Any<int>()).ReturnsForAnyArgs(resp);
                return this;
            }

            public BackgroundProcessControllerFixture WithBackgroundProcessList(int? processId)
            {
                if (processId.HasValue)
                {
                    BackgroundProcessMessage.Get(Arg.Any<IEnumerable<int>>(), Arg.Any<bool>()).Returns(new List<BackgroundProcessMessage> {new BackgroundProcessMessage {ProcessId = processId.Value}});
                    return this;
                }

                BackgroundProcessMessage.Get(Arg.Any<IEnumerable<int>>(), Arg.Any<bool>()).Returns(new List<BackgroundProcessMessage>());

                return this;
            }
        }

        public class GetMethod : FactBase
        {
            [Fact]
            public void DeleteBackgroundProcessMessages()
            {
                var bcFixture = new BackgroundProcessControllerFixture(Db);
                var processIds = new[] {1, 2};
                bcFixture.BackgroundProcessMessage.DeleteBackgroundProcessMessages(Arg.Any<int[]>()).Returns(true);
                var response = bcFixture.Subject.DeleteBackgroundProcessMessages(processIds);
                Assert.True(response);
                bcFixture.BackgroundProcessMessage.Received(1).DeleteBackgroundProcessMessages(processIds);
            }

            [Fact]
            public void ListOfBackgroundProcessMessages()
            {
                var bcFixture = new BackgroundProcessControllerFixture(Db);
                bcFixture.SecurityContext.User.Returns(new UserBuilder(Db).Build().WithKnownId(Fixture.Integer()));

                var backgroundProcess = new BackgroundProcess
                {
                    IdentityId = bcFixture.SecurityContext.User.Id,
                    ProcessType = BackgroundProcessType.GlobalCaseChange.ToString(),
                    Status = (int) StatusType.Completed,
                    StatusDate = DateTime.Now,
                    StatusInfo = string.Empty
                };
                var backgroundProcess1 = new BackgroundProcess
                {
                    IdentityId = bcFixture.SecurityContext.User.Id,
                    ProcessType = BackgroundProcessType.CpaXmlExport.ToString(),
                    Status = (int) StatusType.Error,
                    StatusDate = DateTime.Now,
                    StatusInfo = string.Empty
                };
                var messages = new[]
                {
                    new BackgroundProcessMessage
                    {
                        StatusType = (StatusType) backgroundProcess.Status,
                        ProcessId = backgroundProcess.Id,
                        ProcessType = (BackgroundProcessType) Enum.Parse(typeof(BackgroundProcessType), backgroundProcess.ProcessType),
                        StatusDate = backgroundProcess.StatusDate,
                        StatusInfo = backgroundProcess.StatusInfo,
                        IdentityId = backgroundProcess.IdentityId
                    },
                    new BackgroundProcessMessage
                    {
                        StatusType = (StatusType) backgroundProcess1.Status,
                        ProcessId = backgroundProcess1.Id,
                        ProcessType = (BackgroundProcessType) Enum.Parse(typeof(BackgroundProcessType), backgroundProcess1.ProcessType),
                        StatusDate = backgroundProcess1.StatusDate,
                        StatusInfo = backgroundProcess1.StatusInfo,
                        IdentityId = backgroundProcess1.IdentityId
                    }
                };
                bcFixture.BackgroundProcessMessage.Get(Arg.Any<int[]>(), Arg.Any<bool>()).Returns(messages.ToList());
                Db.Set<BackgroundProcess>().Add(backgroundProcess);
                Db.Set<BackgroundProcess>().Add(backgroundProcess1);

                var result = bcFixture.Subject.List();
                Assert.Equal(2, result.Count());
            }
        }

        public class PostMethod : FactBase
        {
            [Fact]
            public void CallsToGetCpaXmlExported()
            {
                var userId = Fixture.Integer();
                const int processId = 5;

                var f = new BackgroundProcessControllerFixture(Db).WithKnownUserId(userId)
                                                                  .WithBackgroundProcessList(processId);

                f.Subject.DownloadCpaXmlExport(processId);

                f.CpaXmlExporter.Received(1).DownloadCpaXmlExport(Arg.Is(processId), Arg.Is(userId));
            }

            [Fact]
            public void ReturnsNotFoundIfUserDoesNotHaveAccessToProcessId()
            {
                var userId = Fixture.Integer();
                const int processId = 5;

                var f = new BackgroundProcessControllerFixture(Db)
                        .WithKnownUserId(userId)
                        .WithBackgroundProcessList(null);

                var result = f.Subject.DownloadCpaXmlExport(processId);

                Assert.IsType<NotFoundResult>(result);
            }

            [Fact]
            public void ReturnsTheExportedXml()
            {
                var userId = Fixture.Integer();
                const int processId = 5;
                var fileExportResponse = new FileExportResponse {ContentType = "Abcd", FileName = "MaryHadALittleLamb.xml", Document = new XmlDocument()};

                var f = new BackgroundProcessControllerFixture(Db)
                        .WithKnownUserId(userId)
                        .WithCpaXmlExportedResponse(fileExportResponse)
                        .WithBackgroundProcessList(processId);

                var result = f.Subject.DownloadCpaXmlExport(processId);

                Assert.IsType<HttpFileDownloadResponseMessage>(result);

                Assert.NotNull(result);
            }
        }
    }
}
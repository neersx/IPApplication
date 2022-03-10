using System.Threading.Tasks;
using Inprotech.Infrastructure.Localisation;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Cases;
using Inprotech.Web.Cases.SummaryPreview;
using Inprotech.Web.Images;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Cases;
using InprotechKaizen.Model.Components.Cases.CriticalDates;
using InprotechKaizen.Model.Components.Cases.Reminders;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Cases
{
    public class CaseControllerFacts
    {
        public class GetSummary : FactBase
        {
            readonly string _taskPlannerRowKey = Fixture.String();
            readonly string _culture = Fixture.String();
            readonly int _caseId = Fixture.Integer();

            [Fact]
            public async Task ReturnsCaseData()
            {
                var caseHeader = new CaseSummary();

                var criticalDates = new[]
                {
                    new CriticalDate {RenewalYear = 99},
                    new CriticalDate {RenewalYear = 9}
                };

                var names = new[]
                {
                    new CaseSummaryName(),
                    new CaseSummaryName()
                };

                var f = new CaseControllerFixture(Db);

                f.PreferredCultureResolver.Resolve().Returns(_culture);

                f.CaseHeaderInfo.Retrieve(Arg.Any<int>(), _culture, _caseId)
                 .Returns((caseHeader, names));

                f.CriticalDatesResolver.Resolve(_caseId)
                 .Returns(criticalDates);

                var result = await f.Subject.GetSummary(_caseId);

                Assert.Equal(caseHeader, result.CaseData);
                Assert.Equal(criticalDates, result.Dates);
                Assert.Equal(names, result.Names);
            }

            [Fact]
            public async Task ReturnsTaskData()
            {
                var taskDetails = new TaskDetails
                {
                    DueDate = Fixture.Date(),
                    ReminderDate = Fixture.Date(),
                    NextReminderDate = Fixture.Date(),
                    EventDescription = Fixture.String(),
                    LongReminderMessage = Fixture.String(),
                    Name = Fixture.String()
                };

                var f = new CaseControllerFixture(Db);

                f.TaskPlannerDetailsResolver.Resolve(_taskPlannerRowKey)
                 .Returns(taskDetails);

                var result = await f.Subject.GetTaskDetailsSummary(_taskPlannerRowKey);

                Assert.Equal(taskDetails, result);
            }
        }

        public class GetImage : FactBase
        {
            [Fact]
            public void RetrievesImageAndResizes()
            {
                var f = new CaseControllerFixture(Db);
                var caseKey = Fixture.Integer();
                var imageData = new byte[0];
                var image = new Image(99) { ImageData = imageData }.In(Db);
                var returnData = new ResizedImage();
                f.ImageService.ResizeImage(null, null, null).ReturnsForAnyArgs(returnData);

                var result = f.Subject.GetImage(99, caseKey, 999, 9999);
                f.ImageService.Received(1).ResizeImage(image.ImageData, 999, 9999);
                Assert.Equal(returnData, result);
            }
        }
    }

    internal class CaseControllerFixture : IFixture<CaseController>
    {
        public CaseControllerFixture(InMemoryDbContext db)
        {
            var securityContext = Substitute.For<ISecurityContext>();
            securityContext.User.Returns(new User());

            PreferredCultureResolver = Substitute.For<IPreferredCultureResolver>();
            ImageService = Substitute.For<IImageService>();
            CaseHeaderInfo = Substitute.For<ICaseHeaderInfo>();
            CriticalDatesResolver = Substitute.For<ICriticalDatesResolver>();
            TaskPlannerDetailsResolver = Substitute.For<ITaskPlannerDetailsResolver>();

            Subject = new CaseController(db, securityContext, PreferredCultureResolver,
                                         CaseHeaderInfo, CriticalDatesResolver, ImageService, TaskPlannerDetailsResolver);
        }

        public IPreferredCultureResolver PreferredCultureResolver { get; }

        public ICriticalDatesResolver CriticalDatesResolver { get; set; }

        public ICaseHeaderInfo CaseHeaderInfo { get; }

        public IImageService ImageService { get; }

        public ITaskPlannerDetailsResolver TaskPlannerDetailsResolver { get; set; }
        public CaseController Subject { get; }
    }
}
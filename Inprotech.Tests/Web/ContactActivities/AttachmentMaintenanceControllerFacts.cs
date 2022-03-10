using System.Dynamic;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Attachment;
using Inprotech.Web.ContactActivities;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.ContactActivities
{
    public class AttachmentMaintenanceControllerFacts
    {
        public class ControllerTests : FactBase
        {
            [Fact]
            public async Task DeletesAttachment()
            {
                var f = new AttachmentMaintenanceControllerFixture();
                var attachment = new ActivityAttachmentModel {ActivityId = Fixture.Integer(), SequenceNo = 0};
                f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].DeleteAttachment(attachment, false).Returns(true);

                var result = await f.Subject.Delete(attachment);

                Assert.True(result);
                await f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].Received(1).DeleteAttachment(attachment, false);
            }

            [Fact]
            public async Task InsertsAttachment()
            {
                var f = new AttachmentMaintenanceControllerFixture();
                var input = new ActivityAttachmentModel {AttachmentName = Fixture.String()};
                var attachment = new ActivityAttachmentModel {ActivityId = Fixture.Integer(), SequenceNo = 0, AttachmentName = input.AttachmentName};
                f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].InsertAttachment(input).Returns(attachment);

                var result = await f.Subject.Create(input);

                Assert.NotNull(result);
                Assert.Equal(attachment, result);
                await f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].Received(1).InsertAttachment(input);
                await f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].DidNotReceive().UpdateAttachment(Arg.Any<ActivityAttachmentModel>());
            }

            [Fact]
            public async Task ReturnAttachment()
            {
                var f = new AttachmentMaintenanceControllerFixture().WithAttachmentData(1001, 0);
                f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].GetAttachment(Arg.Any<int>(), Arg.Any<int>()).Returns(new ActivityAttachmentModel());
                var result = await f.Subject.Get(1001, 0);
                await f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].Received(1).GetAttachment(1001, 0);
                Assert.NotNull(result);
            }

            [Fact]
            public async Task ReturnAttachmentMaintenanceViewFromActivityApi()
            {
                var activityDetails = new ActivityDetails();
                var viewDetailsFromActivityApi = new ExpandoObject();

                var f = new AttachmentMaintenanceControllerFixture();
                f.ActivityMaintenance.GetActivity(Arg.Any<int>()).ReturnsForAnyArgs(activityDetails);
                f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].ViewDetails(Arg.Any<int?>(), Arg.Any<int?>()).ReturnsForAnyArgs(viewDetailsFromActivityApi);

                var result = await f.Subject.View(101);
                f.ActivityMaintenance.Received(1).GetActivity(101).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].Received(1).ViewDetails(101).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].DidNotReceive().ViewDetails(activityDetails.ActivityNameId).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.Case].DidNotReceive().ViewDetails(activityDetails.ActivityCaseId, activityDetails.EventId).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(activityDetails, result.activityDetails);

                dynamic expectedResult = viewDetailsFromActivityApi;
                expectedResult.activityDetails = activityDetails;
                Assert.Equal(expectedResult, result);
            }

            [Fact]
            public async Task ReturnAttachmentMaintenanceViewFromCaseApi()
            {
                var activityDetails = new ActivityDetails {ActivityCaseId = 10, EventId = 90};
                var viewDetailsFromCaseApi = new ExpandoObject();

                var f = new AttachmentMaintenanceControllerFixture();
                f.ActivityMaintenance.GetActivity(Arg.Any<int>()).ReturnsForAnyArgs(activityDetails);
                f.AttachmentMaintenanceTypes[AttachmentFor.Case].ViewDetails(Arg.Any<int?>(), Arg.Any<int?>()).ReturnsForAnyArgs(viewDetailsFromCaseApi);

                var result = await f.Subject.View(101);
                f.ActivityMaintenance.Received(1).GetActivity(101).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.Case].Received(1).ViewDetails(activityDetails.ActivityCaseId, activityDetails.EventId).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].DidNotReceive().ViewDetails(activityDetails.ActivityNameId).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].DidNotReceive().ViewDetails(101).IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(activityDetails, result.activityDetails);

                dynamic expectedResult = viewDetailsFromCaseApi;
                expectedResult.activityDetails = activityDetails;
                Assert.Equal(expectedResult, result);
            }

            [Fact]
            public async Task ReturnAttachmentMaintenanceViewFromNameApi()
            {
                var activityDetails = new ActivityDetails {ActivityNameId = 10};
                var viewDetailsFromNameApi = new ExpandoObject();

                var f = new AttachmentMaintenanceControllerFixture();
                f.ActivityMaintenance.GetActivity(Arg.Any<int>()).ReturnsForAnyArgs(activityDetails);
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].ViewDetails(Arg.Any<int?>(), Arg.Any<int?>()).ReturnsForAnyArgs(viewDetailsFromNameApi);

                var result = await f.Subject.View(101);
                f.ActivityMaintenance.Received(1).GetActivity(101).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].Received(1).ViewDetails(activityDetails.ActivityNameId).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.Case].DidNotReceive().ViewDetails(activityDetails.ActivityCaseId, activityDetails.EventId).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].DidNotReceive().ViewDetails(101).IgnoreAwaitForNSubstituteAssertion();
                Assert.Equal(activityDetails, result.activityDetails);

                dynamic expectedResult = viewDetailsFromNameApi;
                expectedResult.activityDetails = activityDetails;
                Assert.Equal(expectedResult, result);
            }

            [Fact]
            public async Task UpdatesAttachment()
            {
                var f = new AttachmentMaintenanceControllerFixture();
                var input = new ActivityAttachmentModel {ActivityId = Fixture.Integer(), SequenceNo = 0, AttachmentName = Fixture.String()};
                f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].UpdateAttachment(input).Returns(input);

                var result = await f.Subject.Update(input);

                Assert.NotNull(result);
                Assert.Equal(input, result);
                await f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].Received(1).UpdateAttachment(input);
                await f.AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].DidNotReceive().InsertAttachment(Arg.Any<ActivityAttachmentModel>());
            }
        }

        class AttachmentMaintenanceControllerFixture : IFixture<AttachmentMaintenanceController>
        {
            public AttachmentMaintenanceControllerFixture()
            {
                AttachmentMaintenanceTypes = Substitute.For<IIndex<AttachmentFor, IActivityAttachmentMaintenance>>();
                ActivityMaintenance = Substitute.For<IActivityMaintenance>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                Subject = new AttachmentMaintenanceController(AttachmentMaintenanceTypes, ActivityMaintenance, SiteControlReader);
            }

            public IActivityMaintenance ActivityMaintenance { get; }
            public IIndex<AttachmentFor, IActivityAttachmentMaintenance> AttachmentMaintenanceTypes { get; }
            ISiteControlReader SiteControlReader { get; }
            public AttachmentMaintenanceController Subject { get; }

            public AttachmentMaintenanceControllerFixture WithAttachmentData(int activitId, int sequenceNo)
            {
                var data = new ActivityAttachmentModel
                {
                    AttachmentName = Fixture.String(),
                    ActivityCategoryId = Fixture.Integer(),
                    ActivityDate = Fixture.Monday,
                    ActivityType = Fixture.Integer(),
                    AttachmentType = Fixture.Integer(),
                    EventCycle = 1,
                    EventDescription = Fixture.String(),
                    IsPublic = true
                };
                AttachmentMaintenanceTypes[AttachmentFor.ContactActivity].GetAttachment(activitId, sequenceNo).Returns(data);
                SiteControlReader.Read<bool>(SiteControls.DocumentAttachmentsDisabled).Returns(true);
                return this;
            }
        }
    }
}
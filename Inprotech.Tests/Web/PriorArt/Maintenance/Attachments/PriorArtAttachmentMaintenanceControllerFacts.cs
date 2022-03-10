using System.Dynamic;
using System.Threading.Tasks;
using Inprotech.Tests.Extensions;
using Inprotech.Web.ContactActivities;
using Inprotech.Web.PriorArt.Maintenance.Attachments;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.PriorArt.Maintenance.Attachments
{
    public class PriorArtAttachmentMaintenanceControllerFacts : FactBase
    {
        [Fact]
        public async Task ReturnsViewDetails()
        {
            var priorArtId = Fixture.Integer();
            var caseId = Fixture.Integer();
            var f = new AttachmentMaintenanceControllerFixture();
            f.AttachmentMaintenanceTypes.ViewDetails(Arg.Any<int?>(), Arg.Any<int?>()).ReturnsForAnyArgs(new ExpandoObject());
            await f.Subject.View(priorArtId);
            f.AttachmentMaintenanceTypes.Received(1).ViewDetails(null).IgnoreAwaitForNSubstituteAssertion();
            await f.Subject.View(priorArtId, caseId);
            f.AttachmentMaintenanceTypes.Received(1).ViewDetails(caseId ).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task InsertsAttachment()
        {
            var f = new AttachmentMaintenanceControllerFixture();
            var priorArtId = Fixture.Integer();
            var input = new ActivityAttachmentModel {AttachmentName = Fixture.String()};
            var attachment = new ActivityAttachmentModel
            {
                ActivityId = Fixture.Integer(),
                SequenceNo = 0,
                AttachmentName = input.AttachmentName,
                PriorArtId = Fixture.Integer()
            };
            f.AttachmentMaintenanceTypes.InsertAttachment(input).Returns(attachment);

            var result = await f.Subject.Create(priorArtId, input);

            Assert.NotNull(result);
            Assert.Equal(attachment, result);
            f.AttachmentMaintenanceTypes.Received(1).InsertAttachment(input).IgnoreAwaitForNSubstituteAssertion();
            f.AttachmentMaintenanceTypes.DidNotReceive().UpdateAttachment(Arg.Any<ActivityAttachmentModel>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task DeletesAttachment()
        {
            var f = new AttachmentMaintenanceControllerFixture();
            var priorArtId = Fixture.Integer();
            var attachment = new ActivityAttachmentModel {ActivityId = Fixture.Integer(), SequenceNo = 0};
            f.AttachmentMaintenanceTypes.DeleteAttachment(attachment, Arg.Any<bool>()).Returns(true);

            var result = await f.Subject.Delete(priorArtId, attachment);

            Assert.True(result);
            f.AttachmentMaintenanceTypes.Received(1).DeleteAttachment(attachment).IgnoreAwaitForNSubstituteAssertion();
        }
    }

    internal class AttachmentMaintenanceControllerFixture : IFixture<AttachmentsMaintenanceController>
    {
        public AttachmentMaintenanceControllerFixture()
        {
            AttachmentMaintenanceTypes = Substitute.For<IActivityAttachmentMaintenance>();
            Subject = new AttachmentsMaintenanceController(AttachmentMaintenanceTypes);
        }

        public IActivityAttachmentMaintenance AttachmentMaintenanceTypes { get; }

        public AttachmentsMaintenanceController Subject { get; }

        public AttachmentMaintenanceControllerFixture WithAttachmentData(int priorArtId, int sequenceNo)
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
                IsPublic = true,
                PriorArtId = priorArtId
            };
            AttachmentMaintenanceTypes.GetAttachment(priorArtId, sequenceNo).Returns(data);
            return this;
        }
    }
}
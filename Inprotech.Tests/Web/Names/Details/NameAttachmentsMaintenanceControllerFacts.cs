using System.Dynamic;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using Inprotech.Web.Attachment;
using Inprotech.Web.ContactActivities;
using Inprotech.Web.Names.Details;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Names.Details
{
    public class NameAttachmentsMaintenanceControllerFacts
    {
        public class ControllerTests : FactBase
        {
            [Fact]
            public async Task DeletesAttachment()
            {
                var f = new AttachmentMaintenanceControllerFixture();

                var attachment = new ActivityAttachmentModel { ActivityId = Fixture.Integer(), SequenceNo = 0 };
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].DeleteAttachment(attachment, Arg.Any<bool>()).Returns(true);

                var result = await f.Subject.Delete(attachment, Fixture.Integer());

                Assert.True(result);
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].Received(1).DeleteAttachment(attachment, false).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task InsertsAttachment()
            {
                var f = new AttachmentMaintenanceControllerFixture();

                var input = new ActivityAttachmentModel { AttachmentName = Fixture.String() };
                var attachment = new ActivityAttachmentModel { ActivityId = Fixture.Integer(), SequenceNo = 0, AttachmentName = input.AttachmentName };
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].InsertAttachment(input).Returns(attachment);

                var result = await f.Subject.Create(input, Fixture.Integer());

                Assert.NotNull(result);
                Assert.Equal(attachment, result);
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].Received(1).InsertAttachment(input).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].DidNotReceive().UpdateAttachment(Arg.Any<ActivityAttachmentModel>()).IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ReturnAttachment()
            {
                var f = new AttachmentMaintenanceControllerFixture().WithAttachmentData(1001, 0);

                var result = await f.Subject.Get(1, 1001, 0);
                Assert.NotNull(result);
            }

            [Fact]
            public async Task ReturnAttachmentMaintenanceView()
            {
                var f = new AttachmentMaintenanceControllerFixture();
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].ViewDetails(Arg.Any<int?>(), Arg.Any<int?>()).ReturnsForAnyArgs(new ExpandoObject());
                await f.Subject.View(1234);
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].Received(1).ViewDetails(1234).IgnoreAwaitForNSubstituteAssertion();
            }
            
            [Fact]
            public async Task ReturnTaskSecurityPermission()
            {
                var f = new AttachmentMaintenanceControllerFixture();
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].ViewDetails(Arg.Any<int?>(), Arg.Any<int?>()).ReturnsForAnyArgs(new ExpandoObject());
                f.TaskSecurityProvider.HasAccessTo(ApplicationTask.MaintainNameAttachments, ApplicationTaskAccessLevel.Create).Returns(true);
                var result = await f.Subject.View(1234);
                Assert.Equal(true, result.canAddAttachments);
            }

            [Fact]
            public async Task UpdatesAttachment()
            {
                var f = new AttachmentMaintenanceControllerFixture();
                var input = new ActivityAttachmentModel { ActivityId = Fixture.Integer(), SequenceNo = 0, AttachmentName = Fixture.String() };
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].UpdateAttachment(input).Returns(input);

                var result = await f.Subject.Update(input, Fixture.Integer());

                Assert.NotNull(result);
                Assert.Equal(input, result);
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].Received(1).UpdateAttachment(input).IgnoreAwaitForNSubstituteAssertion();
                f.AttachmentMaintenanceTypes[AttachmentFor.Name].DidNotReceive().InsertAttachment(Arg.Any<ActivityAttachmentModel>()).IgnoreAwaitForNSubstituteAssertion();
            }
        }

        class AttachmentMaintenanceControllerFixture : IFixture<NameAttachmentMaintenanceController>
        {
            public AttachmentMaintenanceControllerFixture()
            {
                AttachmentMaintenanceTypes = Substitute.For<IIndex<AttachmentFor, IActivityAttachmentMaintenance>>();
                SiteControlReader = Substitute.For<ISiteControlReader>();
                TaskSecurityProvider = Substitute.For<ITaskSecurityProvider>();
                SiteControlReader.Read<bool>(SiteControls.DocumentAttachmentsDisabled).Returns(true);
                Subject = new NameAttachmentMaintenanceController(AttachmentMaintenanceTypes, SiteControlReader, TaskSecurityProvider);
            }

            public IIndex<AttachmentFor, IActivityAttachmentMaintenance> AttachmentMaintenanceTypes { get; }
            ISiteControlReader SiteControlReader { get; }
            public ITaskSecurityProvider TaskSecurityProvider { get; }
            public NameAttachmentMaintenanceController Subject { get; }

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
                AttachmentMaintenanceTypes[AttachmentFor.Name].GetAttachment(activitId, sequenceNo).Returns(data);
                return this;
            }
        }
    }
}
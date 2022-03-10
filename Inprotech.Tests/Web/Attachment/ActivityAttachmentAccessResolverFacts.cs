using System.Threading.Tasks;
using Inprotech.Infrastructure.Security;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Web.Attachment;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.ContactActivities;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.Attachment
{
    public class ActivityAttachmentAccessResolverFacts : FactBase
    {
        [Fact]
        public async Task ShouldReturnTrueIfInternalUser()
        {
            var fixture = new ActivityAttachmentAccessResolverFixture(Db);
            fixture.SecurityContext.User.Returns(new User(Fixture.String(), false));

            var result = await fixture.Subject.CheckAccessForExternalUser(Fixture.Integer(), Fixture.Integer());

            Assert.True(result);
        }

        [Fact]
        public async Task ShouldReturnTrueIfMatchingAttachmentWithNoCaseIdOrNameId()
        {
            var fixture = new ActivityAttachmentAccessResolverFixture(Db);
            fixture.SecurityContext.User.Returns(new User(Fixture.String(), true));
            var activityId = Fixture.Integer();
            var sequence = Fixture.Integer();
            new ActivityAttachment(activityId, sequence).In(Db).PublicFlag = 1;
            var activity = new Activity(activityId, Fixture.String(),
                                        new TableCode(Fixture.Integer(), Fixture.Short(), Fixture.String()),
                                        new TableCode(Fixture.Integer(), Fixture.Short(), Fixture.String())).In(Db);
            activity.CaseId = null;
            activity.ContactNameId = null;

            var result = await fixture.Subject.CheckAccessForExternalUser(activityId, sequence);

            Assert.True(result);
            fixture.CaseAuthorization
                   .DidNotReceive()
                   .Authorize(Arg.Any<int>(), Arg.Any<AccessPermissionLevel>()).IgnoreAwaitForNSubstituteAssertion();
            fixture.NameAuthorization
                   .DidNotReceive()
                   .Authorize(Arg.Any<int>(), Arg.Any<AccessPermissionLevel>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnTrueIfNoMatchingAttachment()
        {
            var fixture = new ActivityAttachmentAccessResolverFixture(Db);
            fixture.SecurityContext.User.Returns(new User(Fixture.String(), true));

            var result = await fixture.Subject.CheckAccessForExternalUser(Fixture.Integer(), Fixture.Integer());

            Assert.False(result);
        }

        [Fact]
        public async Task ShouldReturnValueInCaseAuthorisationIfCaseIdOnActivity()
        {
            var fixture = new ActivityAttachmentAccessResolverFixture(Db);
            fixture.SecurityContext.User.Returns(new User(Fixture.String(), true));
            var activityId = Fixture.Integer();
            var sequence = Fixture.Integer();
            new ActivityAttachment(activityId, sequence).In(Db).PublicFlag = 1;
            var activity = new Activity(activityId, Fixture.String(),
                                        new TableCode(Fixture.Integer(), Fixture.Short(), Fixture.String()),
                                        new TableCode(Fixture.Integer(), Fixture.Short(), Fixture.String())).In(Db);
            activity.CaseId = Fixture.Integer();
            activity.ContactNameId = null;
            fixture.CaseAuthorization.Authorize(Arg.Any<int>(), AccessPermissionLevel.Select).Returns(Task.FromResult(new AuthorizationResult {IsUnauthorized = false}));

            var result = await fixture.Subject.CheckAccessForExternalUser(activityId, sequence);
            Assert.True(result);
            fixture.CaseAuthorization
                   .Received(1)
                   .Authorize(activity.CaseId.Value, Arg.Any<AccessPermissionLevel>()).IgnoreAwaitForNSubstituteAssertion();
            fixture.NameAuthorization
                   .DidNotReceive()
                   .Authorize(Arg.Any<int>(), Arg.Any<AccessPermissionLevel>()).IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldReturnValueInNameAuthorisationIfNameIdOnActivity()
        {
            var fixture = new ActivityAttachmentAccessResolverFixture(Db);
            fixture.SecurityContext.User.Returns(new User(Fixture.String(), true));
            var activityId = Fixture.Integer();
            var sequence = Fixture.Integer();
            new ActivityAttachment(activityId, sequence).In(Db).PublicFlag = 1;
            var activity = new Activity(activityId, Fixture.String(),
                                        new TableCode(Fixture.Integer(), Fixture.Short(), Fixture.String()),
                                        new TableCode(Fixture.Integer(), Fixture.Short(), Fixture.String())).In(Db);
            activity.CaseId = null;
            activity.ContactNameId = Fixture.Integer();
            fixture.NameAuthorization.Authorize(Arg.Any<int>(), AccessPermissionLevel.Select).Returns(Task.FromResult(new AuthorizationResult {IsUnauthorized = false}));

            var result = await fixture.Subject.CheckAccessForExternalUser(activityId, sequence);

            Assert.True(result);
            fixture.CaseAuthorization
                   .DidNotReceive()
                   .Authorize(Arg.Any<int>(), Arg.Any<AccessPermissionLevel>()).IgnoreAwaitForNSubstituteAssertion();
            fixture.NameAuthorization
                   .Received(1)
                   .Authorize(activity.ContactNameId.Value, Arg.Any<AccessPermissionLevel>()).IgnoreAwaitForNSubstituteAssertion();
        }
    }

    public class ActivityAttachmentAccessResolverFixture : IFixture<ActivityAttachmentAccessResolver>
    {
        public ActivityAttachmentAccessResolverFixture(IDbContext db)
        {
            NameAuthorization = Substitute.For<INameAuthorization>();
            SecurityContext = Substitute.For<ISecurityContext>();
            CaseAuthorization = Substitute.For<ICaseAuthorization>();
            Subject = new ActivityAttachmentAccessResolver(db, SecurityContext, CaseAuthorization, NameAuthorization);
        }

        public INameAuthorization NameAuthorization { get; }

        public ISecurityContext SecurityContext { get; set; }
        public ICaseAuthorization CaseAuthorization { get; set; }

        public ActivityAttachmentAccessResolver Subject { get; }
    }
}
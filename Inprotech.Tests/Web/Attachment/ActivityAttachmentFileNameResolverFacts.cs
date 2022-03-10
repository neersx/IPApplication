using System.Threading.Tasks;
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
    public class ActivityAttachmentFileNameResolverFacts : FactBase
    {
        [Fact]
        public async Task ShouldFilterIfExternalUser()
        {
            new TopicSecurity {IsAvailable = true}.In(Db);
            var fixture = new ActivityAttachmentFileNameResolverFixture(Db);
            fixture.SecurityContext.User.Returns(new User(Fixture.String(), true));
            var activityKey = Fixture.Integer();
            var sequenceKey = Fixture.Integer();
            var attachment = new ActivityAttachment(activityKey, sequenceKey).In(Db);
            attachment.FileName = Fixture.String();
            new Activity(activityKey, Fixture.String(), new TableCode(), new TableCode()).In(Db);

            var result = fixture.Subject.Resolve(activityKey, sequenceKey);

            Assert.Null(result);
        }

        [Fact]
        public async Task ShouldReturnActivityAttachmentWhereActivityKeyMatches()
        {
            new TopicSecurity {IsAvailable = true}.In(Db);
            var fixture = new ActivityAttachmentFileNameResolverFixture(Db);
            fixture.SecurityContext.User.Returns(new User(Fixture.String(), false));
            var activityKey = Fixture.Integer();
            var sequenceKey = Fixture.Integer();
            var attachment = new ActivityAttachment(activityKey, sequenceKey).In(Db);
            attachment.FileName = Fixture.String();
            new Activity(activityKey, Fixture.String(), new TableCode(), new TableCode()).In(Db);

            var result = fixture.Subject.Resolve(activityKey, sequenceKey);

            Assert.Equal(attachment.FileName, result);
        }

        [Fact]
        public async Task ShouldReturnNullIfNoTopicSecurity()
        {
            var fixture = new ActivityAttachmentFileNameResolverFixture(Db);
            fixture.SecurityContext.User.Returns(new User(Fixture.String(), Fixture.Boolean()));

            var result = fixture.Subject.Resolve(Fixture.Integer(), Fixture.Integer());

            Assert.Null(result);
        }

        [Fact]
        public async Task ShouldReturnPublicResultsIfExternalUser()
        {
            new TopicSecurity {IsAvailable = true}.In(Db);
            var fixture = new ActivityAttachmentFileNameResolverFixture(Db);
            fixture.SecurityContext.User.Returns(new User(Fixture.String(), true));
            var activityKey = Fixture.Integer();
            var sequenceKey = Fixture.Integer();
            var attachment = new ActivityAttachment(activityKey, sequenceKey).In(Db);
            attachment.PublicFlag = 1;
            attachment.FileName = Fixture.String();
            new Activity(activityKey, Fixture.String(), new TableCode(), new TableCode()).In(Db);

            var result = fixture.Subject.Resolve(activityKey, sequenceKey);

            Assert.Equal(attachment.FileName, result);
        }
    }

    internal class ActivityAttachmentFileNameResolverFixture : IFixture<ActivityAttachmentFileNameResolver>
    {
        public ActivityAttachmentFileNameResolverFixture(IDbContext db)
        {
            SecurityContext = Substitute.For<ISecurityContext>();
            Subject = new ActivityAttachmentFileNameResolver(db, SecurityContext);
        }

        public ISecurityContext SecurityContext { get; }

        public ActivityAttachmentFileNameResolver Subject { get; }
    }
}
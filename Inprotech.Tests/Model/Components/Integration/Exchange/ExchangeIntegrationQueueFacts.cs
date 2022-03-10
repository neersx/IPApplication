using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Integration.Exchange;
using InprotechKaizen.Model.ExchangeIntegration;
using InprotechKaizen.Model.Security;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Integration.Exchange
{
    public class ExchangeIntegrationQueueFacts : FactBase
    {
        readonly IFileHelpers _fileHelpers = Substitute.For<IFileHelpers>();

        ExchangeIntegrationQueue CreateSubject()
        {
            return new ExchangeIntegrationQueue(Db, Fixture.Today, _fileHelpers);
        }

        [Fact]
        public async Task ShouldEnqueueWithIdentityAndNameOfRequester()
        {
            var user = new UserBuilder(Db).Build().In(Db);

            var ar = new CaseActivityRequest
            {
                IdentityId = user.Id
            }.In(Db);

            var subject = CreateSubject();

            await subject.QueueDraftEmailRequest(new DraftEmailProperties(), ar.Id);

            Assert.Equal(ar.IdentityId, Db.Set<ExchangeRequestQueueItem>().Single().IdentityId);
            Assert.Equal(user.Name.Id, Db.Set<ExchangeRequestQueueItem>().Single().StaffId);
        }

        [Fact]
        public async Task ShouldEnqueueWithActivityRequestedTime()
        {
            var ar = new CaseActivityRequest
            {
                IdentityId = new UserBuilder(Db).Build().In(Db).Id,
                WhenRequested = Fixture.PastDate()
            }.In(Db);

            var subject = CreateSubject();

            await subject.QueueDraftEmailRequest(new DraftEmailProperties(), ar.Id);

            Assert.Equal(ar.WhenRequested, Db.Set<ExchangeRequestQueueItem>().Single().SequenceDate);
        }

        [Fact]
        public async Task ShouldEnqueueNameOfRequesterWhenGeneratedViaClientServer()
        {
            var user = new UserBuilder(Db).Build().In(Db);
            var classicUser = new ClassicUser
            {
                UserIdentity = user
            }.In(Db);

            var ar = new CaseActivityRequest
            {
                SqlUser = classicUser.Id
            }.In(Db);

            var subject = CreateSubject();

            await subject.QueueDraftEmailRequest(new DraftEmailProperties(), ar.Id);

            Assert.Equal(user.Name.Id, Db.Set<ExchangeRequestQueueItem>().Single().StaffId);
        }

        [Fact]
        public async Task ShouldEnqueueAsDraftEmail()
        {
            var ar = new CaseActivityRequest
            {
                IdentityId = new UserBuilder(Db).Build().In(Db).Id
            }.In(Db);

            var subject = CreateSubject();

            await subject.QueueDraftEmailRequest(new DraftEmailProperties(), ar.Id);

            Assert.Equal((int) ExchangeRequestType.SaveDraftEmail, Db.Set<ExchangeRequestQueueItem>().Single().RequestTypeId);
        }

        [Fact]
        public async Task ShouldEnqueueReadyToProcess()
        {
            var ar = new CaseActivityRequest
            {
                IdentityId = new UserBuilder(Db).Build().In(Db).Id
            }.In(Db);

            var subject = CreateSubject();

            await subject.QueueDraftEmailRequest(new DraftEmailProperties(), ar.Id);

            Assert.Equal((int) ExchangeRequestStatus.Ready, Db.Set<ExchangeRequestQueueItem>().Single().StatusId);
        }

        [Fact]
        public async Task ShouldEnqueueWithDraftEmailProperties()
        {
            var ar = new CaseActivityRequest
            {
                IdentityId = new UserBuilder(Db).Build().In(Db).Id
            }.In(Db);

            var email = new DraftEmailProperties
            {
                Subject = Fixture.String(),
                Body = Fixture.String(),
                IsBodyHtml = Fixture.Boolean(),
                Mailbox = Fixture.String()
            };

            email.Recipients.Add(Fixture.String());
            email.CcRecipients.Add(Fixture.String());
            email.BccRecipients.Add(Fixture.String());
            email.Attachments.Add(new EmailAttachment
            {
                Content = Fixture.String(),
                ContentId = Fixture.String(),
                FileName = Fixture.String(),
                IsInline = Fixture.Boolean()
            });

            var subject = CreateSubject();

            await subject.QueueDraftEmailRequest(email, ar.Id);

            var db = Db.Set<ExchangeRequestQueueItem>();

            Assert.Equal(email.Recipients.Single(), db.Single().Recipients);
            Assert.Equal(email.CcRecipients.Single(), db.Single().CcRecipients);
            Assert.Equal(email.BccRecipients.Single(), db.Single().BccRecipients);
            Assert.Equal(JsonConvert.SerializeObject(email.Attachments), db.Single().Attachments);
        }
    }
}
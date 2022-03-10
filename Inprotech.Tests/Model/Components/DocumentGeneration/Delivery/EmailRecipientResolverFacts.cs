using System.Linq;
using System.Threading.Tasks;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.DocumentGeneration.Delivery;
using InprotechKaizen.Model.Documents;
using InprotechKaizen.Model.Names;
using InprotechKaizen.Model.Names.Correspondence;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.DocumentGeneration.Delivery
{
    public class EmailRecipientResolverFacts : FactBase
    {
        EmailRecipientResolver CreateSubject(EmailRecipients emailSpResult = null)
        {
            var emailSpRunner = Substitute.For<IEmailStoredProcedureRunner>();
            emailSpRunner.Run(Arg.Any<int>(), Arg.Any<string>())
                         .Returns(emailSpResult ?? new EmailRecipients());

            return new EmailRecipientResolver(Db, emailSpRunner);
        }

        [Fact]
        public async Task ShouldReturnRecipientEmailsFromNameTypesSpecifiedByTheCorrespondenceTypeOfTheLetter()
        {
            var instructorNameType = new NameTypeBuilder().Build().In(Db);

            var instructor = new CaseNameBuilder(Db)
            {
                Name = new NameBuilder(Db)
                {
                    NameTelecomAsEntities = true,
                    Email = new Telecommunication
                    {
                        TelecomNumber = "tony.stark@starkindustries.com"
                    }.In(Db)
                }.Build(),
                NameType = instructorNameType
            }.Build().In(Db);

            var ar = new CaseActivityRequest
            {
                CaseId = instructor.CaseId,
                DeliveryMethodId = new DeliveryMethod().In(Db).Id,
                LetterNo = new Document
                {
                    CorrespondType = new CorrespondTo
                    {
                        NameTypeId = instructor.NameType.NameTypeCode
                    }.In(Db).Id
                }.In(Db).Id
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Resolve(ar.Id);

            Assert.Equal("tony.stark@starkindustries.com", r.To.Single());
        }

        [Fact]
        public async Task ShouldReturnCcRecipientEmailsFromNameTypesSpecifiedByTheCorrespondenceTypeOfTheLetter()
        {
            var correspondenceCopiesToNameType = new NameTypeBuilder().Build().In(Db);

            var correspondenceContact = new CaseNameBuilder(Db)
            {
                Name = new NameBuilder(Db)
                {
                    NameTelecomAsEntities = true,
                    Email = new Telecommunication
                    {
                        TelecomNumber = "tony.stark@starkindustries.com"
                    }.In(Db)
                }.Build(),
                NameType = correspondenceCopiesToNameType
            }.Build().In(Db);

            var ar = new CaseActivityRequest
            {
                CaseId = correspondenceContact.CaseId,
                DeliveryMethodId = new DeliveryMethod().In(Db).Id,
                LetterNo = new Document
                {
                    CorrespondType = new CorrespondTo
                    {
                        CopiesToNameTypeId = correspondenceContact.NameType.NameTypeCode
                    }.In(Db).Id
                }.In(Db).Id
            }.In(Db);

            var subject = CreateSubject();

            var r = await subject.Resolve(ar.Id);

            Assert.Equal("tony.stark@starkindustries.com", r.Cc.Single());
        }

        [Fact]
        public async Task ShouldUseRecipientsFromConfiguredEmailStoredProcedureInDeliveryMethod()
        {
            var ar = new CaseActivityRequest
            {
                LetterNo = Fixture.Short(),
                DeliveryMethodId = new DeliveryMethod
                {
                    EmailStoredProcedure = Fixture.String()
                }.In(Db).Id
            }.In(Db);

            var subject = CreateSubject(new EmailRecipients("main@recipient", "cc1@recipient;cc2@recipient", "bcc@recipient")
            {
                Subject = Fixture.String()
            });
            
            var r = await subject.Resolve(ar.Id);

            Assert.Equal("main@recipient", r.To.Single());
            Assert.Contains("cc1@recipient", r.Cc);
            Assert.Contains("cc2@recipient", r.Cc);
            Assert.Equal("bcc@recipient", r.Bcc.Single());
            Assert.NotNull(r.Subject);
        }
    }
}
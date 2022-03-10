using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Validations;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Names;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Accounting.Billing.BillReview;
using InprotechKaizen.Model.Components.Accounting.Billing.Debtors;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Model.Components.Accounting.Billing.BillReview
{
    public class EmailRecipientsProviderFacts : FactBase
    {
        EmailRecipientsProvider CreateSubject(bool emailValidationValid = true)
        {
            var logger = Substitute.For<ILogger<EmailRecipientsProvider>>();
            var emailValidator = Substitute.For<IEmailValidator>();
            emailValidator.IsValid(Arg.Any<string>()).Returns(emailValidationValid);

            return new EmailRecipientsProvider(logger, Db, emailValidator);
        }

        [Fact]
        public async Task ShouldReturnMainEmailAddressInsteadOfAllEmailAddressOfTheName()
        {
            var name = new NameBuilder(Db)
            {
                Email = new Telecommunication { TelecomNumber = "accounts@clients.com"}.In(Db)
            }.Build().In(Db);
            
            var subject = CreateSubject();

            var r = await subject.Provide(name.Id, Enumerable.Empty<DebtorCopiesTo>());

            Assert.Equal("accounts@clients.com", r[name.Id].Single());
        }

        [Fact]
        public async Task ShouldReturnOtherEmailAddressOfTheNameIfMainEmailNotSet()
        {
            var emailType = new TableCode((int)KnownTelecomTypes.Email, Fixture.Short(), "Email").In(Db);

            var name = new NameBuilder(Db).Build().In(Db);
            name.MainEmailId = null;
            name.Telecoms.Add(new NameTelecom(name, new Telecommunication { TelecomType = emailType, TelecomNumber = "accounts@clients.com" }.In(Db)).In(Db));
            name.Telecoms.Add(new NameTelecom(name, new Telecommunication { TelecomType = emailType, TelecomNumber = "hellokitty@yahoo.com" }.In(Db)).In(Db));
            
            var subject = CreateSubject();

            var r = await subject.Provide(name.Id, Enumerable.Empty<DebtorCopiesTo>());

            Assert.Contains("accounts@clients.com", r[name.Id]);
            Assert.Contains("hellokitty@yahoo.com", r[name.Id]);
        }

        [Fact]
        public async Task ShouldReturnMainEmailAddressInsteadOfAllEmailAddressOfTheCopyToName()
        {
            var name = new NameBuilder(Db)
            {
                Email = new Telecommunication { TelecomNumber = "accounts@clients.com"}.In(Db)
            }.Build().In(Db);
            
            var subject = CreateSubject();

            var r = await subject.Provide(Fixture.Integer(),
                                          new[]
                                          {
                                              new DebtorCopiesTo
                                              {
                                                  CopyToNameId = name.Id
                                              }
                                          });

            Assert.Equal("accounts@clients.com", r[name.Id].Single());
        }

        [Fact]
        public async Task ShouldReturnOtherEmailAddressOfTheCopyToNameIfMainEmailNotSet()
        {
            var emailType = new TableCode((int)KnownTelecomTypes.Email, Fixture.Short(), "Email").In(Db);

            var name = new NameBuilder(Db).Build().In(Db);
            name.MainEmailId = null;
            name.Telecoms.Add(new NameTelecom(name, new Telecommunication { TelecomType = emailType, TelecomNumber = "accounts@clients.com" }.In(Db)).In(Db));
            name.Telecoms.Add(new NameTelecom(name, new Telecommunication { TelecomType = emailType, TelecomNumber = "hellokitty@yahoo.com" }.In(Db)).In(Db));
            
            var subject = CreateSubject();

            var r = await subject.Provide(Fixture.Integer(),
                                          new[]
                                          {
                                              new DebtorCopiesTo
                                              {
                                                  CopyToNameId = name.Id
                                              }
                                          });

            Assert.Contains("accounts@clients.com", r[name.Id]);
            Assert.Contains("hellokitty@yahoo.com", r[name.Id]);
        }

        [Fact]
        public async Task ShouldReturnMainEmailAddressInsteadOfAllEmailAddressOfTheContactOfTheCopyToName()
        {
            var name = new NameBuilder(Db)
            {
                Email = new Telecommunication { TelecomNumber = "accounts@clients.com"}.In(Db)
            }.Build().In(Db);
            
            var subject = CreateSubject();

            var r = await subject.Provide(Fixture.Integer(),
                                          new[]
                                          {
                                              new DebtorCopiesTo
                                              {
                                                  ContactNameId = name.Id
                                              }
                                          });

            Assert.Equal("accounts@clients.com", r[name.Id].Single());
        }

        [Fact]
        public async Task ShouldReturnOtherEmailAddressOfTheContactOfTheCopyToNameIfMainEmailNotSet()
        {
            var emailType = new TableCode((int)KnownTelecomTypes.Email, Fixture.Short(), "Email").In(Db);

            var name = new NameBuilder(Db).Build().In(Db);
            name.MainEmailId = null;
            name.Telecoms.Add(new NameTelecom(name, new Telecommunication { TelecomType = emailType, TelecomNumber = "accounts@clients.com" }.In(Db)).In(Db));
            name.Telecoms.Add(new NameTelecom(name, new Telecommunication { TelecomType = emailType, TelecomNumber = "hellokitty@yahoo.com" }.In(Db)).In(Db));
            
            var subject = CreateSubject();

            var r = await subject.Provide(Fixture.Integer(),
                                          new[]
                                          {
                                              new DebtorCopiesTo
                                              {
                                                  ContactNameId = name.Id
                                              }
                                          });

            Assert.Contains("accounts@clients.com", r[name.Id]);
            Assert.Contains("hellokitty@yahoo.com", r[name.Id]);
        }

        [Fact]
        public async Task ShouldReturnValidEmailAddressesOnly()
        {

            var name = new NameBuilder(Db)
            {
                Email = new Telecommunication { TelecomNumber = "junk1"}.In(Db)
            }.Build().In(Db);

            var nameCopyTo = new NameBuilder(Db)
            {
                Email = new Telecommunication { TelecomNumber = "junk2"}.In(Db)
            }.Build().In(Db);

            var nameCopyToContact = new NameBuilder(Db)
            {
                Email = new Telecommunication { TelecomNumber = "junk3"}.In(Db)
            }.Build().In(Db);
            
            const bool emailsValidates = false;
            var subject = CreateSubject(emailsValidates);

            var r = await subject.Provide(name.Id,
                                          new[]
                                          {
                                              new DebtorCopiesTo
                                              {
                                                  DebtorNameId = name.Id,
                                                  CopyToNameId = nameCopyTo.Id,
                                                  ContactNameId = nameCopyToContact.Id
                                              }
                                          });

            Assert.Empty(r[name.Id]);
            Assert.Empty(r[nameCopyTo.Id]);
            Assert.Empty(r[nameCopyToContact.Id]);
        }
    }
}
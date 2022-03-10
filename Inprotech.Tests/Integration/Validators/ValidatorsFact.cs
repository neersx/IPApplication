using Inprotech.Integration.Uspto.PrivatePair.Sponsorships;
using Inprotech.Integration.Validators;
using Inprotech.Tests.Fakes;
using System;
using Xunit;

namespace Inprotech.Tests.Integration.Validators
{
    public class ValidatorsFact : FactBase
    {
        public ValidatorsFact()
        {
            new Sponsorship { Id = 10001, SponsorName = "test1", SponsoredAccount = "test@test.com", CustomerNumbers = "1111,2222", IsDeleted = false }.In(Db);
            new Sponsorship { Id = 10002, SponsorName = "test2", SponsoredAccount = "test@test2.com", CustomerNumbers = "2222,3333", IsDeleted = true, DeletedBy = 45, DeletedOn = DateTime.Now }.In(Db);
        }

        [Theory]
        [InlineData("test@internal.com", true)]
        [InlineData("a.test@test.co", true)]
        [InlineData("TEST@test.com.au", true)]
        [InlineData("test@TEST.CO", false)]
        [InlineData("test@test", false)]
        [InlineData("test@test.c", false)]
        [InlineData("$test@test.com.cn", false)]
        public void EmailFormatValidator(string emailString, bool expected)
        {
            var emailValidator = new EmailFormatValidator();

            Assert.Equal(expected, emailValidator.IsValid(emailString));
        }

        [Theory]
        [InlineData("123224, 21989434", true)]
        [InlineData("r123224, 21989434", false)]
        [InlineData("123224_1, 21989434", false)]
        public void MemberNumberFormatValidator(string memberNumber, bool expected)
        {
            var customerNumberFormatValidator = new CustomerNumberFormatValidator();

            Assert.Equal(expected, customerNumberFormatValidator.IsValid(memberNumber));
        }

        [Theory]
        [InlineData("test@test.com", "test", true)]
        [InlineData("test@test.com", "test1", false)]
        public void DuplicateSponsorshipValidator(string emailAddress, string sponsorName, bool expected)
        {
            var duplicateSponsorshipValidator = new DuplicateSponsorshipValidator(Db);

            Assert.Equal(expected, duplicateSponsorshipValidator.IsValid(new SponsorshipModel() { SponsoredEmail = emailAddress, SponsorName = sponsorName }));
        }

        [Theory]
        [InlineData("1111,33333", false)]
        [InlineData("33333,33333", false)]
        [InlineData("55555", true)]
        public void DuplicateCustomerNumberValidator(string customerNumber, bool expected)
        {
            var duplicateCustomerNumberValidator = new DuplicateCustomerNumberValidator(Db);

            Assert.Equal(expected, duplicateCustomerNumberValidator.IsValid(new SponsorshipModel() { CustomerNumbers = customerNumber }));
        }

        [Theory]
        [InlineData("test@test.com", "test", "33333", true, null, null)]
        [InlineData("test@test.com", "test", "1111,33333", false, "duplicateCustomerNumber", "1111")]
        [InlineData("test@test.com", "test1", "55555", false, "duplicate", "")]
        public void DuplicateValidatorRoute(string emailAddress, string sponsorName, string customerNumber, bool expected, string expectedKey, string expectedError)
        {
            var duplicateValidator = new DuplicateCustomerNumberValidator(Db).Then(new DuplicateSponsorshipValidator(Db));
            var model = new SponsorshipModel() { SponsoredEmail = emailAddress, SponsorName = sponsorName, CustomerNumbers = customerNumber };
            var result = duplicateValidator.IsValid(model, out var error);

            Assert.Equal(expected, result);
            Assert.Equal(expectedKey, error?.Key);
            Assert.Equal(expectedError, error?.Error);
        }
    }
}

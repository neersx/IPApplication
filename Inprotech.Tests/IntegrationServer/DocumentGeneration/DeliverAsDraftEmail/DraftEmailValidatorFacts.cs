using System;
using Inprotech.IntegrationServer.DocumentGeneration.RequestTypes.DeliverAsDraftEmail;
using InprotechKaizen.Model.Components.Integration.Exchange;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.DocumentGeneration.DeliverAsDraftEmail
{
    public class DraftEmailValidatorFacts
    {
        [Fact]
        public void ShouldThrowExceptionWhenMailboxUnresolved()
        {
            var email = new DraftEmailProperties();

            email.Recipients.Add("me@paradise.com");

            var subject = new DraftEmailValidator();

            var exception = Assert.Throws<ApplicationException>(() => subject.EnsureValid(email));

            Assert.StartsWith("Mailbox must be specified", exception.Message);
        }

        [Fact]
        public void ShouldThrowExceptionWhenNoRecipientsFound()
        {
            var email = new DraftEmailProperties {Mailbox = Fixture.String()};

            var subject = new DraftEmailValidator();

            var exception = Assert.Throws<ApplicationException>(() => subject.EnsureValid(email));

            Assert.StartsWith("No email address has been specified", exception.Message);
        }

        [Fact]
        public void ShouldIndicateIsValid()
        {
            var email = new DraftEmailProperties {Mailbox = Fixture.String()};

            email.Recipients.Add("me@paradise.com");

            var subject = new DraftEmailValidator();

            Assert.True(subject.EnsureValid(email));
        }
    }
}
using System.Linq;
using System.Net.Mail;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Extensions;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.Notifications.Security;
using Inprotech.Integration.Security.Authorization;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Security.Authorization
{
    public class EmailNotificationFacts
    {
        readonly ISmtpClient _smtpClient = Substitute.For<ISmtpClient>();

        [Fact]
        public async Task CreateAndSendEmailToEachUserAdministrator()
        {
            var n = new Notification
            {
                From = "someone@some.org",
                Body = Fixture.String(),
                Subject = Fixture.String()
            };
            n.EmailRecipient.AddRange(new[]
            {
                new UserEmail
                {
                    Email = "abc@def.com"
                },
                new UserEmail
                {
                    Email = "def@ghi.com"
                }
            });

            await new EmailNotification(_smtpClient).Send(n);

            _smtpClient.Received(1).SendAsync(Arg.Is<MailMessage>(_ => !_.IsBodyHtml && _.Body == n.Body)).IgnoreAwaitForNSubstituteAssertion();
            _smtpClient.Received(1).SendAsync(Arg.Is<MailMessage>(_ => _.From.Address == n.From)).IgnoreAwaitForNSubstituteAssertion();
            _smtpClient.Received(1).SendAsync(Arg.Is<MailMessage>(_ => _.Subject == n.Subject)).IgnoreAwaitForNSubstituteAssertion();
            _smtpClient.Received(1).SendAsync(Arg.Is<MailMessage>(_ => _.To.First().Address == "abc@def.com")).IgnoreAwaitForNSubstituteAssertion();
            _smtpClient.Received(1).SendAsync(Arg.Is<MailMessage>(_ => _.To.Last().Address == "def@ghi.com")).IgnoreAwaitForNSubstituteAssertion();
        }
    }
}
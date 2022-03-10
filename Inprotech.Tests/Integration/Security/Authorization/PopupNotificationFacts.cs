using System;
using System.Linq;
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
    public class PopupNotificationFacts
    {
        readonly IBackgroundProcessMessageClient _messageClient = Substitute.For<IBackgroundProcessMessageClient>();

        [Fact]
        public async Task CreatePopupMessageForEachUserAdministrator()
        {
            var n = new Notification
            {
                Body = Fixture.String(),
                Subject = Fixture.String()
            };

            n.EmailRecipient.AddRange(new[]
            {
                new UserEmail
                {
                    Id = Fixture.Integer()
                },
                new UserEmail
                {
                    Id = Fixture.Integer()
                }
            });

            await new PopupNotification(_messageClient).Send(n);

            _messageClient.Received(1)
                          .SendAsync(Arg.Is<BackgroundProcessMessage>(_ => _.ProcessType == BackgroundProcessType.UserAdministration
                                                                           && _.StatusType == StatusType.Information
                                                                           && _.Message == n.Subject + Environment.NewLine + n.Body
                                                                           && _.IdentityId == n.EmailRecipient.First().Id))
                          .IgnoreAwaitForNSubstituteAssertion();

            _messageClient.Received(1)
                          .SendAsync(Arg.Is<BackgroundProcessMessage>(_ => _.ProcessType == BackgroundProcessType.UserAdministration
                                                                           && _.StatusType == StatusType.Information
                                                                           && _.Message == n.Subject + Environment.NewLine + n.Body
                                                                           && _.IdentityId == n.EmailRecipient.First().Id))
                          .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}
using System.Linq;
using Inprotech.Contracts.Messages.Channel;
using InprotechKaizen.Model.Components.Cases;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class GlobalNameChangeCaseIdProviderFacts
    {
        readonly GlobalNameChangeCaseIdProvider _provider = new GlobalNameChangeCaseIdProvider();

        [Fact]
        public void AddsCaseIdOnSubscription()
        {
            _provider.Handle(new GlobalNameChangeSubscribedMessage
            {
                ConnectionId = "1",
                CaseId = 1
            });

            _provider.Handle(new GlobalNameChangeSubscribedMessage
            {
                ConnectionId = "2",
                CaseId = 2
            });

            Assert.Equal(new[] {1, 2}, _provider.CaseIds.OrderBy(_ => _).ToArray());
        }

        [Fact]
        public void IfKeyAlreadyExists()
        {
            _provider.Handle(new GlobalNameChangeSubscribedMessage
            {
                ConnectionId = "1",
                CaseId = 1
            });

            _provider.Handle(new GlobalNameChangeSubscribedMessage
            {
                ConnectionId = "1",
                CaseId = 1
            });

            Assert.Equal(new[] {1}, _provider.CaseIds);
        }

        [Fact]
        public void IfKeyDoesNotExistShouldNotThrowException()
        {
            _provider.Handle(new GlobalNameChangeUnsubscribedMessage
            {
                ConnectionId = "1"
            });
        }

        [Fact]
        public void RemovesCaseIdOnUnsubscription()
        {
            _provider.Handle(new GlobalNameChangeSubscribedMessage
            {
                ConnectionId = "1",
                CaseId = 1
            });

            _provider.Handle(new GlobalNameChangeUnsubscribedMessage
            {
                ConnectionId = "1"
            });

            Assert.Empty(_provider.CaseIds);
        }

        [Fact]
        public void ReturnsUniqueCaseIds()
        {
            _provider.Handle(new GlobalNameChangeSubscribedMessage
            {
                ConnectionId = "1",
                CaseId = 1
            });

            _provider.Handle(new GlobalNameChangeSubscribedMessage
            {
                ConnectionId = "2",
                CaseId = 1
            });

            Assert.Equal(new[] {1}, _provider.CaseIds);
        }
    }
}
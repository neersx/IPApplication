using System.Linq;
using Inprotech.Contracts.Messages.Channel;
using InprotechKaizen.Model.Components.Cases;
using Xunit;

namespace Inprotech.Tests.Model.Components.Cases
{
    public class PolicingChangeCaseIdProviderFacts
    {
        readonly PolicingChangeCaseIdProvider _provider = new PolicingChangeCaseIdProvider();

        [Fact]
        public void AddsCaseIdOnSubscription()
        {
            _provider.Handle(new PolicingChangeSubscribedMessage
            {
                ConnectionId = "1",
                CaseId = 1
            });

            _provider.Handle(new PolicingChangeSubscribedMessage
            {
                ConnectionId = "2",
                CaseId = 2
            });

            Assert.Equal(new[] {1, 2}, _provider.CaseIds.OrderBy(_ => _).ToArray());
        }

        [Fact]
        public void IfKeyAlreadyExists()
        {
            _provider.Handle(new PolicingChangeSubscribedMessage
            {
                ConnectionId = "1",
                CaseId = 1
            });

            _provider.Handle(new PolicingChangeSubscribedMessage
            {
                ConnectionId = "1",
                CaseId = 1
            });

            Assert.Equal(new[] {1}, _provider.CaseIds);
        }

        [Fact]
        public void IfKeyDoesNotExistShouldNotThrowException()
        {
            _provider.Handle(new PolicingChangeUnsubscribedMessage
            {
                ConnectionId = "1"
            });
        }

        [Fact]
        public void RemovesCaseIdOnUnsubscription()
        {
            _provider.Handle(new PolicingChangeSubscribedMessage
            {
                ConnectionId = "1",
                CaseId = 1
            });

            _provider.Handle(new PolicingChangeUnsubscribedMessage
            {
                ConnectionId = "1"
            });

            Assert.Empty(_provider.CaseIds);
        }

        [Fact]
        public void ReturnsUniqueCaseIds()
        {
            _provider.Handle(new PolicingChangeSubscribedMessage
            {
                ConnectionId = "1",
                CaseId = 1
            });

            _provider.Handle(new PolicingChangeSubscribedMessage
            {
                ConnectionId = "2",
                CaseId = 1
            });

            Assert.Equal(new[] {1}, _provider.CaseIds);
        }
    }
}
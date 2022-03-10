using System;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Innography
{
    public class LinkConfirmedHandlerFacts
    {
        public LinkConfirmedHandlerFacts()
        {
            var cpaXml = Fixture.String();

            _subject = new LinkConfirmedHandler(_innographyIdUpdater, _cpaXmlProvider, _innographyIdFromCpaXml);

            _cpaXmlProvider.For(Arg.Any<int>())
                           .Returns(cpaXml);
        }

        readonly ICpaXmlProvider _cpaXmlProvider = Substitute.For<ICpaXmlProvider>();

        readonly IInnographyIdUpdater _innographyIdUpdater = Substitute.For<IInnographyIdUpdater>();

        readonly IInnographyIdFromCpaXml _innographyIdFromCpaXml = Substitute.For<IInnographyIdFromCpaXml>();

        readonly LinkConfirmedHandler _subject;

        [Theory]
        [InlineData(DataSourceType.Epo)]
        [InlineData(DataSourceType.UsptoPrivatePair)]
        [InlineData(DataSourceType.UsptoTsdr)]
        public async Task ShouldThrowExceptionIfNotificationNotForInnography(DataSourceType irrelevantSourceType)
        {
            var cn = new CaseNotification
            {
                Case = new Case
                {
                    Source = irrelevantSourceType
                }
            };

            await Assert.ThrowsAsync<InvalidOperationException>(async () => { await _subject.Handle(cn); });
        }

        [Fact]
        public async Task ShouldHandleCpaXmlPassedIn()
        {
            var caseId = Fixture.Integer();
            var cpaXml = Fixture.String();
            var innographyId = Fixture.String();
            _innographyIdFromCpaXml.Resolve(cpaXml)
                                   .Returns(innographyId);

            await _subject.Handle(caseId, cpaXml);

            _innographyIdUpdater.Received(1)
                                .Update(caseId, innographyId)
                                .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ShouldThrowExceptionIfNoCaseIdProvided()
        {
            var cn = new CaseNotification
            {
                Case = new Case
                {
                    Source = DataSourceType.IpOneData
                }
            };

            await Assert.ThrowsAsync<InvalidOperationException>(async () => { await _subject.Handle(cn); });
        }

        [Fact]
        public async Task ShouldThrowExceptionIfNotificationDoesNotHaveACase()
        {
            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await _subject.Handle(new CaseNotification()); });
        }

        [Fact]
        public async Task ShouldThrowExceptionIfNotificationNotProvided()
        {
            await Assert.ThrowsAsync<ArgumentNullException>(async () => { await _subject.Handle(null); });
        }

        [Fact]
        public async Task ShouldUpdateInnographyId()
        {
            var caseId = Fixture.Integer();

            var cn = new CaseNotification
            {
                Case = new Case
                {
                    Source = DataSourceType.IpOneData,
                    CorrelationId = caseId
                }
            };

            var innographyId = Fixture.String();
            _innographyIdFromCpaXml.Resolve(Arg.Any<string>())
                                   .Returns(innographyId);

            await _subject.Handle(cn);

            _innographyIdUpdater.Received(1)
                                .Update(caseId, innographyId)
                                .IgnoreAwaitForNSubstituteAssertion();
        }
    }
}
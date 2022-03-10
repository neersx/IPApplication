using System;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Diagnostics;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Innography;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Innography
{
    public class SourceCaseMatchRejectableFacts
    {
        readonly ICpaXmlProvider _cpaXmlProvider = Substitute.For<ICpaXmlProvider>();
        readonly IInnographyIdFromCpaXml _innographyIdFromCpaXml = Substitute.For<IInnographyIdFromCpaXml>();
        readonly IInnographyIdUpdater _innographyIdUpdater = Substitute.For<IInnographyIdUpdater>();
        readonly ICaseAuthorization _caseAuthorization = Substitute.For<ICaseAuthorization>();

        readonly int _caseId = Fixture.Integer();

        [Fact]
        public async Task DiscoversInnographyIdThenCallsReject()
        {
            _caseAuthorization.Authorize(_caseId, AccessPermissionLevel.Update).Returns(x =>
            {
                var caseId = (int) x[0];
                return new AuthorizationResult(caseId, true, false, null);
            });

            var notificationId = Fixture.Integer();
            var inprotechCaseId = _caseId;
            var innographyId = Fixture.String();
            var cpaXml = Fixture.String();

            var cn = new CaseNotification
            {
                Id = notificationId,
                Case = new Case
                {
                    CorrelationId = inprotechCaseId
                }
            };

            _cpaXmlProvider.For(notificationId)
                           .Returns(cpaXml);

            _innographyIdFromCpaXml.Resolve(cpaXml)
                                   .Returns(innographyId);

            var subject = new SourceCaseMatchRejectable(_cpaXmlProvider, _innographyIdFromCpaXml, _innographyIdUpdater, _caseAuthorization);

            await subject.Reject(cn);

            _innographyIdUpdater.Received(1)
                                .Reject(inprotechCaseId, innographyId)
                                .IgnoreAwaitForNSubstituteAssertion();
        }

        [Fact]
        public async Task ThrowsExceptionWhenCaseDeniedByEthicalWallOrUpdateDenined()
        {
            const bool caseUnauthorised = true;

            _caseAuthorization.Authorize(_caseId, AccessPermissionLevel.Update).Returns(x =>
            {
                var caseId = (int) x[0];
                return new AuthorizationResult(caseId, true, caseUnauthorised, "SomeDataSecurityProblem");
            });

            var cn = new CaseNotification
            {
                Case = new Case
                {
                    CorrelationId = _caseId
                }
            };

            var subject = new SourceCaseMatchRejectable(_cpaXmlProvider, _innographyIdFromCpaXml, _innographyIdUpdater, _caseAuthorization);

            await Assert.ThrowsAsync<DataSecurityException>(async () => await subject.Reject(cn));
        }

        [Fact]
        public async Task ThrowsExceptionWhenCaseNotFound()
        {
            var cn = new CaseNotification
            {
                Case = new Case
                {
                    CorrelationId = Fixture.Integer()
                }
            };

            _caseAuthorization.Authorize(Arg.Any<int>(), AccessPermissionLevel.Update).Returns(x =>
            {
                var caseId = (int) x[0];
                return new AuthorizationResult(caseId, false, true, Fixture.String());
            });

            var subject = new SourceCaseMatchRejectable(_cpaXmlProvider, _innographyIdFromCpaXml, _innographyIdUpdater, _caseAuthorization);

            await Assert.ThrowsAsync<InvalidOperationException>(async () => await subject.Reject(cn));
        }

        [Fact]
        public async Task ThrowsExceptionWhenInprotechCaseIdNotFound()
        {
            var cn = new CaseNotification
            {
                Case = new Case
                {
                    CorrelationId = null
                }
            };

            var subject = new SourceCaseMatchRejectable(_cpaXmlProvider, _innographyIdFromCpaXml, _innographyIdUpdater, _caseAuthorization);

            await Assert.ThrowsAsync<ArgumentException>(async () => await subject.Reject(cn));
        }
    }
}
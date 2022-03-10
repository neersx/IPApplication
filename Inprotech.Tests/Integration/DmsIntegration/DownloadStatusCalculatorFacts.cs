using Inprotech.Integration;
using Inprotech.Integration.DmsIntegration;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Settings;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.DmsIntegration
{
    public class DownloadStatusCalculatorFacts
    {
        public class GetDownloadStatusMethod
        {
            readonly DownloadStatusCalculatorFixture _fixture = new DownloadStatusCalculatorFixture();

            [Fact]
            public void ShouldReturnDownloadedWhenDmsIntegrationIsDisabledForPrivatePair()
            {
                _fixture.Settings.IsEnabledFor(DataSourceType.UsptoPrivatePair).Returns(false);

                Assert.Equal(DocumentDownloadStatus.Downloaded,
                             _fixture.Subject.GetDownloadStatus(DataSourceType.UsptoPrivatePair));
            }

            [Fact]
            public void ShouldReturnDownloadedWhenDmsIntegrationIsDisabledForTsdr()
            {
                _fixture.Settings.IsEnabledFor(DataSourceType.UsptoTsdr).Returns(false);

                Assert.Equal(DocumentDownloadStatus.Downloaded,
                             _fixture.Subject.GetDownloadStatus(DataSourceType.UsptoTsdr));
            }

            [Fact]
            public void ShouldReturnSendingToDmsWhenDmsIntegrationIsEnabledForPrivatePair()
            {
                _fixture.Settings.IsEnabledFor(DataSourceType.UsptoPrivatePair).Returns(true);

                Assert.Equal(DocumentDownloadStatus.ScheduledForSendingToDms,
                             _fixture.Subject.GetDownloadStatus(DataSourceType.UsptoPrivatePair));
            }

            [Fact]
            public void ShouldReturnSendingToDmsWhenDmsIntegrationIsEnabledForTsdr()
            {
                _fixture.Settings.IsEnabledFor(DataSourceType.UsptoTsdr).Returns(true);

                Assert.Equal(DocumentDownloadStatus.ScheduledForSendingToDms,
                             _fixture.Subject.GetDownloadStatus(DataSourceType.UsptoTsdr));
            }
        }

        public class CanChangeDmsStatusMethod
        {
            /* State Transitions */
            /* 
                Pending --> [Downloaded | Failed]  (DMS Not Enabled)
                Pending --> [ScheduledForSendingToDms | Failed] (DMS Enabled)

                ScheduledForSendingToDms --> SendingToDms --> [SentToDms | FailedToSendToDms]

                Instigated by end user from front end
                [SendToDms | FailedToSendToDms | Downloaded] --> ScheduledForSendingToDms
            */

            readonly DownloadStatusCalculatorFixture _fixture = new DownloadStatusCalculatorFixture();

            [Theory]
            [InlineData(DocumentDownloadStatus.SentToDms)]
            [InlineData(DocumentDownloadStatus.SendingToDms)]
            public void CannotSendToDmsWhenAlreadyInProgress(DocumentDownloadStatus fromStatus)
            {
                const DocumentDownloadStatus targetStatus = DocumentDownloadStatus.SendToDms;

                Assert.False(_fixture
                             .Subject
                             .CanChangeDmsStatus(fromStatus, targetStatus));
            }

            [Theory]
            [InlineData(DocumentDownloadStatus.Downloaded)]
            [InlineData(DocumentDownloadStatus.FailedToSendToDms)]
            public void CanIndicateDocumentTobePickedUpForDmsIntegration(DocumentDownloadStatus fromStatus)
            {
                /* this state is to indicate that a document is to be sent to DMS, 
                    no DMS process is started yet */
                const DocumentDownloadStatus targetStatus = DocumentDownloadStatus.ScheduledForSendingToDms;

                Assert.True(_fixture
                            .Subject
                            .CanChangeDmsStatus(fromStatus, targetStatus));
            }

            [Theory]
            [InlineData(DocumentDownloadStatus.Failed)]
            [InlineData(DocumentDownloadStatus.Pending)]
            [InlineData(DocumentDownloadStatus.SendingToDms)]
            [InlineData(DocumentDownloadStatus.SentToDms)]
            [InlineData(DocumentDownloadStatus.ScheduledForSendingToDms)]
            public void CannotPickupDocumentForDmsWhenItIsNotDownloadedOrFailedOrAlreadyInProgress(DocumentDownloadStatus fromStatus)
            {
                /* this state is to indicate that a document is to be sent to DMS, 
                    no DMS process is started yet */
                const DocumentDownloadStatus targetStatus = DocumentDownloadStatus.ScheduledForSendingToDms;

                Assert.False(_fixture
                             .Subject
                             .CanChangeDmsStatus(fromStatus, targetStatus));
            }

            [Theory]
            [InlineData(DocumentDownloadStatus.Failed)]
            [InlineData(DocumentDownloadStatus.Pending)]
            [InlineData(DocumentDownloadStatus.SendingToDms)]
            [InlineData(DocumentDownloadStatus.SentToDms)]
            [InlineData(DocumentDownloadStatus.SendToDms)]
            [InlineData(DocumentDownloadStatus.Downloaded)]
            public void DocumentCannotBeIndicatedToCommenceSendingFromOtherStates(DocumentDownloadStatus fromStatus)
            {
                const DocumentDownloadStatus targetStatus = DocumentDownloadStatus.SendingToDms;

                Assert.False(_fixture
                             .Subject
                             .CanChangeDmsStatus(fromStatus, targetStatus));
            }

            [Fact]
            public void CanIndicateDocumentCommencesDmsSendingProcess()
            {
                const DocumentDownloadStatus targetStatus = DocumentDownloadStatus.SendingToDms;
                const DocumentDownloadStatus fromStatus = DocumentDownloadStatus.ScheduledForSendingToDms;

                Assert.True(_fixture
                            .Subject
                            .CanChangeDmsStatus(fromStatus, targetStatus));
            }

            [Fact]
            public void CannotSendToDmsWhenDocumentIsNotYetDownloaded()
            {
                const DocumentDownloadStatus targetStatus = DocumentDownloadStatus.SendToDms;
                const DocumentDownloadStatus fromStatus = DocumentDownloadStatus.Pending;

                Assert.False(_fixture
                             .Subject
                             .CanChangeDmsStatus(fromStatus, targetStatus));
            }

            [Fact]
            public void CanStartDmsProgressForDocumentIndicatedForDmsIntegration()
            {
                const DocumentDownloadStatus targetStatus = DocumentDownloadStatus.SendToDms;
                const DocumentDownloadStatus fromStatus = DocumentDownloadStatus.ScheduledForSendingToDms;

                Assert.True(_fixture
                            .Subject
                            .CanChangeDmsStatus(fromStatus, targetStatus));
            }

            [Fact]
            public void CanStartDmsProgressForDocumentsFailedToBeSentToDmsPreviously()
            {
                /* state change instigated by end user from front end */

                const DocumentDownloadStatus targetStatus = DocumentDownloadStatus.SendToDms;
                const DocumentDownloadStatus fromStatus = DocumentDownloadStatus.FailedToSendToDms;

                Assert.True(_fixture
                            .Subject
                            .CanChangeDmsStatus(fromStatus, targetStatus));
            }

            [Fact]
            public void CanStartDmsProgressForDownloadedDocuments()
            {
                const DocumentDownloadStatus targetStatus = DocumentDownloadStatus.SendToDms;
                const DocumentDownloadStatus fromStatus = DocumentDownloadStatus.Downloaded;

                Assert.True(_fixture
                            .Subject
                            .CanChangeDmsStatus(fromStatus, targetStatus));
            }
        }

        public class DownloadStatusCalculatorFixture : IFixture<DownloadStatusCalculator>
        {
            public DownloadStatusCalculatorFixture()
            {
                Settings = Substitute.For<IDmsIntegrationSettings>();

                Subject = new DownloadStatusCalculator(Settings);
            }

            public IDmsIntegrationSettings Settings { get; set; }

            public DownloadStatusCalculator Subject { get; set; }
        }
    }
}
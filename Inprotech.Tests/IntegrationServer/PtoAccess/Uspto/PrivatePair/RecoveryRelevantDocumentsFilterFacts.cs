using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Schedules;
using Inprotech.IntegrationServer.PtoAccess.Recovery;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class RecoveryRelevantDocumentsFilterFacts
    {
        public class ForMethod
        {
            const string CustomerNumber = "12345";

            [Fact]
            public async Task ReturnsDocumentsAsRequired()
            {
                var f = new RecoveryRelevantDocumentFilterFixture()
                    .HasDocumentIdsToRecover(CustomerNumber, 1, 2, 3, 4, 5);

                var r = await f.Subject.For(
                                            new Session
                                            {
                                                CustomerNumber = CustomerNumber
                                            },
                                            new ApplicationDownload(),
                                            Fixture.String());

                Assert.Equal(f.ReturnedDocuments, r);

                f.ProvideDocumentsToRecover.Received(1).GetDocumentsToRecover(
                                                                              Arg.Is<IEnumerable<int>>(x => x.SequenceEqual(new[] {1, 2, 3, 4, 5})));
            }

            [Fact]
            public async Task ReturnsDocumentsFromApplicationThatIsInScope()
            {
                var f = new RecoveryRelevantDocumentFilterFixture()
                    .WithoutAnyDocumentIdsToRecover(CustomerNumber);

                var session = new Session
                {
                    CustomerNumber = CustomerNumber
                };

                var applicationDownload = new ApplicationDownload();

                var r = await f.Subject.For(session, applicationDownload, Fixture.String());

                Assert.Equal(f.ReturnedDocuments, r);

#pragma warning disable 4014
                f.ProvideDocumentsToRecover.Received(1).GetDocumentsToRecover(session, applicationDownload);
#pragma warning restore 4014
            }
        }

        public class RecoveryRelevantDocumentFilterFixture : IFixture<RecoveryRelevantDocumentsFilter>
        {
            public RecoveryRelevantDocumentFilterFixture()
            {
                UsptoScheduleSettings = Substitute.For<IReadScheduleSettings>();
                UsptoScheduleSettings
                    .GetTempStorageId(Arg.Any<int>())
                    .Returns(Fixture.Integer());

                ManageRecoveryInfo = Substitute.For<IManageRecoveryInfo>();

                ReturnedDocuments = new List<AvailableDocument>();

                ProvideDocumentsToRecover = Substitute.For<IProvideDocumentsToRecover>();
                ProvideDocumentsToRecover.GetDocumentsToRecover(Arg.Any<IEnumerable<int>>())
                                         .Returns(ReturnedDocuments);

                ProvideDocumentsToRecover.GetDocumentsToRecover(Arg.Any<Session>(), Arg.Any<ApplicationDownload>())
                                         .Returns(Task.FromResult(ReturnedDocuments.AsEnumerable()));

                Subject = new RecoveryRelevantDocumentsFilter(
                                                              UsptoScheduleSettings,
                                                              ManageRecoveryInfo,
                                                              ProvideDocumentsToRecover);
            }

            public List<AvailableDocument> ReturnedDocuments { get; }

            public IReadScheduleSettings UsptoScheduleSettings { get; set; }

            public IManageRecoveryInfo ManageRecoveryInfo { get; set; }

            public IProvideDocumentsToRecover ProvideDocumentsToRecover { get; set; }

            public RecoveryRelevantDocumentsFilter Subject { get; }

            public RecoveryRelevantDocumentFilterFixture HasDocumentIdsToRecover(string customerNumber,
                                                                                 params int[] documentIds)
            {
                ManageRecoveryInfo.GetIds(Arg.Any<long>())
                                  .Returns(
                                           new[]
                                           {
                                               new RecoveryInfo
                                               {
                                                   CorrelationId = customerNumber,
                                                   DocumentIds = documentIds
                                               }
                                           }
                                          );

                return this;
            }

            public RecoveryRelevantDocumentFilterFixture WithoutAnyDocumentIdsToRecover(string customerNumber)
            {
                ManageRecoveryInfo.GetIds(Arg.Any<long>())
                                  .Returns(
                                           new[]
                                           {
                                               new RecoveryInfo
                                               {
                                                   CorrelationId = customerNumber
                                               }
                                           }
                                          );

                return this;
            }
        }
    }
}
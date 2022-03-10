using System.Net;
using System.Net.Http;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class SourceCaseRejectionFacts
    {
        public class RejectMethod : FactBase
        {
            readonly IIndex<DataSourceType, ISourceCaseMatchRejectable> _rejectables = Substitute.For<IIndex<DataSourceType, ISourceCaseMatchRejectable>>();
            readonly INotificationResponse _notification = Substitute.For<INotificationResponse>();

            [Theory]
            [InlineData(DataSourceType.IpOneData)]
            [InlineData(DataSourceType.UsptoPrivatePair)]
            public async Task CallsSourceCaseRejectThenMarkRejected(DataSourceType anySource)
            {
                var cn = new CaseNotification
                {
                    Case = new Case
                    {
                        Source = anySource
                    }.In(Db),
                    Type = CaseNotificateType.CaseUpdated
                }.In(Db);

                var sourceMatchRejectable = Substitute.For<ISourceCaseMatchRejectable>();

                // ReSharper disable once UnusedVariable
                _rejectables.TryGetValue(anySource, out var scmr)
                            .Returns(x =>
                            {
                                x[1] = sourceMatchRejectable;
                                return true;
                            });

                _notification.For(Arg.Any<CaseNotification>())
                             .Returns(x =>
                             {
                                 var cn1 = (CaseNotification) x[0];
                                 return new CaseNotificationResponse(cn1, cn1.Body);
                             });

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.Reject(cn.Id);

                Assert.Equal(CaseNotificateType.Rejected, cn.Type);
                Assert.Equal("rejected", ((CaseNotificationResponse) r).Type);

                sourceMatchRejectable
                    .Received(1)
                    .Reject(cn)
                    .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ReturnsBadRequestForErrorNotification()
            {
                var cn = new CaseNotification
                {
                    Case = new Case().In(Db),
                    Type = CaseNotificateType.Error
                }.In(Db);

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.Reject(cn.Id);

                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseMessage) r).StatusCode);
            }

            [Fact]
            public async Task ReturnsBadRequestForRejectionAgainstUnsupportedDataSource()
            {
                var cn = new CaseNotification
                {
                    Case = new Case().In(Db),
                    Type = CaseNotificateType.CaseUpdated
                }.In(Db);

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.Reject(cn.Id);

                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseMessage) r).StatusCode);
            }

            [Fact]
            public async Task ReturnsBadRequestIfNotificationNotFound()
            {
                var notificationId = Fixture.Integer();

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.Reject(notificationId);

                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseMessage) r).StatusCode);
            }
        }

        public class ReverseRejectMethod : FactBase
        {
            readonly IIndex<DataSourceType, ISourceCaseMatchRejectable> _rejectables = Substitute.For<IIndex<DataSourceType, ISourceCaseMatchRejectable>>();
            readonly INotificationResponse _notification = Substitute.For<INotificationResponse>();

            [Theory]
            [InlineData(DataSourceType.IpOneData)]
            [InlineData(DataSourceType.UsptoPrivatePair)]
            public async Task CallsSourceCaseRejectThenMarkAvailable(DataSourceType anySource)
            {
                var cn = new CaseNotification
                {
                    Case = new Case
                    {
                        CorrelationId = Fixture.Integer(),
                        Source = anySource
                    }.In(Db),
                    Type = CaseNotificateType.Rejected
                }.In(Db);

                var sourceMatchRejectable = Substitute.For<ISourceCaseMatchRejectable>();

                // ReSharper disable once UnusedVariable
                _rejectables.TryGetValue(anySource, out var scmr)
                            .Returns(x =>
                            {
                                x[1] = sourceMatchRejectable;
                                return true;
                            });

                _notification.For(Arg.Any<CaseNotification>())
                             .Returns(x =>
                             {
                                 var cn1 = (CaseNotification) x[0];
                                 return new CaseNotificationResponse(cn1, cn1.Body);
                             });

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.ReverseRejection(cn.Id);

                Assert.Equal(CaseNotificateType.CaseUpdated, cn.Type);
                Assert.Equal("case-comparison", ((CaseNotificationResponse) r).Type);
                Assert.False(((CaseNotificationResponse) r).IsReviewed);

                sourceMatchRejectable
                    .Received(1)
                    .ReverseReject(cn)
                    .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task ReturnsBadRequestForErrorNotification()
            {
                var cn = new CaseNotification
                {
                    Case = new Case().In(Db),
                    Type = CaseNotificateType.Error
                }.In(Db);

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.ReverseRejection(cn.Id);

                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseMessage) r).StatusCode);
            }

            [Fact]
            public async Task ReturnsBadRequestForNonRejectedNotification()
            {
                var cn = new CaseNotification
                {
                    Case = new Case().In(Db),
                    Type = CaseNotificateType.CaseUpdated
                }.In(Db);

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.ReverseRejection(cn.Id);

                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseMessage) r).StatusCode);
            }

            [Fact]
            public async Task ReturnsBadRequestForRejectionAgainstUnsupportedDataSource()
            {
                var cn = new CaseNotification
                {
                    Case = new Case().In(Db),
                    Type = CaseNotificateType.Rejected
                }.In(Db);

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.ReverseRejection(cn.Id);

                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseMessage) r).StatusCode);
            }

            [Fact]
            public async Task ReturnsBadRequestIfNotificationNotFound()
            {
                var notificationId = Fixture.Integer();

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.ReverseRejection(notificationId);

                Assert.Equal(HttpStatusCode.BadRequest, ((HttpResponseMessage) r).StatusCode);
            }
        }

        public class CheckRejectabilityMethod : FactBase
        {
            readonly IIndex<DataSourceType, ISourceCaseMatchRejectable> _rejectables = Substitute.For<IIndex<DataSourceType, ISourceCaseMatchRejectable>>();
            readonly INotificationResponse _notification = Substitute.For<INotificationResponse>();

            [Theory]
            [InlineData(DataSourceType.IpOneData)]
            public async Task ReturnsCanRejectIfRejectableExists(DataSourceType anySource)
            {
                var cn = new CaseNotification
                {
                    Case = new Case
                    {
                        Source = anySource
                    }.In(Db),
                    Type = CaseNotificateType.CaseUpdated
                }.In(Db);

                var sourceMatchRejectable = Substitute.For<ISourceCaseMatchRejectable>();

                // ReSharper disable once UnusedVariable
                _rejectables.TryGetValue(anySource, out var scmr)
                            .Returns(x =>
                            {
                                x[1] = sourceMatchRejectable;
                                return true;
                            });

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.CheckRejectability(cn.Id);

                Assert.True(r.CanReject);
                Assert.False(r.CanReverseReject);
            }

            [Theory]
            [InlineData(DataSourceType.IpOneData)]
            [InlineData(DataSourceType.UsptoPrivatePair)]
            public async Task ReturnsCanReverseRejectIfNotificationWasPreviouslyRejected(DataSourceType anySource)
            {
                var cn = new CaseNotification
                {
                    Case = new Case
                    {
                        Source = anySource
                    }.In(Db),
                    Type = CaseNotificateType.Rejected
                }.In(Db);

                var sourceMatchRejectable = Substitute.For<ISourceCaseMatchRejectable>();

                // ReSharper disable once UnusedVariable
                _rejectables.TryGetValue(anySource, out var scmr)
                            .Returns(x =>
                            {
                                x[1] = sourceMatchRejectable;
                                return true;
                            });

                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.CheckRejectability(cn.Id);

                Assert.True(r.CanReject);
                Assert.True(r.CanReverseReject);
            }

            [Fact]
            public async Task ReturnsFalseIfNotificationNotFound()
            {
                var subject = new SourceCaseRejection(Db, _rejectables, _notification);

                var r = await subject.CheckRejectability(Fixture.Integer());

                Assert.False(r.CanReject);
                Assert.False(r.CanReverseReject);
            }
        }
    }
}
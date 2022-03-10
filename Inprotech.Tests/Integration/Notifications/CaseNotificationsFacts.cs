using System.Linq;
using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Security;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Security;
using InprotechKaizen.Model.Components.Security;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.Notifications
{
    public class CaseNotificationsFacts
    {
        public class CountByDataSourceTypeMethod : FactBase
        {
            [Fact]
            public async Task ReturnCountForEachDataSource()
            {
                var f = new CaseNotificationFixture(Db)
                        .WithNotification(DataSourceType.UsptoPrivatePair)
                        .WithNotification(DataSourceType.UsptoPrivatePair)
                        .WithNotification(DataSourceType.UsptoPrivatePair)
                        .WithNotification(DataSourceType.UsptoPrivatePair)
                        .WithNotification(DataSourceType.UsptoPrivatePair)
                        .WithNotification(DataSourceType.UsptoPrivatePair)
                        .WithNotification(DataSourceType.UsptoTsdr)
                        .WithNotification(DataSourceType.UsptoTsdr)
                        .WithNotification(DataSourceType.UsptoTsdr)
                        .WithNotification(DataSourceType.UsptoTsdr);

                var r = await f.Subject.CountByDataSourceType();

                Assert.NotNull(r);
                Assert.Equal(6, r[DataSourceType.UsptoPrivatePair]);
                Assert.Equal(4, r[DataSourceType.UsptoTsdr]);
            }
        }

        public class ThatSatisfiesMethod : FactBase
        {
            [Fact]
            public void ReturnErrorNotifications()
            {
                var f = new CaseNotificationFixture(Db)
                        .WithNotification(DataSourceType.UsptoPrivatePair, CaseNotificateType.Error)
                        .WithNotification(DataSourceType.UsptoPrivatePair, CaseNotificateType.CaseUpdated);

                var r = f.Subject.ThatSatisfies(new SearchParameters
                         {
                             IncludeErrors = true
                         })
                         .ToArray();

                Assert.Contains(r, _ => _.Type == CaseNotificateType.Error);
                Assert.Contains(r, _ => _.Type == CaseNotificateType.CaseUpdated);
            }

            [Fact]
            public void ReturnsNotificationFromAnyDataSources()
            {
                var f = new CaseNotificationFixture(Db)
                        .WithNotification(DataSourceType.UsptoPrivatePair)
                        .WithNotification(DataSourceType.UsptoTsdr)
                        .WithNotification(DataSourceType.Epo);

                var r = f.Subject.ThatSatisfies(new SearchParameters()).ToArray();

                Assert.Equal(3, r.Count());
            }

            [Fact]
            public void ReturnsNotificationFromSelectedDataSource()
            {
                var f = new CaseNotificationFixture(Db)
                        .WithNotification(DataSourceType.UsptoPrivatePair)
                        .WithNotification(DataSourceType.UsptoTsdr)
                        .WithNotification(DataSourceType.Epo);

                var r = f.Subject.ThatSatisfies(new SearchParameters
                         {
                             DataSourceTypes = new[]
                             {
                                 DataSourceType.UsptoPrivatePair
                             }
                         })
                         .ToArray();

                Assert.Single(r);
            }

            [Fact]
            public void ReturnsOnlyNotificationsWithoutErrors()
            {
                var f = new CaseNotificationFixture(Db)
                        .WithNotification(DataSourceType.UsptoPrivatePair, CaseNotificateType.Error)
                        .WithNotification(DataSourceType.UsptoPrivatePair, CaseNotificateType.CaseUpdated);

                var r = f.Subject.ThatSatisfies(new SearchParameters
                         {
                             IncludeErrors = false
                         })
                         .ToArray();

                Assert.DoesNotContain(r, _ => _.Type == CaseNotificateType.Error);
                Assert.Contains(r, _ => _.Type == CaseNotificateType.CaseUpdated);
            }

            [Fact]
            public void ReturnsOnlyUnreviewedNotifications()
            {
                var f = new CaseNotificationFixture(Db)
                        .WithNotification(DataSourceType.UsptoPrivatePair, CaseNotificateType.CaseUpdated, true)
                        .WithNotification(DataSourceType.UsptoPrivatePair, CaseNotificateType.CaseUpdated);

                var r = f.Subject.ThatSatisfies(new SearchParameters
                         {
                             IncludeReviewed = false
                         })
                         .ToArray();

                Assert.Single(r);
                Assert.True(r.All(_ => !_.IsReviewed));
            }

            [Fact]
            public void ReturnsReviewedErrorNotifications()
            {
                var f = new CaseNotificationFixture(Db)
                    .WithNotification(DataSourceType.UsptoPrivatePair, CaseNotificateType.Error, true);

                var r = f.Subject.ThatSatisfies(new SearchParameters
                         {
                             IncludeReviewed = true,
                             IncludeErrors = true
                         })
                         .ToArray();

                Assert.Single(r);
            }

            [Fact]
            public void ReturnsReviewedNotifications()
            {
                var f = new CaseNotificationFixture(Db)
                        .WithNotification(DataSourceType.UsptoPrivatePair, CaseNotificateType.CaseUpdated, true)
                        .WithNotification(DataSourceType.UsptoPrivatePair, CaseNotificateType.CaseUpdated);

                var r = f.Subject.ThatSatisfies(new SearchParameters
                         {
                             IncludeReviewed = true
                         })
                         .ToArray();

                Assert.Equal(2, r.Count());
            }
        }

        public class ReviewMethod : FactBase
        {
            [Fact]
            public async Task CallReviewedHandlerIfAvailable()
            {
                var c = new CaseNotificationBuilder(Db)
                {
                    SourceType = DataSourceType.IpOneData
                }.Build();
                var f = new CaseNotificationFixture(Db);

                var h = Substitute.For<ISourceNotificationReviewedHandler>();
                f.ReviewedNotificationHandlers.TryGetValue(DataSourceType.IpOneData, out _)
                 .Returns(x =>
                 {
                     x[1] = h;
                     return true;
                 });

                await f.Subject.MarkReviewed(c.Id);

                Assert.True(c.IsReviewed);
                Assert.Equal(f.SecurityContext.User.Id, c.ReviewedBy);

                h.Received(1)
                 .Handle(c)
                 .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task MarksNotificationAsReviewed()
            {
                var c = new CaseNotificationBuilder(Db).Build();
                var f = new CaseNotificationFixture(Db);

                await f.Subject.MarkReviewed(c.Id);

                Assert.True(c.IsReviewed);
                Assert.Equal(f.SecurityContext.User.Id, c.ReviewedBy);
            }
        }

        public class CaseNotificationFixture : IFixture<CaseNotifications>
        {
            readonly InMemoryDbContext _db;

            public CaseNotificationFixture(InMemoryDbContext db)
            {
                _db = db;
                SecurityContext = Substitute.For<ISecurityContext>();
                SecurityContext.User.Returns(new UserBuilder(db).Build());

                EthicalWall = Substitute.For<IEthicalWall>();
                CaseAuthorization = Substitute.For<ICaseAuthorization>();

                ReviewedNotificationHandlers = Substitute.For<IIndex<DataSourceType, ISourceNotificationReviewedHandler>>();

                Subject = new CaseNotifications(db, SecurityContext, EthicalWall, CaseAuthorization, ReviewedNotificationHandlers);
            }

            public IEthicalWall EthicalWall { get; set; }

            public ICaseAuthorization CaseAuthorization { get; set; }

            public ISecurityContext SecurityContext { get; set; }

            public IIndex<DataSourceType, ISourceNotificationReviewedHandler> ReviewedNotificationHandlers { get; set; }

            public CaseNotifications Subject { get; set; }

            public CaseNotificationFixture WithNotification(DataSourceType sourceType,
                                                            CaseNotificateType? type = CaseNotificateType.CaseUpdated, bool? isReviewed = false)
            {
                new CaseNotification
                {
                    Type = type.GetValueOrDefault(),
                    IsReviewed = isReviewed.GetValueOrDefault(),
                    Case = new Case
                    {
                        Source = sourceType
                    }
                }.In(_db);

                return this;
            }
        }
    }
}
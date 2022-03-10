using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration;
using Inprotech.Integration.Notifications;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Newtonsoft.Json.Linq;
using Xunit;
using Case = InprotechKaizen.Model.Cases.Case;

namespace Inprotech.Tests.Integration.Notifications
{
    public class NotificationResponseFacts
    {
        public class ForMultipleMethod : FactBase
        {
            public ForMultipleMethod()
            {
                _subject = new NotificationResponse(Db);
            }

            readonly NotificationResponse _subject;

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr, "123", "hello")]
            [InlineData(DataSourceType.Epo, "234", "world")]
            [InlineData(DataSourceType.UsptoPrivatePair, "345", null)]
            public void ReturnsCaseNotificationResponse(DataSourceType source, string number, string title)
            {
                var notification = new[]
                {
                    new CaseNotificationBuilder(Db)
                    {
                        SourceType = source,
                        ApplicationNumber = number,
                        UpdatedOn = Fixture.PastDate(),
                        Body = title
                    }.Build()
                };

                var r = _subject.For(notification).Single();

                Assert.Equal(source, r.DataSourceType);
                Assert.Equal(number, r.AppNum);
                Assert.Equal(title, r.Title);
                Assert.NotNull(r.Type);
            }

            [Fact]
            public void ReturnsErrorNotification()
            {
                var notification = new[]
                {
                    new CaseNotificationBuilder(Db)
                    {
                        SourceType = DataSourceType.UsptoPrivatePair,
                        ApplicationNumber = "1234",
                        UpdatedOn = Fixture.Today(),
                        Body = new JObject
                        {
                            {"the error", "details"}
                        }.ToString(),
                        Type = CaseNotificateType.Error
                    }.Build()
                };

                var r = _subject.For(notification).Single();

                Assert.Equal("Error", r.Title);
                Assert.Equal("details", ((JObject) r.Body)["the error"]);
            }

            [Fact]
            public void ReturnsRejectedMatchNotification()
            {
                var title = Fixture.String();
                var number = Fixture.String();

                var notification = new[]
                {
                    new CaseNotificationBuilder(Db)
                    {
                        SourceType = DataSourceType.IpOneData,
                        ApplicationNumber = number,
                        UpdatedOn = Fixture.PastDate(),
                        Body = title
                    }.Build()
                };

                var r = _subject.For(notification).Single();

                Assert.Equal(DataSourceType.IpOneData, r.DataSourceType);
                Assert.Equal(number, r.AppNum);
                Assert.Equal(title, r.Title);
                Assert.NotNull(r.Type);
            }
        }

        public class ForSingleMethod : FactBase
        {
            public ForSingleMethod()
            {
                _case = new CaseBuilder().Build().In(Db);
                _subject = new NotificationResponse(Db);
            }

            readonly Case _case;
            readonly NotificationResponse _subject;

            [Theory]
            [InlineData(DataSourceType.UsptoTsdr, "123", "hello")]
            [InlineData(DataSourceType.Epo, "234", "world")]
            [InlineData(DataSourceType.UsptoPrivatePair, "345", null)]
            public async Task ReturnsCaseNotificationResponse(DataSourceType source, string number, string title)
            {
                var notification = new CaseNotificationBuilder(Db)
                {
                    SourceType = source,
                    ApplicationNumber = number,
                    UpdatedOn = Fixture.PastDate(),
                    Body = title,
                    CaseId = _case.Id
                }.Build();

                var r = await _subject.For(notification);

                Assert.Equal(source, r.DataSourceType);
                Assert.Equal(number, r.AppNum);
                Assert.Equal(title, r.Title);
                Assert.Equal(_case.Irn, r.CaseRef);
                Assert.NotNull(r.Type);
            }

            [Fact]
            public async Task ReturnsErrorNotification()
            {
                var notification = new CaseNotificationBuilder(Db)
                {
                    SourceType = DataSourceType.UsptoPrivatePair,
                    ApplicationNumber = "1234",
                    UpdatedOn = Fixture.Today(),
                    CaseId = _case.Id,
                    Body = new JObject
                    {
                        {"the error", "details"}
                    }.ToString(),
                    Type = CaseNotificateType.Error
                }.Build();

                var r = await _subject.For(notification);

                Assert.Equal("Error", r.Title);
                Assert.Equal(_case.Irn, r.CaseRef);
                Assert.Equal("details", ((JObject) r.Body)["the error"]);
            }

            [Fact]
            public async Task ReturnsRejectedMatchNotification()
            {
                var title = Fixture.String();
                var number = Fixture.String();

                var notification = new CaseNotificationBuilder(Db)
                {
                    SourceType = DataSourceType.IpOneData,
                    ApplicationNumber = number,
                    UpdatedOn = Fixture.PastDate(),
                    Body = title,
                    CaseId = _case.Id
                }.Build();

                var r = await _subject.For(notification);

                Assert.Equal(DataSourceType.IpOneData, r.DataSourceType);
                Assert.Equal(number, r.AppNum);
                Assert.Equal(title, r.Title);
                Assert.Equal(_case.Irn, r.CaseRef);
                Assert.NotNull(r.Type);
            }
        }
    }
}
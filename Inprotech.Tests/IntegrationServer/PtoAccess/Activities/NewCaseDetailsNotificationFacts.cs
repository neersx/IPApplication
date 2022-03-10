using System.Threading.Tasks;
using Autofac.Features.Indexed;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.Integration.Notifications;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.IntegrationServer.PtoAccess.ContentVersioning;
using Inprotech.Tests.Fakes;
using NSubstitute;
using Xunit;

#pragma warning disable 4014

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Activities
{
    public class NewCaseDetailsNotificationFacts
    {
        public class NotifyMethod : FactBase
        {
            readonly DataDownload _dataDownload = new DataDownload
            {
                DataSourceType = DataSourceType.UsptoTsdr,
                Case = new EligibleCase {CaseKey = 1}
            };

            [Fact]
            public async Task CallsModifierIfAvailable()
            {
                var f = new NewCaseDetailsNotificationFixture(Db);
                f.DownloadedContent.MakeVersionable(Arg.Any<DataDownload>()).Returns(Task.FromResult("application details"));
                f.ContentHasher.ComputeHash("application details").Returns("new version");

                var m = Substitute.For<ISourceNotificationModifier>();
                f.Modifiers.TryGetValue(DataSourceType.UsptoTsdr, out _)
                 .Returns(x =>
                 {
                     x[1] = m;
                     return true;
                 });

                new Case
                {
                    Source = DataSourceType.UsptoTsdr,
                    CorrelationId = 1,
                    Version = "not the same version"
                }.In(Db);

                await f.Subject.NotifyIfChanged(_dataDownload);

                m.Received(1).Modify(Arg.Any<CaseNotification>(), _dataDownload);
            }

            [Fact]
            public async Task ReturnsIfNotChanged()
            {
                var f = new NewCaseDetailsNotificationFixture(Db);
                f.DownloadedContent.MakeVersionable(Arg.Any<DataDownload>()).Returns(Task.FromResult("application details"));
                f.ContentHasher.ComputeHash("application details").Returns("same version");

                var @case = new Case
                {
                    Source = DataSourceType.UsptoTsdr,
                    CorrelationId = 1,
                    Version = "same version"
                }.In(Db);

                await f.Subject.NotifyIfChanged(_dataDownload);

                f.ContentHasher.Received(1).ComputeHash("application details");
                f.DownloadedContent.Received(1).MakeVersionable(Arg.Any<DataDownload>());

                f.TitleExtractor.DidNotReceive().ExtractFrom(_dataDownload);
                f.PtoAccessCase.DidNotReceive().Update(Arg.Any<string>(), @case, "same version", _dataDownload.Case);
                f.PtoAccessCase.DidNotReceive().CreateOrUpdateNotification(@case, Arg.Any<string>());
            }

            [Fact]
            public async Task UpdatesAndNotifies()
            {
                var f = new NewCaseDetailsNotificationFixture(Db);
                f.DownloadedContent.MakeVersionable(Arg.Any<DataDownload>()).Returns(Task.FromResult("application details"));
                f.ContentHasher.ComputeHash("application details").Returns("new version");

                var @case = new Case
                {
                    Source = DataSourceType.UsptoTsdr,
                    CorrelationId = 1,
                    Version = "not the same version"
                }.In(Db);

                await f.Subject.NotifyIfChanged(_dataDownload);

                f.DataDownloadLocationResolver.Received(1).Resolve(_dataDownload, PtoAccessFileNames.CpaXml);
                f.ContentHasher.Received(1).ComputeHash("application details");
                f.DownloadedContent.Received(1).MakeVersionable(Arg.Any<DataDownload>());

                f.TitleExtractor.Received(1).ExtractFrom(_dataDownload);
                f.PtoAccessCase.Received(1).Update(Arg.Any<string>(), @case, "new version", _dataDownload.Case);
                f.PtoAccessCase.Received(1).CreateOrUpdateNotification(@case, Arg.Any<string>());
            }

            [Fact]
            public async Task UpdatesAndNotifiesOverErrorNotification()
            {
                var f = new NewCaseDetailsNotificationFixture(Db);
                f.DownloadedContent.MakeVersionable(Arg.Any<DataDownload>()).Returns(Task.FromResult("application details"));
                f.ContentHasher.ComputeHash("application details").Returns("same version");

                var @case = new Case
                {
                    Source = DataSourceType.UsptoTsdr,
                    CorrelationId = 1,
                    Version = "same version"
                }.In(Db);

                new CaseNotification
                {
                    Case = @case,
                    CaseId = @case.Id,
                    Type = CaseNotificateType.Error
                }.In(Db);

                await f.Subject.NotifyIfChanged(_dataDownload);

                f.DataDownloadLocationResolver.Received(1).Resolve(_dataDownload, PtoAccessFileNames.CpaXml);
                f.ContentHasher.Received(1).ComputeHash("application details");
                f.DownloadedContent.Received(1).MakeVersionable(Arg.Any<DataDownload>());

                f.TitleExtractor.Received(1).ExtractFrom(_dataDownload);
                f.PtoAccessCase.Received(1).Update(Arg.Any<string>(), @case, "same version", _dataDownload.Case);
                f.PtoAccessCase.Received(1).CreateOrUpdateNotification(@case, Arg.Any<string>());
            }
        }

        public class NewCaseDetailsNotificationFixture : IFixture<NewCaseDetailsNotification>
        {
            public NewCaseDetailsNotificationFixture(InMemoryDbContext db)
            {
                PtoAccessCase = Substitute.For<IPtoAccessCase>();

                ContentHasher = Substitute.For<IContentHasher>();

                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();

                DownloadedContent = Substitute.For<IDownloadedContent>();

                TitleExtractor = Substitute.For<ITitleExtractor>();

                Modifiers = Substitute.For<IIndex<DataSourceType, ISourceNotificationModifier>>();

                Subject = new NewCaseDetailsNotification(
                                                         db, PtoAccessCase,
                                                         DataDownloadLocationResolver, DownloadedContent, ContentHasher,
                                                         TitleExtractor, Modifiers);
            }

            public IPtoAccessCase PtoAccessCase { get; set; }

            public IContentHasher ContentHasher { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public IIndex<DataSourceType, ISourceNotificationModifier> Modifiers { get; set; }

            public IDownloadedContent DownloadedContent { get; set; }

            public ITitleExtractor TitleExtractor { get; set; }
            public NewCaseDetailsNotification Subject { get; }
        }
    }
}
using System;
using System.IO;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.CaseSource;
using Inprotech.IntegrationServer.PtoAccess;
using Inprotech.IntegrationServer.PtoAccess.Innography.Activities;
using Inprotech.Tests.Extensions;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Innography.Activities
{
    public class DownloadCaseDispatcherFacts
    {
        public class DispatchMethod : FactBase
        {
            [Fact]
            public async Task CasesAreCreated()
            {
                var a = new DataDownload
                {
                    Case = new EligibleCase()
                };

                var b = new DataDownload
                {
                    Case = new EligibleCase()
                };

                var c = new DataDownload
                {
                    Case = new EligibleCase()
                };

                var fixture = new DownloadCaseDispatcherFixture();

                var generatedFileName = "chunk_" + Guid.Empty + ".json";

                fixture.DataDownloadLocationResolver
                       .ResolveRoot(a, generatedFileName)
                       .Returns(Path.Combine("abcdef", generatedFileName));

                await fixture.Subject.DispatchForMatching(new[] {a, b, c});

                fixture.PtoAccessCase.Received()
                       .EnsureAvailableDetached(a.Case, b.Case, c.Case)
                       .IgnoreAwaitForNSubstituteAssertion();
            }

            [Fact]
            public async Task SavesTheListThenDispatch()
            {
                var a = new DataDownload();

                var b = new DataDownload();

                var c = new DataDownload();

                var fixture = new DownloadCaseDispatcherFixture();

                var generatedFileName = "chunk_" + Guid.Empty + ".json";

                fixture.DataDownloadLocationResolver
                       .ResolveRoot(a, generatedFileName)
                       .Returns(Path.Combine("abcdef", generatedFileName));

                var r = await fixture.Subject.DispatchForMatching(new[] {a, b, c});

                Assert.Equal("DownloadRequired.FromInnography", ((SingleActivity) r).TypeAndMethod());

                Assert.Equal(Path.Combine("abcdef", generatedFileName), ((SingleActivity) r).Arguments[0]);

                fixture.BufferedStringWriter.Received(1)
                       .Write(Path.Combine("abcdef", generatedFileName), JsonConvert.SerializeObject(new[] {a, b, c}))
                       .IgnoreAwaitForNSubstituteAssertion();
            }
        }

        public class DownloadCaseDispatcherFixture : IFixture<DownloadCaseDispatcher>
        {
            public DownloadCaseDispatcherFixture()
            {
                BufferedStringWriter = Substitute.For<IBufferedStringWriter>();

                DataDownloadLocationResolver = Substitute.For<IDataDownloadLocationResolver>();

                PtoAccessCase = Substitute.For<IPtoAccessCase>();

                Subject = new DownloadCaseDispatcher(DataDownloadLocationResolver,
                                                     BufferedStringWriter,
                                                     PtoAccessCase,
                                                     () => Guid.Empty);
            }

            public IPtoAccessCase PtoAccessCase { get; set; }

            public IBufferedStringWriter BufferedStringWriter { get; set; }

            public IDataDownloadLocationResolver DataDownloadLocationResolver { get; set; }

            public DownloadCaseDispatcher Subject { get; }
        }
    }
}
using System.Collections.Generic;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Integration.Artifacts;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Activities;
using Inprotech.Tests.Extensions;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Activities
{
    public class ChunkedDownloadRequestsFacts
    {
        public class DispatchMethod
        {
            [Fact]
            public void ChunksWithCorrectSize()
            {
                const int sizeOfChunk = 3;
                const int totalSize = 5;

                var f = new ChunkedDownloadRequestsFixture()
                    .WithDataDownloadRequests(totalSize, out var d);

                var r = f
                        .Subject
                        .Dispatch(d, sizeOfChunk, f.FuncFixture.CreateDownloadActivity)
                        .ToArray();

                f.FuncFixture.Received(1).CreateDownloadActivity(Arg.Is<DataDownload[]>(x => x.Length == sizeOfChunk));
                f.FuncFixture.Received(1).CreateDownloadActivity(Arg.Is<DataDownload[]>(x => x.Length == totalSize - sizeOfChunk));

                Assert.Equal(2, r.Length);
            }

            [Fact]
            public void CreateDownloadActivitesForEachChunk()
            {
                const int sizeOfChunk = 1;

                var f = new ChunkedDownloadRequestsFixture()
                    .WithDataDownloadRequests(3, out var d);

                var r = f
                        .Subject
                        .Dispatch(d, sizeOfChunk, f.FuncFixture.CreateDownloadActivity)
                        .ToArray();

                f.FuncFixture.Received(3).CreateDownloadActivity(Arg.Any<DataDownload[]>());
                Assert.Equal(3, r.Length);
            }
        }

        public class DispatchAsyncMethod
        {
            [Fact]
            public async Task ChunksWithCorrectSize()
            {
                const int sizeOfChunk = 3;
                const int totalSize = 5;

                var f = new ChunkedDownloadRequestsFixture()
                    .WithDataDownloadRequests(totalSize, out var d);

                var r = (await f
                               .Subject
                               .DispatchAsync(d, sizeOfChunk, f.FuncFixture.CreateDownloadActivityAsync))
                    .ToArray();

                f.FuncFixture.Received(1)
                 .CreateDownloadActivityAsync(Arg.Is<DataDownload[]>(x => x.Length == sizeOfChunk))
                 .IgnoreAwaitForNSubstituteAssertion();

                f.FuncFixture.Received(1)
                 .CreateDownloadActivityAsync(Arg.Is<DataDownload[]>(x => x.Length == totalSize - sizeOfChunk))
                 .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(2, r.Length);
            }

            [Fact]
            public async Task CreateDownloadActivitesForEachChunk()
            {
                const int sizeOfChunk = 1;

                var f = new ChunkedDownloadRequestsFixture()
                    .WithDataDownloadRequests(3, out var d);

                var r = (await f
                               .Subject
                               .DispatchAsync(d, sizeOfChunk, f.FuncFixture.CreateDownloadActivityAsync))
                    .ToArray();

                f.FuncFixture.Received(3)
                 .CreateDownloadActivityAsync(Arg.Any<DataDownload[]>())
                 .IgnoreAwaitForNSubstituteAssertion();

                Assert.Equal(3, r.Length);
            }
        }

        public class ChunkedDownloadRequestsFixture : IFixture<ChunckedDownloadRequests>
        {
            public ChunkedDownloadRequestsFixture()
            {
                FuncFixture = Substitute.For<IFuncFixture>();

                FuncFixture.CreateDownloadActivity(Arg.Any<DataDownload[]>())
                           .Returns(DefaultActivity.NoOperation());

                FuncFixture.CreateDownloadActivityAsync(Arg.Any<DataDownload[]>())
                           .Returns(DefaultActivity.NoOperation());

                Subject = new ChunckedDownloadRequests();
            }

            public IFuncFixture FuncFixture { get; set; }
            public ChunckedDownloadRequests Subject { get; set; }

            public ChunkedDownloadRequestsFixture WithDataDownloadRequests(int numberOfRequests, out List<DataDownload> requests)
            {
                var d = new List<DataDownload>();
                for (var i = 0; i < numberOfRequests; i++)
                    d.Add(new DataDownload());

                requests = d;
                return this;
            }
        }
    }
}
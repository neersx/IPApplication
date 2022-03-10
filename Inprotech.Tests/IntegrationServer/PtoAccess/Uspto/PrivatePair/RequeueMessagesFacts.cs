using System;
using System.Linq;
using Inprotech.Contracts;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair
{
    public class RequeueMessagesFacts
    {
        [Fact]
        public void CreatesSetsOfDatesThatAreAllDistinct()
        {
            var dates = new DateTime[]
            {
                new DateTime(2020,01,01),
                new DateTime(2020,02,02),
                new DateTime(2020,03,03),
                new DateTime(2020,04,04),
                new DateTime(2020,05,05),
                new DateTime(2020,06,06)
            };
            var f = new RequeueMessagesFixture()
                .WithDefaultFolderStructure(dates);
            var r = f.Subject.GetDateRanges(new Session());
            Assert.NotNull(r);
            Assert.Equal(6, r.Count);
            foreach (var dateSet in r)
            {
                Assert.Equal(dateSet.startDate, dateSet.endDate);
            }
        }

        [Fact]
        public void JoinDatesThatAreInSequence()
        {
            var dates = new DateTime[]
            {
                new DateTime(2020,01,01),
                new DateTime(2020,01,02),
                new DateTime(2020,01,03),
                new DateTime(2020,04,04),
                new DateTime(2020,04,05),
                new DateTime(2020,04,06)
            };
            var f = new RequeueMessagesFixture()
                .WithDefaultFolderStructure(dates);
            var r = f.Subject.GetDateRanges(new Session());
            Assert.NotNull(r);
            Assert.Equal(2, r.Count);
            Assert.Equal(dates[0], r[0].startDate);
            Assert.Equal(dates[2], r[0].endDate);
            Assert.Equal(dates[3], r[1].startDate);
            Assert.Equal(dates[5], r[1].endDate);
        }

        [Fact]
        public void JoinDatesThatAreInSequenceDifferentCombination()
        {
            var dates = new DateTime[]
            {
                new DateTime(2020,01,01),
                new DateTime(2020,01,02),
                new DateTime(2020,01,04),
                new DateTime(2020,04,04),
                new DateTime(2020,04,05),
                new DateTime(2020,04,07)
            };
            var f = new RequeueMessagesFixture()
                .WithDefaultFolderStructure(dates);
            var r = f.Subject.GetDateRanges(new Session());
            Assert.NotNull(r);
            Assert.Equal(4, r.Count);
            Assert.Equal(dates[0], r[0].startDate);
            Assert.Equal(dates[1], r[0].endDate);
            Assert.Equal(r[1].startDate, r[1].endDate);
            Assert.Equal(dates[3], r[2].startDate);
            Assert.Equal(dates[4], r[2].endDate);
            Assert.Equal(r[3].startDate, r[3].endDate);
        }

        class RequeueMessagesFixture : IFixture<IRequeueMessageDates>
        {
            public RequeueMessagesFixture()
            {
                FileSystem = Substitute.For<IFileSystem>();
                ArtifactsLocationResolver = Substitute.For<IArtifactsLocationResolver>();
                Subject = new RequeueMessageDates(FileSystem, ArtifactsLocationResolver);
            }
            public IRequeueMessageDates Subject { get; }
            IFileSystem FileSystem { get; }
            IArtifactsLocationResolver ArtifactsLocationResolver { get; }

            public RequeueMessagesFixture WithDefaultFolderStructure(DateTime[] dates)
            {
                var files = new[] { "abc.json", "def.json", "ghi.json", "jkl.json", "mno.json", "pqr.json" };
                var folders = new[] { $"{Fixture.Integer()}", $"{Fixture.Integer()}", $"{Fixture.Integer()}" };
                var format = "yyyy-MM-dd HH:mm:ss:ffffff";

                FileSystem.Folders(Arg.Any<string>()).Returns(folders.Select(f => $@"c:\inprotech\uspto\schedule1\guid\{f}"));

                ArtifactsLocationResolver.Resolve(Arg.Any<ApplicationDownload>()).Returns(c => ((ApplicationDownload)c[0]).ApplicationId);

                FileSystem.Files(folders[0], "*.json").Returns(new[] { files[0], files[1] });
                FileSystem.Files(folders[1], "*.json").Returns(new[] { files[2], files[3] });
                FileSystem.Files(folders[2], "*.json").Returns(new[] { files[4], files[5] });

                for (int i = 0; i < dates.Length; i++)
                {
                    if (i > files.Length) break;
                    FileSystem.ReadAllText(files[i]).Returns(JsonConvert.SerializeObject(new Message()
                    {
                        Meta = new Meta { EventTimeStamp = dates[i].ToString(format) }
                    }));
                }
                return this;
            }
        }
    }
}

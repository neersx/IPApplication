using System.IO;
using Inprotech.Contracts;
using Inprotech.Integration.Diagnostics.PtoAccess;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Jobs;
using Inprotech.Integration.Persistence;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Integration.PtoAccess.Diagnostics.PtoAccess
{
    public class IpOneFailuresFacts
    {
        public class PrepareMethod : FactBase
        {
            [Fact]
            public void ShouldNotWriteTextIfNoMessages()
            {
                var fixture = new IpOneFailuresFixture(Db);

                fixture.Subject.Prepare(Fixture.String());

                fixture.FileSystem.Received(0).WriteAllText(Arg.Any<string>(), Arg.Any<string>());
            }

            [Fact]
            public void ShouldNotWriteTextIfNoMessagesWithRightTypeOrState()
            {
                var fixture = new IpOneFailuresFixture(Db);
                new[]
                {
                    new JobExecution
                    {
                        Job = new Job
                        {
                            Type = "DequeueUsptoMessagesJob"
                        },
                        State = null
                    },
                    new JobExecution
                    {
                        Job = new Job
                        {
                            Type = "NotCorrect"
                        },
                        State = Fixture.String()
                    },
                    new JobExecution
                    {
                        Job = new Job
                        {
                            Type = "NotCorrect"
                        },
                        State = null
                    }
                }.In(Db);
                fixture.Subject.Prepare(Fixture.String());

                fixture.FileSystem.Received(0).WriteAllText(Arg.Any<string>(), Arg.Any<string>());
            }

            [Fact]
            public void ShouldWriteFileIfHasMessages()
            {
                var fixture = new IpOneFailuresFixture(Db);
                var messages = new[]
                {
                    new Message(),
                    new Message(),
                    new Message(),
                    new Message(),
                    new Message()
                };
                new[]
                {
                    new JobExecution
                    {
                        Job = new Job
                        {
                            Type = "DequeueUsptoMessagesJob"
                        },
                        State = JsonConvert.SerializeObject(new[]
                        {
                            messages[0],
                            messages[1],
                            messages[2]
                        })
                    },
                    new JobExecution
                    {
                        Job = new Job
                        {
                            Type = "DequeueUsptoMessagesJob"
                        },
                        State = JsonConvert.SerializeObject(new[]
                        {
                            messages[3],
                            messages[4]
                        })
                    }
                }.In(Db);
                var basePath = Fixture.String();

                fixture.Subject.Prepare(basePath);

                fixture.FileSystem.Received(1).WriteAllText(Path.Combine(basePath, "IPOneUnprocessedMessages.json"), Arg.Any<string>());
            }
        }

        public class IpOneFailuresFixture : IFixture<IpOneFailures>
        {
            public IpOneFailuresFixture(InMemoryDbContext db)
            {
                FileSystem = Substitute.For<IFileSystem>();
                Repository = db;
                Subject = new IpOneFailures(FileSystem, Repository);
            }

            public IFileSystem FileSystem { get; }
            public IRepository Repository { get; }
            public IpOneFailures Subject { get; }
        }
    }
}
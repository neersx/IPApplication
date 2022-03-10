using System.Collections.Generic;
using System.Threading.Tasks;
using Dependable;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Storage;
using Inprotech.Integration;
using Inprotech.Integration.CaseFiles;
using Inprotech.Integration.Documents;
using Inprotech.Integration.Extensions;
using Inprotech.Integration.Innography.PrivatePair;
using Inprotech.Integration.Storage;
using Inprotech.IntegrationServer.PtoAccess.Uspto.PrivatePair.MissingDocuments;
using Inprotech.Tests.Extensions;
using Inprotech.Tests.Fakes;
using Newtonsoft.Json;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.IntegrationServer.PtoAccess.Uspto.PrivatePair.Activities.MissingDocuments
{
    public class FindMissingDocumentsJobFacts : FactBase
    {
        [Fact]
        public void GetJobShouldReturnCorrectActivity()
        {
            var fixture = new FindMissingDocumentsJobFixture(Db);
            var result = fixture.Subject.GetJob(1, null);

            Assert.Equal(typeof(FindMissingDocumentsJob), result.Type);
            Assert.Equal("Discover", result.Name);
        }

        [Fact]
        public async Task DefaultActivityIfNoDbRecords()
        {
            var fixture = new FindMissingDocumentsJobFixture(Db);
            var result = await fixture.Subject.Discover();

            Assert.Equal(typeof(NullActivity), ((SingleActivity)result).Type);
            fixture.FileSystem.DidNotReceiveWithAnyArgs().Exists(Arg.Any<string>());
        }

        [Fact]
        public async Task OnlyProcessesIfBiblioFileExists()
        {
            var fixture = new FindMissingDocumentsJobFixture(Db).WithDefaultData(Fixture.String());
            var result = await fixture.Subject.Discover();

            Assert.Equal(typeof(NullActivity), ((SingleActivity)result).Type);
            fixture.FileSystem.Received(1).Exists(Arg.Any<string>());
        }

        [Fact]
        public async Task DoesNotWriteToFileIfNoMissingDocument()
        {
            var app = Fixture.String();
            var fixture = new FindMissingDocumentsJobFixture(Db)
                .WithDefaultData(app);
            fixture.FileSystem.Exists(Arg.Any<string>()).Returns(true);

            var doc = new Document()
            {
                DocumentObjectId = Fixture.String(),
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = app,
                MailRoomDate = Fixture.Today()
            }.In(Db);

            var biblio = new BiblioFile()
            {
                ImageFileWrappers = new List<ImageFileWrapper>()
                {
                    new ImageFileWrapper()
                    {
                        ObjectId = doc.DocumentObjectId,
                        FileName = Fixture.String(),
                        DocCategory = Fixture.String(),
                        MailDate = Fixture.Today().ToString("yyyy-MM-dd"),
                        DocDesc = Fixture.String(),
                        DocCode = Fixture.String(),
                        PageCount = Fixture.Integer(),
                        AppId = doc.ApplicationNumber
                    }
                }
            };
            fixture.BufferedStringReader.Read(Arg.Any<string>())
                   .Returns(JsonConvert.SerializeObject(biblio));

            var result = await fixture.Subject.Discover();

            Assert.Equal(typeof(NullActivity), ((SingleActivity)result).Type);

            fixture.FileSystem.Received(1).Exists(Arg.Any<string>());
            fixture.BufferedStringReader.Received(1).Read(Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            fixture.FileSystem.DidNotReceiveWithAnyArgs().WriteAllText(Arg.Any<string>(), Arg.Any<string>());
        }

        [Fact]
        public async Task DoesNotConsiderRecordsWithOlderMailRoomDate()
        {
            var app = Fixture.String();
            var fixture = new FindMissingDocumentsJobFixture(Db)
                .WithDefaultData(app);
            fixture.FileSystem.Exists(Arg.Any<string>()).Returns(true);

            var doc = new Document()
            {
                DocumentObjectId = Fixture.String(),
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = app,
                MailRoomDate = Fixture.Today()
            }.In(Db);

            var biblio = new BiblioFile()
            {
                ImageFileWrappers = new List<ImageFileWrapper>()
                {
                    new ImageFileWrapper()
                    {
                        ObjectId = doc.DocumentObjectId,
                        AppId = doc.ApplicationNumber,
                        MailDate = Fixture.Today().ToString("yyyy-MM-dd"),
                        DocCode = Fixture.String(),
                        DocDesc = Fixture.String(),
                        PageCount = Fixture.Integer(),
                        FileName = Fixture.String(),
                        DocCategory = Fixture.String()
                    },
                    new ImageFileWrapper()
                    {
                        ObjectId = Fixture.String(),
                        AppId = doc.ApplicationNumber,
                        MailDate = Fixture.PastDate().ToString("yyyy-MM-dd"),
                        DocCode = Fixture.String(),
                        DocDesc = Fixture.String(),
                        PageCount = Fixture.Integer(),
                        FileName = Fixture.String(),
                        DocCategory = Fixture.String()
                    }
                }
            };
            fixture.BufferedStringReader.Read(Arg.Any<string>())
                   .Returns(JsonConvert.SerializeObject(biblio));

            var result = await fixture.Subject.Discover();

            Assert.Equal(typeof(NullActivity), ((SingleActivity)result).Type);

            fixture.FileSystem.Received(1).Exists(Arg.Any<string>());
            fixture.BufferedStringReader.Received(1).Read(Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            fixture.FileSystem.DidNotReceiveWithAnyArgs().WriteAllText(Arg.Any<string>(), Arg.Any<string>());
        }

        [Fact]
        public async Task DoesNotConsiderRecordsWithInvalidDocCodes()
        {
            var app = Fixture.String();
            var fixture = new FindMissingDocumentsJobFixture(Db)
                .WithDefaultData(app);
            fixture.FileSystem.Exists(Arg.Any<string>()).Returns(true);

            var doc = new Document()
            {
                DocumentObjectId = Fixture.String(),
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = app,
                MailRoomDate = Fixture.Today()
            }.In(Db);

            var biblio = new BiblioFile()
            {
                ImageFileWrappers = new List<ImageFileWrapper>()
                {
                    new ImageFileWrapper()
                    {
                        ObjectId = doc.DocumentObjectId,
                        AppId = doc.ApplicationNumber,
                        MailDate = Fixture.Today().ToString("yyyy-MM-dd"),
                        DocCode = Fixture.String(),
                        DocDesc = Fixture.String(),
                        PageCount = Fixture.Integer(),
                        FileName = Fixture.String(),
                        DocCategory = Fixture.String()
                    },
                    new ImageFileWrapper()
                    {
                        ObjectId = Fixture.String(),
                        AppId = doc.ApplicationNumber,
                        MailDate = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                        DocCode = Fixture.String(),
                        DocDesc = Fixture.String(),
                        PageCount = Fixture.Integer(),
                        FileName = Fixture.String(),
                        DocCategory = Fixture.String()
                    }
                }
            };
            fixture.BufferedStringReader.Read(Arg.Any<string>())
                   .Returns(JsonConvert.SerializeObject(biblio));

            var result = await fixture.Subject.Discover();

            Assert.Equal(typeof(NullActivity), ((SingleActivity)result).Type);

            fixture.FileSystem.Received(1).Exists(Arg.Any<string>());
            fixture.BufferedStringReader.Received(1).Read(Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            fixture.FileSystem.DidNotReceiveWithAnyArgs().WriteAllText(Arg.Any<string>(), Arg.Any<string>());
        }

        [Theory]
        [InlineData("892")]
        [InlineData("371.RQ.M922")]
        [InlineData("SE.FILE.DATE")]
        public async Task FindsMissingDocuments(string docCode)
        {
            var app = Fixture.String();
            var fixture = new FindMissingDocumentsJobFixture(Db)
                .WithDefaultData(app);
            fixture.FileSystem.Exists(Arg.Any<string>()).Returns(true);

            var doc = new Document()
            {
                DocumentObjectId = Fixture.String(),
                Source = DataSourceType.UsptoPrivatePair,
                ApplicationNumber = app,
                MailRoomDate = Fixture.Today()
            }.In(Db);

            var biblio = new BiblioFile()
            {
                ImageFileWrappers = new List<ImageFileWrapper>()
                {
                    new ImageFileWrapper()
                    {
                        ObjectId = doc.DocumentObjectId,
                        AppId = doc.ApplicationNumber,
                        MailDate = Fixture.Today().ToString("yyyy-MM-dd"),
                        DocCode = Fixture.String(),
                        DocDesc = Fixture.String(),
                        PageCount = Fixture.Integer(),
                        FileName = Fixture.String(),
                        DocCategory = Fixture.String()
                    },
                    new ImageFileWrapper()
                    {
                        ObjectId = Fixture.String(),
                        AppId = doc.ApplicationNumber,
                        MailDate = Fixture.FutureDate().ToString("yyyy-MM-dd"),
                        DocCode = docCode,
                        DocDesc = Fixture.String(),
                        PageCount = Fixture.Integer(),
                        FileName = Fixture.String(),
                        DocCategory = Fixture.String()
                    }
                }
            };
            fixture.BufferedStringReader.Read(Arg.Any<string>())
                   .Returns(JsonConvert.SerializeObject(biblio));

            var result = await fixture.Subject.Discover();

            Assert.Equal(typeof(NullActivity), ((SingleActivity)result).Type);

            fixture.FileSystem.Received(1).Exists(Arg.Any<string>());
            fixture.BufferedStringReader.Received(1).Read(Arg.Any<string>()).IgnoreAwaitForNSubstituteAssertion();
            fixture.FileSystem.Received(1).WriteAllText(Arg.Any<string>(), Arg.Any<string>());
        }

        class FindMissingDocumentsJobFixture : IFixture<FindMissingDocumentsJob>
        {
            public FindMissingDocumentsJobFixture(InMemoryDbContext db)
            {
                Db = db;
                FileSystem = Substitute.For<IFileSystem>();
                BufferedStringReader = Substitute.For<IBufferedStringReader>();
                Subject = new FindMissingDocumentsJob(Db, FileSystem, BufferedStringReader);
            }

            public FindMissingDocumentsJob Subject { get; }

            InMemoryDbContext Db { get; }

            public IFileSystem FileSystem { get; }
            public IBufferedStringReader BufferedStringReader { get; }

            public FindMissingDocumentsJobFixture WithDefaultData(string applicationNumber)
            {
                new Case()
                {
                    ApplicationNumber = applicationNumber,
                    Source = DataSourceType.UsptoPrivatePair,
                    Id = 1
                }.In(Db);
                new CaseFiles()
                {
                    CaseId = 1,
                    Type = (int)CaseFileType.Biblio,
                    FileStore = new FileStore()
                    {
                        Id = Fixture.Integer(),
                        OriginalFileName = Fixture.String(),
                        Path = Fixture.String()
                    }.In(Db)
                }.In(Db);

                return this;
            }
        }
    }
}
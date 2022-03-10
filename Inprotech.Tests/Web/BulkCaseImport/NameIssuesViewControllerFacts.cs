using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.BulkCaseImport;
using Inprotech.Web.BulkCaseImport.NameResolution;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class NameIssuesViewControllerFacts
    {
        public class NameIssuesViewControllerFixture : IFixture<NameIssuesViewController>
        {
            readonly InMemoryDbContext _db;

            EdeSenderDetails _batchDetails;

            int _id;
            int _edeNameId;
            int _transacionId;

            public NameIssuesViewControllerFixture(InMemoryDbContext db)
            {
                _db = db;

                SiteConfiguration = Substitute.For<ISiteConfiguration>();
                SiteConfiguration.HomeCountry().Returns(new CountryBuilder().Build());

                MapCandidates = Substitute.For<IMapCandidates>();

                Subject = new NameIssuesViewController(db, SiteConfiguration, MapCandidates);
            }

            public ISiteConfiguration SiteConfiguration { get; }

            public IMapCandidates MapCandidates { get; }

            public NameIssuesViewController Subject { get; }

            public NameIssuesViewControllerFixture BuildNameTypes()
            {
                new NameType(1, "I", "Instructor").In(_db);
                new NameType(1, "A", "Agent").In(_db);
                new NameType(1, "D", "Debtor").In(_db);

                return this;
            }

            public NameIssuesViewControllerFixture Import(int batchId, string senderRequestIdentifier)
            {
                _batchDetails = new EdeSenderDetails
                {
                    LastModified = Fixture.Today(),
                    Sender = "MYAC",
                    SenderRequestIdentifier = senderRequestIdentifier,
                    TransactionHeader = new EdeTransactionHeader
                    {
                        BatchId = batchId,
                        BatchStatus =
                            new TableCode(1, (short) TableTypes.EDEBatchStatus,
                                          "batch status").In(_db)
                    }.In(_db)
                }.In(_db);
                return this;
            }

            public NameIssuesViewControllerFixture WithUnresolvedName(int batchId, string name, string firstname, string senderNameId, string nameType)
            {
                _batchDetails.TransactionHeader.UnresolvedNames.Add(new EdeUnresolvedName
                {
                    Id = ++_id,
                    BatchId = batchId,
                    Name = name,
                    FirstName = firstname,
                    SenderNameIdentifier = senderNameId,
                    NameType = nameType
                }.In(_db));
                return this;
            }

            public NameIssuesViewControllerFixture WithEdeName(int batchId, string senderNameId, string recieverNameId, string nameTypeCode, int nameSequence)
            {
                new EdeName
                {
                    Id = _edeNameId++,
                    BatchId = batchId,
                    TransactionId = _transacionId.ToString(),
                    NameTypeCode = nameTypeCode,
                    NamesSequenceNo = nameSequence,
                    SenderNameIdentifier = senderNameId,
                    ReceiverNameIdentifier = recieverNameId
                }.In(_db);

                new EdeAddressBook
                {
                    Id = _edeNameId++,
                    BatchId = batchId,
                    TransactionId = _transacionId++.ToString(),
                    NameTypeCode = nameTypeCode,
                    NamesSequenceNo = nameSequence,
                    UnresolvedNameId = _id
                }.In(_db);

                return this;
            }
        }

        public class NameIssuesViewGetMethod : FactBase
        {
            [Fact]
            public void ReturnsNameIssues()
            {
                const int batchId = 1;
                var senderRequestIdentifier = Fixture.String("SenderRequestIdentifier");

                var f = new NameIssuesViewControllerFixture(Db)
                        .BuildNameTypes()
                        .Import(batchId, senderRequestIdentifier)
                        .WithUnresolvedName(batchId, "George", "Gray", "001000", "A")
                        .WithUnresolvedName(batchId, "Farming Equipment Private Limited", string.Empty, "002000", "D")
                        .WithUnresolvedName(batchId, "Farming Private Limited", string.Empty, "003000", "I")
                        .WithUnresolvedName(batchId, "Farming Equipment Limited", string.Empty, "004000", "A")
                        .WithUnresolvedName(batchId, "Acorn", "Arthur Francis", "005000", "A")
                        .WithUnresolvedName(batchId, "Farming Private Ltd", string.Empty, "006000", "D")
                        .WithUnresolvedName(batchId, "Farming Equ Private Limited", string.Empty, "007000", "I");

                f.MapCandidates.For(Arg.Any<EdeUnresolvedName>()).Returns(new[] {"candidates"});

                var r = f.Subject.Get(batchId);
                var firstUnresolvedName = ((IEnumerable<dynamic>) r.NameIssues).First();
                var lastUnresolvedName = ((IEnumerable<dynamic>) r.NameIssues).Last();

                Assert.Equal(senderRequestIdentifier, r.BatchIdentifier);
                Assert.Equal(7, ((IEnumerable<dynamic>) r.NameIssues).Count());
                Assert.Equal("Acorn, Arthur Francis", firstUnresolvedName.FormattedName);
                Assert.Equal("Agent", firstUnresolvedName.NameType);
                Assert.Equal("005000", firstUnresolvedName.NameCode);
                Assert.Equal(1, firstUnresolvedName.MapCandidates.Length);
                Assert.Null(lastUnresolvedName.MapCandidates);
            }

            [Fact]
            public void ReturnsRecieverNameIdIfSenderNameIdIsNull()
            {
                const int batchId = 1;
                var senderRequestIdentifier = Fixture.String("SenderRequestIdentifier");
                const string recieverNameIdentifier = "RecieverNameId";

                var f = new NameIssuesViewControllerFixture(Db)
                        .BuildNameTypes()
                        .Import(batchId, senderRequestIdentifier)
                        .WithUnresolvedName(batchId, "Farming Equipment Private Limited", string.Empty, null, "D")
                        .WithEdeName(batchId, null, recieverNameIdentifier, "D", 1);

                f.MapCandidates.For(Arg.Any<EdeUnresolvedName>()).Returns(new[] {"candidates"});
                var r = f.Subject.Get(batchId);

                var firstUnresolvedName = ((IEnumerable<dynamic>) r.NameIssues).First();

                Assert.Equal(recieverNameIdentifier, firstUnresolvedName.NameCode);
            }

            [Fact]
            public void ReturnsSenderNameId()
            {
                const int batchId = 1;
                var senderRequestIdentifier = Fixture.String("SenderRequestIdentifier");
                const string senderNameIdentifier = "002000";

                var f = new NameIssuesViewControllerFixture(Db)
                        .BuildNameTypes()
                        .Import(batchId, senderRequestIdentifier)
                        .WithUnresolvedName(batchId, "Farming Equipment Private Limited", string.Empty, senderNameIdentifier, "D")
                        .WithEdeName(batchId, senderNameIdentifier, "RecieverNameId", "D", 1);

                f.MapCandidates.For(Arg.Any<EdeUnresolvedName>()).Returns(new[] {"candidates"});
                var r = f.Subject.Get(batchId);

                var firstUnresolvedName = ((IEnumerable<dynamic>) r.NameIssues).First();

                Assert.Equal(senderNameIdentifier, firstUnresolvedName.NameCode);
            }

            [Fact]
            public void SameNameIssueOnMultiplleCases()
            {
                const int batchId = 1;
                var senderRequestIdentifier = Fixture.String("SenderRequestIdentifier");
                const string senderNameIdentifier = "002000";

                var f = new NameIssuesViewControllerFixture(Db)
                        .BuildNameTypes()
                        .Import(batchId, senderRequestIdentifier)
                        .WithUnresolvedName(batchId, "Farming Equipment Private Limited", string.Empty, senderNameIdentifier, "D")
                        .WithEdeName(batchId, senderNameIdentifier, null, "D", 1)
                        .WithEdeName(batchId, senderNameIdentifier, string.Empty, "D", 1);

                f.MapCandidates.For(Arg.Any<EdeUnresolvedName>()).Returns(new[] {"candidates"});
                var r = f.Subject.Get(batchId);

                var firstUnresolvedName = ((IEnumerable<dynamic>) r.NameIssues).First();

                Assert.Single((IEnumerable<dynamic>) r.NameIssues);
                Assert.Equal(senderNameIdentifier, firstUnresolvedName.NameCode);
            }

            [Fact]
            public void SameNameIssueOnMultiplleCasesWithDiffRecieverNameId()
            {
                const int batchId = 1;
                var senderRequestIdentifier = Fixture.String("SenderRequestIdentifier");
                const string recieverNameIdentifier = "RecieverNameId";

                var f = new NameIssuesViewControllerFixture(Db)
                        .BuildNameTypes()
                        .Import(batchId, senderRequestIdentifier)
                        .WithUnresolvedName(batchId, "Farming Equipment Private Limited", string.Empty, null, "D")
                        .WithEdeName(batchId, null, recieverNameIdentifier, "D", 1)
                        .WithEdeName(batchId, null, recieverNameIdentifier + "A", "D", 1);

                f.MapCandidates.For(Arg.Any<EdeUnresolvedName>()).Returns(new[] {"candidates"});
                var r = f.Subject.Get(batchId);

                var firstUnresolvedName = ((IEnumerable<dynamic>) r.NameIssues).First();

                Assert.Single((IEnumerable<dynamic>) r.NameIssues);
                Assert.Equal(recieverNameIdentifier, firstUnresolvedName.NameCode);
            }
        }
    }
}
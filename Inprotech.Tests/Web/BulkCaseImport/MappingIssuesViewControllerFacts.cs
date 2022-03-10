using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BulkCaseImport;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class MappingIssuesViewControllerFacts
    {
        public class MappingIssuesViewControllerFixture : IFixture<MappingIssuesViewController>
        {
            readonly InMemoryDbContext _db;

            public MappingIssuesViewControllerFixture(InMemoryDbContext db)
            {
                _db = db;
                Subject = new MappingIssuesViewController(db);
            }

            public MappingIssuesViewController Subject { get; }

            public MappingIssuesViewControllerFixture Import(int batchId, string senderRequestIdentifier)
            {
                var esd = new EdeSenderDetails
                {
                    Sender = "MYAC",
                    SenderRequestIdentifier = senderRequestIdentifier,
                    TransactionHeader = new EdeTransactionHeader
                    {
                        BatchId = batchId
                    }.In(_db)
                }.In(_db);

                var transactionBody = new EdeTransactionBody
                {
                    BatchId = batchId,
                    TransactionIdentifier = new Guid().ToString(),
                    TransactionStatus = new TableCode((int) TransactionStatus.UnmappedCodes, (int) TableTypes.EDETransactionStatus, "Unmapped").In(_db)
                };

                esd.TransactionHeader.TransactionBodies.Add(transactionBody);
                return this;
            }

            public MappingIssuesViewControllerFixture WithMappingIssues(int batchId, string longDescription, string issue)
            {
                new EdeOutstandingIssues
                {
                    BatchId = batchId,
                    Issue = issue,
                    TransactionIdentifier = null,
                    StandardIssue = new EdeStandardIssues {Id = Issues.UnmappedCode, LongDescription = longDescription}.In(_db)
                }.In(_db);
                return this;
            }

            public MappingIssuesViewControllerFixture WithMappingIssuesWithShortDescription(int batchId, string shortDescription, string issue)
            {
                new EdeOutstandingIssues
                {
                    BatchId = batchId,
                    Issue = issue,
                    TransactionIdentifier = null,
                    StandardIssue = new EdeStandardIssues {Id = Issues.UnmappedCode, ShortDescription = shortDescription}.In(_db)
                }.In(_db);
                return this;
            }
        }

        public class MappingIssuesViewGetMethod : FactBase
        {
            [Fact]
            public void ReturnsMappingIssues()
            {
                const int batchId = 1;
                const string longDescription = "Code mapping rule missing.  Please check your mapping rules for the following";
                var senderRequestIdentifier = Fixture.String("SenderRequestIdentifier");

                var f = new MappingIssuesViewControllerFixture(Db)
                        .Import(batchId, senderRequestIdentifier)
                        .WithMappingIssues(batchId, longDescription, "Country: Issue1")
                        .WithMappingIssues(batchId, longDescription, "NameType: Issue2");

                var r = f.Subject.Get(batchId);

                Assert.Equal(senderRequestIdentifier, r.batchIdentifier);
                Assert.Equal(1, r.mappingIssueCaseCount);
                Assert.NotNull(r.issueDescription);
                Assert.Equal(longDescription, r.issueDescription);
                Assert.Equal(2, ((IEnumerable<dynamic>) r.mappingIssues).Count());
                Assert.Equal("Country: Issue1", r.mappingIssues[0]);
                Assert.Equal("NameType: Issue2", r.mappingIssues[1]);
            }

            [Fact]
            public void ReturnsMappingIssuesWithShortDescription()
            {
                const int batchId = 1;
                const string shortDescription = "Code mapping rule missing.";
                var senderRequestIdentifier = Fixture.String("SenderRequestIdentifier");

                var f = new MappingIssuesViewControllerFixture(Db)
                        .Import(batchId, senderRequestIdentifier)
                        .WithMappingIssuesWithShortDescription(batchId, shortDescription, "Country: Issue1")
                        .WithMappingIssuesWithShortDescription(batchId, shortDescription, "NameType: Issue2");

                var r = f.Subject.Get(batchId);

                Assert.Equal(senderRequestIdentifier, r.batchIdentifier);
                Assert.Equal(1, r.mappingIssueCaseCount);
                Assert.NotNull(r.issueDescription);
                Assert.Equal(shortDescription, r.issueDescription);
                Assert.Equal(2, ((IEnumerable<dynamic>) r.mappingIssues).Count());
                Assert.Equal("Country: Issue1", r.mappingIssues[0]);
                Assert.Equal("NameType: Issue2", r.mappingIssues[1]);
            }

            [Fact]
            public void ShouldThrowIfIncorrectBatch()
            {
                const int batchId = 1;
                var senderRequestIdentifier = Fixture.String("SenderRequestIdentifier");

                var f = new MappingIssuesViewControllerFixture(Db)
                    .Import(batchId, senderRequestIdentifier);

                Assert.Throws<InvalidOperationException>(() => f.Subject.Get(batchId + 1));
            }
        }
    }
}
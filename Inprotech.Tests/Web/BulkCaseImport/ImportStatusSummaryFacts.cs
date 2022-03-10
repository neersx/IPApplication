using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Web;
using Inprotech.Tests.Fakes;
using Inprotech.Web.BulkCaseImport;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Configuration.SiteControl;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Names;
using NSubstitute;
using Xunit;

namespace Inprotech.Tests.Web.BulkCaseImport
{
    public class ImportStatusSummaryFacts
    {
        public class ImportStatusSummaryFixture : IFixture<ImportStatusSummary>
        {
            readonly InMemoryDbContext _db;
            int _batchNumber;

            public ImportStatusSummaryFixture(InMemoryDbContext db)
            {
                _db = db;
                SiteConfiguration = Substitute.For<ISiteConfiguration>();
                CommonQueryService = Substitute.For<ICommonQueryService>();
                CommonQueryService.BuildCodeDescriptionObject(string.Empty, string.Empty).ReturnsForAnyArgs(new CodeDescription {Code = "Error", Description = "Error"});
                Subject = new ImportStatusSummary(_db, SiteConfiguration, CommonQueryService);
                QueryParameters = new CommonQueryParameters {Skip = 0, Take = 50};
            }

            public CommonQueryParameters QueryParameters { get; set; }

            public ISiteConfiguration SiteConfiguration { get; }

            public ICommonQueryService CommonQueryService { get; set; }

            public ImportStatusSummary Subject { get; }

            public ImportStatusSummaryFixture WithValidSender(string sender, bool isHomeName = false)
            {
                var n = new Name {LastName = sender + "'s full name"}.In(_db);
                if (isHomeName)
                {
                    SiteConfiguration.HomeName().Returns(n);
                }

                new NameAlias
                {
                    Name = n,
                    Alias = sender,
                    AliasType = new NameAliasType {Code = KnownAliasTypes.EdeIdentifier}.In(_db)
                }.In(_db);

                return this;
            }

            public ImportStatusSummaryFixture WithValidSenderAsHomeName(string sender)
            {
                return WithValidSender(sender, true);
            }

            public ImportStatusSummaryFixture NotImportedFromFile()
            {
                _batchNumber = -1; /* special processing for CPA TM1 */
                return this;
            }

            public ImportStatusSummaryFixture ImportedOn(DateTime submitted, string sender, params EdeTransactionBody[] bodies)
            {
                var esd = new EdeSenderDetails
                {
                    LastModified = submitted,
                    Sender = sender,
                    SenderRequestIdentifier = Fixture.String("SenderRequestIdentifier"),
                    TransactionHeader = new EdeTransactionHeader
                    {
                        BatchId = _batchNumber++,
                        BatchStatus = new TableCode(1, (short) TableTypes.EDEBatchStatus, "Error").In(_db)
                    }.In(_db)
                }.In(_db);

                foreach (var b in bodies)
                    esd.TransactionHeader.TransactionBodies.Add(b);

                return this;
            }

            public EdeSenderDetails LastBatch()
            {
                return _db.Set<EdeSenderDetails>().Last();
            }
        }

        public class RetrieveFilterData : FactBase
        {
            public EdeTransactionBody WithTransactionBody(TransactionStatus status)
            {
                return new EdeTransactionBody {TransactionStatus = new TableCode((int) status, (int) TableTypes.EDETransactionStatus, status.ToString())}.In(Db);
            }

            public EdeTransactionBody WithTransactionBody(string returnCode)
            {
                return new EdeTransactionBody {TransactionReturnCode = returnCode, TransactionStatus = new TableCode((int) TransactionStatus.Processed, (int) TableTypes.EDETransactionStatus, "Status")}.In(Db);
            }

            public EdeTransactionBody WithTransactionBody(TransactionStatus status, string returnCode)
            {
                return new EdeTransactionBody {TransactionStatus = new TableCode((int) status, (int) TableTypes.EDETransactionStatus, "Status"), TransactionReturnCode = returnCode}.In(Db);
            }

            [Fact]
            public async Task ReturnFilters()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("MYAC")
                        .ImportedOn(Fixture.Today(),
                                    "MYAC",
                                    WithTransactionBody(TransactionStatus.UnmappedCodes),
                                    WithTransactionBody(TransactionStatus.OperatorReview),
                                    WithTransactionBody(TransactionReturnCodes.CaseReverted),
                                    WithTransactionBody(TransactionStatus.Processed, TransactionReturnCodes.NoChangesMade),
                                    WithTransactionBody(TransactionStatus.Processed, TransactionReturnCodes.NoChangesMade)
                                   );

                var r = (await f.Subject.RetrieveFilterData("displayStatusType")).ToArray();
                Assert.True(r.Any());
                Assert.Equal("Error", r[0].Code);
                Assert.Equal("Error", r[0].Description);
            }
        }

        public class RetrieveMethod : FactBase
        {
            public EdeTransactionBody WithTransactionBody(TransactionStatus status)
            {
                return new EdeTransactionBody {TransactionStatus = new TableCode((int) status, (int) TableTypes.EDETransactionStatus, status.ToString())}.In(Db);
            }

            public EdeTransactionBody WithTransactionBody(string returnCode)
            {
                return new EdeTransactionBody {TransactionReturnCode = returnCode, TransactionStatus = new TableCode((int) TransactionStatus.Processed, (int) TableTypes.EDETransactionStatus, "Status")}.In(Db);
            }

            public EdeTransactionBody WithTransactionBody(TransactionStatus status, string returnCode)
            {
                return new EdeTransactionBody {TransactionStatus = new TableCode((int) status, (int) TableTypes.EDETransactionStatus, "Status"), TransactionReturnCode = returnCode}.In(Db);
            }

            [Theory]
            [InlineData(ProcessRequestStatus.Processing, BatchStatus.InProgress)]
            [InlineData(ProcessRequestStatus.Error, BatchStatus.Error)]
            public async Task IdentifiesBatchStatus(ProcessRequestStatus actualStatusRequired, BatchStatus expectedStatus)
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("HomeName")
                        .ImportedOn(Fixture.Today(), "HomeName", WithTransactionBody(TransactionReturnCodes.NewCase));

                new ProcessRequest
                {
                    BatchId = f.LastBatch().TransactionHeader.BatchId,
                    Status = new TableCode((int) actualStatusRequired, (short) TableTypes.EDEBatchStatus, actualStatusRequired.ToString()).In(Db)
                }.In(Db);

                f.LastBatch().TransactionHeader.BatchStatus = new TableCode(EdeBatchStatus.Unprocessed, (short) TableTypes.EDEBatchStatus, "blah").In(Db);

                var r = await f.Subject.Retrieve(f.QueryParameters);

                Assert.Equal(expectedStatus.ToString(), r.Data.ToArray<dynamic>()[0].StatusType);
            }

            [Theory]
            [InlineData(EdeBatchStatus.OutputProduced, false)]
            [InlineData(EdeBatchStatus.Processed, true)]
            [InlineData(EdeBatchStatus.Unprocessed, true)]
            public async Task ReturnsIsNotReversibleIfOutputAlreadyProduced(int batchStatus, bool expectedReversibility)
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("HomeName")
                        .ImportedOn(Fixture.Today(), "HomeName", WithTransactionBody(TransactionReturnCodes.NewCase));

                f.LastBatch().TransactionHeader.BatchStatus = new TableCode(batchStatus, (short) TableTypes.EDEBatchStatus, "blah").In(Db);

                var result = (await f.Subject.Retrieve(f.QueryParameters)).Data.ToArray<dynamic>();

                Assert.Equal(expectedReversibility, result[0].IsReversible);
            }

            [Fact]
            public async Task BuildsNewCasesUrl()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("ABC")
                        .ImportedOn(Fixture.Today(), "ABC", WithTransactionBody(TransactionReturnCodes.NewCase));

                var r = (await f.Subject.Retrieve(f.QueryParameters)).Data.ToArray<dynamic>();

                var dataSourceKey = Db.Set<NameAlias>().Single().Name.Id;

                Assert.True(r.First().NewCasesUrl.IndexOf(dataSourceKey.ToString()) > -1);
                Assert.True(r.First().NewCasesUrl.IndexOf(r.First().BatchIdentifier) > -1);
            }

            [Fact]
            public async Task IdentifiesHomeName()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("HomeName")
                        .WithValidSender("NotHomeName")
                        .ImportedOn(Fixture.Today(), "HomeName", WithTransactionBody(TransactionReturnCodes.NewCase))
                        .ImportedOn(Fixture.Today(), "NotHomeName", WithTransactionBody(TransactionReturnCodes.NewCase));

                var r = (await f.Subject.Retrieve(f.QueryParameters)).Data.ToArray<dynamic>();

                Assert.True(r[0].IsHomeName);
                Assert.False(r[1].IsHomeName);
            }

            [Fact]
            public async Task OrdersBySubmittedDateDescending()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("ABC")
                        .WithValidSender("DEF")
                        .WithValidSender("GHI")
                        .ImportedOn(Fixture.Today(), "ABC", WithTransactionBody(TransactionReturnCodes.NewCase))
                        .ImportedOn(Fixture.PastDate(), "DEF", WithTransactionBody(TransactionReturnCodes.CaseAmended))
                        .ImportedOn(Fixture.FutureDate(), "GHI", WithTransactionBody(TransactionStatus.UnresolvedNames));

                var r = (await f.Subject.Retrieve(f.QueryParameters)).Data.ToArray<dynamic>();

                Assert.Equal(Fixture.FutureDate(), r.First().SubmittedDate);
                Assert.Equal(Fixture.PastDate(), r.Last().SubmittedDate);
            }

            [Fact]
            public async Task ReturnsErrorFromOutstandingIssues()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("HomeName")
                        .ImportedOn(Fixture.Today(), "HomeName",
                                    WithTransactionBody(TransactionReturnCodes.NewCase));

                new EdeOutstandingIssues
                {
                    BatchId = f.LastBatch().TransactionHeader.BatchId,
                    Issue = "OutstandingIssue",
                    StandardIssue = new EdeStandardIssues
                    {
                        LongDescription = "StandardIssueText"
                    }.In(Db)
                }.In(Db);

                var result = await f.Subject.Retrieve(f.QueryParameters);

                Assert.Equal("StandardIssueText" + Environment.NewLine + "OutstandingIssue",
                             result.Data.ToArray<dynamic>()[0].OtherErrors.Issues[0]);
            }

            [Fact]
            public async Task ReturnsErrorFromProcess()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("HomeName")
                        .ImportedOn(Fixture.Today(), "HomeName", WithTransactionBody(TransactionReturnCodes.NewCase));

                new ProcessRequest
                {
                    BatchId = f.LastBatch().TransactionHeader.BatchId,
                    Status = new TableCode((int) ProcessRequestStatus.Error, (short) TableTypes.ProcessRequestStatus, "Error").In(Db),
                    StatusMessage = "The Error"
                }.In(Db);

                var result = (await f.Subject.Retrieve(f.QueryParameters)).Data.ToArray<dynamic>();

                Assert.Equal("The Error", result[0].OtherErrors.Issues[0]);
            }

            [Fact]
            public async Task ReturnsImportStatus()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("MYAC")
                        .ImportedOn(Fixture.Today(),
                                    "MYAC",
                                    WithTransactionBody(TransactionStatus.UnresolvedNames),
                                    WithTransactionBody(TransactionStatus.UnmappedCodes),
                                    WithTransactionBody(TransactionStatus.UnmappedCodes),
                                    WithTransactionBody(TransactionStatus.OperatorReview),
                                    WithTransactionBody(TransactionStatus.OperatorReview),
                                    WithTransactionBody(TransactionReturnCodes.NewCase),
                                    WithTransactionBody(TransactionReturnCodes.NewCase),
                                    WithTransactionBody(TransactionReturnCodes.NewCase),
                                    WithTransactionBody(TransactionReturnCodes.CaseRejected),
                                    WithTransactionBody(TransactionReturnCodes.CaseRejected),
                                    WithTransactionBody(TransactionReturnCodes.CaseReverted),
                                    WithTransactionBody(TransactionReturnCodes.CaseDeleted),
                                    WithTransactionBody(TransactionStatus.Processed, TransactionReturnCodes.CaseAmended),
                                    WithTransactionBody(TransactionStatus.Processed, TransactionReturnCodes.CaseAmended),
                                    WithTransactionBody(TransactionStatus.Processed, TransactionReturnCodes.CaseAmended),
                                    WithTransactionBody(TransactionStatus.Processed, TransactionReturnCodes.NoChangesMade),
                                    WithTransactionBody(TransactionStatus.Processed, TransactionReturnCodes.NoChangesMade)
                                   );

                var r = (await f.Subject.Retrieve(f.QueryParameters)).Data.ToArray<dynamic>();

                Assert.Single(r);
                Assert.Equal(17, r[0].Total);
                Assert.Equal(3, r[0].NewCases);
                Assert.Equal(4, r[0].Rejected);
                Assert.Equal(2, r[0].NotMapped);
                Assert.Equal(1, r[0].NameIssues);
                Assert.Equal(3, r[0].Amended);
                Assert.Equal(2, r[0].NoChange);
                Assert.Equal(2, r[0].Unresolved);
                Assert.Equal(BatchStatus.Processed.ToString(), r[0].StatusType);
            }

            [Fact]
            public async Task ReturnsIsReversibleIfProcessIsErroredOut()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("HomeName")
                        .ImportedOn(Fixture.Today(), "HomeName", WithTransactionBody(TransactionReturnCodes.NewCase));

                new ProcessRequest
                {
                    BatchId = f.LastBatch().TransactionHeader.BatchId,
                    Status = new TableCode((int) ProcessRequestStatus.Error, (short) TableTypes.ProcessRequestStatus, "Error").In(Db),
                    StatusMessage = "The Error"
                }.In(Db);

                var result = (await f.Subject.Retrieve(f.QueryParameters)).Data.ToArray<dynamic>();

                Assert.True(result[0].IsReversible);
            }

            [Fact]
            public async Task ReturnsIsReversibleIfProcessNotRunning()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("HomeName")
                        .ImportedOn(Fixture.Today(), "HomeName", WithTransactionBody(TransactionReturnCodes.NewCase));

                // no proecess row

                var result = (await f.Subject.Retrieve(f.QueryParameters)).Data.ToArray<dynamic>();

                Assert.True(result[0].IsReversible);
            }

            [Fact]
            public async Task ReturnsOnlyBatchesImportedFromFile()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("MYAC")
                        .NotImportedFromFile()
                        .ImportedOn(Fixture.Today(), "MYAC", WithTransactionBody(TransactionReturnCodes.NewCase));

                var r = await f.Subject.Retrieve(f.QueryParameters);

                Assert.Equal(0, r.Total);
            }

            [Fact]
            public async Task ReturnsResolutionRequiredStatus()
            {
                var f = new ImportStatusSummaryFixture(Db)
                        .WithValidSenderAsHomeName("HomeName")
                        .ImportedOn(Fixture.Today(), "HomeName",
                                    WithTransactionBody(TransactionReturnCodes.NewCase));

                f.LastBatch().TransactionHeader.BatchStatus = new TableCode(EdeBatchStatus.Unprocessed, (short) TableTypes.EDEBatchStatus, "blah").In(Db);

                var result = await f.Subject.Retrieve(f.QueryParameters);

                Assert.Equal(BatchStatus.ResolutionRequired.ToString(), result.Data.ToArray<dynamic>()[0].StatusType);
            }
        }
    }
}
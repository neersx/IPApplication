using System;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Components.Names;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;
using InprotechKaizen.Model.Names;
using Z.EntityFramework.Plus;

namespace Inprotech.Tests.Integration.Classic.EndToEnd.BulkCaseImport
{
    public class MappingIssuesDbSetup : DbSetup
    {
        public MappingIssuesDbSetup()
        {
            NameBuilder = new NameBuilder(DbContext);
        }

        public NameBuilder NameBuilder { get; }

        public Names CreateNames()
        {
            var orgPrefix = RandomString.Next(5);
            var indPrefix = RandomString.Next(5);

            var orgCandidate1 = NameBuilder.CreateClientOrg(orgPrefix);
            var orgCandidate2 = NameBuilder.CreateClientOrg(orgPrefix);

            var individualCandidate1 = NameBuilder.CreateClientIndividual(indPrefix);
            var individualCandidate2 = NameBuilder.CreateClientIndividual(indPrefix);
            var individualCandidate3 = NameBuilder.CreateClientIndividual(indPrefix);

            return new Names
                   {
                       Org1 = orgCandidate1,
                       Org2 = orgCandidate2,
                       Ind1 = individualCandidate1,
                       Ind2 = individualCandidate2,
                       Ind3 = individualCandidate3
                   };
        }

        public int CreateBatchWithMappingIssue(Name orgToMatch, Name indToMatch)
        {
            using (var tcs = DbContext.BeginTransaction())
            {
                var codes = DbContext.Set<TableCode>()
                                     .Where(
                                            tc =>
                                                tc.Id == EdeBatchStatus.Unprocessed || tc.Id == (int) ProcessRequestStatus.Error ||
                                                tc.Id == (int) TransactionStatus.UnmappedCodes ||
                                                tc.Id == (int) TransactionStatus.UnresolvedNames)
                                     .ToDictionary(k => k.Id, v => v);

                var unmapped = DbContext.Set<EdeStandardIssues>().Single(si => si.Id == Issues.UnmappedCode);

                var th = Insert(new EdeTransactionHeader
                                {
                                    BatchStatus = codes[EdeBatchStatus.Unprocessed]
                                });

                th.TransactionBodies.Add(new EdeTransactionBody(new[]
                                                                {
                                                                    new EdeOutstandingIssues
                                                                    {
                                                                        Issue = "this e2e test!",
                                                                        StandardIssue = unmapped
                                                                    }
                                                                })
                                         {
                                             TransactionStatus = codes[(int) TransactionStatus.UnmappedCodes],
                                             TransactionIdentifier = Guid.NewGuid().ToString(),
                                             CaseDetails = null,
                                             CaseMatch = null
                                         });

                th.TransactionBodies.Add(new EdeTransactionBody
                                         {
                                             TransactionStatus = codes[(int) TransactionStatus.UnresolvedNames],
                                             TransactionIdentifier = Guid.NewGuid().ToString()
                                         });

                th.UnresolvedNames.Add(new EdeUnresolvedName
                                       {
                                           Name = orgToMatch.LastName,
                                           NameType = "I",
                                           SenderNameIdentifier = orgToMatch.NameCode,
                                           AddressLine = orgToMatch.PostalAddress().Street1,
                                           City = orgToMatch.PostalAddress().City,
                                           State = orgToMatch.PostalAddress().State,
                                           PostCode = orgToMatch.PostalAddress().PostCode
                                       });

                th.UnresolvedNames.Add(new EdeUnresolvedName
                                       {
                                           Name = indToMatch.LastName + "1",
                                           FirstName = indToMatch.FirstName,
                                           NameType = "I",
                                           SenderNameIdentifier = indToMatch.NameCode
                                       });

                Insert(new EdeSenderDetails
                       {
                           LastModified = DateTime.Now,
                           Sender = "MYAC",
                           SenderRequestIdentifier = RandomString.Next(20),
                           SenderNameNo = -493,
                           SenderRequestType = KnownSenderRequestTypes.CaseImport,
                           TransactionHeader = th
                       });

                Insert(new ProcessRequest
                       {
                           User = "dbo",
                           Context = ProcessRequestContexts.ElectronicDataExchange,
                           RequestType = "EDE Resubmit Batch",
                           RequestDescription = Fixture.Prefix("E2E Test"),
                           Status = codes[(int) ProcessRequestStatus.Error],
                           StatusMessage = Fixture.Prefix("E2E Status Message"),
                           BatchId = th.BatchId
                       });

                DbContext.Set<EdeOutstandingIssues>()
                         .Where(_ => _.BatchId == th.BatchId)
                         .Update(x => new EdeOutstandingIssues {TransactionIdentifier = null});

                tcs.Complete();

                return th.BatchId;
            }
        }
    }
}
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Fakes;
using Inprotech.Tests.Web.Builders.Model.Cases;
using Inprotech.Web.BulkCaseImport;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Ede;

namespace Inprotech.Tests.Web.Builders.BulkCaseImport
{
    public class EdeBatchBuilder : IBuilder<EdeTransactionHeader>
    {
        readonly InMemoryDbContext _db;

        public EdeBatchBuilder(InMemoryDbContext db, int batchId, string senderRequestIdentifier, int batchStatus)
        {
            _db = db;
            BatchId = batchId;
            EdeTransactionHeader =
                new EdeTransactionHeader
                {
                    BatchId = batchId,
                    BatchStatus = new TableCode(batchStatus, (int) TableTypes.EDEBatchStatus, "BatchStatus")
                }.In(db);
            EdeSenderDetails =
                new EdeSenderDetails
                {
                    SenderRequestIdentifier = senderRequestIdentifier,
                    TransactionHeader = EdeTransactionHeader
                }.In(db);
        }

        public EdeTransactionHeader EdeTransactionHeader { get; protected set; }
        public EdeSenderDetails EdeSenderDetails { get; protected set; }
        public int BatchId { get; set; }

        public EdeTransactionHeader Build()
        {
            return EdeTransactionHeader;
        }

        public EdeBatchBuilder WithNewCase(string irn, string edeCountry, string edePropertyType,
                                           int? transStatus, string transactionId = "", string transactionReturnCode = "", string shortTitleText = "")
        {
            var @case = new CaseBuilder {Irn = irn}
                        .Build().In(_db);

            var edeCaseDetails = new EdeCaseDetails
            {
                CasePropertyTypeCode = edePropertyType,
                CaseCountryCode = edeCountry,
                CaseId = @case.Id
            }.In(_db);

            LinkTransactionBody(transactionId, edeCaseDetails, null, transStatus, transactionReturnCode, GetDescriptionDetails(transactionId, shortTitleText));

            return this;
        }

        public EdeBatchBuilder WithNewCases(int count)
        {
            for (var i = 0; i < count; i++)
            {
                var @case = new CaseBuilder {Irn = Fixture.String()}
                            .Build().In(_db);

                var edeCaseDetails = new EdeCaseDetails
                {
                    CasePropertyTypeCode = Fixture.String(),
                    CaseCountryCode = Fixture.String(),
                    CaseId = @case.Id
                }.In(_db);

                LinkTransactionBody(Fixture.String(), edeCaseDetails, null, null, null);
            }

            return this;
        }

        public EdeBatchBuilder WithMatchedCase(string irn, string edeCountry, string edePropertyType, int? transStatus, string transactionId = "", string transactionReturnCode = "", string shortTitleText = "", string matchLevel = null)
        {
            var @case = new CaseBuilder {Irn = irn}
                        .Build().In(_db);

            var edeCaseMatch = new EdeCaseMatch
            {
                DraftCaseId = @case.Id,
                LiveCaseId = @case.Id
            }.In(_db);

            if (!string.IsNullOrWhiteSpace(matchLevel))
            {
                edeCaseMatch.MatchLevel = new TableCode(Fixture.Integer(), (short) TableTypes.DraftCaseMatchLevel, matchLevel).In(_db).Id;
            }

            LinkTransactionBody(transactionId, null, edeCaseMatch, transStatus, transactionReturnCode, GetDescriptionDetails(transactionId, shortTitleText));

            return this;
        }

        public EdeBatchBuilder WithTransactionIssue(string shortIssueDesc, string longIssueDesc)
        {
            foreach (var t in EdeTransactionHeader.TransactionBodies)
            {
                var issues = new EdeOutstandingIssues
                {
                    BatchId = BatchId,
                    StandardIssue =
                        new EdeStandardIssues
                        {
                            Id = Fixture.Integer(),
                            Code = Fixture.String(),
                            ShortDescription = shortIssueDesc,
                            LongDescription = longIssueDesc
                        }.In(_db)
                };
                t.OutstandingIssues.Add(issues);
                t.In(_db);
            }

            return this;
        }

        public EdeBatchBuilder WithOfficialNumber(string number, short? displayPriority, string numberType)
        {
            foreach (var t in EdeTransactionHeader.TransactionBodies)
            {
                var edeNumber = new EdeIdentifierNumberDetails
                {
                    NumberType =
                        string.IsNullOrEmpty(numberType)
                            ? null
                            : new NumberTypeBuilder {DisplayPriority = displayPriority, Code = numberType}.Build(),
                    IdentifierNumberText = number
                };
                t.IdentifierNumberDetails.Add(edeNumber);
                t.In(_db);
            }

            return this;
        }

        IEnumerable<EdeDescriptionDetails> GetDescriptionDetails(string transactionId, string description)
        {
            yield return new EdeDescriptionDetails
            {
                BatchId = BatchId,
                TransactionIdentifier = transactionId,
                DescriptionCode = Constants.ShortTitleType,
                DescriptionText = description
            }.In(_db);
        }

        void LinkTransactionBody(string transactionId, EdeCaseDetails caseDetails, EdeCaseMatch caseMatch, int? status, string transactionReturnCode = "", IEnumerable<EdeDescriptionDetails> descriptions = null)
        {
            status = status ?? (int) TransactionStatus.Processed;

            var transBody = new EdeTransactionBody
            {
                BatchId = BatchId,
                TransactionIdentifier =
                    string.IsNullOrWhiteSpace(transactionId)
                        ? (EdeTransactionHeader.TransactionBodies.Count + 1).ToString()
                        : transactionId,
                TransactionReturnCode = transactionReturnCode,
                TransactionStatus =
                    new TableCode((int) status, (int) TableTypes.EDETransactionStatus, status.ToString()),
                CaseDetails = caseDetails,
                CaseMatch = caseMatch,
                DescriptionDetails = descriptions == null ? new EdeDescriptionDetails[] { } : descriptions.ToArray()
            }.In(_db);

            EdeTransactionHeader.TransactionBodies.Add(transBody);
        }
    }
}
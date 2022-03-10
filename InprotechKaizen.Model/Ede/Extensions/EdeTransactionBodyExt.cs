using System.Collections.Generic;
using System.Linq;

namespace InprotechKaizen.Model.Ede.Extensions
{
    public static class EdeTransactionBodyExt
    {
        static readonly int[] TransactionStatusIncomplete =
        {
            (int) TransactionStatus.UnmappedCodes,
            (int) TransactionStatus.UnresolvedNames,
            (int) TransactionStatus.Processed
        };

        static readonly Dictionary<string, int> ReturnStatusMap = new Dictionary<string, int>
                                                                  {
                                                                      {"nameIssuesCases", (int) TransactionStatus.UnresolvedNames},
                                                                      {"mappingIssuesCases", (int) TransactionStatus.UnmappedCodes},
                                                                  };

        static IQueryable<EdeTransactionBody> HasTransactionStatus(this IQueryable<EdeTransactionBody> transactionBodies)
        {
            return transactionBodies.Where(tb => tb.TransactionStatus != null);
        }

        public static IQueryable<EdeTransactionBody> WithReturnCode(this IQueryable<EdeTransactionBody> transactions, string transReturnCode = null)
        {
            if (string.IsNullOrWhiteSpace(transReturnCode))
                return transactions;

            if (transReturnCode == "incomplete")
            {
                return transactions
                    .Where(t =>
                               t.TransactionStatus == null ||
                               !TransactionStatusIncomplete.Contains(t.TransactionStatus.Id));
            }

            if (transReturnCode == "nameIssuesCases" || transReturnCode == "mappingIssuesCases")
            {
                var transStatusCodeFilter = ReturnStatusMap[transReturnCode];
                return transactions
                    .HasTransactionStatus()
                    .Where(t => t.TransactionStatus.Id == transStatusCodeFilter);
            }

            if (transReturnCode == TransactionReturnCode.RejectedCases)
            {
                var rejectedTransactionReturnCodes = TransactionReturnCode.Map[transReturnCode];

                return transactions
                    .HasTransactionStatus()
                    .Where(t => rejectedTransactionReturnCodes.Contains(t.TransactionReturnCode));
            }

            var transReturnCodeFilter = TransactionReturnCode.Map[transReturnCode];
            return transactions
                .HasTransactionStatus()
                .Where(t => transReturnCodeFilter.Contains(t.TransactionReturnCode) &&
                            t.TransactionStatus.Id == (int) TransactionStatus.Processed);
        }
    }

    public static class TransactionReturnCode
    {
        public const string AmendedCases = "amendedCases";
        public const string RejectedCases = "rejectedCases";
        public const string NoChangeCases = "noChangeCases";
        public const string NewCases = "newCases";

        public static readonly Dictionary<string, string[]> Map = new Dictionary<string, string[]>
                                                                  {
                                                                      {AmendedCases, new[] {TransactionReturnCodes.CaseAmended}},
                                                                      {RejectedCases, new[] {TransactionReturnCodes.CaseRejected, TransactionReturnCodes.CaseReverted, TransactionReturnCodes.CaseDeleted}},
                                                                      {NoChangeCases, new[] {TransactionReturnCodes.NoChangesMade}},
                                                                      {NewCases, new[] {TransactionReturnCodes.NewCase}}
                                                                  };
    }
}
using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Names.TrustAccounting
{
    public interface ITrustAccounting
    {
        IEnumerable<TrustAccounts> GetTrustAccountingData(int nameId, string culture);
        IEnumerable<TrustAccountingDetails> GetTrustAccountingDetails(int nameId, int bankId, int bankSeqId, int entityId, string culture);
    }

    public class TrustAccounting : ITrustAccounting
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;

        public TrustAccounting(ISecurityContext securityContext, IDbContext dbContext)
        {
            if (securityContext == null) throw new ArgumentNullException("securityContext");
            if (dbContext == null) throw new ArgumentNullException("dbContext");

            _securityContext = securityContext;
            _dbContext = dbContext;
        }

        public IEnumerable<TrustAccounts> GetTrustAccountingData(int nameId, string culture)
        {
            using (var sqlCommand = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.ListTrustAccounting))
            {
                sqlCommand.CommandTimeout = 0;
                sqlCommand.Parameters.AddRange(
                    new[]
                    {
                        new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                        new SqlParameter("@psCulture", culture),
                        new SqlParameter("@pbCalledFromCentura", false),
                        new SqlParameter("@pnNameKey", nameId)
                    });

                var resultList = new List<TrustAccounts>();
                using (var reader = sqlCommand.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        resultList.Add(new TrustAccounts
                        {
                            Id = reader["RowKey"] as string,
                            EntityKey = (int)reader["EntityKey"],
                            Entity = reader["Entity"] as string,
                            BankAccountNameKey = (int)reader["BankAccountNameKey"],
                            BankAccountSeqKey = (int)reader["BankAccountSeqKey"],
                            BankAccount = reader["BankAccount"] as string,
                            LocalBalance = reader["LocalBalance"] == DBNull.Value ? (decimal?)null : (decimal)reader["LocalBalance"],
                            ForeignBalance = reader["ForeignBalance"] == DBNull.Value ? null : (decimal)reader["ForeignBalance"] == (decimal)0 ? (decimal?)null : (decimal)reader["ForeignBalance"],
                            LocalCurrency = reader["LocalCurrency"] as string,
                            Currency = reader["Currency"] as string
                        });
                    }

                    return resultList;
                }
            }
        }

        public IEnumerable<TrustAccountingDetails> GetTrustAccountingDetails(int nameId, int bankId, int bankSeqId, int entityId, string culture)
        {
            using (var sqlCommand = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.ListTrustAccountingDetail))
            {
                sqlCommand.CommandTimeout = 0;
                sqlCommand.Parameters.AddRange(
                                               new[]
                                               {
                                                   new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                                   new SqlParameter("@psCulture", culture),
                                                   new SqlParameter("@pbCalledFromCentura", false),
                                                   new SqlParameter("@pnNameKey", nameId),
                                                   new SqlParameter("@pnBankKey", bankId),
                                                   new SqlParameter("@pnBankSeqNo", bankSeqId),
                                                   new SqlParameter("@pnEntityKey", entityId)
                                               });

                var resultList = new List<TrustAccountingDetails>();
                using (var reader = sqlCommand.ExecuteReader())
                    while (reader.Read())
                    {
                        resultList.Add(new TrustAccountingDetails
                        {
                            TraderId = (int)reader["TraderKey"],
                            Trader = reader["Trader"] == DBNull.Value ? string.Empty : ((string) reader["Trader"]).Length > 50 ? ((string) reader["Trader"]).Substring(0,46) + "..." : (string) reader["Trader"],
                            TraderFull = reader["Trader"] as string,
                            Date = reader.GetDateTime(4),
                            ItemRefNo = reader["ItemRefNo"] as string,
                            ReferenceNo = (int)reader["ReferenceNo"],
                            LocalValue = reader["LocalValue"] == DBNull.Value ? (decimal?)null : (decimal)reader["LocalValue"],
                            LocalBalance = reader["LocalBalance"] == DBNull.Value ? (decimal?)null : (decimal)reader["LocalBalance"],
                            ForeignValue = reader["ForeignValue"] == DBNull.Value ? (decimal?)null : (decimal)reader["ForeignValue"],
                            ForeignBalance = reader["ForeignBalance"] == DBNull.Value ? (decimal?)null : (decimal)reader["ForeignBalance"],
                            ExchVariance = reader["ExchVariance"] == DBNull.Value ? (decimal?)null : (decimal)reader["ExchVariance"],
                            LocalCurrency = reader["LocalCurrency"] as string,
                            Currency = reader["Currency"] as string,
                            TransType = reader["TransType"] as string,
                            DescriptionFull = reader["Description"] as string,
                            Description = reader["Description"] == DBNull.Value ? string.Empty : ((reader["Description"] as string).Length > 50 ? ((string) reader["Description"]).Substring(0,46) + "..." : (string) reader["Description"])
                        });
                    }

                return resultList;
            }
        }
    }
}
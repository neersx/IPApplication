using System;
using System.Collections.Generic;
using InprotechKaizen.Model.Components.Accounting;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.ChargeGeneration
{
    public static class RatesCommand
    {
        public static List<BestChargeRates> GetRates(this IDbContext dbContext, int caseId, int? chargeTypeId)
        {
            var inputParameters = new Parameters
            {
                {"@pnCaseId", caseId},
                {"@pnChargeTypeId", chargeTypeId}
            };

            using (var command = dbContext.CreateStoredProcedureCommand("apps_GetRateNos", inputParameters))
            {
                var resultList = new List<BestChargeRates>();
                using (var reader = command.ExecuteReader())
                {
                    while (reader.Read())
                    {
                        resultList.Add(new BestChargeRates
                        {
                            RateId = (int) reader["RateId"],
                            RateTypeId = reader["RateTypeId"] == DBNull.Value ? (int?) null : (int) reader["RateTypeId"]
                        });
                    }

                    return resultList;
                }
            }
        }
    }
}
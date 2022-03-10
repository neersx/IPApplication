using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Processing;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Policing.Forecast
{
    public interface IPolicingRequestSps
    {
        PolicingRequestAffectedCases GetNoOfAffectedCases(int requestId, bool onlyCheckFeatureAvailability = false);

        Task<IPolicingResult> CreatePolicingForCasesFromRequest(int requestId);
    }

    public class PolicingRequestSps : IPolicingRequestSps
    {
        /// <summary>
        ///     @pnRequestId int
        /// </summary>
        public const string WhatWillBePoliced = "apps_WhatWillBePoliced";

        /// <summary>
        ///     @pnRequestId int
        /// </summary>
        public const string CreatePolicingForAffectedCases = "apps_CreatePolicingForAffectedCases";

        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IAsyncCommandScheduler _asyncCommandScheduler;

        public PolicingRequestSps(IDbContext dbContext, ISecurityContext securityContext, IAsyncCommandScheduler asyncCommandScheduler)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _asyncCommandScheduler = asyncCommandScheduler;
        }

        public PolicingRequestAffectedCases GetNoOfAffectedCases(int requestId, bool onlyCheckFeatureAvailability = false)
        {
            var affectedCases = new PolicingRequestAffectedCases();

            using (var command = _dbContext.CreateStoredProcedureCommand(WhatWillBePoliced))
            {
                command.CommandTimeout = 0;
                command.Parameters.AddRange(
                                            new[]
                                            {
                                                new SqlParameter("@pbOnlyCheckAvailability", onlyCheckFeatureAvailability),
                                                new SqlParameter("@pnUserIdentityId", DBNull.Value),
                                                new SqlParameter("@pnRequestId", requestId)
                                            });

                using (IDataReader dr = command.ExecuteReader())
                {
                    if (dr.Read())
                    {
                        affectedCases.IsSupported = Convert.ToBoolean(dr["IsSupported"]);
                        affectedCases.NoOfCases = Convert.ToInt32(dr["NoOfCases"]);
                    }

                    return affectedCases;
                }
            }
        }

        public async Task<IPolicingResult> CreatePolicingForCasesFromRequest(int requestId)
        {
            try
            {
                await _asyncCommandScheduler.ScheduleAsync(CreatePolicingForAffectedCases, 
                                                           new Dictionary<string, object>
                                                           {
                                                               { "@pnUserIdentityId", _securityContext.User.Id },
                                                               { "@pnRequestId", requestId }
                                                           });
            }
            catch (SqlException sqe)
            {
                return new PolicingResult(sqe.Message);
            }

            return new PolicingResult();
        }
    }
}
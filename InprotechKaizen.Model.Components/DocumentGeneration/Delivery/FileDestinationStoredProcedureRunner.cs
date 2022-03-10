using System;
using System.Collections.Generic;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Exceptions;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.DocumentGeneration.Delivery
{
    public interface IDeliveryDestinationStoredProcedureRunner
    {
        Task<DeliveryDestination> Run(int? caseId, int? nameId, short? letterId, int? activityId, string externallyProvidedFileDestinationResolver);
    }

    public class DeliveryDestinationStoredProcedureRunner : IDeliveryDestinationStoredProcedureRunner
    {
        readonly IDbContext _dbContext;
        readonly ISqlHelper _sqlHelper;
        readonly IBackgroundProcessLogger<DeliveryDestinationStoredProcedureRunner> _logger;

        public DeliveryDestinationStoredProcedureRunner(IDbContext dbContext, ISqlHelper sqlHelper, IBackgroundProcessLogger<DeliveryDestinationStoredProcedureRunner> logger)
        {
            _dbContext = dbContext;
            _sqlHelper = sqlHelper;
            _logger = logger;
        }

        public async Task<DeliveryDestination> Run(int? caseId, int? nameId, short? letterId, int? activityId, string externallyProvidedFileDestinationResolver)
        {
            if (externallyProvidedFileDestinationResolver == null) throw new ArgumentNullException(nameof(externallyProvidedFileDestinationResolver));

            try
            {
                _logger.Debug($"Resolving Delivery Destination using {externallyProvidedFileDestinationResolver} with activityId: {activityId}");
                var derivedParams = _sqlHelper.DeriveParameters(externallyProvidedFileDestinationResolver).ToList();
                using (var command = _dbContext.CreateStoredProcedureCommand(externallyProvidedFileDestinationResolver))
                {
                    if (caseId.HasValue && TryParam(derivedParams, out var param, "@pnCaseId", "@pnCaseKey"))
                        command.Parameters.AddWithValue(param, caseId);

                    if (letterId.HasValue && TryParam(derivedParams, out param, "@pnLetterNo", "@pnDocumentKey"))
                        command.Parameters.AddWithValue(param, letterId);

                    if (activityId.HasValue && TryParam(derivedParams, out param, "@pnActivityId", "@pnActivityKey"))
                        command.Parameters.AddWithValue(param, activityId);

                    if (nameId.HasValue && TryParam(derivedParams, out param, "@pnNameNo", "@pnNameKey"))
                        command.Parameters.AddWithValue(param, nameId);

                    command.Parameters.Add(new SqlParameter("@prsDestinationDirectory", SqlDbType.NVarChar, 254)
                    {
                        Direction = ParameterDirection.Output
                    });

                    command.Parameters.Add(new SqlParameter("@prsDestinationFile", SqlDbType.NVarChar, 254)
                    {
                        Direction = ParameterDirection.Output
                    });

                    await command.ExecuteNonQueryAsync();

                    return new DeliveryDestination
                    {
                        DirectoryName = Convert.ToString(command.Parameters["@prsDestinationDirectory"].Value),
                        FileName = Convert.ToString(command.Parameters["@prsDestinationFile"].Value)
                    };
                }
            }
            catch (Exception e)
            {
                var message = $"Execution of {externallyProvidedFileDestinationResolver} with activityId: {activityId} has failed.";

                throw new CustomStoredProcedureErrorException(externallyProvidedFileDestinationResolver, message, e);
            }
        }

        bool TryParam(List<KeyValuePair<string, SqlDbType>> list, out string r, params string[] param)
        {
            r = string.Empty;
            foreach (var p in param)
            {
                if (list.Exists(_ => _.Key == p))
                {
                    r = p;
                    return true;
                }
            }

            return false;
        }
    }
}
using System;
using System.Data;
using System.Data.SqlClient;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Infrastructure.Messaging;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Components.Security;
using InprotechKaizen.Model.Components.System.Messages;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;
using InprotechKaizen.Model.Reminders;

namespace InprotechKaizen.Model.Components.Policing
{
    public interface IPolicingEngine
    {
        IQueuedPolicingResult QueueOpenActionRequest(int caseId, string actionId, int? cycle, bool isPoliceImmediately = false);
        bool AreThereOutstandingPolicingRequests(int caseId);
        IPolicingResult Police(int? policingBatchNo);
        int CreateBatch();
        IPolicingResult PoliceEvent(CaseEvent caseEvent, int? criteriaId, int? policingBatchNo, string actionId);
        IPolicingResult PoliceAsync(int policingBatchNo);
        IPolicingResult PoliceAsync(DateTime dateEntered, int sequenceNumber);
        Task PoliceWithoutTransaction(int? policingBatchNo);

        IPolicingResult PoliceEvent(CaseEvent caseEvent, int? criteriaId, int? policingBatchNo, string actionId, TypeOfPolicingRequest request);
        IPolicingResult PoliceAdHocDates(AlertRule alert, int? policingBatchNo);
    }

    public class PolicingEngine : IPolicingEngine
    {
        readonly IDbContext _dbContext;
        readonly ISecurityContext _securityContext;
        readonly IBus _bus;
        public PolicingEngine(IDbContext dbContext, ISecurityContext securityContext, IBus bus)
        {
            _dbContext = dbContext;
            _securityContext = securityContext;
            _bus = bus;
        }

        public IQueuedPolicingResult QueueOpenActionRequest(int caseId, string actionId, int? cycle, bool isPoliceImmediately = false)
        {
            QueuedPolicingResult result;
            try
            {
                int? policingBatchNo = null;
                if (isPoliceImmediately)
                {
                     policingBatchNo = GenerateBatchNumber();
                }

                var sqlCommand = _dbContext.CreateStoredProcedureCommand("ip_InsertPolicing");
                sqlCommand.CommandTimeout = 0;
                sqlCommand.Parameters.AddRange(
                                               new[]
                                               {
                                                   new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                                   new SqlParameter("@psCulture", null),
                                                   new SqlParameter("@psCaseKey", caseId.ToString()),
                                                   new SqlParameter("@pnTypeOfRequest", (int)TypeOfPolicingRequest.OpenAnAction),
                                                   new SqlParameter("@pnPolicingBatchNo", policingBatchNo),
                                                   new SqlParameter("@psSysGeneratedFlag", true),
                                                   new SqlParameter("@psAction", actionId),
                                                   new SqlParameter("@psEventKey", null),
                                                   new SqlParameter("@pnCycle", cycle),
                                                   new SqlParameter("@pnCriteriaNo", null),
                                                   new SqlParameter("@pnCountryFlags", null),
                                                   new SqlParameter("@pbFlagSetOn", false)
                                               });

                sqlCommand.ExecuteNonQuery();
                var message = new BroadcastMessageToClient
                {
                    Topic = "policing.change." + caseId,
                    Data = isPoliceImmediately ? "Running" : "Pending"
                };
                _bus.Publish(message);
                result = new QueuedPolicingResult(policingBatchNo);
            }
            catch (SqlException sqe)
            {
                result = new QueuedPolicingResult(sqe.Message);
            }
            return result;
        }

        public IPolicingResult Police(int? policingBatchNo)
        {
            PolicingResult result;
            using (var txScope = _dbContext.BeginTransaction())
            {
                var sqlCommand = _dbContext.CreateStoredProcedureCommand("ipu_Policing");
                sqlCommand.CommandTimeout = 0;
                sqlCommand.Parameters.AddRange(
                                               new[]
                                               {
                                                   new SqlParameter("@pdtPolicingDateEntered", null),
                                                   new SqlParameter("@pnPolicingSeqNo", null),
                                                   new SqlParameter("@pnDebugFlag", 0),
                                                   new SqlParameter("@pnBatchNo", policingBatchNo),
                                                   new SqlParameter("@psDelayLength", null),
                                                   new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                                   new SqlParameter("@psPolicingMessageTable", null),
                                                   new SqlParameter("@pnAsynchronousFlag", null),
                                                   new SqlParameter("@pnSessionTransNo", null),
                                                   new SqlParameter("@pnEDEBatchNo", null),
                                                   new SqlParameter("@pnBatchSize", null)
                                               });
                try
                {
                    sqlCommand.ExecuteNonQuery();
                    result = new PolicingResult();
                }
                catch (SqlException sqe)
                {
                    result = new PolicingResult(sqe.Message);
                }

                txScope.Complete();
            }

            return result;
        }

        public async Task PoliceWithoutTransaction(int? policingBatchNo)
        {
            var sqlCommand = _dbContext.CreateStoredProcedureCommand("ipu_Policing");
            sqlCommand.CommandTimeout = 0;
            sqlCommand.Parameters.AddRange(
                                               new[]
                                               {
                                                   new SqlParameter("@pdtPolicingDateEntered", null),
                                                   new SqlParameter("@pnPolicingSeqNo", null),
                                                   new SqlParameter("@pnDebugFlag", 0),
                                                   new SqlParameter("@pnBatchNo", policingBatchNo),
                                                   new SqlParameter("@psDelayLength", null),
                                                   new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                                   new SqlParameter("@psPolicingMessageTable", null),
                                                   new SqlParameter("@pnAsynchronousFlag", null),
                                                   new SqlParameter("@pnSessionTransNo", null),
                                                   new SqlParameter("@pnEDEBatchNo", null),
                                                   new SqlParameter("@pnBatchSize", null)
                                               });
            await sqlCommand.ExecuteNonQueryAsync();
        }

        public IPolicingResult PoliceAsync(int policingBatchNo)
        {
            return PoliceAsync(null, null, policingBatchNo);
        }

        public IPolicingResult PoliceAsync(DateTime dateEntered, int sequenceNumber)
        {
            return PoliceAsync(dateEntered, sequenceNumber, null);
        }
        IPolicingResult PoliceAsync(DateTime? dateEntered, int? sequenceNumber, int? policingBatchNo)
        {
            PolicingResult result;
            using (var txScope = _dbContext.BeginTransaction())
            {
                var sqlCommand = _dbContext.CreateStoredProcedureCommand("ipu_Policing_async");
                sqlCommand.CommandTimeout = 0;
                sqlCommand.Parameters.AddRange(
                                               new[]
                                               {
                                                   new SqlParameter("@pdtPolicingDateEntered", dateEntered),
                                                   new SqlParameter("@pnPolicingSeqNo", sequenceNumber),
                                                   new SqlParameter("@pnDebugFlag", 0),
                                                   new SqlParameter("@pnBatchNo", policingBatchNo),
                                                   new SqlParameter("@psDelayLength", null),
                                                   new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                                   new SqlParameter("@psPolicingMessageTable", null),
                                                   new SqlParameter("@pbGetTransactionNo", null)
                                               });
                try
                {
                    sqlCommand.ExecuteNonQuery();
                    result = new PolicingResult();
                }
                catch (SqlException sqe)
                {
                    result = new PolicingResult(sqe.Message);
                }

                txScope.Complete();
            }

            return result;
        }

        public bool AreThereOutstandingPolicingRequests(int caseId)
        {
            return _dbContext.Set<PolicingRequest>()
                             .Any(
                                  p => p.CaseId == caseId && p.IsSystemGenerated == 1);
        }

        public IPolicingResult PoliceEvent(CaseEvent caseEvent, int? criteriaId, int? policingBatchNo, string actionId)
        {
            return PoliceEvent(
                               caseEvent,
                               criteriaId,
                               policingBatchNo,
                               actionId,
                               caseEvent.HasOccurred()
                                   ? TypeOfPolicingRequest.PoliceOccurredEvent
                                   : TypeOfPolicingRequest.PoliceDueEvent);
        }

        public int CreateBatch()
        {
            return GenerateBatchNumber();
        }

        int GenerateBatchNumber()
        {
            var sqlCommand = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.GetLastInternalCode);
            sqlCommand.CommandTimeout = 0;
            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                               new SqlParameter("@psCulture", null),
                                               new SqlParameter("@psTable", "POLICING"),
                                               new SqlParameter("@pnLastInternalCode", SqlDbType.Int)
                                               {
                                                   Direction =
                                                       ParameterDirection
                                                       .Output
                                               },
                                               new SqlParameter("@pbCalledFromCentura", false),
                                               new SqlParameter("@pbIsInternalCodeNegative", false)
                                           });
            return Convert.ToInt32(sqlCommand.ExecuteNonQuery());
        }

        public IPolicingResult PoliceEvent(
            CaseEvent caseEvent,
            int? criteriaId,
            int? policingBatchNo,
            string actionId,
            TypeOfPolicingRequest typeOfPolicingRequest)
        {
            PolicingResult result;
            var sqlCommand = _dbContext.CreateStoredProcedureCommand("ip_InsertPolicing");
            sqlCommand.CommandTimeout = 0;
            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                               new SqlParameter("@psCulture", null),
                                               new SqlParameter("@psCaseKey", caseEvent.CaseId.ToString()),
                                               new SqlParameter("@pnTypeOfRequest", typeOfPolicingRequest),
                                               new SqlParameter("@pnPolicingBatchNo", policingBatchNo),
                                               new SqlParameter("@psSysGeneratedFlag", true),
                                               new SqlParameter("@psAction", actionId),
                                               new SqlParameter("@psEventKey", caseEvent.EventNo),
                                               new SqlParameter("@pnCycle", caseEvent.Cycle),
                                               new SqlParameter("@pnCriteriaNo", criteriaId),
                                               new SqlParameter("@pnCountryFlags", null),
                                               new SqlParameter("@pbFlagSetOn", false)
                                           });
            try
            {
                sqlCommand.ExecuteNonQuery();
                result = new PolicingResult();
            }
            catch (SqlException sqe)
            {
                result = new PolicingResult(sqe.Message);
            }
            return result;
        }

        public IPolicingResult PoliceAdHocDates(AlertRule alert, int? policingBatchNo)
        {
            PolicingResult result;
            var sqlCommand = _dbContext.CreateStoredProcedureCommand("ipw_InsertPolicing");
            sqlCommand.CommandTimeout = 0;
            sqlCommand.Parameters.AddRange(
                                           new[]
                                           {
                                               new SqlParameter("@pnUserIdentityId", _securityContext.User.Id),
                                               new SqlParameter("@psCulture", null),
                                               new SqlParameter("@pnTypeOfRequest", alert.DateOccurred.HasValue ? TypeOfPolicingRequest.PoliceOccurredEvent : TypeOfPolicingRequest.PoliceDueEvent),
                                               new SqlParameter("@pnPolicingBatchNo", policingBatchNo),
                                               new SqlParameter("@pnAdHocNameNo", alert.StaffId),
                                               new SqlParameter("@pdtAdHocDateCreated", alert.DateCreated)
                                           });
            try
            {
                sqlCommand.ExecuteNonQuery();
                result = new PolicingResult();
            }
            catch (SqlException sqe)
            {
                result = new PolicingResult(sqe.Message);
            }

            return result;
        }
    }
}
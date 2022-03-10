using System;
using System.Collections.Generic;
using System.Linq;
using Inprotech.Tests.Integration.DbHelpers;
using Inprotech.Tests.Integration.DbHelpers.Builders;
using Inprotech.Tests.Integration.Extensions;
using Inprotech.Tests.Integration.Utils;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Policing;

#pragma warning disable 618

namespace Inprotech.Tests.Integration.IntegrationTests.Policing.Graphs
{
    public class PolicingGraphDbSetup : DbSetup
    {
        public void StopModificationTrigger()
        {
            DbContext.CreateSqlCommand("Disable Trigger tI_POLICING_Audit on Policing").ExecuteNonQuery();
        }

        public void EnableModificationTrigger()
        {
            DbContext.CreateSqlCommand("Enable Trigger tI_POLICING_Audit on Policing").ExecuteNonQuery();
        }

        Case GetCase(string irn = null)
        {
            var prefixedIrn = Fixture.Prefix(irn);

            return DbContext.Set<Case>().SingleOrDefault(_ => _.Irn == prefixedIrn + "irn") ?? new CaseBuilder(DbContext).Create(prefixedIrn, true);
        }

        public PolicingRequest EnqueueFor(string status, string typeOfRequest, DateTime? start = null, string irn = "")
        {
            var startAdjusted = start == null ? Helpers.UniqueDateTime() : Helpers.UniqueDateTime(start);
            Case @case = null;
            if (!string.IsNullOrWhiteSpace(irn))
                @case = GetCase(irn);

            return Insert(new PolicingRequest(null)
                          {
                              OnHold = KnownValues.StringToHoldFlag[status],
                              IsSystemGenerated = 1,
                              Name = "E2E Test " + RandomString.Next(6),
                              DateEntered = startAdjusted,
                              SequenceNo = 1,
                              TypeOfRequest = (short) KnownValues.StringToTypeOfRequest[typeOfRequest],
                              Case = @case,
                              CaseId = @case?.Id,
                              Irn = @case?.Irn,
                              LastModified = startAdjusted
                          });
        }

        public PolicingError CreateErrorFor(PolicingRequest request)
        {
            var log = DbContext.Set<PolicingLog>()
                               .SingleOrDefault(_ => _.StartDateTime == request.DateEntered && _.PolicingName == request.Name);

            if (log == null)
            {
                Insert(new PolicingLog
                       {
                           StartDateTime = request.DateEntered,
                           PolicingName = request.Name,
                           FailMessage = "Fail message" + RandomString.Next(6)
                       });
            }

            return InsertWithNewId(new PolicingError
                                   {
                                       StartDateTime = request.DateEntered,
                                       CaseId = request.Case?.Id,
                                       CycleNo = 1,
                                       Message = "E2E Error" + RandomString.Next(6)
                                   },
                                   x => x.ErrorSeqNo,
                                   x => x.StartDateTime == request.DateEntered);
        }

        public void EnsureLogExists()
        {
            if (RevertLog())
            {
                using (var cleanCmd = DbContext.CreateSqlCommand("DELETE POLICING_iLOG WHERE CreatedByE2E = 1"))
                {
                    cleanCmd.ExecuteNonQuery();
                }
                return;
            }

            const string script = "CREATE TABLE POLICING_iLOG(LOGDATETIMESTAMP datetime, LOGACTION nchar (1), CREATEDBYE2E bit Default 1)";

            DbContext.CreateSqlCommand(script).ExecuteNonQuery();
        }

        private bool RevertLog()
        {
            if (new SqlDbArtifacts(DbContext).Exists("POLICING_iLOG", SysObjects.Table, SysObjects.View))
                return true;

            if (!new SqlDbArtifacts(DbContext).Exists("POLICING_iLOGTempZ", SysObjects.Table, SysObjects.View))
                return false;

            const string script = "EXEC sp_rename 'POLICING_iLOGTempZ', 'POLICING_iLOG'";
            DbContext.CreateSqlCommand(script).ExecuteNonQuery();

            return true;
        }

        public void AddLogForInsert(DateTime? dateTime)
        {
            AddLog(dateTime, "I");
        }

        public void AddLogForDelete(DateTime? dateTime = null)
        {
            AddLog(dateTime, "D");
        }

        private void AddLog(DateTime? dateTime, string logAction)
        {
            dateTime = Helpers.UniqueDateTime(dateTime);
            using (var sqlCmd = DbContext.CreateSqlCommand("Insert into Policing_iLog(LOGDATETIMESTAMP, LOGACTION) values(@dateTime, @logAction)"))
            {
                sqlCmd.Parameters.AddWithValue("@dateTime", dateTime);
                sqlCmd.Parameters.AddWithValue("@logAction", logAction);
                sqlCmd.ExecuteNonQuery();
            }
        }
    }

    static class KnownValues
    {
        public static readonly Dictionary<string, int> StringToHoldFlag =
            new Dictionary<string, int>
            {
                {"in-error", 4},
                {"on-hold", 9},
                {"waiting-to-start", 0},
                {"in-progress", 3}
            };

        public static readonly Dictionary<string, int> StringToTypeOfRequest =
            new Dictionary<string, int>
            {
                {"open-action", 1},
                {"due-date-changed", 2},
                {"event-occurred", 3},
                {"action-recalculation", 4},
                {"designated-country-change", 5},
                {"due-date-recalculation", 6},
                {"patent-term-adjustment", 7},
                {"document-case-changes", 8},
                {"prior-art-distribution", 9}
            };
    }

    internal static class Helpers
    {
        static int _secs = 1;

        internal static DateTime UniqueDateTime(DateTime? dateTime = null)
        {
            return (dateTime ?? DateTime.Today).AddSeconds(_secs++);
        }
    }
}
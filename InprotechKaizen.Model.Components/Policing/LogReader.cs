using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Policing
{
    public interface ILogReader
    {
        bool TryGetRateGraphData(out PolicingRateItem[] graphItems);
        bool IsHistoricalDataAvailable();
    }

    public class LogReader : ILogReader
    {
        readonly IDbContext _dbContext;
        readonly IDbArtifacts _dbArtifacts;
        readonly IBackgroundProcessLogger<LogReader> _logger;
        
        const string PolicingRateSp = "apps_PolicingRate";

        public LogReader(IDbContext dbContext, IDbArtifacts dbArtifacts, IBackgroundProcessLogger<LogReader> logger)
        {
            _dbContext = dbContext;
            _dbArtifacts = dbArtifacts;
            _logger = logger;
        }

        public bool IsHistoricalDataAvailable()
        {
            return _dbArtifacts.Exists(AuditTrail.Logging.Policing, SysObjects.View, SysObjects.Table);
        }

        public bool TryGetRateGraphData(out PolicingRateItem[] graphItems)
        {
            try
            {
                graphItems = GetData().ToArray();
                return true;
            }
            catch (SqlException ex)
            {
                _logger.Exception(ex);

                graphItems = new PolicingRateItem[0];
                return false;
            }
        }

        IEnumerable<PolicingRateItem> GetData()
        {
            var sqlCommand = _dbContext.CreateStoredProcedureCommand(PolicingRateSp);
            sqlCommand.CommandTimeout = 0;

            using (var reader = sqlCommand.ExecuteReader())
            {
                while (reader.Read())
                {
                    yield return new PolicingRateItem
                    {
                        TimeSlot = (DateTime)reader["Slot"],
                        EnterQueue = (int)reader["EnterQueue"],
                        ExitQueue = (int)reader["ExitQueue"]
                    };
                }
            }
        }
    }
    
    public class PolicingRateItem
    {
        public DateTime TimeSlot { get; set; }
        public int EnterQueue { get; set; }
        public int ExitQueue { get; set; }
    }
}
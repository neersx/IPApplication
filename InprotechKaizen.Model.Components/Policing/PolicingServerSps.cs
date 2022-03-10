using System;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Policing
{
    public interface IPolicingServerSps
    {
        void PolicingStartContinuously(int? backgroundIdentityId, int? delayInSeconds);

        bool PolicingBackgroundProcessExists();
    }

    public class PolicingServerSps : IPolicingServerSps
    {
        static TrackingTableStatus _trackingTableStatus;

        readonly IDbArtifacts _dbArtifacts;
        readonly IDbContext _dbContext;

        public PolicingServerSps(IDbContext dbContext, IDbArtifacts dbArtifacts)
        {
            _dbContext = dbContext;
            _dbArtifacts = dbArtifacts;
        }

        public void PolicingStartContinuously(int? backgroundIdentityId, int? delayInSeconds)
        {
            var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.PolicingStartContinuously);

            command.Parameters.AddWithValue("pnUserIdentityId", backgroundIdentityId);

            if (delayInSeconds != null && delayInSeconds > 0 && delayInSeconds <= 3600)
            {
                var pollingDelay = TimeSpan.FromSeconds((double) delayInSeconds);

                command.Parameters.AddWithValue("psDelayLength", pollingDelay.ToString());
            }

            command.ExecuteNonQuery();
        }

        public bool PolicingBackgroundProcessExists()
        {
            if (_trackingTableStatus == TrackingTableStatus.Unchecked)
            {
                _trackingTableStatus = _dbArtifacts.Exists(Functions.PolicingContinuouslyTrackingTable, SysObjects.Function)
                    ? TrackingTableStatus.Exists
                    : TrackingTableStatus.NotExists;
            }

            var command = _dbContext.CreateStoredProcedureCommand("apps_IsPolicingProcessRunning");

            command.Parameters.AddWithValue("pnType", (int) _trackingTableStatus);

            return (int?) command.ExecuteScalar() == 1;
        }
    }

    internal enum TrackingTableStatus
    {
        Unchecked = 0,
        Exists = 1,
        NotExists = 2
    }
}
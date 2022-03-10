using Inprotech.Infrastructure;
using InprotechKaizen.Model.Cases;
using InprotechKaizen.Model.Configuration;
using InprotechKaizen.Model.Persistence;
using InprotechKaizen.Model.Security;
using System;
using System.Collections.Generic;
using System.Linq;
using System.Text;
using System.Threading.Tasks;

namespace Inprotech.Integration.BulkCaseUpdates
{
    public interface IBulkFileLocationUpdateHandler
    {
        Task UpdateFileLocationAsync(BulkCaseUpdatesArgs request, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkUpdateResult bulkUpdateResult);
    }

    public class BulkFileLocationUpdateHandler : IBulkFileLocationUpdateHandler
    {
        readonly IDbContext _dbContext;
        readonly ISiteControlReader _siteControl;

        public BulkFileLocationUpdateHandler(IDbContext dbContext, ISiteControlReader siteControl)
        {
            _dbContext = dbContext;
            _siteControl = siteControl;
        }
        public async Task UpdateFileLocationAsync(BulkCaseUpdatesArgs request, IQueryable<InprotechKaizen.Model.Cases.Case> casesToBeUpdated, BulkUpdateResult bulkUpdateResult)
        {
            if (request.SaveData.FileLocation == null || !request.SaveData.FileLocation.FileLocation.HasValue) return;

            if (request.SaveData.FileLocation.ToRemove)
            {
                await RemoveFileLocation(casesToBeUpdated.ToArray(), request.SaveData.FileLocation);
            }
            else
            {
                await UpdateFileLocation(casesToBeUpdated.ToArray(), request.SaveData.FileLocation);
            }

            bulkUpdateResult.HasFileLocationUpdated = true;
        }

        async Task UpdateFileLocation(InprotechKaizen.Model.Cases.Case[] casesToBeUpdated, BulkFileLocationUpdate flu)
        {
            var maxLocations = _siteControl.Read<int?>(SiteControls.MAXLOCATIONS) ?? 0;

            var caseList = string.Join(",", casesToBeUpdated.Select(_ => _.Id));

            var parameters = new Dictionary<string, object>
            {
                {"@fileLocation", flu.FileLocation},
                {"@bayNumber", string.IsNullOrWhiteSpace(flu.BayNumber) ? (object) DBNull.Value : flu.BayNumber.Trim()},
                {"@issuedBy", flu.MovedBy ?? (object) DBNull.Value},
                {"@whenMoved", flu.WhenMoved},
                {"@maxLocations", maxLocations}
            };

            var insertCommand = new StringBuilder(@"INSERT INTO CASELOCATION (CASEID, WHENMOVED, FILEPARTID, FILELOCATION, BAYNO, ISSUEDBY)
		    SELECT C.CASEID, DATEADD(millisecond,10 * ROW_NUMBER() OVER (ORDER BY C.CASEID, FP.FILEPART), @whenMoved), FP.FILEPART, @fileLocation, @bayNumber, @issuedBy
		    from CASES C
            left join FILEPART FP on (FP.CASEID = C.CASEID)
            where not exists ( SELECT 1 from CASELOCATION CL WHERE CL.CASEID = C.CASEID AND CL.WHENMOVED = @whenMoved )
		    and C.CASEID in (" + caseList + ")");

            insertCommand.AppendLine(@"
             Delete from CASELOCATION
	        from CASELOCATION C
            join (select CL.CASEID, CL.WHENMOVED, row_number() over (PARTITION BY CASEID ORDER BY WHENMOVED DESC) as ROWID
                    from CASELOCATION CL) DC on (DC.CASEID = C.CASEID and DC.WHENMOVED = C.WHENMOVED)
            WHERE DC.ROWID > @maxLocations
            and C.CASEID in (" + caseList + ")");

            await ExecuteAsync(insertCommand.ToString(), parameters);
        }

        async Task RemoveFileLocation(InprotechKaizen.Model.Cases.Case[] casesToBeUpdated, BulkFileLocationUpdate flu)
        {
            var caseList = string.Join(",", casesToBeUpdated.Select(_ => _.Id));

            var parameters = new Dictionary<string, object>
            {
                {"@fileLocation", flu.FileLocation},
                {"@bayNumber", string.IsNullOrWhiteSpace(flu.BayNumber) ? (object) DBNull.Value : flu.BayNumber.Trim()},
                {"@issuedBy", flu.MovedBy ?? (object) DBNull.Value}
            };

            var deleteCommand = new StringBuilder(@"Delete from CASELOCATION
            where FILELOCATION = @fileLocation
            and (@issuedBy IS NULL OR ISSUEDBY = @issuedBy )
            and (@bayNumber IS NULL OR BAYNO = @bayNumber )
		    and CASEID in (" + caseList + ")");
            
            await ExecuteAsync(deleteCommand.ToString(), parameters);
        }

        public async Task ExecuteAsync(string sqlCommand, Dictionary<string, object> parameters)
        {
            using (var command = _dbContext.CreateSqlCommand(sqlCommand, parameters))
            {
                command.CommandTimeout = 0;
                await command.ExecuteNonQueryAsync();
            }
        }
    }
}

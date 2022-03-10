using System;
using System.Collections.Generic;
using System.Data.SqlClient;
using System.Linq;
using System.Net.Configuration;
using System.Text.RegularExpressions;
using System.Threading.Tasks;
using Inprotech.Contracts;
using Inprotech.Infrastructure.Notifications;
using Inprotech.Infrastructure.Notifications.Validation;
using InprotechKaizen.Model.Persistence;
using Newtonsoft.Json;
using Newtonsoft.Json.Serialization;

namespace InprotechKaizen.Model.Components.Accounting.Time
{
    public interface IPostTimeCommand
    {
        Task<PostTimeResult> PostTime(PostTimeArgs args);
        Task PostInBackground(PostTimeArgs args);
        Task PostMultipleStaffInBackground(PostTimeArgs args);
    }

    public class PostTimeCommand : IPostTimeCommand
    {
        readonly IDbContext _dbContext;
        readonly Func<DateTime> _clock;
        readonly IApplicationAlerts _applicationAlerts;

        public PostTimeCommand(IDbContext dbContext, Func<DateTime> clock, IApplicationAlerts applicationAlerts)
        {
            _dbContext = dbContext;
            _clock = clock;
            _applicationAlerts = applicationAlerts;
        }

        public async Task<PostTimeResult> PostTime(PostTimeArgs args)
        {
            var criteria = GetCriteria(args);
            var inputParameters = new Parameters
            {
                {"@pnUserIdentityId", args.UserIdentityId},
                {"@psCulture", args.Culture},
                {"@ptXMLCriteria", criteria.Build().ToString()}
            };

            using var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.TimeRecording.PostTime, inputParameters);
            try
            {
                await command.ExecuteNonQueryAsync();

                return new PostTimeResult(GetIntValue(command.Parameters["@pnRowsPosted"].Value), 
                                          GetIntValue(command.Parameters["@pnIncompleteRows"].Value), 
                                          command.Parameters.Contains("@pbHasOfficeEntityError") && (bool) command.Parameters["@pbHasOfficeEntityError"].Value);
            }
            catch (SqlException ex)
            {
                var resultWithAlert = HandleAlerts(ex);
                if (resultWithAlert == null)
                    throw;

                return resultWithAlert;
            }
        }

        public async Task PostInBackground(PostTimeArgs args)
        {
            var criteria = GetCriteria(args);
            var inputParameters = new Parameters
            {
                {"@pnUserIdentityId", args.UserIdentityId},
                {"@psCulture", args.Culture},
                {"@ptXMLCriteria", criteria.Build().ToString()}
            };

            using var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.TimeRecording.PostTime, inputParameters);
            try
            {
                command.CommandTimeout = 0;
                await command.ExecuteNonQueryAsync();

                var message = new PostTimeResult(GetIntValue(command.Parameters["@pnRowsPosted"].Value), 
                                                 GetIntValue(command.Parameters["@pnIncompleteRows"].Value), 
                                                 command.Parameters.Contains("@pbHasOfficeEntityError") && (bool) command.Parameters["@pbHasOfficeEntityError"].Value);

                UpdateBackgroundStatus(args, StatusType.Completed, JsonConvert.SerializeObject(message, new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver() }));
                await _dbContext.SaveChangesAsync();
            }
            catch (SqlException ex)
            {
                var resultWithAlert = HandleAlerts(ex);
                if (resultWithAlert == null)
                    throw;

                UpdateBackgroundStatus(args, StatusType.Error, JsonConvert.SerializeObject(resultWithAlert, new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver() }));
                await _dbContext.SaveChangesAsync();
            }
        }

        public async Task PostMultipleStaffInBackground(PostTimeArgs args)
        {
            var allStaff = (from d in args.SelectedStaffDates
                                    where d.StaffNameId.HasValue
                                    select d.StaffNameId.Value).Distinct();
            foreach (var staff in allStaff)
            {
                var postTimeArgs = new PostTimeArgs
                {
                    UserIdentityId = args.UserIdentityId,
                    EntityKey = args.EntityKey,
                    StaffNameNo = staff,
                    SelectedDates = args.SelectedStaffDates.Where(v => v.StaffNameId == staff).Select(q => q.Date).ToArray(),
                    Culture = args.Culture
                };
                var criteria = GetCriteria(postTimeArgs);
                var inputParameters = new Parameters
                {
                    { "@pnUserIdentityId", args.UserIdentityId },
                    { "@psCulture", args.Culture },
                    { "@ptXMLCriteria", criteria.Build().ToString() }
                };

                using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.TimeRecording.PostTime, inputParameters);
                try
                {
                    command.CommandTimeout = 0;
                    await command.ExecuteNonQueryAsync();

                    var message = new PostTimeResult(GetIntValue(command.Parameters["@pnRowsPosted"].Value),
                                                     GetIntValue(command.Parameters["@pnIncompleteRows"].Value),
                                                     command.Parameters.Contains("@pbHasOfficeEntityError") && (bool)command.Parameters["@pbHasOfficeEntityError"].Value);

                    UpdateBackgroundStatus(args, StatusType.Completed, JsonConvert.SerializeObject(message, new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver() }));
                    await _dbContext.SaveChangesAsync();
                }
                catch (SqlException ex)
                {
                    var resultWithAlert = HandleAlerts(ex);
                    if (resultWithAlert == null)
                        throw;

                    UpdateBackgroundStatus(args, StatusType.Error, JsonConvert.SerializeObject(resultWithAlert, new JsonSerializerSettings { ContractResolver = new CamelCasePropertyNamesContractResolver() }));
                    await _dbContext.SaveChangesAsync();
                }
            }
        }

        PostTimeFilterCriteria GetCriteria(PostTimeArgs args)
        {
            var filter = new PostTimeFilterCriteria
            {
                WipEntityId = args.EntityKey,
                StaffFilter = args.PostForAllStaff ? null : new PostTimeFilterCriteria.StaffFilterCriteria
                {
                    StaffNameId = args.StaffNameNo,
                    IsCurrentUser = !args.StaffNameNo.HasValue
                },
                EntryDates = args.SelectedDates,
                EntryNos = args.SelectedEntryNos
            };
            if (args.SelectedDates == null || !args.SelectedDates.Any())
            {
                filter.DateRange = new PostTimeFilterCriteria.DateRangeCriteria { ToDate = _clock().Date };
            }

            return filter.ValidForPosting();
        }

        void UpdateBackgroundStatus(PostTimeArgs args, StatusType statusType, string info)
        {
            var bgProcess = new BackgroundProcess.BackgroundProcess
            {
                IdentityId = args.UserIdentityId,
                ProcessType = BackgroundProcessType.General.ToString(),
                ProcessSubType = BackgroundProcessSubType.TimePosting.ToString(),
                Status = (int) statusType,
                StatusDate = _clock(),
                StatusInfo = info
            };
            _dbContext.Set<BackgroundProcess.BackgroundProcess>().Add(bgProcess);
        }

        PostTimeResult HandleAlerts(SqlException ex)
        {
            if (!_applicationAlerts.TryParse(ex.Message, out var applicationAlerts))
                return null;

            var alerts = applicationAlerts as ApplicationAlert[] ?? applicationAlerts.ToArray();
            var error = alerts.First();
            if (!error.ContextArguments.Any())
                return new PostTimeResult(0, 0, false, true) {Error = error};

            var errorParam = error.ContextArguments.First();
            if (!Regex.Match(errorParam, @"^[0-9]{8}$").Success)
            {
                error.ContextArguments = new List<string> {errorParam};
            }
            else
            {
                var yearParam = int.Parse(errorParam.Substring(0, 4));
                var monthParam = int.Parse(errorParam.Substring(4, 2));
                var dayParam = int.Parse(errorParam.Substring(6, 2));
                error.ContextArguments = new List<string> {new DateTime(yearParam, monthParam, dayParam).ToString("yyyy-MM-dd")};
            }

            return new PostTimeResult(0, 0, false, true) {Error = error};
        }

        static int? GetIntValue(object outputValue) => int.TryParse(outputValue.ToString(), out var intValue) ? intValue : null;
    }

    public class PostTimeResult
    {
        public PostTimeResult(int? rowsPosted, int? rowsIncomplete, bool hasOfficeEntityError = false, bool hasError = false)
        {
            RowsPosted = rowsPosted;
            RowsIncomplete = rowsIncomplete;
            HasOfficeEntityError = hasOfficeEntityError;
            HasError = hasError;

        }

        public int? RowsPosted { get; }
        public int? RowsIncomplete { get; }
        public bool HasOfficeEntityError { get; }
        public bool HasError { get; set; }
        public bool HasWarning { get; set; }
        public ApplicationAlert Error { get; set; }
    }
}
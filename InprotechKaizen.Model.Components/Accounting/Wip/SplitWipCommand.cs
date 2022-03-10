using System;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public interface ISplitWipCommand
    {
        Task<WipAdjustOrSplitResult> Split(int userIdentityId, string culture, SplitWipItem wipItem);
    }

    public class SplitWipCommand : ISplitWipCommand
    {
        readonly IDbContext _dbContext;
        readonly ILogger<SplitWipCommand> _logger;

        public SplitWipCommand(IDbContext dbContext, ILogger<SplitWipCommand> logger)
        {
            _dbContext = dbContext;
            _logger = logger;
        }

        public async Task<WipAdjustOrSplitResult> Split(int userIdentityId, string culture, SplitWipItem wipItem)
        {
            var inputParameters = new Parameters
            {
                {"@pnUserIdentityId", userIdentityId},
                {"@psCulture", culture},
                {"@pbCalledFromCentura", false}, 
                {"@pnEntityKey", wipItem.EntityKey}, 
                {"@pnTransKey", wipItem.TransKey}, 
                {"@pnWIPSeqKey", wipItem.WipSeqKey}, 
                {"@pnStaffKey", wipItem.StaffKey},
                {"@pnCaseKey", wipItem.CaseKey}, 
                {"@pnNameKey", wipItem.NameKey},
                {"@pnNarrativeKey", wipItem.NarrativeKey},
                {"@psDebitNoteText", wipItem.DebitNoteText},
                {"@psProfitCentreCode", wipItem.ProfitCentreKey},
                {"@psReasonCode", wipItem.ReasonCode},
                {"@pnLocalSplit", wipItem.LocalAmount}, 
                {"@pnForeignSplit", wipItem.ForeignAmount}, 
                {"@pnSplitPercentage", wipItem.SplitPercentage}, 
                {"@pbAdjustOriginalWIP", wipItem.IsLastSplit}, 
                {"@pdtLogDateTimeStamp", wipItem.LogDateTimeStamp},
                {"@pnAppendToTransKey", wipItem.NewTransKey},
                {"@pnNewWipSeqKey", wipItem.NewWipSeqKey}
            };

            var result = new WipAdjustOrSplitResult();

            using var command = _dbContext.CreateStoredProcedureCommand(StoredProcedures.WipManagement.SplitWip, inputParameters);
            
            await command.ExecuteNonQueryAsync();
            
            if (command.Parameters["@pnAppendToTransKey"].Value != DBNull.Value)
            {
                result.ErrorCode = 0;
                result.NewTransKey = command.Parameters["@pnAppendToTransKey"].GetValueOrDefault<int>();
                result.NewWipSeqKey = Convert.ToInt16(command.Parameters["@pnNewWipSeqKey"].GetValueOrDefault<int>());
            }

            _logger.Trace("WIP Splitting", new
            {
                input = wipItem,
                result
            });

            return result;
        }
    }
}

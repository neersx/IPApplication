using System;
using System.Linq;
using System.Threading.Tasks;
using Inprotech.Contracts;
using InprotechKaizen.Model.Persistence;

namespace InprotechKaizen.Model.Components.Accounting.Wip
{
    public interface IAdjustWipCommand
    {
        Task<WipAdjustOrSplitResult> SaveAdjustment(int userIdentityId, string culture, AdjustWipItem wipItem, bool isCalledFromTimesheet = true);
    }

    public class AdjustWipCommand : IAdjustWipCommand
    {
        static bool? _hasNewEntityKey;
        readonly IDbContext _dbContext;
        readonly ILogger<AdjustWipCommand> _logger;
        readonly ISqlHelper _sqlHelper;

        public AdjustWipCommand(IDbContext dbContext, ISqlHelper sqlHelper, ILogger<AdjustWipCommand> logger)
        {
            _dbContext = dbContext;
            _sqlHelper = sqlHelper;
            _logger = logger;

            DetectNewEntityKeyCompatibility();
        }

        public async Task<WipAdjustOrSplitResult> SaveAdjustment(int userIdentityId, string culture, AdjustWipItem wipItem, bool isCalledFromTimesheet = true)
        {
            var inputParameters = new Parameters
            {
                {"@pnUserIdentityId", userIdentityId},
                {"@psCulture", culture},
                {"@pbCalledFromCentura", false},
                {"@pnEntityKey", wipItem.EntityKey},
                {"@pnTransKey", wipItem.TransKey},
                {"@pnWIPSeqKey", wipItem.WipSeqNo},
                {"@pdtLogDateTimeStamp", wipItem.LogDateTimeStamp},
                {"@pnRequestedByStaffKey", wipItem.RequestedByStaffKey},
                {"@pdtAdjustmentDate", wipItem.TransDate},
                {"@pnAdjustmentType", wipItem.AdjustmentType},
                {"@psReasonCode", wipItem.ReasonCode},
                {"@pnNewLocalValue", wipItem.NewLocal},
                {"@pnNewForeignValue", wipItem.NewForeign},
                {"@pnNewCaseKey", wipItem.NewCaseKey},
                {"@pnNewDebtorKey", wipItem.NewAcctClientKey}, //@pnNewDebtorKey
                {"@pnNewStaffKey", wipItem.NewStaffKey}, //@pnNewStaffKey
                {"@pnNewQuotationKey", wipItem.NewQuotationKey}, //@pnNewQuotationKey
                {"@pnNewProductKey", wipItem.NewProductKey}, //@pnNewProductKey
                {"@pnNewNarrativeKey", wipItem.NewNarrativeKey},
                {"@psNewDebitNoteText", string.IsNullOrWhiteSpace(wipItem.NewDebitNoteText) ? null : wipItem.NewDebitNoteText},
                {"@psNewActivityKey", wipItem.NewActivityCode},
                {"@pdtNewTotalTime", TimeSpanToSqlDateTime(wipItem.NewTotalTime)},
                {"@pnNewTotalUnits", wipItem.NewTotalUnits},
                {"@pnNewChargeOutRate", wipItem.NewChargeRate},
                {"@pbIsAdjustWipToZero", wipItem.IsAdjustToZero},
                {"@pbCalledFromTimeSheet", isCalledFromTimesheet},
                {"@pnNewTransKey", wipItem.NewTransKey }
            };

            if (_hasNewEntityKey.GetValueOrDefault())
            {
                inputParameters.Add("@pnNewEntityKey", DBNull.Value);
            }

            var result = new WipAdjustOrSplitResult();

            using var command = _dbContext.CreateStoredProcedureCommand(Inprotech.Contracts.StoredProcedures.WipManagement.AdjustWip, inputParameters);

            await command.ExecuteNonQueryAsync();

            if (command.Parameters["@pnNewTransKey"].Value != DBNull.Value)
            {
                result.ErrorCode = 0;
                result.NewTransKey = Convert.ToInt32(command.Parameters["@pnNewTransKey"].Value);
            }

            _logger.Trace("WIP Adjustment", new
            {
                input = wipItem,
                result
            });

            return result;
        }

        void DetectNewEntityKeyCompatibility()
        {
            if (_hasNewEntityKey != null)
            {
                return;
            }

            _logger.Trace("Check NewEntityKey availability");

            var parameters = _sqlHelper.DeriveParameters(StoredProcedures.WipManagement.AdjustWip);
            _hasNewEntityKey = parameters.Any(_ => _.Key == "@pnNewEntityKey");

            _logger.Trace($"Check NewEntityKey availability complete: result={_hasNewEntityKey}");
        }

        static DateTime? TimeSpanToSqlDateTime(TimeSpan ts)
        {
            if (ts == TimeSpan.Zero)
            {
                return null;
            }

            var dt = new DateTime(1899, 1, 1);
            dt = dt.Add(ts);
            return dt;
        }
    }

    public class AdjustWipItem
    {
        public int EntityKey { get; set; }
        public int TransKey { get; set; }
        public int WipSeqNo { get; set; }
        public DateTime? LogDateTimeStamp { get; set; }

        public DateTime TransDate { get; set; }
        public int RequestedByStaffKey { get; set; }
        public decimal? NewLocal { get; set; }
        public decimal? NewForeign { get; set; }
        public string ReasonCode { get; set; }
        public int? NewCaseKey { get; set; }
        public int? NewAcctClientKey { get; set; }
        public int? NewStaffKey { get; set; }
        public int? NewProductKey { get; set; }
        public int? NewQuotationKey { get; set; }
        public int? NewNarrativeKey { get; set; }
        public string NewActivityCode { get; set; }
        public string NewDebitNoteText { get; set; }
        public int? AdjustmentType { get; set; }
        public TimeSpan NewTotalTime { get; set; }
        public int? NewTotalUnits { get; set; }
        public decimal? NewChargeRate { get; set; }
        public bool IsAdjustToZero { get; set; }
        public int? NewTransKey { get; set; }
    }
}
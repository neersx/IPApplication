using System.ComponentModel.DataAnnotations;

namespace Inprotech.Web.Configuration.SanityCheck
{
    public class BaseSanityCheckViewModel
    {
        public BaseSanityCheckViewModel()
        {
            RuleOverview = new RuleOverviewModel();
            StandingInstruction = new StandingInstructionModel();
            Other = new OtherModel();
        }

        public RuleOverviewModel RuleOverview { get; set; }

        public StandingInstructionModel StandingInstruction { get; set; }

        public OtherModel Other { get; set; }
    }

    public class RuleOverviewModel
    {
        public string DisplayMessage { get; set; }

        [MaxLength(254)]
        public string RuleDescription { get; set; }

        public string Notes { get; set; }

        public bool? Deferred { get; set; }

        public bool? InUse { get; set; }
        public bool? InformationOnly { get; set; }

        /// <summary>
        ///     Item Id
        /// </summary>
        public int? SanityCheckSql { get; set; }

        /// <summary>
        ///     RoleId
        /// </summary>
        public int? MayBypassError { get; set; }

        public bool IsValid()
        {
            if (string.IsNullOrEmpty(DisplayMessage))
            {
                return false;
            }

            if (string.IsNullOrEmpty(RuleDescription))
            {
                return false;
            }

            if (Deferred.HasValue && Deferred.Value && !SanityCheckSql.HasValue)
            {
                return false;
            }

            return true;
        }
    }

    public class StandingInstructionModel
    {
        [MaxLength(3)]
        public string InstructionType { get; set; }

        public short? Characteristics { get; set; }

        public bool IsValid()
        {
            return string.IsNullOrEmpty(InstructionType) || Characteristics.HasValue;
        }
    }

    public class OtherModel
    {
        public int? TableCode { get; set; }
    }
}
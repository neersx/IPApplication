using Inprotech.Infrastructure.Localisation;

namespace Inprotech.Web.Cases.EventRules
{
    public interface IEventRulesHelper
    {
        string PeriodTypeToLocalizedString(short? period, PeriodType periodType, string[] cultureResolver);
        string PeriodTypeToLocalizedString(short? period, string periodType, string[] cultureResolver);
        string DateTypeToLocalizedString(int? dateType, string[] cultureResolver);
        string RelativeCycleToLocalizedString(int? relativeCycle, string[] cultureResolver);
        ComparisonOperator StringToComparisonOperator(string code);
        string ComparisonOperatorToSymbol(string code, string[] cultureResolver);
        string RatesCodeToLocalizedString(int? ratesCode, string[] cultureResolver);
    }
    public class EventRulesHelper : IEventRulesHelper
    {
        readonly IStaticTranslator _translator;
        const string DueDateCalcTranslate = "caseview.eventRules.dueDateCalculations.";

        public EventRulesHelper(IStaticTranslator translator)
        {
            _translator = translator;
        }

        public string PeriodTypeToLocalizedString(short? period, PeriodType periodType, string[] cultureResolver)
        {
            if (period.HasValue &&
                periodType != PeriodType.NotSet &&
                periodType != PeriodType.UserEntered &&
                periodType != PeriodType.StandingInstruction_Period1 &&
                periodType != PeriodType.StandingInstruction_Period2 &&
                periodType != PeriodType.StandingInstruction_Period3
            )
            {
                return $"{period} {_translator.Translate(DueDateCalcTranslate + "periodConcatenation_" + periodType, cultureResolver)}";
            }

            if (periodType == PeriodType.UserEntered)
            {
                return _translator.Translate(DueDateCalcTranslate + "periodConcatenation_UserEntered", cultureResolver);
            }

            return periodType.ToString().StartsWith("StandingInstruction") ? _translator.Translate(DueDateCalcTranslate + periodType, cultureResolver) : string.Empty;
        }

        public string PeriodTypeToLocalizedString(short? period, string periodType, string[] cultureResolver)
        {
            return PeriodTypeToLocalizedString(period, PeriodTypeHelper.StringToPeriodType(periodType), cultureResolver);
        }

        public string DateTypeToLocalizedString(int? dateType, string[] cultureResolver)
        {
            var dt = DateTypeHelper.ToDateType(dateType);

            return dt != DateType.NotSet ?
                _translator.Translate(DueDateCalcTranslate + "dateType_" + dt, cultureResolver)
                : string.Empty;
        }

        public string RelativeCycleToLocalizedString(int? relativeCycle, string[] cultureResolver)
        {
            var rt = RelativeCycleHelper.ToRelativeCycle(relativeCycle);
            return rt != RelativeCycle.NotSet ?
                _translator.Translate(DueDateCalcTranslate + "relativeCycle_" + rt, cultureResolver)
                : string.Empty;
        }

        public string RatesCodeToLocalizedString(int? ratesCode, string[] cultureResolver)
        {
            var rt = RatesCodeHelper.StringToRatesCode(ratesCode.ToString());

            const string documentsTranslate = "caseview.eventRules.documents.payFeeCode.";
            if (ratesCode != (int)RatesCode.NotSet)
            {
                return _translator.Translate(documentsTranslate + rt, cultureResolver);
            }
            return string.Empty;
        }

        public ComparisonOperator StringToComparisonOperator(string code)
        {
            var comparisonOperator = ComparisonOperator.NotSet;
            if (string.IsNullOrEmpty(code))
            {
                return comparisonOperator;
            }

            switch (code)
            {
                case "=":
                    comparisonOperator = ComparisonOperator.EqualTo;
                    break;
                case "<>":
                    comparisonOperator = ComparisonOperator.NotEqualTo;
                    break;
                case ">":
                    comparisonOperator = ComparisonOperator.GreaterThan;
                    break;
                case ">=":
                    comparisonOperator = ComparisonOperator.GreaterThanAndEqualTo;
                    break;
                case "<":
                    comparisonOperator = ComparisonOperator.LessThan;
                    break;
                case "<=":
                    comparisonOperator = ComparisonOperator.LessThanAndEqualTo;
                    break;
                case "EX":
                    comparisonOperator = ComparisonOperator.Exists;
                    break;
                case "NE":
                    comparisonOperator = ComparisonOperator.NotExists;
                    break;
            }

            return comparisonOperator;
        }

        public string ComparisonOperatorToSymbol(string code, string[] cultureResolver)
        {
            var op = StringToComparisonOperator(code);
            if (op == ComparisonOperator.NotSet)
            {
                return string.Empty;
            }

            var opSymbol = string.Empty;
            switch (op)
            {
                case ComparisonOperator.EqualTo:
                    opSymbol = "=";
                    break;
                case ComparisonOperator.NotEqualTo:
                    opSymbol = "<>";
                    break;
                case ComparisonOperator.GreaterThan:
                    opSymbol = ">";
                    break;
                case ComparisonOperator.GreaterThanAndEqualTo:
                    opSymbol = ">=";
                    break;
                case ComparisonOperator.LessThan:
                    opSymbol = "<";
                    break;
                case ComparisonOperator.LessThanAndEqualTo:
                    opSymbol = "<=";
                    break;
                case ComparisonOperator.Exists:
                    opSymbol = _translator.Translate(DueDateCalcTranslate + "operator_Exists", cultureResolver);
                    break;
                case ComparisonOperator.NotExists:
                    opSymbol = _translator.Translate(DueDateCalcTranslate + "operator_DoesNotExist", cultureResolver);
                    break;
            }

            return opSymbol;
        }
    }
}

using System;
using System.Globalization;

namespace Inprotech.Web.Cases.EventRules
{
    public enum DueDateType
    {
        NotSet,
        Earliest,
        Latest
    }

    public enum PeriodType
    {
        NotSet,
        Days,
        Weeks,
        Months,
        Years,
        UserEntered,
        StandingInstruction_Period1,
        StandingInstruction_Period2,
        StandingInstruction_Period3
    }

    public enum UpdateEventOption : short
    {
        NotSet,
        /// <summary>
        /// The event will be updated with today's date when the document is requested
        /// </summary>
        UpdateEventWhenDocumentProduced = 1,
        /// <summary>
        /// Request the document when the event is updated
        /// </summary>
        ProduceDocumentWhenEventUpdated = 2
    }

    public enum RatesCode
    {
        NotSet = 0,
        RaiseCharge = 1,
        PayFee = 2,
        PayFeeAndRaiseCharge = 3
    }

    public enum BooleanComparison
    {
        NotSet = -1,
        Any = 0,
        All = 1
    }

    public enum RelativeCycle
    {
        NotSet = -1,
        CurrentCycle = 0,
        PreviousCycle = 1,
        NextCycle = 2,
        FirstCycle = 3,
        LatestCycle = 4
    }

    public enum DateType
    {
        NotSet = -1,
        EventDate = 1,
        DueDate = 2,
        EventOrDueDate = 3
    }

    public enum DateOperator
    {
        NotSet,
        Add,
        Subtract
    }

    public enum WorkDayType
    {
        NotSet = 0,
        PreviousWorkDay = 1,
        NextWorkDay = 2
    }

    public enum ComparisonOperator
    {
        NotSet,
        EqualTo, // =
        NotEqualTo, // <>
        GreaterThan, // >
        GreaterThanAndEqualTo, // >=
        LessThan, // <
        LessThanAndEqualTo, // <=
        Exists, // EX
        NotExists // NE
    }

    public enum FailureAction : int
    {
        NotSet = -1,
        Warning = 0,
        Error = 1
    }

    public static class DueDateTypeHelper
    {
        public static DueDateType StringToDueDateType(string dueDateTypeValue)
        {
            var returnDueDateType = DueDateType.NotSet;
            switch (dueDateTypeValue)
            {
                case "E":
                    returnDueDateType = DueDateType.Earliest;
                    break;
                case "L":
                    returnDueDateType = DueDateType.Latest;
                    break;
            }

            return returnDueDateType;
        }
    }

    public static class PeriodTypeHelper
    {
        public static PeriodType StringToPeriodType(string periodTypeValue)
        {
            var returnPeriodType = PeriodType.NotSet;
            switch (periodTypeValue)
            {
                case "D":
                    returnPeriodType = PeriodType.Days;
                    break;
                case "W":
                    returnPeriodType = PeriodType.Weeks;
                    break;
                case "M":
                    returnPeriodType = PeriodType.Months;
                    break;
                case "Y":
                    returnPeriodType = PeriodType.Years;
                    break;
                case "E":
                    returnPeriodType = PeriodType.UserEntered;
                    break;
                case "1":
                    returnPeriodType = PeriodType.StandingInstruction_Period1;
                    break;
                case "2":
                    returnPeriodType = PeriodType.StandingInstruction_Period2;
                    break;
                case "3":
                    returnPeriodType = PeriodType.StandingInstruction_Period3;
                    break;
            }

            return returnPeriodType;
        }
    }

    public static class BooleanComparisonHelper
    {
        public static BooleanComparison StringToBooleanComparison(string code)
        {
            var comparisonValue = BooleanComparison.NotSet;
            if (string.IsNullOrEmpty(code))
            {
                return comparisonValue;
            }

            switch (code.ToUpperInvariant())
            {
                case "ANY":
                    comparisonValue = BooleanComparison.Any;
                    break;
                case "ALL":
                    comparisonValue = BooleanComparison.All;
                    break;
            }

            return comparisonValue;
        }
    }

    public static class RatesCodeHelper
    {
        public static RatesCode StringToRatesCode(string strRateCode)
        {
            RatesCode rateCode = RatesCode.NotSet;
            if (string.IsNullOrEmpty(strRateCode))
            {
                return rateCode;
            }

            int intRateCode;
            if (int.TryParse(strRateCode, out intRateCode))
            {
                rateCode = (RatesCode)intRateCode;
            }
            return rateCode;
        }
    }

    public static class RelativeCycleHelper
    {
        public static RelativeCycle ToRelativeCycle(int? code)
        {
            var relativeCycle = RelativeCycle.NotSet;
            if (!code.HasValue)
            {
                return relativeCycle;
            }

            relativeCycle = (RelativeCycle) code.Value;
            return relativeCycle;
        }
    }

    public static class DateTypeHelper
    {
        public static DateType ToDateType(int? code)
        {
            var dateType = DateType.NotSet;
            if (!code.HasValue)
            {
                return dateType;
            }

            dateType = (DateType) code.Value;
            return dateType;
        }
    }

    public static class DateOperatorHelper
    {
        public static DateOperator StringToDateOperator(string code)
        {
            var dateOperator = DateOperator.NotSet;
            if (string.IsNullOrEmpty(code))
            {
                return dateOperator;
            }

            switch (code)
            {
                case "A":
                    dateOperator = DateOperator.Add;
                    break;
                case "S":
                    dateOperator = DateOperator.Subtract;
                    break;
            }

            return dateOperator;
        }

        public static string DateOperatorToSymbol(DateOperator op)
        {
            if (op == DateOperator.NotSet)
            {
                return string.Empty;
            }

            var opSymbol = string.Empty;
            switch (op)
            {
                case DateOperator.Add:
                    opSymbol = "+";
                    break;
                case DateOperator.Subtract:
                    opSymbol = "-";
                    break;
            }

            return opSymbol;
        }
    }

    public static class WorkDayTypeHelper
    {
        public static WorkDayType ToWorkDayType(decimal? code)
        {
            var workDayType = WorkDayType.NotSet;
            if (!code.HasValue)
            {
                return workDayType;
            }

            workDayType = (WorkDayType) Convert.ToInt32(code.Value);
            return workDayType;
        }
    }
    
    public static class SentenceHelper
    {
        public static string MakeSentenceLike(this string sentenceOrPhraseOrClause)
        {
            if (string.IsNullOrEmpty(sentenceOrPhraseOrClause))
            {
                return sentenceOrPhraseOrClause;
            }

            return sentenceOrPhraseOrClause
                   .Trim()
                   .Replace("  ", " ") /* repeat two spaces with one space */
                   .Replace("  ", " ") /* repeat two spaces with one space */
                   .Replace(" ,", ","); /* because of possible empty clauses being inserted in between spaces. */
        }
    }

    public static class DateStyleHelper
    {
        public static string GetDateStyle(int? dateStyle, string cultureResolver)
        {
            var culture = new CultureInfo(cultureResolver);

            if (culture.Name.StartsWith("zh"))
            {
                dateStyle = 0;
            }
            var dateFormat = string.Empty;
            switch (dateStyle)
            {
                case 0:
                    var dtInfo = culture.DateTimeFormat;
                    dateFormat = dtInfo.GetAllDateTimePatterns('d')[0];
                    break;
                case 1: dateFormat = "dd-MMM-yyyy"; break;
                case 2: dateFormat = "MMM-dd-yyyy"; break;
                case 3: dateFormat = "yyyy-MMM-dd"; break;
            }

            return dateFormat;
        }
    }

    public static class FailureActionHelper
    {
        public static FailureAction ToFailureAction(decimal? code)
        {
            var failureAction = FailureAction.NotSet;
            if (!code.HasValue)
            {
                return failureAction;
            }

            failureAction = (FailureAction)Convert.ToInt32(code.Value);
            return failureAction;
        }
    }
}
using System;
using Inprotech.Web.Properties;
using InprotechKaizen.Model;
using InprotechKaizen.Model.Components.Cases.DataEntryTasks.Validation;
using InprotechKaizen.Model.Names;
using Newtonsoft.Json;
using Newtonsoft.Json.Converters;

namespace Inprotech.Web.BatchEventUpdate.Models
{
    public class RestrictionDetailsModel
    {
        public string Message { get; set; }

        [JsonConverter(typeof(StringEnumConverter))]
        public Severity Severity { get; set; }

        public static RestrictionDetailsModel For(DebtorStatus debtorStatus)
        {
            if(debtorStatus == null) throw new ArgumentNullException("debtorStatus");

            return new RestrictionDetailsModel
                   {
                       Message = debtorStatus.Status,
                       Severity = GetDebtorStatusSeverity(debtorStatus.RestrictionAction)
                   };
        }

        public static RestrictionDetailsModel ForExceededCreditLimit()
        {
            return new RestrictionDetailsModel
                   {
                       Message = Resources.WarningCreditLimitExceeded,
                       Severity = Severity.Warning
                   };
        }

        static Severity GetDebtorStatusSeverity(short restrictionAction)
        {
            switch(restrictionAction)
            {
                case KnownDebtorRestrictions.DisplayWarning:
                    return Severity.Warning;
                case KnownDebtorRestrictions.DisplayWarningWithPasswordConfirmation:
                    return Severity.Warning;
                case KnownDebtorRestrictions.DisplayError:
                    return Severity.Error;
            }

            return Severity.Information;
        }
    }
}
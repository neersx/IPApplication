using InprotechKaizen.Model.Cases;

namespace Inprotech.Web.Configuration.Core
{
    public static class StatusTranslator
    {
        public static SaveStatusModel ConvertToSaveStatusModel(Status status, StopPayReason stopPayReason, int noOfCases = 0)
        {
            return new SaveStatusModel
            {
                Id = status.Id,
                Name = status.Name,
                ExternalName = status.ExternalName,
                StatusSummary = status.StatusSummary(),
                StatusType = status.StatusType(),
                IsDead = !status.LiveFlag.ToBoolean(),
                IsRegistered = status.RegisteredFlag.ToBoolean(),
                IsPending = status.LiveFlag.ToBoolean() && !status.RegisteredFlag.ToBoolean(),
                IsRenewal = status.RenewalFlag.ToBoolean(),
                PoliceRenewals = status.PoliceRenewals.ToBoolean(),
                PoliceExam = status.PoliceExam.ToBoolean(),
                PoliceOtherActions = status.PoliceOtherActions.ToBoolean(),
                LettersAllowed = status.LettersAllowed.ToBoolean(),
                ChargesAllowed = status.ChargesAllowed.ToBoolean(),
                RemindersAllowed = status.RemindersAllowed.ToBoolean(),
                ConfirmationRequired = status.ConfirmationRequiredFlag == 1,
                StopPayReason = stopPayReason,
                StopPayReasonDesc = stopPayReason?.Name,
                PreventWip = status.PreventWip,
                PreventBilling = status.PreventBilling,
                PreventPrepayment = status.PreventPrepayment,
                PriorArtFlag = status.PriorArtFlag,
                NoOfCases = noOfCases 
            };
        }

        public static Status ConvertToStatusModel(SaveStatusModel saveModel, short id)
        {
            var status = new Status(id, saveModel.Name);
            return SetStatusFromSaveStatusModel(status, saveModel);
        }

        public static Status SetStatusFromSaveStatusModel(Status status, SaveStatusModel saveModel)
        {
            status.Name = saveModel.Name;
            status.ExternalName = saveModel.ExternalName;
            status.LiveFlag = saveModel.StatusSummary == Core.StatusSummary.Dead ? 0 : 1;
            status.RegisteredFlag = saveModel.StatusSummary == Core.StatusSummary.Registered ? 1 : 0;
            status.RenewalFlag = saveModel.StatusType == Core.StatusType.Renewal ? 1 : 0;
            status.PoliceRenewals = saveModel.PoliceRenewals.ToDecimal();
            status.PoliceExam = saveModel.PoliceExam.ToDecimal();
            status.PoliceOtherActions = saveModel.PoliceOtherActions.ToDecimal();
            status.LettersAllowed = saveModel.LettersAllowed.ToDecimal();
            status.ChargesAllowed = saveModel.ChargesAllowed.ToDecimal();
            status.RemindersAllowed = saveModel.RemindersAllowed.ToDecimal();
            status.ConfirmationRequiredFlag = saveModel.ConfirmationRequired.ToDecimal();
            status.StopPayReason = saveModel.StopPayReason?.UserCode;
            status.PreventWip = saveModel.PreventWip;
            status.PreventBilling = saveModel.PreventBilling;
            status.PreventPrepayment = saveModel.PreventPrepayment;
            status.PriorArtFlag = saveModel.PriorArtFlag ?? false;

            return status;
        }

        #region Extensions
        public static StatusSummary StatusSummary(this Status status)
        {
            if (!status.LiveFlag.ToBoolean())
                return Core.StatusSummary.Dead;

            return status.RegisteredFlag.ToBoolean() ? Core.StatusSummary.Registered : Core.StatusSummary.Pending;
        }

        public static StatusType StatusType(this Status status)
        {
            return status.IsRenewal ? Core.StatusType.Renewal : Core.StatusType.Case;
        }

        public static decimal ToDecimal(this bool value)
        {
            return value? 1m : 0m;
        }

        public static bool ToBoolean(this decimal? value)
        {
            return value == 1;
        }

        #endregion
    }
}
